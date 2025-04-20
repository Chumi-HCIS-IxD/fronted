import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseInfoCard extends StatelessWidget {
  const CourseInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 課程說明區塊
            ListTile(
              title: Text(
                "課程說明",
                style: GoogleFonts.notoSansTc(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                "一些說明...",
                style: GoogleFonts.notoSansTc(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
              onTap: () {
                // 點擊導向細節頁
              },
            ),

            // 單元一區塊
            ListTile(
              title: Text(
                "單元一",
                style: GoogleFonts.notoSansTc(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                "一些說明...",
                style: GoogleFonts.notoSansTc(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 教學進度 + 進度條
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "教學進度",
                style: GoogleFonts.notoSansTc(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.6,
                color: Colors.deepPurple,
                backgroundColor: Color(0xFFE0DCEB),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
