import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';

class UnitDetailPage extends StatefulWidget {
  final String date; // ← 新增這行
  final String unitId;
  final String roomId;
  final String userId;
  final AuthApiService authService;

  /// 新增：可選的作答紀錄（直接來自 UnitSelectionPage）
  final Map<String, dynamic>? recordData;

  const UnitDetailPage({
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
      final questions = await widget.authService.fetchQuestions(widget.unitId);

      final record = widget.recordData ??
          await widget.authService.fetchRecordForUnit(widget.unitId);

      final userAnswersList = record?['answers'] as List<dynamic>? ?? [];

      final Map<int, int> userAnswers = {};
      for (var a in userAnswersList) {
        try {
          final raw = a['questionId'].toString(); // e.g. "q01"
          final match = RegExp(r'\d+').firstMatch(raw); // 擷取數字部分
          if (match != null) {
            final parsedId = int.parse(match.group(0)!) + 1; // ✅ 減一
            userAnswers[parsedId] = a['selected'];
          } else {
            print('⚠️ 無法從 questionId=$raw 擷取數字');
          }
        } catch (e) {
          print('❌ 無法解析 questionId=${a['questionId']}：$e');
        }
      }





      final List<QuestionCorrection> parsed = [];

      for (var q in questions) {
        final qidStr = q['id'].toString(); // e.g. "q01"
        print('🔍 處理題目 ID: $qidStr');

        try {
          final match = RegExp(r'\d+').firstMatch(qidStr);
          if (match == null) {
            print('⚠️ 無法從 $qidStr 找到數字');
            continue;
          }

          final qidIndex = int.parse(match.group(0)!); // 不減 1，與 questionId 對齊
          final userAnswer = userAnswers[qidIndex];

          print('✅ 題目 $qidStr (index=$qidIndex) 使用者選：$userAnswer');

          parsed.add(QuestionCorrection(
            question: q['title'],
            choices: List<String>.from(q['option']),
            correctAnswerIndex: q['ans'],
            userAnswerIndex: userAnswer,
            isCorrect: userAnswer != null && userAnswer == q['ans'],
          ));
        } catch (e) {
          print('❌ 錯誤處理題目 $qidStr：$e');
        }
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
    final correctCount = corrections.where((c) => c.isCorrect).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitId),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : corrections.isEmpty
          ? const Center(child: Text('無作答紀錄'))
          : Column(
        children: [
          const SizedBox(height: 12),

          // 🔽 加在這裡（顯示作答時間）
          Text(
            '作答時間：${widget.date.replaceFirst("T", " ").split(".")[0]}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            '答對題數：$correctCount / ${corrections.length}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          const Text(
            '錯題訂正',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PageView.builder(
              itemCount: corrections.length,
              controller: PageController(viewportFraction: 0.9),
              itemBuilder: (context, index) {
                return CorrectionCard(
                  correction: corrections[index],
                  index: index,
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
  final String question;
  final List<String> choices;
  final int correctAnswerIndex;
  final int? userAnswerIndex;
  final bool isCorrect;

  QuestionCorrection({
    required this.question,
    required this.choices,
    required this.correctAnswerIndex,
    this.userAnswerIndex,
    required this.isCorrect,
  });
}

class CorrectionCard extends StatelessWidget {
  final QuestionCorrection correction;
  final int index;

  const CorrectionCard({
    super.key,
    required this.correction,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('第 ${index + 1} 題', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('「${correction.question}」', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Column(
              children: List.generate(correction.choices.length, (i) {
                final isCorrect = i == correction.correctAnswerIndex;
                final isPicked = i == correction.userAnswerIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? isPicked
                        ? Colors.green.withOpacity(0.9) // ✅ 正確且選到 → 深綠色
                        : Colors.green.withOpacity(0.2) // ✅ 正確但沒選 → 淺綠色
                        : isPicked
                        ? Colors.red.withOpacity(0.2)   // ❌ 選錯 → 淺紅色
                        : Colors.grey.withOpacity(0.1), // 沒選中 → 淺灰

                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text('${String.fromCharCode(65 + i)}. ${correction.choices[i]}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () {
                        // TODO: 播放該選項音檔
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
