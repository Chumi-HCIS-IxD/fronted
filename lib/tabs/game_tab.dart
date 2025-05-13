// // lib/tabs/game_tab.dart
//
// import 'package:flutter/material.dart';
// import '../services/auth_api_service.dart';
// import '../MCQ_Game/room_selection_page.dart';
//
// class GameTab extends StatefulWidget {
//   final AuthApiService authService;
//   const GameTab({Key? key, required this.authService}) : super(key: key);
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
//       _filteredGames = _games
//           .where((g) => g.toLowerCase().contains(kw))
//           .toList();
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
//                     // 跳到 RoomSelectionPage
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => RoomSelectionPage(
//                           authService: widget.authService,
//                         ),
//                       ),
//                     );
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('$title 尚未開放')),
//                     );
//                   }
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 6),
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 14),
//                   decoration: BoxDecoration(
//                     color: selected
//                         ? Colors.grey.shade200
//                         : Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     boxShadow: [
//                       BoxShadow(
//                           color: Colors.black.withOpacity(0.02),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2)),
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
//                           child: Text(title,
//                               style: const TextStyle(fontSize: 16))),
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
import '../games/MCQ_Game/room_selection_page.dart';

class GameTab extends StatefulWidget {
  const GameTab({Key? key}) : super(key: key);

  @override
  State<GameTab> createState() => _GameTabState();
}

class _GameTabState extends State<GameTab> {
  final List<String> _games = [
    '選擇題小遊戲',
    '濾鏡小遊戲',
    '誰是臥底',
    '其他小遊戲',
  ];
  int _selectedIndex = -1;
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _filteredGames = [];

  @override
  void initState() {
    super.initState();
    _filteredGames = List.from(_games);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final kw = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredGames = _games.where((g) => g.toLowerCase().contains(kw)).toList();
      if (_selectedIndex >= 0 &&
          !_filteredGames.contains(_games[_selectedIndex])) {
        _selectedIndex = -1;
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜尋欄
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '搜尋遊戲',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // 遊戲列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _filteredGames.length,
            itemBuilder: (ctx, idx) {
              final title = _filteredGames[idx];
              final originalIndex = _games.indexOf(title);
              final selected = originalIndex == _selectedIndex;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = originalIndex);
                  if (originalIndex == 0) {
                    // 跳到選擇題房間列表
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoomSelectionPage(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$title 尚未開放')),
                    );
                  }
                },
                child: Container(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? Colors.grey.shade200 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.videogame_asset,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(fontSize: 16)),
                      ),
                      const Icon(Icons.headset, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
