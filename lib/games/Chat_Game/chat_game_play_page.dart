// // lib/games/Chat_Game/chat_game_play_page.dart
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:http/http.dart' as http;
// import '../../services/auth_api_service.dart';
// import 'package:path/path.dart' as path;
//
// class ChatMessage {
//   final String sender;
//   final String fileName;
//   final String audioUrl;
//   ChatMessage({
//     required this.sender,
//     required this.fileName,
//     required this.audioUrl,
//   });
// }
//
// class Pair {
//   final String a;
//   final String b;
//   Pair(this.a, this.b);
// }
//
// class ChatGamePlayPage extends StatefulWidget {
//   final AuthApiService authService;
//   final String roomId;
//   final List<String> participants; // 從大廳傳入的 UID 列表
//
//   const ChatGamePlayPage({
//     Key? key,
//     required this.authService,
//     required this.roomId,
//     required this.participants,
//   }) : super(key: key);
//
//   @override
//   State<ChatGamePlayPage> createState() => _ChatGamePlayPageState();
// }
//
// class _ChatGamePlayPageState extends State<ChatGamePlayPage> {
//   static const String _teacherUid = 'a07fe81b-1f73-46ea-9d52-473017069c43';
//
//   // Round-Robin 配對結果
//   final int _maxRounds = 3;
//   late List<List<Pair>> _pairings;
//   int _currentRound = 0;
//
//   // 當前對話對象
//   String? _partnerUid;
//
//   // 訊息、錄音
//   List<ChatMessage> _messages = [];
//   final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
//   final FlutterSoundPlayer _player = FlutterSoundPlayer();
//   bool _recorderReady = false;
//   bool _playerReady = false;
//   bool _isRecording = false;
//   String? _tempPath;
//
//   // 計時
//   Timer? _roundTimer;
//   int _remaining = 180;
//   bool _roundActive = false;
//
//   // 使用者
//   late String _userUid;
//   String _userName = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _initGame();
//   }
//
//   Future<void> _initGame() async {
//     // 1. 取得自己 UID、名字
//     _userUid = (await widget.authService.getUid())!;
//     final profile = await widget.authService.fetchUserProfile();
//     _userName = (profile?['name'] as String?)?.isNotEmpty == true
//         ? profile!['name'] as String
//         : profile?['username'] as String? ?? _userUid;
//
//     // 2. 準備配對列表
//     _setupPairings();
//
//     // 3. 初始化錄音、播放
//     await _recorder.openRecorder();
//     _recorderReady = true;
//     await _player.openPlayer();
//     _playerReady = true;
//
//     // 4. 開始第一輪
//     _startRound();
//   }
//
//   void _setupPairings() {
//     // 複製一份參與者列表，奇數時加入老師
//     List<String> list = List.from(widget.participants);
//     if (list.length % 2 != 0 && !list.contains(_teacherUid)) {
//       list.add(_teacherUid);
//     }
//     int n = list.length;
//     list.shuffle();
//
//     // 用“圓桌”算法產生最多 _maxRounds 輪
//     _pairings = [];
//     List<String> arrange = List.from(list);
//     int rounds = (_maxRounds < n - 1) ? _maxRounds : (n - 1);
//     for (int r = 0; r < rounds; r++) {
//       List<Pair> pairs = [];
//       for (int i = 0; i < n ~/ 2; i++) {
//         pairs.add(Pair(arrange[i], arrange[n - 1 - i]));
//       }
//       _pairings.add(pairs);
//       // rotate: keep arrange[0], move last to index1
//       var last = arrange.removeLast();
//       arrange.insert(1, last);
//     }
//   }
//
//   void _startRound() {
//     // 確定本輪的 partner
//     final pairs = _pairings[_currentRound];
//     final myPair = pairs.firstWhere(
//           (p) => p.a == _userUid || p.b == _userUid,
//       orElse: () => Pair(_userUid, _userUid),
//     );
//     _partnerUid = (myPair.a == _userUid) ? myPair.b : myPair.a;
//
//     setState(() {
//       _messages.clear();
//       _remaining = 180;
//       _roundActive = true;
//     });
//     _roundTimer?.cancel();
//     _roundTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (_remaining <= 1) {
//         t.cancel();
//         setState(() => _roundActive = false);
//         _onRoundEnd();
//       } else {
//         setState(() => _remaining--);
//       }
//     });
//   }
//
//   void _onRoundEnd() {
//     if (_currentRound < _pairings.length - 1) {
//       setState(() => _currentRound++);
//       _startRound();
//     } else {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('所有輪次結束')));
//     }
//   }
//
//   Future<void> _toggleRecording() async {
//     if (!_recorderReady) return;
//     if (_isRecording) {
//       final p = await _recorder.stopRecorder();
//       setState(() {
//         _isRecording = false;
//         _tempPath = p;
//       });
//     } else {
//       final dir = await Directory.systemTemp.createTemp();
//       final filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
//       await _recorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);
//       setState(() {
//         _isRecording = true;
//         _tempPath = null;
//       });
//     }
//   }
//
//   Future<void> _uploadRecording() async {
//     if (_tempPath == null) return;
//     final file = File(_tempPath!);
//     if (!await file.exists()) return;
//
//     final uri = Uri.parse(
//       '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}'
//           '/groups/$_currentRound/record',
//     );
//     final req = http.MultipartRequest('POST', uri)
//       ..fields['user'] = _userUid
//       ..files.add(await http.MultipartFile.fromPath('audio', _tempPath!));
//     final res = await req.send();
//     if (res.statusCode >= 200 && res.statusCode < 300) {
//       final body = await res.stream.bytesToString();
//       final js = jsonDecode(body) as Map<String, dynamic>;
//       final fn = js['file'] as String? ?? path.basename(_tempPath!);
//       final recIdx = js['recordIndex'];
//       final url =
//           '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}'
//           '/groups/$_currentRound/record/$recIdx/$fn';
//       setState(() {
//         _messages.add(ChatMessage(sender: _userName, fileName: fn, audioUrl: url));
//         _tempPath = null;
//       });
//     }
//   }
//
//   Future<void> _play(String url) async {
//     if (!_playerReady) return;
//     try {
//       if (url.toLowerCase().endsWith('.wav')) {
//         await _player.startPlayer(fromURI: url, codec: Codec.pcm16WAV);
//       } else if (url.toLowerCase().endsWith('.aac') ||
//           url.toLowerCase().endsWith('.adts')) {
//         await _player.startPlayer(fromURI: url, codec: Codec.aacADTS);
//       } else {
//         await _player.startPlayer(fromURI: url);
//       }
//     } catch (e) {
//       debugPrint('❌ 播放失敗：$e');
//     }
//   }
//
//   @override
//   void dispose() {
//     _roundTimer?.cancel();
//     _recorder.closeRecorder();
//     _player.closePlayer();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('聊天（第 ${_currentRound + 1} 輪，剩餘 $_remaining 秒）')),
//       body: Column(
//         children: [
//           if (_roundActive && _partnerUid != null)
//             Padding(
//               padding: const EdgeInsets.all(8),
//               child: Text('本輪您與 $_partnerUid 配對聊天',
//                   style: const TextStyle(fontWeight: FontWeight.bold)),
//             ),
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: _messages.length,
//               itemBuilder: (c, i) {
//                 final m = _messages[i];
//                 final me = m.sender == _userName;
//                 return Align(
//                   alignment: me ? Alignment.centerRight : Alignment.centerLeft,
//                   child: GestureDetector(
//                     onTap: () => _play(m.audioUrl),
//                     child: Container(
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: me ? Colors.blue[100] : Colors.grey[200],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(m.sender,
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.bold, fontSize: 12)),
//                           const SizedBox(height: 4),
//                           Text(m.fileName),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           if (_roundActive)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(
//                   icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic),
//                   iconSize: 36,
//                   onPressed: _toggleRecording,
//                 ),
//                 const SizedBox(width: 16),
//                 if (_tempPath != null)
//                   ElevatedButton(
//                       onPressed: _uploadRecording, child: const Text('上傳')),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_api_service.dart';
import 'package:path/path.dart' as path;

