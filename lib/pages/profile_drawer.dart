import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _lastLogin;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.authService.fetchUserProfile();
    final prefs = await SharedPreferences.getInstance();
    final storedLoginTime = prefs.getString('lastLogin');

    setState(() {
      _profile = profile;
      _lastLogin = storedLoginTime;
    });
  }

  String formatDateTime(String? isoString) {
    if (isoString == null) return "不詳";
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return "格式錯誤";
    return DateFormat('yyyy/MM/dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Drawer(
      backgroundColor: const Color(0xFFEFF4E9),
      child: SafeArea(
        child: profile == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: profile['photo'] != null
                    ? NetworkImage(profile['photo'])
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: profile['photo'] == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                profile['name'] ?? '使用者',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            // const Center(
            //   child: Text(
            //     "老師",
            //     style: TextStyle(fontSize: 16, color: Colors.black54),
            //   ),
            // ),

            const SizedBox(height: 24),
            const Divider(thickness: 1, indent: 24, endIndent: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("基本資料", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("生日：${profile['birthday'] ?? '未提供'}"),
                  const SizedBox(height: 8),
                  Text("學號：${profile['studentId'] ?? ''}"),
                  const SizedBox(height: 8),
                  Text("信箱：${profile['email'] ?? ''}"),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("上次登入時間", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(formatDateTime(_lastLogin)),
                ],
              ),
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade100,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await widget.authService.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginPage(authService: widget.authService),
                        ),
                            (_) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("登出", style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
