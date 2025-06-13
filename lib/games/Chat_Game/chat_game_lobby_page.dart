import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_api_service.dart';
import 'chat_game_play_page.dart';

class ChatGameLobbyPage extends StatefulWidget {
  final AuthApiService authService;
  final String roomId;

  const ChatGameLobbyPage({
    Key? key,
    required this.authService,
    required this.roomId,
  }) : super(key: key);

  @override
  State<ChatGameLobbyPage> createState() => _ChatGameLobbyPageState();
}

class _ChatGameLobbyPageState extends State<ChatGameLobbyPage> {
  static const String _teacherUid = 'a07fe81b-1f73-46ea-9d52-473017069c43';

  late String _userUid;
  bool _isHost = false;
  bool _loading = false;
  String? _error;

  List<String> _uids = [];
  Map<String, String> _names = {};
  final Set<String> _roomsLeft = {};

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _setupUserAndStart();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _setupUserAndStart() async {
    final uid = await widget.authService.getUid();
    if (uid == null) {
      setState(() => _error = '無法取得使用者資訊');
      return;
    }
    _userUid = uid;
    _isHost = (uid == _teacherUid);

    // 先讀一次
    await _fetchPlayers();

    // 如果是教師，就先把自己 join 進房間
    if (_isHost) {
       final uriJoin = Uri.parse(
         '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}/join'
       );
       await http.post(
         uriJoin,
         headers: {'Content-Type': 'application/json'},
         body: jsonEncode({'user': _userUid}),
       );
       // 重新讀一次，這回就會看到自己也在 players 裡
       await _fetchPlayers();
     }

    // 輪詢：同時做成員更新 & 分組檢查
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _fetchPlayers();
    });
  }

  Future<void> _fetchPlayers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.parse(
        '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}',
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        throw '狀態碼 ${resp.statusCode}';
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      // 1. 取出 players/members
      List<String> members = [];
      if (data['players'] is List) {
        members = (data['players'] as List).cast<String>();
      } else if (data['members'] is List) {
        members = (data['members'] as List).cast<String>();
      } else if (data['groupMap'] is Map) {
        // groupMap: { "0": [uid1,uid2], "1": [...] }
        members = (data['groupMap'] as Map)
            .values
            .whereType<List>()
            .expand((e) => e.cast<String>())
            .toList();
      } else if (data['groups'] is List) {
        for (var grp in data['groups'] as List) {
          if (grp is List) members.addAll(grp.cast<String>());
        }
      }

      // 2. 如果曾經離開，就不顯示自己
      if (!_isHost && _roomsLeft.contains(widget.roomId)) {
        members.remove(_userUid);
      }
      setState(() => _uids = members);

      // 3. 非老師才檢查：有分到組就進遊戲
      if (!_isHost && data['groupMap'] is Map) {
        final gm = data['groupMap'] as Map<String, dynamic>;
        for (var entry in gm.entries) {
          final groupMembers = entry.value;
          if (groupMembers is List && groupMembers.contains(_userUid)) {
            // 停輪詢、跳轉
            _pollTimer?.cancel();
            _goToPlay();
            return;
          }
        }
      }

      // 4. 取 profile 資料
      await _fetchProfiles();
    } catch (e) {
      setState(() => _error = '讀取成員失敗：$e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _fetchProfiles() async {
    for (var uid in _uids) {
      try {
        final uri = Uri.parse(
          '${widget.authService.baseUrl}/api/users/profile?uid=$uid',
        );
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final js = jsonDecode(resp.body) as Map<String, dynamic>;
          final name = (js['name'] as String?)?.isNotEmpty == true
              ? js['name'] as String
              : js['username'] as String? ?? uid;
          _names[uid] = name;
        } else {
          _names[uid] = uid;
        }
      } catch (_) {
        _names[uid] = uid;
      }
    }
    if (mounted) setState(() {});
  }

  void _goToPlay() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatGamePlayPage(
          authService: widget.authService,
          roomId: widget.roomId,
          participants: _uids,
        ),
      ),
    );
  }

  Future<void> _startGame() async {
    if (_uids.length < 2) {
      setState(() => _error = '至少需要2位成員才能開始聊天');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.parse(
        '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}/assign',
      );
      final resp = await http.post(uri);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw '狀態碼 ${resp.statusCode}';
      }
      // 老師直接跳到 Play
      if (mounted) _goToPlay();
    } catch (e) {
      setState(() => _error = '啟動遊戲失敗：$e');
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<bool> _onWillPop() async {
    _roomsLeft.add(widget.roomId);
    return true;
  }

  Future<void> _refresh() async {
    await _fetchPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Expanded(child: Text('大廳：${widget.roomId}')),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
            IconButton(icon: const Icon(Icons.copy), onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.roomId));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('已複製房號')));
            }),
          ]),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('總人數：${_uids.length}'),
              const SizedBox(height: 8),
              const Text('已加入成員：', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_uids.isEmpty && _error == null)
                    ? const Center(child: Text('尚無成員加入'))
                    : ListView.builder(
                  itemCount: _uids.length,
                  itemBuilder: (c, i) {
                    final uid = _uids[i];
                    final name = _names[uid] ?? uid;
                    final isTeacher = uid == _teacherUid;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(name.isNotEmpty ? name[0] : '?'),
                          backgroundColor: isTeacher ? Colors.blue : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        title: Text(name),
                        subtitle: Text(uid),
                        trailing: isTeacher
                            ? Chip(
                          label: const Text('老師'),
                          backgroundColor: Colors.blue,
                          labelStyle: const TextStyle(color: Colors.white),
                        )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              if (_isHost)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _startGame,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('開始聊天'),
                  ),
                ),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}