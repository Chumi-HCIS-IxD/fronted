import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart';
import '../services/auth_api_service.dart';

class LoginPage extends StatefulWidget {
  final AuthApiService authService;
  const LoginPage({super.key, required this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('登入', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: '帳號')),
            const SizedBox(height: 12),
            TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '密碼')),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: () async {
                final error = await widget.authService
                    .login(emailController.text, passwordController.text);
                if (error == null && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            HomePage(authService: widget.authService)),
                  );
                } else {
                  setState(() => _error = error);
                }
              },
              child: const Text('登入'),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegisterPage(authService: widget.authService),
                  ),
                );
              },
              child: const Text(
                "還沒有帳號？前往註冊",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
