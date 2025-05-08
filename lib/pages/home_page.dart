import 'package:flutter/material.dart';
import 'profile_drawer.dart';
import '../widgets/course_info_card.dart';
import '../widgets/progress_card.dart';
import '../services/auth_api_service.dart';
import '../tabs/game_tab.dart';
import '../tabs/record.dart';
import '../tabs/settings_tab.dart';
import '../MCQ_Game/api.dart';

class HomePage extends StatefulWidget {
  final AuthApiService authService;

  const HomePage({super.key, required this.authService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthApiService(baseUrl: baseUrl);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  late List<Widget> _pages;
  // final List<Widget> _pages = [
  //   GameTab(),
  //   //   FavoritesTab(),
  //   //   SettingsTab(),
  // ];

  final List<String> _titles = const ['小遊戲', '積分榜', '設定'];

  @override
  void initState() {
    super.initState();
    _pages = [
      GameTab(),
      RecordTab(authService: _authService),
      SettingsTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: ProfileDrawer(authService: widget.authService),
      backgroundColor: const Color(0xFFE5E5E5),
      body: Column(
        children: [
          // 這一整塊是「自製的AppBar」
          Container(
            color: Colors.grey.shade200,
            padding:
                const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左上角什麼都不要（或放回上一頁 icon也行）
                const SizedBox(width: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    Text(
                      _currentIndex == 0 ? "首頁" : _titles[_currentIndex - 1],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                // 右邊帳號按鈕
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined,
                      size: 32, color: Colors.black54),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ],
            ),
          ),
          // 下面才是內容
          Expanded(
            child: _currentIndex == 0
                ? _buildHomeContent()
                : Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: _pages[_currentIndex - 1],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.grey.shade200,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(
              icon: Icon(Icons.videogame_asset), label: '小遊戲'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: '積分榜'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Container(
      color: Colors.grey.shade200, // 整個背景是灰色
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250, // 背景區域更高
              child: Center(
                child: Icon(Icons.image, size: 120, color: Colors.grey), // 圖片更大
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: const [
                    CourseInfoCard(),
                    SizedBox(height: 16),
                    ProgressCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
