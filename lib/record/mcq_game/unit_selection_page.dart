// import 'package:flutter/material.dart';
// import '../../../services/auth_api_service.dart';
// import 'unit_detail_page.dart';
// import '../../../theme/colors.dart';
//
// /// 選擇題－作答紀錄選單頁
// class UnitSelectionPage extends StatefulWidget {
//   final AuthApiService authService;
//   const UnitSelectionPage({Key? key, required this.authService}) : super(key: key);
//
//   @override
//   State<UnitSelectionPage> createState() => _UnitSelectionPageState();
// }
//
// class _UnitSelectionPageState extends State<UnitSelectionPage> {
//   List<Map<String, dynamic>> recentRecords = [];
//   bool isLoading = true;
//
//   // 對應 UnitId 到顯示名稱與 icon
//   final List<String> units = const [
//     'Unit_1', 'Unit_2', 'Unit_3', 'Unit_4', 'Unit_5', 'Unit_6',
//   ];
//   final List<String> unitNames = const [
//     '單元一', '單元二', '單元三', '單元四', '單元五', '單元六',
//   ];
//   final List<String> icons = const [
//     '🍐', '🍔', '📷', '🎯', '📚', '🧠',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     widget.authService.fetchAllRecords().then((records) {
//       setState(() {
//         recentRecords = records.length <= 5
//             ? records.reversed.toList()
//             : records.sublist(records.length - 5).reversed.toList();
//         isLoading = false;
//       });
//     }).catchError((e) {
//       setState(() => isLoading = false);
//       debugPrint('抓取作答紀錄失敗：$e');
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     return Scaffold(
//       backgroundColor: AppColors.primaryLight,
//       body: Column(
//         children: [
//           // Header：背景圖 + 返回鍵 + 標題
//           Stack(
//             children: [
//               Image.asset(
//                 'assets/images/wax_apple_header.png',
//                 width: double.infinity,
//                 height: 300,
//                 fit: BoxFit.cover,
//               ),
//               SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.of(context).pop(),
//                         child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
//                       ),
//                       const Spacer(),
//                       Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: const [
//                           Text(
//                             '選擇題紀錄',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'suán-tik-tê kì-lōk',
//                             style: TextStyle(color: Colors.white, fontSize: 14),
//                           ),
//                         ],
//                       ),
//                       const Spacer(),
//                       const SizedBox(width: 30),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           // 主體區：淺綠背景 + 列表卡片
//           Expanded(
//             child: Container(
//               decoration: const BoxDecoration(
//                 color: AppColors.primaryTint,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//               child: recentRecords.isEmpty
//                   ? const Center(child: Text('目前沒有作答紀錄'))
//                   : ListView.separated(
//                 itemCount: recentRecords.length,
//                 separatorBuilder: (_, __) => const SizedBox(height: 12),
//                 itemBuilder: (ctx, idx) {
//                   final record = recentRecords[idx];
//                   final mode = record['mode'] as String;
//                   final unitIndex = units.indexOf(mode);
//                   final name = unitIndex != -1 ? unitNames[unitIndex] : mode;
//                   final icon = unitIndex != -1 ? icons[unitIndex] : '❓';
//                   final dateString = record['date'] ?? '未提供時間';
//                   return GestureDetector(
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => UnitDetailPage(
//                           unitId: mode,
//                           roomId: 'room_$mode',
//                           userId: 'anonymous',
//                           authService: widget.authService,
//                           date: dateString,
//                           recordData: record,
//                         ),
//                       ),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(24),
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           // 卡片底色
//                           Container(
//                             height: 80,
//                             color: Colors.white,
//                           ),
//                           // 淺圖裝飾（可選）
//                           // Positioned.fill(
//                           //   child: Image.asset('assets/images/card_decor.png', fit: BoxFit.cover),
//                           // ),
//                           // 內層陰影與邊框
//                           Container(
//                             height: 80,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(24),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.05),
//                                   blurRadius: 6,
//                                   offset: const Offset(0, 3),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           // ListTile 內容
//                           ListTile(
//                             leading: Text(icon, style: const TextStyle(fontSize: 32)),
//                             title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
//                             subtitle: Text(dateString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//                             trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
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

import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/auth_api_service.dart';
import '../MCQ_Game/unit_detail_page.dart';

/// 選擇題－作答紀錄選單頁
class UnitSelectionPage extends StatefulWidget {
  final AuthApiService authService;
  const UnitSelectionPage({Key? key, required this.authService}) : super(key: key);

  @override
  State<UnitSelectionPage> createState() => _UnitSelectionPageState();
}

class _UnitSelectionPageState extends State<UnitSelectionPage> {
  List<Map<String, dynamic>> recentRecords = [];
  bool isLoading = true;

  // 對應 UnitId 到顯示名稱與 icon
  final List<String> units = const [
    'Unit_1', 'Unit_2', 'Unit_3', 'Unit_4', 'Unit_5', 'Unit_6',
  ];
  final List<String> unitNames = const [
    '單元一', '單元二', '單元三', '單元四', '單元五', '單元六',
  ];
  final List<String> icons = const [
    '🍐', '🍔', '📷', '🎯', '📚', '🧠',
  ];

  @override
  void initState() {
    super.initState();
    widget.authService.fetchAllRecords().then((records) {
      setState(() {
        recentRecords = records.length <= 5
            ? records.reversed.toList()
            : records.sublist(records.length - 5).reversed.toList();
        isLoading = false;
      });
    }).catchError((e) {
      setState(() => isLoading = false);
      debugPrint('❌ 抓取作答紀錄失敗：$e');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryLight,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.primaryLight, // 整體背景為淺米綠
      body: Column(
        children: [
          // 1. Header：背景圖 + 返回鍵 + 標題
          SizedBox(
            width: double.infinity,
            height: 330,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/wax_apple_header.png',
                    fit: BoxFit.cover,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        ),
                        const Spacer(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              '選擇題紀錄',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'suán-tik-tē kì-lōk',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 主體區：mint green 底 + 卡片列表 (ListView 加上 top padding 30)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryTint, // mint green
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: recentRecords.isEmpty
                  ? const Center(child: Text('目前沒有作答紀錄'))
                  : ListView.separated(
                // 重點：這裡 top: 30 會在 Header 和第一張卡片之間保留空間
                padding: const EdgeInsets.only(top: 30, bottom: 16),
                itemCount: recentRecords.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final record = recentRecords[idx];
                  final mode = record['mode'] as String;
                  final unitIndex = units.indexOf(mode);
                  final name = unitIndex != -1 ? unitNames[unitIndex] : mode;
                  final icon = unitIndex != -1 ? icons[unitIndex] : '❓';
                  final dateString = record['date'] ?? '未提供時間';
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnitDetailPage(
                          unitId: mode,
                          roomId: 'room_$mode',
                          userId: 'anonymous',
                          authService: widget.authService,
                          date: dateString,
                          recordData: record,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 卡片底色
                          Container(
                            height: 80,
                            color: Colors.white,
                          ),
                          // 卡片陰影層
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          // ListTile 內容
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            leading: Text(icon, style: const TextStyle(fontSize: 32)),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(dateString,
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.black54,
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