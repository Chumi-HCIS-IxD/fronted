// lib/games/Chat_Game/chat_room_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import 'chat_api.dart';
import 'chat_game_page.dart';
import 'match_result_page.dart';
import 'package:collection/collection.dart';

enum RoomStatus { waiting, matching, grouped, started }

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String hostName;
  final String hostUid;
  const ChatRoomPage({
    Key? key,
    required this.roomId,
    required this.hostName,
    required this.hostUid,
  }) : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final AuthApiService _auth = AuthApiService(baseUrl: baseUrl);
  bool _loading = true;
  String _uid = '';
  String _hostUid = '';
  String hostName = '';
  List<String> playersName = [];
  DateTime createdAt = DateTime.now();
  String unitId = '';
  bool _started = false;
  Timer? _pollTimer;
  RoomStatus _status = RoomStatus.waiting;
  Timer? _teacherRefreshTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _uid = await getUserId();
    } catch (e) {
      debugPrint('getUserId error: $e');
      _uid = '';
    }
    await _loadRoom();

    if (_uid == _hostUid) {
      _startTeacherRefresh();
    } else {
      _startPollingRoomStatus(); // 改名並修改邏輯
    }
  }

  /// 老師端用：每隔 3 秒自動抓一次房間，更新列表和狀態
  void _startTeacherRefresh() {
    _teacherRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      await _loadRoom();  // 抓最新 playersName + status

      // 如果房間狀態變為 matching，老師也跳轉到配對結果頁
      if (_status == RoomStatus.matching) {
        _teacherRefreshTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatchResultPage(
              roomId:   widget.roomId,
              hostName: hostName,     // 之前抓到的 hostName
              hostUid:  widget.hostUid,
            ),
          ),
        );
      }
      // 如果房間狀態變為 started，跳轉到遊戲頁面
      else if (_status == RoomStatus.started) {
        _teacherRefreshTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatGamePlayPage(
              authService: _auth,
              roomId: widget.roomId,
            ),
          ),
        );
      }
    });
  }

  /// 學生端用：輪詢房間狀態變化（加入更多調試信息）
  void _startPollingRoomStatus() {
    print('🔄 開始輪詢房間狀態 - 房間ID: ${widget.roomId}');

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) {
        print('⚠️ Widget已卸載，停止輪詢');
        return;
      }

      try {
        print('📡 正在檢查房間狀態...');
        final token = await getToken();
        final res = await http.get(
          Uri.parse('$baseUrl/api/chat/rooms/${widget.roomId}'),
          headers: {'Authorization': 'Bearer $token'},
        );

        print('🌐 API回應狀態碼: ${res.statusCode}');
        print('📄 API回應內容: ${res.body}');

        if (res.statusCode == 200) {
          final d = json.decode(res.body) as Map<String, dynamic>;
          final currentStatus = d['status'] as String?;
          final isStarted = d['started'] == true;

          print('🎯 房間狀態: $currentStatus');
          print('🎮 是否已開始: $isStarted');
          print('📊 完整房間數據: $d');

          // 檢查不同的房間狀態
          if (currentStatus == 'matching' || currentStatus == 'grouped') {
            print('🎲 房間進入配對環節，準備跳轉...');
            _pollTimer?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MatchResultPage(
                  roomId:   widget.roomId,
                  hostName: hostName,
                  hostUid:  widget.hostUid,  // 新增
                ),
              ),
            );
          } else if (currentStatus == 'active' || isStarted) {
            print('🎮 房間開始聊天，準備跳轉到遊戲頁面...');
            _pollTimer?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChatGamePlayPage(
                  authService: _auth,
                  roomId: widget.roomId,
                ),
              ),
            );
          } else {
            print('⏳ 房間仍在等待狀態');
          }

          // 同步更新參與者列表（不影響跳轉邏輯）
          await _updateParticipantsList(d);
        } else {
          print('❌ API請求失敗: ${res.statusCode} - ${res.body}');
        }
      } catch (e) {
        print('💥 輪詢發生錯誤: $e');
        debugPrint('Polling error: $e');
      }
    });
  }

  /// 更新參與者列表（從輪詢中分離出來）
  Future<void> _updateParticipantsList(Map<String, dynamic> roomData) async {
    try {
      final token = await getToken();

      // 更新玩家列表
      final raw = (roomData['players'] as List<dynamic>).cast<String>();
      List<String> newPlayersName = [];

      for (var uid in raw) {
        final r3 = await http.get(
          Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (r3.statusCode == 200) {
          final m = json.decode(r3.body) as Map<String, dynamic>;
          newPlayersName.add(m['name'] as String? ?? uid);
        } else {
          newPlayersName.add(uid);
        }
      }

      // 只在列表真的有變化時才更新 UI
      if (newPlayersName.length != playersName.length ||
          !const DeepCollectionEquality().equals(newPlayersName, playersName)) {
        setState(() {
          playersName = newPlayersName;
        });
      }
    } catch (e) {
      debugPrint('Update participants error: $e');
    }
  }

  Future<void> _loadRoom() async {
    setState(() => _loading = true);
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/api/chat/rooms/${widget.roomId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final d = json.decode(res.body) as Map<String, dynamic>;

        // 解析 host
        _hostUid = d['host'] as String;
        final hostUid = d['host'] as String;
        final r2 = await http.get(
          Uri.parse('$baseUrl/api/users/profile?uid=$hostUid'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (r2.statusCode == 200) {
          final m = json.decode(r2.body) as Map<String, dynamic>;
          hostName = m['name'] as String? ?? hostUid;
        } else {
          hostName = hostUid;
        }

        // 解析 players
        final raw = (d['players'] as List<dynamic>).cast<String>();
        playersName = [];
        for (var uid in raw) {
          final r3 = await http.get(
            Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (r3.statusCode == 200) {
            final m = json.decode(r3.body) as Map<String, dynamic>;
            playersName.add(m['name'] as String? ?? uid);
          } else {
            playersName.add(uid);
          }
        }

        // 解析房間狀態
        final statusStr = d['status'] as String?;
        _started = d['started'] == true;

        if (statusStr == 'matching') {
          _status = RoomStatus.matching;
        } else if (statusStr == 'active' || _started) {
          _status = RoomStatus.started;
        } else {
          _status = RoomStatus.waiting;
        }

        // createdAt (若後端有回傳 timestamp)
        if (d.containsKey('createdAt')) {
          final raw = d['createdAt'];
          if (raw is int) {
            createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
          } else if (raw is String) {
            try {
              createdAt = DateTime.parse(raw);
            } catch (_) {
              try {
                createdAt = HttpDate.parse(raw);
              } catch (e) {
                debugPrint('createdAt parse error: $e');
              }
            }
          }
        }

        // unitId
        unitId = d['unitId'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('loadRoom exception: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _teacherRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _onStartPressed() async {
    setState(() => _loading = true);
    try {
      final token = await getToken();

      // 1️⃣ 只呼叫配對 API（assign 端點應該會自動把 status 設為 matching）
      final assignRes = await http.post(
        Uri.parse('$baseUrl/api/chat/rooms/${widget.roomId}/assign'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('assignRes → ${assignRes.statusCode}: ${assignRes.body}');

      if (assignRes.statusCode == 200) {
        // 2️⃣ 直接跳轉到配對結果頁
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatchResultPage(
              roomId:   widget.roomId,
              hostName: hostName,
              hostUid:  widget.hostUid,
            ),
          ),
        );
      } else {
        throw Exception('配對失敗（HTTP ${assignRes.statusCode}）');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開始遊戲失敗：$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _uid == _hostUid;
    final participants = [hostName, ...playersName];
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    const double headerH = 300;
    const double overlap = 120;
    const double btnH = 56;

    return Scaffold(
      backgroundColor: AppColors.primaryBG,
      body: SafeArea(
        child: Stack(
          children: [
            // 1️⃣ 頭圖（透明度 0.1）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerH,
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/chat_game_header.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 2️⃣ 返回鈕
            Positioned(
              top: 16,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.primaryDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 3️⃣ 雙行標題 + 日期
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text('來聊天',
                      style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('lâi khai-káng',
                      style: TextStyle(
                          color: AppColors.primaryDark, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        '${createdAt.year}/${createdAt.month.toString().padLeft(2,'0')}/${createdAt.day.toString().padLeft(2,'0')}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4️⃣ 主卡片
            Positioned(
              top: overlap,
              left: Dimens.paddingPage,
              right: Dimens.paddingPage,
              bottom: btnH + Dimens.paddingPage,
              child: Container(
                padding: const EdgeInsets.all(Dimens.paddingPage),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: AppColors.primary, width: 1.2),
                  borderRadius:
                  BorderRadius.circular(Dimens.radiusCard),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // 房號 & 創建者 Pill
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '房間號碼：${widget.roomId}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14),
                            ),
                          ),
                          Text('創建者：$hostName',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text('遊戲說明：',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('香蕉仔是一隻熱情開朗的精靈，平常最愛東問西問、跟大家聊天交朋友。但近年大家越來越少用台語講話，發現整個山林越來越安靜，台語能量也在減退！為了恢復台灣山林的活力，決定舉辦一場超好玩的「水果聊天室」，邀請所有朋友們用台語來開槓、聊天、互相認識，分享彼此的人生經歷！',
                        style: TextStyle(
                            fontSize: 12)),
                    const SizedBox(height: 16),
                    Text('已加入：${participants.length} 人',
                        style: const TextStyle(
                            fontSize: 12)),
                    const SizedBox(height: 8),

                    // 參與者頭像
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: participants
                              .map((n) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.grey900,
                                child: Icon(Icons.person,
                                    color: AppColors.grey500),
                              ),
                              const SizedBox(height: 4),
                              Text(n,
                                  style:
                                  const TextStyle(fontSize: 10)),
                            ],
                          ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5️⃣ 進入按鈕
            Positioned(
              left: Dimens.paddingPage * 4,
              right: Dimens.paddingPage * 4,
              bottom: Dimens.paddingPage,
              height: 45,
              child: ElevatedButton(
                onPressed: isTeacher ? _onStartPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTeacher
                      ? AppColors.primaryLight
                      : AppColors.grey700,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  isTeacher ? '進入' : '等待老師開始',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
