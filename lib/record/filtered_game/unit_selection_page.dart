// // lib/record/filtered_game/unit_selection_page.dart
//
// import 'package:flutter/material.dart';
// import '../../services/auth_api_service.dart';
// import '../../theme/colors.dart';
// import 'unit_detail_page.dart';
//
// /// SpeakUnit 用來存放 API 回傳的單元資訊
// class SpeakUnit {
//   final String unitId;
//   final String title;
//   final String subtitle;
//   final String iconPath;
//
//   SpeakUnit({
//     required this.unitId,
//     required this.title,
//     required this.subtitle,
//     required this.iconPath,
//   });
//
//   factory SpeakUnit.fromJson(Map<String, dynamic> json) {
//     final unitId = (json['unitId'] ?? '').toString();
//     final title = (json['unitTitle'] ?? '').toString();
//     final subtitle = (json['description'] ?? '').toString();
//
//     final iconPath = {
//       'Unit_1': 'assets/images/one.png',
//       'Unit_2': 'assets/images/two.png',
//       'Unit_3': 'assets/images/three.png',
//       'Unit_4': 'assets/images/four.png',
//       'Unit_5': 'assets/images/five.png',
//     }[unitId] ??
//         'assets/images/default.png';
//
//     return SpeakUnit(
//       unitId: unitId,
//       title: title,
//       subtitle: subtitle,
//       iconPath: iconPath,
//     );
//   }
// }
//
// /// 調整后的 Filter_UnitSelectionPage：
// ///   - 新增從外部傳入的 `authService` 參數
// ///   - 其餘版面部分完全對齊「你提供的排版＆圖片路徑」
// class Filter_UnitSelectionPage extends StatefulWidget {
//   final AuthApiService authService;
//
//   const Filter_UnitSelectionPage({
//     Key? key,
//     required this.authService,
//   }) : super(key: key);
//
//   @override
//   State<Filter_UnitSelectionPage> createState() =>
//       _Filter_UnitSelectionPageState();
// }
//
// class _Filter_UnitSelectionPageState extends State<Filter_UnitSelectionPage> {
//   List<SpeakUnit> units = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchUnits();
//   }
//
//   /// 從 API 抓所有單元（GET /api/speak/speakQuestionSets）
//   void fetchUnits() async {
//     try {
//       final response = await widget.authService.get(
//         '/api/speak/speakQuestionSets',
//       );
//       final data = response['speakSets'] as List<dynamic>;
//       final loaded = data.map((json) => SpeakUnit.fromJson(json)).toList();
//       setState(() {
//         units = loaded;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('❌ 取得單元失敗：$e');
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.primaryLight,
//       body: Column(
//         children: [
//           const SizedBox(height: 0),
//           // ─── 1. Header 區塊（Stack + 圖片 + 文字） ───
//           Stack(
//             children: [
//               Image.asset(
//                 'assets/images/star_fruit_header.png',
//                 width: double.infinity,
//                 height: 320,
//                 fit: BoxFit.cover,
//               ),
//               SafeArea(
//                 child: Padding(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.of(context).pop(),
//                         child: const Icon(
//                           Icons.arrow_back,
//                           color: Colors.white,
//                           size: 28,
//                         ),
//                       ),
//                       const Expanded(child: SizedBox()),
//                       Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: const [
//                           Text(
//                             '練說話',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'Lián kóng-uē',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const Expanded(child: SizedBox()),
//                       const SizedBox(width: 28),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           // ─── 2. 下方圓角列表背景 ───
//           Expanded(
//             child: Container(
//               decoration: const BoxDecoration(
//                 color: AppColors.primaryTint,
//                 borderRadius: BorderRadius.vertical(
//                   top: Radius.circular(36),
//                 ),
//               ),
//               child: isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : ListView.separated(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 16, vertical: 16),
//                 itemCount: units.length,
//                 separatorBuilder: (_, __) => const SizedBox(height: 12),
//                 itemBuilder: (context, index) {
//                   final unit = units[index];
//                   return GestureDetector(
//                     onTap: () async {
//                       // 按下去要跳到詳細頁
//                       final questions = await widget.authService
//                           .fetchFilterQuestions(unit.unitId);
//
//                       // 找出所有同 unitId 的紀錄
//                       final allRecs =
//                       await widget.authService.fetchAllFilterRecords();
//                       final sameUnitRecs = allRecs
//                           .where((r) =>
//                       (r['unitId']?.toString() ?? '') ==
//                           unit.unitId)
//                           .map((r) => r as Map<String, dynamic>)
//                           .toList();
//
//                       String dateString = '未提供時間';
//                       if (sameUnitRecs.isNotEmpty) {
//                         dateString = sameUnitRecs.last['submittedAt']
//                             ?.toString() ??
//                             '未提供時間';
//                       }
//
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => UnitDetailPage(
//                             unitId: unit.unitId,
//                             roomId: 'room_${unit.unitId}',
//                             userId: 'anonymous',
//                             authService: widget.authService,
//                             date: dateString,
//                             recordList: sameUnitRecs,
//                             questions: questions,
//                             unitTitle: unit.title,
//                             unitRoman: unit.subtitle,
//                             topIconAsset: unit.iconPath,
//                             isCompleted: sameUnitRecs.isNotEmpty,
//                           ),
//                         ),
//                       );
//                     },
//                     child: SizedBox(
//                       height: 80,
//                       width: double.infinity,
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(24),
//                         child: Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             // 背景圖
//                             Image.asset(
//                               unit.iconPath,
//                               height: 80,
//                               fit: BoxFit.cover,
//                             ),
//                             // 半透明白遮罩
//                             Container(
//                               height: 80,
//                               color: Colors.white.withOpacity(0.5),
//                             ),
//                             // 文字置中
//                             Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   unit.title,
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                     color: AppColors.grey900,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   unit.subtitle,
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: AppColors.grey700,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import 'unit_detail_page.dart';

// 單元對應表
const unitIcons = {
  'Unit_1': 'assets/images/one.png',
  'Unit_2': 'assets/images/two.png',
  'Unit_3': 'assets/images/three.png',
  'Unit_4': 'assets/images/four.png',
  'Unit_5': 'assets/images/five.png',
  'Unit_6': 'assets/images/six.png',
};
const unitTitles = {
  'Unit_1': '單元一',
  'Unit_2': '單元二',
  'Unit_3': '單元三',
  'Unit_4': '單元四',
  'Unit_5': '單元五',
  'Unit_6': '單元六',
};
const unitSubtitles = {
  'Unit_1': '主題一',
  'Unit_2': '主題二',
  'Unit_3': '主題三',
  'Unit_4': '主題四',
  'Unit_5': '主題五',
  'Unit_6': '主題六',
};

class Filter_UnitSelectionPage extends StatefulWidget {
  final AuthApiService authService;

  const Filter_UnitSelectionPage({Key? key, required this.authService}) : super(key: key);

  @override
  State<Filter_UnitSelectionPage> createState() => _Filter_UnitSelectionPageState();
}

class _Filter_UnitSelectionPageState extends State<Filter_UnitSelectionPage> {
  List<Map<String, dynamic>> recentRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecentRecords();
  }

  /// 只取最近五筆紀錄（依 submittedAt 倒序）
  Future<void> fetchRecentRecords() async {
    try {
      final all = await widget.authService.fetchAllFilterRecords();
      final sorted = List<Map<String, dynamic>>.from(all)
        ..sort((a, b) =>
            (b['submittedAt'] ?? '').toString().compareTo((a['submittedAt'] ?? '').toString()));
      setState(() {
        recentRecords = sorted.take(5).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('❌ 取得紀錄失敗：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Column(
        children: [
          const SizedBox(height: 0),
          // Header
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
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
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
          // 下方圓角列表背景
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (recentRecords.isEmpty
                  ? const Center(
                child: Text('尚無濾鏡小遊戲紀錄',
                    style: TextStyle(fontSize: 18, color: Colors.black45)),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: recentRecords.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final rec = recentRecords[index];
                  final unitId = (rec['unitId'] ?? '').toString();
                  final iconPath = unitIcons[unitId] ?? 'assets/images/default.png';
                  final title = unitTitles[unitId] ?? unitId;
                  final subtitle = unitSubtitles[unitId] ?? '';
                  final dateString = (rec['submittedAt'] ?? '').toString();

                  return GestureDetector(
                    onTap: () async {
                      final questions = await widget.authService.fetchFilterQuestions(unitId);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UnitDetailPage(
                            unitId: unitId,
                            roomId: 'room_$unitId',
                            userId: 'anonymous',
                            authService: widget.authService,
                            date: dateString,
                            recordList: [rec], // 只傳這一筆
                            questions: questions,
                            unitTitle: title,
                            unitRoman: subtitle,
                            topIconAsset: iconPath,
                            isCompleted: true,
                          ),
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
                            // 背景圖
                            Image.asset(
                              iconPath,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                            // 半透明白遮罩
                            Container(
                              height: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            // 文字置中
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.grey900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.grey700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateString,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
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
              )),
            ),
          ),
        ],
      ),
    );
  }
}
