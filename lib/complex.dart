import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'games.dart';

final _r = Random();

final complexGames = <Game>[
  Game('2048', 'Puzzle', () => const Game2048(), bn: '2048'),
  for (final (label, bn, givens) in [('Easy', 'সহজ', 40), ('Hard', 'কঠিন', 28)]) Game('Sudoku $label', 'Logic', () => Sudoku(givens), bn: 'সুডোকু $bn'),
  for (final (n, mines) in [(9, 10), (12, 24)]) Game('Minesweeper $n×$n', 'Logic', () => Minesweeper(n, mines), bn: 'মাইনসুইপার $n×$n'),
  Game('Mastermind', 'Logic', () => const Mastermind(), bn: 'মাস্টারমাইন্ড'),
  for (final n in [3, 4, 5]) Game('Hanoi Tower $n Disks', 'Puzzle', () => Hanoi(n), bn: 'হ্যানয় টাওয়ার $n চাকতি'),
  Game('Connect Four', 'Puzzle', () => const ConnectFour(), bn: 'কানেক্ট ফোর'),
];

/// 8-way neighbours of cell [i] on a [cols]-wide grid of [count] cells.
List<int> around(int i, int cols, int count) => [
      for (var dr = -1; dr <= 1; dr++)
        for (var dc = -1; dc <= 1; dc++)
          if ((dr != 0 || dc != 0) && i % cols + dc >= 0 && i % cols + dc < cols && i + dr * cols + dc >= 0 && i + dr * cols + dc < count) i + dr * cols + dc,
    ];

// ---------- 2048 ----------

/// Slides one line towards index 0, merging equal pairs once. Returns the new line and points gained.
(List<int>, int) slideLine(List<int> line) {
  final t = line.where((x) => x > 0).toList(), out = <int>[];
  var gained = 0;
  for (var i = 0; i < t.length; i++) {
    if (i + 1 < t.length && t[i] == t[i + 1]) {
      out.add(t[i] * 2);
      gained += t[i] * 2;
      i++;
    } else {
      out.add(t[i]);
    }
  }
  return ([...out, ...List.filled(line.length - out.length, 0)], gained);
}

final arrowKeys = {LogicalKeyboardKey.arrowLeft: 0, LogicalKeyboardKey.arrowRight: 1, LogicalKeyboardKey.arrowUp: 2, LogicalKeyboardKey.arrowDown: 3};

class Game2048 extends StatefulWidget {
  const Game2048({super.key});
  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  late List<int> cells;
  int score = 0;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    cells = List.filled(16, 0);
    score = 0;
    spawn();
    spawn();
  }

  void spawn() {
    final free = [for (var i = 0; i < 16; i++) if (cells[i] == 0) i];
    if (free.isNotEmpty) cells[free[_r.nextInt(free.length)]] = _r.nextInt(10) == 0 ? 4 : 2;
  }

  bool canMove() => cells.contains(0) || [for (var i = 0; i < 16; i++) i].any((i) => (i % 4 < 3 && cells[i] == cells[i + 1]) || (i < 12 && cells[i] == cells[i + 4]));

  /// dir: 0 left, 1 right, 2 up, 3 down.
  void move(int dir) {
    var changed = false, gained = 0;
    for (var a = 0; a < 4; a++) {
      final idx = [
        for (var b = 0; b < 4; b++)
          switch (dir) { 0 => a * 4 + b, 1 => a * 4 + 3 - b, 2 => b * 4 + a, _ => (3 - b) * 4 + a },
      ];
      final (out, g) = slideLine([for (final i in idx) cells[i]]);
      gained += g;
      for (var k = 0; k < 4; k++) {
        changed |= cells[idx[k]] != out[k];
        cells[idx[k]] = out[k];
      }
    }
    if (!changed) return;
    sfx(gained > 0 ? 'right' : 'tap');
    setState(() {
      score += gained;
      spawn();
    });
    if (!canMove()) showResult(context, won: false, score: score, tr('No moves left!\nScore: $score', 'আর কোনো চাল নেই!\nস্কোর: $score'), () => setState(start));
  }

  @override
  Widget build(BuildContext context) => page(
        '2048',
        Focus(
          autofocus: true,
          onKeyEvent: (_, e) {
            if (e is! KeyDownEvent || !arrowKeys.containsKey(e.logicalKey)) return KeyEventResult.ignored;
            move(arrowKeys[e.logicalKey]!);
            return KeyEventResult.handled;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanEnd: (d) {
              final v = d.velocity.pixelsPerSecond;
              if (v.distance < 100) return;
              move(v.dx.abs() > v.dy.abs() ? (v.dx > 0 ? 1 : 0) : (v.dy > 0 ? 3 : 2));
            },
            child: board(4, 16, (i) {
              final v = cells[i];
              final hue = v == 0 ? 0.0 : (log(v) / ln2 * 32) % 360;
              return tile(v == 0 ? Colors.grey.shade800 : HSLColor.fromAHSL(1, hue, .6, .45).toColor(), text: v == 0 ? '' : '$v');
            }),
          ),
        ),
        tr('Score $score', 'স্কোর $score'),
      );
}

