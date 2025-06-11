//
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

// lib/games/filtered_game/result_page.dart

import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../../utils/platform_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // 影片播放
import 'package:http/http.dart' as http;
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
  bool _submitting = false;
  late final String _audioHost;
  /// 用來存放每一題對應的 VideoPlayerController (可空)
  final List<VideoPlayerController?> _videoControllers = [];
  // final AudioPlayer _audioPlayer = AudioPlayer();
  late final PlatformAudioPlayer _pPlayer;
  /// PageController 用於 PageView
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pPlayer = PlatformAudioPlayer();
    // _audioHost = '${widget.authService.baseUrl}/api/speak/audio';
    _initVideoControllers();
    _submitResults();
  }

  @override
  void dispose() {
    for (var controller in _videoControllers) {
      controller?.dispose();
    }
    // _audioPlayer.dispose();
    _pPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// 初始化每一筆 questionResults 對應的影片控制器
  Future<void> _initVideoControllers() async {
    for (var q in widget.questionResults) {
      final path = q['userVideoUrl'] as String?;
      if (path != null && path.isNotEmpty) {
        final controller = VideoPlayerController.file(File(path));
        try {
          await controller.initialize();
          controller.setLooping(false);
          _videoControllers.add(controller);
        } catch (e) {
          _videoControllers.add(null);
          print('❌ VideoPlayerController 初始化失敗 (path=$path)：$e');
        }
      } else {
        _videoControllers.add(null);
      }
    }
    setState(() {});
  }

  /// 模擬送出結果給後端
  Future<void> _submitResults() async {
    setState(() => _submitting = true);

    final payload = widget.questionResults
        .map((q) => {
      'questionId': q['questionId'],
      'result': true,
    })
        .toList();

    final success = await widget.authService.submitSpeakResults(
      widget.unitId,
      payload,
    );
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '提交成功' : '提交失敗')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questionResults.length;
    final completedCount = _videoControllers
        .where((c) => c != null && c.value.isInitialized)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              '練說話結果',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '單元 ${widget.unitId}  |  共 $total 題，已錄製影片 $completedCount 支',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Expanded 包含 PageView，佔滿剩餘空間
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.questionResults.length,
                itemBuilder: (context, idx) {
                  final q = widget.questionResults[idx];
                  final videoPath = q['videoPath'] as String?;
                  final questionId = q['questionId'] as String?;

                  VideoPlayerController? controller;
                  if (idx < _videoControllers.length) {
                    controller = _videoControllers[idx];
                  }

                  // 卡片內容
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          // Card 容器
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 第 X 題 標題
                                  Text(
                                    questionId != null
                                        ? "第 ${idx + 1} 題 (ID: $questionId)"
                                        : "第 ${idx + 1} 題",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '您的錄影結果：',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: double.infinity,
                                        height: 280,
                                        color: const Color(0xFFF0F8F5),
                                        child: (controller != null &&
                                            controller.value.isInitialized)
                                            ? Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // 影片預覽
                                            AspectRatio(
                                              aspectRatio:
                                              controller.value
                                                  .aspectRatio,
                                              child: VideoPlayer(controller),
                                            ),
                                            // 中間播放按鈕
                                            GestureDetector(
                                              onTap: () {
                                                if (controller!.value
                                                    .isPlaying) {
                                                  controller.pause();
                                                } else {
                                                  controller.play();
                                                }
                                                setState(() {});
                                              },
                                              child: Container(
                                                color: Colors.black26,
                                                child: Icon(
                                                  controller.value.isPlaying
                                                      ? Icons
                                                      .pause_circle_filled
                                                      : Icons
                                                      .play_circle_filled,
                                                  color: Colors.white,
                                                  size: 48,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                            : Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.videocam_off,
                                              color: Colors.grey,
                                              size: 48,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              videoPath != null
                                                  ? '影片尚未載入'
                                                  : '尚無錄影',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // 「正確發音」按鈕 (示意按鈕，可照原本需求放功能)
                                  Center(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E7D32),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(160, 44),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: () async {
                                        final url = q['audioUrl'] as String?;
                                        if (url == null || url.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('無法取得正確發音')),
                                          );
                                          return;
                                        }
                                        try {
                                          await _pPlayer.play(url);
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('播放錯誤：$e')),
                                          );
                                        }
                                        // final url = q['audioUrl'] as String?;
                                        // if (url == null || url.isEmpty) {
                                        //   ScaffoldMessenger.of(context).showSnackBar(
                                        //     const SnackBar(content: Text('無法取得正確發音')),
                                        //   );
                                        //   return;
                                        // }
                                        // print('嘗試下載並播放 WAV：$url');
                                        // try {
                                        //   // 1. 先用 HTTP GET 下載檔案到記憶體
                                        //   final response = await http.get(Uri.parse(url));
                                        //   if (response.statusCode != 200) {
                                        //     throw 'HTTP 錯誤：${response.statusCode}';
                                        //   }
                                        //
                                        //   // 2. 停掉上一段播放，並設音量
                                        //   await _audioPlayer.stop();
                                        //   await _audioPlayer.setVolume(1.0);
                                        //
                                        //   // 3. 以 BytesSource 播放下載到的 bodyBytes
                                        //   await _audioPlayer.play(BytesSource(response.bodyBytes));
                                        //   print('下載後的 BytesSource 已開始播放 WAV');
                                        // } catch (e) {
                                        //   print('❌ 下載或播放失敗：$e');
                                        //   ScaffoldMessenger.of(context).showSnackBar(
                                        //     SnackBar(content: Text('播放錯誤：$e')),
                                        //   );
                                        // }
                                      },
                                      icon: const Icon(Icons.volume_up, size: 20),
                                      label: const Text('正確發音', style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 下方橫向分頁指示點 (dots)
                          SizedBox(
                            height: 20,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  widget.questionResults.length,
                                      (dotIndex) => Container(
                                    margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                    width: dotIndex == idx ? 12 : 8,
                                    height: dotIndex == idx ? 12 : 8,
                                    decoration: BoxDecoration(
                                      color: dotIndex == idx
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey[400],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 最下方「回到首頁」按鈕
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
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePage(
                        authService: widget.authService,
                        initialIndex: 0,
                      ),
                    ),
                        (route) => false,
                  );
                },
                child: const Text(
                  '回到首頁',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}