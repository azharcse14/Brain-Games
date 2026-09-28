import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Game {
  const Game(this.name, this.cat, this.build, {this.glyph, this.bn});
  final String name, cat; // English name keys best scores and routes, so switching language keeps them
  final Widget Function() build;
  final String? glyph; // card icon; falls back to the glyphs map in main.dart
  final String? bn; // Bangla name
  String get title => tr(name, bn ?? name);
}

// ---------- language ----------

/// UI language: true = বাংলা. Only changes on the home screen, so games may read it once when they build a round.
final bangla = ValueNotifier(false);

/// English or Bangla text for the current language.
String tr(String en, String bn) => bangla.value ? bn : en;

/// Bangla game names by English name, so [page] can title a game from the English name it's given. Filled in main.dart.
final bnNames = <String, String>{};

final _r = Random();

final otherGames = <Game>[
  Game('Simon Says', 'Memory', () => const Simon(), bn: 'সাইমন বলে'),
  Game('Number Memory', 'Memory', () => const NumberMemory(), bn: 'সংখ্যা মনে রাখা'),
  for (final n in [3, 4, 5]) Game('Pattern Memory $n×$n', 'Memory', () => PatternMemory(n), bn: 'নকশা মনে রাখা $n×$n'),
  for (final (c, r) in [(3, 4), (4, 4), (4, 5)]) Game('Card Match ${c * r ~/ 2} Pairs', 'Memory', () => CardMatch(c, r), bn: 'কার্ড মেলানো ${c * r ~/ 2} জোড়া'),
  Game('Reaction Time', 'Focus', () => const Reaction(), bn: 'প্রতিক্রিয়ার সময়'),
  for (final n in [3, 4, 5]) Game('Schulte Table $n×$n', 'Focus', () => Schulte(n), bn: 'শুল্টে টেবিল $n×$n'),
  Game('Aim Trainer', 'Focus', () => const Aim(), bn: 'নিশানা অনুশীলন'),
  for (final n in [3, 4]) Game('Sliding Puzzle $n×$n', 'Puzzle', () => Sliding(n), bn: 'স্লাইডিং পাজল $n×$n'),
  for (final n in [3, 4, 5]) Game('Lights Out $n×$n', 'Puzzle', () => LightsOut(n), bn: 'বাতি নেভাও $n×$n'),
  Game('Tic Tac Toe', 'Puzzle', () => const TicTacToe(), bn: 'টিক ট্যাক টো'),
  Game('Guess the Number', 'Puzzle', () => const GuessNumber(), bn: 'সংখ্যা অনুমান'),
];

// ---------- shared UI ----------

/// Game screen. Back asks first so a stray tap doesn't throw away a game in progress; Navigator.pop (the result dialog's Exit) skips the question.
Widget page(String title, Widget body, [String? status]) => Builder(
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final nav = Navigator.of(context);
          final leave = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(tr('Leave game?', 'গেম ছেড়ে যাবেন?')),
              content: Text(tr('Your progress will be lost.', 'এই গেমের অগ্রগতি হারিয়ে যাবে।')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Stay', 'থাকুন'))),
                FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Leave', 'ছেড়ে যান'))),
              ],
            ),
          );
          if (leave ?? false) nav.pop();
        },
        child: Scaffold(
          appBar: AppBar(title: Text(tr(title, bnNames[title] ?? title)), actions: [
            // Shrinks rather than overflows when a long (often Bangla) status meets a narrow phone.
            if (status != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 170), child: FittedBox(fit: BoxFit.scaleDown, child: Text(status, style: const TextStyle(fontSize: 16)))),
              ),
          ]),
          body: SafeArea(child: body),
        ),
      ),
    );

Widget board(int cols, int count, Widget Function(int) cell, {double gap = 8}) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // boards never scroll; keeps swipes for games like 2048
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          children: List.generate(count, cell),
        ),
      ),
    );

