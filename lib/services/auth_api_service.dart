import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiService {
  final String baseUrl;

  AuthApiService({required this.baseUrl});

  Future<String?> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final uid = data['uid'];
      await _saveUid(uid);
      return null;
    } else {
      return jsonDecode(response.body)['message'] ?? '註冊失敗';
    }
  }

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final uid = data['uid'];
      await _saveUid(uid);
      return null;
    } else {
      return jsonDecode(response.body)['message'] ?? '登入失敗';
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final uid = await getUid();
    if (uid == null) return null;
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
  }

  Future<void> _saveUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
  }

  Future<String?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid');
  }
  Future<Map<String, bool>> fetchCompletedUnits() async {
    final uid = await getUid();
    if (uid == null) return {};

    final url = Uri.parse('$baseUrl/api/mcq/rooms/results');
    final res = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final result = data.firstWhere((r) => r["user"] == uid, orElse: () => null);
      final completedUnits = result?["completed_units"] ?? [];

      final statusMap = <String, bool>{};
      for (var unit in ["Unit_1", "Unit_2", "Unit_3", "Unit_4", "Unit_5", "Unit_6"]) {
        statusMap[unit] = completedUnits.contains(unit);
      }
      return statusMap;
    } else {
      return {};
    }
  }
}


