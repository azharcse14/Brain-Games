import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'complex.dart' show arrowKeys, slideLine;
import 'games.dart';

final _r = Random();

final puzzleGames2 = <Game>[
  for (final n in [5, 7, 10]) Game('Nonogram $n×$n', 'Logic', () => Nonogram(n), glyph: '🖼️$n', bn: 'ননোগ্রাম $n×$n'),
  for (final (n, k) in [(8, 6), (10, 8), (12, 10)]) Game('Word Search $n×$n', 'Word', () => WordSearch(n, k), glyph: '🔎$n', bn: 'শব্দ খোঁজা $n×$n'),
  for (final (n, c) in [(10, 6), (14, 6), (18, 7)]) Game('Flood It $n×$n', 'Puzzle', () => FloodIt(n, c), glyph: '🌊$n', bn: 'রঙের বন্যা $n×$n'),
  for (final (label, bn, w, h) in [('Small', 'ছোট', 8, 12), ('Medium', 'মাঝারি', 12, 18), ('Large', 'বড়', 16, 24)]) Game('Maze $label', 'Puzzle', () => Maze(w, h), glyph: '🌀${label[0]}', bn: 'গোলকধাঁধা $bn'),
  Game('Peg Solitaire', 'Puzzle', () => const PegSolitaire(false), glyph: '⚫✚', bn: 'পেগ সলিটেয়ার'),
  Game('Peg Triangle', 'Puzzle', () => const PegSolitaire(true), glyph: '⚫△', bn: 'পেগ ত্রিভুজ'),
  for (final c in [4, 6, 8]) Game('Water Sort $c Colors', 'Puzzle', () => WaterSort(c), glyph: '🧪$c', bn: 'পানি সাজানো $c রঙ'),
  for (final n in [5, 6]) Game("Knight's Tour $n×$n", 'Puzzle', () => KnightsTour(n), glyph: '♘$n', bn: 'ঘোড়ার ভ্রমণ $n×$n'),
  for (final n in [3, 5, 6]) Game('2048 $n×$n', 'Puzzle', () => Game2048N(n), glyph: '2048·$n', bn: '2048 $n×$n'),
  Game('Skyscrapers 4×4', 'Logic', () => const Skyscrapers(4), glyph: '🏙️', bn: 'আকাশচুম্বী 4×4'),
];

const puzzlePalette = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.pink, Colors.cyan];

void _won(BuildContext context, Stopwatch sw, VoidCallback again) {
  sw.stop();
  final s = sw.elapsed.inSeconds;
  showResult(context, score: s, lower: true, unit: ' s', tr('Solved in ${s ~/ 60}m ${s % 60}s', '${s ~/ 60} মি. ${s % 60} সে.-এ সমাধান'), again);
}

// ---------- Nonogram ----------

List<int> nonoRuns(List<bool> line) {
  final out = <int>[];
  var k = 0;
  for (final v in line) {
    if (v) {
      k++;
    } else if (k > 0) {
      out.add(k);
      k = 0;
    }
  }
  if (k > 0) out.add(k);
  return out;
}

List<List<int>> nonoClues(List<bool> g, int n, {required bool rows}) => [
      for (var a = 0; a < n; a++) nonoRuns([for (var b = 0; b < n; b++) g[rows ? a * n + b : b * n + a]]),
    ];

String _key(List<List<int>> c) => c.map((x) => x.join(',')).join('|');

/// Any grid that matches every row and column clue counts as solved.
bool nonoSolved(List<bool> target, List<bool> grid, int n) =>
    _key(nonoClues(target, n, rows: true)) == _key(nonoClues(grid, n, rows: true)) &&
    _key(nonoClues(target, n, rows: false)) == _key(nonoClues(grid, n, rows: false));

class Nonogram extends StatefulWidget {
  const Nonogram(this.n, {super.key});
  final int n;
  @override
  State<Nonogram> createState() => _NonogramState();
}

class _NonogramState extends State<Nonogram> {
  final sw = Stopwatch();
  late List<bool> target, filled, marked;
  bool xMode = false;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    do {
      target = List.generate(n * n, (_) => _r.nextDouble() < .58);
    } while (!target.contains(true));
    filled = List.filled(n * n, false);
    marked = List.filled(n * n, false);
    sw
      ..reset()
      ..start();
  }

  void tap(int i, {bool mark = false}) {
    if (mark || xMode) {
      if (!filled[i]) setState(() => marked[i] = !marked[i]);
      return;
    }
    sfx('tap');
    setState(() {
      filled[i] = !filled[i];
      marked[i] = false;
    });
    if (nonoSolved(target, filled, n)) _won(context, sw, () => setState(start));
  }

  @override
  Widget build(BuildContext context) {
    final rc = nonoClues(target, n, rows: true), cc = nonoClues(target, n, rows: false);
    final cw = n >= 10 ? 70.0 : 56.0, ch = 14.0 * ((n + 1) ~/ 2) + 6;
    final fs = TextStyle(fontSize: 12, color: dim);
    return page(
      tr('Nonogram', 'ননোগ্রাম'),
      Column(children: [
        Expanded(
          child: LayoutBuilder(builder: (_, box) {
            final cell = max(8.0, min((box.maxWidth - 16 - cw) / n, (box.maxHeight - 16 - ch) / n));
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: cw, height: ch),
                  for (final c in cc)
                    SizedBox(
                      width: cell,
                      height: ch,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomCenter,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [for (final v in c.isEmpty ? [0] : c) Text('$v', style: fs)]),
                      ),
                    ),
                ]),
                for (var r = 0; r < n; r++)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: cw,
                      height: cell,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FittedBox(fit: BoxFit.scaleDown, child: Text((rc[r].isEmpty ? [0] : rc[r]).join(' '), style: fs)),
                        ),
                      ),
                    ),
                    for (var c = 0; c < n; c++)
                      GestureDetector(
                        onTap: () => tap(r * n + c),
                        onLongPress: () => tap(r * n + c, mark: true),
                        child: Container(
                          width: cell,
                          height: cell,
                          decoration: BoxDecoration(color: filled[r * n + c] ? Colors.white : Colors.blueGrey.shade800, border: Border.all(color: Colors.black45, width: .5)),
                          child: marked[r * n + c] ? Icon(Icons.close, size: cell * .7, color: Colors.redAccent) : null,
                        ),
                      ),
                  ]),
              ]),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FilterChip(label: Text(tr('✕ Mark mode (or long-press)', '✕ চিহ্ন মোড (বা লম্বা চাপ)')), selected: xMode, onSelected: (v) => setState(() => xMode = v)),
        ),
      ]),
      '$n×$n',
    );
  }
}

// ---------- Word Search ----------

const wsWords = [
  'APPLE', 'TIGER', 'RIVER', 'CLOUD', 'PLANET', 'ROCKET', 'GARDEN', 'PUZZLE', 'BRAIN', 'OCEAN', 'FOREST', 'CASTLE', 'DRAGON', //
  'PENCIL', 'SUMMER', 'WINTER', 'BRIDGE', 'ISLAND', 'JUNGLE', 'MARKET', 'SILVER', 'ORANGE', 'LEMON', 'MANGO', 'ZEBRA', 'EAGLE',
  'SHARK', 'HORSE', 'PIANO', 'GUITAR', 'VIOLIN', 'TRAIN', 'PLANE', 'CAMEL', 'MONKEY', 'RABBIT', 'KITTEN', 'FLOWER', 'WINDOW',
  'CANDLE', 'STAR', 'MOON', 'RAIN', 'SNOW', 'FIRE', 'TREE', 'LEAF', 'BOOK', 'KITE', 'LAMP',
];
const wsDirs = [(0, 1), (1, 0), (1, 1), (1, -1), (0, -1), (-1, 0), (-1, -1), (-1, 1)];

/// Hides up to [k] words on an [n]×[n] grid in any of 8 directions. Returns the letters and each word's cells.
(List<String>, Map<String, List<int>>) wsMake(int n, int k, Random r) {
  final g = List.filled(n * n, ''), placed = <String, List<int>>{};
  for (final w in wsWords.where((w) => w.length <= n).toList()..shuffle(r)) {
    if (placed.length == k) break;
    for (var tries = 0; tries < 100; tries++) {
      final d = wsDirs[r.nextInt(8)], r0 = r.nextInt(n), c0 = r.nextInt(n);
      final er = r0 + d.$1 * (w.length - 1), ec = c0 + d.$2 * (w.length - 1);
      if (er < 0 || er >= n || ec < 0 || ec >= n) continue;
      final idx = [for (var i = 0; i < w.length; i++) (r0 + d.$1 * i) * n + c0 + d.$2 * i];
      if (!List.generate(w.length, (i) => g[idx[i]] == '' || g[idx[i]] == w[i]).every((ok) => ok)) continue;
      for (var i = 0; i < w.length; i++) {
        g[idx[i]] = w[i];
      }
      placed[w] = idx;
      break;
    }
  }
  for (var i = 0; i < n * n; i++) {
    if (g[i] == '') g[i] = String.fromCharCode(65 + r.nextInt(26));
  }
  return (g, placed);
}

class WordSearch extends StatefulWidget {
  const WordSearch(this.n, this.k, {super.key});
  final int n, k;
  @override
  State<WordSearch> createState() => _WordSearchState();
}

