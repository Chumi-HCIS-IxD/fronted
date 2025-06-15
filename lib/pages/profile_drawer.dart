// lib/widgets/profile_drawer.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_api_service.dart';
import '../theme/colors.dart';
import '../pages/login_page.dart';

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
    if (isoString == null) return "未提供";
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return "格式錯誤";
    return DateFormat('yyyy/MM/dd  HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Drawer(
      backgroundColor: AppColors.primaryBG,
      child: SafeArea(
        child: profile == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            // ← 返回鈕
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
              ),
            ),

            // 頭像
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.grey300,
                backgroundImage: profile['photo'] != null
                    ? NetworkImage(profile['photo'])
                    : null,
                child: profile['photo'] == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // 姓名 + 身分
            Center(
              child: Column(
                children: [
                  Text(
                    profile['name'] ?? '使用者',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '使用者',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Divider(
              thickness: 1,
              indent: 24,
              endIndent: 24,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),

            // 基本資料
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "基本資料",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "生日：${profile['birthday'] ?? '未提供'}",
                    style: const TextStyle(color: AppColors.grey700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "學號：${profile['studentId'] ?? '未提供'}",
                    style: const TextStyle(color: AppColors.grey700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "信箱：${profile['email'] ?? '未提供'}",
                    style: const TextStyle(color: AppColors.grey700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Divider(
              thickness: 1,
              indent: 24,
              endIndent: 24,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 24),

            // 上次登入時間
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "上次登入時間",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20,
                        color: AppColors.grey700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatDateTime(_lastLogin),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 登出按鈕（改成綠底白字）
            Padding(
              padding: const EdgeInsets.all(70),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 5),
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
                  child: Column(
                    children: const [
                      Text("登出", style: TextStyle(fontSize: 16)),
                      SizedBox(height: 4),
                      Text(
                        "ting-tshut",
                        style: TextStyle(fontSize: 12, color: AppColors.grey100),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}