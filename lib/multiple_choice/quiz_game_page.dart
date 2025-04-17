import 'dart:async';
import 'package:flutter/material.dart';

/// ────────── 資料模型 ──────────
class Question {
  final String prompt;          // 題目文字
  final List<String> choices;   // 四個選項
  final int answerIndex;        // 正確答案索引

  Question({
    required this.prompt,
    required this.choices,
    required this.answerIndex,
  });
}

/// ────────── 遊戲畫面 ──────────
class QuizGamePage extends StatefulWidget {
  /// 可以從後端丟題目進來；若為 null 就用預設假資料
  final List<Question>? questions;

  const QuizGamePage({super.key, this.questions});

  @override
  State<QuizGamePage> createState() => _QuizGamePageState();
}

class _QuizGamePageState extends State<QuizGamePage> {
  // ===== 遊戲狀態 =====
  late final List<Question> _questions;
  int _curr = 0;                // 目前題號
  int? _picked;                 // 當前題目使用者已選擇的 index
  int _score = 0;               // 累積分數
  int _secondsLeft = 10;        // 倒數計時
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _questions = widget.questions ?? _dummyQuestions;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final q = _questions[_curr];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('選擇題小遊戲'),
        centerTitle: true,
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.account_circle_outlined))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildRoomInfo(),
            const SizedBox(height: 16),
            _buildQuestionCard(q),
            const SizedBox(height: 24),
            _buildChoiceGrid(q),
            const Spacer(),
            _buildTimer(),
          ],
        ),
      ),
    );
  }

  /// 房間資訊（示意）
  Widget _buildRoomInfo() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: const [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('單元一', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('今日主題：台灣水果'),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('房間號碼：30601', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('創建者：王曉仁'),
      ]),
    ],
  );

  /// 題目卡片
  Widget _buildQuestionCard(Question q) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('第 ${_curr + 1} 題', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('「${q.prompt}」', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {}, // TODO: 播放音檔
            icon: const Icon(Icons.play_arrow),
            label: const Text('請選擇一種食物！'),
          ),
        ],
      ),
    ),
  );

  /// 4 選項（2×2）
  Widget _buildChoiceGrid(Question q) => Expanded(
    flex: 0,
    child: GridView.builder(
      shrinkWrap: true,
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
      itemBuilder: (context, i) {
        final isChosen = _picked == i;
        return GestureDetector(
          onTap: _picked == null ? () => _onChoice(i) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isChosen ? Colors.grey.shade400 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                '${String.fromCharCode(65 + i)}. ${q.choices[i]}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        );
      },
    ),
  );

  /// 底部倒數計時
  Widget _buildTimer() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: Colors.black, width: 2),
    ),
    child: Text(
      '00 : ${_secondsLeft.toString().padLeft(2, '0')}',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  // ====== 互動 & 流程 ======
  void _onChoice(int index) {
    setState(() => _picked = index);
    if (index == _questions[_curr].answerIndex) _score++;

    // 0.8 秒後跳下一題
    Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
  }

  void _nextQuestion() {
    _timer?.cancel();
    if (_curr < _questions.length - 1) {
      setState(() {
        _curr++;
        _picked = null;
        _secondsLeft = 10;
      });
      _startTimer();
    } else {
      _showResultDialog();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        _nextQuestion();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('遊戲結束'),
        content: Text('你的得分：$_score / ${_questions.length}'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);      // 關閉對話框
                Navigator.pop(context);      // 回上一頁
              },
              child: const Text('返回'))
        ],
      ),
    );
  }
}

/// ────────── 假資料 ──────────
final _dummyQuestions = [
  Question(
    prompt: '請聽這段話，選出正確的答案！',
    choices: ['番茄炒蛋', '滷肉飯', '烤玉米', '牛肉湯'],
    answerIndex: 1,
  ),
  Question(
    prompt: '下列何者是台灣最高峰？',
    choices: ['玉山', '雪山', '南湖大山', '奇萊主峰'],
    answerIndex: 0,
  ),
  Question(
    prompt: '香蕉的英文是…',
    choices: ['Banana', 'Orange', 'Pineapple', 'Apple'],
    answerIndex: 0,
  ),
];