// lib/pages/scoreboard_tab.dart
import 'package:flutter/material.dart';

class ScoreboardTab extends StatelessWidget {
  const ScoreboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: 從後端載入真正的積分排行
    final ranking = [
      {'name': '王順仁', 'score': 95},
      {'name': '學生A',   'score': 82},
      {'name': '學生B',   'score': 74},
    ];
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ranking.length,
        itemBuilder: (ctx, idx) {
          final entry = ranking[idx];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(child: Text('${idx+1}')),
              title: Text(entry['name'] as String),
              trailing: Text('${entry['score']} 分'),
            ),
          );
        },
      ),
    );
  }
}