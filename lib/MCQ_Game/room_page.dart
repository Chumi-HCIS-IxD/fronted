import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_api_service.dart';
import 'api.dart';
import 'mcq_game_page.dart';

class RoomPage extends StatefulWidget {
  final String roomId;
  /// 新增：從 CreateRoomPage 傳進來的時限
  final int initTimeLimit;

  const RoomPage({
    Key? key,
    required this.roomId,
    required this.initTimeLimit,  // ← 一定要加這行
  }) : super(key: key);

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  Timer? _timer;
  bool _loading = true;

  String? _currentUid;
  String hostUid = '';
  String hostName = '';
  List<String> playersUid = [];
  List<String> playersName = [];
  String status = '';
  String unitId = '';

  /// 改成用 widget.initTimeLimit 初始化
  late int timeLimit = widget.initTimeLimit;

  final AuthApiService _authApi = AuthApiService(baseUrl: baseUrl);

  bool get isHost => _currentUid != null && _currentUid == hostUid;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final profile = await _authApi.fetchUserProfile();
      _currentUid = profile?['uid'] as String?;
    } catch (e) {
      debugPrint('Fetch profile error: $e');
      _currentUid = null;
    }
    await _refreshStatus();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final token = await getToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        hostUid = data['host'] as String? ?? hostUid;
        playersUid = (data['players'] as List? ?? playersUid).cast<String>();
        status = data['status'] as String? ?? status;
        unitId = data['unitId'] as String? ?? unitId;
        timeLimit = data['timeLimit'] as int? ?? timeLimit;
        // 改用 num.toInt()：
        if (data['timeLimit'] != null) {
          timeLimit = (data['timeLimit'] as num).toInt();
        }

        hostName = await _lookupUsername(hostUid);
        playersName = await Future.wait(playersUid.map(_lookupUsername));
      } else {
        debugPrint('Status fetch failed: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Status fetch exception: $e');
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<String> _lookupUsername(String uid) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/api/users/profile')
          .replace(queryParameters: {'uid': uid});
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final profile = json.decode(res.body) as Map<String, dynamic>;
        return profile['username'] as String? ?? uid;
      } else {
        debugPrint('lookupUsername failed: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('lookupUsername exception: $e');
    }
    return uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('房間 ${widget.roomId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final participants = <Widget>[
      _buildAvatar(hostName, isHost: true),
      for (var name in playersName) _buildAvatar(name),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('房間 ${widget.roomId}'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _infoCard(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: participants),
            ),
            const Spacer(),
            Padding(padding: const EdgeInsets.all(16), child: _buildAction()),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.meeting_room, size: 40, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('房間：${widget.roomId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('主持人：$hostName', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text('單元：$unitId  •  狀態：$status', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, {bool isHost = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isHost ? Colors.orange : Colors.grey[300],
            child: Text(name.isNotEmpty ? name[0] : '', style: const TextStyle(color: Colors.white, fontSize: 20)),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAction() {
    // 若狀態是 started，就顯示「進入遊戲」
    if (status == 'started') {
      return ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => McqGamePage(
                unitId: unitId,
                roomId: widget.roomId,
                duration: timeLimit,
              ),
            ),
          );
        },
        child: const Text('進入遊戲'),
      );
    }

    // 非房主
    if (!isHost) {
      return const Text('等待老師開始…', style: TextStyle(color: Colors.orange));
    }

    // 房主才能看到「開始遊戲」
    return ElevatedButton(
      onPressed: _startGameAsHost,
      child: const Text('開始遊戲'),
    );
  }

  void _enterGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => McqGamePage(
          unitId: unitId,
          roomId: widget.roomId,
          duration: timeLimit,
        ),
      ),
    );
    return;
  }

  Future<void> _startGameAsHost() async {
    _timer?.cancel();
    setState(() => _loading = true);

    final token = await getToken();
    debugPrint('StartGame token: $token');
    debugPrint('Starting as host: $_currentUid');

    final body = {
      'host':   _currentUid,   // ← 一定要帶
      'unitId': unitId,
      // 'timeLimit':timeLimit,
    };
    debugPrint('POST /start body: $body');

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
        },
        body: json.encode(body),
      );

      debugPrint('POST /start → status=${res.statusCode}, body=${res.body}');
      if (res.statusCode == 200) {
        _enterGame();
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('開始遊戲失敗：${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開始遊戲錯誤：$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
      if (status != 'started') {
        _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
      }
    }
  }
}

