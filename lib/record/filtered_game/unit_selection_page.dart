import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';
import 'unit_detail_page.dart';

class Filter_UnitSelectionPage extends StatefulWidget {
  final AuthApiService authService;

  const Filter_UnitSelectionPage({super.key, required this.authService});

  @override
  State<Filter_UnitSelectionPage> createState() => _UnitSelectionPageState();
}

class _UnitSelectionPageState extends State<Filter_UnitSelectionPage> {
  List<Map<String, dynamic>> recentRecords = [];

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
  bool isLoading = true; // 加上 loading 狀態

  @override
  void initState() {
    super.initState();
    widget.authService.fetchAllFilterRecords().then((records) {
      setState(() {
        recentRecords = records.length <= 5
            ? records.reversed.toList()
            : records.sublist(records.length - 5).reversed.toList();
        isLoading = false; // 資料抓完
      });

      print('📘 共抓到 ${records.length} 筆作答紀錄');
      print(recentRecords);
    }).catchError((e) {
      print('❌ 抓紀錄失敗: $e');
      setState(() => isLoading = false);
    });
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (recentRecords.isEmpty && !isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('濾鏡紀錄'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('尚無濾鏡遊戲紀錄', style: TextStyle(fontSize: 18)),
        ),
      );
    }


    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('濾鏡紀錄'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Center(
            child: Image(
              image: AssetImage('assets/images/filter_record.png'),
              width: 160, // ⬅️ 可調整你想要的尺寸
              height: 160,
              fit: BoxFit.contain,
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
                  itemCount: recentRecords.length,
                  itemBuilder: (context, index) {
                    final record = recentRecords[index];
                    final unitId = (record['unitId'] ?? '').toString(); // <--- 修正欄位
                    final unitIndex = units.indexOf(unitId);
                    final unitName = unitIndex != -1 ? unitNames[unitIndex] : unitId;
                    final icon = unitIndex != -1 ? icons[unitIndex] : '❓';
                    final dateString = (record['submittedAt'] ?? '未提供時間').toString(); // <--- 修正欄位

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Text(icon, style: const TextStyle(fontSize: 32)),
                        title: const Text("濾鏡小遊戲", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(unitName),
                        trailing: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('前往訂正', style: TextStyle(color: Colors.black87)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
                          ],
                        ),
                        onTap: () async {
                          // 取得這一筆的 unitId
                          final questions = await widget.authService.fetchFilterQuestions(unitId);

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
                                questions: questions,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
              ),
            ),
          ),
        ],
      ),
    );
  }
}
