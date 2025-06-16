// lib/utils/platform_audio_player.dart
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

/// 用同一支函式自動判斷 iOS / Android，播放遠端音檔
class PlatformAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String url) async {
    await _player.stop();          // 先停掉任何正在播放的音
    await _player.setVolume(1.0);  // 設定預設音量

    if (Platform.isIOS) {
      /// iOS 直接用 UrlSource
      await _player.play(UrlSource(url));
    } else if (Platform.isAndroid) {
      /// Android 先下載，再 BytesSource
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        throw 'HTTP ${res.statusCode}';
      }
      await _player.play(BytesSource(res.bodyBytes));
    } else {
      /// 其他平台就先嘗試 UrlSource
      await _player.play(UrlSource(url));
    }
  }

  void dispose() => _player.dispose();
}