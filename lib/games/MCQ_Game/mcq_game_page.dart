import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;                // 已有
import 'package:audioplayers/audioplayers.dart';
import 'api.dart';            // const String baseUrl + Future<String> getToken()
import 'result_page.dart';

class McqGamePage extends StatefulWidget {
  final String unitId;
  final String roomId;
  final String uid;
  final bool isHost;
  final int startTimestamp; // 伺服器回傳的 epoch(ms)
  final int timeLimit;      // 時限（秒）

  const McqGamePage({
    Key? key,
    required this.unitId,
    required this.roomId,
    required this.uid,
    required this.isHost,
    required this.startTimestamp,
    required this.timeLimit,
  }) : super(key: key);

  @override
  _McqGamePageState createState() => _McqGamePageState();
}

class _McqGamePageState extends State<McqGamePage> {
  List<Question> questions = [];
  bool loading = true;
  int currentIndex = 0;
  late int remaining;
  Timer? timer;
  late final AudioPlayer _player;
  final List<Map<String, dynamic>> answers = [];
  bool timeUp = false;
  bool _navigated = false; // 確保只導航一次

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      print('🛈 播放狀態：$state');
    });

    // 計算結束的 timestamp（ms）
    final endTs = widget.startTimestamp + widget.timeLimit * 1000;
    remaining = ((endTs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    if (remaining < 0) remaining = 0;

    _loadQuestions();
  }

  @override
  void dispose() {
    timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/mcq/questionSets/${widget.unitId}/questions'),
      );
      if (res.statusCode != 200) {
        throw Exception('載題失敗：${res.statusCode}');
      }
      final body = json.decode(res.body) as Map<String, dynamic>;
      questions = (body['questions'] as List)
          .map((j) => Question.fromJson(j as Map<String, dynamic>))
          .toList();
      setState(() => loading = false);
      _startCountdown();
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入題目失敗：$e')),
      );
    }
  }

  void _startCountdown() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => remaining--);
      if (remaining <= 0) {
        timer?.cancel();
        _prepareUnanswered();
        setState(() => timeUp = true);
        _submitResults();
      }
    });
  }

  void _onSelectAnswer(int selectedIndex) {
    if (widget.isHost || timeUp) return;

    final String qid = questions[currentIndex].id;
    answers.add({
      'questionId': qid,
      'selected': selectedIndex,
    });

    if (currentIndex + 1 < questions.length) {
      setState(() => currentIndex++);
    } else {
      timer?.cancel();
      _prepareUnanswered();
      _submitResults();
    }
  }

  void _prepareUnanswered() {
    for (var q in questions) {
      if (!answers.any((a) => a['questionId'] == q.id)) {
        answers.add({
          'questionId': q.id,
          'selected': q.option.length,
        });
      }
    }
  }

  void _submitResults() {
    if (_navigated) return;
    _navigated = true;

    final score = answers.where((a) {
      final q = questions.firstWhere((q) => q.id == a['questionId']);
      return a['selected'] == q.ans;
    }).length;
    final max = questions.length;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WaitingPage(
          roomId: widget.roomId,
          uid: widget.uid,
          unitId: widget.unitId,
          answers: answers,
          score: score,
          max: max,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final q = questions[currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('題目 ${currentIndex + 1}/${questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('剩餘：$remaining s'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Text(q.title, style: const TextStyle(fontSize: 18))),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () async {
                    final url = q.audioUrl;
                    print('▶️ HTTP 下載並播放 bytes: $url');
                    try {
                      final res = await http.get(Uri.parse(url));
                      if (res.statusCode == 200) {
                        await _player.stop();
                        await _player.setVolume(1.0);
                        await _player.play(BytesSource(res.bodyBytes));
                        print('🛈 BytesSource 已開始播放');
                      } else {
                        print('⚠️ HTTP 錯誤：${res.statusCode}');
                      }
                    } catch (e) {
                      print('❌ HTTP 下載或播放失敗：$e');
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: timeUp
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('時間到，即將送出答案…', style: TextStyle(fontSize: 16)),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: q.option.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (_, i) {
                      final label = String.fromCharCode(65 + i);
                      return InkWell(
                        onTap: () => _onSelectAnswer(i),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: q.imageUrls.length > i
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        child: Image.network(q.imageUrls[i], fit: BoxFit.cover),
                                      )
                                    : Center(child: Text(q.option[i])),
                              ),
                              const SizedBox(height: 4),
                              Text('$label. ${q.option[i]}', textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class Question {
  final String id, title, audioUrl;
  final List<String> imageUrls, option;
  final int ans;
  Question.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String? ?? '',
        title = j['title'] as String? ?? '',
        audioUrl = j['audioUrl'] as String? ?? '',
        imageUrls = (j['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
        option = (j['option'] as List<dynamic>?)?.cast<String>() ?? [],
        ans = j['ans'] as int? ?? 0;
}

class WaitingPage extends StatefulWidget {
  final String roomId;
  final String uid;
  final String unitId;
  final List<Map<String, dynamic>> answers;
  final int score;
  final int max;
  const WaitingPage({
    Key? key,
    required this.roomId,
    required this.uid,
    required this.unitId,
    required this.answers,
    required this.score,
    required this.max,
  }) : super(key: key);
  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  Timer? _timer;
  bool submitted = false;
  @override
  void initState() {
    super.initState();
    _submitAnswers();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Future<void> _submitAnswers() async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/submit');
    final body = {'user': widget.uid, 'answers': widget.answers};
    try {
      final res = await http.post(uri,
        headers: {'Authorization': 'Bearer $token','Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) setState(() => submitted = true);
      else throw Exception('狀態 ${res.statusCode}');
    } catch (e) {
      debugPrint('提交失敗：$e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提交答案失敗，請檢查網路')),
      );
    }
  }
  Future<void> _checkStatus() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['status'] == 'finished' && mounted) {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultPage(
            score: widget.score,
            max: widget.max,
            roomId: widget.roomId,
            uid: widget.uid,
            answers: widget.answers,
          )),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6ED),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!submitted) const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            submitted ? "✅ 已送出，等待其他人完成..." : "正在提交答案...",
            style: const TextStyle(fontSize: 18),
          ),
        ]),
      ),
    );
  }
}
