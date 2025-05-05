import 'package:flutter/material.dart';
import '../games/MCQ_Game/room_selection_page.dart';

class GameTab extends StatefulWidget {
  const GameTab({super.key});

  @override
  State<GameTab> createState() => _GameTabState();
}

class _GameTabState extends State<GameTab> {
  final List<Map<String, String>> _games = [
    {"title": "選擇題小遊戲"},
    {"title": "濾鏡小遊戲"},
    {"title": "誰是臥底"},
    {"title": "小遊戲"},
  ];
  final Map<String, Widget Function()> _gameRoutes = {
    "選擇題小遊戲": () => const RoomSelectionPage(isTeacher: false),
    // "濾鏡小遊戲": () => const MirrorGamePage(),  // 可以之後再補
    // "誰是臥底": () => const UndercoverGamePage(), // 可以之後再補
  };

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredGames = _games
        .where((game) => game["title"]!.contains(_searchQuery))
        .toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 搜尋欄
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '搜尋遊戲',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // 遊戲列表
            Expanded(
              child: ListView.builder(
                itemCount: filteredGames.length,
                itemBuilder: (context, index) {
                  final game = filteredGames[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: index == 1 ? Colors.grey.shade300 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFEAEAEA),
                        child: Icon(Icons.image_outlined, color: Colors.black54),
                      ),
                      title: Text(
                        game["title"]!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(Icons.lock, color: Colors.black54),
                      onTap: () {
                        final gameTitle = game["title"]!;
                        if (_gameRoutes.containsKey(gameTitle)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => _gameRoutes[gameTitle]!()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$gameTitle 尚未開放')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

    );
  }
}