// ---------- Sudoku ----------

/// Whether [v] can go in cell [i] (ignoring the cell's own value).
bool sudokuOk(List<int> g, int i, int v) {
  final r = i ~/ 9, c = i % 9, br = r ~/ 3 * 3, bc = c ~/ 3 * 3;
  for (var k = 0; k < 9; k++) {
    for (final j in [r * 9 + k, k * 9 + c, (br + k ~/ 3) * 9 + bc + k % 3]) {
      if (j != i && g[j] == v) return false;
    }
  }
  return true;
}

/// Fills every 0 in [g] by randomized backtracking. Returns false if impossible.
bool sudokuFill(List<int> g, Random r) {
  final i = g.indexOf(0);
  if (i < 0) return true;
  for (final v in List.generate(9, (k) => k + 1)..shuffle(r)) {
    if (!sudokuOk(g, i, v)) continue;
    g[i] = v;
    if (sudokuFill(g, r)) return true;
  }
  g[i] = 0;
  return false;
}

/// ponytail: puzzles aren't checked for a unique solution; any grid that obeys the rules is accepted as solved.
List<int> sudokuPuzzle(int givens, Random r) {
  final g = List.filled(81, 0);
  sudokuFill(g, r);
  for (final i in (List.generate(81, (i) => i)..shuffle(r)).take(81 - givens)) {
    g[i] = 0;
  }
  return g;
}

class Sudoku extends StatefulWidget {
  const Sudoku(this.givens, {super.key});
  final int givens;
  @override
  State<Sudoku> createState() => _SudokuState();
}

