import 'package:flutter/material.dart';
import 'result_page.dart';

class FilterGamePage extends StatelessWidget {
  final String unitId;
  final dynamic authService; // 建議指定型別，例如 AuthApiService

  const FilterGamePage({
    Key? key,
    required this.unitId,
    required this.authService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 之後可以用 unitId 跟 authService 抓題目
    return Scaffold(
      appBar: AppBar(
        title: Text('濾鏡小遊戲 $unitId'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('目前單元: $unitId', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultPage(
                      authService: authService,
                    ),
                  ),
                );
                // 這裡可加入開始遊戲/進入下一頁的邏輯
              },
              child: const Text('開始遊戲'),
            ),
          ],
        ),
      ),
    );
  }
}
