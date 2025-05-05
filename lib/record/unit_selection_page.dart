import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_api_service.dart';
import 'unit_detail_page.dart';
import 'package:http/http.dart' as http;

class UnitSelectionPage extends StatefulWidget {
  final AuthApiService authService;

  const UnitSelectionPage({super.key, required this.authService});

  @override
  State<UnitSelectionPage> createState() => _UnitSelectionPageState();
}

class _UnitSelectionPageState extends State<UnitSelectionPage> {
  String? userId;

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

  Map<String, bool> completedStatus = {}; // 存每個單元是否完成

  @override
  void initState() {
    super.initState();
    widget.authService.getUid().then((uid) {
      setState(() => userId = uid);
      widget.authService.fetchCompletedUnits().then((status) {
        setState(() => completedStatus = status);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        title: const Text('選擇題紀錄'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // 平均完成率
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  '平均達題正確率：80%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Column(
              children: [
                Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 8),
                Text("主視覺", style: TextStyle(fontSize: 16, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unitId = units[index];
                  final unitName = unitNames[index];
                  final isCompleted = completedStatus[unitId] ?? false;


                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Text(icons[index], style: const TextStyle(fontSize: 32)),
                      title: const Text("選擇題小遊戲", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(unitName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCompleted ? '已完成' : '未完成',
                            style: TextStyle(color: isCompleted ? Colors.black87 : Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isCompleted ? Icons.arrow_forward_ios : Icons.lock_outline,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      onTap: isCompleted
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UnitDetailPage(
                              unitId: unitId,
                              roomId: 'room_${unitId}', // 可根據真實房間邏輯改寫
                              userId: userId!,
                            ),
                          ),
                        );
                      }
                          : null,
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
