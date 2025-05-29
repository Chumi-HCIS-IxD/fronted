// //filtered_game/result_page
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// // 以下兩個可以視需求移除，因為已經不需要下載到本地
// // import 'package:http/http.dart' as http;
// // import 'package:path_provider/path_provider.dart';
// import '../../pages/home_page.dart';
// import '../../services/auth_api_service.dart';
// import 'package:http/http.dart' as http;
//
// class ResultPage extends StatefulWidget {
//   final AuthApiService authService;
//   final List<Map<String, dynamic>> questionResults;
//   final String unitId;
//
//   const ResultPage({
//     Key? key,
//     required this.authService,
//     required this.questionResults,
//     required this.unitId,
//   }) : super(key: key);
//
//   @override
//   _ResultPageState createState() => _ResultPageState();
// }
//
// class _ResultPageState extends State<ResultPage> {
//   final player = AudioPlayer();
//   bool _submitting = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _submitResults();
//   }
//
//   Future<void> _submitResults() async {
//     setState(() => _submitting = true);
//     final success = await widget.authService.submitSpeakResults(
//       widget.unitId,
//       widget.questionResults
//           .map((q) => {
//         'questionId': q['questionId'],
//         'result': q['correct'] == true,
//       })
//           .toList(),
//     );
//     setState(() => _submitting = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(success ? '提交成功' : '提交失敗')),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final total = widget.questionResults.length;
//     final correctCount =
//         widget.questionResults.where((q) => q['correct'] == true).length;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFE5E5E5),
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const SizedBox(height: 16),
//
//             const SizedBox(height: 16),
//             const Text(
//               '練說話小遊戲結果',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.green,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               '本次共 $total 題，答對 $correctCount 題',
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 itemCount: widget.questionResults.length,
//                 itemBuilder: (context, idx) {
//                   final q = widget.questionResults[idx];
//                   final audioUrl = q['audioUrl'] as String?;
//
//                   final userUrl = q['userRecordingUrl'] as String?;
//                   final isCorrect = q['correct'] as bool? ?? false;
//
//                   return Container(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     padding: const EdgeInsets.symmetric(
//                         vertical: 12, horizontal: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         CircleAvatar(
//                           backgroundColor:
//                           isCorrect ? Colors.green : Colors.red,
//                           child: Icon(
//                             isCorrect ? Icons.check : Icons.close,
//                             color: Colors.white,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "第${idx + 1}題",
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 q['text'] ?? '',
//                                 style: const TextStyle(
//                                   fontSize: 17,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               Text(
//                                 q['romaji'] ?? '',
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               Text(
//                                 q['translation'] ?? '',
//                                 style: const TextStyle(
//                                   fontSize: 13,
//                                   color: Colors.black54,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             ElevatedButton.icon(
//                               style: ElevatedButton.styleFrom(
//                                 foregroundColor: Colors.white,
//                                 backgroundColor: Colors.green,
//                                 minimumSize: const Size(80, 36),
//                                 padding:
//                                 const EdgeInsets.symmetric(horizontal: 8),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                 ),
//                               ),
//                               onPressed: (audioUrl == null || audioUrl.isEmpty)
//                                   ? null
//                                   : () async {
//                                 try {
//                                   final res = await http
//                                       .get(Uri.parse(audioUrl!));
//                                   if (res.statusCode == 200) {
//                                     // 停掉上一段播放
//                                     await player.stop();
//                                     // 調整音量
//                                     await player.setVolume(1.0);
//                                     // BytesSource 直接用 bodyBytes 播放
//                                     await player
//                                         .play(BytesSource(res.bodyBytes));
//                                     print('🛈 BytesSource 已開始播放');
//                                   } else {
//                                     print('⚠️ HTTP 錯誤：${res.statusCode}');
//                                     ScaffoldMessenger.of(context)
//                                         .showSnackBar(
//                                       SnackBar(
//                                           content: Text(
//                                               '下載失敗：${res.statusCode}')),
//                                     );
//                                   }
//                                 } catch (e) {
//                                   print('❌ HTTP 下載或播放失敗：$e');
//                                   ScaffoldMessenger.of(context)
//                                       .showSnackBar(
//                                     SnackBar(content: Text('播放失敗：$e')),
//                                   );
//                                 }
//                               },
//                               icon: const Icon(Icons.volume_up, size: 20),
//                               label: const Text('正確發音',
//                                   style: TextStyle(fontSize: 14)),
//                             ),
//                             const SizedBox(height: 8),
//                             ElevatedButton.icon(
//                               style: ElevatedButton.styleFrom(
//                                 foregroundColor: Colors.white,
//                                 backgroundColor: Colors.grey,
//                                 minimumSize: const Size(80, 36),
//                                 padding:
//                                 const EdgeInsets.symmetric(horizontal: 8),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                 ),
//                               ),
//                               onPressed: () async {
//                                 if (userUrl != null && userUrl.isNotEmpty) {
//                                   final file = File(userUrl);
//                                   if (await file.exists()) {
//                                     await player
//                                         .play(DeviceFileSource(userUrl));
//                                   } else {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(content: Text('錄音檔不存在')),
//                                     );
//                                   }
//                                 } else {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(content: Text('尚無您的發音')),
//                                   );
//                                 }
//                               },
//                               icon:
//                               const Icon(Icons.record_voice_over, size: 20),
//                               label: const Text('您的發音',
//                                   style: TextStyle(fontSize: 14)),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   foregroundColor: Colors.black,
//                   side: const BorderSide(color: Colors.black12),
//                   minimumSize: const Size(180, 48),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20)),
//                   elevation: 0,
//                 ),
//                 onPressed: () {
//                   Navigator.pushAndRemoveUntil(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => HomePage(
//                         authService: widget.authService,
//                         initialIndex: 0,
//                       ),
//                     ),
//                         (route) => false,
//                   );
//                 },
//                 child: const Text('回到首頁',
//                     style: TextStyle(fontWeight: FontWeight.bold)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// filtered_game/result_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../pages/home_page.dart';
import '../../services/auth_api_service.dart';

class ResultPage extends StatefulWidget {
  final AuthApiService authService;
  final List<Map<String, dynamic>> questionResults;
  final String unitId;

  const ResultPage({
    Key? key,
    required this.authService,
    required this.questionResults,
    required this.unitId,
  }) : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final Map<int, VideoPlayerController> _controllers = {};
  bool _videosReady = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initVideoControllers();
    _submitResults();
  }

  Future<void> _initVideoControllers() async {
    final List<Future> inits = [];
    for (int i = 0; i < widget.questionResults.length; i++) {
      final path = widget.questionResults[i]['videoPath'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          final ctrl = VideoPlayerController.file(File(path))
            ..setLooping(false);
          _controllers[i] = ctrl;
          inits.add(ctrl.initialize().catchError((e) {
            debugPrint('⚠️ Video init failed for idx $i: $e');
          }));
        } catch (e) {
          debugPrint('⚠️ Create controller failed for idx $i: $e');
        }
      }
    }

    // 等全部初始化（或錯誤）完成
    await Future.wait(inits);
    if (mounted) {
      setState(() {
        _videosReady = true;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitResults() async {
    setState(() => _submitting = true);
    final success = await widget.authService.submitSpeakResults(
      widget.unitId,
      widget.questionResults
          .map((q) => {
        'questionId': q['questionId'],
        'result': q['correct'] == true,
      })
          .toList(),
    );
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '提交成功' : '提交失敗')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 還沒準備好時顯示 loading
    if (!_videosReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = widget.questionResults.length;
    final correctCount =
        widget.questionResults.where((q) => q['correct'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              '練說話小遊戲結果',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text('本次共 $total 題，答對 $correctCount 題',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: total,
                itemBuilder: (ctx, idx) {
                  final q = widget.questionResults[idx];
                  final ctrl = _controllers[idx];
                  final isCorrect = q['correct'] as bool? ?? false;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 題號與正確 / 錯誤
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                              isCorrect ? Colors.green : Colors.red,
                              child: Icon(
                                isCorrect ? Icons.check : Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "第${idx + 1}題：${q['text'] ?? ''}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 若 controller 初始化成功則顯示影片，否則提示
                        if (ctrl != null && ctrl.value.isInitialized)
                          AspectRatio(
                            aspectRatio: ctrl.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                VideoPlayer(ctrl),
                                _PlayPauseOverlay(controller: ctrl),
                                VideoProgressIndicator(ctrl,
                                    allowScrubbing: true),
                              ],
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            color: Colors.black12,
                            child: const Center(
                              child: Text('無法播放影片'),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 回到首頁按鈕
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black12),
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomePage(
                      authService: widget.authService,
                      initialIndex: 0,
                    ),
                  ),
                      (route) => false,
                ),
                child: const Text('回到首頁',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 播放/暫停按鈕疊加層
class _PlayPauseOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  const _PlayPauseOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
      controller.value.isPlaying ? controller.pause() : controller.play(),
      child: Container(
        color: Colors.black26,
        child: Center(
          child: Icon(
            controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}