// // lib/pages/mcq_game_page.dart
//
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:audioplayers/audioplayers.dart';    // ★ 新增
//
// class McqGamePage extends StatefulWidget {
//   final String unitId;
//   final String roomId;
//   const McqGamePage({
//     Key? key,
//     required this.unitId,
//     required this.roomId,
//   }) : super(key: key);
//
//   @override
//   State<McqGamePage> createState() => _McqGamePageState();
// }
//
// class _McqGamePageState extends State<McqGamePage> {
//   List<Question> questions = [];
//   bool loading = true;
//   int currentIndex = 0;
//   int score = 0;
//   int elapsed = 0;
//   Timer? timer;
//   int? _pressedIndex;
//   late final AudioPlayer _player;
//
//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//     _player = AudioPlayer();
//     _loadQuestions();
//   }
//
//   void _startTimer() {
//     timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       setState(() => elapsed++);
//     });
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
//
//     // Android emulator 用 10.0.2.2，其它平台用 127.0.0.1
//     final host = Platform.isAndroid ? '10.0.2.2' : '140.116.245.157';
//     final uri = Uri.parse(
//       'http://$host:5019/api/mcq/questionSets/${widget.unitId}/questions',
//     );
//
//     try {
//       final res = await http.get(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//       );
//       if (res.statusCode != 200) {
//         throw Exception('HTTP ${res.statusCode}');
//       }
//
//       final Map<String, dynamic> body = json.decode(res.body);
//       final raw = body['questions'] as List<dynamic>? ?? <dynamic>[];
//       final loaded = raw
//           .map((e) => Question.fromJson(e as Map<String, dynamic>))
//           .toList();
//
//       setState(() {
//         questions = loaded;
//         loading = false;
//       });
//     } catch (e) {
//       setState(() => loading = false);
//       await showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('取題失敗'),
//           content: Text(e.toString()),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('確定'),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   void _choose(int idx) {
//     if (questions[currentIndex].ans == idx) {
//       score++;
//     }
//     if (currentIndex + 1 < questions.length) {
//       setState(() => currentIndex++);
//     } else {
//       timer?.cancel();
//       Navigator.pushReplacementNamed(
//         context,
//         '/result',
//         arguments: {'score': score, 'max': questions.length},
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     final q = questions[currentIndex];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('題目 ${currentIndex + 1}/${questions.length}'),  // ← 把「單元 ${widget.unitId}  •」拿掉
//         centerTitle: true,
//         leading: BackButton(onPressed: () => Navigator.pop(context)),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: Center(child: Text('時間：$elapsed s')),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // 題目＋播放按鈕
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       q.title,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.volume_up),
//                     onPressed: () async {
//                       debugPrint('▶️ 播放: ${q.audioUrl}');
//                       await _player.stop();
//                       await _player.play(UrlSource(q.audioUrl));
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             // 選項格子
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: GridView.builder(
//                   itemCount: q.option.length,
//                   gridDelegate:
//                   const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     mainAxisSpacing: 12,
//                     crossAxisSpacing: 12,
//                     childAspectRatio: 1.1,
//                   ),
//                   itemBuilder: (ctx, i) {
//                     final label = String.fromCharCode(65 + i);         // A, B, C, D…
//                     final isPressed = _pressedIndex == i;
//
//                     return Material(
//                       color: Colors.transparent,
//                       child: InkWell(
//                         onTapDown:   (_)   => setState(() => _pressedIndex = i),
//                         onTapUp:     (_)   => setState(() => _pressedIndex = null),
//                         onTapCancel: ()    => setState(() => _pressedIndex = null),
//                         onTap:       ()    => _choose(i),
//                         borderRadius: BorderRadius.circular(12),
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 100),
//                           margin: const EdgeInsets.all(8),
//                           transform: Matrix4.identity()..scale(isPressed ? 0.94 : 1.0),
//                           transformAlignment: Alignment.center,
//                           decoration: BoxDecoration(
//                             color: isPressed ? Colors.grey[100] : Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 6,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               // ★ 這裡放「圖片或文字」條件式
//                               Expanded(
//                                 child: q.imageUrls.length > i
//                                     ? ClipRRect(
//                                   borderRadius:
//                                   const BorderRadius.vertical(top: Radius.circular(12)),
//                                   child: Image.network(
//                                     q.imageUrls[i],               // 後端給你的完整 URL
//                                     fit: BoxFit.cover,
//                                     width: double.infinity,
//                                     loadingBuilder: (ctx, w, ev) =>
//                                     ev == null ? w : const Center(
//                                         child: CircularProgressIndicator(strokeWidth: 2)),
//                                     errorBuilder: (ctx, err, st) {
//                                       debugPrint(
//                                           '❌ image load failed: ${q.imageUrls[i]} → $err');
//                                       return const Center(child: Icon(Icons.broken_image));
//                                     },
//                                   ),
//                                 )
//                                     : Center(
//                                   child: Text(
//                                     q.option[i],                // 如果沒圖就顯示文字
//                                     textAlign: TextAlign.center,
//                                     style: const TextStyle(fontSize: 16),
//                                   ),
//                                 ),
//                               ),
//
//                               const SizedBox(height: 4),
//
//                               // 底下的選項 Label
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 4),
//                                 child: Text(
//                                   '$label. ${q.option[i]}',
//                                   textAlign: TextAlign.center,
//                                   style: const TextStyle(fontSize: 14),
//                                 ),
//                               ),
//
//                               const SizedBox(height: 8),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// 題目 Model
// class Question {
//   final String title;
//   final String audioUrl;
//   final List<String> imageUrls;
//   final List<String> option;
//   final int ans;
//
//   Question({
//     required this.title,
//     required this.audioUrl,
//     required this.imageUrls,
//     required this.option,
//     required this.ans,
//   });
//
//   factory Question.fromJson(Map<String, dynamic> j) {
//     return Question(
//       title: j['title'] as String? ?? '',
//       audioUrl: j['audioUrl'] as String? ?? '',
//       imageUrls:
//       (j['imageUrls'] as List<dynamic>?)?.cast<String>() ?? <String>[],
//       option: (j['option'] as List<dynamic>?)?.cast<String>() ?? <String>[],
//       ans: j['ans'] as int? ?? 0,
//     );
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

