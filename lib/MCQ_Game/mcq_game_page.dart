// lib/MCQ_Game/mcq_game_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'api.dart';
import 'result_page.dart';

class McqGamePage extends StatefulWidget {
  final String unitId;
  final String roomId;
  final int duration;
  const McqGamePage({
    Key? key,
    required this.unitId,
    required this.roomId,
    required this.duration,
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
  final List<Map<String, int>> answers = [];
  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    remaining = widget.duration;
    debugPrint('mcq_game_page: start with duration=${widget.duration}');
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
    final host = Platform.isAndroid ? '10.0.2.2' : '140.116.245.157';
    final res = await http.get(
      Uri.parse('http://$host:5019/api/mcq/questionSets/${widget.unitId}/questions'),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    questions = (body['questions'] as List)
        .map((j) => Question.fromJson(j as Map<String, dynamic>))
        .toList();
    setState(() => loading = false);
    _startCountdown();
  }

  void _startCountdown() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => remaining = remaining - 1);
      if (remaining <= 0) {
        timer?.cancel();
        _prepareUnanswered();
        _submitResults();
      }
    });
  }

  void _onSelectAnswer(int selectedIndex) {
    answers.add({'questionId': currentIndex, 'selected': selectedIndex});
    if (currentIndex + 1 < questions.length) {
      setState(() {
        currentIndex++;
        // ← 不要再這裡改 remaining！
      });
    } else {
      timer?.cancel();
      _prepareUnanswered();
      _submitResults();
    }
  }

  void _prepareUnanswered() {
    // 若有未作答題目，標記為 option.length
    for (var i = 0; i < questions.length; i++) {
      if (!answers.any((a) => a['questionId'] == i)) {
        answers.add({'questionId': i, 'selected': questions[i].option.length});
      }
    }
  }

  Future<void> _submitResults() async {
    final max = questions.length;
    final score = answers.where((a) {
      final q = questions[a['questionId']!];
      return a['selected'] == q.ans;
    }).length;
    final token = await getToken();
    await http.post(
      Uri.parse('$baseUrl/api/mcq/submitResults'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'roomId': widget.roomId,
        'unitId': widget.unitId,
        'answers': answers,
      }),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          score: score,
          max: max,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final q = questions[currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('題目 ${currentIndex + 1}/${questions.length}'),
        actions: [Padding(padding: const EdgeInsets.all(16), child: Text('剩餘：$remaining s'))],
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
                    await _player.stop();
                    await _player.play(UrlSource(q.audioUrl));
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
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


// // lib/MCQ_Game/mcq_game_page.dart
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:audioplayers/audioplayers.dart';
// import 'api.dart';
// import 'result_page.dart'; // 引入正確的結果頁
//
// class McqGamePage extends StatefulWidget {
//   final String unitId;
//   final String roomId;
//   final int duration;
//   const McqGamePage({
//     Key? key,
//     required this.unitId,
//     required this.roomId,
//     required this.duration,
//   }) : super(key: key);
//
//   @override
//   _McqGamePageState createState() => _McqGamePageState();
// }
//
// class _McqGamePageState extends State<McqGamePage> {
//   List<Question> questions = [];
//   bool loading = true;
//   int currentIndex = 0;
//   late int remaining;
//   Timer? timer;
//   final List<Map<String, int>> answers = [];
//   late final AudioPlayer _player;
//
//   @override
//   void initState() {
//     super.initState();
//     _player = AudioPlayer();
//     remaining = widget.duration;
//     _loadQuestions();
//   }
//
//   @override
//   void dispose() {
//     timer?.cancel();
//     _player.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadQuestions() async {
//     setState(() => loading = true);
//     final host = Platform.isAndroid ? '10.0.2.2' : '140.116.245.157';
//     final res = await http.get(
//       Uri.parse('http://$host:5019/api/mcq/questionSets/${widget.unitId}/questions'),
//     );
//     final body = json.decode(res.body) as Map<String, dynamic>;
//     questions = (body['questions'] as List)
//         .map((j) => Question.fromJson(j as Map<String, dynamic>))
//         .toList();
//     setState(() => loading = false);
//     _startCountdown();
//   }
//
//   void _startCountdown() {
//     timer?.cancel();
//     timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       setState(() => remaining = remaining - 1);
//       if (remaining <= 0) {
//         timer?.cancel();
//         _submitResults();
//       }
//     });
//   }
//
//   void _onSelectAnswer(int selectedIndex) {
//     answers.add({'questionId': currentIndex, 'selected': selectedIndex});
//     if (currentIndex + 1 < questions.length) {
//       setState(() {
//         currentIndex++;
//         remaining = widget.duration;
//       });
//     } else {
//       timer?.cancel();
//       _submitResults();
//     }
//   }
//
//   Future<void> _submitResults() async {
//     // 補齊未作答題目
//     for (var i = 0; i < questions.length; i++) {
//       if (!answers.any((a) => a['questionId'] == i)) {
//         answers.add({'questionId': i, 'selected': questions[i].option.length});
//       }
//     }
//     final max = questions.length;
//     final score = answers.where((a) {
//       final q = questions[a['questionId']!];
//       return a['selected'] == q.ans;
//     }).length;
//     final token = await getToken();
//     await http.post(
//       Uri.parse('$baseUrl/api/mcq/submitResults'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: json.encode({
//         'roomId': widget.roomId,
//         'unitId': widget.unitId,
//         'answers': answers,
//       }),
//     );
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ResultPage(score: score, max: max),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     final q = questions[currentIndex];
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('題目 ${currentIndex + 1}/${questions.length}'),
//         actions: [Padding(padding: const EdgeInsets.all(16), child: Text('剩餘：$remaining s'))],
//       ),
//       body: Column(
//         children: [
//           // 題幹＋音檔
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(child: Text(q.title, style: const TextStyle(fontSize: 18))),
//                 IconButton(
//                   icon: const Icon(Icons.volume_up),
//                   onPressed: () async {
//                     await _player.stop();
//                     await _player.play(UrlSource(q.audioUrl));
//                   },
//                 ),
//               ],
//             ),
//           ),
//           // 選項
//           Expanded(
//             child: GridView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: q.option.length,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 mainAxisSpacing: 12,
//                 crossAxisSpacing: 12,
//                 childAspectRatio: 1.1,
//               ),
//               itemBuilder: (_, i) {
//                 final label = String.fromCharCode(65 + i);
//                 return InkWell(
//                   onTap: () => _onSelectAnswer(i),
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       border: Border.all(color: Colors.grey.shade300),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Column(
//                       children: [
//                         Expanded(
//                           child: q.imageUrls.length > i
//                               ? ClipRRect(
//                             borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
//                             child: Image.network(q.imageUrls[i], fit: BoxFit.cover),
//                           )
//                               : Center(child: Text(q.option[i])),
//                         ),
//                         const SizedBox(height: 4),
//                         Text('$label. ${q.option[i]}', textAlign: TextAlign.center),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class Question {
//   final String id, title, audioUrl;
//   final List<String> imageUrls, option;
//   final int ans;
//   Question.fromJson(Map<String, dynamic> j)
//       : id = j['id'] as String? ?? '',
//         title = j['title'] as String? ?? '',
//         audioUrl = j['audioUrl'] as String? ?? '',
//         imageUrls = (j['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
//         option = (j['option'] as List<dynamic>?)?.cast<String>() ?? [],
//         ans = j['ans'] as int? ?? 0;
// }