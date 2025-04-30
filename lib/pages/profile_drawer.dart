// lib/pages/profile_drawer.dart
import 'package:flutter/material.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
// TODO: replace with real user data
    const userName = 'Name';
    const className = '三年六班';
    const teacherName = '王順仁';
    const description = '一些說明...';
    const gender = '女';
    const birthday = '99/10/22';
    const studentId = 'P36134084';
    const email = 'P36134084@gmail.com';
    const lastLogin = '2025/04/06 15:06';
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with avatar and name
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.image, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              userName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Basic profile info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      '班級：', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(className),
                  const SizedBox(height: 8),
                  const Text(
                      '教師：', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(teacherName),
                  const SizedBox(height: 16),
                  const Text('課程說明',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(description),
                  const Divider(height: 32),

                  const Text('基本資料',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [const Text('性別：'), Text(gender)]),
                  const SizedBox(height: 4),
                  Row(children: [const Text('生日：'), Text(birthday)]),
                  const SizedBox(height: 4),
                  Row(children: [const Text('學號：'), Text(studentId)]),
                  const SizedBox(height: 4),
                  Row(children: [const Text('信箱：'), Text(email)]),
                  const Divider(height: 32),

                  const Text('上次登入時間',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(lastLogin),
                ],
              ),
            ),
            const Spacer(),

            // Logout button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  },
                  child: const Text('登出'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }}