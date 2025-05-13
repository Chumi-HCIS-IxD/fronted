// // lib/MCQ_Game/unit_selection_page.dart
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import 'api.dart';
// import 'mcq_game_page.dart';
//
// /// 單元選擇頁面：選完之後直接進入遊戲
// /// 由 RoomPage / CreateRoomPage 傳入 roomId、timeLimit
// class UnitSelectionPage extends StatefulWidget {
//   final String roomId;
//   final int timeLimit;
//
//   const UnitSelectionPage({
//     Key? key,
//     required this.roomId,
//     required this.timeLimit,
//   }) : super(key: key);
//
//   @override
//   State<UnitSelectionPage> createState() => _UnitSelectionPageState();
// }
//
// class _UnitSelectionPageState extends State<UnitSelectionPage> {
//   bool _loading = true;
//   List<String> _unitIds = [];
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
//       if (res.statusCode == 200) {
//         final decoded = json.decode(res.body);
//         // 從 unitIds 取字串列表
//         if (decoded is Map<String, dynamic> && decoded['unitIds'] is List) {
//           _unitIds = List<String>.from(decoded['unitIds']);
//         }
//       } else {
//         debugPrint('GET questionSets failed: ${res.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('GET questionSets exception: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     return Scaffold(
//       appBar: AppBar(title: const Text('選擇單元')),
//       body: ListView.builder(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         itemCount: _unitIds.length,
//         itemBuilder: (ctx, i) {
//           final unit = _unitIds[i];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//             child: ListTile(
//               leading: const Icon(Icons.list_alt, color: Colors.blue),
//               title: Text('題庫：$unit'),
//               trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => McqGamePage(
//                       unitId: unit,
//                       roomId: widget.roomId,
//                       duration: widget.timeLimit,
//                       uid: '',
//                     ),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }


// lib/MCQ_Game/unit_selection_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/auth_api_service.dart';
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
  String? _currentUid;

  final _authApi = AuthApiService(baseUrl: baseUrl);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1) 先抓當前使用者 UID
    try {
      final profile = await _authApi.fetchUserProfile();
      _currentUid = profile?['uid'] as String?;
    } catch (e) {
      debugPrint('fetchUserProfile error: $e');
    }
    // 2) 再抓單元列表
    await _fetchUnits();
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
                // 進入遊戲頁，傳入所有需要的參數
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => McqGamePage(
                      unitId: unit,
                      roomId: widget.roomId,
                      uid: _currentUid ?? '',
                      isHost: false,  // 單元選擇頁一定是學生，所以 false
                      startTimestamp: DateTime.now().millisecondsSinceEpoch,
                      timeLimit: widget.timeLimit,
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