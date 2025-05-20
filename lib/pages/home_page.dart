// import 'package:flutter/material.dart';
// import 'profile_drawer.dart';
// import '../widgets/course_info_card.dart';
// import '../widgets/progress_card.dart';
// import '../services/auth_api_service.dart';
// import '../tabs/game_tab.dart';
// import '../tabs/record.dart';
// import '../tabs/settings_tab.dart';
// import '../games/MCQ_Game/api.dart';
//
// class HomePage extends StatefulWidget {
//   final AuthApiService authService;
//
//   // 1) 新增 initialIndex
//   final int initialIndex;
//
//   const HomePage({
//     Key? key,
//     required this.authService,
//     this.initialIndex = 0,    // 預設為 0（首頁）
//   }) : super(key: key);
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
//
// class _HomePageState extends State<HomePage> {
//   final _authService = AuthApiService(baseUrl: baseUrl);
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   late int _currentIndex;
//
//   late List<Widget> _pages;
//   // final List<Widget> _pages = [
//   //   GameTab(),
//   //   //   FavoritesTab(),
//   //   //   SettingsTab(),
//   // ];
//
//   final List<String> _titles = const ['小遊戲', '紀錄', '設定'];
//
//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//     _pages = [
//       GameTab(),
//       RecordTab(authService: _authService),
//       SettingsTab(authService: widget.authService),
//     ];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       drawer: ProfileDrawer(authService: widget.authService),
//       backgroundColor: const Color(0xFFE5E5E5),
//       body: Column(
//         children: [
//           // 這一整塊是「自製的AppBar」
//           Container(
//             color: Colors.grey.shade200,
//             padding:
//             const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // 左上角什麼都不要（或放回上一頁 icon也行）
//                 const SizedBox(width: 48),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const SizedBox(width: 12),
//                     Text(
//                       _currentIndex == 0 ? "首頁" : _titles[_currentIndex - 1],
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black54,
//                       ),
//                     ),
//                   ],
//                 ),
//                 // 右邊帳號按鈕
//                 IconButton(
//                   icon: const Icon(Icons.account_circle_outlined,
//                       size: 32, color: Colors.black54),
//                   onPressed: () {
//                     _scaffoldKey.currentState?.openDrawer();
//                   },
//                 ),
//               ],
//             ),
//           ),
//           // 下面才是內容
//           Expanded(
//             child: _currentIndex == 0
//                 ? _buildHomeContent()
//                 : Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius:
//                 BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               child: _pages[_currentIndex - 1],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//         selectedItemColor: Colors.blueAccent,
//         unselectedItemColor: Colors.grey,
//         backgroundColor: Colors.grey.shade200,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.videogame_asset), label: '小遊戲'),
//           BottomNavigationBarItem(icon: Icon(Icons.star), label: '積分榜'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHomeContent() {
//     return Container(
//       color: Colors.grey.shade200, // 整個背景是灰色
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             Container(
//               height: 250, // 背景區域更高
//               child: Center(
//                 child: Icon(Icons.image, size: 120, color: Colors.grey), // 圖片更大
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               child: Padding(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
//                 child: Column(
//                   children: const [
//                     CourseInfoCard(),
//                     SizedBox(height: 16),
//                     ProgressCard(),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/dimens.dart';
import '../theme/colors.dart';
import '../widgets/progress_card.dart';
import '../services/auth_api_service.dart';
import '../tabs/game_tab.dart';
import '../tabs/record.dart';
import '../tabs/settings_tab.dart';
import 'profile_drawer.dart';

class HomePage extends StatefulWidget {
  final AuthApiService authService;
  final int initialIndex;

  const HomePage({
    Key? key,
    required this.authService,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;
  late List<Widget> _pages;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // 設計稿常數
  static const double headerImgHeight = 380.0;
  static const double headerImgOffsetY = 30.0;
  static const double circleDiameter = 260.0;
  static const double overlap = 30.0;
  static const double cardGap = 32.0;
  static const double starOffsetX = -10.0;
  static const double starOffsetY = 120.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      GameTab(),
      RecordTab(authService: widget.authService),
      SettingsTab(authService: widget.authService),
    ];
  }

  @override
  Widget build(BuildContext ctx) {
    final sw = MediaQuery.of(ctx).size.width;
    // 白卡上緣 Y
    final whiteTop = headerImgOffsetY + headerImgHeight - overlap;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.primary,
      drawer: ProfileDrawer(authService: widget.authService),
      body: _currentIndex == 0
          ? Stack(
        children: [
          // header 圖片
          Positioned(
            top: headerImgOffsetY,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/lobby.png',
              height: headerImgHeight,
              fit: BoxFit.cover,
            ),
          ),
          // 白卡背景
          Positioned(
            top: whiteTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
          // 圓餅圖
          Positioned(
            top: headerImgOffsetY + headerImgHeight / 2,
            left: (sw - circleDiameter) / 2,
            child: CustomPaint(
              size: Size(circleDiameter, circleDiameter),
              painter: _PieChartPainter(),
            ),
          ),
          // 進度卡，窄寬度並加三角
          Positioned(
            top: whiteTop + circleDiameter / 2 + cardGap,
            left: 60,
            right: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Dimens.radiusCard),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, -2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('上次進度',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Text('選擇題遊戲', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 20),
                          Text('單元一',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.grey700)),
                          Spacer(),
                          Icon(Icons.calendar_today,
                              size: 14, color: AppColors.grey700),
                          SizedBox(width: 8),
                          Text('2025/04/06', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 6,
                          color: AppColors.grey300,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.8,
                            child:
                            Container(color: AppColors.accentGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 三角標
                Positioned(
                  bottom: -10,      // 若改大，也要微調
                  right: 16,
                  child: PhysicalShape(
                    color: Colors.white,         // 三角底色
                    elevation: 4,                // 陰影深度
                    shadowColor: Colors.black26, // 陰影顏色
                    clipper: _TriangleClipper(), // 使用 clipper 畫形狀
                    child: SizedBox(
                      width: 24,
                      height: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 星星
          Positioned(
            top: whiteTop + circleDiameter / 2 + cardGap + starOffsetY,
            right: 16 + starOffsetX,
            child: Image.asset(
              'assets/images/star.png',
              width: 100,
              height: 100,
            ),
          ),
          // AppBar icon
          Positioned(
            top: headerImgOffsetY + 30,
            right: 16,
            child: IconButton(
              icon: Image.asset(
                'assets/icon/profile.png',
                width: 32,
                height: 32,
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ],
      )
          : _pages[_currentIndex - 1],
    bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey500,
      backgroundColor: Colors.white,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/icon/home_icon.png', width: 24, height: 24),
          label: '首頁',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icon/game_icon.png', width: 24, height: 24),
          label: '小遊戲',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icon/record_icon.png', width: 24, height: 24),
          label: '積分榜',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icon/settings_icon.png', width: 24, height: 24),
          label: '設定',
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

/// 畫白色三角的小 Painter
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);
    final radius = s.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final segments = [
      {'label': '選擇題遊戲', 'value': 0.35, 'color': AppColors.primaryLight},
      {'label': '濾鏡遊戲', 'value': 0.25, 'color': AppColors.primaryTint},
      {'label': '誰是臥底', 'value': 0.4, 'color': AppColors.accentGold},
    ];

    double startAngle = -pi / 2;
    const textStyle = TextStyle(fontSize: 14, color: AppColors.grey700);

    for (var seg in segments) {
      final sweep = 2 * pi * (seg['value'] as double);
      paint.color = seg['color'] as Color;
      c.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
          sweep, true, paint);

      final labelAngle = startAngle + sweep / 2;
      final labelR = radius * 0.75;
      final lx = center.dx + cos(labelAngle) * labelR;
      final ly = center.dy + sin(labelAngle) * labelR;
      final tp = TextPainter(
        text: TextSpan(text: seg['label'] as String, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(lx - tp.width / 2, ly - tp.height / 2));
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

