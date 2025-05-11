// // lib/MCQ_Game/create_room_page.dart
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import 'api.dart';
// import 'room_page.dart';
//
// class CreateRoomPage extends StatefulWidget {
//   final String hostUid;           // ← 新增這行
//   const CreateRoomPage({Key? key, required this.hostUid}) : super(key: key);
//
//   @override
//   State<CreateRoomPage> createState() => _CreateRoomPageState();
// }
//
// class _CreateRoomPageState extends State<CreateRoomPage> {
//   bool _loading = true;
//   List<QuestionSet> _sets = [];
//   final _timeController = TextEditingController(text: '30');
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchQuestionSets();
//   }
//
//   /// 讀取單元列表：同時支援 unitIds / questionSets / data
//   Future<void> _fetchQuestionSets() async {
//     setState(() => _loading = true);
//     final token = await getToken();
//     final url = '$baseUrl/api/mcq/questionSets';
//     debugPrint('GET questionSets → $url');
//
//     try {
//       final res = await http.get(
//         Uri.parse(url),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (res.statusCode == 200) {
//         debugPrint('RAW questionSets body: ${res.body}');
//         final body = json.decode(res.body);
//
//         final List<QuestionSet> sets = [];
//
//         if (body is Map<String, dynamic>) {
//           // 1) unitIds: ["Unit_1", ...]
//           if (body['unitIds'] is List) {
//             for (var uid in (body['unitIds'] as List)) {
//               if (uid is String) {
//                 sets.add(QuestionSet(uid, uid, 0));
//               }
//             }
//           }
//           // 2) questionSets: [ {id,name,count}, ... ]
//           else if (body['questionSets'] is List) {
//             for (var e in (body['questionSets'] as List)) {
//               if (e is Map<String, dynamic>) {
//                 sets.add(QuestionSet.fromJson(e));
//               }
//             }
//           }
//           // 3) data: [...]
//           else if (body['data'] is List) {
//             for (var e in (body['data'] as List)) {
//               if (e is Map<String, dynamic>) {
//                 sets.add(QuestionSet.fromJson(e));
//               }
//             }
//           }
//         }
//         else if (body is List) {
//           for (var e in body) {
//             if (e is Map<String, dynamic>) {
//               sets.add(QuestionSet.fromJson(e));
//             }
//           }
//         }
//
//         setState(() => _sets = sets);
//         if (_sets.isEmpty) {
//           debugPrint('⚠️ questionSets list is empty');
//         }
//       } else {
//         debugPrint('❌ fetchQuestionSets failed: ${res.statusCode}');
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('讀取單元失敗：${res.statusCode}')));
//       }
//     } catch (e) {
//       debugPrint('❌ GET /questionSets exception: $e');
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('讀取單元錯誤：$e')));
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   /// 按下「創建房間」前，彈出 Dialog 輸入時限
//   Future<void> _onPressedCreate(String setId) async {
//     final input = await showDialog<String>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('請輸入遊戲時限（秒）'),
//         content: TextField(
//           controller: _timeController,
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(hintText: '例如 30'),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
//           TextButton(onPressed: () => Navigator.pop(context, _timeController.text), child: const Text('確定')),
//         ],
//       ),
//     );
//     if (input == null) return;
//     final t = int.tryParse(input);
//     if (t == null || t <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入大於 0 的整數')));
//       return;
//     }
//     await _createRoom(setId, t);
//   }
//
//   Future<void> _createRoom(String setId, int timeLimit) async {
//     setState(() => _loading = true);
//     final token = await getToken();
//
//     try {
//       final res = await http.post(
//         Uri.parse('$baseUrl/api/mcq/rooms'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type':  'application/json',
//         },
//         body: json.encode({
//           'host':       widget.hostUid,  // ← 一定要帶這個
//           'unitId':     setId,
//           'timeLimit': int.parse(_timeController.text),
//         }),
//       );
//
//       debugPrint('POST /rooms → status=${res.statusCode}, body=${res.body}');
//       if (res.statusCode == 200 || res.statusCode == 201) {
//         final roomId = json.decode(res.body)['roomId'] as String;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => RoomPage(roomId: roomId, initTimeLimit: timeLimit)),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('創建房間失敗：${res.statusCode}\n${res.body}')),
//         );
//       }
//     } catch (e) {
//       debugPrint('❌ POST /rooms exception: $e');
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('建立房間錯誤：$e')));
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('創建新房間')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         itemCount: _sets.length,
//         itemBuilder: (_, i) {
//           final s = _sets[i];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ListTile(
//               title: Text(s.name),
//               subtitle: s.questionCount > 0
//                   ? Text('共 ${s.questionCount} 題')
//                   : null,
//               trailing: ElevatedButton(
//                 onPressed: () => _onPressedCreate(s.id),
//                 child: const Text('創建房間'),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// /// 題庫 model
// class QuestionSet {
//   final String id;
//   final String name;
//   final int questionCount;
//   QuestionSet(this.id, this.name, this.questionCount);
//
//   factory QuestionSet.fromJson(Map<String, dynamic> j) => QuestionSet(
//     j['id'] as String,
//     j['name'] as String,
//     (j['count'] as int?) ??
//         (j['length'] as int?) ??
//         (j['questionsCount'] as int?) ??
//         0,
//   );
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'room_page.dart';

class CreateRoomPage extends StatefulWidget {
  final String hostUid;
  const CreateRoomPage({Key? key, required this.hostUid}) : super(key: key);

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  bool _loading = true;
  List<QuestionSet> _sets = [];

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

  Future<void> _onPressedCreate(String unitId) async {
    // Dialog 輸入房號和時限
    final codeController = TextEditingController();
    final timeController = TextEditingController(text: '30');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('設定房號與時限'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: '房間號碼',
                hintText: '例如 1234',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '遊戲時限（秒）',
                hintText: '例如 45',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'roomId': codeController.text.trim(),
                'timeLimit': int.tryParse(timeController.text.trim()) ?? 0,
              });
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final roomCode = result['roomId'] as String;
    final timeLimit = result['timeLimit'] as int;
    if (roomCode.isEmpty || timeLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入正確房號與時限')),
      );
      return;
    }
    await _createRoom(unitId, roomCode, timeLimit);
  }

  Future<void> _createRoom(
      String unitId,
      String roomCode,
      int timeLimit,
      ) async {
    setState(() => _loading = true);
    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/api/mcq/rooms'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'host': widget.hostUid,
          'unitId': unitId,
          'timeLimit': timeLimit,
          'roomId': roomCode,
        }),
      );
      debugPrint('POST /rooms → ${res.statusCode}, ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoomPage(
              roomId: roomCode,
              initTimeLimit: timeLimit,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('創建房間失敗：${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('建立房間錯誤：$e')),
      );
    } finally {
      setState(() => _loading = false);
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

