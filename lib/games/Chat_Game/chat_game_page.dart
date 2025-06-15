import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../services/auth_api_service.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import 'chat_api.dart';

class ChatMessage {
  final String sender;    // 顯示名稱
  final String fileName;  // 檔案顯示文字
  final String audioUrl;  // 後端完整 URL
  ChatMessage({
    required this.sender,
    required this.fileName,
    required this.audioUrl,
  });
}

class ChatGamePlayPage extends StatefulWidget {
  final AuthApiService authService;
  final String roomId;
  const ChatGamePlayPage({
    Key? key,
    required this.authService,
    required this.roomId,
  }) : super(key: key);

  @override
  State<ChatGamePlayPage> createState() => _ChatGamePlayPageState();
}

class _ChatGamePlayPageState extends State<ChatGamePlayPage> {
  // ---- 常數 ----
  static const int _roundSeconds = 180;

  // ---- 使用者 & 房間 ----
  late String _userUid;
  String _userName = '';
  String _hostName = '';
  int _groupIdx = 0;
  String? _partnerUid;

  // ---- 訊息列表 & 檢索 index ----
  List<ChatMessage> _messages = [];
  int _nextFetchIdx = 0; // 用於迴圈呼叫 serve_group_recording

  // ---- 錄音／播放 ----
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _recorderReady = false, _playerReady = false;
  bool _isRecording = false;
  String? _tempPath;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  // ---- 計時 ----
  Timer? _timer;
  int _remaining = _roundSeconds;
  bool _roundActive = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    // 1) 拿 UID
    final uid = await widget.authService.getUid();
    if (uid == null) return;
    _userUid = uid;
    // 2) 初始化自己的顯示名稱
    _userName = await lookupName(_userUid);

    // 3) 拿分組資訊
    await _fetchGroupInfo();
    // 4) 拿房間創建者
    await _fetchRoomInfo();

    // 5) 開啟音訊 session
    await _recorder.openAudioSession();
    _recorderReady = true;
    await _player.openAudioSession();
    _playerReady = true;

    if (_partnerUid == null || _partnerUid!.isEmpty) {
      setState(() {
        _remaining   = 0;
        _roundActive = false;
      });
    } else {
      // 正常啟動倒數
      _startTimer();
      Timer.periodic(const Duration(seconds: 5), (_) => _loadNextMessage());
    }

    // // 7) 啟動倒數以及定時拉新訊息
    // _startTimer();
    // Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  Future<void> _fetchGroupInfo() async {
    final uri = Uri.parse(
        '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}/groups/$_userUid'
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return;
    final js = jsonDecode(res.body) as Map<String, dynamic>;
    final gIdx = js['groupIndex'] as int;
    final members = (js['members'] as List).cast<String>();
    final partner = members.firstWhere((u) => u != _userUid, orElse: () => '');
    setState(() {
      _groupIdx = gIdx;
      _partnerUid = partner;
    });
  }