// // lib/MCQ_Game/room_page.dart
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import '../services/auth_api_service.dart';
// import 'api.dart';
// import 'unit_selection_page.dart';
// import 'mcq_game_page.dart';
//
// class RoomPage extends StatefulWidget {
//   final String roomId;
//   const RoomPage({Key? key, required this.roomId}) : super(key: key);
//
//   @override
//   State<RoomPage> createState() => _RoomPageState();
// }
//
// class _RoomPageState extends State<RoomPage> {
//   Timer? _timer;
//   bool _loading = true;
//   bool get isHost => _currentUid != null && _currentUid == hostUid;
//   String hostUid = '';
//   String hostName = '';
//   List<String> playersUid = [];
//   List<String> playersName = [];
//   String status = '';
//   String unitId = '';
//   int timeLimit = 60;
//   late AuthApiService _authService;
//   // final AuthApiService authService;
//
//   String? _currentUid;
//
//   @override
//   void initState() {
//     super.initState();
//     _authService = AuthApiService(baseUrl: baseUrl);
//
//     // 1) 先拿自己
//     _authService.fetchUserProfile().then((profile) {
//       setState(() => _currentUid = profile?['uid'] as String?);
//     }).whenComplete(() {
//       // 2) 撈一次狀態
//       _refreshStatus();
//       // 3) 啟動每 3 秒輪詢
//       _timer = Timer.periodic(const Duration(seconds: 3), (_) {
//         _refreshStatus();
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _loadCurrentUserAndStartPolling() async {
//     try {
//       final profile = await _authService.fetchUserProfile();
//       _currentUid = profile?['uid'] as String?;
//     } catch (_) {
//       _currentUid = null;
//     }
//     await _refreshStatus();
//     _timer = Timer.periodic(
//       const Duration(seconds: 3),
//           (_) => _refreshStatus(),
//     );
//   }
//
//   Future<void> _refreshStatus() async {
//     if (!mounted) return;
//     setState(() => _loading = true);
//     final token = await getToken();
//     debugPrint('>>> startGame token: $token');
//     try {
//        final profile = await _authService.fetchUserProfile();
//        _currentUid = profile?['uid'] as String?;
//     } catch (_) {
//       _currentUid = null;
//     }
//
//     // 1) 先撈房間狀態（只回 UID）
//     final res = await http.get(
//       Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     if (res.statusCode == 200) {
//       final d = json.decode(res.body) as Map<String, dynamic>;
//       hostUid    = d['host']    as String? ?? hostUid;
//       playersUid = (d['players'] as List).cast<String>();
//       status     = d['status']  as String? ?? status;
//       unitId     = d['unitId']  as String? ?? unitId;
//       timeLimit  = d['timeLimit'] as int? ?? timeLimit;
//
//       // 2) 再用 /api/users/profile?uid=xxx 查名字
//       hostName = await _lookupUsername(hostUid);
//       playersName = await Future.wait(playersUid.map(_lookupUsername));
//     } else {
//       debugPrint('GET status failed: ${res.statusCode}');
//     }
//
//     if (!mounted) return;               // ← guard
//     setState(() => _loading = false);
//   }
//
//   /// 透過 GET /api/users/profile?uid=xxx 取得 username
//   Future<String> _lookupUsername(String uid) async {
//     try {
//       final token = await getToken();  // 取得剛存好的 access token
//       // 組成 Uri，放到 queryParameters 裡
//       final uri = Uri.parse('$baseUrl/api/users/profile')
//           .replace(queryParameters: {'uid': uid});
//
//       final res = await http.get(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $token',      // 若後端需要驗證
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body) as Map<String, dynamic>;
//         // 回傳 username，若 API 改名字請同步調整
//         return data['username'] as String? ?? uid;
//       } else {
//         debugPrint('❌ lookupUsername failed: '
//             'status=${res.statusCode}, body=${res.body}');
//       }
//     } catch (e) {
//       debugPrint('❌ lookupUsername exception: $e');
//     }
//     // 失敗就 fallback 回原本的 uid
//     return uid;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return Scaffold(
//         appBar: AppBar(title: Text('房間 ${widget.roomId}')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     final isHost = _currentUid != null && hostUid == _currentUid;
//     final participants = <Widget>[
//       _buildAvatar(hostName, isHost: true),
//       for (int i = 0; i < playersUid.length; i++)
//         _buildAvatar(playersName[i]),
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('房間 ${widget.roomId}'),
//         leading: BackButton(onPressed: () => Navigator.pop(context)),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // 資訊卡
//             Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [
//                 BoxShadow(color: Colors.black12, blurRadius: 8),
//               ],
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.meeting_room, size: 40, color: Colors.blue),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('房間：${widget.roomId}',
//                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 4),
//                         Text('主持人：$hostName', style: const TextStyle(color: Colors.grey)),
//                         const SizedBox(height: 4),
//                         Text('單元：$unitId  •  狀態：$status',
//                             style: const TextStyle(color: Colors.grey)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // 玩家列表
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(children: participants),
//             ),
//             const Spacer(),
//             // 按鈕區
//             Padding(padding: const EdgeInsets.all(16), child: _buildAction()),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAvatar(String name, {bool isHost = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 12),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 24,
//             backgroundColor: isHost ? Colors.orange : Colors.grey[300],
//             child: Text(name.substring(0, 1),
//                 style: const TextStyle(color: Colors.white, fontSize: 20)),
//           ),
//           const SizedBox(height: 6),
//           Text(name, style: const TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAction() {
//     // (1) 如果已經 started，直接「進入遊戲」
//     if (status == 'started') {
//       return ElevatedButton(
//         onPressed: _enterGame,
//         child: const Text('進入遊戲'),
//       );
//     }
//
//     // (2) 非房主，只看提示
//     if (!isHost) {
//       return const Text('等待老師開始…', style: TextStyle(color: Colors.orange));
//     }
//
//     // (3) 只有真正房主才看到「開始遊戲」按鈕
//     return ElevatedButton(
//       onPressed: _startGameAsHost,
//       child: const Text('開始遊戲'),
//     );
//   }
//
//   /// 導航到 MCQGamePage
//    void _enterGame() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => McqGamePage(
//           unitId: unitId,
//           roomId: widget.roomId,
//           duration: timeLimit,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _startGameAsHost() async {
//     _timer?.cancel();               // 不要讓已 dispose 的 Timer 再呼 setState
//     setState(() => _loading = true);
//
//     final token = await getToken();
//     final res = await http.post(
//       Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/start'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type':  'application/json',
//       },
//       body: json.encode({'unitId': unitId}),
//     );
//
//     setState(() => _loading = false);
//
//     if (res.statusCode == 200) {
//       // 房主一開始就進遊戲，不用等下一次輪詢
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => McqGamePage(
//             unitId:   unitId,
//             roomId:   widget.roomId,
//             duration: timeLimit,
//           ),
//         ),
//       );
//     } else {
//       // 403 or 其他錯誤，直接告訴使用者
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('開始遊戲失敗：${res.body}')),
//       );
//       // 若想繼續等學生進房則重啟輪詢
//       _timer = Timer.periodic(const Duration(seconds: 3), (_) {
//         _refreshStatus();
//       });
//     }
//   }
// }
