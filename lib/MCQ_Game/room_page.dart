// lib/pages/room_page.dart
import 'package:flutter/material.dart';

class RoomPage extends StatelessWidget {
  const RoomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
// 從路由取得房間 ID
    final roomId = ModalRoute
        .of(context)!
        .settings
        .arguments as String;
    // 範例參與者列表，實際可由後端取得
    final participants = [
      {'name': '王順仁', 'isHost': true},
      {'name': '學生A', 'isHost': false},
      {'name': '學生B', 'isHost': false},
      {'name': '學生C', 'isHost': false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('房間 $roomId'),
        centerTitle: true,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 房間資訊卡片
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room, size: 40, color: Colors.blue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '房間號碼：$roomId',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '主持人：${participants.first['name']}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 參與者名單
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: participants.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: p['isHost']! as bool
                              ? Colors.orange
                              : Colors.grey[300],
                          child: Text(
                            (p['name'] as String).substring(0, 1),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p['name'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const Spacer(),
            // 開始遊戲按鈕
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/unitSelection',
                    arguments: roomId,
                  );
                },
                child: const Text('開始遊戲', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      // 如需底部導航，請取消下方註解
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: 1,
      //   type: BottomNavigationBarType.fixed,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
      //     BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: '遊戲'),
      //     BottomNavigationBarItem(icon: Icon(Icons.star), label: '收藏'),
      //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
      //   ],
      //   onTap: (_) {},
      // ),
    );
  }}