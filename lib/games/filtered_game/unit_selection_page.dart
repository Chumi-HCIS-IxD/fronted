//filtered_game/unit_selection_page
import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import 'filter_game_page.dart';

class UnitSelectionPage extends StatelessWidget {
  final authService = AuthApiService(baseUrl: 'http://140.116.245.157:5019');
  UnitSelectionPage({super.key});

  // 單元清單：主題/拼音/emoji/icon
  final List<Map<String, String>> units = const [
    {
      'id': 'Unit_1',
      'title': '壹．台灣水果',
      'subtitle': 'Tâi-uân-tsuí-kó',
      'icon': 'assets/images/one.png',
    },
    {
      'id': 'Unit_2',
      'title': '貳．吃飯對話',
      'subtitle': 'tsia̍h-pn̄g-tùi-uē',
      'icon': 'assets/images/two.png',
    },
    {
      'id': 'Unit_3',
      'title': '参．台灣昆蟲',
      'subtitle': 'Tâi-uân-khun-thiông',
      'icon': 'assets/images/three.png',
    },
    {
      'id': 'Unit_4',
      'title': '肆．海底生物',
      'subtitle': 'hái-té-sing-būt',
      'icon': 'assets/images/four.png',
    },
    {
      'id': 'Unit_5',
      'title': '伍．兒時童玩',
      'subtitle': 'gín-á-ê-guân-khù',
      'icon': 'assets/images/five.png',
    },
    {
      'id': 'Unit_6',
      'title': '陸．日常服飾',
      'subtitle': 'jīt-siōng-hok-sik',
      'icon': 'assets/images/six.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 整體底色為淺綠
      backgroundColor: AppColors.primaryLight,
      body: Column(
        children: [
          const SizedBox(height: 0),
          // Header 區塊：背景圖與標題文字
          Stack(
            children: [
              // 背景圖，只覆蓋上方 250 高度
              Image.asset(
                'assets/images/star_fruit_header.png',
                width: double.infinity,
                height: 320,
                fit: BoxFit.cover,
              ),
              // 返回鍵與標題置中疊加
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 返回按鈕
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      // 標題文字
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            '練說話',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lián kóng-uē',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
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
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: units.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FilterGamePage(unitId: unit['id']!, authService: authService),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 圖片全底
                          Image.asset(
                            unit['icon']!,
                            // width: double.infinity,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          // 半透明遮罩提升文字可讀性
                          Container(
                            // width: double.infinity,
                            height: 80,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          // 文本置中
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                unit['title']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                unit['subtitle']!,
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
