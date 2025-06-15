// lib/pages/settings_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext ctx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    Navigator.pushNamedAndRemoveUntil(ctx, '/login', (_) => false);
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