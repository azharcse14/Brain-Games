import 'dart:math';

import 'package:flutter/material.dart';

import 'duel.dart';
import 'games.dart';
import 'tabletop.dart';

// Board cells: 0 = empty, 1 = Blue (player 0), 2 = Red (player 1).

final duelBoardGames = <Game>[
  Game('2P Tic Tac Toe 3×3', '2P Board', () => const InARow('Tic Tac Toe', 3, 3, 3), glyph: '✕○'),
  Game('2P Tic Tac Toe 4×4', '2P Board', () => const InARow('Tic Tac Toe 4×4', 4, 4, 4), glyph: '4×4'),
  Game('2P Tic Tac Toe 5×5', '2P Board', () => const InARow('Tic Tac Toe 5×5', 5, 5, 4), glyph: '5×5'),
  for (final n in [9, 11, 15]) Game('Gomoku $n×$n', '2P Board', () => InARow('Gomoku $n×$n', n, n, 5), glyph: '⚫⚪'),
  Game('2P Connect Four 7×6', '2P Board', () => const InARow('Connect Four', 6, 7, 4, gravity: true), glyph: '🔵🔴'),
  Game('Connect Four 8×7', '2P Board', () => const InARow('Connect Four 8×7', 7, 8, 4, gravity: true), glyph: '8×7'),
  Game('Connect Five 9×7', '2P Board', () => const InARow('Connect Five', 7, 9, 5, gravity: true), glyph: 'C5'),
  Game('Connect Three 5×4', '2P Board', () => const InARow('Connect Three', 4, 5, 3, gravity: true), glyph: 'C3'),
  Game('Gravity Gomoku 10×10', '2P Board', () => const InARow('Gravity Gomoku', 10, 10, 5, gravity: true), glyph: '⬇⚪'),
  Game('Misère Tic Tac Toe', '2P Board', () => const InARow('Misère Tic Tac Toe', 3, 3, 3, misere: true), glyph: '🙃'),
  Game('Ultimate Tic Tac Toe', '2P Board', () => const UltimateTtt(), glyph: '⊞'),
  for (final n in [6, 8, 10]) Game('Reversi $n×$n', '2P Board', () => Reversi(n), glyph: '◐'),
  for (final n in [3, 4, 5, 6]) Game('Dots and Boxes $n×$n', '2P Board', () => DotsBoxes(n), glyph: '⊡'),
  for (final s in [3, 4, 6]) Game('Mancala $s Seeds', '2P Board', () => Mancala(s), glyph: '🥣'),
  for (final n in [5, 7, 9]) Game('Hex $n×$n', '2P Board', () => Hex(n), glyph: '⬡'),
  for (final n in [5, 6, 8]) Game('Domineering $n×$n', '2P Board', () => Domineering(n), glyph: '▯▭'),
  Game('Nim 3-4-5', '2P Board', () => const Nim('Nim 3-4-5', [3, 4, 5]), glyph: '|||'),
  Game('Nim 1-3-5-7', '2P Board', () => const Nim('Nim 1-3-5-7', [1, 3, 5, 7]), glyph: '|‖|'),
  Game('Misère Nim', '2P Board', () => const Nim('Misère Nim', [1, 3, 5, 7], misere: true), glyph: '🙃|'),
  Game('21 Sticks', '2P Board', () => const Nim('21 Sticks', [21], misere: true, maxTake: 3), glyph: '21'),
  for (final (r, c) in [(4, 6), (6, 8)]) Game('Chomp $r×$c', '2P Board', () => Chomp(r, c), glyph: '🍫'),
  for (final t in [50, 100]) Game('Pig to $t', '2P Board', () => Pig(t), glyph: '🐷'),
  Game('Pentago', '2P Board', () => const Pentago(), glyph: '↻'),
  Game('Isolation 7×7', '2P Board', () => const Isolation(7, knight: false), glyph: '♛'),
  Game('Knight Isolation 8×8', '2P Board', () => const Isolation(8, knight: true), glyph: '♞'),
];

// ---------- shared logic ----------

