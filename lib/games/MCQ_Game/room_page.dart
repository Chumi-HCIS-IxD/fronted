import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/auth_api_service.dart';
import 'api.dart';
import 'mcq_game_page.dart';
import 'host_monitor_page.dart';


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

    // 3) 第一次抓狀態
    await _refreshStatus();
    if (!isHost && _currentUid != null) {
      await _joinRoom();
    }
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
        final newHostName      = await _lookupName(newHostUid);
        final newPlayersNames  = await Future.wait(filteredPlayers.map(_lookupName));

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
        // ✅ 自動跳轉：老師進入 HostGameMonitorPage
        if (isHost && newStatus == 'started') {
          debugPrint('👀 檢查條件：isHost=$isHost, status=$newStatus');
          _timer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HostGameMonitorPage(roomId: widget.roomId),
            ),
          );
        }

        // ✅ 自動跳轉：學生進入 McqGamePage
        if (!isHost && newStatus == 'started') {
          _timer?.cancel();
          _enterGame(); // 內部已處理 pushReplacement
        }
      }
    } catch (e) {
      debugPrint('Status fetch exception: $e');
    }
  }

  Future<String> _lookupName(String uid) async {
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
        return map['name'] as String? ?? uid;
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
                      '創建者：$hostName老師',
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
  Widget _buildAction() {
    if (isHost && status != 'started') {
      // 老師還沒開始遊戲 → 顯示按鈕
      return ElevatedButton(
        onPressed: _startGameAsHost,
        child: const Text('開始遊戲'),
      );
    }

    if (!isHost && status != 'started') {
      // 學生還沒開始遊戲 → 顯示提示文字
      return const Text(
        '等待老師開始...',
        style: TextStyle(fontSize: 16, color: Colors.orange),
      );
    }

    // 遊戲開始後 → 不顯示任何按鈕（因為會自動跳轉）
    return const SizedBox.shrink();
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
      await _refreshStatus();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開始遊戲失敗：${res.body}')),
      );
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
    }
  }
}