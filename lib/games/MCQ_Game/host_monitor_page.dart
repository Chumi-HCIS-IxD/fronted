import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'result_page.dart';
import '../../services/auth_api_service.dart';
import 'api.dart';

class HostGameMonitorPage extends StatefulWidget {
  final String roomId;
  const HostGameMonitorPage({super.key, required this.roomId});

  @override
  State<HostGameMonitorPage> createState() => _HostGameMonitorPageState();
}

class _HostGameMonitorPageState extends State<HostGameMonitorPage> {
  final AuthApiService _authApi = AuthApiService(baseUrl: baseUrl);
  List<Map<String, dynamic>> students = []; // 包含 uid、username、submitted
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      debugPrint('🚀 開始抓取狀態...');

      // 1. 拿玩家名單
      final playersRes = await http.get(Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/players'));
      debugPrint('📥 playersRes.status=${playersRes.statusCode}');
      final playersData = jsonDecode(playersRes.body);
      final hostUid = playersData['host'] as String;
      final players = List<String>.from(playersData['players'])..remove(hostUid);
      debugPrint('👥 玩家名單（排除 host）: $players');

      // 2. 取得已繳交學生 UID
      final resultsRes = await http.get(Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/results'));
      debugPrint('📥 resultsRes.status=${resultsRes.statusCode}');
      final resultMap = jsonDecode(resultsRes.body) as Map<String, dynamic>;
      final submittedUids = (resultMap['results'] as List)
          .map((e) => e['user'] as String)
          .toList();
      debugPrint('✅ 已繳交名單: $submittedUids');


      // 3. 組合學生資訊
      final studentsInfo = await Future.wait(players.map((uid) async {
        final username = await lookupName(uid);
        final submitted = submittedUids.contains(uid);
        debugPrint('🔍 $uid (${username}) submitted=$submitted');
        return {
          'uid': uid,
          'username': username,
          'submitted': submitted,
        };
      }));

      setState(() => students = studentsInfo);

      // 4. 判斷是否全部完成
      if (studentsInfo.isNotEmpty && studentsInfo.every((s) => s['submitted'] == true)) {
        debugPrint('🎉 所有學生都完成了作答，跳轉至結果頁');
        _pollingTimer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultPage(
                roomId: widget.roomId,
                uid: 'host',
                score: 0,
                max: 0,
                answers: const [],
              ),
            ),
          );
        }
      } else {
        debugPrint('⏳ 尚有學生未完成');
      }

    } catch (e) {
      debugPrint('❌ fetch error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6ED),
      appBar: AppBar(
        title: const Text('學生作答狀況'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: student['submitted'] ? Colors.green : Colors.grey,
                  child: Text(student['username'][0], style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(student['username'], style: const TextStyle(fontSize: 16))),
                Icon(
                  student['submitted'] ? Icons.check_circle : Icons.pending,
                  color: student['submitted'] ? Colors.green : Colors.grey,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