class McqGamePage extends StatefulWidget {
  const McqGamePage({Key? key}) : super(key: key);

  @override
  State<McqGamePage> createState() => _McqGamePageState();
}

class _McqGamePageState extends State<McqGamePage> {
  List<Question> questions = [];
  bool loading = true;

  int currentIndex = 0;
  late final int perQuestionTime; // 老師指定的秒數
  int remaining = 0;              // 剩餘秒數
  Timer? timer;
  late final AudioPlayer _player;

  List<Map<String, dynamic>> answers = [];

  @override
  void initState() {
    super.initState();
    // 從路由拿 roomId, duration
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    perQuestionTime = args['duration'] as int;
    remaining = perQuestionTime;

    _player = AudioPlayer();
    _startCountdown();
    _loadQuestions();
  }

  @override
  void dispose() {
    timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _startCountdown() {
    timer?.cancel();
    setState(() => remaining = perQuestionTime);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        remaining--;
      });
      if (remaining <= 0) {
        _recordAndNext(
            selected: questions[currentIndex].option.length); // 逾時用錯誤值
      }
    });
  }

  Future<void> _loadQuestions() async {
    setState(() => loading = true);
    // TODO: 換成真實 host
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final uri = Uri.parse(
        'http://$host:5019/api/mcq/questionSets/${/*你的unit*/ "Unit_1"}/questions');

    try {
      final res = await http.get(uri,
          headers: {'Content-Type': 'application/json'});
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final body = json.decode(res.body) as Map<String, dynamic>;
      final raw = body['questions'] as List<dynamic>? ?? [];
      final loaded = raw
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        questions = loaded;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('取題失敗'),
          content: Text(e.toString()),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('確定'))
          ],
        ),
      );
    }
  }

  void _recordAndNext({required int selected}) {
    final q = questions[currentIndex];
    answers.add({'questionId': q.id, 'selected': selected});
    if (currentIndex + 1 < questions.length) {
      setState(() => currentIndex++);
      _startCountdown();
    } else {
      timer?.cancel();
      _submitResults();
    }
  }

  void _choose(int idx) => _recordAndNext(selected: idx);

  Future<void> _submitResults() async {
    final payload = {
      'user': /* TODO: 換成你的 uid */ '',
      'answers': answers,
    };
    // TODO: 呼叫後端 API
    // await http.post(..., body: jsonEncode(payload));
    Navigator.pushReplacementNamed(context, '/result',
        arguments: payload);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final q = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('題目 ${currentIndex + 1}/${questions.length}'),
        centerTitle: true,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('時間：$remaining s')),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 題目 + 播放按鈕
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      q.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
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

            // 選項格子
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  itemCount: q.option.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1),
                  itemBuilder: (ctx, i) {
                    final label = String.fromCharCode(65 + i);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _choose(i),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border:
                            Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // 圖片或文字 fallback
                              Expanded(
                                child: q.imageUrls.length > i
                                    ? ClipRRect(
                                  borderRadius:
                                  const BorderRadius.vertical(
                                      top: Radius.circular(
                                          8)),
                                  child: Image.network(
                                    q.imageUrls[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    loadingBuilder:
                                        (ctx, w, ev) =>
                                    ev == null
                                        ? w
                                        : const Center(
                                        child:
                                        CircularProgressIndicator(
                                            strokeWidth:
                                            2)),
                                    errorBuilder:
                                        (ctx, err, stack) {
                                      return const Center(
                                          child: Icon(Icons
                                              .broken_image));
                                    },
                                  ),
                                )
                                    : Center(
                                  child: Text(
                                    q.option[i],
                                    textAlign:
                                    TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: Text(
                                  '$label. ${q.option[i]}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 題目 Model
class Question {
  final String id;
  final String title;
  final String audioUrl;
  final List<String> imageUrls;
  final List<String> option;
  final int ans;

  Question({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.imageUrls,
    required this.option,
    required this.ans,
  });

  factory Question.fromJson(Map<String, dynamic> j) {
    return Question(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      audioUrl: j['audioUrl'] as String? ?? '',
      imageUrls:
      (j['imageUrls'] as List<dynamic>?)?.cast<String>() ??
          <String>[],
      option: (j['option'] as List<dynamic>?)?.cast<String>() ??
          <String>[],
      ans: j['ans'] as int? ?? 0,
    );
  }
}