/// Whether the stone at [i] is part of [k] or more in a row.
bool lineAt(List<int> cells, int rows, int cols, int i, int k) {
  final p = cells[i], r0 = i ~/ cols, c0 = i % cols;
  if (p == 0) return false;
  int run(int dr, int dc) {
    var n = 0, r = r0 + dr, c = c0 + dc;
    while (r >= 0 && r < rows && c >= 0 && c < cols && cells[r * cols + c] == p) {
      n++;
      r += dr;
      c += dc;
    }
    return n;
  }

  return [(0, 1), (1, 0), (1, 1), (1, -1)].any((d) => 1 + run(d.$1, d.$2) + run(-d.$1, -d.$2) >= k);
}

bool hasLine(List<int> cells, int rows, int cols, int k, int p) =>
    [for (var i = 0; i < cells.length; i++) i].any((i) => cells[i] == p && lineAt(cells, rows, cols, i, k));

Widget disc(int v) => v == 0
    ? const SizedBox.expand()
    : Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: duelColors[v - 1], border: Border.all(color: Colors.white54)));

Widget cellBox(Color color, Widget child, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)), child: child),
    );

Widget duelPage(String title, int turn, Widget body, {String? banner, String? status}) =>
    page(title, Column(children: [turnBanner(turn, banner), Expanded(child: body)]), status);

// ---------- N in a row ----------

class InARow extends StatefulWidget {
  const InARow(this.title, this.rows, this.cols, this.k, {this.gravity = false, this.misere = false, super.key});
  final String title;
  final int rows, cols, k;
  final bool gravity, misere;
  @override
  State<InARow> createState() => _InARowState();
}

class _InARowState extends State<InARow> {
  late List<int> cells;
  int turn = 0;
  bool over = false;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    cells = List.filled(widget.rows * widget.cols, 0);
    turn = 0;
    over = false;
  }

  void tap(int i) {
    final w = widget;
    if (over) return;
    var j = i;
    if (w.gravity) {
      j = -1;
      for (var r = w.rows - 1; r >= 0; r--) {
        if (cells[r * w.cols + i % w.cols] == 0) {
          j = r * w.cols + i % w.cols;
          break;
        }
      }
      if (j < 0) return;
    } else if (cells[j] != 0) {
      return;
    }
    sfx('tap');
    setState(() => cells[j] = turn + 1);
    if (lineAt(cells, w.rows, w.cols, j, w.k)) {
      over = true;
      showWinner(context, w.misere ? 1 - turn : turn, () => setState(start));
    } else if (!cells.contains(0)) {
      over = true;
      showWinner(context, null, () => setState(start));
    } else {
      setState(() => turn = 1 - turn);
    }
  }

  @override
  Widget build(BuildContext context) => duelPage(
        widget.title,
        turn,
        board(widget.cols, cells.length, gap: widget.cols > 9 ? 1 : 3, (i) => cellBox(Colors.blueGrey.shade800, disc(cells[i]), () => tap(i))),
        banner: "${duelNames[turn]}'s turn · ${widget.misere ? '${widget.k} in a row LOSES' : '${widget.k} in a row wins'}",
      );
}

// ---------- Ultimate Tic Tac Toe ----------

const tttLines = [
  [0, 1, 2],
  [3, 4, 5],
  [6, 7, 8],
  [0, 3, 6],
  [1, 4, 7],
  [2, 5, 8],
  [0, 4, 8],
  [2, 4, 6]
];

/// 1 or 2 if that player has three in a row on a 3×3 board (3 = drawn board, never counts), else 0.
int tttWinner(List<int> v) {
  for (final l in tttLines) {
    if ((v[l[0]] == 1 || v[l[0]] == 2) && v[l[0]] == v[l[1]] && v[l[1]] == v[l[2]]) return v[l[0]];
  }
  return 0;
}

class UltimateTtt extends StatefulWidget {
  const UltimateTtt({super.key});
  @override
  State<UltimateTtt> createState() => _UltimateTttState();
}

