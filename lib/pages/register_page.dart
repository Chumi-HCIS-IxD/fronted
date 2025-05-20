// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'login_page.dart';
// import '../services/auth_api_service.dart';
//
// class RegisterPage extends StatefulWidget {
//   final AuthApiService authService;
//   const RegisterPage({super.key, required this.authService});
//
//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }
//
// class _RegisterPageState extends State<RegisterPage> {
//   final usernameController = TextEditingController();
//   final passwordController = TextEditingController();
//   final nameController = TextEditingController();
//   final emailController = TextEditingController();
//   final birthdayController = TextEditingController();
//   final studentIdController = TextEditingController();
//   final photoUrlController = TextEditingController();
//
//   File? selectedImageFile;
//   String selectedGender = '男';
//   String selectedGrade = '一年級';
//   String selectedClass = '一班';
//
//   Future<void> pickImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         selectedImageFile = File(picked.path);
//         photoUrlController.text = 'https://example.com/default_profile.jpg'; // 暫時圖片網址
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("註冊")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             TextField(controller: usernameController, decoration: const InputDecoration(labelText: "帳號")),
//             TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "密碼")),
//             TextField(controller: nameController, decoration: const InputDecoration(labelText: "姓名")),
//             TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
//             TextField(controller: birthdayController, decoration: const InputDecoration(labelText: "生日 (YYYY-MM-DD)")),
//             TextField(controller: studentIdController, decoration: const InputDecoration(labelText: "學號")),
//
//             DropdownButtonFormField<String>(
//               value: selectedGender,
//               decoration: const InputDecoration(labelText: '性別'),
//               items: ['男', '女'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
//               onChanged: (val) => setState(() => selectedGender = val!),
//             ),
//
//             DropdownButtonFormField<String>(
//               value: selectedGrade,
//               decoration: const InputDecoration(labelText: '年級'),
//               items: ['一年級', '二年級', '三年級', '四年級', '五年級', '六年級']
//                   .map((g) => DropdownMenuItem(value: g, child: Text(g)))
//                   .toList(),
//               onChanged: (val) => setState(() => selectedGrade = val!),
//             ),
//
//             DropdownButtonFormField<String>(
//               value: selectedClass,
//               decoration: const InputDecoration(labelText: '班級'),
//               items: ['一班', '二班', '三班', '四班', '五班', '六班', '七班', '八班', '九班', '十班']
//                   .map((c) => DropdownMenuItem(value: c, child: Text(c)))
//                   .toList(),
//               onChanged: (val) => setState(() => selectedClass = val!),
//             ),
//
//             const SizedBox(height: 12),
//             ElevatedButton(onPressed: pickImage, child: const Text("選擇照片")),
//             if (selectedImageFile != null)
//               Padding(
//                 padding: const EdgeInsets.all(8),
//                 child: Image.file(selectedImageFile!, width: 100, height: 100),
//               ),
//
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 final error = await widget.authService.register(
//                   username: usernameController.text.trim(),
//                   password: passwordController.text.trim(),
//                   name: nameController.text.trim(),
//                   email: emailController.text.trim(),
//                   photo: photoUrlController.text.trim(),
//                   birthday: birthdayController.text.trim(),
//                   studentId: studentIdController.text.trim(),
//                   gender: selectedGender,
//                   className: '$selectedGrade$selectedClass',
//                   teacher: '', // 老師已移除
//                 );
//
//                 if (error == null && context.mounted) {
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(builder: (_) => LoginPage(authService: widget.authService)),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? "註冊失敗")));
//                 }
//               },
//               child: const Text("註冊"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// lib/pages/register_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_api_service.dart';
import '../theme/colors.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final AuthApiService authService;
  const RegisterPage({Key? key, required this.authService}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final birthdayCtrl = TextEditingController();
  final studentIdCtrl = TextEditingController();

  File? _imageFile;
  String _photoUrl = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _photoUrl = 'https://example.com/default_profile.jpg';
      });
    }
  }

  Future<void> _onRegister() async {
    if (passCtrl.text.trim() != confirmCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密碼與確認密碼不一致')),
      );
      return;
    }

    final error = await widget.authService.register(
      username: emailCtrl.text.trim(),
      password: passCtrl.text.trim(),
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      photo: _photoUrl,
      birthday: birthdayCtrl.text.trim(),
      studentId: studentIdCtrl.text.trim(),
      gender: '',
      className: '',
      teacher: '',
    );

    if (error == null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(authService: widget.authService),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? '註冊失敗')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final btnWidth = screenW * 0.25;

    return Scaffold(
      backgroundColor: AppColors.primaryBG,
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.none, // 讓 Positioned 的負值也能顯示
          children: [
            // 1. 最底層：插畫背景
            Positioned(
              top: -130, // 整個畫面往下移 20px，你可以微調這個數值
              left: 0,
              right: 0,
              height: screenH * 0.30,
              child: Image.asset(
                'assets/images/login.png',
                fit: BoxFit.cover,
              ),
            ),

            // 2. 白色表單卡片
            Positioned(
              top: screenH * 0.30 - 150, // 30% 高度再往上蓋 40px，再加上剛才的 20 下移
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryBG,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField('信箱', emailCtrl),
                      _spacer(10),
                      _buildField('密碼', passCtrl, obscure: true),
                      _spacer(10),
                      _buildField('確認密碼', confirmCtrl, obscure: true),
                      _spacer(10),
                      _buildField('姓名', nameCtrl),
                      _spacer(10),
                      _buildField('生日', birthdayCtrl),
                      _spacer(10),
                      _buildField('學號/教職員碼', studentIdCtrl),
                      _spacer(20),
                      Center(
                        child: SizedBox(
                          width: btnWidth,
                          height: 50,  // 兩行文字＋上下 padding
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            onPressed: _onRegister,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('註冊', style: TextStyle(fontSize: 14, color: Colors.white)),
                                SizedBox(height: 2),
                                Text('tsù-tsheh',
                                    style: TextStyle(fontSize: 10, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. 頭像 (要蓋在卡片上面)
            Positioned(
              top: screenH * 0.30 - 250, // 蓋在卡片頂端上方
              left: (screenW - 120) / 2,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.grey300.withOpacity(0.9),
                // backgroundColor: AppColors.grey300,
                backgroundImage:
                _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null
                    ? const Icon(Icons.image, size: 32, color: Colors.white)
                    : null,
              ),
            ),

            // 4. 上傳頭像按鈕 (也蓋在卡片上)
            Positioned(
              top: screenH * 0.30 - 120, // 頭像底部再往下 10px
              left: (screenW - 70) / 2,
              child: SizedBox(
                width: 70,
                height: 30,
                child: TextButton(
                  onPressed: _pickImage,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    '上傳頭像',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),

            // 5. 返回按鈕
            Positioned(
              top: MediaQuery.of(context).padding.top - 30,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.grey900),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

// 修改後也要更新 _buildField，確保文字大小
  Widget _buildField(String label, TextEditingController ctrl,
      {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey700,
            fontSize: 14,           // ← 這裡改「12」或你想要的數字
            height: 1.5,
          ),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14, height: 1.2),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _spacer(double h) => SizedBox(height: h);
}