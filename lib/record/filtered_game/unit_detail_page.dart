import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';

class UnitDetailPage extends StatefulWidget {
  final List<dynamic>? questions;
  final String date;
  final String unitId;
  final String roomId;
  final String userId;
  final AuthApiService authService;
  final Map<String, dynamic>? recordData;

  const UnitDetailPage({
    this.questions,
    super.key,
    required this.unitId,
    required this.roomId,
    required this.userId,
    required this.authService,
    required this.date,
    this.recordData,
  });

  @override
  State<UnitDetailPage> createState() => _UnitDetailPageState();
}

class _UnitDetailPageState extends State<UnitDetailPage> {
  List<QuestionCorrection> corrections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final questions = widget.questions ?? await widget.authService.fetchFilterQuestions(widget.unitId);
      final record = widget.recordData ?? await widget.authService.fetchRecordForUnit(widget.unitId);
      final resultsList = (record != null && record['results'] != null)
          ? (record['results'] as List<dynamic>)
          : <dynamic>[];

      final List<QuestionCorrection> parsed = [];

      for (var res in resultsList) {
        if (res['result'] == true) continue; // 只顯示錯的

        final qid = res['questionId']?.toString() ?? '';
        final qObjIndex = questions.indexWhere((q) => q['id'] == qid);
        if (qObjIndex == -1) continue;

        final qObj = questions[qObjIndex];
        parsed.add(QuestionCorrection(
          questionIndex: qObjIndex,   // 題號（index）
          question: qObj['taibun'] ?? '',
          tailou: qObj['tailou'] ?? '',
          translation: qObj['zh'] ?? '',
          audioUrl: qObj['audioUrl'] ?? '',
        ));
      }

      setState(() {
        corrections = parsed;
        isLoading = false;
      });
    } catch (e) {
      print('❌ 外層錯誤：$e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitId),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : corrections.isEmpty
          ? const Center(child: Text('全部答對，沒有錯題訂正！'))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            '作答時間：${widget.date.replaceFirst("T", " ").split(".")[0]}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Text(
            '錯題訂正',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: corrections.length,
              itemBuilder: (context, idx) {
                final c = corrections[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顯示「第幾題」
                        Row(
                          children: [
                            const Icon(Icons.close, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              "第 ${c.questionIndex + 1} 題",
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          c.question,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          c.tailou,
                          style: const TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                        Text(
                          c.translation,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.volume_up, color: Colors.white),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () {
                                // TODO: 加入音檔播放功能
                              },
                              label: const Text('正確發音', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
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