class _UltimateTttState extends State<UltimateTtt> {
  late List<int> cells, small; // cells[b * 9 + c]; small: 0 open, 1/2 won, 3 drawn
  int turn = 0;
  int? forced;
  bool over = false;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    cells = List.filled(81, 0);
    small = List.filled(9, 0);
    turn = 0;
    forced = null;
    over = false;
  }

  bool allowed(int b) => !over && small[b] == 0 && (forced == null || forced == b);

  void tap(int g) {
    final r = g ~/ 9, c = g % 9, b = r ~/ 3 * 3 + c ~/ 3, cl = r % 3 * 3 + c % 3, i = b * 9 + cl;
    if (!allowed(b) || cells[i] != 0) return;
    sfx('tap');
    setState(() {
      cells[i] = turn + 1;
      final sub = cells.sublist(b * 9, b * 9 + 9), w = tttWinner(sub);
      small[b] = w != 0 ? w : (sub.contains(0) ? 0 : 3);
      forced = small[cl] == 0 ? cl : null;
      turn = 1 - turn;
    });
    final big = tttWinner(small);
    if (big != 0 || !small.contains(0)) {
      over = true;
      showWinner(context, big == 0 ? null : big - 1, () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) => duelPage(
        'Ultimate Tic Tac Toe',
        turn,
        banner: "${duelNames[turn]}'s turn · ${forced == null ? 'play any open board' : 'play in the lit board'}",
        board(9, 81, gap: 2, (g) {
          final r = g ~/ 9, c = g % 9, b = r ~/ 3 * 3 + c ~/ 3;
          final color = small[b] == 1 || small[b] == 2
              ? duelColors[small[b] - 1].shade900
              : (allowed(b) ? Colors.teal.shade700 : (b.isEven ? Colors.blueGrey.shade800 : Colors.blueGrey.shade700));
          return cellBox(color, disc(cells[b * 9 + r % 3 * 3 + c % 3]), () => tap(g));
        }),
      );
}

// ---------- Reversi ----------

/// Opponent discs flipped if player [p] (1/2) plays at [i]; empty = illegal move.
List<int> reversiFlips(List<int> cells, int n, int i, int p) {
  if (cells[i] != 0) return const [];
  final out = <int>[];
  for (var dr = -1; dr <= 1; dr++) {
    for (var dc = -1; dc <= 1; dc++) {
      if (dr == 0 && dc == 0) continue;
      final line = <int>[];
      var r = i ~/ n + dr, c = i % n + dc;
      while (r >= 0 && r < n && c >= 0 && c < n && cells[r * n + c] == 3 - p) {
        line.add(r * n + c);
        r += dr;
        c += dc;
      }
      if (line.isNotEmpty && r >= 0 && r < n && c >= 0 && c < n && cells[r * n + c] == p) out.addAll(line);
    }
  }
  return out;
}

bool reversiCanMove(List<int> cells, int n, int p) => [for (var i = 0; i < n * n; i++) i].any((i) => reversiFlips(cells, n, i, p).isNotEmpty);

class Reversi extends StatefulWidget {
  const Reversi(this.n, {super.key});
  final int n;
  @override
  State<Reversi> createState() => _ReversiState();
}

class _ReversiState extends State<Reversi> {
  late List<int> cells;
  int turn = 0;
  String? note;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    final m = n ~/ 2;
    cells = List.filled(n * n, 0);
    cells[(m - 1) * n + m - 1] = cells[m * n + m] = 2;
    cells[(m - 1) * n + m] = cells[m * n + m - 1] = 1;
    turn = 0;
    note = null;
  }

  void tap(int i) {
    final flips = reversiFlips(cells, n, i, turn + 1);
    if (flips.isEmpty) return sfx('wrong');
    sfx('tap');
    var over = false;
    setState(() {
      cells[i] = turn + 1;
      for (final f in flips) {
        cells[f] = turn + 1;
      }
      note = null;
      if (reversiCanMove(cells, n, 2 - turn)) {
        turn = 1 - turn;
      } else if (reversiCanMove(cells, n, turn + 1)) {
        note = '${duelNames[1 - turn]} has no move and passes';
      } else {
        over = true;
      }
    });
    if (over) {
      final b = cells.where((v) => v == 1).length, r = cells.where((v) => v == 2).length;
      showWinner(context, b == r ? null : (b > r ? 0 : 1), () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) {
    final legal = {
      for (var i = 0; i < n * n; i++)
        if (reversiFlips(cells, n, i, turn + 1).isNotEmpty) i
    };
    return duelPage(
      'Reversi $n×$n',
      turn,
      banner: note,
      status: '🔵${cells.where((v) => v == 1).length} 🔴${cells.where((v) => v == 2).length}',
      board(
          n,
          n * n,
          gap: 2,
          (i) => cellBox(
                Colors.green.shade800,
                cells[i] != 0
                    ? disc(cells[i])
                    : legal.contains(i)
                        ? Center(
                            child: FractionallySizedBox(
                                widthFactor: .25,
                                heightFactor: .25,
                                child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white38))))
                        : const SizedBox.expand(),
                () => tap(i),
              )),
    );
  }
}