class _WordSearchState extends State<WordSearch> {
  final sw = Stopwatch();
  late List<String> g;
  late Map<String, List<int>> words;
  final found = <String>{}, foundCells = <int>{};
  int? first;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    final made = wsMake(n, widget.k, _r);
    g = made.$1;
    words = made.$2;
    found.clear();
    foundCells.clear();
    first = null;
    sw
      ..reset()
      ..start();
  }

  void tap(int i) {
    final f = first;
    if (f == null || f == i) {
      setState(() => first = f == i ? null : i);
      return;
    }
    setState(() => first = null);
    final r1 = f ~/ n, c1 = f % n, r2 = i ~/ n, c2 = i % n;
    if (!(r1 == r2 || c1 == c2 || (r2 - r1).abs() == (c2 - c1).abs())) return sfx('wrong');
    final len = max((r2 - r1).abs(), (c2 - c1).abs()) + 1, dr = (r2 - r1).sign, dc = (c2 - c1).sign;
    final cells = [for (var k = 0; k < len; k++) (r1 + dr * k) * n + c1 + dc * k];
    final s = cells.map((j) => g[j]).join(), rev = s.split('').reversed.join();
    final w = words.keys.where((w) => !found.contains(w) && (w == s || w == rev)).firstOrNull;
    if (w == null) return sfx('wrong');
    sfx('right');
    setState(() {
      found.add(w);
      foundCells.addAll(cells);
    });
    if (found.length == words.length) _won(context, sw, () => setState(start));
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Word Search', 'শব্দ খোঁজা'),
        Column(children: [
          Expanded(
            child: board(n, n * n, gap: 2, (i) {
              final color = i == first ? Colors.amber.shade700 : (foundCells.contains(i) ? Colors.green.shade700 : Colors.blueGrey.shade800);
              return tile(color, text: g[i], onTap: () => tap(i));
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Wrap(spacing: 12, runSpacing: 6, alignment: WrapAlignment.center, children: [
              for (final w in words.keys)
                Text(
                  w,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: found.contains(w) ? (dark ? Colors.greenAccent : Colors.green.shade700) : ink,
                    decoration: found.contains(w) ? TextDecoration.lineThrough : null,
                  ),
                ),
            ]),
          ),
        ]),
        '${found.length}/${words.length}',
      );
}

// ---------- Flood It ----------

/// Cells connected to the top-left cell by its colour.
Set<int> floodRegion(List<int> g, int n) {
  final seen = {0}, stack = [0];
  while (stack.isNotEmpty) {
    for (final j in adj(stack.removeLast(), n)) {
      if (g[j] == g[0] && seen.add(j)) stack.add(j);
    }
  }
  return seen;
}

void floodFill(List<int> g, int n, int color) {
  for (final i in floodRegion(g, n)) {
    g[i] = color;
  }
}

/// Moves a greedy player needs (always pick the colour that grows the region most).
// ponytail: the move limit is the greedy solution, so it's always achievable; an exact solver would make it tighter.
int floodGreedy(List<int> start, int n, int colors) {
  final g = start.toList();
  var moves = 0;
  while (floodRegion(g, n).length < n * n) {
    var best = -1, bestSize = -1;
    for (var c = 0; c < colors; c++) {
      if (c == g[0]) continue;
      final t = g.toList();
      floodFill(t, n, c);
      final s = floodRegion(t, n).length;
      if (s > bestSize) (best, bestSize) = (c, s);
    }
    floodFill(g, n, best);
    moves++;
  }
  return moves;
}

class FloodIt extends StatefulWidget {
  const FloodIt(this.n, this.colors, {super.key});
  final int n, colors;
  @override
  State<FloodIt> createState() => _FloodItState();
}

class _FloodItState extends State<FloodIt> {
  late List<int> g;
  late int limit;
  int moves = 0;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    g = List.generate(n * n, (_) => _r.nextInt(widget.colors));
    limit = floodGreedy(g, n, widget.colors);
    moves = 0;
  }

  void pick(int c) {
    if (c == g[0] || moves >= limit) return;
    sfx('tap');
    setState(() {
      floodFill(g, n, c);
      moves++;
    });
    if (floodRegion(g, n).length == n * n) {
      showResult(context, score: moves, lower: true, unit: ' moves', tr('Flooded in $moves moves!', '$moves চালে পুরো বোর্ড ভরেছে!'), () => setState(start));
    } else if (moves >= limit) {
      showResult(context, won: false, tr('Out of moves!', 'চাল শেষ!'), () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Flood It', 'রঙের বন্যা'),
        Column(children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(tr('Fill the board with one colour, starting top-left.', 'উপরের বাম কোণ থেকে শুরু করে পুরো বোর্ড এক রঙে ভরুন।'), style: TextStyle(color: dim))),
          Expanded(child: board(n, n * n, gap: 0, (i) => Container(color: puzzlePalette[g[i]]))),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              for (var c = 0; c < widget.colors; c++)
                GestureDetector(
                  onTap: () => pick(c),
                  child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: puzzlePalette[c], border: Border.all(color: Colors.white, width: 2))),
                ),
            ]),
          ),
        ]),
        tr('Moves $moves/$limit', 'চাল $moves/$limit'),
      );
}

