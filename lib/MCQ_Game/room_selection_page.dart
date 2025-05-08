// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import 'api.dart';
// import 'unit_selection_page.dart';
// import 'room_page.dart';
//
// class RoomSelectionPage extends StatefulWidget {
//   const RoomSelectionPage({Key? key}) : super(key: key);
//
//   @override
//   State<RoomSelectionPage> createState() => _RoomSelectionPageState();
// }
//
// class _RoomSelectionPageState extends State<RoomSelectionPage> {
//   bool _loading = true;
//   String? _currentUid;
//   List<RoomItem> _rooms = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//   Future<void> _init() async {
//     // 1) 拿老師 UID
//     try {
//       _currentUid = await getUserId();
//     } catch (_) {
//       _currentUid = null;
//     }
//     // 2) 撈房間列表
//     await _loadRooms();
//   }
//
//   Future<void> _loadRooms() async {
//     setState(() => _loading = true);
//     final token = await getToken();
//     final res = await http.get(
//       Uri.parse('$baseUrl/api/mcq/rooms'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//     if (res.statusCode == 200) {
//       final list = (json.decode(res.body)['rooms'] as List)
//           .cast<Map<String, dynamic>>();
//       _rooms = list.map(RoomItem.fromJson).toList();
//     } else {
//       debugPrint('GET /rooms failed: ${res.statusCode}');
//     }
//     setState(() => _loading = false);
//   }
//
//   Future<void> _onCreateRoom() async {
//     // A) 先跳到選單元，拿回 chosenUnit
//     final chosenUnit = await Navigator.push<String>(
//       context,
//       MaterialPageRoute(builder: (_) => const UnitSelectionPage()),
//     );
//     if (chosenUnit == null) return; // 老師按了返回
//
//     // B) 呼 API 建房
//     setState(() => _loading = true);
//     final token = await getToken();
//     final newRoomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
//     final res = await http.post(
//       Uri.parse('$baseUrl/api/mcq/rooms'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: json.encode({
//         'host':      _currentUid,
//         'unitId':    chosenUnit,   // ← 真正帶回的單元
//         'roomId':    newRoomId,
//         'timeLimit': 30,           // 預設 30s
//       }),
//     );
//     if (res.statusCode == 200) {
//       await _loadRooms(); // 成功就刷新列表
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('建立房間失敗 (${res.statusCode})')),
//       );
//     }
//     setState(() => _loading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('選擇房間')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: _rooms.length,
//         itemBuilder: (ctx, i) {
//           final r = _rooms[i];
//           return Card(
//             margin:
//             const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             child: ListTile(
//               leading: const Icon(Icons.meeting_room, color: Colors.blue),
//               title: Text('房間 ${r.roomId}  •  時限：${r.timeLimit}s'),
//               subtitle: Text('主持人：${r.host}'),
//               trailing: ElevatedButton(
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => RoomPage(roomId: r.roomId),
//                   ),
//                 ),
//                 child: const Text('進入'),
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _onCreateRoom,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
//
// class RoomItem {
//   final String roomId;
//   final String host;
//   final int timeLimit;
//   RoomItem({
//     required this.roomId,
//     required this.host,
//     required this.timeLimit,
//   });
//   factory RoomItem.fromJson(Map<String, dynamic> j) => RoomItem(
//     roomId:    j['roomId']    as String,
//     host:      j['host']      as String,
//     timeLimit: (j['timeLimit'] as int?) ?? 60,
//   );
// }

// lib/MCQ_Game/room_selection_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'create_room_page.dart';
import 'unit_selection_page.dart';
import '../services/auth_api_service.dart';
import 'api.dart';
import 'room_page.dart';

const String teacherUid = 'a07fe81b-1f73-46ea-9d52-473017069c43';

class RoomSelectionPage extends StatefulWidget {
  const RoomSelectionPage({Key? key}) : super(key: key);

  @override
  State<RoomSelectionPage> createState() => _RoomSelectionPageState();
}

class _RoomSelectionPageState extends State<RoomSelectionPage> {
  final AuthApiService _authService = AuthApiService(baseUrl: baseUrl);
  String? _currentUid;
  bool _loadingUid = true;
  bool _loadingRooms = true;
  bool _loading = false;
  List<RoomItem> _rooms = [];

  @override
  void initState() {
    super.initState();
    _initUserAndRooms();
  }

  Future<void> _initUserAndRooms() async {
    // 1) 取得當前使用者 UID
    try {
      final profile = await _authService.fetchUserProfile();
      _currentUid = profile?['uid'] as String?;
    } catch (_) {
      _currentUid = null;
    }
    setState(() => _loadingUid = false);

    // 2) 取得房間列表
    await _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _loadingRooms = true);
    final token = await getToken();
    final url = '$baseUrl/api/mcq/rooms';
    debugPrint('GET rooms → $url');
    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final list = (json.decode(res.body)['rooms'] as List).cast<Map<String, dynamic>>();
      setState(() => _rooms = list.map(RoomItem.fromJson).toList());
    }
    setState(() => _loadingRooms = false);
  }

  Future<void> _createRoom() async {
    final token = await getToken();
    final newId = 'room_${DateTime.now().millisecondsSinceEpoch}';
    final url = '$baseUrl/api/mcq/rooms';
        debugPrint('POST create room → $url, host=$_currentUid');
        final res = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
      body: json.encode({
        'host': _currentUid,
        'unitId': '',
        'roomId': newId,
        'timeLimit': 30,
      }),
    );
    if (res.statusCode == 200) {
      await _loadRooms();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('建立房間失敗 (${res.statusCode})')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid || _loadingRooms || _loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isTeacher = _currentUid == teacherUid;
    return Scaffold(
      appBar: AppBar(title: const Text('選擇房間')),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateRoomPage(hostUid: _currentUid!),  // ← 把 _currentUid 傳進去
            ),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
      body: ListView.builder(
        itemCount: _rooms.length,
        itemBuilder: (_, i) {
          final r = _rooms[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.meeting_room, color: Colors.blue),
              title: Text('房間 ${r.roomId}  •  時限：${r.timeLimit}s'),
              subtitle: Text('主持人：${r.host}'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomPage(roomId: r.roomId, initTimeLimit: 0),
                    ),
                  );
                },
                child: Text(isTeacher ? '進入' : '加入'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RoomItem {
  final String roomId;
  final String host;
  final int timeLimit;
  RoomItem({required this.roomId, required this.host, required this.timeLimit});
  factory RoomItem.fromJson(Map<String, dynamic> j) => RoomItem(
    roomId: j['roomId'] as String,
    host: j['host'] as String,
    timeLimit: (j['timeLimit'] as int?) ?? 60,
  );
}
