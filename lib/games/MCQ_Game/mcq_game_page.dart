
// === FILE: lib/games/MCQ_Game/mcq_game_page.dart ===

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../../utils/platform_audio_player.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import 'api.dart';
import 'result_page.dart';

class McqGamePage extends StatefulWidget {
  final String unitId;
  final String roomId;
  final String uid;
  final bool isHost;
  final int startTimestamp;
  final int timeLimit;

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
  bool _loading = true;
  int _currentIndex = 0;
  late int _remaining;
  Timer? _timer;
  // late AudioPlayer _player;
  late PlatformAudioPlayer _pPlayer;
  final List<Map<String, dynamic>> _answers = [];
  bool _navigated = false;

  // 加這個 getter 讓 runtime lookup 不會失敗
  List<Map<String, dynamic>> get answers => _answers;

  @override
  void initState() {
    super.initState();
    // _player = AudioPlayer();
    _pPlayer = PlatformAudioPlayer();
    final endTs = widget.startTimestamp + widget.timeLimit * 1000;
    _remaining = ((endTs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    if (_remaining < 0) _remaining = 0;
    _fetchQuestions();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // _player.dispose();
    _pPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _loading = true);
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/mcq/questionSets/${widget.unitId}/questions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // 如果你的後端需要
        },
      );
      if (res.statusCode != 200) throw Exception('載題失敗：${res.statusCode}');
      final body = json.decode(res.body) as Map<String, dynamic>;
      questions = (body['questions'] as List)
          .map((j) => Question.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print(e); // 幫助 debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入題目失敗：$e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        print('== 倒數歸零，送出 ==');
        _timer?.cancel();
        _fillUnanswered();
        _submitResults();
      }
    });
  }

  void _fillUnanswered() {
    for (var i = 0; i < questions.length; i++) {
      if (!_answers.any((a) => a['questionId'] == questions[i].id)) { // 比對也用字串
        _answers.add({'questionId': questions[i].id, 'selected': -1});
      }
    }
  }

  void _onSelect(int idx) {
    print('== 點選答案 ==');
    if (widget.isHost || _remaining <= 0) return;
    _answers.add({'questionId': questions[_currentIndex].id, 'selected': idx});
    if (_currentIndex + 1 < questions.length) {
      setState(() => _currentIndex++);
    } else {
      print('== 題目答完準備送出 ==');
      _timer?.cancel();
      _fillUnanswered();
      _submitResults();
    }
  }

  Future<void> _submitResults() async {
    print('== _submitResults() called ==');
    await Future.delayed(Duration(milliseconds: 100));
    if (_navigated) return;
    _navigated = true;

    final List<Map<String, dynamic>> payloadAnswers = [];
    for (final q in questions) {
      final ansObj = _answers.lastWhere(
            (a) => a['questionId'] == q.id,
        orElse: () => {'selected': -1},
      );
      payloadAnswers.add({
        'questionId': q.id, // 這裡保證是字串 id
        'selected': ansObj['selected'] ?? -1,
      });
    }

    print('▶ SUBMIT BODY: ${json.encode({
      'user': widget.uid,
      'answers': payloadAnswers,
    })}');

    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/submit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'user': widget.uid, 'answers': payloadAnswers}),
    );

    if (res.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交答案失敗: ${res.statusCode}')),
      );
      _navigated = false;
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WaitingPage(
          roomId: widget.roomId,
          uid: widget.uid,
          unitId: widget.unitId,
          answers: payloadAnswers,
          score: 0,
          max: questions.length,
        ),
      ),
    );
  }

  Future<void> _playAudio(String url) async {
    try { await _pPlayer.play(url); }
    catch (e) { debugPrint('播放失敗：$e'); }
  }

  @override
  Widget build(BuildContext context) {
    const double headerH = 150;     // 頭部圖的高度
    const double peachSize = 100;
    // 1) 還在載入時顯示 Loading
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // 2) 如果載完還是沒題目，就顯示錯誤或空狀態
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('錯誤')),
        body: const Center(child: Text('目前沒有題目可顯示')),
      );
    }
    // 3) 確定有題目之後再取第一題
    final q = questions[_currentIndex];

    // 版型參數
    const overlap = 50.0;
    const timerH  = 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
            children: [
              // 1️⃣ Back button - positioned separately
              Positioned(
                top: 20,
                left: 6,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // 2️⃣ Title section
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Column(
                  children: const [
                    Text(
                      '選擇題',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'suan-tik-tê',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          // 3️⃣ 題目 Card
          Positioned(
            top: headerH - overlap,
            left: Dimens.paddingPage,
            right: Dimens.paddingPage,
            child: Container(
              padding: const EdgeInsets.all(Dimens.paddingPage),
              decoration: BoxDecoration(
                color: AppColors.primaryBG,
                border: Border.all(color: AppColors.primary, width: 1.2),
                borderRadius: BorderRadius.circular(Dimens.radiusCard),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '第${_currentIndex+1}題',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '聽聲音，選答案',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Text(
                  //   '「${q.title}」',
                  //   style: const TextStyle(fontSize: 14),
                  // ),
                  const SizedBox(height: 4),
                  const Text(
                    'thiann siann-im, kìng kái-tap',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                      onPressed: () {
                        print('點了播放，URL=${q.audioUrl}');
                        _playAudio(q.audioUrl);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: headerH + 80, // 微調垂直位置
            right: Dimens.paddingPage / 2,             // 微調水平位置
            width: peachSize,
            height: peachSize,
            child: Image.asset('assets/images/peach.png'),
          ),
          // 4️⃣ 答案 Grid
          Positioned(
            top: headerH + overlap + 150,
            left: 10,
            right: 10,
            bottom: timerH + 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1,
                children: List.generate(q.option.length, (i) {
                  final selectedBg = Colors.white;
                  final fg = Colors.black;
                  return InkWell(
                    onTap: () => _onSelect(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedBg,
                        borderRadius: BorderRadius.circular(Dimens.radiusCard),
                        border: Border.all(color: AppColors.primaryTint),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (q.imageUrls.length > i)
                            Expanded(child: Image.network(q.imageUrls[i])),
                          const SizedBox(height: 8),
                          Text(
                            '${String.fromCharCode(65 + i)}. ${q.option[i]}',
                            style: TextStyle(color: fg),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // 5️⃣ 倒數錶
          Positioned(
            left: Dimens.paddingPage * 5,
            right: Dimens.paddingPage * 5,
            bottom: Dimens.paddingPage,
            height: timerH,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(timerH/2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '$_remaining'.padLeft(2,'0'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
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
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
            max:   widget.max,
            roomId: widget.roomId,
            uid:    widget.uid,
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
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('等待其他人完成...', style: TextStyle(fontSize: 18)),
        ]),
      ),
    );
  }
}