// ---------- Maze ----------

/// (wall bit, dx, dy, opposite bit): 1 = north, 2 = east, 4 = south, 8 = west.
const mazeDirs = [(1, 0, -1, 4), (2, 1, 0, 8), (4, 0, 1, 1), (8, -1, 0, 2)];

/// Perfect maze via recursive backtracking; each cell holds a bitmask of its open sides.
List<int> mazeMake(int w, int h, Random r) {
  final open = List.filled(w * h, 0), seen = List.filled(w * h, false), stack = [0];
  seen[0] = true;
  while (stack.isNotEmpty) {
    final c = stack.last, x = c % w, y = c ~/ w;
    final opts = [
      for (final (bit, dx, dy, back) in mazeDirs)
        if (x + dx >= 0 && x + dx < w && y + dy >= 0 && y + dy < h && !seen[(y + dy) * w + x + dx]) (bit, (y + dy) * w + x + dx, back),
    ];
    if (opts.isEmpty) {
      stack.removeLast();
      continue;
    }
    final (bit, nb, back) = opts[r.nextInt(opts.length)];
    open[c] |= bit;
    open[nb] |= back;
    seen[nb] = true;
    stack.add(nb);
  }
  return open;
}

class Maze extends StatefulWidget {
  const Maze(this.w, this.h, {super.key});
  final int w, h;
  @override
  State<Maze> createState() => _MazeState();
}

class _MazeState extends State<Maze> {
  final sw = Stopwatch();
  late List<int> open;
  int pos = 0;
  bool done = false;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    open = mazeMake(widget.w, widget.h, _r);
    pos = 0;
    done = false;
    sw
      ..reset()
      ..start();
  }

  void move(int bit) {
    if (done || (open[pos] & bit) == 0) return;
    final d = mazeDirs.firstWhere((m) => m.$1 == bit);
    setState(() => pos += d.$3 * widget.w + d.$2);
    if (pos == widget.w * widget.h - 1) {
      done = true;
      _won(context, sw, () => setState(start));
    }
  }

  Widget arrow(IconData icon, int bit) => IconButton.filledTonal(iconSize: 30, onPressed: () => move(bit), icon: Icon(icon));

  @override
  Widget build(BuildContext context) => page(
        tr('Maze', 'গোলকধাঁধা'),
        Focus(
          autofocus: true,
          onKeyEvent: (_, e) {
            if (e is! KeyDownEvent || !arrowKeys.containsKey(e.logicalKey)) return KeyEventResult.ignored;
            move(const [8, 2, 1, 4][arrowKeys[e.logicalKey]!]);
            return KeyEventResult.handled;
          },
          child: Column(children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanEnd: (d) {
                  final v = d.velocity.pixelsPerSecond;
                  if (v.distance < 100) return;
                  move(v.dx.abs() > v.dy.abs() ? (v.dx > 0 ? 2 : 8) : (v.dy > 0 ? 4 : 1));
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AspectRatio(aspectRatio: widget.w / widget.h, child: CustomPaint(painter: _MazePainter(open, widget.w, widget.h, pos), size: Size.infinite)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                arrow(Icons.keyboard_arrow_up, 1),
                Row(mainAxisSize: MainAxisSize.min, children: [arrow(Icons.keyboard_arrow_left, 8), const SizedBox(width: 56), arrow(Icons.keyboard_arrow_right, 2)]),
                arrow(Icons.keyboard_arrow_down, 4),
              ]),
            ),
          ]),
        ),
        tr('Reach 🟩', '🟩-তে পৌঁছান'),
      );
}

class _MazePainter extends CustomPainter {
  _MazePainter(this.open, this.w, this.h, this.pos);
  final List<int> open;
  final int w, h, pos;

