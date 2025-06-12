// // lib/pages/login_page.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/auth_api_service.dart';
// import '../theme/colors.dart';
// import 'home_page.dart';
// import 'register_page.dart';
//
// class LoginPage extends StatefulWidget {
//   final AuthApiService authService;
//   const LoginPage({super.key, required this.authService});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final emailCtrl = TextEditingController();
//   final passCtrl = TextEditingController();
//   bool rememberMe = false;
//   String? errorMsg;
//
//   @override
//   Widget build(BuildContext context) {
//     final screenH = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       backgroundColor: AppColors.primary,
//       body: Column(
//         children: [
//           SizedBox(height: 45),
//           // 1. 插畫：使用螢幕高度的 35%
//           SizedBox(
//             height: screenH * 0.35,
//             width: double.infinity,
//             child: Image.asset(
//               'assets/images/login.png',
//               fit: BoxFit.cover,
//             ),
//           ),
//
//           // 2. 白底圓角卡片：自動填滿剩餘空間
//           Expanded(
//             child: Container(
//               decoration: const BoxDecoration(
//                 color: AppColors.grey100,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(24),
//                   topRight: Radius.circular(24),
//                 ),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//               child: SingleChildScrollView(
//                 child: _buildForm(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildForm() {
//     final screenW = MediaQuery.of(context).size.width;
//     final btnWidth = screenW * 0.35;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // 標題
//         Center(
//           child: Column(
//             children: const [
//               Text(
//                 '登登登登！',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.grey900,
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         const SizedBox(height: 32),
//
//         // 信箱
//         const Text('信箱', style: TextStyle(color: AppColors.grey700)),
//         const SizedBox(height: 6),
//         TextField(
//           controller: emailCtrl,
//           decoration: _inputDecoration(),
//         ),
//
//         const SizedBox(height: 3),
//
//         // 密碼
//         const Text('密碼', style: TextStyle(color: AppColors.grey700)),
//         const SizedBox(height: 3),
//         TextField(
//           controller: passCtrl,
//           obscureText: true,
//           decoration: _inputDecoration(),
//         ),
//
//         const SizedBox(height: 4),
//
//         // 記住我 & 忘記密碼
//         Row(
//           children: [
//             Checkbox(
//               value: rememberMe,
//               activeColor: AppColors.primary,
//               onChanged: (v) => setState(() => rememberMe = v ?? false),
//             ),
//             const Text('記住我',
//                 style: TextStyle(color: AppColors.grey700)),
//             const Spacer(),
//             GestureDetector(
//               onTap: () {
//                 // TODO: 忘記密碼
//               },
//
//               child: const Text(
//                 '忘記密碼',
//                 style: TextStyle(color: AppColors.grey700),
//               ),
//             ),
//           ],
//         ),
//
//         if (errorMsg != null) ...[
//           const SizedBox(height: 4),
//           Text(errorMsg!, style: const TextStyle(color: Colors.red)),
//         ],
//
//         const SizedBox(height: 16),
//
//         // 註冊按鈕
//         Align(
//           alignment: Alignment.center, // 置中
//           child: SizedBox(
//             width: btnWidth,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 6),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(24), // 圓角
//                 ),
//               ),
//               onPressed: _onLogin,
//               child: Column(
//                 children: const [
//                   Text('登入', style: TextStyle(fontSize: 16)),
//                   SizedBox(height: 0.1),
//                   Text('ting-jip',
//                       style: TextStyle(fontSize: 12, color: AppColors.grey100)),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//         const SizedBox(height: 12),
//
//         // ★ 同理，把註冊按鈕也換成窄版 ★
//         Align(
//           alignment: Alignment.center,
//           child: SizedBox(
//             width: btnWidth * 0.7,
//             child: OutlinedButton(
//               style: OutlinedButton.styleFrom(
//                 backgroundColor: AppColors.primaryTint,
//                 foregroundColor: AppColors.grey900,
//                 padding: const EdgeInsets.symmetric(vertical: 6),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 side: const BorderSide(color: AppColors.accentGreen),
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) =>
//                         RegisterPage(authService: widget.authService),
//                   ),
//                 );
//               },
//               child: Column(
//                 children: const [
//                   Text('註冊', style: TextStyle(fontSize: 16, color: Colors.white)),
//                   SizedBox(height: 0.1),
//                   Text('tsù-tsheh',
//                       style: TextStyle(fontSize: 12, color: Colors.white)),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//         const SizedBox(height: 16),
//       ],
//     );
//   }
//
//   InputDecoration _inputDecoration() {
//     return InputDecoration(
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding:
//       const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: AppColors.grey300),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: AppColors.grey300),
//       ),
//     );
//   }
//
//   Future<void> _onLogin() async {
//     final err = await widget.authService
//         .login(emailCtrl.text, passCtrl.text);
//     if (err == null) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(
//           'lastLogin', DateTime.now().toIso8601String());
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => HomePage(authService: widget.authService),
//         ),
//       );
//     } else {
//       setState(() => errorMsg = err);
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_api_service.dart';
import '../theme/colors.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final AuthApiService authService;
  const LoginPage({super.key, required this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool rememberMe = false;
  String? errorMsg;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          SizedBox(height: 45),
          SizedBox(
            height: screenH * 0.35,
            width: double.infinity,
            child: Image.asset(
              'assets/images/login.png',
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: SingleChildScrollView(
                child: _buildForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final screenW = MediaQuery
        .of(context)
        .size
        .width;
    final btnWidth = screenW * 0.35;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: const [
              Text(
                '登登登登！',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('信箱', style: TextStyle(color: AppColors.grey700)),
        const SizedBox(height: 6),
        TextField(
          controller: emailCtrl,
          decoration: _inputDecoration(),
        ),
        const SizedBox(height: 12),
        const Text('密碼', style: TextStyle(color: AppColors.grey700)),
        const SizedBox(height: 6),
        TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: _inputDecoration(),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => rememberMe = v ?? false),
            ),
            const Text('記住我', style: TextStyle(color: AppColors.grey700)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // TODO: 忘記密碼
              },
              child: const Text(
                '忘記密碼',
                style: TextStyle(color: AppColors.grey700),
              ),
            ),
          ],
        ),
        if (errorMsg != null) ...[
          const SizedBox(height: 4),
          Text(errorMsg!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: btnWidth,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _onLogin,
              child: Column(
                children: const [
                  Text('登入', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 2),
                  Text('ting-jip',
                      style: TextStyle(fontSize: 12, color: AppColors.grey100)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: btnWidth * 0.7,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.primaryTint,
                foregroundColor: AppColors.grey900,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: const BorderSide(color: AppColors.accentGreen),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegisterPage(authService: widget.authService),
                  ),
                );
              },
              child: Column(
                children: const [
                  Text('註冊',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('tsù-tsheh',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
    );
  }

  Future<void> _onLogin() async {
    final err = await widget.authService.login(
      emailCtrl.text,
      passCtrl.text,
    );
    if (err == null) {
      // 登入成功，AuthApiService 內已存 userToken 和 uid
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(authService: widget.authService),
        ),
      );
    } else {
      setState(() => errorMsg = err);
    }
  }
}