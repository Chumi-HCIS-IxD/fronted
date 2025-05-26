// lib/pages/settings_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import '../services/auth_api_service.dart';

class SettingsTab extends StatelessWidget {
  final AuthApiService authService; // ✅ 加這行

  const SettingsTab({Key? key, required this.authService}) : super(key: key); // ✅ 傳進來


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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('登出'),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}