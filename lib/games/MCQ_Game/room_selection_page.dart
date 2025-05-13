import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_api_service.dart';
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
      final list =
      (json.decode(res.body)['rooms'] as List).cast<Map<String, dynamic>>();
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
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // 優先用 username，再 fallback name
      final name = (data['name'] as String?)
          ?? (data['username'] as String?)
          ?? '未知使用者';
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
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFEAF6ED),
      appBar: AppBar(
        title: const Text('選擇題', style: TextStyle(color: Colors.green)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // 左右 24，上方 16，底部隨鍵盤高度 + 24
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 建立／選房
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

              // 搜尋＋列表區
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFB5D2BF),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 搜尋框
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

                    // 房間列表
                    ...filteredRooms.map((room) {
                      final selected = selectedRoom?['roomId'] == room['roomId'];
                      final hostName = hostNameCache[room['host']] ?? '讀取中...';
                      return GestureDetector(
                        onTap: () => setState(() => selectedRoom = room),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                            selected ? const Color(0xFF2F9E76) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '房間號碼：${room['roomId']}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '創建者：$hostName老師',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                    selected ? Colors.white : Colors.black54,
                                  ),
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

              const SizedBox(height: 24),

              // 進入房間按鈕（不被鍵盤蓋住）
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRoom == null ? null : () async {
                    // 只有學生呼 join
                    if (!isTeacher) {
                      final token = await getToken();
                      final res = await http.post(
                        Uri.parse(
                            '$baseUrl/api/mcq/rooms/${selectedRoom!['roomId']}/join'
                        ),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({"user": _currentUid}),
                      );
                      if (res.statusCode != 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('加入房間失敗：${res.body}')),
                        );
                        return;
                      }
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomPage(
                          roomId: selectedRoom!['roomId'],
                          initTimeLimit: selectedRoom!['timeLimit'] as int,
                        ),
                      ),
                    );
                  },
                  child: const Text('進入房間'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}