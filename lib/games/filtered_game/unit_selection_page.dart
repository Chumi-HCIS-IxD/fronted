import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';
import 'filter_game_page.dart';

class UnitSelectionPage extends StatelessWidget {
  final authService = AuthApiService(baseUrl: 'http://140.116.245.157:5019');
  UnitSelectionPage({super.key});

  // 單元清單：主題/拼音/emoji/icon
  final List<Map<String, String>> units = const [
    {
      'id': 'Unit_1',
      'title': '臺．台灣水果',
      'subtitle': 'Tâi-uân-tsuí-kó',
      'icon': '🍇',
    },
    {
      'id': 'Unit_2',
      'title': '弍．吃飯對話',
      'subtitle': 'tsia̍h-pn̄g-tùi-uē',
      'icon': '🍳',
    },
    {
      'id': 'Unit_3',
      'title': '参．台灣昆蟲',
      'subtitle': 'Tâi-uân-khun-thiông',
      'icon': '🦋',
    },
    {
      'id': 'Unit_4',
      'title': '肆．海底生物',
      'subtitle': 'hái-té-sing-būt',
      'icon': '🦀',
    },
    {
      'id': 'Unit_5',
      'title': '伍．兒時童玩',
      'subtitle': 'gín-á-ê-guân-khù',
      'icon': '🏀',
    },
    {
      'id': 'Unit_6',
      'title': '陆．日常服飾',
      'subtitle': 'jīt-siōng-hok-sik',
      'icon': '🧢',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF82C8D9), // 粉藍底色
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '練說話',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Lian kóng-uē',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 8),
          // 吉祥物圖案（可換成Image.asset或用emoji暫代）
          Container(
            height: 140,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 替代吉祥物的 emoji 或圖片
                const Text('🌟', style: TextStyle(fontSize: 100)),
                Positioned(
                  right: 50, top: 24,
                  child: Icon(Icons.music_note, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE5F3EE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                itemCount: units.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FilterGamePage(
                            unitId: unit['id']!,
                            authService: authService,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(unit['icon']!, style: const TextStyle(fontSize: 38)),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(unit['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text(unit['subtitle']!, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black26),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
