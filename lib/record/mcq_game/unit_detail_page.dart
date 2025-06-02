// // lib/record/mcq_game/unit_detail_page.dart
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import '../../services/auth_api_service.dart';
//
// /// 1. 一定要先定義這個 class，才不會出現「不是 type」的錯誤
// class QuestionCorrection {
//   final String question;
//   final List<String> choices;
//   final int correctAnswerIndex;
//   final int? userAnswerIndex;
//   final bool isCorrect;
//
//   QuestionCorrection({
//     required this.question,
//     required this.choices,
//     required this.correctAnswerIndex,
//     this.userAnswerIndex,
//     required this.isCorrect,
//   });
// }
//
// /// 2. 也把 CorrectionCard 放在同一個檔案裡，確保被找到
// class CorrectionCard extends StatelessWidget {
//   final QuestionCorrection correction;
//   final int index;
//
//   const CorrectionCard({
//     Key? key,
//     required this.correction,
//     required this.index,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('第 ${index + 1} 題',
//                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             const SizedBox(height: 8),
//             Text('「${correction.question}」', style: const TextStyle(fontSize: 16)),
//             const SizedBox(height: 16),
//             // 列出每個選項
//             Column(
//               children: List.generate(correction.choices.length, (i) {
//                 final isCorrect = i == correction.correctAnswerIndex;
//                 final isPicked = i == correction.userAnswerIndex;
//                 Color bgColor;
//                 if (isCorrect && isPicked) {
//                   bgColor = Colors.green.withOpacity(0.9);
//                 } else if (isCorrect) {
//                   bgColor = Colors.green.withOpacity(0.2);
//                 } else if (isPicked) {
//                   bgColor = Colors.red.withOpacity(0.2);
//                 } else {
//                   bgColor = Colors.grey.withOpacity(0.1);
//                 }
//                 return Container(
//                   margin: const EdgeInsets.symmetric(vertical: 6),
//                   decoration: BoxDecoration(
//                     color: bgColor,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: const Icon(Icons.image_outlined),
//                     title: Text('${String.fromCharCode(65 + i)}. ${correction.choices[i]}'),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.volume_up),
//                       onPressed: () {
//                         // TODO: 播放該選項音檔
//                       },
//                     ),
//                   ),
//                 );
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// 3. 接著是原本的 UnitDetailPage
// class UnitDetailPage extends StatefulWidget {
//   final String date;
//   final String unitId;
//   final String roomId;
//   final String userId;
//   final AuthApiService authService;
//   final Map<String, dynamic>? recordData;
//
//   const UnitDetailPage({
//     Key? key,
//     required this.unitId,
//     required this.roomId,
//     required this.userId,
//     required this.authService,
//     required this.date,
//     this.recordData,
//   }) : super(key: key);
//
//   @override
//   State<UnitDetailPage> createState() => _UnitDetailPageState();
// }
//
// class _UnitDetailPageState extends State<UnitDetailPage> {
//   List<QuestionCorrection> corrections = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }
//
//   Future<void> fetchData() async {
//     try {
//       final questions = await widget.authService.fetchQuestions(widget.unitId);
//       final record = widget.recordData ??
//           await widget.authService.fetchRecordForUnit(widget.unitId);
//       final userAnswersList = record?['answers'] as List<dynamic>? ?? [];
//
//       final Map<int, int> userAnswers = {};
//       for (var a in userAnswersList) {
//         final raw = a['questionId'].toString();
//         final match = RegExp(r'\d+').firstMatch(raw);
//         if (match != null) {
//           final parsedId = int.parse(match.group(0)!);
//           userAnswers[parsedId] = a['selected'];
//         }
//       }
//
//       final List<QuestionCorrection> parsed = [];
//       for (var q in questions) {
//         final qidStr = q['id'].toString();
//         final match = RegExp(r'\d+').firstMatch(qidStr);
//         if (match == null) continue;
//         final qidIndex = int.parse(match.group(0)!);
//         final userAnswer = userAnswers[qidIndex];
//
//         parsed.add(QuestionCorrection(
//           question: q['title'],
//           choices: List<String>.from(q['option']),
//           correctAnswerIndex: q['ans'],
//           userAnswerIndex: userAnswer,
//           isCorrect: userAnswer != null && userAnswer == q['ans'],
//         ));
//       }
//
//       setState(() {
//         corrections = parsed;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('❌ 外層錯誤：$e');
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (corrections.isEmpty) {
//       return const Scaffold(body: Center(child: Text('無作答紀錄')));
//     }
//
//     final correctCount = corrections.where((c) => c.isCorrect).length;
//
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.unitId), centerTitle: true),
//       body: Column(
//         children: [
//           const SizedBox(height: 12),
//           Text(
//             '作答時間：${widget.date.replaceFirst("T", " ").split(".")[0]}',
//             style: const TextStyle(fontSize: 14, color: Colors.grey),
//           ),
//           const SizedBox(height: 12),
//           Text('答對題數：$correctCount / ${corrections.length}',
//               style: const TextStyle(fontSize: 16)),
//           const SizedBox(height: 12),
//           const Text('錯題訂正',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 20),
//           Expanded(
//             child: PageView.builder(
//               itemCount: corrections.length,
//               controller: PageController(viewportFraction: 0.9),
//               itemBuilder: (context, index) =>
//                   CorrectionCard(correction: corrections[index], index: index),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// lib/record/mcq_game/unit_detail_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';

