// lib/pages/unit_selection_page.dart
import 'package:flutter/material.dart';

class UnitSelectionPage extends StatelessWidget {
  const UnitSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. 先拿 rawArgs
    final rawArgs = ModalRoute.of(context)!.settings.arguments;
    // 2. 确保它是 Map<String, dynamic>
    if (rawArgs is! Map<String, dynamic> || !rawArgs.containsKey('room')) {
      return Scaffold(
        appBar: AppBar(title: const Text('選擇單元')),
        body: const Center(child: Text('參數錯誤，無法顯示單元列表')),
      );
    }
    final args = rawArgs;
    final roomId = args['room'] as String;

    // 3. 你的单元列表（测试时可以写死，后端接好再改成网络请求）
    final units = <String>[
      'Unit_1',
      'Unit_2',
      'Unit_3',
      'Unit_4',
      'Unit_5',
      'Unit_6',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇單元'),
        centerTitle: true,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: units.length,
        itemBuilder: (ctx, i) {
          final unit = units[i];
          return Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.orange),
              title: Text(unit),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // 4. 点击后丢给 MCQ 游戏页
                Navigator.pushNamed(
                  context,
                  '/mcqGame',
                  arguments: {
                    'room': roomId,
                    'unit': unit,
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}