// ---------- Dots and Boxes ----------

/// On a (2n+1)² grid (dots at even/even, boxes at odd/odd), the boxes next to [edge] that are now fully enclosed.
List<int> closedBoxes(Set<int> lines, int s, int edge) {
  final beside = (edge ~/ s).isEven ? [edge - s, edge + s] : [edge - 1, edge + 1];
  return beside.where((b) => b >= 0 && b < s * s && (b ~/ s).isOdd && (b % s).isOdd && [b - s, b + s, b - 1, b + 1].every(lines.contains)).toList();
}

class DotsBoxes extends StatefulWidget {
  const DotsBoxes(this.n, {super.key});
  final int n;
  @override
  State<DotsBoxes> createState() => _DotsBoxesState();
}

class _DotsBoxesState extends State<DotsBoxes> {
  final lines = <int>{};
  final owner = <int, int>{};
  int turn = 0;
  int get s => 2 * widget.n + 1;

  void start() {
    lines.clear();
    owner.clear();
    turn = 0;
  }

  void tap(int g) {
    if ((g ~/ s + g % s).isEven || lines.contains(g)) return;
    sfx('tap');
    final closed = closedBoxes({...lines, g}, s, g);
    setState(() {
      lines.add(g);
      for (final b in closed) {
        owner[b] = turn;
      }
      if (closed.isEmpty) turn = 1 - turn;
    });
    if (closed.isNotEmpty) sfx('right');
    if (owner.length == widget.n * widget.n) {
      final b = owner.values.where((p) => p == 0).length, r = owner.length - b;
      showWinner(context, b == r ? null : (b > r ? 0 : 1), () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) => duelPage(
        'Dots and Boxes',
        turn,
        banner: "${duelNames[turn]}'s turn · close a box to go again",
        status: '🔵${owner.values.where((p) => p == 0).length} 🔴${owner.values.where((p) => p == 1).length}',
        board(s, s * s, gap: 0, (g) {
          final r = g ~/ s, c = g % s;
          if (r.isEven && c.isEven) {
            return Center(
              child: FractionallySizedBox(widthFactor: .4, heightFactor: .4, child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white))),
            );
          }
          if (r.isOdd && c.isOdd) {
            return Container(margin: const EdgeInsets.all(2), color: owner[g] == null ? null : duelColors[owner[g]!].withValues(alpha: .6));
          }
          final drawn = lines.contains(g);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => tap(g),
            child: Center(
              child: FractionallySizedBox(
                widthFactor: r.isEven ? 1 : .2,
                heightFactor: r.isEven ? .2 : 1,
                child: Container(color: drawn ? Colors.white : Colors.white12),
              ),
            ),
          );
        }),
      );
}

// ---------- Mancala (Kalah) ----------

/// Pits 0–5 + store 6 belong to Blue (p 0); pits 7–12 + store 13 to Red. Sows pit [i]; returns true for an extra turn.
bool kalahSow(List<int> pits, int i, int p) {
  var seeds = pits[i], j = i;
  pits[i] = 0;
  final skip = p == 0 ? 13 : 6, store = p == 0 ? 6 : 13;
  while (seeds > 0) {
    j = (j + 1) % 14;
    if (j == skip) continue;
    pits[j]++;
    seeds--;
  }
  if (j == store) return true;
  final own = p == 0 ? j < 6 : j > 6 && j < 13;
  if (own && pits[j] == 1 && pits[12 - j] > 0) {
    pits[store] += pits[12 - j] + 1;
    pits[12 - j] = pits[j] = 0;
  }
  return false;
}

/// When a side is empty, sweeps the other side into its store; returns true if the game is over.
bool kalahEnd(List<int> pits) {
  if (pits.sublist(0, 6).any((x) => x > 0) && pits.sublist(7, 13).any((x) => x > 0)) return false;
  for (var i = 0; i < 6; i++) {
    pits[6] += pits[i];
    pits[13] += pits[i + 7];
    pits[i] = pits[i + 7] = 0;
  }
  return true;
}

class Mancala extends StatefulWidget {
  const Mancala(this.seeds, {super.key});
  final int seeds;
  @override
  State<Mancala> createState() => _MancalaState();
}