Widget tile(Color color, {String text = '', VoidCallback? onTap}) => Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap == null
            ? null
            : () {
                sfx('tap');
                onTap();
              },
        child: Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    );

SharedPreferences? prefs;

/// Saves [v] as the best score of the current route's game if it beats the old one.
bool record(BuildContext context, num v, {bool lower = false, String unit = ''}) {
  final name = ModalRoute.of(context)?.settings.name, p = prefs;
  if (name == null || p == null || (!lower && v <= 0)) return false; // scoring 0 is never a record
  final old = p.getDouble('best:$name');
  if (old != null && (lower ? v >= old : v <= old)) return false;
  p.setDouble('best:$name', v.toDouble());
  p.setString('bestText:$name', '$v$unit');
  return true;
}

final _players = <String, AudioPlayer>{};

/// Plays assets/sfx/[name].wav with a matching buzz, unless muted.
void sfx(String name) {
  if (prefs?.getBool('mute') ?? false) return;
  name == 'tap' ? HapticFeedback.selectionClick() : HapticFeedback.mediumImpact();
  final p = _players.putIfAbsent(name, AudioPlayer.new);
  p.stop().then((_) => p.play(AssetSource('sfx/$name.wav'))).ignore();
}

void showResult(BuildContext context, String msg, VoidCallback again, {num? score, bool lower = false, String unit = '', bool won = true}) {
  final best = score != null && record(context, score, lower: lower, unit: unit);
  sfx(best || won ? 'win' : 'wrong');
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => AlertDialog(
      title: Text(best ? tr('🏆 New best!', '🏆 নতুন রেকর্ড!') : tr('Result', 'ফলাফল')),
      content: Text(msg, style: const TextStyle(fontSize: 20)),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(c)
              ..pop()
              ..pop(),
            child: Text(tr('Exit', 'বের হন'))),
        FilledButton(
            onPressed: () {
              Navigator.pop(c);
              again();
            },
            child: Text(tr('Play again', 'আবার খেলুন'))),
      ],
    ),
  );
}

/// Orthogonal neighbours of cell [i] on an [n]×[n] grid.
List<int> adj(int i, int n) => [
      if (i % n > 0) i - 1,
      if (i % n < n - 1) i + 1,
      if (i >= n) i - n,
      if (i < n * n - n) i + n,
    ];

// ---------- Memory ----------

class Simon extends StatefulWidget {
  const Simon({super.key});
  @override
  State<Simon> createState() => _SimonState();
}

class _SimonState extends State<Simon> {
  static const colors = [Colors.red, Colors.green, Colors.blue, Colors.amber];
  final seq = <int>[];
  int step = 0;
  int? lit;
  bool busy = true;

  @override
  void initState() {
    super.initState();
    next();
  }

  Future<void> flash(int i) async {
    setState(() => lit = i);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => lit = null);
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> next() async {
    seq.add(_r.nextInt(4));
    step = 0;
    setState(() => busy = true);
    await Future.delayed(const Duration(milliseconds: 700));
    for (final i in seq) {
      if (!mounted) return;
      await flash(i);
    }
    if (mounted) setState(() => busy = false);
  }

  void tap(int i) {
    if (busy) return;
    flash(i);
    if (seq[step] != i) {
      busy = true;
      showResult(context, won: false, score: seq.length - 1, tr('Score: ${seq.length - 1}', 'স্কোর: ${seq.length - 1}'), () {
        seq.clear();
        next();
      });
    } else if (++step == seq.length) {
      sfx('right');
      next();
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Simon Says', 'সাইমন বলে'),
        board(2, 4, (i) => tile(lit == i ? colors[i] : colors[i].withValues(alpha: .3), onTap: () => tap(i))),
        busy ? tr('Watch…', 'দেখুন…') : tr('Level ${seq.length}', 'লেভেল ${seq.length}'),
      );
}

class NumberMemory extends StatefulWidget {
  const NumberMemory({super.key});
  @override
  State<NumberMemory> createState() => _NumberMemoryState();
}

class _NumberMemoryState extends State<NumberMemory> {
  final ctrl = TextEditingController();
  int level = 1;
  String target = '';
  bool showing = true;
  Timer? t;

