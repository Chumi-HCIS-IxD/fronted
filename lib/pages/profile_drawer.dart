import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import 'login_page.dart';

class ProfileDrawer extends StatefulWidget {
  final AuthApiService authService;

  const ProfileDrawer({super.key, required this.authService});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.authService.fetchUserProfile();
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey.shade100,
      child: SafeArea(
        child: Column(
          children: [
            // 返回鍵
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).pop(); // 關閉 Drawer
                    },
                  ),
                  const Spacer(),
                  const Icon(Icons.account_circle_outlined, size: 28),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 頭像
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // 使用者名稱
            Text(
              _profile?['username'] ?? '使用者',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32, thickness: 1, indent: 32, endIndent: 32),

            // 資訊
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _profile == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text("UID：${_profile!['uid'] ?? ''}"),
                        const SizedBox(height: 8),
                        Text(
                            "戰績數量：${(_profile!['record'] as List?)?.length ?? 0} 筆"),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade100,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await widget.authService.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LoginPage(authService: widget.authService),
                        ),
                        (_) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("登出", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
