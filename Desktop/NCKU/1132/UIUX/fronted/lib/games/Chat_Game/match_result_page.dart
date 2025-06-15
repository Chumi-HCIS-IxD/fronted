// lib/games/Chat_Game/match_result_page.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import 'chat_api.dart';
import 'chat_game_page.dart';

class PlayerInfo {
  final String uid;
  final String name;

  PlayerInfo({required this.uid, required this.name});
}

class MatchResultPage extends StatefulWidget {
  final String roomId;
  final String hostName;
  final String hostUid;
  const MatchResultPage({
    Key? key,
    required this.roomId,
    required this.hostName,
    required this.hostUid,
  }) : super(key: key);

  @override
  State<MatchResultPage> createState() => _MatchResultPageState();
}

class _MatchResultPageState extends State<MatchResultPage> {
  bool _loading = true;
  String _topic = '', _topicTlio = '';
  Timer? _pollTimer;
  late bool _isHost;
  late String _myUid;
  late String _myName;
  List<PlayerInfo> _allPlayers = [];
  String _myPartnerName = '';
  String? _cachedToken;

  static const String baseUrl = 'http://140.116.245.157:5019'; // 與後端一致

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    final auth = AuthApiService(baseUrl: baseUrl);
    final profile = await auth.fetchUserProfile();
    _myUid = profile?['uid']?.toString() ?? '';
    _myName = profile?['name']?.toString() ?? '';
    _isHost = widget.hostUid == _myUid;
    await _fetchTopic();
    await _fetchRoomMembers();
    if (_isHost) {
      await _assignGroups();
    }
    await _fetchMyGroup();
    if (!_isHost) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
            (_) => _checkStatus(),
      );
    }
    setState(() => _loading = false);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchTopic() async {
    final token = await getToken();
    final tRes = await http.get(
      Uri.parse('$baseUrl/api/chat/rooms/${widget.roomId}/topic'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (tRes.statusCode == 200) {
      final m = json.decode(tRes.body);
      _topic = m['topic'] ?? '';
      _topicTlio = m['topicTlio'] ?? '';
    }
  }

  Future<void> _fetchRoomMembers() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/chat/rooms/${widget.roomId}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final auth = AuthApiService(baseUrl: baseUrl);
      final roomData = json.decode(res.body);
      final memberUids = List<String>.from(roomData['members'] ?? []);
      _allPlayers = [];
      for (String uid in memberUids) {
        final userProfile = await auth.fetchUserProfileByUid(uid);
        String name = userProfile?['name'] ?? uid;
        _allPlayers.add(PlayerInfo(uid: uid, name: name));
      }
      // for (String uid in memberUids) {
      //   final auth = AuthApiService(baseUrl: baseUrl);
      //   final userProfile = await auth.fetchUserProfileByUid(uid);
      //   String name = userProfile?['name']?.toString() ?? uid;
      //   _allPlayers.add(PlayerInfo(uid: uid, name: name));
      // }
      // 加入老師（如果還沒）
      if (!_allPlayers.any((p) => p.uid == widget.hostUid)) {
        final userProfile = await auth.fetchUserProfileByUid(widget.hostUid);
        final hostName = userProfile?['name'] ?? widget.hostUid;
        _allPlayers.add(PlayerInfo(uid: widget.hostUid, name: hostName));
      }
      // if (!_allPlayers.any((p) => p.name == widget.hostName)) {
      //   _allPlayers.add(PlayerInfo(uid: 'teacher', name: widget.hostName));
      // }
    }
  }

  Future<void> _assignGroups() async {
    final token = await getToken();
    final url = '$baseUrl/api/chat/rooms/${widget.roomId}/assign';
    final resp = await http.post(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      print('Failed to assign groups: ${resp.statusCode}');
    }
  }

  Future<void> _fetchMyGroup() async {
    // 1. 透過 fetchUserProfile() 拿到完整 profile
    final profile = await AuthApiService(baseUrl: baseUrl).fetchUserProfile();
    print('🔍 profile: $profile');
    final uid = profile?['uid']?.toString();
    if (uid == null || uid.isEmpty) {
      print('Error: 無法取得 uid，profile 回傳 = $profile');
      setState(() => _myPartnerName = '無配對對象');
      return;
    }

    // 2. 直接用 uid 呼叫群組 API
    final url = '$baseUrl/api/chat/rooms/${widget.roomId}/groups/$uid';
    print('Fetching group info from: $url');

    try {
      final resp = await http.get(Uri.parse(url));
      print('Response status: ${resp.statusCode}, body: ${resp.body}');
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final members = List<String>.from(data['members'] ?? []);
        final partnerUid = members.firstWhere((x) => x != uid, orElse: () => '');
        if (partnerUid.isNotEmpty) {
          // 找 partner 的名字
          String partnerName = _allPlayers
              .firstWhere(
                  (p) => p.uid == partnerUid,
              orElse: () => PlayerInfo(uid: partnerUid, name: ''),
          )
              .name;
          if (partnerName.isEmpty || partnerName == partnerUid) {
            partnerName = await lookupName(partnerUid);
          }
          setState(() => _myPartnerName = partnerName);
          // final partner = _allPlayers.firstWhere(
          //       (p) => p.uid == partnerUid,
          //   orElse: () => PlayerInfo(uid: partnerUid, name: partnerUid),
          // );
          // setState(() => _myPartnerName = partner.name);
        } else {
          setState(() => _myPartnerName = '無配對對象');
        }
      } else {
        print('Failed to fetch group info: ${resp.statusCode}');
        setState(() => _myPartnerName = '無配對對象');
      }
    } catch (e) {
      print('Error fetching group info: $e');
      setState(() => _myPartnerName = '無配對對象');
    }
    if (_myPartnerName != null && _myPartnerName.isNotEmpty && _myPartnerName != '等待配對…') {
      _scheduleAutoNavigate();
    }
  }

  void _scheduleAutoNavigate() {
    const delay = Duration(seconds: 3);
    Future.delayed(delay, () {
      // 可能要再檢查一次狀態，或用 mounted 保護
      if (mounted) {
        _navigateToChat();
      }
    });
  }

  Future<void> _checkStatus() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/chat/rooms/${widget.roomId}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final js = json.decode(res.body);
      if (js['status'] == 'active') {
        _pollTimer?.cancel();
        _navigateToChat();
      }
    }
  }

  Future<void> _startChat() async {
    if (_myPartnerName == '無配對對象') return;

    final token = await getToken();   // ← 很可能回傳 null
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',     // 只有 token 存在才塞
    };

    final res = await http.post(
      Uri.parse('$baseUrl/api/chat/rooms/${widget.roomId}/start'),
      headers: headers,
    );

    debugPrint('START → ${res.statusCode}  ${res.body}');

    if (res.statusCode == 200) {
      _navigateToChat();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('啟動失敗（${res.statusCode}）')),
      );
    }
  }

  void _navigateToChat() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatGamePlayPage(
          authService: AuthApiService(baseUrl: baseUrl),
          roomId: widget.roomId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Opacity(
            opacity: 0.1,
            child: Image.asset(
              'assets/images/chat_game_header.png',
              width: w,
              height: 280,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingPage),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.grey900,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          '來聊天',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '房間號碼：${widget.roomId}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '創建者：${widget.hostName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 70),
                  Center(child: _buildTopicCard()),
                  const SizedBox(height: 30),
                  const Text(
                    '您的配對聊天對象：',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '請依照聊天主題和您的配對對象聊天！',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(child: _buildPartnerRow()),
                  const SizedBox(height: 20),
                  const Spacer(),
                  Center(
                    child: ElevatedButton(
                      onPressed: _startChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 14,
                        ),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '開始聊天',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'khai-sí khai-káng',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -20,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '聊天主題',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const Text(
                  'tē-it tē',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _topic.isEmpty ? '台灣水果' : _topic,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _topicTlio.isEmpty ? 'Tâi-uân tsuí-kó' : _topicTlio,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                _myPartnerName.isNotEmpty ? _myPartnerName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _myPartnerName.isNotEmpty ? _myPartnerName : '等待配對...',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        for (int i = 0; i < 3; i++) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
          ),
        ]
      ],
    );
  }
}