import 'package:flutter/material.dart';
import 'login_page.dart';
import '../services/auth_api_service.dart';

class RegisterPage extends StatelessWidget {
  final AuthApiService authService;
  const RegisterPage({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("註冊")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "姓名"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "帳號"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "密碼"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final username = emailController.text.trim();
                final password = passwordController.text.trim();

                final error = await authService.register(username, password);

                if (error == null && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginPage(authService: authService),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? "註冊失敗")),
                  );
                }
              },
              child: const Text("註冊"),
            ),
          ],
        ),
      ),
    );
  }
}