class _MancalaState extends State<Mancala> {
  late List<int> pits;
  int turn = 0;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    pits = List.generate(14, (i) => i == 6 || i == 13 ? 0 : widget.seeds);
    turn = 0;
  }

  void tap(int i) {
    final mine = turn == 0 ? i < 6 : i > 6 && i < 13;
    if (!mine || pits[i] == 0) return;
    sfx('tap');
    late bool again, end;
    setState(() {
      again = kalahSow(pits, i, turn);
      end = kalahEnd(pits);
      if (!again) turn = 1 - turn;
    });
    if (end) showWinner(context, pits[6] == pits[13] ? null : (pits[6] > pits[13] ? 0 : 1), () => setState(start));
  }

  Widget pit(int i) {
    final store = i == 6 || i == 13, owner = i < 7 ? 0 : 1;
    return GestureDetector(
      onTap: () => tap(i),
      child: Container(
        width: store ? 44 : 40,
        height: store ? 120 : 40,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.brown.shade700,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: !store && owner == turn && pits[i] > 0 ? duelColors[turn] : Colors.brown.shade900, width: 3),
        ),
        child: Text('${pits[i]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => duelPage(
        'Mancala · ${widget.seeds} Seeds',
        turn,
        banner: "${duelNames[turn]}'s turn · ${turn == 0 ? 'bottom' : 'top'} row",
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown, // the board is 372 px wide; shrink it on 360 px phones
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.brown.shade400, borderRadius: BorderRadius.circular(24)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                pit(13),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [for (var i = 12; i >= 7; i--) pit(i)]),
                  const SizedBox(height: 20),
                  Row(children: [for (var i = 0; i < 6; i++) pit(i)]),
                ]),
                pit(6),
              ]),
            ),
          ),
        ),
      );
}

// ---------- Hex ----------

/// Blue (1) joins top to bottom, Red (2) joins left to right.
bool hexWon(List<int> cells, int n, int p) {
  final seen = <int>{},
      stack = [
        for (var k = 0; k < n; k++)
          if (cells[p == 1 ? k : k * n] == p) p == 1 ? k : k * n
      ];
  while (stack.isNotEmpty) {
    final i = stack.removeLast();
    if (!seen.add(i)) continue;
    final r = i ~/ n, c = i % n;
    if (p == 1 ? r == n - 1 : c == n - 1) return true;
    for (final (dr, dc) in [(-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0)]) {
      final rr = r + dr, cc = c + dc;
      if (rr >= 0 && rr < n && cc >= 0 && cc < n && cells[rr * n + cc] == p) stack.add(rr * n + cc);
    }
  }
  return false;
}

class Hex extends StatefulWidget {
  const Hex(this.n, {super.key});
  final int n;
  @override
  State<Hex> createState() => _HexState();
}

class _HexState extends State<Hex> {
  late List<int> cells;
  int turn = 0;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    cells = List.filled(n * n, 0);
    turn = 0;
  }

  void tap(int i) {
    if (cells[i] != 0) return;
    sfx('tap');
    setState(() => cells[i] = turn + 1);
    if (hexWon(cells, n, turn + 1)) {
      showWinner(context, turn, () => setState(start));
    } else {
      setState(() => turn = 1 - turn);
    }
  }

  @override
  Widget build(BuildContext context) => duelPage(
        'Hex $n×$n',
        turn,
        banner: "${duelNames[turn]}'s turn · Blue: top↕bottom · Red: left↔right",
        LayoutBuilder(builder: (_, box) {
          final s = min(box.maxWidth - 24, 460) / (n + (n - 1) / 2);
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: s * n, height: 4, margin: EdgeInsets.only(right: s * (n - 1) / 2), color: duelColors[0]),
              for (var r = 0; r < n; r++)
                Padding(
                  padding: EdgeInsets.only(left: r * s / 2, right: (n - 1 - r) * s / 2),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 3, height: s * .8, color: duelColors[1]),
                    for (var c = 0; c < n; c++)
                      GestureDetector(
                        onTap: () => tap(r * n + c),
                        child: Container(
                          width: s - 1,
                          height: s - 1,
                          margin: const EdgeInsets.all(.5),
                          decoration:
                              BoxDecoration(shape: BoxShape.circle, color: cells[r * n + c] == 0 ? Colors.blueGrey.shade700 : duelColors[cells[r * n + c] - 1]),
                        ),
                      ),
                    Container(width: 3, height: s * .8, color: duelColors[1]),
                  ]),
                ),
              Container(width: s * n, height: 4, margin: EdgeInsets.only(left: s * (n - 1) / 2), color: duelColors[0]),
            ]),
          );
        }),
      );
}

