// import 'package:flutter/material.dart';
// import '../../services/auth_api_service.dart';
// import 'unit_detail_page.dart';
//
// class UnitSelectionPage extends StatefulWidget {
//   final AuthApiService authService;
//
//   const UnitSelectionPage({super.key, required this.authService});
//
//   @override
//   State<UnitSelectionPage> createState() => _UnitSelectionPageState();
// }
//
// class _UnitSelectionPageState extends State<UnitSelectionPage> {
//   List<Map<String, dynamic>> recentRecords = [];
//   bool isLoading = true;
//
//   final List<String> units = const [
//     'Unit_1',
//     'Unit_2',
//     'Unit_3',
//     'Unit_4',
//     'Unit_5',
//     'Unit_6',
//   ];
//
//   final List<String> unitNames = const [
//     '單元一',
//     '單元二',
//     '單元三',
//     '單元四',
//     '單元五',
//     '單元六',
//   ];
//
//   final icons = ['🍐', '🍔', '📷', '🎯', '📚', '🧠'];
//
//   @override
//   void initState() {
//     super.initState();
//     widget.authService.fetchAllRecords().then((records) {
//       setState(() {
//         recentRecords = records.length <= 5
//             ? records.reversed.toList()
//             : records.sublist(records.length - 5).reversed.toList();
//         isLoading = false;  // ← 載入完成
//       });
//       print('📘 共抓到 ${records.length} 筆作答紀錄');
//     }).catchError((e) {
//       setState(() => isLoading = false);
//       print('❌ 抓取作答紀錄失敗：$e');
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFE5E5E5),
//       appBar: AppBar(
//         title: const Text('選擇題紀錄'),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : recentRecords.isEmpty
//           ? const Center(child: Text('目前沒有作答紀錄'))
//           : Column(
//         children: [
//           const SizedBox(height: 16),
//           const Center(
//             child: Column(
//               children: [
//                 Icon(Icons.image_outlined, size: 80, color: Colors.grey),
//                 SizedBox(height: 8),
//                 Text("主視覺",
//                     style:
//                     TextStyle(fontSize: 16, color: Colors.black54)),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade200,
//                 borderRadius:
//                 const BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               padding: const EdgeInsets.all(16),
//               child: ListView.builder(
//                 itemCount: recentRecords.length,
//                 itemBuilder: (ctx, idx) {
//                   final record = recentRecords[idx];
//                   final unitId = record['mode'];
//                   final unitIndex = units.indexOf(unitId);
//                   final unitName = unitIndex != -1
//                       ? unitNames[unitIndex]
//                       : unitId;
//                   final icon =
//                   unitIndex != -1 ? icons[unitIndex] : '❓';
//                   final dateString = record['date'] ?? '未提供時間';
//
//                   return Container(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 8),
//                       leading: Text(icon,
//                           style: const TextStyle(fontSize: 32)),
//                       title: const Text("選擇題小遊戲",
//                           style:
//                           TextStyle(fontWeight: FontWeight.bold)),
//                       subtitle: Text(unitName),
//                       trailing: const Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text('前往訂正',
//                               style: TextStyle(color: Colors.black87)),
//                           SizedBox(width: 8),
//                           Icon(Icons.arrow_forward_ios,
//                               size: 18, color: Colors.black54),
//                         ],
//                       ),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => UnitDetailPage(
//                               unitId: unitId,
//                               roomId: 'room_$unitId',
//                               userId: 'anonymous',
//                               authService: widget.authService,
//                               date: dateString,
//                               recordData: record,
//                             ),
//                           ),
//                         );
//                       },
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
import '../../../services/auth_api_service.dart';
import 'unit_detail_page.dart';
import '../../../theme/colors.dart';

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
      debugPrint('抓取作答紀錄失敗：$e');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Column(
        children: [
          // Header：背景圖 + 返回鍵 + 標題
          Stack(
            children: [
              Image.asset(
                'assets/images/wax_apple_header.png',
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'suán-tik-tê kì-lōk',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 主體區：淺綠背景 + 列表卡片
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: recentRecords.isEmpty
                  ? const Center(child: Text('目前沒有作答紀錄'))
                  : ListView.separated(
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
                          // 淺圖裝飾（可選）
                          // Positioned.fill(
                          //   child: Image.asset('assets/images/card_decor.png', fit: BoxFit.cover),
                          // ),
                          // 內層陰影與邊框
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
                            leading: Text(icon, style: const TextStyle(fontSize: 32)),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(dateString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
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
