// lib/pages/mcq_game_page.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class McqGamePage extends StatefulWidget {
  final String unitId;
  final String roomId;
  const McqGamePage({
    Key? key,
    required this.unitId,
    required this.roomId,
  }) : super(key: key);

  @override
  State<McqGamePage> createState() => _McqGamePageState();
}

class _McqGamePageState extends State<McqGamePage> {
  List<Question> questions = [];
  bool loading = true;
  int currentIndex = 0;
  int score = 0;
  int elapsed = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadQuestions();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => elapsed++);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => loading = true);

    // Android emulator 用 10.0.2.2，其它平台用 127.0.0.1
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final uri = Uri.parse(
      'http://$host:5019/api/mcq/questionSets/${widget.unitId}/questions',
    );

    try {
      final res = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final Map<String, dynamic> body = json.decode(res.body);
      final raw = body['questions'] as List<dynamic>? ?? <dynamic>[];
      final loaded = raw
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        questions = loaded;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('取題失敗'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('確定'),
            ),
          ],
        ),
      );
    }
  }

  void _choose(int idx) {
    if (questions[currentIndex].ans == idx) {
      score++;
    }
    if (currentIndex + 1 < questions.length) {
      setState(() => currentIndex++);
    } else {
      timer?.cancel();
      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: {'score': score, 'max': questions.length},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final q = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '單元 ${widget.unitId}  •  題目 ${currentIndex + 1}/${questions.length}',
        ),
        centerTitle: true,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('時間：$elapsed s')),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 題目＋播放按鈕
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      q.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () {
                      // TODO: 用 q.audioUrl 播檔
                    },
                  ),
                ],
              ),
            ),
            // 選項格子
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  itemCount: q.option.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (ctx, i) {
                    final label = String.fromCharCode(65 + i);
                    return InkWell(
                      onTap: () => _choose(i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$label. ${q.option[i]}',
                            style: const TextStyle(fontSize: 16),
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
      ),
    );
  }
}

/// 題目 Model
class Question {
  final String title;
  final String audioUrl;
  final List<String> imageUrls;
  final List<String> option;
  final int ans;

  Question({
    required this.title,
    required this.audioUrl,
    required this.imageUrls,
    required this.option,
    required this.ans,
  });

  factory Question.fromJson(Map<String, dynamic> j) {
    return Question(
      title: j['title'] as String? ?? '',
      audioUrl: j['audioUrl'] as String? ?? '',
      imageUrls:
      (j['imageUrls'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      option: (j['option'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      ans: j['ans'] as int? ?? 0,
    );
  }
}