  Future<void> _fetchRoomInfo() async {
    final uri = Uri.parse(
        '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}'
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return;
    final js = jsonDecode(res.body) as Map<String, dynamic>;
    final hostUid = js['host'] as String? ?? '';
    final realName = await lookupName(hostUid);
    setState(() => _hostName = realName);
  }

  Future<void> _loadNextMessage() async {
    final base  = widget.authService.baseUrl;
    final room  = widget.roomId;
    final group = _groupIdx;
    final idx   = _nextFetchIdx;

    final res = await http.get(
        Uri.parse('$base/api/chat/rooms/$room/groups/$group/record/$idx'));

    // --- A. 新版︰直接得到 audio/wav ---
    final contentType = res.headers['content-type'] ?? '';
    if (res.statusCode == 200 && contentType.contains('audio')) {
      // 1. 存到暫存檔
      final dir     = await getTemporaryDirectory();
      final path    = '${dir.path}/$room\_$group\_$idx.wav';
      // final file    = File(path)..writeAsBytesSync(res.bodyBytes, flush: true);
      final file    = File(path);
      await file.writeAsBytes(res.bodyBytes, flush: true);
      // 2. 計算時長
      // final helper  = FlutterSoundHelper();
      // final dur     = await helper.duration(file.path) ?? Duration.zero;
      final dur   = await _getWavDuration(file.path);
      final fileUri = 'file://${file.path}';
      // final dur     = await helper.duration(fileUri) ?? Duration.zero;
      final ms      = dur.inMilliseconds;
      final label   =
          '${ms ~/ 60000}:${((ms % 60000) ~/ 1000).toString().padLeft(2, '0')}″';

      // 3. 加入訊息 (sender 只能用 unknown，如需顯示名稱請自行補 header 或額外 API)
      setState(() {
        _messages.add(ChatMessage(
          sender:   'Partner',   // 如果後端有 X-Sender-Name header 可改成 res.headers['x-sender-name']
          fileName: label,
          audioUrl: fileUri,   // 本機路徑
        ));
        _nextFetchIdx = idx + 1;
      });
      _scrollToBottom();
      return;
    }

    // --- B. 舊版︰先拿 JSON 再下載檔 ---
    if (res.statusCode == 200 && contentType.contains('json')) {
      final js     = jsonDecode(res.body) as Map<String, dynamic>;
      final userId = js['user']?.toString();
      final sender =
          js['senderName']?.toString() ?? (userId == null ? 'Unknown' : await lookupName(userId));

      final fileUrl = js['fileUrl']?.toString();
      if (fileUrl == null) { _nextFetchIdx = idx + 1; return; }

      String label;
      if (js['duration'] != null) {
        final durMs = js['duration'] as int;
        label =
        '${durMs ~/ 60000}:${((durMs % 60000) ~/ 1000).toString().padLeft(2, '0')}″';
      } else {
        // 舊後端沒給 duration → 下載後計算
        final wavRes = await http.get(Uri.parse(fileUrl));
        if (wavRes.statusCode != 200) return;
        final dir     = await getTemporaryDirectory();
        final tmpFile = File(
            '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.wav')..writeAsBytesSync(
            wavRes.bodyBytes,
            flush: true);

        // final helper = FlutterSoundHelper();
        // final dur    = await helper.duration(tmpFile.path) ?? Duration.zero;
        final dur = await _getWavDuration(tmpFile.path);
        final ms     = dur.inMilliseconds;
        label =
        '${ms ~/ 60000}:${((ms % 60000) ~/ 1000).toString().padLeft(2, '0')}″';
        // 保留本機檔以供播放
        setState(() {
          _messages.add(ChatMessage(
            sender:   sender,
            fileName: label,
            audioUrl: tmpFile.path,
          ));
          _nextFetchIdx = idx + 1;
        });
        _scrollToBottom();
        return;
      }

      // JSON 有 duration 時仍使用遠端 URL
      setState(() {
        _messages.add(ChatMessage(
          sender:   sender,
          fileName: label,
          audioUrl: fileUrl,
        ));
        _nextFetchIdx = idx + 1;
      });
      _scrollToBottom();
      return;
    }

    // --- C. 還沒輪到這筆 ---
    if (res.statusCode == 404) return;

    // --- D. 其他錯誤 ---
    print('► 撈取錄音 idx=$idx 失敗，status=${res.statusCode}, ct=$contentType');
  }

  // Future<void> _loadNextMessage() async {
  //   final base  = widget.authService.baseUrl;
  //   final room  = widget.roomId;
  //   final group = _groupIdx;
  //   final idx   = _nextFetchIdx;
  //
  //   final res = await http.get(
  //       Uri.parse('$base/api/chat/rooms/$room/groups/$group/record/$idx')
  //   );
  //   if (res.statusCode == 200) {
  //     final js = jsonDecode(res.body) as Map<String, dynamic>;
  //     final userId = js['user']?.toString();
  //     if (userId == null) { _nextFetchIdx = idx + 1; return; }
  //     final sender = js['senderName']?.toString() ?? await lookupName(userId);
  //
  //     final fileUrl = js['fileUrl']?.toString();
  //     if (fileUrl == null) { _nextFetchIdx = idx + 1; return; }
  //
  //     String label;
  //     if (js['duration'] != null) {
  //       final durMs = js['duration'] as int;
  //       label = '${durMs~/60000}:${((durMs%60000)~/1000).toString().padLeft(2,'0')}″';
  //     } else {
  //       // 下載一次，量出真實時長
  //       final fileRes = await http.get(Uri.parse(fileUrl));
  //       final dir     = await getTemporaryDirectory();
  //       final ext     = p.extension(fileUrl);
  //       final tmpFile = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext');
  //       await tmpFile.writeAsBytes(fileRes.bodyBytes, flush: true);
  //
  //       final helper = FlutterSoundHelper();
  //       // duration 回傳 Duration
  //       final dur = await helper.duration(tmpFile.path) ?? Duration.zero;
  //       final ms  = dur.inMilliseconds;
  //       label = '${ms ~/ 60000}:${((ms % 60000) ~/ 1000).toString().padLeft(2,'0')}″';
  //       await tmpFile.delete();
  //     }
  //
  //     setState(() {
  //       _messages.add(ChatMessage(
  //         sender:   sender,
  //         fileName: label,
  //         audioUrl: fileUrl,
  //       ));
  //       _nextFetchIdx = idx + 1;
  //     });
  //     _scrollToBottom();
  //
  //   } else if (res.statusCode == 404) {
  //     // 還沒到這筆，等下次
  //     return;
  //   } else {
  //     print('► 撈取錄音 idx=$idx 失敗，status=${res.statusCode}');
  //   }
  // }

  void _startTimer() {
    setState(() {
      _roundActive = true;
      _remaining = _roundSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining   = 0;
          _roundActive = false;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _toggleRecording() async {
    if (!_recorderReady) return;
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        _tempPath = path;
      });
    } else {
      final dir = await Directory.systemTemp.createTemp();
      // ← 改成 .wav
      final file = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.wav';
      // ← 改用 PCM16 WAV
      await _recorder.startRecorder(
        toFile: file,
        codec: Codec.pcm16WAV,
      );
      setState(() {
        _isRecording = true;
        _tempPath = null;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordSeconds++);
      });
    }
  }

