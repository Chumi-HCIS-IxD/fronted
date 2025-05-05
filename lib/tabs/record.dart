import 'package:flutter/material.dart';
import '../record/unit_selection_page.dart';
import '../../services/auth_api_service.dart';

class RecordTab extends StatelessWidget {
  final AuthApiService authService;

  RecordTab({super.key, required this.authService}) {
    _gameRoutes = {
      "選擇題小遊戲": () => UnitSelectionPage(authService: authService),
    };
  }

  final List<Map<String, String>> _games = const [
    {"title": "選擇題小遊戲"},
    {"title": "濾鏡小遊戲"},
    {"title": "誰是臥底"},
    {"title": "小遊戲"},
  ];

  late final Map<String, Widget Function()> _gameRoutes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.image_outlined, size: 50, color: Colors.grey),
                    SizedBox(width: 24),
                    Text(
                      "複習自己的學習內容！",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      final title = game["title"] ?? '';
                      return _buildGameItem(context, title);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameItem(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        if (_gameRoutes.containsKey(title)) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _gameRoutes[title]!()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title 尚未開放')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEAEAEA),
              child: Icon(Icons.image_outlined, color: Colors.black54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