class ChatMessage {
  final String sender;
  final String fileName;
  final String audioUrl;

  ChatMessage({
    required this.sender,
    required this.fileName,
    required this.audioUrl,
  });
}

class Pair {
  final String a;
  final String b;
  Pair(this.a, this.b);
}

class ChatGamePlayPage extends StatefulWidget {
  final AuthApiService authService;
  final String roomId;
  final List<String> participants;

  const ChatGamePlayPage({
    Key? key,
    required this.authService,
    required this.roomId,
    required this.participants,
  }) : super(key: key);

  @override
  State<ChatGamePlayPage> createState() => _ChatGamePlayPageState();
}

class _ChatGamePlayPageState extends State<ChatGamePlayPage> {
  static const String _teacherUid = 'a07fe81b-1f73-46ea-9d52-473017069c43';

  final int _maxRounds = 3;
  late List<List<Pair>> _pairings;
  int _currentRound = 0;
  String? _partnerUid;

  List<ChatMessage> _messages = [];
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _recorderReady = false;
  bool _playerReady = false;
  bool _isRecording = false;
  String? _tempPath;

  Timer? _roundTimer;
  int _remaining = 180;
  bool _roundActive = false;

  late String _userUid;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    _userUid = (await widget.authService.getUid())!;
    final profile = await widget.authService.fetchUserProfile();
    _userName = (profile?['name'] as String?)?.isNotEmpty == true
        ? profile!['name'] as String
        : profile?['username'] as String? ?? _userUid;

