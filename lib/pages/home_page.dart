import 'package:flutter/material.dart';
import 'profile_drawer.dart';
import '../widgets/course_info_card.dart';
import '../widgets/progress_card.dart';
import '../services/auth_api_service.dart';
import '../tabs/game_tab.dart';
// import 'tabs/favorites_tab.dart';
// import 'tabs/settings_tab.dart';

class HomePage extends StatefulWidget {
  final AuthApiService authService;

  const HomePage({super.key, required this.authService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  final List<Widget> _pages =  [
     GameTab(),
  //   FavoritesTab(),
  //   SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: ProfileDrawer(authService: widget.authService),
      appBar: AppBar(
        title: const Text("教學平台"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          )
        ],
      ),
      body: _currentIndex == 0
          ? ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          CourseInfoCard(),
          SizedBox(height: 16),
          ProgressCard(),
        ],
      )
          : _pages[_currentIndex - 1],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(
              icon: Icon(Icons.videogame_asset), label: '小遊戲'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: '收藏'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
