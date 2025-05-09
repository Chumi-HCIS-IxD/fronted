import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiService {
  final String baseUrl;

  AuthApiService({required this.baseUrl});

  Future<String?> register({
    required String username,
    required String password,
    required String name,
    required String email,
    required String photo,
    required String birthday,
    required String studentId,
    required String gender,
    required String className,
    required String teacher,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'name': name,
        'email': email,
        'photo': photo,
        'birthday': birthday,
        'studentId': studentId,
        'gender': gender,
        'className': className,
        'teacher': teacher,
        'record': [],
        'spyRecord': [],
        'speakRecord': [],
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
  Future<List<Map<String, dynamic>>> fetchRecentRecords() async {
    final uid = await getUid();
    if (uid == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final recordList = data['record'];
      if (recordList is List) {
        return recordList.cast<Map<String, dynamic>>();
      }
    }

    return []; // 若失敗則回傳空陣列
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
  Future<List<Map<String, dynamic>>> fetchQuestions(String unitId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/mcq/questionSets/$unitId/questions'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final questions = data['questions'];
      if (questions is List) {
        return questions.cast<Map<String, dynamic>>();
      }
    }

    throw Exception('無法取得題目');
  }
  Future<Map<String, dynamic>?> fetchRecordForUnit(String unitId) async {
    final uid = await getUid();
    if (uid == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final records = data['record'];

      if (records is List) {
        // 找出對應單元的紀錄
        return records.cast<Map<String, dynamic>>().firstWhere(
              (r) => r['mode'] == unitId,
          orElse: () => {},
        );
      }
    }

    return null;
  }
  Future<String?> updateUserProfile(Map<String, dynamic> data) async {
    final uid = await getUid();
    if (uid == null) return '找不到使用者 ID';

    final response = await http.post(
      Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return null;
    } else {
      print("⚠️ updateUserProfile status: ${response.statusCode}");
      print("⚠️ updateUserProfile body: ${response.body}");
      return '更新失敗';
    }
  }

}

