// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import '../../services/auth_api_service.dart';
// import '../../theme/colors.dart';
// import '../../theme/dimens.dart';
// import 'chat_api.dart';
// import 'mcq_game_page.dart';
// import 'chat_host_monitor_page.dart';
//
//
// class RoomPage extends StatefulWidget {
//   final String roomId;
//   final int initTimeLimit;
//
//   const RoomPage({
//     Key? key,
//     required this.roomId,
//     required this.initTimeLimit,
//   }) : super(key: key);
//
//   @override
//   State<RoomPage> createState() => _RoomPageState();
// }
//
// class _RoomPageState extends State<RoomPage> {
//   Timer? _timer;
//   bool _loading = true;
//
//   String? _currentUid;
//   String hostUid = '';
//   String hostName = '';
//   List<String> playersUid = [];
//   List<String> playersName = [];
//   String status = '';
//   String unitId = '';
//   late int timeLimit = widget.initTimeLimit;
//
//   final AuthApiService _authApi = AuthApiService(baseUrl: baseUrl);
//
//   bool get isHost => _currentUid != null && _currentUid == hostUid;
//
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }
//
//   Future<void> _initialize() async {
//     setState(() => _loading = true);
//     // 1) 拿自己的 uid
//     try {
//       final profile = await _authApi.fetchUserProfile();
//       _currentUid = profile?['uid'] as String?;
//     } catch (_) {
//       _currentUid = null;
//     }
//
//     // 3) 第一次抓狀態
//     await _refreshStatus();
//     if (!isHost && _currentUid != null) {
//       await _joinRoom();
//     }
//     // 4) 輪詢
//     _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
//     setState(() => _loading = false);
//   }
//
//
//   Future<void> _joinRoom() async {
//     final token = await getToken();
//     final uri = Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/join');
//     final res = await http.post(
//       uri,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: json.encode({'user': _currentUid}),
//     );
//     debugPrint('JOIN ${res.statusCode}: ${res.body}');
//     if (res.statusCode != 200 && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('加入房間失敗：${res.statusCode}')),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _refreshStatus() async {
//     if (!mounted) return;
//     final token = await getToken();
//     try {
//       final res = await http.get(
//         Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//       debugPrint('STATUS JSON → ${res.body}');
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body) as Map<String, dynamic>;
//
//         // 1) 先拿新的 hostUid
//         final newHostUid = data['host'] as String? ?? hostUid;
//
//         // 2) 拿 raw players 並過濾掉 host
//         final rawPlayers = (data['players'] as List<dynamic>?)?.cast<String>() ?? [];
//         final filteredPlayers = rawPlayers.where((u) => u != newHostUid).toList();
//
//         // 3) 其他欄位
//         final newStatus    = data['status']    as String? ?? status;
//         final newUnitId    = data['unitId']    as String? ?? unitId;
//         final newTimeLimit = (data['timeLimit'] as num?)?.toInt() ?? timeLimit;
//
//         // 4) 查名字
//         final newHostName      = await _lookupName(newHostUid);
//         final newPlayersNames  = await Future.wait(filteredPlayers.map(_lookupName));
//
//         // 5) 一次更新 state（不碰 _loading）
//         if (!mounted) return;
//         setState(() {
//           hostUid     = newHostUid;
//           hostName    = newHostName;
//           playersUid  = filteredPlayers;
//           playersName = newPlayersNames;
//           status      = newStatus;
//           unitId      = newUnitId;
//           timeLimit   = newTimeLimit;
//         });
//         // ✅ 自動跳轉：老師進入 HostGameMonitorPage
//         if (isHost && newStatus == 'started') {
//           debugPrint('👀 檢查條件：isHost=$isHost, status=$newStatus');
//           _timer?.cancel();
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => HostGameMonitorPage(roomId: widget.roomId),
//             ),
//           );
//         }
//
//         // ✅ 自動跳轉：學生進入 McqGamePage
//         if (!isHost && newStatus == 'started') {
//           _timer?.cancel();
//           _enterGame(); // 內部已處理 pushReplacement
//         }
//       }
//     } catch (e) {
//       debugPrint('Status fetch exception: $e');
//     }
//   }
//
//   Future<String> _lookupName(String uid) async {
//     try {
//       final token = await getToken();
//       final uri = Uri.parse('$baseUrl/api/users/profile')
//           .replace(queryParameters: {'uid': uid});
//       final res = await http.get(uri, headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       });
//       if (res.statusCode == 200) {
//         final map = json.decode(res.body) as Map<String, dynamic>;
//         return map['name'] as String? ?? uid;
//       }
//     } catch (_) {}
//     return uid;
//   }
//
//   String get unitName {
//     switch (unitId) {
//       case 'Unit_1': return '單元一';
//       case 'Unit_2': return '單元二';
//       case 'Unit_3': return '單元三';
//       case 'Unit_4': return '單元四';
//       case 'Unit_5': return '單元五';
//       case 'Unit_6': return '單元六';
//       default:        return '未命名單元';
//     }
//   }
//
//   String _todayString() {
//     final n = DateTime.now();
//     return '${n.year}/${n.month.toString().padLeft(2,'0')}/${n.day.toString().padLeft(2,'0')}';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // ① loading 畫面 ---------------------------------------------------------
//     if (_loading) {
//       return Scaffold(
//         backgroundColor: AppColors.primaryBG,
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     // ② 頭像陣列 -------------------------------------------------------------
//     final avatars = playersName.map((n) => _buildAvatar(n)).toList();
//
//     // ③ 版面 -----------------------------------------------------------------
//     return Scaffold(
//       backgroundColor: AppColors.primaryBG,
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // ◎ 綠色 Header ----------------------------------------------------
//             Container(
//               padding: const EdgeInsets.symmetric(
//                   horizontal: Dimens.paddingPage, vertical: 20),
//               color: AppColors.primary,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // 房號 & 日期
//                   Text('房間編號：${widget.roomId}',
//                       style:
//                       const TextStyle(color: Colors.white, fontSize: 14)),
//                   const SizedBox(height: 4),
//                   Text(_todayString(),
//                       style: const TextStyle(color: Colors.white70, fontSize: 12)),
//                 ],
//               ),
//             ),
//
//             // ◎ 卡片：單元 + 老師 ------------------------------------------------
//             Container(
//               margin: const EdgeInsets.fromLTRB(
//                   Dimens.paddingPage, 20, Dimens.paddingPage, 12),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(Dimens.radiusCard),
//                 boxShadow: const [
//                   BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2))
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.book, color: AppColors.primary),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text('當前單元：$unitName',
//                         style: const TextStyle(fontSize: 14)),
//                   ),
//                   Text('$hostName 老師',
//                       style:
//                       const TextStyle(fontSize: 12, color: AppColors.grey500)),
//                 ],
//               ),
//             ),
//
//             // ◎ 參與者列表 ------------------------------------------------------
//             Padding(
//               padding:
//               const EdgeInsets.symmetric(horizontal: Dimens.paddingPage),
//               child: Wrap(spacing: 20, runSpacing: 16, children: avatars),
//             ),
//
//             const Spacer(),
//
//             // ◎ 動作按鈕 --------------------------------------------------------
//             Padding(
//               padding: const EdgeInsets.all(Dimens.paddingPage),
//               child: _buildAction(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAvatar(String name, {bool isHost = false}) {
//     return Column(
//       children: [
//         CircleAvatar(
//           radius: 24,
//           backgroundColor: isHost ? Colors.orange : Colors.grey[300],
//           child: Text(name.isNotEmpty ? name[0] : '', style: const TextStyle(color: Colors.white, fontSize: 20)),
//         ),
//         const SizedBox(height: 6),
//         Text(name, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }
//   Widget _buildAction() {
//     if (isHost && status != 'started') {
//       // 老師還沒開始遊戲 → 顯示按鈕
//       return ElevatedButton(
//         onPressed: _startGameAsHost,
//         child: const Text('開始遊戲'),
//       );
//     }
//
//     if (!isHost && status != 'started') {
//       // 學生還沒開始遊戲 → 顯示提示文字
//       return const Text(
//         '等待老師開始...',
//         style: TextStyle(fontSize: 16, color: Colors.orange),
//       );
//     }
//
//     // 遊戲開始後 → 不顯示任何按鈕（因為會自動跳轉）
//     return const SizedBox.shrink();
//   }
//
//   Future<void> _enterGame() async {
//     final token = await getToken();
//
//     // 1) 呼叫 status 拿遊戲狀態＋時限
//     final res = await http.get(
//       Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//     if (res.statusCode != 200) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('取得房間資訊失敗：${res.statusCode}')),
//       );
//       return;
//     }
//
//     // 2) 解析 JSON
//     final data = json.decode(res.body) as Map<String, dynamic>;
//     final host = data['host'] as String? ?? hostUid;
//     // 這邊可能拿不到 startTime，就 fallback 成現在
//     final rawStart = data['startTime'] as int?;
//     final startTs = rawStart ?? DateTime.now().millisecondsSinceEpoch;
//     // timeLimit 也有 fallback
//     final limit = (data['timeLimit'] as num?)?.toInt() ?? widget.initTimeLimit;
//
//     // 3) 進入遊戲頁
//     if (!mounted) return;
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => McqGamePage(
//           unitId:         unitId,
//           roomId:         widget.roomId,
//           uid:            _currentUid!,
//           isHost:         _currentUid == host,
//           startTimestamp: startTs,
//           timeLimit:      limit,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _startGameAsHost() async {
//     _timer?.cancel();
//     // setState(() => _loading = true);
//     final token = await getToken();
//     final res = await http.post(
//       Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/start'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: json.encode({'host': _currentUid, 'unitId': unitId}),
//     );
//     // setState(() => _loading = false);
//     if (res.statusCode == 200 && mounted) {
//       await _refreshStatus();
//     } else if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('開始遊戲失敗：${res.body}')),
//       );
//       _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
//     }
//   }
// }

// lib/games/MCQ_Game/chat_room_page.dart

import 'dart:async';
import 'dart:convert';
import 'package:chumi_frontend_fixed/games/MCQ_Game/result_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import 'api.dart';
import 'host_monitor_page.dart';
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
  final _auth = AuthApiService(baseUrl: baseUrl);
  Timer? _timer;
  bool _loading = true;

  String? _uid;
  String hostUid = '';
  String hostName = '';
  List<String> playersUid = [];
  List<String> playersName = [];
  String unitId = '';
  late int timeLimit;

  @override
  void initState() {
    super.initState();
    timeLimit = widget.initTimeLimit;
    _initialize();
  }

  Future<void> _initialize() async {
    // 1) 拿自己 uid
    try {
      final p = await _auth.fetchUserProfile();
      _uid = p?['uid'] as String?;
    } catch (_) {}

    // 2) 第一次撈狀態
    await _refreshStatus();

    // 3) 若為學生，自動加入
    if (_uid != null && _uid != hostUid) {
      await _joinRoom();
    }

    // 4) 每3秒輪詢一次
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
    setState(() => _loading = false);
  }

  Future<void> _joinRoom() async {
    final token = await getToken();
    await http.post(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/join'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: json.encode({'user': _uid}),
    );
  }

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('獲取房間狀態失敗：${res.statusCode}')),
        );
      }
      return;
    }
    final d = json.decode(res.body) as Map<String, dynamic>;
    debugPrint('✅ API 回應: $d');

    // Update hostUid
    hostUid = d['host'] as String? ?? hostUid;

    // Update player list (excluding host)
    final raw = (d['players'] as List<dynamic>?)?.cast<String>() ?? [];
    playersUid = raw.where((u) => u != hostUid).toList();
    debugPrint('👥 playersUid: $playersUid');

    // Fetch host and player names
    hostName = await _fetchName(hostUid);
    playersName = await Future.wait(playersUid.map(_fetchName));
    debugPrint('👥 playersName: $playersName');

    // Update unitId and timeLimit
    unitId = d['unitId'] as String? ?? unitId;
    timeLimit = (d['timeLimit'] as num?)?.toInt() ?? timeLimit;

    // Navigate based on status
    if (d['status'] == 'started') {
      _timer?.cancel();
      if (isHost) {
        debugPrint('老師跳轉到 HostGameMonitorPage');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HostGameMonitorPage(roomId: widget.roomId)),
        );
      } else {
        final startTs = (d['startTime'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
        debugPrint('學生跳轉到 McqGamePage');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => McqGamePage(
            unitId: unitId,
            roomId: widget.roomId,
            uid: _uid ?? '',
            isHost: false,
            startTimestamp: startTs,
            timeLimit: timeLimit,
          )),
        );
      }
      return;
    }

    if (d['status'] == 'finished' && isHost) {
      _timer?.cancel();
      debugPrint('老師跳轉到 ResultPage');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultPage(
          score: 0,
          max: 0,
          roomId: widget.roomId,
          uid: _uid ?? '',
          answers: const [],
        )),
      );
      return;
    }

    setState(() {});
  }

  Future<String> _fetchName(String uid) async {
    try {
      final token = await getToken();
      final r = await http.get(
        Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('獲取名稱: uid=$uid, 狀態=${r.statusCode}');
      if (r.statusCode == 200) {
        final m = json.decode(r.body) as Map<String, dynamic>;
        final name = m['name'] as String? ?? uid;
        debugPrint('名稱結果: $name');
        return name;
      }
    } catch (e) {
      debugPrint('獲取名稱失敗: uid=$uid, 錯誤=$e');
    }
    return uid;
  }

  Future<void> _startGame() async {
    _timer?.cancel();                 // 先停輪詢
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api/mcq/rooms/${widget.roomId}/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: json.encode({'host': _uid, 'unitId': unitId}),
    );

    // ⚠️ 一定要等後端成功 → 強制再跑一次 _refreshStatus() 來導航
    if (mounted && res.statusCode == 200) {
      await _refreshStatus();         // 立刻檢查 status==started → 跳頁
    } else if (mounted) {
      // 如果失敗，就把 timer 再開回去、不然會永遠不動
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開始遊戲失敗：${res.statusCode}')),
      );
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
    }
  }

  bool get isHost => _uid == hostUid;

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

  String get _subject {
    // 若後端無提供主題欄位，可自行改
    if (unitId == 'Unit_1') return '台灣水果';
    return '';
  }

  String get _today {
    final n = DateTime.now();
    return '${n.year}/${n.month.toString().padLeft(2, '0')}/${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    // 版型常數
    const headerH = 300.0;
    const overlap = 120.0;
    const btnH    = 50.0;

    return Scaffold(
      backgroundColor: AppColors.primaryBG,
      body: SafeArea(
        child: Stack(children: [
          // 1️⃣ 純綠色 Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(),
          ),

          // 2️⃣ 返回鈕
          Positioned(
            top: 30,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.primaryDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 3️⃣ 頭圖（透明度 0.2）、放在 header 下方
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerH,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/wax_apple_header.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 4️⃣ 雙行標題
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            height: headerH - 40,
            child: Column(
              children: const [
                SizedBox(height: 24),
                Text('選擇題',
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('suan-tik-tê',
                    style: TextStyle(
                        color: AppColors.primaryDark, fontSize: 14)),
              ],
            ),
          ),

          // 5️⃣ 單元＋主題＋日期
          Positioned(
            top: 80,
            left: Dimens.paddingPage,
            right: Dimens.paddingPage,
            child: Row(
              children: [
                // 單元＋主題
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(unitName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                              color: AppColors.primaryDark)),
                      const SizedBox(height: 4),
                      Text('主題：$_subject',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryDark)),
                    ],
                  ),
                ),
                // 日期
                Row(children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 4),
                  Text(_today,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark)),
                ]),
              ],
            ),
          ),

          // 6️⃣ 主卡片
          Positioned(
            top: 80 + overlap - 32,
            left: Dimens.paddingPage,
            right: Dimens.paddingPage,
            bottom: btnH + 40 + Dimens.paddingPage,
            child: Container(
              padding:
              const EdgeInsets.all(Dimens.paddingPage),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
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
                  // 房號 Pill
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8),
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
                  const Text('蓮霧仔是負責保管最古老的台語詞典，但由於語言能量減弱，詞典上的字開始模糊消失。為了重建詞庫，精靈們設計了一場「聽力挑戰賽」，邀請大家來比比誰最懂台語。只要選對越多題，就能找尋更多記憶碎片！',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 80),
                  Text('已加入：${playersName.length}',
                      style: const TextStyle(
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  // 參與者頭像
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: playersName
                            .map((n) => Column(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor:
                              AppColors.grey900,
                              child: Icon(
                                  Icons.person,
                                  color: AppColors
                                      .grey500),
                            ),
                            const SizedBox(
                                height: 4),
                            Text(n,
                                style:
                                const TextStyle(
                                    fontSize:
                                    10)),
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

          // 7️⃣ 準備 / 等待 按鈕
          Positioned(
            left: Dimens.paddingPage * 4,
            right: Dimens.paddingPage * 4,
            bottom: Dimens.paddingPage,
            height: btnH,
            child: ElevatedButton(
              onPressed: isHost ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isHost
                    ? AppColors.primary
                    : AppColors.grey300,
                shape: const StadiumBorder(),
              ),
              child: Text(
                  isHost ? '準備' : '等待老師開始…',
                  style: TextStyle(
                    fontSize: 16,
                    color: isHost
                        ? Colors.white
                        : AppColors.grey700,
                  )),
            ),
          ),
        ]),
      ),
    );
  }
}