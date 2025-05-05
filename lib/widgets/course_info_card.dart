import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseInfoCard extends StatelessWidget {
  const CourseInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('學習紀錄',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('您的學習狀況良好，繼續保持！'),
            SizedBox(height: 12),
            Text('選擇題遊戲',
                style: TextStyle(fontWeight: FontWeight.w500)),
            Text('平均答題正確率：80%'),
            SizedBox(height: 12),
            Text('濾鏡小遊戲',
                style: TextStyle(fontWeight: FontWeight.w500)),
            Text('總遊玩次數：20 次'),
            SizedBox(height: 16),
            LinearProgressIndicator(value: 0.5),
          ],
        ),
      ),
    );
  }
}
