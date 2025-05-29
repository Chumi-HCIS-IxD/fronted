// // lib/tabs/game_tab.dart
//
// import 'package:flutter/material.dart';
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
//     '誰是臥底',
//     '其他小遊戲',
//   ];
//   int _selectedIndex = -1;
//   final TextEditingController _searchCtrl = TextEditingController();
//   List<String> _filteredGames = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _filteredGames = List.from(_games);
//     _searchCtrl.addListener(_onSearchChanged);
//   }
//
//   void _onSearchChanged() {
//     final kw = _searchCtrl.text.toLowerCase();
//     setState(() {
//       _filteredGames = _games.where((g) => g.toLowerCase().contains(kw)).toList();
//       if (_selectedIndex >= 0 &&
//           !_filteredGames.contains(_games[_selectedIndex])) {
//         _selectedIndex = -1;
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _searchCtrl
//       ..removeListener(_onSearchChanged)
//       ..dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // 搜尋欄
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//           child: TextField(
//             controller: _searchCtrl,
//             decoration: InputDecoration(
//               prefixIcon: const Icon(Icons.search),
//               hintText: '搜尋遊戲',
//               filled: true,
//               fillColor: Colors.white,
//               contentPadding:
//               const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(24),
//                 borderSide: BorderSide.none,
//               ),
//             ),
//           ),
//         ),
//         // 遊戲列表
//         Expanded(
//           child: ListView.builder(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             itemCount: _filteredGames.length,
//             itemBuilder: (ctx, idx) {
//               final title = _filteredGames[idx];
//               final originalIndex = _games.indexOf(title);
//               final selected = originalIndex == _selectedIndex;
//
//               return GestureDetector(
//                 onTap: () {
//                   setState(() => _selectedIndex = originalIndex);
//                   if (originalIndex == 0) {
//                     // 跳到選擇題房間列表
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const RoomSelectionPage(),
//                       ),
//                     );
//                   }
//                   else if(originalIndex == 1){
//                     // 跳到filter單元選擇列表
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => UnitSelectionPage(),
//                       ),
//                     );
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('$title 尚未開放')),
//                     );
//                   }
//                 },
//                 child: Container(
//                   margin:
//                   const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                   decoration: BoxDecoration(
//                     color: selected ? Colors.grey.shade200 : Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.02),
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade300,
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: const Icon(Icons.videogame_asset,
//                             color: Colors.white, size: 20),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(title,
//                             style: const TextStyle(fontSize: 16)),
//                       ),
//                       const Icon(Icons.headset, color: Colors.grey),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
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
  final List<String> _games = [
    '選擇題小遊戲',
    '濾鏡小遊戲',
    '來聊天',
    // '其他小遊戲',
  ];

  Widget _buildIcon(int idx) {
    if (idx == 0) {
      return Image.asset(
        'assets/images/game_peach.png',
        width: 90,
        height: 90,
        fit: BoxFit.contain,
      );
    } else if (idx == 1) {
      return Image.asset(
        'assets/images/game_star.png',
        width: 90,
        height: 90,
        fit: BoxFit.contain,
      );
    } else {
      return Icon(Icons.image, size: 50, color: AppColors.grey300);
    }
  }

  int _selectedIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _bgColor(int idx) {
    if (idx == _selectedIndex) {
      return AppColors.primaryTint;
    } else if (idx <= 1) {
      return AppColors.grey100;
    } else {
      return AppColors.grey100;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 拿到 status bar 高度
    final double topPadding = MediaQuery.of(context).padding.top;

    return SafeArea(
      top: false,
      bottom: true,
      child: Column(
        children: [
          // 手動塗滿 status bar 背景：淺綠
          Container(
            height: topPadding,
            color: AppColors.primaryBG,
          ),

          // 上方標題＋搜尋區塊
          Container(
            color: AppColors.primaryBG,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Taiwanese',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Little Games',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon:
                      Icon(Icons.search, color: AppColors.grey500),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.grey300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.grey500),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 下方遊戲列表
          Expanded(
            child: Container(
              color: AppColors.primaryBG,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _games.length,
                itemBuilder: (ctx, idx) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = idx);
                      if (idx == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RoomSelectionPage()),
                        );
                      } else if (idx == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => UnitSelectionPage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                              Text('${_games[idx]} 尚未開放')),
                        );
                      }
                    },
                    child: Container(
                      height: 88,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _bgColor(idx),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          // 圖片置中
                          Align(
                            alignment: Alignment.center,
                            child: _buildIcon(idx),
                          ),
                          // 文字貼右下
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 12, right: 16),
                              child: Text(
                                _games[idx],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.grey700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}