  @override
  void paint(Canvas c, Size s) {
    final cw = s.width / w, chh = s.height / h;
    final wall = Paint()
      ..color = dim
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    c.drawRect(Rect.fromLTWH((w - 1) * cw + cw * .15, (h - 1) * chh + chh * .15, cw * .7, chh * .7), Paint()..color = dark ? Colors.greenAccent : Colors.green.shade600);
    for (var i = 0; i < w * h; i++) {
      final x = i % w, y = i ~/ w, x0 = x * cw, y0 = y * chh;
      if ((open[i] & 1) == 0) c.drawLine(Offset(x0, y0), Offset(x0 + cw, y0), wall);
      if ((open[i] & 8) == 0) c.drawLine(Offset(x0, y0), Offset(x0, y0 + chh), wall);
      if (x == w - 1 && (open[i] & 2) == 0) c.drawLine(Offset(x0 + cw, y0), Offset(x0 + cw, y0 + chh), wall);
      if (y == h - 1 && (open[i] & 4) == 0) c.drawLine(Offset(x0, y0 + chh), Offset(x0 + cw, y0 + chh), wall);
    }
    c.drawCircle(Offset((pos % w + .5) * cw, (pos ~/ w + .5) * chh), min(cw, chh) * .35, Paint()..color = Colors.amber);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------- Peg Solitaire ----------

const pegOrth = [(0, 1), (0, -1), (1, 0), (-1, 0)];
const pegTriDirs = [...pegOrth, (1, 1), (-1, -1)];

/// Jumping the peg at [a] over a neighbour into the empty hole [b].
bool pegJump(Set<(int, int)> holes, Set<(int, int)> pegs, (int, int) a, (int, int) b, List<(int, int)> dirs) {
  final dr = b.$1 - a.$1, dc = b.$2 - a.$2;
  if (!dirs.any((d) => d.$1 * 2 == dr && d.$2 * 2 == dc)) return false;
  return pegs.contains(a) && pegs.contains((a.$1 + dr ~/ 2, a.$2 + dc ~/ 2)) && holes.contains(b) && !pegs.contains(b);
}

bool pegAnyJump(Set<(int, int)> holes, Set<(int, int)> pegs, List<(int, int)> dirs) =>
    pegs.any((a) => dirs.any((d) => pegJump(holes, pegs, a, (a.$1 + 2 * d.$1, a.$2 + 2 * d.$2), dirs)));

class PegSolitaire extends StatefulWidget {
  const PegSolitaire(this.triangle, {super.key});
  final bool triangle;
  @override
  State<PegSolitaire> createState() => _PegSolitaireState();
}

class _PegSolitaireState extends State<PegSolitaire> {
  late Set<(int, int)> holes, pegs;
  (int, int)? sel;
  List<(int, int)> get dirs => widget.triangle ? pegTriDirs : pegOrth;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    holes = widget.triangle
        ? {for (var r = 0; r < 5; r++) for (var c = 0; c <= r; c++) (r, c)}
        : {for (var r = 0; r < 7; r++) for (var c = 0; c < 7; c++) if ((r >= 2 && r <= 4) || (c >= 2 && c <= 4)) (r, c)};
    pegs = holes.difference({widget.triangle ? (0, 0) : (3, 3)});
    sel = null;
  }

  void tap((int, int) p) {
    final s = sel;
    if (s != null && pegJump(holes, pegs, s, p, dirs)) {
      sfx('tap');
      setState(() {
        pegs
          ..remove(s)
          ..remove(((s.$1 + p.$1) ~/ 2, (s.$2 + p.$2) ~/ 2))
          ..add(p);
        sel = null;
      });
      if (!pegAnyJump(holes, pegs, dirs)) {
        final left = pegs.length;
        showResult(context, won: left == 1, score: left, lower: true, unit: ' pegs', left == 1 ? tr('Perfect! One peg left 🎉', 'দারুণ! মাত্র একটা পেগ বাকি 🎉') : tr('No moves left.\n$left pegs remain', 'আর চাল নেই।\n$left টি পেগ বাকি'), () => setState(start));
      }
      return;
    }
    setState(() => sel = pegs.contains(p) && p != s ? p : null);
  }

  Widget hole((int, int) p, double size) => GestureDetector(
        onTap: () => tap(p),
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pegs.contains(p) ? (p == sel ? Colors.white : Colors.amber) : Colors.grey.shade800,
            border: Border.all(color: Colors.black54, width: 2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => page(
        widget.triangle ? tr('Peg Triangle', 'পেগ ত্রিভুজ') : tr('Peg Solitaire', 'পেগ সলিটেয়ার'),
        Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(tr('Jump a peg over another into an empty hole.\nLeave just one peg.', 'একটা পেগ দিয়ে আরেকটা ডিঙিয়ে খালি গর্তে যান।\nশেষে একটাই পেগ রাখুন।'), textAlign: TextAlign.center, style: TextStyle(color: dim))),
          Expanded(
            child: widget.triangle
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      for (var r = 0; r < 5; r++) Row(mainAxisSize: MainAxisSize.min, children: [for (var c = 0; c <= r; c++) hole((r, c), 52)]),
                    ]),
                  )
                : board(7, 49, gap: 2, (i) => holes.contains((i ~/ 7, i % 7)) ? Center(child: FractionallySizedBox(widthFactor: .9, heightFactor: .9, child: hole((i ~/ 7, i % 7), double.infinity))) : const SizedBox()),
          ),
        ]),
        tr('Pegs ${pegs.length}', 'পেগ ${pegs.length}'),
      );
}

// ---------- Water Sort ----------

const tubeCap = 4;

/// Pours the top run of [from] onto [to]; returns how many balls moved (0 = illegal).
int waterPour(List<List<int>> t, int from, int to) {
  if (from == to || t[from].isEmpty || t[to].length == tubeCap) return 0;
  final c = t[from].last;
  if (t[to].isNotEmpty && t[to].last != c) return 0;
  var k = 0;
  while (t[from].isNotEmpty && t[from].last == c && t[to].length < tubeCap) {
    t[to].add(t[from].removeLast());
    k++;
  }
  return k;
}