/// 用於顯示單題訂正資訊
class QuestionCorrection {
  final String question;           // 題目（中文）
  final List<String> choices;      // 選項文字（中文）
  final int correctAnswerIndex;    // 正確選項索引
  final int? userAnswerIndex;      // 使用者選項索引
  final bool isCorrect;            // 是否答對

  QuestionCorrection({
    required this.question,
    required this.choices,
    required this.correctAnswerIndex,
    this.userAnswerIndex,
    required this.isCorrect,
  });
}

/// 顯示單題訂正卡片
class CorrectionCard extends StatelessWidget {
  final QuestionCorrection correction;
  final int index;

  const CorrectionCard({
    Key? key,
    required this.correction,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 題號
            Text(
              '第 ${index + 1} 題',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 題目本尊（中文）
            Text(
              '「${correction.question}」',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // 顯示所有選項
            Column(
              children: List.generate(correction.choices.length, (i) {
                final isCorrect = i == correction.correctAnswerIndex;
                final isPicked = i == correction.userAnswerIndex;
                Color bgColor;
                if (isCorrect && isPicked) {
                  bgColor = Colors.green.withOpacity(0.9);
                } else if (isCorrect) {
                  bgColor = Colors.green.withOpacity(0.2);
                } else if (isPicked) {
                  bgColor = Colors.red.withOpacity(0.2);
                } else {
                  bgColor = Colors.grey.withOpacity(0.1);
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Text(
                      '${String.fromCharCode(65 + i)}.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCorrect
                            ? AppColors.primary
                            : Colors.black87,
                      ),
                    ),
                    title: Text(correction.choices[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () {
                        // TODO: 播放該選項音檔（如果有）
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

/// 單元詳情頁 (顯示單元摘要與錯題訂正)
class UnitDetailPage extends StatefulWidget {
  final String date;
  final String unitId;
  final String roomId;
  final String userId;
  final AuthApiService authService;
  final Map<String, dynamic>? recordData; // 從上一頁傳入的紀錄資料

  const UnitDetailPage({
    Key? key,
    required this.unitId,
    required this.roomId,
    required this.userId,
    required this.authService,
    required this.date,
    this.recordData,
  }) : super(key: key);

  @override
  State<UnitDetailPage> createState() => _UnitDetailPageState();
}

class _UnitDetailPageState extends State<UnitDetailPage> {
  List<QuestionCorrection> corrections = [];
  bool isLoading = true;

  String topic = ''; // 顯示主題 (從 recordData 或 API 拿)
  late DateTime answeredAt; // 作答日期
  int correctCount = 0;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  /// 取得題目與使用者作答，並解析錯題
  Future<void> fetchData() async {
    try {
      // 1. 先取得所有「選擇題」題目清單（MCQ）
      final questions = await widget.authService.fetchQuestions(widget.unitId);
      // 確認 questions 裡每筆都包含 id/title/option/ans 等欄位：
      //   [{ "id":"q01", "title":"…", "option":["…","…","…","…"], "ans":0, …}, …]

      // 2. 取得該單元的作答紀錄
      final record = widget.recordData ??
          await widget.authService.fetchRecordForUnit(widget.unitId);

      // 3. 取出題目主題與作答時間
      if (record != null && record.containsKey('topic')) {
        topic = record['topic'];
      } else {
        topic = '未提供主題';
      }
      answeredAt = DateTime.parse(widget.date);

      // 4. 解析使用者答案清單 (假設 record['answers'] 是 List of {questionId, selected})
      final userAnswersList = record?['answers'] as List<dynamic>? ?? [];
      final Map<int, int> userAnswers = {};
      for (var a in userAnswersList) {
        // a['questionId'] 可能像 "q01"、"q02"……我們只取數字部分作為索引
        final raw = a['questionId'].toString();
        final match = RegExp(r'\d+').firstMatch(raw);
        if (match != null) {
          final parsedId = int.parse(match.group(0)!);
          userAnswers[parsedId] = a['selected'] as int;
        }
      }

      // 5. 逐題比對，組成 corrections 列表
      final List<QuestionCorrection> parsed = [];
      for (var q in questions) {
        // 這裡取 q['id'] 裡的數字部分當作索引
        final qidStr = q['id'].toString();           // e.g. "q01"
        final match = RegExp(r'\d+').firstMatch(qidStr);
        if (match == null) continue;
        final qidIndex = int.parse(match.group(0)!);  // 1

        final userAnswer = userAnswers[qidIndex];

        // MCQ JSON 每筆至少要有：
        //   "title": "…", "option": [ "…","…","…","…" ], "ans": 0
        parsed.add(QuestionCorrection(
          question: q['title'] as String,
          choices: List<String>.from(q['option'] as List<dynamic>),
          correctAnswerIndex: q['ans'] as int,
          userAnswerIndex: userAnswer as int?,
          isCorrect: userAnswer != null && userAnswer == (q['ans'] as int),
        ));
      }

      // 6. 計算總題數與答對題數
      correctCount = parsed.where((c) => c.isCorrect).length;
      totalCount = parsed.length;

      setState(() {
        corrections = parsed;
        isLoading = false;
      });
    } catch (e) {
      print('❌ 資料取得失敗：$e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 若 corrections 為空，代表「沒有任何錯誤題目」或是「完全沒作答」，顯示全對文案
    if (corrections.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          centerTitle: true,
          title: Text(
            widget.unitId,
            style: const TextStyle(color: Colors.black87, fontSize: 20),
          ),
        ),
        body: const Center(child: Text('全部答對，沒有錯題訂正！')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. 自訂 Header：返回鍵 + 標題 + 羅馬
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 28),
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '選擇題紀錄',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'suán-tik-tē kì-lōk',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 28),
                ],
              ),
            ),

            // ── 2. 單元資訊卡片：單元、主題、日期
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 左側：單元 & 主題
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.unitId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '主題：$topic',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    // 右側：日期
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${answeredAt.year.toString().padLeft(4, '0')}/'
                              '${answeredAt.month.toString().padLeft(2, '0')}/'
                              '${answeredAt.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── 3. 答對題數
            Text(
              '答對題數：$correctCount / $totalCount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 12),

            // ── 4. 錯題訂正標題
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '錯題訂正',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 5. PageView 呈現每張訂正卡片
            Expanded(
              child: PageView.builder(
                itemCount: corrections.length,
                controller: PageController(viewportFraction: 0.9),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CorrectionCard(
                      correction: corrections[index],
                      index: index,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}