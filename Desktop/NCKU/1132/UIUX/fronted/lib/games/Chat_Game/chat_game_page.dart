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

    // 6) 讀一次歷史訊息
    await _loadMessages();

    // 7) 啟動倒數以及定時拉新訊息
    _startTimer();
    Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
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

  Future<void> _loadMessages() async {
    final base = widget.authService.baseUrl;
    final room = widget.roomId;
    final g    = _groupIdx;
    final helper = FlutterSoundHelper();

    List<ChatMessage> loaded = [];
    // 從 _nextFetchIdx 開始逐筆抓，遇到第一個非 200 就 break
    for (int idx = _nextFetchIdx; idx < _nextFetchIdx + 10; idx++) {
      final uri = Uri.parse(
          '$base/api/chat/rooms/$room/groups/$g/record/$idx/ignored.aac'
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) break;
      final js = jsonDecode(res.body) as Map<String, dynamic>;

      final userId = js['user'] as String;
      final sender = (js['senderName'] as String?) ?? await lookupName(userId);
      final file   = js['file'] as String;
      final durMs  = js['duration'] as int?;
      final label  = durMs != null
          ? '${durMs ~/ 60000}:${((durMs % 60000) ~/ 1000).toString().padLeft(2, '0')}″'
          : file;
      final url = '$base/api/chat/rooms/$room/groups/$g/record/$idx/$file';

      loaded.add(ChatMessage(
        sender: sender,
        fileName: label,
        audioUrl: url,
      ));
      _nextFetchIdx = idx + 1;
    }

    if (loaded.isNotEmpty) {
      setState(() => _messages.addAll(loaded));
      _scrollToBottom();
    }
  }

  void _startTimer() {
    setState(() {
      _roundActive = true;
      _remaining = _roundSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _roundActive = false);
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
      final file = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: file, codec: Codec.aacADTS);
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
    final idx = js['recordIndex'].toString();
    final fn  = js['file'] as String;
    final url = '${widget.authService.baseUrl}/api/chat/rooms/'
        '${widget.roomId}/groups/$_groupIdx/record/$idx/$fn';

    final seconds = _recordSeconds;
    final durationLabel = '${seconds ~/ 60}:"${(seconds % 60).toString().padLeft(2, '0')}″';

    setState(() {
      _messages.add(ChatMessage(
        sender: _userName,
        fileName: durationLabel,
        audioUrl: url,
      ));
      _tempPath = null;
    });
    _scrollToBottom();
  }

  Future<void> _play(String url) async {
    if (!_playerReady) return;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac');
        await file.writeAsBytes(res.bodyBytes, flush: true);

        await _player.startPlayer(
            fromURI: file.path,
            codec: Codec.aacADTS,
            whenFinished: () async {
              await file.delete();
              setState(() {});
            }
        );
      }
    } catch (e) {
      print('play error $e');
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
        // header 半透明
        Opacity(
        opacity: 0.1,
        child: Image.asset(
          'assets/images/chat_game_header.png',
          width: w, height: 240, fit: BoxFit.cover,
        ),
      ),

      // 白底
      Positioned(
        top: 200, left: 0, right: 0, bottom: 0,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(30)),
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Color(0xFF777777)),
                    onPressed: () => Navigator.pop(context),
                  ),
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
                  reverse: false, // true 會倒序
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m    = _messages[i];
                    final isMe = m.sender == _userName;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          // ★ 顯示發話者
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              m.sender,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Colors.blueAccent : Colors.grey,
                              ),
                            ),
                          ),
                          // 原本的訊息泡泡
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.accentBlue : AppColors.grey100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  color: isMe ? Colors.white : AppColors.primary,
                                  onPressed: () => _play(m.audioUrl),
                                ),
                                Text(
                                  m.fileName,
                                  style: TextStyle(
                                      color: isMe ? Colors.white : AppColors.primary
                                  ),
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
                      child: const Icon(Icons.mic),
                    )
                    ),
                  ),
                ),
            ],
          ),
        ),
      )],
      ),
    );
  }
}