  @override
  void initState() {
    super.initState();
    start();
  }

  @override
  void dispose() {
    t?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  void start() {
    target = List.generate(level + 2, (_) => _r.nextInt(10)).join();
    ctrl.clear();
    setState(() => showing = true);
    t = Timer(Duration(milliseconds: 1000 + 600 * level), () => setState(() => showing = false));
  }

  void submit() {
    if (ctrl.text.trim() == target) {
      sfx('right');
      level++;
      start();
    } else {
      showResult(context, won: false, score: level - 1, tr('Number was $target\nLevels cleared: ${level - 1}', 'সংখ্যাটি ছিল $target\nপার হওয়া লেভেল: ${level - 1}'), () {
        level = 1;
        start();
      });
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Number Memory', 'সংখ্যা মনে রাখা'),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: showing
                ? FittedBox(child: Text(target, style: const TextStyle(fontSize: 44, letterSpacing: 4)))
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32),
                      decoration: InputDecoration(hintText: tr('What was the number?', 'সংখ্যাটি কী ছিল?')),
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: submit, child: Text(tr('Submit', 'জমা দিন'))),
                  ]),
          ),
        ),
        tr('Level $level', 'লেভেল $level'),
      );
}

class PatternMemory extends StatefulWidget {
  const PatternMemory(this.n, {super.key});
  final int n;
  @override
  State<PatternMemory> createState() => _PatternMemoryState();
}

class _PatternMemoryState extends State<PatternMemory> {
  int level = 1;
  Set<int> target = {}, hit = {};
  bool showing = true;
  Timer? t;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  void start() {
    final k = min(n + level - 1, n * n - 1);
    target = (List.generate(n * n, (i) => i)..shuffle(_r)).take(k).toSet();
    hit = {};
    setState(() => showing = true);
    t = Timer(const Duration(milliseconds: 1500), () => setState(() => showing = false));
  }

  void tap(int i) {
    if (showing || hit.length == target.length || hit.contains(i)) return; // ignore taps while the next level loads
    if (!target.contains(i)) {
      setState(() => showing = true);
      showResult(context, won: false, score: level - 1, tr('Levels cleared: ${level - 1}', 'পার হওয়া লেভেল: ${level - 1}'), () {
        level = 1;
        start();
      });
      return;
    }
    setState(() => hit.add(i));
    if (hit.length == target.length) {
      sfx('right');
      level++;
      t = Timer(const Duration(milliseconds: 400), start);
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Pattern Memory', 'নকশা মনে রাখা'),
        board(n, n * n, (i) {
          final on = (showing && target.contains(i)) || hit.contains(i);
          return tile(on ? Colors.teal : Colors.grey.shade800, onTap: () => tap(i));
        }),
        tr('Level $level', 'লেভেল $level'),
      );
}

class CardMatch extends StatefulWidget {
  const CardMatch(this.cols, this.rows, {super.key});
  final int cols, rows;
  @override
  State<CardMatch> createState() => _CardMatchState();
}

class _CardMatchState extends State<CardMatch> {
  static const emojis = ['🐶', '🐱', '🦊', '🐼', '🐸', '🐵', '🦁', '🐙', '🦄', '🐝', '🐢', '🐧'];
  late List<String> cards;
  final open = <int>[], done = <int>{};
  int moves = 0;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    final picks = (emojis.toList()..shuffle(_r)).take(widget.cols * widget.rows ~/ 2);
    cards = [...picks, ...picks]..shuffle(_r);
    open.clear();
    done.clear();
    moves = 0;
  }

