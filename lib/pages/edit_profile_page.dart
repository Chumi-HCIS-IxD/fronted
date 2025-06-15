import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';

class EditProfilePage extends StatefulWidget {
  final AuthApiService authService;

  const EditProfilePage({super.key, required this.authService});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _birthdayController = TextEditingController();

  String _gender = 'male';
  int _grade = 1;
  int _classNum = 1;

  late final List<String> _grades = List.generate(6, (i) => '${i + 1}');
  late final List<String> _classes = List.generate(10, (i) => '${i + 1}');

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.authService.fetchUserProfile();
    if (profile != null) {
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _studentIdController.text = profile['studentId'] ?? '';
        _birthdayController.text = profile['birthday'] ?? '';
        _gender = profile['gender'] ?? 'male';

        final className = profile['className'] ?? '1年1班';
        final match = RegExp(r'(\d)年(\d+)班').firstMatch(className);
        if (match != null) {
          _grade = int.tryParse(match.group(1)!) ?? 1;
          _classNum = int.tryParse(match.group(2)!) ?? 1;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    final updated = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'studentId': _studentIdController.text.trim(),
      'birthday': _birthdayController.text.trim(),
      'gender': _gender,
      'className': '${_grade}年${_classNum}班',
    };

    final result = await widget.authService.updateUserProfile(updated);
    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更新成功')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失敗：$result')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6ED),
      appBar: AppBar(title: const Text('編輯個人資料')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '姓名')),
            const SizedBox(height: 12),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _studentIdController, decoration: const InputDecoration(labelText: '學號')),
            const SizedBox(height: 12),
            TextField(controller: _birthdayController, decoration: const InputDecoration(labelText: '生日 YYYY-MM-DD')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('男')),
                DropdownMenuItem(value: 'female', child: Text('女')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'male'),
              decoration: const InputDecoration(labelText: '性別'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _grade,
                    items: _grades.map((g) => DropdownMenuItem(
                      value: int.parse(g),
                      child: Text('$g 年級'),
                    )).toList(),
                    onChanged: (v) => setState(() => _grade = v ?? 1),
                    decoration: const InputDecoration(labelText: '年級'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _classNum,
                    items: _classes.map((c) => DropdownMenuItem(
                      value: int.parse(c),
                      child: Text('$c 班'),
                    )).toList(),
                    onChanged: (v) => setState(() => _classNum = v ?? 1),
                    decoration: const InputDecoration(labelText: '班級'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4AB38C),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('儲存', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}