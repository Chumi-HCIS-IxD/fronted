// lib/games/MCQ_Game/room_selection_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import 'create_room_page.dart';
import 'host_monitor_page.dart';
import 'room_page.dart';
import 'api.dart';

const String teacherUid = 'a07fe81b-1f73-46ea-9d52-473017069c43';

class RoomSelectionPage extends StatefulWidget {
  const RoomSelectionPage({Key? key}) : super(key: key);
  @override
  State<RoomSelectionPage> createState() => _RoomSelectionPageState();
}

class _RoomSelectionPageState extends State<RoomSelectionPage> {
  final AuthApiService _auth = AuthApiService(baseUrl: baseUrl);
  String? _uid;
  List<Map<String, dynamic>> rooms = [];
  Map<String, String> hostName = {};
  String filter = '';
  Map<String, dynamic>? selectedRoom;
  bool _loading = true;

  bool get isTeacher => _uid == teacherUid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1) 取 UID
    try {
      final p = await _auth.fetchUserProfile();
      _uid = p?['uid'] as String?;
    } catch (_) {}
    // 2) 取房間列表
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/mcq/rooms'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      rooms = (json.decode(res.body)['rooms'] as List)
          .cast<Map<String, dynamic>>();
      // 3) 取 host 名稱
      await Future.wait(rooms.map((r) async {
        final h = r['host'] as String;
        if (!hostName.containsKey(h)) {
          final r2 = await http.get(
            Uri.parse('$baseUrl/api/users/profile?uid=$h'),
            headers: {'Content-Type': 'application/json'},
          );
          if (r2.statusCode == 200) {
            final d = json.decode(r2.body) as Map<String, dynamic>;
            hostName[h] = d['name'] as String? ?? h;
          } else {
            hostName[h] = h;
          }
        }
      }));
    }
    setState(() => _loading = false);
  }

  Future<void> _enterRoom() async {
    if (selectedRoom == null) return;
    final id = selectedRoom!['roomId'] as String;
    final limit = selectedRoom!['timeLimit'] as int;

    // 學生加入房間的邏輯
    if (!isTeacher && _uid != null) {
      final token = await getToken();
      final r = await http.post(
        Uri.parse('$baseUrl/api/mcq/rooms/$id/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'user': _uid}),
      );
      if (r.statusCode != 200 && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('加入失敗：${r.statusCode}')));
        return;
      }
    }

    // 確保頁面仍然 mounted 後再進行導航
    if (!mounted) return;

    // 根據角色導航到不同頁面
    if (isTeacher) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HostGameMonitorPage(roomId: id),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoomPage(roomId: id, initTimeLimit: limit),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 過濾
    final filtered = rooms
        .where((r) => r['roomId'].toString().contains(filter.trim()))
        .toList();

    // 參數
    const double headerHeight = 300;
    const double overlap     = 20;
    const double btnHeight   = 56;

    return Scaffold(
      backgroundColor: AppColors.primaryBG,
      body: SafeArea(
        child: Stack(
          children: [
            // ─── HEADER ─────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/wax_apple_header.png',
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 15,
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.primary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    bottom: 230,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: const [
                        Text('選擇題',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(height: 4),
                        Text('suan-tik-tê',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── 主卡 & 列表 ────────────────
            Positioned(
              top: headerHeight + overlap,
              left: Dimens.paddingPage,
              right: Dimens.paddingPage,
              bottom: btnHeight + Dimens.paddingPage * 1.5,
              child: Container(
                padding: const EdgeInsets.all(Dimens.paddingPage),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius:
                  BorderRadius.circular(Dimens.radiusCard),
                ),
                child: Column(
                  children: [
                    // 搜尋
                    TextField(
                      onChanged: (v) => setState(() => filter = v),
                      decoration: InputDecoration(
                        hintText: '搜尋房間號碼',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              Dimens.radiusButton),
                          borderSide: BorderSide(
                              color: AppColors.primaryTint),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              Dimens.radiusButton),
                          borderSide: BorderSide(
                              color: AppColors.primaryTint),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              Dimens.radiusButton),
                          borderSide: BorderSide(
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 列表
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final r = filtered[i];
                          final h = r['host'] as String;
                          final name = hostName[h] ?? h;
                          final sel = selectedRoom?['roomId'] ==
                              r['roomId'];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => selectedRoom = r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius:
                                BorderRadius.circular(
                                    Dimens.radiusCard),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '房間號碼：${r['roomId']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.w500,
                                      color: sel
                                          ? Colors.white
                                          : Colors.black,

                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '創建者：$name老師',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: sel
                                          ? Colors.white70
                                          : AppColors.grey700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── 按鈕 ───────────────────────
            Positioned(
              left: Dimens.paddingPage * 4,   // 48px 左邊空白
              right: Dimens.paddingPage * 4,  // 48px 右邊空白
              bottom: Dimens.paddingPage,
              height: btnHeight,
              child: ElevatedButton(
                onPressed: isTeacher
                // 老師不需要選房號，直接創建房間
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateRoomPage(hostUid: 'a07fe81b-1f73-46ea-9d52-473017069c43',),
                    ),
                  );
                }
                // 學生則要選中房間才能加入
                    : selectedRoom == null
                    ? null
                    : _enterRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  shape: const StadiumBorder(),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTeacher ? '創建房間' : '加入房間',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTeacher ? 'tshang-kip pang-king' : 'ka-hip pang-king',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}