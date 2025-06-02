// import 'dart:math';
// import 'package:flutter/material.dart';
// import '../theme/dimens.dart';
// import '../theme/colors.dart';
// import '../widgets/progress_card.dart';
// import '../services/auth_api_service.dart';
// import '../tabs/game_tab.dart';
// import '../tabs/record.dart';
// import '../tabs/settings_tab.dart';
// import 'profile_drawer.dart';
//
// class HomePage extends StatefulWidget {
//   final AuthApiService authService;
//   final int initialIndex;
//
//   const HomePage({
//     Key? key,
//     required this.authService,
//     this.initialIndex = 0,
//   }) : super(key: key);
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   late int _currentIndex;
//   late List<Widget> _pages;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   static const double headerImgHeight = 380.0;
//   static const double headerImgOffsetY = 30.0;
//   static const double circleDiameter = 260.0;
//   static const double overlap = 30.0;
//   static const double cardGap = 32.0;
//   static const double starOffsetX = -10.0;
//   static const double starOffsetY = 120.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//     _pages = [
//       GameTab(),
//       RecordTab(authService: widget.authService),
//       SettingsTab(authService: widget.authService),
//     ];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final sw = MediaQuery.of(context).size.width;
//     final whiteTop = headerImgOffsetY + headerImgHeight - overlap;
//     return Scaffold(
//       key: _scaffoldKey,
//       endDrawer: ProfileDrawer(authService: widget.authService),
//       backgroundColor: AppColors.primary,
//       body: _currentIndex == 0
//           ? _buildHomeStack(sw, whiteTop)
//           : _pages[_currentIndex - 1],
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         currentIndex: _currentIndex,
//         onTap: (i) => setState(() => _currentIndex = i),
//         backgroundColor: Colors.white,
//         showSelectedLabels: false,
//         showUnselectedLabels: false,
//         items: [
//           BottomNavigationBarItem(
//             icon: Image.asset('assets/icon/home_off.png', width: 24, height: 24),
//             activeIcon: Image.asset('assets/icon/home_on.png', width: 24, height: 24),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             icon: Image.asset('assets/icon/game_off.png', width: 24, height: 24),
//             activeIcon: Image.asset('assets/icon/game_on.png', width: 24, height: 24),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             icon: Image.asset('assets/icon/record_off.png', width: 24, height: 24),
//             activeIcon: Image.asset('assets/icon/record_on.png', width: 24, height: 24),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             icon: Image.asset('assets/icon/settings_off.png', width: 24, height: 24),
//             activeIcon: Image.asset('assets/icon/settings_on.png', width: 24, height: 24),
//             label: '',
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHomeStack(double sw, double whiteTop) {
//     return Stack(
//       children: [
//         Positioned(
//           top: headerImgOffsetY,
//           left: 0,
//           right: 0,
//           child: Image.asset('assets/images/lobby.png', height: headerImgHeight, fit: BoxFit.cover),
//         ),
//         Positioned(
//           top: whiteTop,
//           left: 0,
//           right: 0,
//           bottom: 0,
//           child: Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//             ),
//           ),
//         ),
//         Positioned(
//           top: headerImgOffsetY + headerImgHeight / 2,
//           left: (sw - circleDiameter) / 2,
//           child: CustomPaint(
//             size: Size(circleDiameter, circleDiameter),
//             painter: _PieChartPainter(),
//           ),
//         ),
//         Positioned(
//           top: whiteTop + circleDiameter / 2 + cardGap,
//           left: 60,
//           right: 60,
//           child: _buildProgressCard(),
//         ),
//         Positioned(
//           top: whiteTop + circleDiameter / 2 + cardGap + starOffsetY,
//           right: 16 + starOffsetX,
//           child: Image.asset('assets/images/star.png', width: 100, height: 100),
//         ),
//         Positioned(
//           top: headerImgOffsetY + 66,
//           right: 36,
//           child: GestureDetector(
//             onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
//             child: Image.asset('assets/icon/profile.png', width: 32, height: 32),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildProgressCard() {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(Dimens.radiusCard),
//             boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('上次進度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               Row(children: const [
//                 Text('選擇題遊戲', style: TextStyle(fontSize: 14)),
//                 SizedBox(width: 20),
//                 Text('單元一', style: TextStyle(fontSize: 12, color: AppColors.grey700)),
//                 Spacer(),
//                 Icon(Icons.calendar_today, size: 14, color: AppColors.grey700),
//                 SizedBox(width: 8),
//                 Text('2025/04/06', style: TextStyle(fontSize: 12)),
//               ]),
//               const SizedBox(height: 16),
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(4),
//                 child: Container(
//                   height: 6,
//                   color: AppColors.grey300,
//                   child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.8, child: Container(color: AppColors.accentGreen)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Positioned(
//           bottom: -10,
//           right: 16,
//           child: PhysicalShape(
//             color: Colors.white,
//             elevation: 4,
//             shadowColor: Colors.black26,
//             clipper: _TriangleClipper(),
//             child: const SizedBox(width: 24, height: 12),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _TriangleClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     return Path()..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width / 2, size.height)..close();
//   }
//
//   @override
//   bool shouldReclip(covariant CustomClipper<Path> old) => false;
// }
//
// class _PieChartPainter extends CustomPainter {
//   @override
//   void paint(Canvas c, Size s) {
//     final center = Offset(s.width / 2, s.height / 2);
//     final radius = s.width / 2;
//     final paint = Paint()..style = PaintingStyle.fill;
//     final segments = [
//       {'label': '選擇題遊戲', 'value': 0.35, 'color': AppColors.primaryLight},
//       {'label': '濾鏡遊戲', 'value': 0.25, 'color': AppColors.primaryTint},
//       {'label': '誰是臥底', 'value': 0.40, 'color': AppColors.accentGold},
//     ];
//     double startAngle = -pi / 2;
//     const textStyle = TextStyle(fontSize: 14, color: AppColors.grey700);
//
//     for (var seg in segments) {
//       final sweep = 2 * pi * (seg['value'] as double);
//       paint.color = seg['color'] as Color;
//       c.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, paint);
//
//       // Draw label
//       final labelAngle = startAngle + sweep / 2;
//       final labelRadius = radius * 0.7;
//       final dx = center.dx + cos(labelAngle) * labelRadius;
//       final dy = center.dy + sin(labelAngle) * labelRadius;
//       final tp = TextPainter(
//         text: TextSpan(text: seg['label'] as String, style: textStyle),
//         textDirection: TextDirection.ltr,
//       )..layout();
//       tp.paint(c, Offset(dx - tp.width / 2, dy - tp.height / 2));
//
//       startAngle += sweep;
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter old) => false;
// }

