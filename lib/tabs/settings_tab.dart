import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/edit_profile_page.dart';
import '../services/auth_api_service.dart';
import '../pages/login_page.dart';

class SettingsTab extends StatelessWidget {
  final AuthApiService authService;
  const SettingsTab({super.key, required this.authService});

  Future<void> _logout(BuildContext context) async {
    await authService.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(authService: authService),
        ),
            (_) => false,
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '個人資料',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('姓名'),
            subtitle: const Text('尚未設定'),
            trailing: const Icon(Icons.edit),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfilePage(authService: authService))
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 20),
          const Text(
            '系統設定',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('語言'),
            subtitle: const Text('繁體中文'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('語言切換尚未實作')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('登出'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
