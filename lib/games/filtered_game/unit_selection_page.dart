import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import 'filter_game_page.dart';



class SpeakUnit {
  final String unitId;
  final String title;
  final String subtitle;
  final String icon;

  SpeakUnit({
    required this.unitId,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  factory SpeakUnit.fromJson(Map<String, dynamic> json) {
    final unitId = json['unitId'] ?? '';

    // API 的 key 是 unitTitle 和 description
    final title = json['unitTitle'] ?? '';
    final subtitle = json['description'] ?? '';

    final iconPath = {
      'Unit_1': 'assets/images/one.png',
      'Unit_2': 'assets/images/two.png',
      'Unit_3': 'assets/images/three.png',
      'Unit_4': 'assets/images/four.png',
      'Unit_5': 'assets/images/five.png',
    }[unitId] ?? 'assets/images/default.png';

    return SpeakUnit(
      unitId: unitId,
      title: title,
      subtitle: subtitle,
      icon: iconPath,
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
    print('🐛 fetchUnits() 被呼叫了！');
    try {
      final response = await authService.get('/api/speak/speakQuestionSets');
      print('🌀 API 回傳: $response');
      final data = response['speakSets'] as List<dynamic>;
      final loadedUnits = data.map((json) => SpeakUnit.fromJson(json)).toList();
      setState(() {
        units = loadedUnits;
        isLoading = false;
      });
      print('🔥 單元數量: ${units.length}');
    } catch (e, st) {
      print('❌ 取得單元失敗: $e\n$st');
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Column(
        children: [
          const SizedBox(height: 0),
          Stack(
            children: [
              Image.asset(
                'assets/images/star_fruit_header.png',
                width: double.infinity,
                height: 320,
                fit: BoxFit.cover,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                      const Expanded(child: SizedBox()),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('練說話', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Lián kóng-uē', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      const Expanded(child: SizedBox()),
                      const SizedBox(width: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: units.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final unit = units[index];
                  print('👉 單元 title: ${unit.title}, subtitle: ${unit.subtitle}');
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FilterGamePage(unitId: unit.unitId, authService: authService),
                        ),
                      );
                    },
                    child: SizedBox(
                      height: 80,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              unit.icon,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              height: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            // 文字全部置中
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  unit.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.grey900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  unit.subtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