  void tap(int i) {
    if (open.length == 2 || open.contains(i) || done.contains(i)) return;
    setState(() => open.add(i));
    if (open.length < 2) return;
    moves++;
    if (cards[open[0]] == cards[open[1]]) {
      sfx('right');
      setState(() {
        done.addAll(open);
        open.clear();
      });
      if (done.length == cards.length) showResult(context, score: moves, lower: true, unit: ' moves', tr('Solved in $moves moves', '$moves চালে সমাধান'), () => setState(start));
    } else {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(open.clear);
      });
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Card Match', 'কার্ড মেলানো'),
        board(widget.cols, cards.length, (i) {
          final up = open.contains(i) || done.contains(i);
          return tile(up ? Colors.indigo : Colors.blueGrey.shade700, text: up ? cards[i] : '', onTap: () => tap(i));
        }),
        tr('Moves $moves', 'চাল $moves'),
      );
}

// ---------- Focus ----------

class Reaction extends StatefulWidget {
  const Reaction({super.key});
  @override
  State<Reaction> createState() => _ReactionState();
}

class _ReactionState extends State<Reaction> {
  String state = 'wait'; // wait | go | result | early
  final sw = Stopwatch();
  final times = <int>[];
  Timer? t;

  @override
  void initState() {
    super.initState();
    arm();
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  void arm() {
    setState(() => state = 'wait');
    t = Timer(Duration(milliseconds: 1500 + _r.nextInt(2500)), () {
      sw
        ..reset()
        ..start();
      setState(() => state = 'go');
    });
  }

  void tap() {
    switch (state) {
      case 'wait':
        t?.cancel();
        setState(() => state = 'early');
      case 'go':
        sw.stop();
        setState(() {
          times.add(sw.elapsedMilliseconds);
          record(context, sw.elapsedMilliseconds, lower: true, unit: ' ms');
          state = 'result';
        });
      default:
        arm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (state) {
      'wait' => (Colors.red.shade700, tr('Wait for green…', 'সবুজের অপেক্ষা করুন…')),
      'go' => (Colors.green.shade600, tr('TAP!', 'চাপুন!')),
      'early' => (Colors.orange.shade800, tr('Too soon!\nTap to retry', 'খুব আগে!\nআবার চেষ্টা করতে চাপুন')),
      _ => (Colors.blue.shade700, tr('${times.last} ms\nBest: ${times.reduce(min)} ms\nTap to retry', '${times.last} ms\nসেরা: ${times.reduce(min)} ms\nআবার খেলতে চাপুন')),
    };
    return page(
      tr('Reaction Time', 'প্রতিক্রিয়ার সময়'),
      GestureDetector(
        onTapDown: (_) => tap(),
        child: Container(
          color: color,
          alignment: Alignment.center,
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 36, color: Colors.white)),
        ),
      ),
    );
  }
}

class Schulte extends StatefulWidget {
  const Schulte(this.n, {super.key});
  final int n;
  @override
  State<Schulte> createState() => _SchulteState();
}

