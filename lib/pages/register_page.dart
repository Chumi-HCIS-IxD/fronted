import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';
import '../services/auth_api_service.dart';

class RegisterPage extends StatefulWidget {
  final AuthApiService authService;
  const RegisterPage({super.key, required this.authService});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final birthdayController = TextEditingController();
  final studentIdController = TextEditingController();
  final photoUrlController = TextEditingController();

  File? selectedImageFile;
  String selectedGender = '男';
  String selectedGrade = '一年級';
  String selectedClass = '一班';

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImageFile = File(picked.path);
        photoUrlController.text = 'https://example.com/default_profile.jpg'; // 暫時圖片網址
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("註冊")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: "帳號")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "密碼")),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "姓名")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: birthdayController, decoration: const InputDecoration(labelText: "生日 (YYYY-MM-DD)")),
            TextField(controller: studentIdController, decoration: const InputDecoration(labelText: "學號")),

            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: const InputDecoration(labelText: '性別'),
              items: ['男', '女'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => selectedGender = val!),
            ),

            DropdownButtonFormField<String>(
              value: selectedGrade,
              decoration: const InputDecoration(labelText: '年級'),
              items: ['一年級', '二年級', '三年級', '四年級', '五年級', '六年級']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) => setState(() => selectedGrade = val!),
            ),

            DropdownButtonFormField<String>(
              value: selectedClass,
              decoration: const InputDecoration(labelText: '班級'),
              items: ['一班', '二班', '三班', '四班', '五班', '六班', '七班', '八班', '九班', '十班']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => selectedClass = val!),
            ),

            const SizedBox(height: 12),
            ElevatedButton(onPressed: pickImage, child: const Text("選擇照片")),
            if (selectedImageFile != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Image.file(selectedImageFile!, width: 100, height: 100),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final error = await widget.authService.register(
                  username: usernameController.text.trim(),
                  password: passwordController.text.trim(),
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  photo: photoUrlController.text.trim(),
                  birthday: birthdayController.text.trim(),
                  studentId: studentIdController.text.trim(),
                  gender: selectedGender,
                  className: '$selectedGrade$selectedClass',
                  teacher: '', // 老師已移除
                );

                if (error == null && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage(authService: widget.authService)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? "註冊失敗")));
                }
              },
              child: const Text("註冊"),
            ),
          ],
        ),
      ),
    );
  }
}