class _SudokuState extends State<Sudoku> {
  final sw = Stopwatch();
  late List<int> g;
  late List<bool> fixed;
  int? sel;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    g = sudokuPuzzle(widget.givens, _r);
    fixed = [for (final v in g) v != 0];
    sel = null;
    sw
      ..reset()
      ..start();
  }

  bool bad(int i) => g[i] != 0 && !sudokuOk(g, i, g[i]);

  void input(int v) {
    final s = sel;
    if (s == null || fixed[s]) return;
    setState(() => g[s] = v);
    if (v != 0 && bad(s)) sfx('wrong');
    if (!g.contains(0) && !List.generate(81, bad).contains(true)) {
      sw.stop();
      final secs = sw.elapsed.inSeconds;
      showResult(context, score: secs, lower: true, unit: ' s', tr('Solved in ${secs ~/ 60}m ${secs % 60}s', '${secs ~/ 60} মি ${secs % 60} সে-এ সমাধান'), () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Sudoku', 'সুডোকু'),
        Column(children: [
          Expanded(
            child: board(9, 81, gap: 2, (i) {
              final r = i ~/ 9, c = i % 9, box = (r ~/ 3 + c ~/ 3).isEven;
              final same = sel != null && g[sel!] != 0 && g[i] == g[sel!];
              return Material(
                color: i == sel ? Colors.deepPurple : (same ? Colors.deepPurple.shade800 : (box ? Colors.blueGrey.shade900 : Colors.blueGrey.shade600)),
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => setState(() => sel = i),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        g[i] == 0 ? '' : '${g[i]}',
                        style: TextStyle(fontSize: 22, fontWeight: fixed[i] ? FontWeight.w900 : FontWeight.w400, color: bad(i) ? Colors.redAccent : (fixed[i] ? Colors.white : Colors.lightBlueAccent)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
              for (var v = 1; v <= 9; v++) SizedBox(width: 48, height: 48, child: FilledButton.tonal(style: FilledButton.styleFrom(padding: EdgeInsets.zero), onPressed: () => input(v), child: Text('$v', style: const TextStyle(fontSize: 20)))),
              SizedBox(width: 48, height: 48, child: IconButton.filledTonal(onPressed: () => input(0), icon: const Icon(Icons.backspace_outlined))),
            ]),
          ),
        ]),
        tr('${g.where((v) => v == 0).length} left', '${g.where((v) => v == 0).length}টি বাকি'),
      );
}

// ---------- Minesweeper ----------

class Minesweeper extends StatefulWidget {
  const Minesweeper(this.n, this.mines, {super.key});
  final int n, mines;
  @override
  State<Minesweeper> createState() => _MinesweeperState();
}

class _MinesweeperState extends State<Minesweeper> {
  final sw = Stopwatch();
  late List<bool> mine, open, flag;
  bool started = false, over = false, flagMode = false;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    mine = List.filled(n * n, false);
    open = List.filled(n * n, false);
    flag = List.filled(n * n, false);
    started = over = false;
    sw.reset();
  }

  int count(int i) => around(i, n, n * n).where((j) => mine[j]).length;

  void toggleFlag(int i) {
    if (over || open[i]) return;
    sfx('tap');
    setState(() => flag[i] = !flag[i]);
  }

  void tap(int i) {
    if (flagMode) return toggleFlag(i);
    if (over || flag[i] || open[i]) return;
    if (!started) {
      // First tap is always safe: keep mines off it and its neighbours.
      final safe = {i, ...around(i, n, n * n)};
      for (final j in ([for (var j = 0; j < n * n; j++) if (!safe.contains(j)) j]..shuffle(_r)).take(widget.mines)) {
        mine[j] = true;
      }
      started = true;
      sw.start();
    }
    if (mine[i]) {
      sw.stop();
      setState(() {
        over = true;
        for (var j = 0; j < n * n; j++) {
          if (mine[j]) open[j] = true;
        }
      });
      showResult(context, won: false, tr('Boom! 💥', 'বুম! 💥'), () => setState(start));
      return;
    }
    sfx('tap');
    setState(() {
      final stack = [i];
      while (stack.isNotEmpty) {
        final j = stack.removeLast();
        if (open[j] || flag[j]) continue;
        open[j] = true;
        if (count(j) == 0) stack.addAll(around(j, n, n * n));
      }
    });
    if (open.where((o) => o).length == n * n - widget.mines) {
      sw.stop();
      over = true;
      final secs = sw.elapsed.inSeconds;
      showResult(context, score: secs, lower: true, unit: ' s', tr('Cleared in $secs s', '$secs সে-এ পরিষ্কার'), () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Minesweeper', 'মাইনসুইপার'),
        Column(children: [
          Expanded(
            child: board(n, n * n, gap: 3, (i) {
              final c = count(i);
              final text = open[i] ? (mine[i] ? '💣' : (c > 0 ? '$c' : '')) : (flag[i] ? '🚩' : '');
              return Material(
                color: open[i] ? (mine[i] ? Colors.red.shade900 : Colors.grey.shade800) : Colors.blueGrey.shade500,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => tap(i),
                  onLongPress: () => toggleFlag(i),
                  child: Center(
                    child: FittedBox(
                      child: Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: [Colors.white, Colors.lightBlueAccent, Colors.lightGreenAccent, Colors.redAccent, Colors.purpleAccent][min(c, 4)])),
                    ),
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FilterChip(label: Text(tr('🚩 Flag mode (or long-press)', '🚩 পতাকা মোড (বা লম্বা চাপ)')), selected: flagMode, onSelected: (v) => setState(() => flagMode = v)),
          ),
        ]),
        '💣 ${widget.mines - flag.where((f) => f).length}',
      );
}

// ---------- Mastermind ----------

/// (right colour & place, right colour wrong place).
(int, int) mastermindScore(List<int> code, List<int> guess) {
  var black = 0, white = 0;
  final cc = List.filled(6, 0), gc = List.filled(6, 0);
  for (var i = 0; i < code.length; i++) {
    if (code[i] == guess[i]) {
      black++;
    } else {
      cc[code[i]]++;
      gc[guess[i]]++;
    }
  }
  for (var k = 0; k < 6; k++) {
    white += min(cc[k], gc[k]);
  }
  return (black, white);
}

class Mastermind extends StatefulWidget {
  const Mastermind({super.key});
  @override
  State<Mastermind> createState() => _MastermindState();
}

class _MastermindState extends State<Mastermind> {
  static const colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
  static const maxGuesses = 10;
  late List<int> code;
  final guesses = <(List<int>, (int, int))>[];
  final cur = <int>[];

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    code = List.generate(4, (_) => _r.nextInt(6));
    guesses.clear();
    cur.clear();
  }

  void check() {
    if (cur.length < 4) return;
    final fb = mastermindScore(code, cur);
    setState(() {
      guesses.add((cur.toList(), fb));
      cur.clear();
    });
    if (fb.$1 == 4) {
      showResult(context, score: guesses.length, lower: true, unit: ' guesses', tr('Cracked in ${guesses.length} guesses!', '${guesses.length} বারে কোড ভাঙা হয়েছে!'), () => setState(start));
    } else if (guesses.length == maxGuesses) {
      showResult(context, won: false, tr('Out of guesses.\nThe code was:\n', 'চেষ্টা শেষ।\nকোডটি ছিল:\n') + code.map((c) => ['🔴', '🔵', '🟢', '🟡', '🟣', '🟠'][c]).join(), () => setState(start));
    } else {
      sfx(fb.$1 + fb.$2 > 0 ? 'right' : 'wrong');
    }
  }

  Widget peg(int? c, {double size = 30}) => Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, color: c == null ? Colors.white10 : colors[c], border: Border.all(color: Colors.white24)),
      );

  @override
  Widget build(BuildContext context) => page(
        tr('Mastermind', 'মাস্টারমাইন্ড'),
        Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(tr('● right color & place   ○ right color, wrong place', '● রং ও জায়গা ঠিক   ○ রং ঠিক, জায়গা ভুল'), style: const TextStyle(color: Colors.white70))),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
              for (final (g, (b, w)) in guesses)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final c in g) peg(c),
                  const SizedBox(width: 16),
                  SizedBox(width: 80, child: Text('${'●' * b}${'○' * w}', style: const TextStyle(fontSize: 18))),
                ]),
            ]),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var k = 0; k < 4; k++) peg(k < cur.length ? cur[k] : null, size: 40)]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(alignment: WrapAlignment.center, children: [
              for (var c = 0; c < 6; c++)
                GestureDetector(
                  onTap: () {
                    if (cur.length == 4) return;
                    sfx('tap');
                    setState(() => cur.add(c));
                  },
                  child: peg(c, size: 44),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton.icon(onPressed: cur.isEmpty ? null : () => setState(cur.removeLast), icon: const Icon(Icons.undo), label: Text(tr('Undo', 'ফেরত'))),
              const SizedBox(width: 12),
              FilledButton.icon(onPressed: cur.length == 4 ? check : null, icon: const Icon(Icons.check), label: Text(tr('Check', 'যাচাই'))),
            ]),
          ),
        ]),
        '${guesses.length}/$maxGuesses',
      );
}