class _SchulteState extends State<Schulte> {
  final sw = Stopwatch();
  late List<int> nums;
  int next = 1;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    nums = List.generate(n * n, (i) => i + 1)..shuffle(_r);
    next = 1;
    sw
      ..reset()
      ..start();
  }

  void tap(int v) {
    if (v != next) return;
    setState(() => next++);
    if (next > n * n) {
      sw.stop();
      final secs = (sw.elapsedMilliseconds / 1000).toStringAsFixed(2);
      showResult(context, score: double.parse(secs), lower: true, unit: ' s', tr('Time: $secs s', 'সময়: $secs s'), () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Schulte Table', 'শুল্টে টেবিল'),
        board(n, n * n, (i) => tile(nums[i] < next ? Colors.green.shade900 : Colors.blueGrey.shade700, text: '${nums[i]}', onTap: () => tap(nums[i]))),
        tr('Find $next', '$next খুঁজুন'),
      );
}

class Aim extends StatefulWidget {
  const Aim({super.key});
  @override
  State<Aim> createState() => _AimState();
}

class _AimState extends State<Aim> {
  static const goal = 20, size = 60.0;
  final sw = Stopwatch()..start();
  int hits = 0;
  Offset pos = const Offset(.5, .5);

  void hit() {
    setState(() {
      hits++;
      pos = Offset(_r.nextDouble(), _r.nextDouble());
    });
    if (hits == goal) {
      sw.stop();
      showResult(context, score: sw.elapsedMilliseconds ~/ goal, lower: true, unit: ' ms', tr('Avg ${sw.elapsedMilliseconds ~/ goal} ms per target', 'প্রতি লক্ষ্যে গড় ${sw.elapsedMilliseconds ~/ goal} ms'), () {
        setState(() => hits = 0);
        sw
          ..reset()
          ..start();
      });
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Aim Trainer', 'নিশানা অনুশীলন'),
        LayoutBuilder(
          builder: (_, box) => Stack(children: [
            Positioned(
              left: pos.dx * (box.maxWidth - size),
              top: pos.dy * (box.maxHeight - size),
              child: GestureDetector(
                onTapDown: (_) => hit(),
                child: Container(width: size, height: size, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
              ),
            ),
          ]),
        ),
        '$hits/$goal',
      );
}

// ---------- Puzzle ----------

class Sliding extends StatefulWidget {
  const Sliding(this.n, {super.key});
  final int n;
  @override
  State<Sliding> createState() => _SlidingState();
}

class _SlidingState extends State<Sliding> {
  late List<int> t; // 0 = blank
  int moves = 0;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    t = List.generate(n * n, (i) => (i + 1) % (n * n));
    // Scramble with legal moves so it's always solvable.
    for (var k = 0; k < 400; k++) {
      final b = t.indexOf(0), nb = adj(b, n), m = nb[_r.nextInt(nb.length)];
      t[b] = t[m];
      t[m] = 0;
    }
    moves = 0;
  }

  void tap(int i) {
    final b = t.indexOf(0);
    if (!adj(b, n).contains(i)) return;
    setState(() {
      t[b] = t[i];
      t[i] = 0;
      moves++;
    });
    if (List.generate(n * n, (i) => i).every((i) => t[i] == (i + 1) % (n * n))) {
      showResult(context, score: moves, lower: true, unit: ' moves', tr('Solved in $moves moves', '$moves চালে সমাধান'), () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Sliding Puzzle', 'স্লাইডিং পাজল'),
        board(n, n * n, (i) => t[i] == 0 ? const SizedBox() : tile(Colors.deepPurple, text: '${t[i]}', onTap: () => tap(i))),
        tr('Moves $moves', 'চাল $moves'),
      );
}

class LightsOut extends StatefulWidget {
  const LightsOut(this.n, {super.key});
  final int n;
  @override
  State<LightsOut> createState() => _LightsOutState();
}

class _LightsOutState extends State<LightsOut> {
  late List<bool> on;
  int moves = 0;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void press(int i) {
    for (final j in [i, ...adj(i, n)]) {
      on[j] = !on[j];
    }
  }

  void start() {
    // Scramble with real presses so it's always solvable.
    on = List.filled(n * n, false);
    for (var k = 0; k < n * n; k++) {
      if (_r.nextBool()) press(k);
    }
    if (!on.contains(true)) press(n * n ~/ 2);
    moves = 0;
  }

  void tap(int i) {
    setState(() {
      press(i);
      moves++;
    });
    if (!on.contains(true)) showResult(context, score: moves, lower: true, unit: ' moves', tr('All lights out in $moves moves', '$moves চালে সব বাতি নিভেছে'), () => setState(start));
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Lights Out', 'বাতি নেভাও'),
        board(n, n * n, (i) => tile(on[i] ? Colors.amber : Colors.grey.shade800, onTap: () => tap(i))),
        tr('Moves $moves', 'চাল $moves'),
      );
}

class TicTacToe extends StatefulWidget {
  const TicTacToe({super.key});
  @override
  State<TicTacToe> createState() => _TicTacToeState();
}

class _TicTacToeState extends State<TicTacToe> {
  static const lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6]
  ];
  final b = List.filled(9, '');

  static String? winner(List<String> b) {
    for (final l in lines) {
      if (b[l[0]] != '' && b[l[0]] == b[l[1]] && b[l[1]] == b[l[2]]) return b[l[0]];
    }
    return b.contains('') ? null : 'draw';
  }

  static int minimax(List<String> b, bool ai) {
    final w = winner(b);
    if (w != null) return w == 'O' ? 1 : (w == 'X' ? -1 : 0);
    var best = ai ? -2 : 2;
    for (var i = 0; i < 9; i++) {
      if (b[i] != '') continue;
      b[i] = ai ? 'O' : 'X';
      final s = minimax(b, !ai);
      b[i] = '';
      best = ai ? max(best, s) : min(best, s);
    }
    return best;
  }

  void tap(int i) {
    if (b[i] != '' || winner(b) != null) return;
    setState(() {
      b[i] = 'X';
      if (winner(b) != null) return;
      final free = [
        for (var j = 0; j < 9; j++)
          if (b[j] == '') j
      ]..shuffle(_r);
      var bi = free.first, bs = -2;
      for (final j in free) {
        b[j] = 'O';
        final s = minimax(b, false);
        b[j] = '';
        if (s > bs) (bs, bi) = (s, j);
      }
      b[bi] = 'O';
    });
    final w = winner(b);
    if (w != null) {
      showResult(context, won: w != 'O', w == 'draw' ? tr("It's a draw", 'ড্র হয়েছে') : (w == 'X' ? tr('You win!', 'আপনি জিতেছেন!') : tr('AI wins', 'কম্পিউটার জিতেছে')), () => setState(() => b.fillRange(0, 9, '')));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Tic Tac Toe', 'টিক ট্যাক টো'),
        board(3, 9,
            (i) => tile(b[i] == 'X' ? Colors.blue.shade700 : (b[i] == 'O' ? Colors.red.shade700 : Colors.grey.shade800), text: b[i], onTap: () => tap(i))),
        tr('You are X', 'আপনি X'),
      );
}

class GuessNumber extends StatefulWidget {
  const GuessNumber({super.key});
  @override
  State<GuessNumber> createState() => _GuessNumberState();
}

class _GuessNumberState extends State<GuessNumber> {
  final ctrl = TextEditingController();
  int target = _r.nextInt(100) + 1, tries = 0;
  String hint = tr('Guess a number 1–100', '1–100 এর মধ্যে একটি সংখ্যা অনুমান করুন');

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void guess() {
    final g = int.tryParse(ctrl.text.trim());
    ctrl.clear();
    if (g == null) return;
    tries++;
    if (g == target) {
      showResult(
          context,
          score: tries,
          lower: true,
          unit: ' tries',
          tr('Got it in $tries tries', '$tries চেষ্টায় পেরেছেন'),
          () => setState(() {
                target = _r.nextInt(100) + 1;
                tries = 0;
                hint = tr('Guess a number 1–100', '1–100 এর মধ্যে একটি সংখ্যা অনুমান করুন');
              }));
    } else {
      setState(() => hint = g < target ? tr('$g is too low ↑', '$g খুব ছোট ↑') : tr('$g is too high ↓', '$g খুব বড় ↓'));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Guess the Number', 'সংখ্যা অনুমান'),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(hint, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32),
                onSubmitted: (_) => guess(),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: guess, child: Text(tr('Guess', 'অনুমান'))),
            ]),
          ),
        ),
        tr('Tries $tries', 'চেষ্টা $tries'),
      );
}
