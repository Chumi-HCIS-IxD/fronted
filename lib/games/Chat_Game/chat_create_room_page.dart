import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chat_api.dart';
import 'chat_room_page.dart';

class ChatCreateRoomPage extends StatefulWidget {
  final String hostUid;
  const ChatCreateRoomPage({Key? key, required this.hostUid}) : super(key: key);

  @override
  State<ChatCreateRoomPage> createState() => _ChatCreateRoomPageState();
}

class _ChatCreateRoomPageState extends State<ChatCreateRoomPage> {
  bool _loading = true;
  List<QuestionSet> _sets = [];
  // final _timeController = TextEditingController(text: '30');
  final _roomIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchQuestionSets();
  }

  Future<void> _fetchQuestionSets() async {
    setState(() => _loading = true);
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/mcq/questionSets'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List<QuestionSet> sets = [];
        if (body is Map<String, dynamic>) {
          if (body['unitIds'] is List) {
            for (var u in body['unitIds']) {
              if (u is String) sets.add(QuestionSet(u, u, 0));
            }
          } else if (body['questionSets'] is List) {
            for (var e in body['questionSets']) {
              if (e is Map<String, dynamic>) sets.add(QuestionSet.fromJson(e));
            }
          } else if (body['data'] is List) {
            for (var e in body['data']) {
              if (e is Map<String, dynamic>) sets.add(QuestionSet.fromJson(e));
            }
          }
        } else if (body is List) {
          for (var e in body) {
            if (e is Map<String, dynamic>) sets.add(QuestionSet.fromJson(e));
          }
        }
        setState(() => _sets = sets);
      }
    } catch (e) {
      debugPrint('fetchQuestionSets error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 按下「創建房間」前，彈出 Dialog 輸入時限
  Future<void> _onPressedCreate(String setId) async {
    final input = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('設定房間資訊'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _roomIdController,
              decoration: const InputDecoration(hintText: '自訂房間 ID（可留空）'),
            ),
            // const SizedBox(height: 12),
            // TextField(
            //   controller: _timeController,
            //   keyboardType: TextInputType.number,
            //   decoration: const InputDecoration(hintText: '時限（秒）例如 30'),
            // ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'roomId': _roomIdController.text.trim(),
              // 'timeLimit': _timeController.text.trim(),
            }),
            child: const Text('確定'),
          ),
        ],
      ),
    );

    if (input == null) return;
    // final timeLimit = int.tryParse(input['timeLimit'] ?? '');
    // if (timeLimit == null || timeLimit <= 0) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('請輸入大於 0 的整數時限')),
    //   );
    //   return;
    // }
    final customRoomId = input['roomId']; // ✅ 接收自訂 roomId
    await _createRoom(setId, customRoomId);
  }

  Future<void> _createRoom(String setId, String? roomId) async {
    setState(() => _loading = true);
    try {
      final token = await getToken(); // ✅ 只要呼叫一次
      final body = {
        'host': widget.hostUid,
        'unitId': setId,
        // 'timeLimit': timeLimit,
        if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
      };
      // 'timeLimit': timeLimit,
      final res = await http.post(
        Uri.parse('$baseUrl/api/chat/rooms'),  // ← 改成 /api/chat/rooms
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      debugPrint('POST /chat/rooms → ${res.statusCode}, ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        final newRoomId = json.decode(res.body)['roomId'] as String;
        final joinRes = await http.post(
          Uri.parse('$baseUrl/api/chat/rooms/$newRoomId/join'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type':  'application/json',
          },
          body: json.encode({'user': widget.hostUid}),
        );
        if (joinRes.statusCode != 200) {
          debugPrint('Host join room failed: ${joinRes.statusCode} ${joinRes.body}');
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(roomId: newRoomId, hostName: '', hostUid: '',),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('創建房間失敗：${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('建立房間錯誤：$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('創建新房間')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _sets.length,
        itemBuilder: (_, i) {
          final set = _sets[i];
          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(set.name),
              subtitle: set.questionCount > 0
                  ? Text('共 ${set.questionCount} 題')
                  : null,
              trailing: ElevatedButton(
                onPressed: () => _onPressedCreate(set.id),
                child: const Text('創建房間'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class QuestionSet {
  final String id;
  final String name;
  final int questionCount;
  QuestionSet(this.id, this.name, this.questionCount);

  factory QuestionSet.fromJson(Map<String, dynamic> j) => QuestionSet(
    j['id'] as String,
    j['name'] as String,
    (j['count'] as int?) ??
        (j['length'] as int?) ??
        (j['questionsCount'] as int?) ??
        0,
  );
}