// ---------- Tower of Hanoi ----------

class Hanoi extends StatefulWidget {
  const Hanoi(this.n, {super.key});
  final int n;
  @override
  State<Hanoi> createState() => _HanoiState();
}

class _HanoiState extends State<Hanoi> {
  late List<List<int>> pegs; // disk sizes, top = last
  int? sel;
  int moves = 0;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    pegs = [List.generate(n, (i) => n - i), [], []];
    sel = null;
    moves = 0;
  }

  void tap(int p) {
    final s = sel;
    if (s == null) {
      if (pegs[p].isNotEmpty) setState(() => sel = p);
      return;
    }
    if (p != s && (pegs[p].isEmpty || pegs[p].last > pegs[s].last)) {
      sfx('tap');
      setState(() {
        pegs[p].add(pegs[s].removeLast());
        moves++;
      });
    } else if (p != s) {
      sfx('wrong');
    }
    setState(() => sel = null);
    if (pegs[2].length == n) {
      showResult(context, score: moves, lower: true, unit: ' moves', tr('Done in $moves moves\n(best possible: ${(1 << n) - 1})', '$moves চালে শেষ\n(সেরা সম্ভব: ${(1 << n) - 1})'), () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Tower of Hanoi', 'হ্যানয় টাওয়ার'),
        Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(tr('Move every disk to the right peg.\nNever put a bigger disk on a smaller one.', 'সব চাকতি ডান দিকের খুঁটিতে নিন।\nছোট চাকতির ওপর কখনো বড়টা রাখবেন না।'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(
            child: Row(children: [
              for (var p = 0; p < 3; p++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tap(p),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: sel == p ? Colors.white12 : null, borderRadius: BorderRadius.circular(12)),
                      child: Stack(alignment: Alignment.bottomCenter, children: [
                        Container(width: 8, margin: const EdgeInsets.only(top: 60), color: Colors.brown.shade300),
                        Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          for (final d in pegs[p].reversed)
                            FractionallySizedBox(
                              widthFactor: .3 + .65 * d / n,
                              child: Container(
                                height: 24,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(color: HSLColor.fromAHSL(1, d * 50.0 % 360, .65, .5).toColor(), borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          Container(height: 8, color: Colors.brown.shade400),
                        ]),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
        tr('Moves $moves', 'চাল $moves'),
      );
}

// ---------- Connect Four ----------

class ConnectFour extends StatefulWidget {
  const ConnectFour({super.key});
  @override
  State<ConnectFour> createState() => _ConnectFourState();
}

/// Whether the disc at [i] (7×6 board, row 0 on top) completes four in a row.
bool connectFourWin(List<int> cells, int i) {
  final who = cells[i], r0 = i ~/ 7, c0 = i % 7;
  int run(int dr, int dc) {
    var k = 0, r = r0 + dr, c = c0 + dc;
    while (r >= 0 && r < 6 && c >= 0 && c < 7 && cells[r * 7 + c] == who) {
      k++;
      r += dr;
      c += dc;
    }
    return k;
  }

  return [(0, 1), (1, 0), (1, 1), (1, -1)].any((d) => 1 + run(d.$1, d.$2) + run(-d.$1, -d.$2) >= 4);
}

class _ConnectFourState extends State<ConnectFour> {
  static const you = 1, ai = 2;
  final cells = List.filled(42, 0);
  bool busy = false, over = false;

  /// Drops [who] into column [c]; returns the cell index.
  int drop(int c, int who) {
    for (var r = 5; r >= 0; r--) {
      final i = r * 7 + c;
      if (cells[i] == 0) {
        cells[i] = who;
        return i;
      }
    }
    return -1;
  }

  // ponytail: rule-based AI (win > block > don't set up the opponent > centre); swap for minimax if it's too easy.
  int aiColumn() {
    final cols = [for (var c = 0; c < 7; c++) if (cells[c] == 0) c];
    for (final who in [ai, you]) {
      for (final c in cols) {
        final i = drop(c, who), w = connectFourWin(cells, i);
        cells[i] = 0;
        if (w) return c;
      }
    }
    final safe = cols.where((c) {
      final i = drop(c, ai);
      var bad = false;
      if (i >= 7) {
        cells[i - 7] = you;
        bad = connectFourWin(cells, i - 7);
        cells[i - 7] = 0;
      }
      cells[i] = 0;
      return !bad;
    }).toList();
    final pool = (safe.isEmpty ? cols : safe)..sort((a, b) => (a - 3).abs() - (b - 3).abs());
    return _r.nextInt(3) == 0 ? pool[_r.nextInt(pool.length)] : pool.first;
  }

  bool finish(int i, String msg, {required bool won}) {
    if (connectFourWin(cells, i)) {
      over = true;
      showResult(context, won: won, msg, () => setState(restart));
      return true;
    }
    if (!cells.contains(0)) {
      over = true;
      showResult(context, won: false, tr("It's a draw", 'ড্র হয়েছে'), () => setState(restart));
      return true;
    }
    return false;
  }

  void restart() {
    cells.fillRange(0, 42, 0);
    over = busy = false;
  }

  Future<void> tap(int c) async {
    if (busy || over || cells[c] != 0) return;
    sfx('tap');
    late int i;
    setState(() => i = drop(c, you));
    if (finish(i, tr('You win! 🎉', 'আপনি জিতেছেন! 🎉'), won: true)) return;
    setState(() => busy = true);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      i = drop(aiColumn(), ai);
      busy = false;
    });
    finish(i, tr('AI wins', 'কম্পিউটার জিতেছে'), won: false);
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Connect Four', 'কানেক্ট ফোর'),
        board(7, 42, gap: 6, (i) {
          final v = cells[i];
          return GestureDetector(
            onTap: () => tap(i % 7),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: v == you ? Colors.amber : (v == ai ? Colors.redAccent : Colors.indigo.shade900),
              ),
            ),
          );
        }),
        busy ? tr('AI thinking…', 'কম্পিউটার ভাবছে…') : tr('You are 🟡', 'আপনি 🟡'),
      );
}