    _setupPairings();

    await _recorder.openRecorder();
    _recorderReady = true;
    await _player.openPlayer();
    _playerReady = true;

    _startRound();
  }

  void _setupPairings() {
    List<String> list = List.from(widget.participants);
    if (list.length % 2 != 0 && !list.contains(_teacherUid)) {
      list.add(_teacherUid);
    }
    int n = list.length;
    list.shuffle();

    _pairings = [];
    int rounds = (_maxRounds < n - 1) ? _maxRounds : (n - 1);
    List<String> arrange = List.from(list);
    for (int r = 0; r < rounds; r++) {
      List<Pair> pairs = [];
      for (int i = 0; i < n ~/ 2; i++) {
        pairs.add(Pair(arrange[i], arrange[n - 1 - i]));
      }
      _pairings.add(pairs);
      var last = arrange.removeLast();
      arrange.insert(1, last);
    }
  }

  void _startRound() {
    final pairs = _pairings[_currentRound];
    final myPair = pairs.firstWhere(
          (p) => p.a == _userUid || p.b == _userUid,
      orElse: () => Pair(_userUid, _userUid),
    );
    _partnerUid = (myPair.a == _userUid) ? myPair.b : myPair.a;

    setState(() {
      _messages.clear();
      _remaining = 180;
      _roundActive = true;
    });

    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _roundActive = false);
        _onRoundEnd();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _onRoundEnd() {
    if (_currentRound < _pairings.length - 1) {
      setState(() => _currentRound++);
      _startRound();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('所有輪次結束')));
    }
  }

  Future<void> _toggleRecording() async {
    if (!_recorderReady) return;
    if (_isRecording) {
      final p = await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _tempPath = p;
      });
    } else {
      final dir = await Directory.systemTemp.createTemp();
      final filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);
      setState(() {
        _isRecording = true;
        _tempPath = null;
      });
    }
  }

  Future<void> _uploadRecording() async {
    if (_tempPath == null) return;
    final file = File(_tempPath!);
    if (!await file.exists()) return;

    final uri = Uri.parse(
      '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}'
          '/groups/$_currentRound/record',
    );
    final req = http.MultipartRequest('POST', uri)
      ..fields['user'] = _userUid
      ..files.add(await http.MultipartFile.fromPath('audio', _tempPath!));
    final res = await req.send();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = await res.stream.bytesToString();
      final js = jsonDecode(body) as Map<String, dynamic>;
      final fn = js['file'] as String? ?? path.basename(_tempPath!);
      final recIdx = js['recordIndex'];
      final url =
          '${widget.authService.baseUrl}/api/chat/rooms/${widget.roomId}'
          '/groups/$_currentRound/record/$recIdx/$fn';
      setState(() {
        _messages.add(ChatMessage(sender: _userName, fileName: fn, audioUrl: url));
        _tempPath = null;
      });
    }
  }

  Future<void> _play(String url) async {
    if (!_playerReady) return;
    try {
      if (url.toLowerCase().endsWith('.wav')) {
        await _player.startPlayer(fromURI: url, codec: Codec.pcm16WAV);
      } else if (url.toLowerCase().endsWith('.aac') ||
          url.toLowerCase().endsWith('.adts')) {
        await _player.startPlayer(fromURI: url, codec: Codec.aacADTS);
      } else {
        await _player.startPlayer(fromURI: url);
      }
    } catch (e) {
      debugPrint('❌ 播放失敗：\$e');
    }
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('聊天（第 \${_currentRound + 1} 輪，剩餘 \$_remaining 秒）'),
      ),
      body: Column(
        children: [
          if (_roundActive && _partnerUid != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '本輪您與 \$_partnerUid 配對聊天',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: _roundActive
                ? ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (c, i) {
                final m = _messages[i];
                final me = m.sender == _userName;
                return Align(
                  alignment: me
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: me ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => _play(m.audioUrl),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.sender,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(m.fileName),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
                : const Center(child: Text('等待下一輪開始')),
          ),
          if (_roundActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic),
                  iconSize: 36,
                  onPressed: _toggleRecording,
                ),
                const SizedBox(width: 16),
                if (_tempPath != null)
                  ElevatedButton(onPressed: _uploadRecording, child: const Text('上傳')),
              ],
            ),
        ],
      ),
    );
  }
}
