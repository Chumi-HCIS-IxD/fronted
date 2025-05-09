import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';

class UnitDetailPage extends StatefulWidget {
  final String unitId;
  final String roomId;
  final String userId;
  final AuthApiService authService;

  const UnitDetailPage({
    super.key,
    required this.unitId,
    required this.roomId,
    required this.userId,
    required this.authService,
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
      final record = await widget.authService.fetchRecordForUnit(widget.unitId);
      final userAnswersList = record?['answers'] as List<dynamic>? ?? [];

      // 將 List 轉成 Map { q01: 2, q02: 1, ... }
      final Map<String, int> userAnswers = {
        for (var a in userAnswersList) a['questionId']: a['selected']
      };

      final List<QuestionCorrection> parsed = questions.map((q) {
        final qid = q['id'];
        final userAnswer = userAnswers[qid];

        return QuestionCorrection(
          question: q['title'],
          choices: List<String>.from(q['option']),
          correctAnswerIndex: q['ans'],
          userAnswerIndex: userAnswer,
          isCorrect: userAnswer != null && userAnswer == q['ans'],
        );
      }).toList();

      setState(() {
        corrections = parsed;
        isLoading = false;
      });
    } catch (e) {
      print('❌ 錯誤：$e');
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
                        ? Colors.green.withOpacity(0.2)
                        : isPicked
                        ? Colors.red.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
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
