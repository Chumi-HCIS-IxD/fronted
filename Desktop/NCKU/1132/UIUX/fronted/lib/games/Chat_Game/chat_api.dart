//chat_api.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../services/auth_api_service.dart';


// 通用 API 設定
const String baseUrl = 'http://140.116.245.157:5019';

/// 從 SharedPreferences 拿 userToken
Future<String> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userToken') ?? '';
}

Future<String> getUserId() async {
  try {
    final auth = AuthApiService(baseUrl: baseUrl);
    final profile = await auth.fetchUserProfile();
    final uid = profile?['uid']?.toString();
    if (uid == null || uid.isEmpty) {
      throw Exception('回傳的 profile 內沒有 uid');
    }
    return uid;
  } catch (e) {
    debugPrint('⚠️ getUserId via AuthApiService error: $e');
    rethrow;
  }
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

Future<String> lookupName(String uid) async {
  try {
    final token = await getToken(); // ✅ 改正函式名稱
    final uri = Uri.parse('$baseUrl/api/users/profile')
        .replace(queryParameters: {'uid': uid});

    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      return map['name'] as String? ?? uid;
    } else {
      debugPrint('⚠️ 查詢 $uid 的名稱失敗：${res.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ 查詢 $uid 的名稱時發生錯誤：$e');
  }
  return uid;
}
