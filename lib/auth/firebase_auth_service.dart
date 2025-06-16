import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 註冊
  Future<String?> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final token = await userCredential.user?.getIdToken();
      await _saveToken(token);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 登入
  Future<String?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final token = await userCredential.user?.getIdToken();
      await _saveToken(token);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 登出
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userToken');
  }

  // 儲存 token
  Future<void> _saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('userToken', token);
    }
  }

  // 取得目前 token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userToken');
  }
}
