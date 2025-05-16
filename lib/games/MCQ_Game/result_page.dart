import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int max;
  final String roomId;
  final String uid;
  final List<Map<String, dynamic>> answers;

  const ResultPage({
    Key? key,
    required this.score,
    required this.max,
    required this.roomId,
    required this.uid,
    required this.answers,
  }) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _loading = true;
  String _unitTitle = '';
  String _displayRoomId = '';
  String _hostUid = '';
  String _hostName = '';
  List<Map<String, dynamic>> _results = [];
  final Map<String, String> _nameCache = {};

  @override
  void initState() {
    super.initState();
    _submitAndLoad();
  }

  Future<void> _submitAndLoad() async {
    final token = await getToken();

    // 1) POST 自己的答案
    // await http.post(
    //   Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/submit'),
    //   headers: {
    //     'Authorization': 'Bearer $token',
    //     'Content-Type': 'application/json',
    //   },
    //   body: json.encode({'user': widget.uid, 'answers': widget.answers}),
    // );

    // 2) GET 全部結果
    final res = await http.get(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/results'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      _results = (data['results'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ??
          [];
    }
    debugPrint("📦 所有 results = $_results");

    // 3) GET 房間狀態 → 取得 hostUid + hostName
    final statusRes = await http.get(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (statusRes.statusCode == 200) {
      final sd = json.decode(statusRes.body) as Map<String, dynamic>;
      _hostUid = sd['host'] as String? ?? '';
      final unitId = sd['unitId'] as String? ?? '';
      final num = unitId.split('_').last;
      _unitTitle = '單元$num';
      _hostName = await _lookupUsername(_hostUid, token);
    }

    final roomsRes = await http.get(
      Uri.parse('$baseUrl/api/mcq/rooms'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (roomsRes.statusCode == 200) {
      final jr = json.decode(roomsRes.body) as Map<String, dynamic>;
      final list = (jr['rooms'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [];
      final me = list.firstWhere(
            (r) => r['host'] == _hostUid,
        orElse: () => <String, dynamic>{},
      );
      _displayRoomId = me['roomId'] as String? ?? widget.roomId;
    }

    // 4) 過濾老師
    _results = _results.where((r) => r['user'] != _hostUid).toList();

    // 5) lookup 其餘玩家暱稱
    for (var r in _results) {
      final u = r['user'] as String;
      if (!_nameCache.containsKey(u)) {
        _nameCache[u] = await _lookupUsername(u, token);
      }
    }

    setState(() => _loading = false);
  }

  Future<String> _lookupUsername(String uid, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/profile')
          .replace(queryParameters: {'uid': uid});
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200) {
        final map = json.decode(resp.body) as Map<String, dynamic>;
        final uname = map['username'] as String?;
        if (uname != null && uname.isNotEmpty) return uname;
        final name = map['name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
    } catch (_) {}
    return uid.length >= 6 ? uid.substring(0, 6) : uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 排序、Top3 + 其他
    _results.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final topCount = _results.length >= 3 ? 3 : _results.length;
    final top3 = _results.take(topCount).toList();
    final allPlayers = _results;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('結算', style: TextStyle(color: Colors.black)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(_unitTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('房號：$_displayRoomId'),
                const SizedBox(width: 8),
                Text('建立者：$_hostName'),
              ],
            ),
          ),

          // 自己分數
          Container(
            width: double.infinity,
            color: const Color(0xFFEFF4FF),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              '你的分數：${widget.score} / ${widget.max}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),
          const Text('排行榜！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Top3
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(top3.length, (i) {
                final r = top3[i];
                final radius = i == 1 ? 40.0 : 30.0;
                final name = _shortName(_nameCache[r['user']] ?? '');
                final bonus = (i == 0 ? 30 : i == 1 ? 20 : 15);
                return Column(
                  children: [
                    CircleAvatar(
                      radius: radius,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, size: radius),
                    ),
                    const SizedBox(height: 6),
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('+${bonus}分', style: const TextStyle(color: Colors.green)),
                  ],
                );
              }),
            ),
          ),

          const Divider(height: 32),

          // 其他名次
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allPlayers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, idx) {
                final r = allPlayers[idx];
                final name = _nameCache[r['user']] ?? r['user'].substring(0, 6);
                final displayScore = (r['user'] == widget.uid)
                    ? widget.score
                    : (r['score'] as int);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.person),
                  ),
                  title: Text(name),
                  trailing: Text('${displayScore}分'),
                );
              },
            ),
          ),

          // 底部按鈕
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    child: const Text('回首頁'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 訂正
                    },
                    child: const Text('訂正'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortName(String name) => name.length <= 6 ? name : name.substring(0, 6);
}