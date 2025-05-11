// lib/MCQ_Game/room_page.dart
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

    // 1) 先拿到自己的 uid
    try {
      final profile = await _authApi.fetchUserProfile();
      _currentUid = profile?['uid'] as String?;
    } catch (e) {
      debugPrint('fetch profile failed: $e');
    }

    // 2) 呼叫 join（一定要在拿到 _currentUid 之後）
    await _joinRoom();

    // 3) 第一次抓狀態
    await _refreshStatus();

    // 4) 啟動輪詢
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());

    setState(() => _loading = false);
  }

  Future<void> _joinRoom() async {
    if (_currentUid == null) {
      debugPrint('No uid，skip join');
      return;
    }

    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/join');

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user': _currentUid,   // ← 加上 user 欄位
        // 或是 'uid': _currentUid，要看後端需要哪個 key
      }),
    );

    debugPrint('JOIN ${res.statusCode}: ${res.body}');

    if (res.statusCode != 200) {
      // 失敗時提示
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

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final token = await getToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('STATUS JSON → ${res.body}');
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        hostUid = data['host'] ?? hostUid;
        playersUid = (data['players'] as List? ?? []).cast<String>();
        status = data['status'] ?? status;
        unitId = data['unitId'] ?? unitId;
        timeLimit = (data['timeLimit'] as num?)?.toInt() ?? timeLimit;

        hostName = await _lookupUsername(hostUid);
        playersName = await Future.wait(playersUid.map(_lookupUsername));
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
      }
    } catch (e) {
      debugPrint('lookupUsername exception: $e');
    }
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
      default: return '未命名單元';
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
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
      backgroundColor: const Color(0xFFEAF6ED),
      appBar: AppBar(
        title: Text('房間 ${widget.roomId}'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
            // Container(
            //   margin: const EdgeInsets.all(16),
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(8),
            //     boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            //   ),
            //   child: Row(
            //     children: [
            //       Text('房間號碼：${widget.roomId}', style: const TextStyle(fontWeight: FontWeight.bold)),
            //       const Spacer(),
            //       Text('創建者：$hostName'),
            //     ],
            //   ),
            // ),
            Flexible(
              child: Text(
                '房間號碼：${widget.roomId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '創建者：$hostName',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('單元一', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      '房號：${widget.roomId}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '建立者：$hostName',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
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

  Widget _buildAction() {
    if (status == 'started') {
      return ElevatedButton(
        onPressed: _enterGame,
        child: const Text('進入遊戲'),
      );
    }
    if (!isHost) {
      return const Text('等待老師開始…', style: TextStyle(color: Colors.orange));
    }
    return ElevatedButton(
      onPressed: _startGameAsHost,
      child: const Text('開始遊戲'),
    );
  }

  Future<void> _enterGame() async {
    final token = await getToken();
    // 1) 先呼叫一次 /rooms/<roomId> 拿 timeLimit
    final infoRes = await http.get(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    debugPrint('ROOM INFO = ${infoRes.body}');
    int duration = widget.initTimeLimit;
    if (infoRes.statusCode == 200) {
      final info = json.decode(infoRes.body) as Map<String, dynamic>;
      duration = (info['timeLimit'] as num?)?.toInt() ?? duration;
    }
    // 2) 再導到遊戲頁
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => McqGamePage(
          unitId: unitId,
          roomId: widget.roomId,
          uid: _currentUid!,
          duration: timeLimit,  // 正確秒數
        ),
      ),
    );
  }

  Future<void> _startGameAsHost() async {
    _timer?.cancel();
    setState(() => _loading = true);

    final token = await getToken();
    final body = {
      'host': _currentUid,
      'unitId': unitId,
    };

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        _enterGame();
        debugPrint('STATUS JSON = ${res.body}');
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('開始遊戲失敗：\${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開始遊戲錯誤：\$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
      if (status != 'started') {
        _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
      }
    }
  }

  // Future<void> _startGameAsHost() async {
  //   // 先取消輪詢、顯示 loading...
  //   await _joinRoom();
  //   await _refreshStatus();            // 確保 timeLimit 有更新
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => McqGamePage(
  //         unitId: unitId,
  //         roomId: widget.roomId,
  //         uid: _currentUid!,
  //         duration: timeLimit,         // ✔️ 這裡用 state
  //       ),
  //     ),
  //   );
  // }
}

