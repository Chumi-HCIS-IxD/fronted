// import 'package:flutter/material.dart';
// import '../record/mcq_game/unit_selection_page.dart';
// import '../../services/auth_api_service.dart';
// import '../record/filtered_game/unit_selection_page.dart';
//
// class RecordTab extends StatelessWidget {
//   final AuthApiService authService;
//
//   RecordTab({super.key, required this.authService}) {
//     _gameRoutes = {
//       "選擇題小遊戲": () => UnitSelectionPage(authService: authService),
//       "濾鏡小遊戲": () => Filter_UnitSelectionPage(authService: authService),
//     };
//   }
//
//   final List<Map<String, String>> _games = const [
//     {"title": "選擇題小遊戲"},
//     {"title": "濾鏡小遊戲"},
//     {"title": "誰是臥底"},
//     {"title": "小遊戲"},
//   ];
//
//   late final Map<String, Widget Function()> _gameRoutes;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFEAEAEA),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 10),
//               Container(
//                 width: double.infinity,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: const [
//                     Icon(Icons.image_outlined, size: 50, color: Colors.grey),
//                     SizedBox(width: 24),
//                     Text(
//                       "複習自己的學習內容！",
//                       style: TextStyle(fontSize: 16, color: Colors.black54),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   child: ListView.builder(
//                     itemCount: _games.length,
//                     itemBuilder: (context, index) {
//                       final game = _games[index];
//                       final title = game["title"] ?? '';
//                       return _buildGameItem(context, title);
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildGameItem(BuildContext context, String title) {
//     return InkWell(
//       onTap: () {
//         if (_gameRoutes.containsKey(title)) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => _gameRoutes[title]!()),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('$title 尚未開放')),
//           );
//         }
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Row(
//           children: [
//             const CircleAvatar(
//               backgroundColor: Color(0xFFEAEAEA),
//               child: Icon(Icons.image_outlined, color: Colors.black54),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.black87,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
//           ],
//         ),
//       ),
//     );
//   }
// }

// lib/pages/record_tab.dart
import 'package:flutter/material.dart';
import '../record/mcq_game/unit_selection_page.dart';
import '../../services/auth_api_service.dart';
import '../record/filtered_game/unit_selection_page.dart';
import '../theme/colors.dart';

class RecordTab extends StatelessWidget {
  final AuthApiService authService;
  late final Map<String, Widget Function()> _gameRoutes;

  RecordTab({Key? key, required this.authService}) : super(key: key) {
    _gameRoutes = {
      "選擇題": () => UnitSelectionPage(authService: authService),
      "練說話": () => Filter_UnitSelectionPage(authService: authService),
      // "來聊天": () => /* TODO: ChatPage(authService) */,
    };
  }

  final List<Map<String, String>> _cards = const [
    {
      'title': '選擇題',
      'subtitle': 'suán-tik-tê',
      'asset': 'assets/images/mcq.png'
    },
    {
      'title': '練說話',
      'subtitle': 'liân-kóng-uē',
      'asset': 'assets/images/speak.png'
    },
    {
      'title': '來聊天',
      'subtitle': 'lâi-khai-káng',
      'asset': 'assets/images/chat.png'
    },
  ];

  static const _mintGreen = AppColors.primaryTint;
  static const _deepGreen = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header 圖 + 疊字
            Stack(
              children: [
                Image.asset(
                  'assets/images/record_header.png',
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
                // 標題疊在右上
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        '學習進度紀錄',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _deepGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'hak-sip-tshin-tōo ki-lōk',
                        style: TextStyle(fontSize: 14, color: _deepGreen),
                      ),
                    ],
                  ),
                ),
                // 副標題疊在右下
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: const Text(
                    '「複習自己的學習內容！」',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),

            // ── Mint-green 主體
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _mintGreen,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: List.generate(_cards.length, (i) {
                    final card = _cards[i];
                    return GestureDetector(
                      onTap: () {
                        final key = card['title']!;
                        if (_gameRoutes.containsKey(key)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => _gameRoutes[key]!()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$key 尚未開放')));
                        }
                      },
                      child: Container(
                        height: 80,
                        margin: EdgeInsets.only(
                            bottom: i == _cards.length - 1 ? 0 : 16),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(card['asset']!),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              // blurRadius: 6,
                              // offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Text(
                              //   card['title']!,
                              //   style: const TextStyle(
                              //     color: _deepGreen,
                              //     fontSize: 18,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                              // const SizedBox(height: 4),
                              // Text(
                              //   card['subtitle']!,
                              //   style: const TextStyle(
                              //     color: _deepGreen,
                              //     fontSize: 14,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}