import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../pages/home_page.dart';
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import 'api.dart';
import 'mcq_game_page.dart';

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
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _loading = true;

  String _displayUnit    = '單元未知';
  String _displayTopic   = '';
  String _displayRoomId  = '';
  String _displayCreator = '';
  List<_UserResult> _results = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);

    try {
      final token = await getToken();

      // ─── 1. 先抓 status 了解 players 與 host ─────────────────────────
      final statusRes = await http.get(
        Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (statusRes.statusCode != 200) throw Exception('status ${statusRes.statusCode}');
      final statusJson = json.decode(statusRes.body) as Map<String, dynamic>;
      final hostUid      = statusJson['host']   as String? ?? '';
      _displayUnit       = statusJson['unitId'] as String? ?? '';
      final players      = List<String>.from(statusJson['players'] ?? [])..remove(hostUid);
      final totalNeed    = players.length;
      // ─── 2. 輪詢 /results 直到所有學生都交卷 ────────────────────────
      List<dynamic> rawResults = [];
      while (true) {
        final resRes = await http.get(
          Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/results'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final data = json.decode(resRes.body) as Map<String, dynamic>;
        rawResults = data['results'] as List<dynamic>;
        if (rawResults.length >= totalNeed) break; // 全部交卷才跳出
        await Future.delayed(const Duration(seconds: 1));
      }

      // ─── 3. 整理並轉成 _UserResult 清單 ─────────────────────────────
      final temp = <_UserResult>[];
      for (final m in rawResults.cast<Map<String, dynamic>>()) {
        final uid   = m['user']  as String;
        final score = (m['score'] as num).toInt();
        final name  = await _lookupUsername(uid, token);
        temp.add(_UserResult(userId: uid, displayName: name, score: score));
      }
      temp.sort((a, b) => b.score.compareTo(a.score));
      _results = temp;

      // 額外顯示資訊
      _displayCreator = await _lookupUsername(hostUid, token);
      _displayRoomId  = widget.roomId;
    } catch (e) {
      debugPrint('loadAllData error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('結果載入失敗：$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 準備前三名
    final top3 = _results.length >= 3
        ? _results.take(3).toList()
        : _results.toList();

    return Scaffold(
      backgroundColor: AppColors.primaryBG,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // 標題區
            Center(
              child: Column(
                children: const [
                  Text('選擇題',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('suan-tik-tê',
                      style:
                      TextStyle(color: AppColors.primary, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 單元／房號／主題／建立者
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('單元：$_displayUnit', style: const TextStyle(fontSize: 15)),
                      const Spacer(),
                      Text('房號：$_displayRoomId', style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '主題：${_displayTopic.isEmpty ? '' : _displayTopic}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      Text('建立者：$_displayCreator', style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 排行榜標題
            const Center(
              child: Text('排行榜！', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            // 前三名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: top3.map((ur) {
                  final idx = top3.indexOf(ur);
                  final isCenter = idx == 1;
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: isCenter ? 36 : 28,
                        backgroundColor: AppColors.primaryTint,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(ur.displayName,
                          style: TextStyle(
                              fontSize: isCenter ? 14 : 12,
                              fontWeight:
                              isCenter ? FontWeight.bold : FontWeight.normal),
                          overflow: TextOverflow.ellipsis),
                      Text('+${ur.score}分',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: isCenter ? 14 : 12)),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            // 全部玩家列表
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
                itemBuilder: (_, i) {
                  final ur = _results[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryTint,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(ur.displayName, overflow: TextOverflow.ellipsis),
                    trailing: Text('${ur.score}分', style: const TextStyle(color: Colors.black87)),
                  );
                },
              ),
            ),
            // 底部按鈕
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                      child: const Text('回首頁'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        final authService = AuthApiService(baseUrl: baseUrl);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage(
                              authService: authService,
                              initialIndex: 2,
                            ),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text('訂正'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserResult {
  final String userId;
  final String displayName;
  final int score;
  _UserResult({
    required this.userId,
    required this.displayName,
    required this.score,
  });
}

