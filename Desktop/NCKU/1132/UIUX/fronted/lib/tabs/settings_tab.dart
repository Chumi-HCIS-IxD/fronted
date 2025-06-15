import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_api_service.dart';
import '../theme/colors.dart';

class SettingsTab extends StatefulWidget {
  final AuthApiService authService;
  final ValueChanged<bool>? onMusicSettingChanged;

  const SettingsTab({
    Key? key,
    required this.authService,
    this.onMusicSettingChanged,
  }) : super(key: key);

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool isMusicOn = true;
  bool isNotificationOn = true;
  bool isLanguageExpanded = false;
  String selectedLanguage = '中文';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isMusicOn = prefs.getBool('musicOn') ?? true;
      isNotificationOn = prefs.getBool('notificationOn') ?? true;
      selectedLanguage = prefs.getString('selectedLanguage') ?? '中文';
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryBG,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 標題 + 大頭照按鈕
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('設定',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                          SizedBox(height: 4),
                          Text('siat-ting',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey700)),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Scaffold.of(context).openEndDrawer(),
                        child: Image.asset(
                          'assets/icon/profile.png',
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 遊戲背景音樂 開關
              _buildSwitchTile(
                title: '遊戲背景音樂',
                value: isMusicOn,
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  setState(() => isMusicOn = v);
                  await prefs.setBool('musicOn', v);
                  // 通知 HomePage 做音樂開關
                  if (widget.onMusicSettingChanged != null) {
                    widget.onMusicSettingChanged!(v);
                  }
                },
              ),

              const SizedBox(height: 12),

              // 開啟通知 開關
              // _buildSwitchTile(
              //   title: '開啟通知',
              //   value: isNotificationOn,
              //   onChanged: (v) async {
              //     final prefs = await SharedPreferences.getInstance();
              //     setState(() => isNotificationOn = v);
              //     await prefs.setBool('notificationOn', v);
              //   },
              // ),

              const SizedBox(height: 12),

              // 語言切換
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(
                        '語言切換',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      trailing: Icon(
                        isLanguageExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppColors.grey700,
                      ),
                      onTap: () => setState(
                              () => isLanguageExpanded = !isLanguageExpanded),
                    ),
                    if (isLanguageExpanded)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        child: Column(
                          children: ['中文'].map((lang) {
                            final isSelected = lang == selectedLanguage;
                            return GestureDetector(
                              onTap: () async {
                                final prefs = await SharedPreferences.getInstance();
                                setState(() {
                                  selectedLanguage = lang;
                                  isLanguageExpanded = false;
                                });
                                await prefs.setString(
                                    'selectedLanguage', lang);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.primaryTint,
                                child: Text(
                                  lang,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.grey900,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 關於遊戲 區塊
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('關於遊戲',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('遊戲故事',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text(
                      '在台灣的深山裡，住著幾隻會說台語的「水果精靈」，水果精靈們會因為吸收台語知識而長大，維持山林的美好。\n'
                          '但近年來大家越來越少講台語，山林裡的語言能量逐漸消失。五隻水果精靈為了撐住台語的語言能量，展開一場有趣的大冒險，玩家需要協助他們完成任務，來守護台灣記憶！',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 12),
                    Text('開發團隊簡介',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Allen, River, Leo\nJimmy, Libby, Julie',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}