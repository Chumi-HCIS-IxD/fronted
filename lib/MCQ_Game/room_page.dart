// // lib/MCQ_Game/room_page.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import '../services/auth_api_service.dart';
// import 'api.dart';
// import 'mcq_game_page.dart';
//
// class RoomPage extends StatefulWidget {
//   final String roomId;
//   final int initTimeLimit;
//
//   const RoomPage({
//     Key? key,
//     required this.roomId,
//     required this.initTimeLimit,
//   }) : super(key: key);
//
//   @override
//   State<RoomPage> createState() => _RoomPageState();
// }
//
// class _RoomPageState extends State<RoomPage> {
//   Timer? _timer;
//   bool _loading = true;
//
//   String? _currentUid;
//   String hostUid = '';
//   String hostName = '';
//   List<String> playersUid = [];
//   List<String> playersName = [];
//   String status = '';
//   String unitId = '';
//   late int timeLimit = widget.initTimeLimit;
//
//   final AuthApiService _authApi = AuthApiService(baseUrl: baseUrl);
//
//   bool get isHost => _currentUid != null && _currentUid == hostUid;
//
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }
//
//   Future<void> _initialize() async {
//     setState(() => _loading = true);
//
//     // 1) 拿自己的 uid
//     try {
//       final profile = await _authApi.fetchUserProfile();
//       _currentUid = profile?['uid'] as String?;
//     } catch (e) {
//       debugPrint('fetch profile failed: $e');
//       _currentUid = null;
//     }
//
//     // 2) 加入房間（要在拿到 uid 後）
//     if (_currentUid != null) {
//       await _joinRoom();
//     }
//
//     // 3) 第一次抓狀態
//     await _refreshStatus();
//
//     // 4) 啟動輪詢
//     _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
//
//     setState(() => _loading = false);
//   }
//
//   Future<void> _joinRoom() async {
//     final token = await getToken();
//     final uri = Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/join');
//     final res = await http.post(
//       uri,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: json.encode({ 'user': _currentUid }),
//     );
//     debugPrint('JOIN ${res.statusCode}: ${res.body}');
//     if (res.statusCode != 200 && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('加入房間失敗：${res.statusCode}')),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _refreshStatus() async {
//     if (!mounted) return;
//     setState(() => _loading = true);
//     final token = await getToken();
//     try {
//       final res = await http.get(
//         Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//       debugPrint('STATUS JSON → ${res.body}');
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body) as Map<String, dynamic>;
//         hostUid    = data['host']    ?? hostUid;
//         playersUid = (data['players'] as List? ?? []).cast<String>();
//         status     = data['status']  ?? status;
//         unitId     = data['unitId']  ?? unitId;
//         timeLimit  = (data['timeLimit'] as num?)?.toInt() ?? timeLimit;
//
//         hostName    = await _lookupUsername(hostUid);
//         playersName = await Future.wait(playersUid.map(_lookupUsername));
//       }
//     } catch (e) {
//       debugPrint('Status fetch exception: $e');
//     }
//     if (!mounted) return;
//     setState(() => _loading = false);
//   }
//
//   Future<String> _lookupUsername(String uid) async {
//     try {
//       final token = await getToken();
//       final uri = Uri.parse('$baseUrl/api/users/profile')
//           .replace(queryParameters: {'uid': uid});
//       final res = await http.get(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//       if (res.statusCode == 200) {
//         final profile = json.decode(res.body) as Map<String, dynamic>;
//         return profile['username'] as String? ?? uid;
//       }
//     } catch (e) {
//       debugPrint('lookupUsername exception: $e');
//     }
//     return uid;
//   }
//
//   String get unitName {
//     switch (unitId) {
//       case 'Unit_1': return '單元一';
//       case 'Unit_2': return '單元二';
//       case 'Unit_3': return '單元三';
//       case 'Unit_4': return '單元四';
//       case 'Unit_5': return '單元五';
//       case 'Unit_6': return '單元六';
//       default:      return '未命名單元';
//     }
//   }
//
//   String _todayString() {
//     final now = DateTime.now();
//     return '${now.year}/${now.month.toString().padLeft(2,'0')}/${now.day.toString().padLeft(2,'0')}';
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
//     // 參與者 avatars
//     final participants = <Widget>[
//       _buildAvatar(hostName, isHost: true),
//       for (var name in playersName) _buildAvatar(name),
//     ];
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFEAF6ED),
//       appBar: AppBar(
//         title: Text('房間 ${widget.roomId}'),
//         leading: BackButton(onPressed: () => Navigator.pop(context)),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // 單元＋日期列
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   const CircleAvatar(radius: 32, backgroundColor: Colors.grey),
//                   const SizedBox(width: 12),
//                   Text(unitName, style: const TextStyle(fontSize: 16)),
//                   const Spacer(),
//                   const Icon(Icons.calendar_today, size: 16),
//                   const SizedBox(width: 4),
//                   Text(_todayString()),
//                 ],
//               ),
//             ),
//
//             // 白底卡片：房間號碼＋建立者
//             Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
//               ),
//               child: Row(
//                 children: [
//                   Flexible(
//                     child: Text(
//                       '房間號碼：${widget.roomId}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 1,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Flexible(
//                     child: Text(
//                       '創建者：$hostName',
//                       style: const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 10,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 1,
//                       textAlign: TextAlign.right,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // 參與者 Avatar 列
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Wrap(
//                 spacing: 16,
//                 runSpacing: 16,
//                 children: participants,
//               ),
//             ),
//
//             const Spacer(),
//
//             // 按鈕區
//             Padding(padding: const EdgeInsets.all(16), child: _buildAction()),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAvatar(String name, {bool isHost = false}) {
//     return Column(
//       children: [
//         CircleAvatar(
//           radius: 24,
//           backgroundColor: isHost ? Colors.orange : Colors.grey[300],
//           child: Text(
//             name.isNotEmpty ? name[0] : '',
//             style: const TextStyle(color: Colors.white, fontSize: 20),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(name, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }
//
//   Widget _buildAction() {
//     if (status == 'started') {
//       return ElevatedButton(
//         onPressed: _enterGame,
//         child: const Text('進入遊戲'),
//       );
//     }
//     if (!isHost) {
//       return const Text('等待老師開始…', style: TextStyle(color: Colors.orange));
//     }
//     return ElevatedButton(
//       onPressed: _startGameAsHost,
//       child: const Text('開始遊戲'),
//     );
//   }
//
//   Future<void> _enterGame() async {
//     final token = await getToken();
//     final infoRes = await http.get(
//       Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//     final info = json.decode(infoRes.body);
//     final hostUid = info['host'] as String;
//     final startTs = info['startTime'] as int; // 後端回傳的 epoch(ms)
//     final timeLimit = (info['timeLimit'] as num).toInt();
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => McqGamePage(
//           unitId: widget.unitId,
//           roomId: widget.roomId,
//           uid: _currentUid!,
//           isHost: _currentUid == hostUid,     // <-- 新增
//           startTimestamp: startTs,             // <-- 新增
//           timeLimit: timeLimit,                // <-- 新增
//         ),
//       ),
//     );
//     int duration = widget.initTimeLimit;
//     if (infoRes.statusCode == 200) {
//       final info = json.decode(infoRes.body) as Map<String, dynamic>;
//       duration = (info['timeLimit'] as num?)?.toInt() ?? duration;
//     }
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => McqGamePage(
//           unitId: unitId,
//           roomId: widget.roomId,
//           uid: _currentUid!,
//           duration: timeLimit,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _startGameAsHost() async {
//     _timer?.cancel();
//     setState(() => _loading = true);
//
//     final token = await getToken();
//     final url = '$baseUrl/api/mcq/rooms/${widget.roomId}/start';
//     final body = {'host': _currentUid, 'unitId': unitId};
//
//     try {
//       final res = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(body),
//       );
//
//       if (res.statusCode == 200 && mounted) {
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (_) => AlertDialog(
//             title: const Text('遊戲已開始'),
//             content: const Text('學生已可進入遊戲，老師是否要前往遊戲畫面？'),
//             actions: [
//               TextButton(
//                 child: const Text('稍後返回'),
//                 onPressed: () => Navigator.pop(context),
//               ),
//               ElevatedButton(
//                 child: const Text('進入遊戲'),
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _enterGame();
//                 },
//               ),
//             ],
//           ),
//         );
//       } else if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('開始遊戲失敗：${res.body}')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('開始遊戲錯誤：$e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _loading = false);
//       if (status != 'started') {
//         _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
//       }
//     }
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_api_service.dart';
import 'api.dart';
import 'mcq_game_page.dart';

class RoomPage extends StatefulWidget {
  final String roomId;
  final int initTimeLimit;

  const RoomPage({
    Key? key,
    required this.roomId,
    required this.initTimeLimit,
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
  late int timeLimit = widget.initTimeLimit;

  final AuthApiService _authApi = AuthApiService(baseUrl: baseUrl);

  bool get isHost => _currentUid != null && _currentUid == hostUid;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _loading = true);
    // 1) 拿自己的 uid
    try {
      final profile = await _authApi.fetchUserProfile();
      _currentUid = profile?['uid'] as String?;
    } catch (_) {
      _currentUid = null;
    }
    // 2) 如果有 uid，就 join
    if (_currentUid != null) await _joinRoom();
    // 3) 第一次抓狀態
    await _refreshStatus();
    // 4) 輪詢
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
    setState(() => _loading = false);
  }

  Future<void> _joinRoom() async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/join');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'user': _currentUid}),
    );
    debugPrint('JOIN ${res.statusCode}: ${res.body}');
    if (res.statusCode != 200 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加入房間失敗：${res.statusCode}')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Future<void> _refreshStatus() async {
  //   if (!mounted) return;
  //
  //   final token = await getToken();
  //   try {
  //     final res = await http.get(
  //       Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
  //       headers: {'Authorization': 'Bearer $token'},
  //     );
  //     debugPrint('STATUS JSON → ${res.body}');
  //     if (res.statusCode == 200) {
  //       final data = json.decode(res.body) as Map<String, dynamic>;
  //
  //       // 1) 解析 hostUid
  //       final newHostUid = data['host'] as String? ?? hostUid;
  //
  //       // 2) 解析所有玩家列表，並去除創建者
  //       final rawPlayers = (data['players'] as List<dynamic>?)
  //           ?.cast<String>() ?? <String>[];
  //       final filtered = rawPlayers.where((u) => u != newHostUid).toList();
  //
  //       // 3) 解析其他欄位
  //       final newStatus    = data['status']    as String? ?? status;
  //       final newUnitId    = data['unitId']    as String? ?? unitId;
  //       final newTimeLimit = (data['timeLimit'] as num?)?.toInt() ?? timeLimit;
  //
  //       // 4) 查名字（只對過濾後的 players）
  //       final names = await Future.wait(filtered.map(_lookupUsername));
  //
  //       // 5) 一次性更新 state
  //       if (!mounted) return;
  //       setState(() {
  //         hostUid    = newHostUid;   // 仍留作紀錄，不在畫面底下顯示
  //         playersUid = filtered;
  //         playersName= names;
  //         status     = newStatus;
  //         unitId     = newUnitId;
  //         timeLimit  = newTimeLimit;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Status fetch exception: $e');
  //   }
  // }

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    final token = await getToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('STATUS JSON → ${res.body}');
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;

        // 1) 先拿新的 hostUid
        final newHostUid = data['host'] as String? ?? hostUid;

        // 2) 拿 raw players 並過濾掉 host
        final rawPlayers = (data['players'] as List<dynamic>?)?.cast<String>() ?? [];
        final filteredPlayers = rawPlayers.where((u) => u != newHostUid).toList();

        // 3) 其他欄位
        final newStatus    = data['status']    as String? ?? status;
        final newUnitId    = data['unitId']    as String? ?? unitId;
        final newTimeLimit = (data['timeLimit'] as num?)?.toInt() ?? timeLimit;

        // 4) 查名字
        final newHostName      = await _lookupUsername(newHostUid);
        final newPlayersNames  = await Future.wait(filteredPlayers.map(_lookupUsername));

        // 5) 一次更新 state（不碰 _loading）
        if (!mounted) return;
        setState(() {
          hostUid     = newHostUid;
          hostName    = newHostName;
          playersUid  = filteredPlayers;
          playersName = newPlayersNames;
          status      = newStatus;
          unitId      = newUnitId;
          timeLimit   = newTimeLimit;
        });
      }
    } catch (e) {
      debugPrint('Status fetch exception: $e');
    }
  }

  Future<String> _lookupUsername(String uid) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/api/users/profile')
          .replace(queryParameters: {'uid': uid});
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (res.statusCode == 200) {
        final map = json.decode(res.body) as Map<String, dynamic>;
        return map['username'] as String? ?? uid;
      }
    } catch (_) {}
    return uid;
  }

  String get unitName {
    switch (unitId) {
      case 'Unit_1': return '單元一';
      case 'Unit_2': return '單元二';
      case 'Unit_3': return '單元三';
      case 'Unit_4': return '單元四';
      case 'Unit_5': return '單元五';
      case 'Unit_6': return '單元六';
      default:        return '未命名單元';
    }
  }

  String _todayString() {
    final n = DateTime.now();
    return '${n.year}/${n.month.toString().padLeft(2,'0')}/${n.day.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('房間 ${widget.roomId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final participants = playersName.map((name) => _buildAvatar(name)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEAF6ED),
      appBar: AppBar(
        title: Text('房間 ${widget.roomId}'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 單元＋日期
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 32, backgroundColor: Colors.grey),
                  const SizedBox(width: 12),
                  Text(unitName, style: const TextStyle(fontSize: 16)),
                  const Spacer(),
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(_todayString()),
                ],
              ),
            ),

            // 房號＋建立者卡片
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      '房間號碼：${widget.roomId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '創建者：$hostName',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // 參與者 avatars
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: participants,
              ),
            ),

            const Spacer(),

            // 動作按鈕
            Padding(padding: const EdgeInsets.all(16), child: _buildAction()),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, {bool isHost = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: isHost ? Colors.orange : Colors.grey[300],
          child: Text(name.isNotEmpty ? name[0] : '', style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Widget _buildAction() {
  //   if (status == 'started') {
  //     return ElevatedButton(onPressed: _enterGame, child: const Text('進入遊戲'));
  //   }
  //   if (!isHost) {
  //     return const Text('等待老師開始…', style: TextStyle(color: Colors.orange));
  //   }
  //   return ElevatedButton(onPressed: _startGameAsHost, child: const Text('開始遊戲'));
  // }

  Widget _buildAction() {
    if (isHost) {
      // 老師
      if (status == 'started') {
        return ElevatedButton(
          onPressed: _enterGame,
          child: const Text('進入遊戲'),
        );
      }
      return ElevatedButton(
        onPressed: _startGameAsHost,
        child: const Text('開始遊戲'),
      );
    } else {
      // 學生 ALWAYS 可以進入遊戲頁，遊戲還沒開始就顯示「等待中」
      return ElevatedButton(
        onPressed: _enterGame,
        child: Text(
          status == 'started' ? '進入遊戲' : '進入遊戲（等待中）',
        ),
      );
    }
  }

  Future<void> _enterGame() async {
    final token = await getToken();

    // 1) 呼叫 status 拿遊戲狀態＋時限
    final res = await http.get(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('取得房間資訊失敗：${res.statusCode}')),
      );
      return;
    }

    // 2) 解析 JSON
    final data = json.decode(res.body) as Map<String, dynamic>;
    final host = data['host'] as String? ?? hostUid;
    // 這邊可能拿不到 startTime，就 fallback 成現在
    final rawStart = data['startTime'] as int?;
    final startTs = rawStart ?? DateTime.now().millisecondsSinceEpoch;
    // timeLimit 也有 fallback
    final limit = (data['timeLimit'] as num?)?.toInt() ?? widget.initTimeLimit;

    // 3) 進入遊戲頁
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => McqGamePage(
          unitId:         unitId,
          roomId:         widget.roomId,
          uid:            _currentUid!,
          isHost:         _currentUid == host,
          startTimestamp: startTs,
          timeLimit:      limit,
        ),
      ),
    );
  }

  // Future<void> _enterGame() async {
  //   final token = await getToken();
  //   final infoRes = await http.get(
  //     Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}'),
  //     headers: {'Authorization': 'Bearer $token'},
  //   );
  //   final data = json.decode(infoRes.body) as Map<String, dynamic>;
  //   final host    = data['host']        as String;
  //   final startTs = data['startTime']   as int;   // 後端必須回 epoch(ms)
  //   final limit   = (data['timeLimit']  as num).toInt();
  //
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => McqGamePage(
  //         unitId: unitId,                  // state 取出的單元
  //         roomId: widget.roomId,
  //         uid: _currentUid!,
  //         isHost: _currentUid == host,     // 標記教師
  //         startTimestamp: startTs,         // server 開始時間
  //         timeLimit: limit,                // server 時限（秒）
  //       ),
  //     ),
  //   );
  // }

  Future<void> _startGameAsHost() async {
    _timer?.cancel();
    // setState(() => _loading = true);
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'host': _currentUid, 'unitId': unitId}),
    );
    // setState(() => _loading = false);
    if (res.statusCode == 200 && mounted) {
      _enterGame();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開始遊戲失敗：${res.body}')),
      );
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
    }
  }
}