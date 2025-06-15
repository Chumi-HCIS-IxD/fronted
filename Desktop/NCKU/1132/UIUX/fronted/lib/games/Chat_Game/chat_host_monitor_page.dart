// // lib/games/Chat_Game/chat_host_monitor_page.dart
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import '../../services/auth_api_service.dart';
// import '../../theme/colors.dart';
// import '../../theme/dimens.dart';
// import 'chat_api.dart';
// import 'chat_game_page.dart';
//
// // lib/games/Chat_Game/chat_host_monitor_page.dart
//
// class ChatHostMonitorPage extends StatefulWidget {
//   final String roomId;
//   final String hostName;
//   const ChatHostMonitorPage({Key? key, required this.roomId, required this.hostName}) : super(key: key);
//   @override State<ChatHostMonitorPage> createState() => _ChatHostMonitorPageState();
// }
//
// class _ChatHostMonitorPageState extends State<ChatHostMonitorPage> {
//   late Timer _timer;
//   String partnerName = '';
//   String partnerAvatarUrl = ''; // 如果要自訂圖片
//   String topic = '';
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _refresh(); // 立刻抓一次
//     _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
//   }
//
//   Future<void> _refresh() async {
//     try {
//       final token = await getToken();
//       // 1) 抓主題
//       final tRes = await http.get(Uri.parse('$baseUrl/api/chat/rooms/${widget.roomId}/topic'),
//           headers: {'Authorization':'Bearer $token'});
//       if (tRes.statusCode == 200) {
//         final m = json.decode(tRes.body) as Map<String, dynamic>;
//         topic = m['topic'] as String? ?? '';
//       }
//
//       // 2) 抓配對結果
//       final gRes = await http.get(Uri.parse('$baseUrl/api/chat/rooms/${widget.roomId}/groups/${await getUserId()}'),
//           headers: {'Authorization':'Bearer $token'});
//       if (gRes.statusCode == 200) {
//         final m = json.decode(gRes.body) as Map<String, dynamic>;
//         final uid = m['partner'] as String;
//         // 拿 partner 的名字
//         final pRes = await http.get(Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
//             headers: {'Authorization':'Bearer $token'});
//         if (pRes.statusCode == 200) {
//           partnerName = (json.decode(pRes.body) as Map<String,dynamic>)['name'] as String;
//         } else {
//           partnerName = uid;
//         }
//       }
//     } catch (_) {}
//     if (mounted) setState(() => _loading = false);
//   }
//
//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     return Scaffold(
//       backgroundColor: AppColors.primaryBG,
//       appBar: AppBar(
//         leading: BackButton(color: Colors.white),
//         title: const Text('配對結果'),
//         backgroundColor: AppColors.primary,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(Dimens.paddingPage),
//         child: Column(
//           children: [
//             // ——— 與設計稿一模一樣的主題卡 ———
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Column(
//                 children: [
//                   Text('聊天主題', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//                   const SizedBox(height:8),
//                   Text(topic, style: TextStyle(fontSize: 16)),
//                   // 如果要加臺羅，可以再加 Row(Text, Text)
//                 ],
//               ),
//             ),
//             const SizedBox(height: 32),
//             Text('您的配對聊天對象：', style: TextStyle(fontSize: 14)),
//             const SizedBox(height: 16),
//             CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
//             const SizedBox(height: 8),
//             Text(partnerName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: () {
//                 // 真正進入遊戲
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ChatGamePlayPage(
//                       authService: AuthApiService(baseUrl: baseUrl),
//                       roomId: widget.roomId,
//                       participants: [widget.hostName, partnerName],
//                     ),
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primaryLight,
//                 shape: StadiumBorder(),
//                 minimumSize: Size(double.infinity, 48),
//               ),
//               child: const Text('開始聊天 / khai-sì khai-káng'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }