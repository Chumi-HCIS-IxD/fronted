// // lib/pages/record_tab.dart
// import 'package:flutter/material.dart';
// import '../record/mcq_game/unit_selection_page.dart';
// import '../../services/auth_api_service.dart';
// import '../record/filtered_game/unit_selection_page.dart';
// import '../theme/colors.dart';
//
// class RecordTab extends StatelessWidget {
//   final AuthApiService authService;
//   late final Map<String, Widget Function()> _gameRoutes;
//
//   RecordTab({Key? key, required this.authService}) : super(key: key) {
//     _gameRoutes = {
//       "選擇題": () => UnitSelectionPage(authService: authService),
//       "練說話": () => Filter_UnitSelectionPage(authService: authService),
//       // "來聊天": () => /* TODO: ChatPage(authService) */,
//     };
//   }
//
//   final List<Map<String, String>> _cards = const [
//     {
//       'title': '選擇題',
//       'subtitle': 'suán-tik-tê',
//       'asset': 'assets/images/mcq.png'
//     },
//     {
//       'title': '練說話',
//       'subtitle': 'liân-kóng-uē',
//       'asset': 'assets/images/speak.png'
//     },
//     {
//       'title': '來聊天',
//       'subtitle': 'lâi-khai-káng',
//       'asset': 'assets/images/Chat_Game.png'
//     },
//   ];
//
//   static const _mintGreen = AppColors.primaryTint;
//   static const _deepGreen = AppColors.primary;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // ── Header 圖 + 疊字
//             Stack(
//               children: [
//                 Image.asset(
//                   'assets/images/record_header.png',
//                   width: double.infinity,
//                   height: 250,
//                   fit: BoxFit.cover,
//                 ),
//                 // 標題疊在右上
//                 Positioned(
//                   top: 16,
//                   right: 16,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: const [
//                       Text(
//                         '學習進度紀錄',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: _deepGreen,
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         'hak-sip-tshin-tōo ki-lōk',
//                         style: TextStyle(fontSize: 14, color: _deepGreen),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // 副標題疊在右下
//                 Positioned(
//                   bottom: 16,
//                   right: 16,
//                   child: const Text(
//                     '「複習自己的學習內容！」',
//                     style: TextStyle(fontSize: 16, color: Colors.black),
//                   ),
//                 ),
//               ],
//             ),
//
//             // ── Mint-green 主體
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: const BoxDecoration(
//                   color: _mintGreen,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
//                 child: Column(
//                   children: List.generate(_cards.length, (i) {
//                     final card = _cards[i];
//                     return GestureDetector(
//                       onTap: () {
//                         final key = card['title']!;
//                         if (_gameRoutes.containsKey(key)) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (_) => _gameRoutes[key]!()),
//                           );
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text('$key 尚未開放')));
//                         }
//                       },
//                       child: Container(
//                         height: 80,
//                         margin: EdgeInsets.only(
//                             bottom: i == _cards.length - 1 ? 0 : 16),
//                         decoration: BoxDecoration(
//                           image: DecorationImage(
//                             image: AssetImage(card['asset']!),
//                             fit: BoxFit.cover,
//                           ),
//                           borderRadius: BorderRadius.circular(24),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.white.withOpacity(0.5),
//                               // blurRadius: 6,
//                               // offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               // Text(
//                               //   card['title']!,
//                               //   style: const TextStyle(
//                               //     color: _deepGreen,
//                               //     fontSize: 18,
//                               //     fontWeight: FontWeight.bold,
//                               //   ),
//                               // ),
//                               // const SizedBox(height: 4),
//                               // Text(
//                               //   card['subtitle']!,
//                               //   style: const TextStyle(
//                               //     color: _deepGreen,
//                               //     fontSize: 14,
//                               //   ),
//                               // ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }),
//                 ),
//               ),
//             ),
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
  const RecordTab({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 取得螢幕寬高
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    // Header 區塊高度：設定為螢幕高度的 35%
    final headerHeight = sh * 0.35;
    // 白色卡片往上蓋住 Header 的高度 (Overlap) 約 24pt
    const double overlap = 24.0;

    // 三個卡片標題
    final List<String> titles = ['選擇題', '練說話', '來聊天'];

    // 對應羅馬拼音
    String roman(int idx) {
      switch (idx) {
        case 0:
          return 'suán-tik-tē';
        case 1:
          return 'liân-kóng-uē';
        case 2:
        default:
          return 'lâi-khai-káng';
      }
    }

    // 點擊後的路由
    void onCardTap(int idx) {
      if (idx == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnitSelectionPage(authService: authService),
          ),
        );
      } else if (idx == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Filter_UnitSelectionPage(authService: authService),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${titles[idx]} 尚未開放')),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBG, // 整體背景淺米綠
      body: Stack(
        children: [
          // 1. Header (record_header.png + 置中文字)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: Stack(
              children: [
                // (a) 底層：完整的 header 圖
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/record_header.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // (b) 中央：置中的標題 + 羅馬拼音
                Positioned(
                  top: headerHeight * 0.18, // 大約佔 header 高度的 18%
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        '學習進度紀錄',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'hak-sip-tshin-tōo ki-lōk',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. 白色大卡片容器，往上重疊 overlap 值，下面放三張子卡片
          Positioned(
            top: headerHeight - overlap,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryTint, // mint green
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 16),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: titles.length,
                  itemBuilder: (ctx, idx) {
                    return GestureDetector(
                      onTap: () => onCardTap(idx),
                      child: Container(
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white, // 子卡片純白背景
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                titles[idx],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                roman(idx),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary.withOpacity(0.75),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}