bool waterSorted(List<List<int>> t) => t.every((x) => x.isEmpty || (x.length == tubeCap && x.every((c) => c == x[0])));

/// Scrambles a solved rack with random *reverse* pours, so it is always solvable.
/// Returns the tubes and the reverse moves (from, to, count); replaying them backwards as pours solves it.
(List<List<int>>, List<(int, int, int)>) waterMake(int colors, Random r, {int steps = 400}) {
  while (true) {
    final t = [
      for (var c = 0; c < colors; c++) [for (var i = 0; i < tubeCap; i++) c],
      <int>[],
      <int>[],
    ];
    final moves = <(int, int, int)>[];
    for (var s = 0; s < steps; s++) {
      final a = r.nextInt(t.length), b = r.nextInt(t.length);
      if (a == b || t[a].isEmpty) continue;
      final c = t[a].last;
      var run = 0;
      while (run < t[a].length && t[a][t[a].length - 1 - run] == c) {
        run++;
      }
      final k = 1 + r.nextInt(run);
      // The forward pour b→a must be legal and move exactly k: a is left empty or still topped by c,
      // and b isn't already topped by c.
      if (k == run && run < t[a].length) continue;
      if (t[b].length + k > tubeCap || (t[b].isNotEmpty && t[b].last == c)) continue;
      for (var i = 0; i < k; i++) {
        t[b].add(t[a].removeLast());
      }
      moves.add((a, b, k));
    }
    if (!waterSorted(t)) return (t, moves);
  }
}

class WaterSort extends StatefulWidget {
  const WaterSort(this.colors, {super.key});
  final int colors;
  @override
  State<WaterSort> createState() => _WaterSortState();
}

class _WaterSortState extends State<WaterSort> {
  late List<List<int>> t;
  final history = <(int, int, int)>[];
  int? sel;
  int moves = 0;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    t = waterMake(widget.colors, _r).$1;
    history.clear();
    sel = null;
    moves = 0;
  }

  void tap(int i) {
    final s = sel;
    if (s == null) {
      if (t[i].isNotEmpty) setState(() => sel = i);
      return;
    }
    final k = waterPour(t, s, i);
    setState(() {
      sel = null;
      if (k > 0) {
        history.add((s, i, k));
        moves++;
      }
    });
    if (k == 0) {
      if (s != i) sfx('wrong');
      return;
    }
    sfx('tap');
    if (waterSorted(t)) showResult(context, score: moves, lower: true, unit: ' moves', tr('Sorted in $moves moves!', '$moves চালে সাজানো হয়েছে!'), () => setState(start));
  }

  void undo() {
    if (history.isEmpty) return;
    final (from, to, k) = history.removeLast();
    setState(() {
      for (var i = 0; i < k; i++) {
        t[from].add(t[to].removeLast());
      }
      moves++;
      sel = null;
    });
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Water Sort', 'পানি সাজানো'),
        Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(tr('Tap a tube, then another, to pour.\nSort every colour into its own tube.', 'ঢালতে একটা টিউবে, তারপর আরেকটায় চাপুন।\nপ্রতিটা রঙ আলাদা টিউবে সাজান।'), textAlign: TextAlign.center, style: TextStyle(color: dim))),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Wrap(alignment: WrapAlignment.center, runSpacing: 16, children: [
                  for (var i = 0; i < t.length; i++)
                    GestureDetector(
                      onTap: () => tap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.fromLTRB(6, sel == i ? 0 : 12, 6, sel == i ? 12 : 0),
                        width: 44,
                        height: tubeCap * 34 + 12,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: sel == i ? Colors.amber : (dark ? Colors.white54 : Colors.black38), width: 2),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          for (final c in t[i].reversed)
                            Container(width: 32, height: 30, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: puzzlePalette[c], borderRadius: BorderRadius.circular(8))),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton.icon(onPressed: history.isEmpty ? null : undo, icon: const Icon(Icons.undo), label: Text(tr('Undo', 'আগের চাল'))),
              const SizedBox(width: 12),
              OutlinedButton.icon(onPressed: () => setState(start), icon: const Icon(Icons.refresh), label: Text(tr('New', 'নতুন'))),
            ]),
          ),
        ]),
        tr('Moves $moves', 'চাল $moves'),
      );
}

// ---------- Knight's Tour ----------

List<int> knightMoves(int i, int n) => [
      for (final (dr, dc) in const [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)])
        if (i ~/ n + dr >= 0 && i ~/ n + dr < n && i % n + dc >= 0 && i % n + dc < n) (i ~/ n + dr) * n + i % n + dc,
    ];

class KnightsTour extends StatefulWidget {
  const KnightsTour(this.n, {super.key});
  final int n;
  @override
  State<KnightsTour> createState() => _KnightsTourState();
}

