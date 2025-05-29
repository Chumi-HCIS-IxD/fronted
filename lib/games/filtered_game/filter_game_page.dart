// 在 pubspec.yaml 加入：
//   camera: ^0.10.0+4
//   record: ^4.4.1
//   path_provider: ^2.0.14
//   dotted_border: ^2.0.0
//   characters: ^1.2.0

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

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _results = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _filePath;
  final Record _recorder = Record();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadQuestions();
  }

  //測試最終圖片樣式
  // @override
  // void initState() {
  //   super.initState();
  //
  //   _results = [
  //     {'correct': true},
  //     {'correct': true},
  //     {'correct': true},
  //     {'correct': true},
  //     {'correct': true},
  //   ];
  //
  //   _initCamera();
  //   _loadQuestions();
  // }


  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    final front = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );
    _cameraController = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
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

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    final id = _questions[_currentIndex]['id'] as String;
    final filename = '${widget.unitId}_$id.wav';
    _filePath = '${dir.path}/$filename';
    await _recorder.start(path: _filePath, encoder: AudioEncoder.wav);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
  await _recorder.stop();
  setState(() {
    _isRecording = false;
    _isProcessing = true;
  });

  // 單題 ASR 辨識
  final path = _filePath!;
  String? recognized;
  try {
    recognized = await request(path);
  } catch (e) {
    recognized = null;
    print('ASR error on $path: $e');
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
    'userRecordingUrl':   path,
    'recognizedSentence': actual,
    'correct':            isCorrect, //利用此參數更換頁面（對一題換一個）
  });

  // 如果還有下一題，就切到下一題；否則直接跳結果頁
  if (_currentIndex < _questions.length - 1) {
    setState(() {
      _isProcessing = false;
      _currentIndex++;
    });
  } else {
    setState(() {
      _isProcessing = false;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          authService:     widget.authService,
          questionResults: _results,
          unitId:          widget.unitId,   // ← 新增這行
        ),
      ),
    );

  }
}

  @override
  Widget build(BuildContext context) {
    final currentImageIndex = _results.where((r) => r['correct'] == true).length - 1;
    final imagePath = currentImageIndex >= 0 && currentImageIndex < _imagePaths.length
        ? _imagePaths[currentImageIndex]
        : 'assets/images/star.png'; // 預設圖片

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

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
        title: const Text('濾鏡小遊戲',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  '第${_currentIndex + 1}題   請照著提示念出正確發音',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 260),
              const SizedBox(height: 80),
            ],
          ),

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
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
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
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(q['tailou'] ?? '',
                            style: const TextStyle(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(q['zh'] ?? '',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black45)),
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
                    height: 500,
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
                          if (currentImageIndex >= 0 && currentImageIndex < _imagePaths.length)
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

          Positioned(
            bottom: 32,
            left: (screenWidth - 64) / 2,
            child: GestureDetector(
              onTap: () =>
                  _isRecording ? _stopRecording() : _startRecording(),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: kAccentGreen,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 32,
                  color: Colors.white,
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