// ---------- Domineering ----------

/// Whether a domino still fits: vertical covers i and i+n, horizontal covers i and i+1.
bool domCanPlace(List<int> owner, int n, bool vertical) =>
    [for (var i = 0; i < n * n; i++) i].any((i) => owner[i] == 0 && (vertical ? i + n < n * n && owner[i + n] == 0 : i % n < n - 1 && owner[i + 1] == 0));

class Domineering extends StatefulWidget {
  const Domineering(this.n, {super.key});
  final int n;
  @override
  State<Domineering> createState() => _DomineeringState();
}

class _DomineeringState extends State<Domineering> {
  late List<int> owner;
  int turn = 0;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    owner = List.filled(n * n, 0);
    turn = 0;
  }

  void tap(int i) {
    final vertical = turn == 0, j = vertical ? i + n : i + 1;
    final fits = owner[i] == 0 && (vertical ? j < n * n : i % n < n - 1) && owner[j] == 0;
    if (!fits) return sfx('wrong');
    sfx('tap');
    setState(() => owner[i] = owner[j] = turn + 1);
    if (!domCanPlace(owner, n, !vertical)) {
      showWinner(context, turn, () => setState(start));
    } else {
      setState(() => turn = 1 - turn);
    }
  }

  @override
  Widget build(BuildContext context) => duelPage(
        'Domineering $n×$n',
        turn,
        banner: "${duelNames[turn]} places ${turn == 0 ? 'vertical ▯ (tap top cell)' : 'horizontal ▭ (tap left cell)'} · no room = you lose",
        board(n, n * n, gap: 2, (i) => cellBox(owner[i] == 0 ? Colors.blueGrey.shade700 : duelColors[owner[i] - 1], const SizedBox.expand(), () => tap(i))),
      );
}

// ---------- Nim ----------

/// Winner once every heap is empty: the last mover wins, or loses in misère play. Null while sticks remain.
int? nimWinner(List<int> heaps, int lastMover, bool misere) => heaps.every((h) => h == 0) ? (misere ? 1 - lastMover : lastMover) : null;

class Nim extends StatefulWidget {
  const Nim(this.title, this.heaps, {this.misere = false, this.maxTake, super.key});
  final String title;
  final List<int> heaps;
  final bool misere;
  final int? maxTake;
  @override
  State<Nim> createState() => _NimState();
}

class _NimState extends State<Nim> {
  late List<int> h;
  int turn = 0;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    h = widget.heaps.toList();
    turn = 0;
  }

  void take(int heap, int k) {
    final n = h[heap] - k, limit = widget.maxTake;
    if (n < 1 || (limit != null && n > limit)) return sfx('wrong');
    sfx('tap');
    setState(() => h[heap] = k);
    final w = nimWinner(h, turn, widget.misere);
    if (w != null) {
      showWinner(context, w, () => setState(start));
    } else {
      setState(() => turn = 1 - turn);
    }
  }

  @override
  Widget build(BuildContext context) => duelPage(
        widget.title,
        turn,
        banner: "${duelNames[turn]}'s turn · ${widget.misere ? 'taking the last stick LOSES' : 'take the last stick to win'}",
        ListView(padding: const EdgeInsets.all(16), children: [
          Text('Tap a stick to take it and every stick to its right${widget.maxTake == null ? ' (one heap per turn)' : ' (1–${widget.maxTake} per turn)'}.',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          for (var i = 0; i < h.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                for (var k = 0; k < h[i]; k++)
                  GestureDetector(
                    onTap: () => take(i, k),
                    child: Container(width: 14, height: 64, decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(7))),
                  ),
                if (h[i] == 0) const Text('—', style: TextStyle(fontSize: 32, color: Colors.white24)),
              ]),
            ),
        ]),
      );
}

// ---------- Chomp ----------

/// Eats (r, c) and every square below and to the right of it.
void chomp(List<bool> eaten, int cols, int r, int c) {
  for (var i = 0; i < eaten.length; i++) {
    if (i ~/ cols >= r && i % cols >= c) eaten[i] = true;
  }
}

class Chomp extends StatefulWidget {
  const Chomp(this.rows, this.cols, {super.key});
  final int rows, cols;
  @override
  State<Chomp> createState() => _ChompState();
}

