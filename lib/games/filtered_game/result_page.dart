import 'package:flutter/material.dart';
import '../../pages/home_page.dart';
import '../../services/auth_api_service.dart';

class ResultPage extends StatelessWidget {
  final AuthApiService authService; // <-- 新增
  final List<Map<String, dynamic>> questionResults;

  ResultPage({
    Key? key,
    required this.authService, // <-- 新增
    this.questionResults = const [ // 預設假資料，正式可用 required
      {
        "text": "你食飽未？",
        "romaji": "Lí tsia̍h-pá--buē?",
        "translation": "你吃飽了沒有？",
        "correct": true,
      },
      {
        "text": "我猶未食飯。",
        "romaji": "Guá iáu-buē tsia̍h-pn̄g",
        "translation": "我還沒吃飯。",
        "correct": true,
      },
      {
        "text": "恁欲去佗位？",
        "romaji": "Lín beh khì tó-uī?",
        "translation": "你們要去哪裡？",
        "correct": false,
      },
      {
        "text": "恁欲去佗位？",
        "romaji": "Lín beh khì tó-uī?",
        "translation": "你們要去哪裡？",
        "correct": false,
      },
    ],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int correctCount = questionResults.where((q) => q['correct'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Text('選擇題小遊戲', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 12),
          const Text('單元二', style: TextStyle(fontSize: 16)),
          const Text('今日主題：吃飯對話', style: TextStyle(fontSize: 15, color: Colors.black54)),
          const SizedBox(height: 12),
          const Text('單元二已完成', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const Text('「來回顧您的發音吧！」', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: questionResults.length,
              itemBuilder: (context, idx) {
                final q = questionResults[idx];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: q['correct'] ? Colors.green : Colors.red,
                        child: Icon(q['correct'] ? Icons.check : Icons.close, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("第${idx + 1}題", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(q['text'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            Text(q['romaji'], style: const TextStyle(fontSize: 16, color: Colors.blue)),
                            Text(q['translation'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.green,
                              minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.volume_up, size: 20),
                            label: const Text('正確發音', style: TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(height: 4),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black54, backgroundColor: Colors.grey,
                              minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.record_voice_over, size: 20),
                            label: const Text('您的發音', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black12),
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePage(
                        authService: authService, // 這裡用你傳進來的變數
                        initialIndex: 0,
                      ),
                    ),
                        (route) => false,
                  );
                },
                child: const Text('回到首頁', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
