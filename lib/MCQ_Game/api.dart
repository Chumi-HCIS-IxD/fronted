//api.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// 通用 API 設定
const String baseUrl = 'http://140.116.245.157:5019';

/// 從 SharedPreferences 拿 userToken
Future<String> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userToken') ?? '';
}

/// 呼叫 /api/users/profile 拿 UID
Future<String> getUserId() async {
  final token = await getToken();
  final res = await http.get(
    Uri.parse('$baseUrl/api/users/profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (res.statusCode == 200) {
    final data = json.decode(res.body) as Map<String, dynamic>;
    return data['uid']?.toString() ?? '';
  }
  throw Exception('無法取得使用者 UID (${res.statusCode})');
}

/// Room 資料結構
class Room {
  final String host;
  final List<String> players;
  final String roomId;
  final String unitId;
  final int timeLimit;

  Room({
    required this.host,
    required this.players,
    required this.roomId,
    required this.unitId,
    required this.timeLimit,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    host:      j['host']     as String,
    players:   (j['players'] as List<dynamic>).cast<String>(),
    roomId:    j['roomId']    as String,
    unitId:    j['unitId']    as String? ?? '',
    timeLimit: j['timeLimit'] as int? ?? 60,
  );
}