class _ChompState extends State<Chomp> {
  late List<bool> eaten;
  int turn = 0;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    eaten = List.filled(widget.rows * widget.cols, false);
    turn = 0;
  }

  void tap(int i) {
    if (eaten[i]) return;
    sfx('tap');
    setState(() => chomp(eaten, widget.cols, i ~/ widget.cols, i % widget.cols));
    if (i == 0) {
      showWinner(context, 1 - turn, () => setState(start));
    } else {
      setState(() => turn = 1 - turn);
    }
  }

  @override
  Widget build(BuildContext context) => duelPage(
        'Chomp ${widget.rows}×${widget.cols}',
        turn,
        banner: "${duelNames[turn]}'s turn · whoever eats ☠️ loses",
        board(
            widget.cols,
            eaten.length,
            gap: 3,
            (i) => eaten[i]
                ? const SizedBox()
                : cellBox(Colors.brown.shade600, Center(child: Text(i == 0 ? '☠️' : '', style: const TextStyle(fontSize: 22))), () => tap(i))),
      );
}

// ---------- Pig (dice) ----------

class Pig extends StatefulWidget {
  const Pig(this.target, {super.key});
  final int target;
  @override
  State<Pig> createState() => _PigState();
}

class _PigState extends State<Pig> {
  final scores = [0, 0];
  int turn = 0, pot = 0;
  int? die;
  bool rolling = false;

  void start() {
    scores.fillRange(0, 2, 0);
    turn = pot = 0;
    die = null;
  }

  Future<void> roll() async {
    setState(() => rolling = true);
    final d = await rollDice((v) {
      if (mounted) setState(() => die = v);
    });
    if (!mounted) return;
    sfx(d == 1 ? 'wrong' : 'tap');
    setState(() {
      rolling = false;
      if (d == 1) {
        pot = 0;
        turn = 1 - turn;
      } else {
        pot += d;
      }
    });
  }

  void hold() {
    setState(() {
      scores[turn] += pot;
      pot = 0;
    });
    if (scores[turn] >= widget.target) {
      showWinner(context, turn, () => setState(start));
    } else {
      setState(() => turn = 1 - turn);
    }
  }

  @override
  Widget build(BuildContext context) => duelPage(
        'Pig to ${widget.target}',
        turn,
        banner: "${duelNames[turn]}'s turn · a 1 loses this turn's points",
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (var p = 0; p < 2; p++)
              Column(children: [
                Text(duelNames[p], style: TextStyle(fontSize: 20, color: duelColors[p])),
                Text('${scores[p]}', style: TextStyle(fontSize: 48, fontWeight: p == turn ? FontWeight.w900 : FontWeight.w300)),
              ]),
          ]),
          const SizedBox(height: 24),
          dice(die, size: 80),
          const SizedBox(height: 16),
          Text('This turn: $pot', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton.icon(onPressed: rolling ? null : roll, icon: const Icon(Icons.casino), label: const Text('Roll')),
            const SizedBox(width: 16),
            FilledButton.tonal(onPressed: rolling || pot == 0 ? null : hold, child: const Text('Hold')),
          ]),
        ]),
      );
}

// ---------- Pentago ----------

/// Rotates quadrant [q] (0 TL, 1 TR, 2 BL, 3 BR) of a 6×6 board by 90°.
void rotateQuadrant(List<int> b, int q, bool cw) {
  final r0 = q ~/ 2 * 3, c0 = q % 2 * 3, old = b.toList();
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      final v = old[(r0 + i) * 6 + c0 + j];
      if (cw) {
        b[(r0 + j) * 6 + c0 + 2 - i] = v;
      } else {
        b[(r0 + 2 - j) * 6 + c0 + i] = v;
      }
    }
  }
}

class Pentago extends StatefulWidget {
  const Pentago({super.key});
  @override
  State<Pentago> createState() => _PentagoState();
}