class _KnightsTourState extends State<KnightsTour> {
  final sw = Stopwatch();
  final path = <int>[];
  int get n => widget.n;

  // On odd boards a full tour can only start on the corners' colour (checked by brute force for 5×5).
  List<int> get legal => path.isEmpty
      ? [for (var i = 0; i < n * n; i++) if (n.isEven || (i ~/ n + i % n).isEven) i]
      : knightMoves(path.last, n).where((j) => !path.contains(j)).toList();

  void tap(int i) {
    if (!legal.contains(i)) return sfx('wrong');
    if (path.isEmpty) {
      sw
        ..reset()
        ..start();
    }
    setState(() => path.add(i));
    if (path.length == n * n) _won(context, sw, () => setState(path.clear));
  }

  @override
  Widget build(BuildContext context) {
    final next = legal;
    return page(
      tr("Knight's Tour", 'ঘোড়ার ভ্রমণ'),
      Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            path.isEmpty ? tr('Tap a highlighted square to place the knight.', 'ঘোড়া বসাতে একটা ঘরে চাপুন।') : (next.isEmpty ? tr('Stuck! Undo and try another path.', 'আটকে গেছেন! পিছিয়ে অন্য পথ চেষ্টা করুন।') : tr('Visit every square exactly once.', 'প্রতিটা ঘরে ঠিক একবার যান।')),
            style: TextStyle(color: dim),
          ),
        ),
        Expanded(
          child: board(n, n * n, gap: 3, (i) {
            final k = path.indexOf(i);
            final color = path.isNotEmpty && i == path.last
                ? Colors.amber.shade700
                : (k >= 0 ? Colors.blueGrey.shade600 : (path.isNotEmpty && next.contains(i) ? Colors.green.shade700 : ((i ~/ n + i % n).isEven ? Colors.grey.shade800 : Colors.grey.shade700)));
            return tile(color, text: path.isNotEmpty && i == path.last ? '♞' : (k >= 0 ? '${k + 1}' : ''), onTap: () => tap(i));
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: path.isEmpty ? null : () => setState(path.removeLast), icon: const Icon(Icons.undo), label: Text(tr('Undo', 'আগের চাল'))),
            OutlinedButton.icon(onPressed: () => setState(path.clear), icon: const Icon(Icons.refresh), label: Text(tr('Restart', 'আবার শুরু'))),
          ]),
        ),
      ]),
      '${path.length}/${n * n}',
    );
  }
}

// ---------- 2048 N×N ----------

class Game2048N extends StatefulWidget {
  const Game2048N(this.n, {super.key});
  final int n;
  @override
  State<Game2048N> createState() => _Game2048NState();
}

class _Game2048NState extends State<Game2048N> {
  late List<int> cells;
  int score = 0;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    cells = List.filled(n * n, 0);
    score = 0;
    spawn();
    spawn();
  }

  void spawn() {
    final free = [for (var i = 0; i < n * n; i++) if (cells[i] == 0) i];
    if (free.isNotEmpty) cells[free[_r.nextInt(free.length)]] = _r.nextInt(10) == 0 ? 4 : 2;
  }

  bool canMove() => cells.contains(0) || [for (var i = 0; i < n * n; i++) i].any((i) => (i % n < n - 1 && cells[i] == cells[i + 1]) || (i < n * n - n && cells[i] == cells[i + n]));

  /// dir: 0 left, 1 right, 2 up, 3 down.
  void move(int dir) {
    var changed = false, gained = 0;
    for (var a = 0; a < n; a++) {
      final idx = [
        for (var b = 0; b < n; b++)
          switch (dir) { 0 => a * n + b, 1 => a * n + n - 1 - b, 2 => b * n + a, _ => (n - 1 - b) * n + a },
      ];
      final (out, g) = slideLine([for (final i in idx) cells[i]]);
      gained += g;
      for (var k = 0; k < n; k++) {
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
    if (!canMove()) showResult(context, won: false, score: score, tr('No moves left!\nScore: $score', 'আর চাল নেই!\nস্কোর: $score'), () => setState(start));
  }

  @override
  Widget build(BuildContext context) => page(
        '2048 · $n×$n',
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
            child: board(n, n * n, gap: n > 5 ? 5 : 8, (i) {
              final v = cells[i];
              final hue = v == 0 ? 0.0 : (log(v) / ln2 * 32) % 360;
              return tile(v == 0 ? (dark ? Colors.grey.shade800 : Colors.grey.shade300) : HSLColor.fromAHSL(1, hue, .6, .45).toColor(), text: v == 0 ? '' : '$v');
            }),
          ),
        ),
        tr('Score $score', 'স্কোর $score'),
      );
}

// ---------- Skyscrapers ----------

