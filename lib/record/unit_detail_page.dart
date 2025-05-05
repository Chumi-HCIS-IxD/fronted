import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UnitDetailPage extends StatefulWidget {
  final String unitId;
  final String roomId;
  final String userId;

  const UnitDetailPage({
    super.key,
    required this.unitId,
    required this.roomId,
    required this.userId,
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
    fetchCorrections();
  }

  Future<void> fetchCorrections() async {
    final questionUrl = 'https://your_base_url/api/mcq/questionSets/${widget.unitId}/questions';
    final resultUrl = 'https://your_base_url/api/mcq/rooms/${widget.roomId}/results';

    try {
      final qRes = await http.get(Uri.parse(questionUrl));
      final rRes = await http.get(Uri.parse(resultUrl));

      if (qRes.statusCode == 200 && rRes.statusCode == 200) {
        final questions = jsonDecode(qRes.body)['questions'] as List;
        final results = jsonDecode(rRes.body)['results'] as List;

        final userResult = results.firstWhere(
              (r) => r['user'] == widget.userId,
          orElse: () => null,
        );

        final userAnswers = userResult?['answers'] ?? {};

        final List<QuestionCorrection> parsed = questions.asMap().entries.map((entry) {
          final index = entry.key;
          final q = entry.value;
          final userAnswer = userAnswers['$index'];

          return QuestionCorrection.fromApiJson(q, userAnswer);
        }).toList();

        setState(() {
          corrections = parsed;
          isLoading = false;
        });
      } else {
        print('錯誤: ${qRes.statusCode}, ${rRes.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('取得資料失敗: $e');
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
                return CorrectionCard(correction: corrections[index], index: index);
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

  factory QuestionCorrection.fromApiJson(Map<String, dynamic> q, dynamic userAnswer) {
    return QuestionCorrection(
      question: q['text'] ?? '未知題目',
      choices: List<String>.from(q['choices'] ?? ['A', 'B', 'C', 'D']),
      correctAnswerIndex: q['correct_index'] ?? 0,
      userAnswerIndex: userAnswer,
      isCorrect: userAnswer == q['correct_index'],
    );
  }
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
