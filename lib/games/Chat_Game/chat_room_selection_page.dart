// lib/games/Chat_Game/chat_room_selection_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import 'chat_create_room_page.dart';
import 'match_result_page.dart';
import 'chat_room_page.dart';
import 'chat_api.dart';

const String teacherUid = 'a07fe81b-1f73-46ea-9d52-473017069c43';

class ChatRoomSelectionPage extends StatefulWidget {
  const ChatRoomSelectionPage({Key? key}) : super(key: key);
  @override
  State<ChatRoomSelectionPage> createState() => _ChatRoomSelectionPageState();
}

class _ChatRoomSelectionPageState extends State<ChatRoomSelectionPage> {
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
    try {
      // 1) 取 UID（失敗也繼續往下）
      try {
        final p = await _auth.fetchUserProfile();
        _uid = p?['uid'] as String?;
      } catch (e) {
        debugPrint('fetchUserProfile error: $e');
      }

      // 2) 取房間列表
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/chat/rooms'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        List<Map<String, dynamic>> list = [];

        if (body is List) {
          list = body.cast<Map<String, dynamic>>();
        } else if (body is Map<String, dynamic>) {
          // 新增對 rooms 欄位的支援
          if (body['rooms'] is List) {
            list = (body['rooms'] as List).cast<Map<String, dynamic>>();
          }
          // 舊有支援 data 欄位
          else if (body['data'] is List) {
            list = (body['data'] as List).cast<Map<String, dynamic>>();
          } else {
            debugPrint('Unexpected rooms response structure: $body');
          }
        }
        rooms = list;
      } else {
        debugPrint('Fetch rooms failed: ${res.statusCode}');
      }

      // 3) 取 host 名稱（如果有 rooms 才做）
      if (rooms.isNotEmpty) {
        final token2 = await getToken();
        await Future.wait(rooms.map((r) async {
          final h = r['host'] as String;
          if (!hostName.containsKey(h)) {
            try {
              final r2 = await http.get(
                Uri.parse('$baseUrl/api/users/profile?uid=$h'),
                headers: {'Authorization': 'Bearer $token2'},
              );
              if (r2.statusCode == 200) {
                final d = json.decode(r2.body) as Map<String, dynamic>;
                hostName[h] = d['name'] as String? ?? h;
              } else {
                hostName[h] = h;
              }
            } catch (e) {
              debugPrint('Fetch hostName for $h error: $e');
              hostName[h] = h;
            }
          }
        }));
      }
    } catch (e, st) {
      debugPrint('_loadData unexpected error: $e\n$st');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _enterRoom() async {
    if (selectedRoom == null) return;
    final id = selectedRoom!['roomId'] as String;

    // 學生加入房間
    if (!isTeacher && _uid != null) {
      final token = await getToken();
      final r = await http.post(
        Uri.parse('$baseUrl/api/chat/rooms/$id/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'user': _uid}),
      );
      if (r.statusCode != 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入失敗：${r.statusCode}')),
        );
        return;
      }
    }

    if (!mounted) return;
    final hostUid = selectedRoom!['host'] as String;
    final displayName = hostName[hostUid] ?? hostUid;
    // 根據角色導航
    if (isTeacher) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) {
            final hostUid = selectedRoom!['host'] as String;
            final displayName = hostName[hostUid] ?? hostUid;
            return MatchResultPage(
              roomId:   id,
              hostName: displayName,            // 你的老師顯示名稱
              hostUid:  selectedRoom!['host'],  // 你的老師 UID
            );
          },
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomPage(roomId: id, hostUid: hostUid, hostName: displayName)),
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

    // 版型參數
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
                    'assets/images/chat_game_header.png',
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
                        Text('來聊天',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(height: 4),
                        Text('lâi khai-káng',
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
                  borderRadius: BorderRadius.circular(Dimens.radiusCard),
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
                          borderRadius: BorderRadius.circular(Dimens.radiusButton),
                          borderSide: BorderSide(color: AppColors.primaryTint),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimens.radiusButton),
                          borderSide: BorderSide(color: AppColors.primaryTint),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimens.radiusButton),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 列表
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final r = filtered[i];
                          final h = r['host'] as String;
                          final name = hostName[h] ?? h;
                          final sel = selectedRoom?['roomId'] == r['roomId'];
                          return GestureDetector(
                            onTap: () => setState(() => selectedRoom = r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(Dimens.radiusCard),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '房間號碼：${r['roomId']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: sel ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '創建者：$name 老師',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                      sel ? Colors.white70 : AppColors.grey700,
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
              left: Dimens.paddingPage * 4,
              right: Dimens.paddingPage * 4,
              bottom: Dimens.paddingPage,
              height: btnHeight,
              child: ElevatedButton(
                onPressed: isTeacher
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatCreateRoomPage(hostUid: teacherUid),
                    ),
                  );
                }
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
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTeacher ? 'tshang-kip pang-king' : 'ka-hip pang-king',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
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