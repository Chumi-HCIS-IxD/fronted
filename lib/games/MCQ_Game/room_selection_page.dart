// lib/pages/room_selection_page.dart
import 'package:flutter/material.dart';

class RoomSelectionPage extends StatefulWidget {
  /// isTeacher = true 顯示「建立房間」按鈕，否則隱藏
  final bool isTeacher;
  const RoomSelectionPage({Key? key, required this.isTeacher}) : super(key: key);

  @override
  _RoomSelectionPageState createState() => _RoomSelectionPageState();
}

// lib/pages/room_selection_page.dart
class _RoomSelectionPageState extends State<RoomSelectionPage> {
  // rooms 由原先 List<String> 改成 List<Map>
  final List<Map<String, dynamic>> rooms = [];
  Map<String, dynamic>? selectedRoom;

  @override
  void initState() {
    super.initState();
    // 範例預設房間
    rooms.addAll([
      {'id': '30601', 'duration': 60},
      {'id': '30602', 'duration': 45},
      {'id': '30603', 'duration': 30},
    ]);
  }

  Future<void> _createRoom() async {
    final TextEditingController idCtrl = TextEditingController();
    final TextEditingController durCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('建立新房間'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(labelText: '房間編號'),
            ),
            TextField(
              controller: durCtrl,
              decoration: const InputDecoration(labelText: '時限 (秒)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final id = idCtrl.text.trim();
              final d = int.tryParse(durCtrl.text) ?? 60;
              if (id.isNotEmpty) {
                setState(() {
                  rooms.add({'id': id, 'duration': d});
                });
                Navigator.pop(context);
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('選擇房間')),
      body: Column(
        children: [
          if (widget.isTeacher)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('建立新房間'),
                onPressed: _createRoom,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (_, i) {
                final room = rooms[i];
                final id = room['id'] as String;
                final dur = room['duration'] as int;
                final selected = selectedRoom?['id'] == id;
                return GestureDetector(
                  onTap: () => setState(() => selectedRoom = room),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue[50] : Colors.white,
                      border: Border.all(color: selected ? Colors.blue : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.meeting_room, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(child: Text('房間 $id  •  時限：${dur}s')),
                        ElevatedButton(
                          onPressed: selected
                              ? () {
                            Navigator.pushNamed(
                              context,
                              'RoomPage',
                              arguments: room,  // 傳 map
                            );
                          }
                              : null,
                          child: const Text('進入'),
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
    );
  }
}