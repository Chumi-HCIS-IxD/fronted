import 'package:flutter/material.dart';
import 'login_page.dart';
import '../auth/firebase_auth_service.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 10),
            const Text("Name",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("班級：三年六班"),
                  Text("教師：王曉仁"),
                  SizedBox(height: 10),
                  Text("基本資料", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("性別：女"),
                  Text("生日：99/10/22"),
                  Text("學號：P36134084"),
                  Text("信箱：P36134084@gmail.com"),
                  SizedBox(height: 10),
                  Text("上次登入時間："),
                  Text("2025/04/06 15:06"),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuthService()
                      .logout(); // 👈 清除 Firebase 與 token
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text("登出"),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