class _PentagoState extends State<Pentago> {
  late List<int> cells;
  int turn = 0;
  bool rotating = false;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    cells = List.filled(36, 0);
    turn = 0;
    rotating = false;
  }

  /// Ends the game if anyone has five; returns true if it ended.
  bool check() {
    final b = hasLine(cells, 6, 6, 5, 1), r = hasLine(cells, 6, 6, 5, 2);
    if (!b && !r && cells.contains(0)) return false;
    showWinner(context, b == r ? null : (b ? 0 : 1), () => setState(start));
    return true;
  }

  void place(int i) {
    if (rotating || cells[i] != 0) return;
    sfx('tap');
    setState(() {
      cells[i] = turn + 1;
      rotating = true;
    });
    if (hasLine(cells, 6, 6, 5, turn + 1)) showWinner(context, turn, () => setState(start));
  }

  void rotate(int q, bool cw) {
    sfx('tap');
    setState(() {
      rotateQuadrant(cells, q, cw);
      rotating = false;
    });
    if (!check()) setState(() => turn = 1 - turn);
  }

  @override
  Widget build(BuildContext context) => duelPage(
        'Pentago',
        turn,
        banner: "${duelNames[turn]}: ${rotating ? 'now rotate a quadrant' : 'place a marble'} · 5 in a row wins",
        Column(children: [
          Expanded(
              child: board(
                  6,
                  36,
                  gap: 3,
                  (i) => cellBox((i ~/ 18 + i % 6 ~/ 3).isEven ? Colors.brown.shade700 : Colors.brown.shade500, disc(cells[i]), () => place(i)))),
          if (rotating)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                for (var q = 0; q < 4; q++)
                  for (final cw in [false, true])
                    OutlinedButton(onPressed: () => rotate(q, cw), child: Text('${'◰◳◱◲'[q]} ${cw ? '↻' : '↺'}', style: const TextStyle(fontSize: 18))),
              ]),
            ),
        ]),
      );
}

// ---------- Isolation ----------

/// Cells a piece at [from] can move to: queen slides or knight jumps, never onto [blocked].
List<int> isoMoves(Set<int> blocked, int n, int from, bool knight) {
  final r0 = from ~/ n, c0 = from % n, out = <int>[];
  bool free(int r, int c) => r >= 0 && r < n && c >= 0 && c < n && !blocked.contains(r * n + c);
  if (knight) {
    for (final (dr, dc) in [(1, 2), (2, 1), (-1, 2), (-2, 1), (1, -2), (2, -1), (-1, -2), (-2, -1)]) {
      if (free(r0 + dr, c0 + dc)) out.add((r0 + dr) * n + c0 + dc);
    }
    return out;
  }
  for (var dr = -1; dr <= 1; dr++) {
    for (var dc = -1; dc <= 1; dc++) {
      if (dr == 0 && dc == 0) continue;
      for (var r = r0 + dr, c = c0 + dc; free(r, c); r += dr, c += dc) {
        out.add(r * n + c);
      }
    }
  }
  return out;
}

class Isolation extends StatefulWidget {
  const Isolation(this.n, {required this.knight, super.key});
  final int n;
  final bool knight;
  @override
  State<Isolation> createState() => _IsolationState();
}

class _IsolationState extends State<Isolation> {
  final burned = <int>{};
  late List<int> pos;
  int turn = 0;
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    burned.clear();
    pos = [0, n * n - 1];
    turn = 0;
  }

  List<int> moves(int p) => isoMoves({...burned, ...pos}, n, pos[p], widget.knight);

  void tap(int i) {
    if (!moves(turn).contains(i)) return;
    sfx('tap');
    setState(() {
      burned.add(pos[turn]);
      pos[turn] = i;
    });
    if (moves(1 - turn).isEmpty) {
      showWinner(context, turn, () => setState(start));
    } else {
      setState(() => turn = 1 - turn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final legal = moves(turn).toSet(), piece = widget.knight ? '♞' : '♛';
    return duelPage(
      widget.knight ? 'Knight Isolation' : 'Isolation',
      turn,
      banner: "${duelNames[turn]}'s turn · move like a ${widget.knight ? 'knight' : 'queen'} · stuck = you lose",
      board(n, n * n, gap: 2, (i) {
        final who = pos.indexOf(i);
        return cellBox(
          burned.contains(i) ? Colors.black : (legal.contains(i) ? duelColors[turn].shade900 : Colors.blueGrey.shade700),
          Center(
            child: FittedBox(
              child: Text(who >= 0 ? piece : (burned.contains(i) ? '✕' : ''),
                  style: TextStyle(fontSize: 26, color: who >= 0 ? duelColors[who].shade200 : Colors.white24)),
            ),
          ),
          () => tap(i),
        );
      }),
    );
  }
}
