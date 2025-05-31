import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';


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

  Future<List<Map<String, dynamic>>> fetchFilterQuestions(String unitId) async {
    final url = '$baseUrl/api/speak/speakQuestionSets/$unitId/questions';
    print('[fetchFilterQuestions] GET: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    print('[fetchFilterQuestions] status: ${response.statusCode}');
    print('[fetchFilterQuestions] body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 有時候回傳是一個 list，有時候是 map，這裡都能處理
      if (data is List) {
        // 直接回傳 list
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map<String, dynamic>) {
        // 回傳格式有 "questions" key
        if (data['questions'] is List) {
          return List<Map<String, dynamic>>.from(data['questions']);
        } else {
          // 假如直接就是題目陣列
          return [];
        }
      } else {
        throw Exception('API 回傳非預期格式');
      }
    }

    throw Exception('無法取得題目：status=${response.statusCode}');
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

  Future<List<Map<String, dynamic>>> fetchAllRecords() async {
    final uid = await getUid();
    if (uid == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final records = data['record'];
      if (records is List) {
        return records.cast<Map<String, dynamic>>();
      }
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> fetchAllFilterRecords() async {
    final uid = await getUid();
    if (uid == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile?uid=$uid'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final records = data['speakRecord'];
      if (records is List) {
        return records.cast<Map<String, dynamic>>();
      }
    }

    return [];
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
  /// 語音辨識 (ASR)
  /// [filePath]：本地 wav 檔案路徑
  /// 回傳辨識後的句子，失敗則拋出 Exception
  Future<String> recognizeAudio(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('音檔不存在：$filePath');
    }

    // 讀取檔案並做 Base64 編碼
    final rawBytes = await file.readAsBytes();
    final audioBase64 = base64Encode(rawBytes);

    // 組 JSON body
    final body = jsonEncode({
      'lang': 'TA and ZH Medical V1',
      'token': '2025@test@asr',
      'audio': audioBase64,
    });

    // 呼叫後端 proxy endpoint
    final uri = Uri.parse('$baseUrl/proxy');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['sentence'] != null) {
        return data['sentence'] as String;
      } else {
        throw Exception('回傳格式錯誤，找不到 sentence');
      }
    } else {
      // 嘗試解析錯誤訊息
      String errMsg = '識別失敗（status=${response.statusCode}）';
      try {
        final err = jsonDecode(response.body);
        if (err['error'] != null) errMsg = err['error'];
      } catch (_) {}
      throw Exception(errMsg);
    }
  }
  Future<bool> submitSpeakResults(String unitId, List<Map<String, dynamic>> results) async {
    // 先取出目前的使用者 uid
    final uid = await getUid();
    if (uid == null) {
      print('Error: no uid stored');
      return false;
    }

    final uri = Uri.parse('$baseUrl/api/speak/speakQuestionSets/$unitId/submit');
    final payload = {
      'user': uid,
      'results': results,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('❌ submitSpeakResults failed: '
          'status=${response.statusCode}, body=${response.body}');
      return false;
    }
  }
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('GET 請求失敗: ${response.statusCode}');
    }
  }
}