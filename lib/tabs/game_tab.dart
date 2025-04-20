import 'package:flutter/material.dart';
import '../games/multiple_choice/quiz_game_page.dart';

class GameTab extends StatefulWidget {
  @override
  _GameTabState createState() => _GameTabState();
}

class _GameTabState extends State<GameTab> {
  final List<Map<String, String>> games = [
    {"title": "選擇題小遊戲"},
    {"title": "遮鏡小遊戲"},
    {"title": "誰是臥底"},
  ];

  final Map<String, Widget Function()> gameRoutes = {
    "選擇題小遊戲": () => const QuizGamePage(),
    // "遮鏡小遊戲": () => const MirrorGamePage(),
    // "誰是臥底": () => const UndercoverGamePage(),
  };

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredGames =
        games.where((game) => game["title"]!.contains(searchQuery)).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Center(
                child: Text(
                  "Taiwanese\nLittle Games",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "搜尋遊戲",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredGames.length,
                  itemBuilder: (context, index) {
                    final title = filteredGames[index]["title"]!;
                    return GestureDetector(
                      onTap: () {
                        if (gameRoutes.containsKey(title)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => gameRoutes[title]!(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$title 尚未開放')),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color:
                              index == 1 ? Colors.grey[300] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image, size: 50),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(Icons.lock),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
