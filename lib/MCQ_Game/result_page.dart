// // lib/pages/result_page.dart
// import 'package:flutter/material.dart';
//
// class ResultPage extends StatelessWidget {
//   const ResultPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
// // 從路由取得分數與最大題數
//     final args = ModalRoute
//         .of(context)!
//         .settings
//         .arguments as Map;
//     final int yourScore = args['score'] as int;
//     final int maxScore = args['max'] as int;
//     // 範例排行資料，實際可從後端取得
//     final ranking = [
//       {'name': '王順仁', 'score': 9},
//       {'name': '學生A', 'score': 8},
//       {'name': '學生B', 'score': 7},
//       {'name': '學生C', 'score': 6},
//       {'name': '你', 'score': yourScore},
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('結算'),
//         centerTitle: true,
//         leading: BackButton(onPressed: () => Navigator.pop(context)),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // 分數摘要
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//               color: Colors.blue[50],
//               child: Text(
//                 '你的分數：$yourScore / $maxScore',
//                 style: const TextStyle(
//                     fontSize: 20, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 12),
//             // 排行列表
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: ranking.length,
//                 itemBuilder: (ctx, idx) {
//                   final entry = ranking[idx];
//                   Color medalColor;
//                   if (idx == 0)
//                     medalColor = Colors.amber;
//                   else if (idx == 1)
//                     medalColor = Colors.grey;
//                   else if (idx == 2)
//                     medalColor = Colors.brown;
//                   else
//                     medalColor = Colors.grey[400]!;
//
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 8),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.02),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         CircleAvatar(
//                           radius: 16,
//                           backgroundColor: medalColor,
//                           child: Text('${idx + 1}',
//                               style: const TextStyle(color: Colors.white)),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             entry['name'] as String,
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                         ),
//                         Text(
//                           '${entry['score']} 分',
//                           style: const TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.w500),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//             // 返回首頁按鈕
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 48,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.pushNamedAndRemoveUntil(
//                       context,
//                       '/home',
//                           (route) => false,
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text('返回首頁', style: TextStyle(fontSize: 16)),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       // 如需底部導航，可取消註解
//       // bottomNavigationBar: BottomNavigationBar(
//       //   currentIndex: 1,
//       //   type: BottomNavigationBarType.fixed,
//       //   items: const [
//       //     BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
//       //     BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: '遊戲'),
//       //     BottomNavigationBarItem(icon: Icon(Icons.star), label: '收藏'),
//       //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
//       //   ],
//       //   onTap: (_) {},
//       // ),
//     );
//   }}

// lib/MCQ_Game/result_page.dart
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final int max;
  const ResultPage({Key? key, required this.score, required this.max}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 範例排行資料，可改為從後端拿
    final ranking = [
      {'name': '王順仁', 'score': 9},
      {'name': '學生A', 'score': 8},
      {'name': '學生B', 'score': 7},
      {'name': '學生C', 'score': 6},
      {'name': '你', 'score': score},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('結算'),
        centerTitle: true,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: Colors.blue[50],
              child: Text(
                '你的分數：$score / $max',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ranking.length,
                itemBuilder: (_, idx) {
                  final entry = ranking[idx];
                  Color medalColor;
                  if (idx == 0)
                    medalColor = Colors.amber;
                  else if (idx == 1)
                    medalColor = Colors.grey;
                  else if (idx == 2)
                    medalColor = Colors.brown;
                  else
                    medalColor = Colors.grey[400]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: medalColor,
                          child: Text('${idx + 1}', style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry['name'] as String, style: const TextStyle(fontSize: 16))),
                        Text('${entry['score']} 分', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // 把所有中間頁面都 pop 掉，回到最初的 HomePage
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('返回首頁', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}