// // lib/tabs/game_tab.dart
//
// import 'package:flutter/material.dart';
// import '../theme/colors.dart';
// import '../games/MCQ_Game/room_selection_page.dart';
// import '../games/filtered_game/unit_selection_page.dart';
//
// class GameTab extends StatefulWidget {
//   const GameTab({Key? key}) : super(key: key);
//
//   @override
//   State<GameTab> createState() => _GameTabState();
// }
//
// class _GameTabState extends State<GameTab> {
//   final List<String> _games = [
//     '選擇題小遊戲',
//     '濾鏡小遊戲',
//     '來聊天',
//     // '其他小遊戲',
//   ];
//
//   Widget _buildIcon(int idx) {
//     if (idx == 0) {
//       return Image.asset(
//         'assets/images/game_peach.png',
//         width: 90,
//         height: 90,
//         fit: BoxFit.contain,
//       );
//     } else if (idx == 1) {
//       return Image.asset(
//         'assets/images/game_star.png',
//         width: 90,
//         height: 90,
//         fit: BoxFit.contain,
//       );
//     } else {
//       return Icon(Icons.image, size: 50, color: AppColors.grey300);
//     }
//   }
//
//   int _selectedIndex = 0;
//   final TextEditingController _searchCtrl = TextEditingController();
//
//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     super.dispose();
//   }
//
//   Color _bgColor(int idx) {
//     if (idx == _selectedIndex) {
//       return AppColors.primaryTint;
//     } else if (idx <= 1) {
//       return AppColors.grey100;
//     } else {
//       return AppColors.grey100;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // 拿到 status bar 高度
//     final double topPadding = MediaQuery.of(context).padding.top;
//
//     return SafeArea(
//       top: false,
//       bottom: true,
//       child: Column(
//         children: [
//           // 手動塗滿 status bar 背景：淺綠
//           Container(
//             height: topPadding,
//             color: AppColors.primaryBG,
//           ),
//
//           // 上方標題＋搜尋區塊
//           Container(
//             color: AppColors.primaryBG,
//             padding: const EdgeInsets.only(bottom: 16),
//             child: Column(
//               children: [
//                 const SizedBox(height: 24),
//                 Text(
//                   'Taiwanese',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.primary,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 Text(
//                   'Little Games',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.primary,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: TextField(
//                     controller: _searchCtrl,
//                     decoration: InputDecoration(
//                       prefixIcon:
//                       Icon(Icons.search, color: AppColors.grey500),
//                       filled: true,
//                       fillColor: Colors.white,
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24),
//                         borderSide: BorderSide(color: AppColors.grey300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24),
//                         borderSide: BorderSide(color: AppColors.grey500),
//                       ),
//                       contentPadding: EdgeInsets.zero,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // 下方遊戲列表
//           Expanded(
//             child: Container(
//               color: AppColors.primaryBG,
//               child: ListView.builder(
//                 padding: const EdgeInsets.only(bottom: 16),
//                 itemCount: _games.length,
//                 itemBuilder: (ctx, idx) {
//                   return GestureDetector(
//                     onTap: () {
//                       setState(() => _selectedIndex = idx);
//                       if (idx == 0) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => RoomSelectionPage()),
//                         );
//                       } else if (idx == 1) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => UnitSelectionPage()),
//                         );
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                               content:
//                               Text('${_games[idx]} 尚未開放')),
//                         );
//                       }
//                     },
//                     child: Container(
//                       height: 88,
//                       margin: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: _bgColor(idx),
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                       child: Stack(
//                         children: [
//                           // 圖片置中
//                           Align(
//                             alignment: Alignment.center,
//                             child: _buildIcon(idx),
//                           ),
//                           // 文字貼右下
//                           Align(
//                             alignment: Alignment.bottomRight,
//                             child: Padding(
//                               padding: const EdgeInsets.only(
//                                   bottom: 12, right: 16),
//                               child: Text(
//                                 _games[idx],
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: AppColors.grey700,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// lib/tabs/game_tab.dart

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../games/MCQ_Game/room_selection_page.dart';
import '../games/filtered_game/unit_selection_page.dart';

class GameTab extends StatefulWidget {
  const GameTab({Key? key}) : super(key: key);

  @override
  State<GameTab> createState() => _GameTabState();
}

class _GameTabState extends State<GameTab> {
  // 三個遊戲選項
  final List<String> _games = [
    '選擇題',     // 卡片 1 用
    '練說話', // 卡片 2 用
    '來聊天',     // 卡片 3 用
  ];

  // 當前點擊(選中)的卡片索引
  int _selectedIndex = -1;

  // 依 idx 回傳羅馬拼音
  String _buildRoman(int idx) {
    switch (idx) {
      case 0:
        return 'suán-tik-tē';
      case 1:
        return 'liān kóng-uē';
      case 2:
      default:
        return 'lâi khai-káng';
    }
  }

  // 依 idx 回傳對應小角色圖片，並縮為 60×60
  Widget _buildIcon(int idx) {
    String path;
    switch (idx) {
      case 0:
        path = 'assets/images/game_peach.png';
        break;
      case 1:
        path = 'assets/images/game_star.png';
        break;
      case 2:
      default:
        path = 'assets/images/game_banana.png';
        break;
    }
    return Image.asset(
      path,
      width: 60,
      height: 60,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    // Header 區塊高度：大約螢幕高度的 28%，讓 papaya 圖露得多一點
    final headerHeight = sh * 0.35;
    // 白色大卡片往上重疊的距離
    const double overlap = 24.0;

    return Scaffold(
      backgroundColor: AppColors.primaryBG, // 整體背景為淺米綠
      body: Stack(
        children: [

          // 1. Header (papaya 圖 + 文字)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: Stack(
              children: [
                // (a) 背景 papaya 圖，不做任何遮罩
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/papaya_header.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // (b) 中央的「遊戲大廳」 + 羅馬拼音
                Positioned(
                  top: headerHeight * 0.18, // 大約 18% 的位置
                  left: 0,
                  right: 0,
                  child: Column(
                    children: const [
                      Text(
                        '遊戲大廳',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'iû-hi̍-tuā-thiann',
                        style: TextStyle(
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

          // 2. 白色大卡片：往上拉 overlap，讓它蓋在 header 下方
          Positioned(
            top: headerHeight - overlap,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 16),
                child: _buildSubCards(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 回傳包含三個子卡片的捲動區
  Widget _buildSubCards() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(_games.length, (idx) {
          const double cardHeight = 100.0;     // 子卡片高度 80
          const double cardRadius = 24.0;     // 子卡片圓角 16
          const double iconSize = 60.0;       // 小角色圖 60×60

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = idx;
              });
              if (idx == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RoomSelectionPage()),
                );
              } else if (idx == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UnitSelectionPage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_games[idx]} 尚未開放')),
                );
              }
            },
            child: Container(
              height: cardHeight,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white, // 子卡片純白背景
                borderRadius: BorderRadius.circular(cardRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    // 1) 文字區，用 Align 將 Column 水平+垂直都置中
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _games[idx],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildRoman(idx),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary.withOpacity(0.75),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2) 如果是第二張 (idx == 1)，把圖靠左放
                    if (idx == 1)
                      Positioned(
                        left: 0,  // 距離卡片內邊緣 0，再加上外層 Padding 16，就等於實際距離螢幕邊緣 16
                        top: (100 - 60) / 2, // 讓 60px 高的圖垂直置中於 100 高度
                        child: _buildIcon(idx),
                      ),

                    // 3) 如果是第一或第三張 (idx != 1)，把圖靠右放
                    if (idx != 1)
                      Positioned(
                        right: 0, // 距離卡片內邊緣 0，再加上外層 Padding 16，等於實際距離螢幕右邊 16
                        top: (100 - 60) / 2, // 圖垂直置中
                        child: _buildIcon(idx),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}