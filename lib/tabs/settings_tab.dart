import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

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
              // TODO: 點擊可以跳到編輯畫面
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
              // TODO: 切換語言
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('登出'),
            onTap: () {
              // TODO: 實作登出
            },
          ),
        ],
      ),
    );
  }
}
