// // lib/pages/home_page.dart
// import 'package:flutter/material.dart';
// import 'room_selection_page.dart';
// import 'game_tab.dart';
// import 'scoreboard_tab.dart';
// import 'settings_tab.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);
//
//   @override
//   State createState() => _HomePageState();
// }
//
// class _HomePageState extends State {
//   int _currentIndex = 0;
//
// // 四個分頁：首頁、遊戲、收藏、設定
//   static const List _pages = [
//     _HomeTab(),
//     GameTab(),
//     ScoreboardTab(),
//     SettingsTab(),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('教學平台'),
//       ),
//       body: _pages[_currentIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (idx) => setState(() => _currentIndex = idx),
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: Colors.blueAccent,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
//           BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: '小遊戲'),
//           BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '積分榜'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
//         ],
//       ),
//     );
//   }
// }
//
// class _HomeTab extends StatelessWidget {
//   const _HomeTab();
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.all(16.0),
//       children: [
// // 課程資訊卡片
//         Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           elevation: 2,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: const [
//                 Text('課程資訊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 SizedBox(height: 8),
//                 Text('這裡顯示課程說明等資訊。'),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
// // 學習進度卡片
//         Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           elevation: 2,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('學習進度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//                 LinearProgressIndicator(value: 0.1),
//                 const SizedBox(height: 8),
//                 const Text('已完成 1 / 10 單元'),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
// // 從首頁改為先選房間
//         GestureDetector(
//           onTap: () {
//             final bool isTeacher = false;
//             Navigator.pushNamed(
//               context,
//               '/roomSelection',
//               arguments: isTeacher,
//             );
//           },
//           child: Card(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             elevation: 2,
//             child: ListTile(
//               title: const Text('單元一'),
//               subtitle: const Text('選擇題小遊戲'),
//               trailing: const Icon(Icons.chevron_right),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//

// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_tab.dart';
import 'scoreboard_tab.dart';
import 'settings_tab.dart';
import '../MCQ_Game/room_selection_page.dart';
import 'profile_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1️⃣ 全局 ScaffoldKey
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  static final List<Widget> _pages = [
    _HomeTab(),
    GameTab(),
    ScoreboardTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ProfileDrawer(),
      appBar: AppBar(
        // 2️⃣ 根據分頁切換標題
        title: _currentIndex == 1
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Taiwanese',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Little Games',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        )
            : const Text('教學平台'),
        centerTitle: true,
        elevation: 0,
        // 3️⃣ 全頁面顯示漢堡選單
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        // 只在小遊戲分頁 顯示右上角「個人」按鈕
        actions: _currentIndex == 1
            ? [
          IconButton(
            onPressed: () => _scaffoldKey.currentState!.openDrawer(),
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ),
        ]
            : null,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: '小遊戲'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '積分榜'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 學習紀錄卡片
        Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('學習紀錄',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('您的學習狀況良好，繼續保持！'),
                SizedBox(height: 12),
                Text('選擇題遊戲',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text('平均答題正確率：80%'),
                SizedBox(height: 12),
                Text('濾鏡小遊戲',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text('總遊玩次數：20 次'),
                SizedBox(height: 16),
                LinearProgressIndicator(value: 0.5),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 上次進度卡片
        Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('上次進度',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.videogame_asset, size: 20),
                    SizedBox(width: 8),
                    Text('選擇題小遊戲 單元一'),
                    Spacer(),
                    Icon(Icons.calendar_today, size: 16),
                    SizedBox(width: 4),
                    Text('2025/04/06'),
                  ],
                ),
                const SizedBox(height: 12),
                const LinearProgressIndicator(value: 0.4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