import 'package:flutter/material.dart';
import '../theme/dimens.dart';
import '../theme/colors.dart';
import '../widgets/progress_card.dart'; // 如果有其他共用組件，可自行移除
import '../services/auth_api_service.dart';
import '../tabs/game_tab.dart';
import '../tabs/record.dart';
import '../tabs/settings_tab.dart';
import 'profile_drawer.dart';

// 注意：原本有使用到 dart:math 的地方已經移除，這裡不需要
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

  // 以下數值和第一張圖對齊：header 圖片高度、白底開始位置等
  static const double headerImgHeight = 380.0;
  static const double headerImgOffsetY = 30.0;
  static const double overlap = 30.0;

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
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    // whiteTop 為白底 Container 的 Y 座標 (headerImgOffsetY + headerImgHeight - overlap)
    final whiteTop = headerImgOffsetY + headerImgHeight - overlap;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: ProfileDrawer(authService: widget.authService),
      backgroundColor: AppColors.primary,
      body: _currentIndex == 0
          ? _buildHomeStack(sw, whiteTop)
          : _pages[_currentIndex - 1],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icon/home_off.png', width: 24, height: 24),
            activeIcon: Image.asset('assets/icon/home_on.png', width: 24, height: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icon/game_off.png', width: 24, height: 24),
            activeIcon: Image.asset('assets/icon/game_on.png', width: 24, height: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icon/record_off.png', width: 24, height: 24),
            activeIcon: Image.asset('assets/icon/record_on.png', width: 24, height: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icon/settings_off.png', width: 24, height: 24),
            activeIcon: Image.asset('assets/icon/settings_on.png', width: 24, height: 24),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeStack(double sw, double whiteTop) {
    return Stack(
      children: [
        // 1. 頂部綠色區塊：六顆豆豆的背景圖
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

        // 2. 白底 Container，與綠色區塊無縫銜接
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

        // 3. 右上角小頭像 (點擊打開 Drawer)
        Positioned(
          top: headerImgOffsetY + 66,
          right: 36,
          child: GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Image.asset(
              'assets/icon/profile.png',
              width: 32,
              height: 32,
            ),
          ),
        ),

        // 4. 調整後的「上次進度」卡片：往上偏移 80，使其重疊到綠色 Header
        Positioned(
          // 原本是 whiteTop + 24，現在改成往上 80
          top: whiteTop - 150,
          left: 16,
          right: 16,
          child: _buildProgressCard(),
        ),
      ],
    );
  }

  /// 此方法回傳一個 Stack，內含白色卡片、卡片底部三角形指向器，以及卡片下方的星星圖示。
  Widget _buildProgressCard() {
    return SizedBox(
      height: 400, // ← 你想要的「卡片總高度」，單位是像素 (px)
      child: Stack(
          clipBehavior: Clip.none,
          children: [
          // ====== 卡片本體 ======
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Dimens.radiusCard),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 卡片標題：上次進度
                const Text(
                  '上次進度',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // 2. 第一筆：選擇題遊戲
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 左側：標題 + 羅馬拼音
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '選擇題',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'suán-tik-tè',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // 右側：單元一 + 日期
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          '單元一',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppColors.grey700,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '2025/05/15',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 進度條 (第一筆進度為 80%) → FractionallySizedBox(widthFactor: 0.8)
                // 用一個灰色底當軌道
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // 1) 在背景灰色上放一個 PhysicalModel（負責陰影＋綠色）
                      //    要注意 PhysicalModel 的大小就是“進度條本身”大小
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.8, // 填滿 80%
                          child: PhysicalModel(
                            color: Colors.transparent,         // 本體透明
                            elevation: 4,                      // 陰影深度，可微調
                            shadowColor: Colors.black26,       // 陰影顏色
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 2) 底下灰色的圓角軌道已經在 Container 裡，不需要再 ClipRRect
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 3. 第二筆：練說話
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '練說話',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'liàn kóng-uē',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          '單元一',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppColors.grey700,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '2025/05/15',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 進度條 (第二筆進度為 70%) → widthFactor: 0.7
                // 用一個灰色底當軌道
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // 1) 在背景灰色上放一個 PhysicalModel（負責陰影＋綠色）
                      //    要注意 PhysicalModel 的大小就是“進度條本身”大小
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.5, // 填滿 80%
                          child: PhysicalModel(
                            color: Colors.transparent,         // 本體透明
                            elevation: 4,                      // 陰影深度，可微調
                            shadowColor: Colors.black26,       // 陰影顏色
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 2) 底下灰色的圓角軌道已經在 Container 裡，不需要再 ClipRRect
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 4. 第三筆：來聊天
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '來聊天',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'lâi khai-káng',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          '單元一',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppColors.grey700,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '2025/05/15',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 進度條 (第三筆進度為 50%) → widthFactor: 0.5
                // 用一個灰色底當軌道
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // 1) 在背景灰色上放一個 PhysicalModel（負責陰影＋綠色）
                      //    要注意 PhysicalModel 的大小就是“進度條本身”大小
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.3, // 填滿 80%
                          child: PhysicalModel(
                            color: Colors.transparent,         // 本體透明
                            elevation: 4,                      // 陰影深度，可微調
                            shadowColor: Colors.black26,       // 陰影顏色
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 2) 底下灰色的圓角軌道已經在 Container 裡，不需要再 ClipRRect
                    ],
                  ),
                ),
    const Spacer(),
              ],
            ),
          ),

          // ====== 卡片底部小三角形指向器 ======
          Positioned(
            bottom: -10, // 三角形高 12, 底部往下 10
            right: 16,   // 與右側邊距對齊
            child: PhysicalShape(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black26,
              clipper: _TriangleClipper(),
              child: const SizedBox(width: 24, height: 12),
            ),
          ),

          // ====== 卡片底下的星星圖案 ======
          Positioned(
            // 星星本身高度 100，pointer tip 在卡片底部向下 2 px (12 - 10 = 2)
            // 因此要讓星星的「頂端」剛好接在 pointer tip，就必須設定 bottom: -(星星高度 + 2) = -102
            bottom: -102,
            right: 16,
            child: Image.asset(
              'assets/images/star.png',
              width: 100,
              height: 100,
            ),
          ),
        ],
      )
    );
  }
}

/// 小三角形用來接在卡片底部，指向星星
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