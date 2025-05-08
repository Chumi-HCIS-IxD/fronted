// // lib/MCQ_Game/unit_selection_page.dart
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import 'api.dart';
//
// class UnitSelectionPage extends StatefulWidget {
//   const UnitSelectionPage({Key? key}) : super(key: key);
//
//   @override
//   State<UnitSelectionPage> createState() => _UnitSelectionPageState();
// }
//
// class _UnitSelectionPageState extends State<UnitSelectionPage> {
//   bool _loading = true;
//   List<_UnitInfo> _units = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUnits();
//   }
//
//   Future<void> _fetchUnits() async {
//     setState(() => _loading = true);
//     try {
//       final token = await getToken();
//       final res = await http.get(
//         Uri.parse('$baseUrl/api/mcq/questionSets'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//       if (res.statusCode != 200) {
//         debugPrint('GET /questionSets failed: ${res.statusCode}');
//         return;
//       }
//
//       // 1) 解析 JSON
//       final decoded = json.decode(res.body);
//
//       // 2) 取出 id 字串列表
//       List<String> ids = [];
//       if (decoded is Map<String, dynamic>) {
//         if (decoded['unitIds'] is List) {
//           ids = List<String>.from(decoded['unitIds']);
//         }
//         else if (decoded['questionSets'] is List) {
//           ids = (decoded['questionSets'] as List)
//               .cast<Map<String, dynamic>>()
//               .map((e) => e['unitId'] as String)
//               .toList();
//         }
//         else if (decoded['data'] is List) {
//           ids = (decoded['data'] as List)
//               .cast<Map<String, dynamic>>()
//               .map((e) => e['unitId'] as String)
//               .toList();
//         }
//       } else if (decoded is List) {
//         // 如果回的是 List<String>
//         ids = List<String>.from(decoded);
//       }
//
//       // 3) 轉成 _UnitInfo list
//       setState(() {
//         _units = ids.map((u) => _UnitInfo(
//           id:    u,
//           title: u,          // 或從其它 key 拿更好看的 title
//           date:  '',         // 目前沒 createdAt，就先空字串
//           icon:  Icons.list_alt,
//         )).toList();
//       });
//     } catch (e) {
//       debugPrint('GET /questionSets exception: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('選擇單元')),
//       body: ListView.builder(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         itemCount: _units.length,
//         itemBuilder: (ctx, i) {
//           final u = _units[i];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8)),
//             child: ListTile(
//               leading: Icon(u.icon, color: Colors.blue),
//               title: Text('選擇題小遊戲'),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(u.title),
//                   Text(u.date, style: const TextStyle(color: Colors.grey)),
//                 ],
//               ),
//               trailing: const Icon(Icons.arrow_forward_ios),
//               onTap: () {
//                 // 回傳選中的 unitId
//                 Navigator.pop(context, u.id);
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _UnitInfo {
//   final String id;    // 要傳回後端的 unitId
//   final String title; // 顯示用
//   final String date;  // 顯示用
//   final IconData icon;
//
//   _UnitInfo({
//     required this.id,
//     required this.title,
//     required this.date,
//     required this.icon,
//   });
// }

// lib/MCQ_Game/unit_selection_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'mcq_game_page.dart';

/// 單元選擇頁面：選完之後直接進入遊戲
/// 由 RoomPage / CreateRoomPage 傳入 roomId、timeLimit
class UnitSelectionPage extends StatefulWidget {
  final String roomId;
  final int timeLimit;

  const UnitSelectionPage({
    Key? key,
    required this.roomId,
    required this.timeLimit,
  }) : super(key: key);

  @override
  State<UnitSelectionPage> createState() => _UnitSelectionPageState();
}

class _UnitSelectionPageState extends State<UnitSelectionPage> {
  bool _loading = true;
  List<String> _unitIds = [];

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  Future<void> _fetchUnits() async {
    setState(() => _loading = true);
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/mcq/questionSets'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        // 從 unitIds 取字串列表
        if (decoded is Map<String, dynamic> && decoded['unitIds'] is List) {
          _unitIds = List<String>.from(decoded['unitIds']);
        }
      } else {
        debugPrint('GET questionSets failed: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('GET questionSets exception: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('選擇單元')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         itemCount: _unitIds.length,
//         itemBuilder: (ctx, i) {
//           final u = _unitIds[i];
//           return ListTile(
//             title: Text('題庫：\$u'),
//             onTap: () {
//               _onSelectAnswer(opt);
//             },
//           );
//         },
//       ),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('選擇單元')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _unitIds.length,
        itemBuilder: (ctx, i) {
          final unit = _unitIds[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.blue),
              title: Text('題庫：$unit'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => McqGamePage(
                      unitId: unit,
                      roomId: widget.roomId,
                      duration: widget.timeLimit,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}