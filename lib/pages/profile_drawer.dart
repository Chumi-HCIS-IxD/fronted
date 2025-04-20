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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _profile?['username'] ?? '使用者',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _profile == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("UID：${_profile!['uid'] ?? ''}"),
                  const SizedBox(height: 10),
                  Text("戰績：${(_profile!['record'] as List?)?.length ?? 0} 筆"),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
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
                label: const Text("登出"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
