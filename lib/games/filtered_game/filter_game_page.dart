import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:dotted_border/dotted_border.dart';
import 'package:characters/characters.dart';
import '../../services/auth_api_service.dart';
import '../../services/stt.dart';
import 'result_page.dart';
import 'package:flutter/foundation.dart';

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
  final List<String> _imagePaths = [
    'assets/images/濾鏡遊戲1.png',
    'assets/images/濾鏡遊戲2.png',
    'assets/images/濾鏡遊戲3.png',
    'assets/images/濾鏡遊戲4.png',
    'assets/images/濾鏡遊戲5.png',
  ];

  late List<CameraDescription> _cameras;
  CameraController? _cameraController;
  // final Record _recorder = Record();
  final AudioRecorder _recorder = AudioRecorder();

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _results = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _videoPath;
  String? _audioPath;

  // 狀態切換用
  bool _showIntro = true;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadQuestions();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final list = await widget.authService.fetchFilterQuestions(widget.unitId);
    setState(() {
      _questions = List<Map<String, dynamic>>.from(list);
      _loading = false;
    });
  }

  // --- 一次啟動錄影與錄音 ---
  Future<void> _startRecording() async {
    bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getApplicationDocumentsDirectory();
    final id = _questions[_currentIndex]['id'].toString();
    final audioFilename = '${widget.unitId}_$id.wav';
    _audioPath = '${dir.path}/$audioFilename';

    // 新 API
    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _audioPath!,
    );
    setState(() => _isRecording = true);

    // 如果有同時啟動錄影
    await _cameraController!.startVideoRecording();
  }

  Future<void> _stopRecording() async {
    // stop audio
    final audioPath = await _recorder.stop();  // 回傳實際錄音檔案路徑
    setState(() => _isRecording = false);

    // stop video
    XFile videoFile = await _cameraController!.stopVideoRecording();
    _videoPath = videoFile.path;

    // STT 辨識
    String? recognized;
    try {
      recognized = await request(audioPath ?? _audioPath!);
    } catch (e) {
      recognized = null;
      print('ASR error on $audioPath: $e');
    }

    final expected = (_questions[_currentIndex]['taibun'] as String).trim();
    final actual   = (recognized ?? '').trim();

    // 只要任兩個字相符就判定答對
    final expectedChars = expected.characters.toList();
    final actualChars   = actual.characters.toSet();
    int matchCount = 0;
    for (var ch in expectedChars) {
      if (actualChars.contains(ch)) matchCount++;
    }
    final isCorrect = matchCount >= 2;

    _results.add({
      'questionId':        _questions[_currentIndex]['id'],
      'text':               expected,
      'romaji':             _questions[_currentIndex]['tailou'] ?? '',
      'translation':        _questions[_currentIndex]['zh']     ?? '',
      'audioUrl':           _questions[_currentIndex]['audioUrl'] ?? '',
      'userRecordingUrl':   audioPath ?? _audioPath,
      'userVideoUrl':       _videoPath,
      'recognizedSentence': actual,
      'correct':            isCorrect,
    });

    // 換題或進入結果頁
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _currentIndex++;
      });
    } else {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _showResult = true;  // 顯示結果卡片
      });
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => ResultPage(
      //       authService:     widget.authService,
      //       questionResults: _results,
      //       unitId:          widget.unitId,
      //     ),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final correctCount = _results.where((r) => r['correct'] == true).length;

    final imagePath = correctCount > 0
        ? _imagePaths[
    correctCount <= _imagePaths.length ? correctCount - 1 : _imagePaths.length - 1
    ]
        : 'assets/images/star.png';

    // final imagePath = correctCount > 0 && correctCount <= _imagePaths.length
    //     ? _imagePaths[correctCount - 1]
    //     : 'assets/images/star.png';

    const kPrimaryGreen = Color(0xFF2E7D32);
    const kAccentGreen = Color(0xFF4CAF50);
    final screenWidth = MediaQuery.of(context).size.width;

    if (_loading ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
// 1. 說明頁
    if (_showIntro) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          backgroundColor: kPrimaryGreen,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          centerTitle: true,
          // title: const Text('濾鏡小遊戲', style: TextStyle(fontWeight: FontWeight.bold)),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '練說話',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Lián kóng-uē',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
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
                        child: const Text('開始', style: TextStyle(fontSize: 18)),
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

    // 2. 全部完成時，顯示結果卡片
    if (_showResult) {
      final int correctCount = _results.where((r) => r['correct'] == true).length;
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
                          authService: widget.authService,
                          questionResults: _results,
                          unitId: widget.unitId,
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

    // 3. 遊戲主畫面
    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
        // title: const Text('練說話',
        //     style: TextStyle(fontWeight: FontWeight.bold)),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '練說話',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Lián kóng-uē',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('單元：${widget.unitId}',
                style: const TextStyle(color: Colors.white70)),
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
          // 題目卡片
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
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q['taibun'] ?? '',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(q['tailou'] ?? '',
                            style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(q['zh'] ?? '',
                            style: const TextStyle(fontSize: 16, color: Colors.black45)),
                      ],
                    ),
                  ),
                  Positioned(
                      top: 0,
                      right: -60,
                      child: Image.asset('assets/images/star.png', width: 150, height: 150)
                  ),
                ],
              ),
            ),
          ),
          // 鏡頭預覽 + 濾鏡圖片
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
                  padding: const EdgeInsets.all(0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 300,
                      height: 450,
                      child: ClipRect(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                            // 疊加濾鏡圖片（根據答對題數）
                            if (correctCount > 0)
                            // if (correctCount > 0 && correctCount <= _imagePaths.length)
                              Positioned.fill(
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
          ),
          // 錄影＋錄音按鈕
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 32 + MediaQuery.of(context).padding.bottom,
              ),
              child: GestureDetector(
                onTap: () => _isRecording ? _stopRecording() : _startRecording(),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: kAccentGreen,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.videocam,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),


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
