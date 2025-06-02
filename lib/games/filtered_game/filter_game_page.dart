// //games/filtered_games/filter_game_page
//
// import 'dart:io';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';
// import 'package:dotted_border/dotted_border.dart';
// import 'package:characters/characters.dart';
// import '../../services/auth_api_service.dart';
// import '../../services/stt.dart';
// import 'result_page.dart';
//
// class FilterGamePage extends StatefulWidget {
//   final String unitId;
//   final AuthApiService authService;
//
//   const FilterGamePage({
//     Key? key,
//     required this.unitId,
//     required this.authService,
//   }) : super(key: key);
//
//   @override
//   _FilterGamePageState createState() => _FilterGamePageState();
// }
//
// class _FilterGamePageState extends State<FilterGamePage> {
//   final List<String> _imagePaths = [
//     'assets/images/濾鏡遊戲1.png',
//     'assets/images/濾鏡遊戲2.png',
//     'assets/images/濾鏡遊戲3.png',
//     'assets/images/濾鏡遊戲4.png',
//     'assets/images/濾鏡遊戲5.png',
//   ];
//
//   late List<CameraDescription> _cameras;
//   CameraController? _cameraController;
//
//   List<Map<String, dynamic>> _questions = [];
//   List<Map<String, dynamic>> _results = [];
//   int _currentIndex = 0;
//   bool _loading = true;
//   bool _isRecording = false;
//   bool _isProcessing = false;
//   String? _filePath;
//   final Record _recorder = Record();
//
//   // 狀態切換用
//   bool _showIntro = true;
//   bool _showResult = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initCamera();
//     _loadQuestions();
//   }
//
//   Future<void> _initCamera() async {
//     _cameras = await availableCameras();
//     final front = _cameras.firstWhere(
//           (cam) => cam.lensDirection == CameraLensDirection.front,
//       orElse: () => _cameras.first,
//     );
//     _cameraController = CameraController(
//       front,
//       ResolutionPreset.medium,
//       enableAudio: true,
//     );
//     await _cameraController!.initialize();
//     if (mounted) setState(() {});
//   }
//
//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadQuestions() async {
//     final list = await widget.authService.fetchFilterQuestions(widget.unitId);
//     setState(() {
//       _questions = List<Map<String, dynamic>>.from(list);
//       _loading = false;
//     });
//   }
//
//   Future<void> _startRecording() async {
//     if (!await _recorder.hasPermission()) return;
//     final dir = await getApplicationDocumentsDirectory();
//     final id = _questions[_currentIndex]['id'] as String;
//     final filename = '${widget.unitId}_$id.wav';
//     _filePath = '${dir.path}/$filename';
//     await _recorder.start(path: _filePath, encoder: AudioEncoder.wav);
//     setState(() => _isRecording = true);
//   }
//
//   Future<void> _stopRecording() async {
//     await _recorder.stop();
//     setState(() {
//       _isRecording = false;
//       _isProcessing = true;
//     });
//
//     // ASR 辨識
//     final path = _filePath!;
//     String? recognized;
//     try {
//       recognized = await request(path);
//     } catch (e) {
//       recognized = null;
//       print('ASR error on $path: $e');
//     }
//
//     final expected = (_questions[_currentIndex]['taibun'] as String).trim();
//     final actual   = (recognized ?? '').trim();
//
//     // 只要任兩個字相符就判定答對
//     final expectedChars = expected.characters.toList();
//     final actualChars   = actual.characters.toSet();
//     int matchCount = 0;
//     for (var ch in expectedChars) {
//       if (actualChars.contains(ch)) matchCount++;
//     }
//     final isCorrect = matchCount >= 2;
//
//     _results.add({
//       'questionId':        _questions[_currentIndex]['id'],
//       'text':               expected,
//       'romaji':             _questions[_currentIndex]['tailou'] ?? '',
//       'translation':        _questions[_currentIndex]['zh']     ?? '',
//       'audioUrl':           _questions[_currentIndex]['audioUrl'] ?? '',
//       'userRecordingUrl':   path,
//       'recognizedSentence': actual,
//       'correct':            isCorrect,
//     });
//
//     // 最後一題完成時，顯示結果卡片
//     if (_currentIndex < _questions.length - 1) {
//       setState(() {
//         _isProcessing = false;
//         _currentIndex++;
//       });
//     } else {
//       setState(() {
//         _isProcessing = false;
//         _showResult = true;  // 顯示結果卡片
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentImageIndex = _results.where((r) => r['correct'] == true).length - 1;
//     final imagePath = currentImageIndex >= 0 && currentImageIndex < _imagePaths.length
//         ? _imagePaths[currentImageIndex]
//         : 'assets/images/star.png'; // 預設圖片
//
//     const kPrimaryGreen = Color(0xFF2E7D32);
//     const kAccentGreen = Color(0xFF4CAF50);
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     if (_loading ||
//         _cameraController == null ||
//         !_cameraController!.value.isInitialized) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     // 1. 說明頁
//     if (_showIntro) {
//       return Scaffold(
//         backgroundColor: Colors.grey[200],
//         appBar: AppBar(
//           backgroundColor: kPrimaryGreen,
//           elevation: 0,
//           leading: const BackButton(color: Colors.white),
//           centerTitle: true,
//           title: const Text('濾鏡小遊戲', style: TextStyle(fontWeight: FontWeight.bold)),
//         ),
//         body: Column(
//           children: [
//             const SizedBox(height: 24),
//             // 單元與主題資訊
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('單元${widget.unitId.replaceAll('Unit_', '')}',
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                   const SizedBox(height: 6),
//                   Text(
//                     '主題：${_questions.isNotEmpty ? (_questions[0]['zh'] ?? '') : ''}',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 8),
//             // 說明框
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(24.0),
//                   child: Column(
//                     children: [
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: Image.asset('assets/images/star.png', width: 56),
//                       ),
//                       const SizedBox(height: 12),
//                       const Text(
//                         '楊桃仔是一位夢想成為「台語發言大使」的偶像精靈。'
//                             '她發現班上林裡的台文寶貝們講話不清楚、沒自信，'
//                             '於是她決定教大家怎麼度放聲說出台語，只要發音夠準，'
//                             '精靈們就會閃閃發亮、跳躍成長。\n'
//                             '你敢開口的話，就能獲得更多記憶碎片！',
//                         style: TextStyle(fontSize: 16),
//                       ),
//                       const SizedBox(height: 24),
//                       ElevatedButton(
//                         onPressed: () => setState(() => _showIntro = false),
//                         child: const Text('開始', style: TextStyle(fontSize: 18, color: Colors.white)),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: kAccentGreen,
//                           minimumSize: const Size(120, 44),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     // 2. 全部完成時，顯示結果卡片
//     if (_showResult) {
//       final int correctCount = _results.where((r) => r['correct'] == true).length;
//       final int totalQuestions = _questions.length;
//       return Scaffold(
//         backgroundColor: Colors.grey[200],
//         appBar: AppBar(
//           backgroundColor: kPrimaryGreen,
//           elevation: 0,
//           centerTitle: true,
//           title: const Text('遊戲結果', style: TextStyle(fontWeight: FontWeight.bold)),
//           leading: const BackButton(color: Colors.white),
//         ),
//         body: Center(
//           child: Container(
//             width: 320,
//             padding: const EdgeInsets.all(32),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(32),
//               boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black12)],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Image.asset('assets/images/star.png', width: 90),
//                 const SizedBox(height: 24),
//                 Text(
//                   '$correctCount / $totalQuestions',
//                   style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   '噢金欸！',
//                   style: TextStyle(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => ResultPage(
//                           authService: widget.authService,
//                           questionResults: _results,
//                           unitId: widget.unitId,
//                         ),
//                       ),
//                     );
//                   },
//                   child: const Text('前往結果頁', style: TextStyle(fontSize: 18)),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kAccentGreen,
//                     minimumSize: const Size(120, 44),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     // 3. 遊戲主畫面
//     final q = _questions[_currentIndex];
//
//     return Scaffold(
//       backgroundColor: Colors.grey[200],
//       appBar: AppBar(
//         backgroundColor: kPrimaryGreen,
//         elevation: 0,
//         leading: const BackButton(color: Colors.white),
//         centerTitle: true,
//         title: const Text('濾鏡小遊戲',
//             style: TextStyle(fontWeight: FontWeight.bold)),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(20),
//           child: Padding(
//             padding: const EdgeInsets.only(bottom: 8),
//             child: Text('單元：${widget.unitId}',
//                 style: const TextStyle(color: Colors.white70)),
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Container(
//                 color: kAccentGreen,
//                 width: double.infinity,
//                 padding:
//                 const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                 child: Text(
//                   '第${_currentIndex + 1}題   請照著提示念出正確發音',
//                   style: const TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//               ),
//               const SizedBox(height: 260),
//               const SizedBox(height: 80),
//             ],
//           ),
//           // 題目卡片與星星裝飾
//           Positioned(
//             top: 100,
//             left: 16,
//             right: 16,
//             child: Center(
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   Container(
//                     width: screenWidth - 120,
//                     padding: const EdgeInsets.symmetric(
//                         vertical: 14, horizontal: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(40),
//                       boxShadow: const [
//                         BoxShadow(
//                             color: Colors.black26,
//                             blurRadius: 6,
//                             offset: Offset(0, 3)),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(q['taibun'] ?? '',
//                             style: const TextStyle(
//                                 fontSize: 20, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 4),
//                         Text(q['tailou'] ?? '',
//                             style: const TextStyle(
//                                 fontSize: 18,
//                                 fontStyle: FontStyle.italic,
//                                 color: Colors.black54)),
//                         const SizedBox(height: 4),
//                         Text(q['zh'] ?? '',
//                             style: const TextStyle(
//                                 fontSize: 16, color: Colors.black45)),
//                       ],
//                     ),
//                   ),
//                   Positioned(
//                       top: 0,
//                       right: -60,
//                       child: Image.asset('assets/images/star.png', width: 150, height: 150)
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // 鏡頭區
//           Positioned(
//               top: 260,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: DottedBorder(
//                   color: kAccentGreen,
//                   strokeWidth: 2,
//                   borderType: BorderType.RRect,
//                   radius: const Radius.circular(12),
//                   dashPattern: const [8, 4],
//                   padding: const EdgeInsets.all(0),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: SizedBox(
//                       width: 300,
//                       height: 500,
//                       child: ClipRect(
//                         child: Stack(
//                           children: [
//                             Positioned.fill(
//                               child: Transform(
//                                 alignment: Alignment.center,
//                                 transform: Matrix4.rotationY(math.pi),
//                                 child: CameraPreview(_cameraController!),
//                               ),
//                             ),
//                             if (currentImageIndex >= 0 && currentImageIndex < _imagePaths.length)
//                               Positioned.fill(
//                                 child: Image.asset(
//                                   imagePath,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               )
//           ),
//           // 錄音按鈕
//           Positioned(
//             bottom: 32,
//             left: (screenWidth - 64) / 2,
//             child: GestureDetector(
//               onTap: () =>
//               _isRecording ? _stopRecording() : _startRecording(),
//               child: CircleAvatar(
//                 radius: 32,
//                 backgroundColor: kAccentGreen,
//                 child: Icon(
//                   _isRecording ? Icons.stop : Icons.mic,
//                   size: 32,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           if (_isProcessing)
//             Container(
//               color: Colors.black38,
//               child: const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// lib/games/filtered_game/filter_game_page.dart

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:characters/characters.dart';
import '../../services/auth_api_service.dart';
import 'result_page.dart';

class FilterGamePage extends StatefulWidget {
  final String unitId;
  final AuthApiService authService;

  const FilterGamePage({
    Key? key,
    required this.unitId,
    required this.authService,
  }) : super(key: key);

  @override
  _FilterGamePageState createState() => _FilterGamePageState();
}

class _FilterGamePageState extends State<FilterGamePage> {
  // === 改用 CameraController 錄影，不再使用 Record plugin
  late List<CameraDescription> _cameras;
  CameraController? _cameraController;

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _results = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _videoPath; // === 錄影檔路徑，取代原本的 audio _filePath

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadQuestions();
  }

  /// 初始化相機 (camera preview)
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      print('🎥 cameras: $_cameras');

      if (_cameras.isEmpty) {
        print('⚠️ 找不到任何相機，跳過相機初始化');
        if (mounted) setState(() => _loading = false);
        return;
      }

      final front = _cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _loading = false);
    } catch (e, st) {
      print('❌ _initCamera 錯誤：$e\n$st');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// 從 API 抓題目清單
  Future<void> _loadQuestions() async {
    final list = await widget.authService.fetchFilterQuestions(widget.unitId);
    setState(() {
      _questions = List<Map<String, dynamic>>.from(list);
      _loading = false;
    });
  }

  /// === 改成錄影(Start Video Recording) ===
  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      // iOS／Android 上有時需先呼叫 prepare
      await _cameraController!.prepareForVideoRecording();

      // 開始錄影 (會同時錄影與錄音)
      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
      });
      print('▶️ 開始錄影');
    } catch (e) {
      print('❌ startVideoRecording 失敗：$e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('開始錄影失敗：$e')));
    }
  }

  /// === 改成停止錄影(Stop Video Recording) ===
  Future<void> _stopRecording() async {
    final current = _questions[_currentIndex];
    debugPrint('🐛 current = $current');
    final audioUrl = current['audioUrl'] ?? '';
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile file = await _cameraController!.stopVideoRecording();
      _videoPath = file.path;

      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });

      print('✅ 錄影完成：$_videoPath');

      // 將結果存到 _results：只存 questionId 與 videoPath
      _results.add({
        'questionId': _questions[_currentIndex]['id'],
        'videoPath': _videoPath,
        'audioUrl': current['audioUrl'],
      });

      // 切到下一題或跳轉結果頁
      if (_currentIndex < _questions.length - 1) {
        setState(() => _currentIndex++);
      } else {
        // 所有題目錄影完畢，前往 ResultPage
        debugPrint('⚠️ audioUrl 進 _results = ${current['audioUrl']}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              authService:     widget.authService,
              questionResults: _results,
              unitId:          widget.unitId,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ stopVideoRecording 失敗：$e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('停止錄影失敗：$e')));
    }
  }


  /// 下面是原本會先顯示 Intro 頁的區塊，我保留了原始結構
  bool _showIntro = true;
  bool _showResult = false; // 這裡不再由錄音後 ASR 決定 correct/incorrect，只是流程保留

  Widget _buildIntroPage(double screenWidth) {
    const kPrimaryGreen = Color(0xFF2E7D32);
    const kAccentGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
        title: const Text('練說話', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // 單元與主題資訊
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('單元${widget.unitId.replaceAll('Unit_', '')}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  '主題：${_questions.isNotEmpty ? (_questions[0]['zh'] ?? '') : ''}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 說明框
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Image.asset('assets/images/star.png', width: 56),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '楊桃仔是一位夢想成為「台語發言大使」的偶像精靈。'
                          '她發現班上林裡的台文寶貝們講話不清楚、沒自信，'
                          '於是她決定教大家怎麼度放聲說出台語，只要發音夠準，'
                          '精靈們就會閃閃發亮、跳躍成長。\n'
                          '你敢開口的話，就能獲得更多記憶碎片！',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () => setState(() => _showIntro = false),
                      child: const Text('開始', style: TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGreen,
                        minimumSize: const Size(120, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 當所有題目都完成時，顯示這個結果卡片(保留原版)
  Widget _buildResultCard() {
    const kPrimaryGreen = Color(0xFF2E7D32);
    const kAccentGreen = Color(0xFF4CAF50);
    final int correctCount = _results.where((r) => r.containsKey('videoPath')).length;
    final int totalQuestions = _questions.length;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text('遊戲結果', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/star.png', width: 90),
              const SizedBox(height: 24),
              Text(
                '$correctCount / $totalQuestions',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '噢金欸！',
                style: TextStyle(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultPage(
                        authService:     widget.authService,
                        questionResults: _results,
                        unitId:          widget.unitId,
                      ),
                    ),
                  );
                },
                child: const Text('前往結果頁', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentGreen,
                  minimumSize: const Size(120, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryGreen = Color(0xFF2E7D32);
    const kAccentGreen = Color(0xFF4CAF50);
    final screenWidth = MediaQuery.of(context).size.width;

    // 如果還在 loading，或 camera 未初始化完成，顯示轉圈
    if (_loading || _cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 1. 首頁 Intro
    if (_showIntro) {
      return _buildIntroPage(screenWidth);
    }

    // 2. 完成所有題目，顯示結果卡片
    if (_showResult) {
      return _buildResultCard();
    }

    // 3. 遊戲主畫面
    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
        title: const Text('練說話', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('單元：${widget.unitId}', style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: kAccentGreen,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  '第${_currentIndex + 1}題   請照著提示念出正確發音',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 260),
              const SizedBox(height: 80),
            ],
          ),

          // 題目卡片與星星裝飾 (照原本寫法保留)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: screenWidth - 120,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['taibun'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q['tailou'] ?? '',
                          style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q['zh'] ?? '',
                          style: const TextStyle(fontSize: 16, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: -60,
                    child: Image.asset('assets/images/star.png', width: 150, height: 150),
                  ),
                ],
              ),
            ),
          ),

          // 鏡頭預覽區 + 影片錄製 (原本是 audio + CameraPreview，這裡改為僅保留 CameraPreview 以錄影)
          Positioned(
            top: 260,
            left: 0,
            right: 0,
            child: Center(
              child: DottedBorder(
                color: kAccentGreen,
                strokeWidth: 2,
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                dashPattern: const [8, 4],
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 240,
                    height: 280,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 錄影按鈕 (原本是錄音按鈕的邏輯，現在改成錄影)
          Positioned(
            bottom: 32,
            left: (screenWidth - 64) / 2,
            child: GestureDetector(
              onTap: () => _isRecording ? _stopRecording() : _startRecording(),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: kAccentGreen,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.videocam, // 用攝影機圖示取代麥克風
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // 錄影中處理遮罩
          if (_isProcessing)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}