/// How many buildings are visible looking along [line] (taller ones hide shorter ones behind).
int skyVisible(Iterable<int> line) {
  var best = 0, k = 0;
  for (final v in line) {
    if (v > best) {
      best = v;
      k++;
    }
  }
  return k;
}

/// Clues as [top, bottom, left, right], each read from the outside in.
List<List<int>> skyClues(List<int> g, int n) => [
      [for (var c = 0; c < n; c++) skyVisible([for (var r = 0; r < n; r++) g[r * n + c]])],
      [for (var c = 0; c < n; c++) skyVisible([for (var r = n - 1; r >= 0; r--) g[r * n + c]])],
      [for (var r = 0; r < n; r++) skyVisible([for (var c = 0; c < n; c++) g[r * n + c]])],
      [for (var r = 0; r < n; r++) skyVisible([for (var c = n - 1; c >= 0; c--) g[r * n + c]])],
    ];

/// A random Latin square (shuffled cyclic square).
List<int> skyMake(int n, Random r) {
  final rows = List.generate(n, (i) => i)..shuffle(r), cols = List.generate(n, (i) => i)..shuffle(r), sym = List.generate(n, (i) => i + 1)..shuffle(r);
  return [for (var i = 0; i < n * n; i++) sym[(rows[i ~/ n] + cols[i % n]) % n]];
}

/// Any filled Latin square matching all clues is accepted.
bool skySolved(List<int> g, int n, List<List<int>> clues) {
  if (g.contains(0)) return false;
  for (var a = 0; a < n; a++) {
    if ({for (var b = 0; b < n; b++) g[a * n + b]}.length < n || {for (var b = 0; b < n; b++) g[b * n + a]}.length < n) return false;
  }
  return _key(skyClues(g, n)) == _key(clues);
}

class Skyscrapers extends StatefulWidget {
  const Skyscrapers(this.n, {super.key});
  final int n;
  @override
  State<Skyscrapers> createState() => _SkyscrapersState();
}

class _SkyscrapersState extends State<Skyscrapers> {
  final sw = Stopwatch();
  late List<List<int>> clues;
  late List<int> g;
  int? sel;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    clues = skyClues(skyMake(n, _r), n);
    g = List.filled(n * n, 0);
    sel = null;
    sw
      ..reset()
      ..start();
  }

  bool clash(int i) {
    final v = g[i], r = i ~/ n, c = i % n;
    return v != 0 && [for (var k = 0; k < n; k++) ...[r * n + k, k * n + c]].any((j) => j != i && g[j] == v);
  }

  void input(int v) {
    final s = sel;
    if (s == null) return;
    setState(() => g[s] = v);
    if (skySolved(g, n, clues)) _won(context, sw, () => setState(start));
  }

  @override
  Widget build(BuildContext context) {
    final m = n + 2;
    return page(
      tr('Skyscrapers', 'আকাশচুম্বী'),
      Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
              tr('Fill 1–4 so each row and column has every height once.\nEdge numbers say how many buildings you can see from there.',
                  'প্রতিটা সারি ও কলামে 1–4 একবার করে বসান।\nকিনারার সংখ্যা বলে ওখান থেকে কয়টা ভবন দেখা যায়।'),
              textAlign: TextAlign.center,
              style: TextStyle(color: dim)),
        ),
        Expanded(
          child: board(m, m * m, gap: 4, (i) {
            final rr = i ~/ m, cc = i % m, inner = rr > 0 && rr <= n && cc > 0 && cc <= n;
            if (!inner) {
              final clue = (rr == 0 || rr == n + 1) && cc > 0 && cc <= n
                  ? clues[rr == 0 ? 0 : 1][cc - 1]
                  : ((cc == 0 || cc == n + 1) && rr > 0 && rr <= n ? clues[cc == 0 ? 2 : 3][rr - 1] : null);
              return Center(child: Text(clue == null ? '' : '$clue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: dark ? Colors.amberAccent : Colors.amber.shade900)));
            }
            final j = (rr - 1) * n + cc - 1;
            return Material(
              color: j == sel ? Colors.deepPurple : Colors.blueGrey.shade800,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => setState(() => sel = j),
                child: Center(
                  child: Text(g[j] == 0 ? '' : '${g[j]}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: clash(j) ? Colors.redAccent : Colors.white)),
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Wrap(spacing: 8, children: [
            for (var v = 1; v <= n; v++) SizedBox(width: 52, height: 52, child: FilledButton.tonal(style: FilledButton.styleFrom(padding: EdgeInsets.zero), onPressed: () => input(v), child: Text('$v', style: const TextStyle(fontSize: 22)))),
            SizedBox(width: 52, height: 52, child: IconButton.filledTonal(onPressed: () => input(0), icon: const Icon(Icons.backspace_outlined))),
          ]),
        ),
      ]),
      tr('${g.where((v) => v == 0).length} left', '${g.where((v) => v == 0).length} বাকি'),
    );
  }
}
