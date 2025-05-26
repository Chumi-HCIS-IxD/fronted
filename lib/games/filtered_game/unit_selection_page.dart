import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';
import 'filter_game_page.dart';

class SpeakUnit {
  final String unitId;
  final String unitTitle;

  SpeakUnit({required this.unitId, required this.unitTitle});

  factory SpeakUnit.fromJson(Map<String, dynamic> json) {
    return SpeakUnit(
      unitId: json['unitId'],
      unitTitle: json['unitTitle'],
    );
  }
}

class UnitSelectionPage extends StatefulWidget {
  const UnitSelectionPage({super.key});

  @override
  State<UnitSelectionPage> createState() => _UnitSelectionPageState();
}

class _UnitSelectionPageState extends State<UnitSelectionPage> {
  final authService = AuthApiService(baseUrl: 'http://140.116.245.157:5019');
  List<SpeakUnit> units = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUnits();
  }

  void fetchUnits() async {
    try {
      final response = await authService.get('/api/speak/speakQuestionSets');
      final data = response['speakSets'] as List<dynamic>;
      final loadedUnits = data.map((json) => SpeakUnit.fromJson(json)).toList();
      setState(() {
        units = loadedUnits;
        isLoading = false;
      });
    } catch (e) {
      print('❌ 取得單元失敗: $e');
      setState(() => isLoading = false);
    }
  }

  String getEmojiForUnit(String unitId) {
    switch (unitId) {
      case 'Unit_1': return '🍇';
      case 'Unit_2': return '🍳';
      case 'Unit_3': return '🦋';
      case 'Unit_4': return '🦀';
      case 'Unit_5': return '🏀';
      case 'Unit_6': return '🧢';
      default: return '📘';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF82C8D9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('練說話', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 8),
          const Text('Lian kóng-uē', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            height: 140,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text('🌟', style: TextStyle(fontSize: 100)),
                const Positioned(right: 50, top: 24, child: Icon(Icons.music_note, color: Colors.white, size: 36)),
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
                  final emoji = getEmojiForUnit(unit.unitId);
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FilterGamePage(
                            unitId: unit.unitId,
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
                          Text(emoji, style: const TextStyle(fontSize: 38)),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(unit.unitTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

