// lib/record/filtered_game/unit_detail_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';

class UnitDetailPage extends StatefulWidget {
  final List<dynamic>? questions;
  final String date;
  final String unitId;
  final String roomId;
  final String userId;
  final AuthApiService authService;
  final List<Map<String, dynamic>> recordList;
  final String unitTitle;
  final String unitRoman;
  final String topIconAsset;
  final bool isCompleted;

  const UnitDetailPage({
    Key? key,
    this.questions,
    required this.unitId,
    required this.roomId,
    required this.userId,
    required this.authService,
    required this.date,
    required this.recordList,
    required this.unitTitle,
    required this.unitRoman,
    required this.topIconAsset,
    required this.isCompleted,
  }) : super(key: key);

  @override
  State<UnitDetailPage> createState() => _UnitDetailPageState();
}

class _UnitDetailPageState extends State<UnitDetailPage> {
  List<QuestionCorrection> corrections = [];
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final questions = widget.questions ??
          await widget.authService.fetchFilterQuestions(widget.unitId);

      final record = widget.recordList.isNotEmpty
          ? widget.recordList.last
          : null;
      final resultsList = (record != null && record['results'] != null)
          ? (record['results'] as List<dynamic>)
          : <dynamic>[];

      final List<QuestionCorrection> parsed = [];
      for (var res in resultsList) {
        if (res['result'] == true) continue;

        final qid = res['questionId']?.toString() ?? '';
        final qObjIndex = questions.indexWhere(
                (q) => q['id']?.toString() == qid);
        if (qObjIndex == -1) continue;

        final qObj = questions[qObjIndex];
        parsed.add(QuestionCorrection(
          questionIndex: qObjIndex,
          question: (qObj['taibun'] ?? '').toString(),
          tailou: (qObj['tailou'] ?? '').toString(),
          translation: (qObj['zh'] ?? '').toString(),
          audioUrl: (qObj['audioUrl'] ?? '').toString(),
        ));
      }

      setState(() {
        corrections = parsed;
        isLoading = false;
      });
    } catch (e) {
      print('❌ 單元詳情抓取失敗：$e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('音檔下載失敗：HTTP ${response.statusCode}')),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/temp.wav');
      await file.writeAsBytes(response.bodyBytes);

      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(file.path));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('播放中')),
      );
    } catch (e) {
      print('❌ 播放失敗：$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('播放失敗：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int playCount = widget.recordList.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. 自訂標題欄 ───
            SizedBox(
              height: 60,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '練說話紀錄',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ki-lōk',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── 2. 單元標題 + 日期 + 遊玩次數 ───
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.unitTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.unitRoman,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        widget.date.split('T').first,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── 3. 遊玩次數 ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '遊玩次數：$playCount 次',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ─── 4. 錯題訂正卡片 (PageView) ───
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (corrections.isEmpty
                  ? const Center(
                child: Text(
                  '全部答對，沒有錯題訂正！',
                  style: TextStyle(
                      fontSize: 16, color: Colors.black54),
                ),
              )
                  : PageView.builder(
                controller:
                PageController(viewportFraction: 0.92),
                itemCount: corrections.length,
                itemBuilder: (context, idx) {
                  final c = corrections[idx];
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6EF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '第 ${c.questionIndex + 1} 題',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.question,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                    FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.tailou,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.translation,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                margin:
                                const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCEDE0),
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.play_circle_fill,
                                      size: 48,
                                      color: Colors.black38,
                                    ),
                                    onPressed: c.audioUrl.isEmpty
                                        ? null
                                        : () {
                                      _playAudio(
                                          c.audioUrl);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 8, 16, 16),
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.volume_up,
                                color: Colors.white,
                              ),
                              label: const Text(
                                '正確發音',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize:
                                const Size.fromHeight(48),
                                backgroundColor:
                                AppColors.primaryDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: c.audioUrl.isEmpty
                                  ? null
                                  : () {
                                _playAudio(
                                    c.audioUrl);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
            ),

            const SizedBox(height: 60),

            // ─── 5. 底部「回到大廳」按鈕 ───
            Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton.extended(
                  icon: const Icon(Icons.home, color: Colors.white,),
                  label: const Text('回到大廳', style: TextStyle(color: Colors.white),),
                  backgroundColor: AppColors.primary,
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
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

class QuestionCorrection {
  final int questionIndex;
  final String question;
  final String tailou;
  final String translation;
  final String audioUrl;

  QuestionCorrection({
    required this.questionIndex,
    required this.question,
    required this.tailou,
    required this.translation,
    required this.audioUrl,
  });
}