  Future<void> _play(String urlOrPath) async {
    if (!_playerReady) return;
    try {
      String localPath;
      Codec codec;

      if (urlOrPath.startsWith('http')) {
        final res = await http.get(Uri.parse(urlOrPath));
        if (res.statusCode != 200) return;
        final dir  = await getTemporaryDirectory();
        final ext  = p.extension(urlOrPath).toLowerCase();
        final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext');
        await file.writeAsBytes(res.bodyBytes, flush: true);

        localPath = file.path;
        codec     = (ext == '.wav') ? Codec.pcm16WAV : Codec.aacADTS;

        // 增加 debug：檔案是否真的存在？大小？
        final exists = await file.exists();
        final len    = exists ? await file.length() : 0;
        print('► downloaded to $localPath, exists=$exists, size=$len');

      } else {
        localPath = urlOrPath;
        final ext = p.extension(localPath).toLowerCase();
        codec     = (ext == '.wav') ? Codec.pcm16WAV : Codec.aacADTS;

        final f = File(localPath);
        final exists = await f.exists();
        final len    = exists ? await f.length() : 0;
        print('► playing local $localPath, exists=$exists, size=$len');
      }

      // 真正播放
      await _player.startPlayer(
        fromURI:    localPath,
        codec:      codec,
        whenFinished: () => setState(() {}),
      );

    } catch (e) {
      print('play error $e');
    }
  }

  Future<void> _uploadRecording() async {
    if (_tempPath == null) return;
    final file = File(_tempPath!);
    if (!await file.exists()) return;

    final uri = Uri.parse(
        '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}/groups/$_groupIdx/record'
    );
    final req = http.MultipartRequest('POST', uri)
      ..fields['user'] = _userUid
      ..files.add(await http.MultipartFile.fromPath('audio', _tempPath!));
    final res = await req.send();
    if (!(res.statusCode >= 200 && res.statusCode < 300)) return;

    final body = await res.stream.bytesToString();
    final js = jsonDecode(body) as Map<String, dynamic>;
    // final idx = js['recordIndex'].toString();
    final idxInt = js['recordIndex'] as int;
    final url = '${baseUrl}/api/chat/rooms/${widget.roomId}/groups/$_groupIdx'
        '/record/$idxInt';
    // final fn  = js['file'] as String;
    // final url = '${widget.authService.baseUrl}/api/chat/rooms/'
    //     '${widget.roomId}/groups/$_groupIdx/record/$idxInt/$fn';

    final seconds = _recordSeconds;
    final durationLabel = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}″';

