import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_api_service.dart';
import 'create_room_page.dart';
import 'room_page.dart';
import 'api.dart';

const String teacherUid = 'a07fe81b-1f73-46ea-9d52-473017069c43';

class RoomSelectionPage extends StatefulWidget {
  const RoomSelectionPage({Key? key}) : super(key: key);

  @override
  State<RoomSelectionPage> createState() => _RoomSelectionPageState();
}

class _RoomSelectionPageState extends State<RoomSelectionPage> {
  final AuthApiService _authService = AuthApiService(baseUrl: baseUrl);
  String? _currentUid;
  List<Map<String, dynamic>> rooms = [];
  Map<String, String> hostNameCache = {}; // hostUid -> name
  String searchText = '';
  Map<String, dynamic>? selectedRoom;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initUserAndRooms();
  }

  Future<void> _initUserAndRooms() async {
    try {
      final profile = await _authService.fetchUserProfile();
      _currentUid = profile?['uid'];
    } catch (_) {
      _currentUid = null;
    }
    await fetchRooms();
    setState(() => _loading = false);
  }

  Future<void> fetchRooms() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/mcq/rooms'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final list = (json.decode(res.body)['rooms'] as List).cast<Map<String, dynamic>>();
      setState(() => rooms = list);
      await Future.wait(rooms.map((r) => getHostName(r['host'])));
    }
  }

  Future<String> getHostName(String uid) async {
    if (hostNameCache.containsKey(uid)) return hostNameCache[uid]!;

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final name = data['name'] ?? '未知使用者';
      setState(() => hostNameCache[uid] = name);
      return name;
    } else {
      return '未知使用者';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isTeacher = _currentUid == teacherUid;
    final filteredRooms = rooms
        .where((room) => room['roomId'].toString().contains(searchText))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEAF6ED),
      appBar: AppBar(
        title: const Text('選擇題', style: TextStyle(color: Colors.green)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: isTeacher
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateRoomPage(hostUid: _currentUid!),
                  ),
                );
              }
                  : null,
              child: Row(
                children: [
                  const CircleAvatar(radius: 24, backgroundColor: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    isTeacher ? '建立遊戲房間' : '請選擇房間進入',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFB5D2BF),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => searchText = v),
                    decoration: InputDecoration(
                      hintText: '搜尋房間號碼',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...filteredRooms.map((room) {
                    final selected = selectedRoom?['roomId'] == room['roomId'];
                    final hostName = hostNameCache[room['host']] ?? '讀取中...';
                    return GestureDetector(
                      onTap: () => setState(() => selectedRoom = room),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF2F9E76) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '房間號碼：${room['roomId']}',
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '創建者：$hostName',
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedRoom == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomPage(
                        roomId: selectedRoom!['roomId'],
                        initTimeLimit: 0,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4AB38C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('進入房間', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
