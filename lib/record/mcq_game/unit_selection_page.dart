import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';
import 'unit_detail_page.dart';

class UnitSelectionPage extends StatefulWidget {
  final AuthApiService authService;

  const UnitSelectionPage({super.key, required this.authService});

  @override
  State<UnitSelectionPage> createState() => _UnitSelectionPageState();
}

class _UnitSelectionPageState extends State<UnitSelectionPage> {
  List<Map<String, dynamic>> recentRecords = [];
  bool isLoading = true;

  final List<String> units = const [
    'Unit_1',
    'Unit_2',
    'Unit_3',
    'Unit_4',
    'Unit_5',
    'Unit_6',
  ];

  final List<String> unitNames = const [
    '單元一',
    '單元二',
    '單元三',
    '單元四',
    '單元五',
    '單元六',
  ];

  final icons = ['🍐', '🍔', '📷', '🎯', '📚', '🧠'];

  @override
  void initState() {
    super.initState();
    widget.authService.fetchAllRecords().then((records) {
      setState(() {
        recentRecords = records.length <= 5
            ? records.reversed.toList()
            : records.sublist(records.length - 5).reversed.toList();
        isLoading = false;  // ← 載入完成
      });
      print('📘 共抓到 ${records.length} 筆作答紀錄');
    }).catchError((e) {
      setState(() => isLoading = false);
      print('❌ 抓取作答紀錄失敗：$e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        title: const Text('選擇題紀錄'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recentRecords.isEmpty
          ? const Center(child: Text('目前沒有作答紀錄'))
          : Column(
        children: [
          const SizedBox(height: 16),
          const Center(
            child: Column(
              children: [
                Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 8),
                Text("主視覺",
                    style:
                    TextStyle(fontSize: 16, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: recentRecords.length,
                itemBuilder: (ctx, idx) {
                  final record = recentRecords[idx];
                  final unitId = record['mode'];
                  final unitIndex = units.indexOf(unitId);
                  final unitName = unitIndex != -1
                      ? unitNames[unitIndex]
                      : unitId;
                  final icon =
                  unitIndex != -1 ? icons[unitIndex] : '❓';
                  final dateString = record['date'] ?? '未提供時間';

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Text(icon,
                          style: const TextStyle(fontSize: 32)),
                      title: const Text("選擇題小遊戲",
                          style:
                          TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(unitName),
                      trailing: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('前往訂正',
                              style: TextStyle(color: Colors.black87)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios,
                              size: 18, color: Colors.black54),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UnitDetailPage(
                              unitId: unitId,
                              roomId: 'room_$unitId',
                              userId: 'anonymous',
                              authService: widget.authService,
                              date: dateString,
                              recordData: record,
                            ),
                          ),
                        );
                      },
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


//   @override
//   Widget build(BuildContext context) {
//     if (recentRecords.isEmpty) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFE5E5E5),
//       appBar: AppBar(
//         title: const Text('選擇題紀錄'),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 16),
//           const Center(
//             child: Column(
//               children: [
//                 Icon(Icons.image_outlined, size: 80, color: Colors.grey),
//                 SizedBox(height: 8),
//                 Text("主視覺", style: TextStyle(fontSize: 16, color: Colors.black54)),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade200,
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               padding: const EdgeInsets.all(16),
//               child: ListView.builder(
//                   itemCount: recentRecords.length,
//                   itemBuilder: (context, index) {
//                     final record = recentRecords[index];
//                     final unitId = record['mode']; // e.g. Unit_1
//                     final unitIndex = units.indexOf(unitId);
//                     final unitName = unitIndex != -1 ? unitNames[unitIndex] : unitId;
//                     final icon = unitIndex != -1 ? icons[unitIndex] : '❓';
//                     final dateString = record['date'] ?? '未提供時間';
//
//                     return Container(
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                         leading: Text(icon, style: const TextStyle(fontSize: 32)),
//                         title: const Text("選擇題小遊戲", style: TextStyle(fontWeight: FontWeight.bold)),
//                         subtitle: Text(unitName),
//                         trailing: const Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text('前往訂正', style: TextStyle(color: Colors.black87)),
//                             SizedBox(width: 8),
//                             Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
//                           ],
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => UnitDetailPage(
//                                 unitId: unitId,
//                                 roomId: 'room_$unitId',
//                                 userId: 'anonymous',
//                                 authService: widget.authService,
//                                 date: dateString,
//                                 recordData: record, // ✅ 傳整筆紀錄進去
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     );
//                   }
//
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
