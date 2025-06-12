// // lib/games/Chat_Game/chat_room_selection_page.dart
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/services.dart';
// import '../../services/auth_api_service.dart';
// import 'chat_game_lobby_page.dart';
//
// class ChatRoom {
//   final String roomId;
//   final String host;
//   final String? unitId;
//   ChatRoom({required this.roomId, required this.host, this.unitId});
//   factory ChatRoom.fromJson(Map<String, dynamic> js) {
//     return ChatRoom(
//       roomId: js['roomId'] as String,
//       host: js['host'] as String,
//       unitId: js['unitId'] as String?,
//     );
//   }
// }
//
// class ChatRoomSelectionPage extends StatefulWidget {
//   final AuthApiService authService;
//   const ChatRoomSelectionPage({Key? key, required this.authService}) : super(key: key);
//
//   @override
//   State<ChatRoomSelectionPage> createState() => _ChatRoomSelectionPageState();
// }
//
// class _ChatRoomSelectionPageState extends State<ChatRoomSelectionPage> {
//   static const String _teacherUid = 'a07fe81b-1f73-46ea-9d52-473017069c43';
//
//   bool _isHost = false;
//   final List<String> _units = ['Unit_1', 'Unit_2', 'Unit_3'];
//   String? _selectedUnit;
//   String _customRoomId = '';
//   bool _creating = false;
//   String? _createError;
//
//   List<ChatRoom> _rooms = [];
//   bool _loadingRooms = false;
//   String? _roomsError;
//
//   @override
//   void initState() {
//     super.initState();
//     _determineRole();
//   }
//
//   Future<void> _determineRole() async {
//     final uid = await widget.authService.getUid();
//     setState(() => _isHost = uid == _teacherUid);
//     await _fetchRooms();
//   }
//
//   Future<void> _fetchRooms() async {
//     setState(() { _loadingRooms = true; _roomsError = null; });
//     try {
//       final uri = Uri.parse('${widget.authService.baseUrl}/api/chat/rooms');
//       final resp = await http.get(uri);
//       final data = jsonDecode(resp.body);
//       List<Map<String, dynamic>> raw;
//       if (data is List) {
//         raw = data.cast<Map<String, dynamic>>();
//       } else if (data is Map<String, dynamic>) {
//         if (data['rooms'] is List) {
//           raw = (data['rooms'] as List).cast<Map<String, dynamic>>();
//         } else {
//           raw = data.values.whereType<Map<String, dynamic>>().toList();
//         }
//       } else {
//         throw FormatException('Unexpected JSON for rooms');
//       }
//       setState(() {
//         _rooms = raw.map((js) => ChatRoom.fromJson(js)).toList();
//       });
//     } catch (e) {
//       setState(() => _roomsError = '讀取房間失敗：$e');
//     } finally {
//       setState(() => _loadingRooms = false);
//     }
//   }
//
//   Future<void> _createRoom() async {
//     if (_customRoomId.trim().isEmpty) {
//       setState(() => _createError = '請輸入想要的房號');
//       return;
//     }
//     if (_selectedUnit == null) {
//       setState(() => _createError = '請選擇單元');
//       return;
//     }
//     setState(() { _creating = true; _createError = null; });
//     final uid = await widget.authService.getUid();
//     if (uid == null) {
//       setState(() { _createError = '請重新登入'; _creating = false; });
//       return;
//     }
//     try {
//       final uri = Uri.parse('${widget.authService.baseUrl}/api/chat/rooms');
//       final resp = await http.post(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'host': uid,
//           'unitId': _selectedUnit,
//           'roomId': _customRoomId.trim(),
//         }),
//       );
//       if (resp.statusCode >= 200 && resp.statusCode < 300) {
//         Clipboard.setData(ClipboardData(text: _customRoomId.trim()));
//         await _fetchRooms();
//         setState(() { _customRoomId = ''; });
//       } else {
//         setState(() => _createError = '創建失敗：${resp.statusCode}');
//       }
//     } catch (e) {
//       setState(() => _createError = '創建錯誤：$e');
//     } finally {
//       setState(() => _creating = false);
//     }
//   }
//
//   Future<void> _enterRoom(String roomId) async {
//     setState(() => _roomsError = null);
//     final uid = await widget.authService.getUid();
//     if (uid == null) {
//       setState(() => _roomsError = '請重新登入');
//       return;
//     }
//     if (!_isHost) {
//       final uri = Uri.parse('${widget.authService.baseUrl}/api/chat/rooms/$roomId/join');
//       final resp = await http.post(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'user': uid}),
//       );
//       if (resp.statusCode < 200 || resp.statusCode >= 300) {
//         setState(() => _roomsError = '加入失敗：${resp.statusCode}');
//         return;
//       }
//     }
//
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ChatGameLobbyPage(
//           authService: widget.authService,
//           roomId: roomId,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isHost ? '教師：創建／選擇房間' : '學生：選擇房間加入'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (_isHost) ...[
//               TextField(
//                 decoration: const InputDecoration(labelText: '自訂房號'),
//                 onChanged: (v) => setState(() { _customRoomId = v; _createError = null; }),
//               ),
//               const SizedBox(height: 8),
//               Row(children: [
//                 DropdownButton<String>(
//                   hint: const Text('選擇單元'),
//                   value: _selectedUnit,
//                   items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
//                   onChanged: (v) => setState(() { _selectedUnit = v; _createError = null; }),
//                 ),
//                 const SizedBox(width: 16),
//                 _creating
//                     ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
//                     : ElevatedButton(onPressed: _createRoom, child: const Text('創建')),
//               ]),
//               if (_createError != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Text(_createError!, style: const TextStyle(color: Colors.red)),
//                 ),
//               const Divider(height: 32),
//             ],
//
//             Expanded(child: _buildRoomList()),
//
//             if (_roomsError != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Text(_roomsError!, style: const TextStyle(color: Colors.red)),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRoomList() {
//     if (_loadingRooms) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     if (_rooms.isEmpty) {
//       return const Center(child: Text('目前無可用房間'));
//     }
//     return ListView.separated(
//       itemCount: _rooms.length,
//       separatorBuilder: (_, __) => const Divider(),
//       itemBuilder: (ctx, i) {
//         final r = _rooms[i];
//         return ListTile(
//           title: Text('房號：${r.roomId}'),
//           subtitle: Text('單元：${r.unitId ?? '—'}\nHost：${r.host}'),
//           isThreeLine: true,
//           trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//           onTap: () => _enterRoom(r.roomId),
//         );
//       },
//     );
//   }
// }

// lib/games/Chat_Game/chat_room_selection_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../../services/auth_api_service.dart';
import 'chat_game_lobby_page.dart';

class ChatRoom {
  final String roomId;
  final String host;
  final String? unitId;

  ChatRoom({required this.roomId, required this.host, this.unitId});

  factory ChatRoom.fromJson(Map<String, dynamic> js) {
    return ChatRoom(
      roomId: js['roomId'] as String,
      host: js['host'] as String,
      unitId: js['unitId'] as String?,
    );
  }
}

class ChatRoomSelectionPage extends StatefulWidget {
  final AuthApiService authService;
  const ChatRoomSelectionPage({Key? key, required this.authService}) : super(key: key);

  @override
  State<ChatRoomSelectionPage> createState() => _ChatRoomSelectionPageState();
}

class _ChatRoomSelectionPageState extends State<ChatRoomSelectionPage> {
  static const String _teacherUid = 'a07fe81b-1f73-46ea-9d52-473017069c43';

  bool _isHost = false;
  final List<String> _units = ['Unit_1', 'Unit_2', 'Unit_3'];
  String? _selectedUnit;
  String _customRoomId = '';

  bool _creating = false;
  String? _createError;

  List<ChatRoom> _rooms = [];
  bool _loadingRooms = false;
  String? _roomsError;

  @override
  void initState() {
    super.initState();
    _determineRole();
  }

  Future<void> _determineRole() async {
    final uid = await widget.authService.getUid();
    setState(() => _isHost = (uid == _teacherUid));
    await _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomsError = null;
    });
    try {
      final uri = Uri.parse('${widget.authService.baseUrl}/api/chat/rooms');
      final resp = await http.get(uri);

      if (resp.statusCode != 200) {
        throw 'HTTP ${resp.statusCode}';
      }

      final data = jsonDecode(resp.body);
      List<dynamic> rawRooms;

      if (data is List) {
        rawRooms = data;
      } else if (data is Map<String, dynamic> && data['rooms'] is List) {
        rawRooms = data['rooms'];
      } else {
        throw 'Unexpected JSON structure';
      }

      setState(() {
        _rooms = rawRooms
            .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _roomsError = '讀取房間失敗：$e');
    } finally {
      setState(() => _loadingRooms = false);
    }
  }

  Future<void> _createRoom() async {
    if (_customRoomId.trim().isEmpty) {
      setState(() => _createError = '請輸入房號');
      return;
    }
    if (_selectedUnit == null) {
      setState(() => _createError = '請選擇單元');
      return;
    }

    setState(() {
      _creating = true;
      _createError = null;
    });

    final uid = await widget.authService.getUid();
    if (uid == null) {
      setState(() {
        _createError = '使用者未登入';
        _creating = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('${widget.authService.baseUrl}/api/chat/rooms');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'host': uid,
          'unitId': _selectedUnit,
          'roomId': _customRoomId.trim(),
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        Clipboard.setData(ClipboardData(text: _customRoomId.trim()));
        await _fetchRooms();
        setState(() => _customRoomId = '');
      } else {
        setState(() => _createError = '創建失敗：HTTP ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _createError = '創建錯誤：$e');
    } finally {
      setState(() => _creating = false);
    }
  }

  Future<void> _enterRoom(String roomId) async {
    setState(() => _roomsError = null);
    final uid = await widget.authService.getUid();
    if (uid == null) {
      setState(() => _roomsError = '請重新登入');
      return;
    }

    if (!_isHost) {
      final uri = Uri.parse('${widget.authService.baseUrl}/api/chat/rooms/$roomId/join');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user': uid}),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        setState(() => _roomsError = '加入失敗：HTTP ${resp.statusCode}');
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatGameLobbyPage(
          authService: widget.authService,
          roomId: roomId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isHost ? '教師：創建／選擇房間' : '學生：選擇房間加入'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isHost) ...[
              TextField(
                decoration: const InputDecoration(labelText: '房號'),
                onChanged: (v) => setState(() {
                  _customRoomId = v;
                  _createError = null;
                }),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  DropdownButton<String>(
                    hint: const Text('選擇單元'),
                    value: _selectedUnit,
                    items: _units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedUnit = v;
                      _createError = null;
                    }),
                  ),
                  const SizedBox(width: 16),
                  _creating
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : ElevatedButton(onPressed: _createRoom, child: const Text('創建')),
                ],
              ),
              if (_createError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_createError!, style: const TextStyle(color: Colors.red)),
                ),
              const Divider(height: 32),
            ],
            Expanded(child: _buildRoomList()),
            if (_roomsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_roomsError!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomList() {
    if (_loadingRooms) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rooms.isEmpty) {
      return const Center(child: Text('目前無可用房間'));
    }
    return ListView.separated(
      itemCount: _rooms.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (ctx, i) {
        final r = _rooms[i];
        return ListTile(
          title: Text('房號：${r.roomId}'),
          subtitle: Text('單元：${r.unitId ?? '—'}\nHost：${r.host}'),
          isThreeLine: true,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _enterRoom(r.roomId),
        );
      },
    );
  }
}