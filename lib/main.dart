// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/auth_api_service.dart';
import 'package:google_fonts/google_fonts.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString('uid');
  runApp(MyApp(isLoggedIn: uid != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final authService = AuthApiService(baseUrl: 'http://140.116.245.157:5019');

  MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '教學平台',
      debugShowCheckedModeBanner: false,
      // theme: ThemeData(primarySwatch: Colors.blue),
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansTcTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.black,    // 全部文字顏色變黑
          displayColor: Colors.black, // AppBar / Title 顏色也變黑
        ).copyWith(
          bodyMedium: GoogleFonts.notoSansTc(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      home: isLoggedIn
          ? HomePage(authService: authService)
          : LoginPage(authService: authService),
    );
  }
}