    setState(() {
      _messages.add(ChatMessage(
        sender: _userName,
        fileName: durationLabel,
        audioUrl: url,
      ));
      // _tempPath = null;
      _tempPath     = null;
      _nextFetchIdx = idxInt + 1;
    });
    _scrollToBottom();
  }

  /// 解析 WAV 檔，從 fmt chunk 取 byteRate，從 data chunk 取 dataSize
  Future<Duration> _getWavDuration(String path) async {
    final raf = await File(path).open();
    try {
      // 1) 讀前 12 bytes: "RIFF" + fileSize + "WAVE"
      final riffHeader = await raf.read(12);
      final riffId = String.fromCharCodes(riffHeader.sublist(0, 4));
      final waveId = String.fromCharCodes(riffHeader.sublist(8, 12));
      if (riffId != 'RIFF' || waveId != 'WAVE') {
        return Duration.zero; // 不是標準 WAV
      }

      int? byteRate;
      int? dataSize;

      // 2) 走訪所有 chunk
      while (true) {
        final hdr = await raf.read(8);
        if (hdr.length < 8) break;
        final id = String.fromCharCodes(hdr.sublist(0, 4));
        final size = ByteData.sublistView(hdr, 4, 8)
            .getUint32(0, Endian.little);

        if (id == 'fmt ') {
          // fmt chunk: audio format (2), channels (2), sampleRate (4), byteRate (4), ...
          final fmt = await raf.read(size);
          // byteRate = ByteData.sublistView(fmt, 4, 8)
          //     .getUint32(0, Endian.little);
          if (fmt.length >= 12) {
            byteRate = ByteData.sublistView(fmt, 8, 12).getUint32(0, Endian.little);
          }
        } else if (id == 'data') {
          dataSize = size;
          break;
        } else {
          // 跳過這個 chunk
          await raf.setPosition(await raf.position() + size);
        }
      }

      if (byteRate == null || dataSize == null || byteRate == 0) {
        return Duration.zero;
      }
      final seconds = dataSize / byteRate;
      return Duration(milliseconds: (seconds * 1000).round());
    } finally {
      await raf.close();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.closeAudioSession();
    _player.closeAudioSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.primaryBG,
      body: Stack(
        children: [
          // 1) 半透明 header（不變）
          Opacity(
            opacity: 0.1,
            child: Image.asset(
              'assets/images/chat_game_header.png',
              width: w, height: 240, fit: BoxFit.cover,
            ),
          ),

          if (!_roundActive && _remaining == 0)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 280,             // 卡片寬度
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/banana.png',
                            width: 80, height: 80),
                        const SizedBox(height: 12),
                        Text(
                          '完成！',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,  // 深綠
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                          child: const Text(
                            '回到首頁',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,    // 黑色字
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 3) 白底主區塊
          Positioned(
            top: 200, left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),

      // SafeArea 內文
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Dimens.paddingPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 返回＆標題
              Row(
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.arrow_back,
                  //       color: Color(0xFF777777)),
                  //   onPressed: () => Navigator.pop(context),
                  // ),
                  const Spacer(),
                  const Column(
                    children: [
                      Text('來聊天',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF008357))),
                      SizedBox(height: 4),
                      Text('lâi khai-káng',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF008357))),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // 補回按鈕空間
                ],
              ),

              const SizedBox(height: 12),

              // 房號＋創建者
              Text('房間號碼：${widget.roomId}　創建者：${_hostName}',
                  style: const TextStyle(fontSize: 13)),

              const SizedBox(height: 12),

              // 卡片＋倒數 Timer
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8F5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text('台灣水果',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text('Tâi-uân tsuí-kó',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                                  ],
                                ),
                              ),
                              // Image.asset(
                              //   'assets/images/橘子.png',
                              //   width: 60,
                              //   height: 60,
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 倒數圓形
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m    = _messages[i];
                    final isMe = m.sender == _userName;

                    // 顏色：自己藍底白字，對方灰底深字
                    final bubbleColor = isMe ? AppColors.primaryLight : AppColors.grey100;
                    final textColor   = isMe ? AppColors.primary        : AppColors.primary;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // 發話者名稱
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              m.sender,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? AppColors.primary : Colors.grey,
                              ),
                            ),
                          ),
                          // 訊息泡泡
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  color: textColor,
                                  onPressed: () => _play(m.audioUrl),
                                ),
                                Text(
                                  m.fileName,
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Expanded(
              //   child: ListView.builder(
              //     controller: _scrollController,
              //     reverse: false, // true 會倒序
              //     padding: const EdgeInsets.only(bottom: 120),
              //     itemCount: _messages.length,
              //     itemBuilder: (_, i) {
              //       final m    = _messages[i];
              //       final isMe = m.sender == _userName;
              //       return Align(
              //         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              //         child: Column(
              //           crossAxisAlignment:
              //           isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              //           children: [
              //             // ★ 顯示發話者
              //             Padding(
              //               padding: const EdgeInsets.symmetric(horizontal: 16),
              //               child: Text(
              //                 m.sender,
              //                 style: TextStyle(
              //                   fontSize: 12,
              //                   color: isMe ? Colors.blueAccent : Colors.grey,
              //                 ),
              //               ),
              //             ),
              //             // 原本的訊息泡泡
              //             Container(
              //               margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              //               padding: const EdgeInsets.all(12),
              //               decoration: BoxDecoration(
              //                 color: isMe ? AppColors.accentBlue : AppColors.grey100,
              //                 borderRadius: BorderRadius.circular(20),
              //               ),
              //               child: Row(
              //                 mainAxisSize: MainAxisSize.min,
              //                 children: [
              //                   IconButton(
              //                     icon: const Icon(Icons.play_arrow),
              //                     color: isMe ? Colors.white : AppColors.primary,
              //                     onPressed: () => _play(m.audioUrl),
              //                   ),
              //                   Text(
              //                     m.fileName,
              //                     style: TextStyle(
              //                         color: isMe ? Colors.white : AppColors.primary
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ],
              //         ),
              //       );
              //     },
              //   ),
              // ),

              // ② 原本的錄音／上傳 UI
              if (_roundActive) ...[
                const SizedBox(height: 8),
                // （錄音區塊，前面建議過不用再貼一次）
              ],

              // 錄音按鈕
              if (_roundActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: _isRecording
                    //── 錄音中：顯示停止＋刪除＋送出 ──
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _recorder.stopRecorder();
                            _recordTimer?.cancel();
                            setState(() {
                              _isRecording = false;
                              _tempPath = null;
                            });
                          },
                        ),
                        Column(
                          children: [
                            Text(
                              '$_recordSeconds″',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              iconSize: 40,
                              icon: const Icon(Icons.stop_circle),
                              onPressed: _toggleRecording,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: AppColors.primary),
                          onPressed: () async {
                            await _uploadRecording();
                            // 上傳完成後可自動清除 tempPath？
                            setState(() => _tempPath = null);
                          },
                        ),
                      ],
                    )
                    //── 錄完了：顯示播放＋刪除＋送出 ──
                        : (_tempPath != null
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => _play(_tempPath!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() => _tempPath = null),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _uploadRecording,
                        ),
                      ],
                    )
                    //── 預設狀態：麥克風按鈕 ──
                        : FloatingActionButton(
                      backgroundColor: AppColors.primaryLight,
                      onPressed: _toggleRecording,
                      child: const Icon(Icons.mic, color: Colors.white,),
                    )
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
          if (!_roundActive && _remaining == 0)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 280,             // 卡片寬度
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBG,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/banana.png',
                            width: 80, height: 80),
                        const SizedBox(height: 12),
                        Text(
                          '完成！',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,  // 深綠
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBG,
                            side: const BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                          child: const Text(
                            '回到首頁',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,    // 黑色字
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
