// lib/pages/room_selection_page.dart
import 'package:flutter/material.dart';

class RoomSelectionPage extends StatefulWidget {
  /// isTeacher = true 顯示「建立房間」按鈕，否則隱藏
  final bool isTeacher;
  const RoomSelectionPage({Key? key, required this.isTeacher}) : super(key: key);

  @override
  _RoomSelectionPageState createState() => _RoomSelectionPageState();
}

class _RoomSelectionPageState extends State<RoomSelectionPage> {
  // 範例房間列表，實際可由後端拉取
  final List<String> rooms = ['30601', '30602', '30603'];
  String? selectedRoom; // 目前選中的房間

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇房間'),
        centerTitle: true,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 如果是老師，才顯示「建立新房間」
            if (widget.isTeacher)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('建立新房間'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // TODO: 建立房間 API
                  },
                ),
              ),

            // 房間列表
            Expanded(
              child: ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: rooms.length,
                itemBuilder: (ctx, i) {
                  final room = rooms[i];
                  final isSelected = room == selectedRoom;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRoom = room;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color:
                        isSelected ? Colors.blue[50] : Colors.white,
                        border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.meeting_room,
                              size: 28, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '房間 $room',
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors.blue
                                  : Colors.grey[200],
                              minimumSize: const Size(64, 36),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(6)),
                            ),
                            onPressed: isSelected
                                ? () {
                              // 搭配之前教的，把 roomId 包成 Map 傳下去
                              Navigator.pushNamed(
                                context,
                                '/unitSelection',
                                arguments: {'room': room},
                              );
                            }
                                : null,
                            child: Text(
                              '進入',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // （若此頁不需要底部導航可以移除 below）
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // or whatever index
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(
              icon: Icon(Icons.videogame_asset), label: '遊戲'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: '積分榜'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: '設定'),
        ],
        onTap: (_) {},
      ),
    );
  }
}