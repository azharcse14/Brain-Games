import 'dart:math';

import 'package:flutter/material.dart';

import 'complex.dart' show mastermindScore;
import 'duel.dart';
import 'games.dart';

final _r = Random();

final duelClassicGames = <Game>[
  Game('Chess', '2P Board', () => ClassicBoard(Chess.new), glyph: '♞'),
  Game('Chess960', '2P Board', () => ClassicBoard(() => Chess(fischer: true)), glyph: '960'),
  Game('Checkers', '2P Board', () => ClassicBoard(() => Checkers(8)), glyph: '🏁'),
  Game('Checkers Casual', '2P Board', () => ClassicBoard(() => Checkers(8, forcedCapture: false)), glyph: '🏁'),
  Game('Checkers 10×10', '2P Board', () => ClassicBoard(() => Checkers(10)), glyph: '🏁'),
  Game('Giveaway Checkers', '2P Board', () => ClassicBoard(() => Checkers(8, giveaway: true)), glyph: '🎁'),
  for (final n in [9, 13]) Game('Go $n×$n', '2P Board', () => ClassicBoard(() => Go(n)), glyph: '⚫⚪'),
  Game("Nine Men's Morris", '2P Board', () => ClassicBoard(Morris.nine), glyph: '9⚪'),
  Game("Six Men's Morris", '2P Board', () => ClassicBoard(Morris.six), glyph: '6⚪'),
  Game("Three Men's Morris", '2P Board', () => ClassicBoard(Morris.three), glyph: '3⚪'),
  for (final (n, w) in [(9, 10), (7, 7)]) Game('Quoridor $n×$n', '2P Board', () => ClassicBoard(() => Quoridor(n, w)), glyph: '🧱'),
  for (final (n, ships) in [(8, [4, 3, 3, 2, 2]), (10, [5, 4, 3, 3, 2])]) Game('Battleship $n×$n', '2P Board', () => Battleship(n, ships), glyph: '🚢'),
  Game('Tablut', '2P Board', () => ClassicBoard(() => Tafl(9)), glyph: '👑'),
  Game('Brandubh', '2P Board', () => ClassicBoard(() => Tafl(7)), glyph: '🛡️'),
  for (final n in [6, 8]) Game('Breakthrough $n×$n', '2P Board', () => ClassicBoard(() => Breakthrough(n)), glyph: '⚔️'),
  for (final n in [6, 8]) Game('Amazons $n×$n', '2P Board', () => ClassicBoard(() => Amazons(n)), glyph: '🏹'),
  Game('Fox and Geese', '2P Board', () => ClassicBoard(FoxGeese.new), glyph: '🦊'),
  for (final n in [6, 8]) Game('Konane $n×$n', '2P Board', () => ClassicBoard(() => Konane(n)), glyph: '🌋'),
  Game('Lines of Action', '2P Board', () => ClassicBoard(LinesOfAction.new), glyph: '🔗'),
  for (final (c, r) in [(4, 4), (4, 6), (6, 6)]) Game('Memory Duel $c×$r', '2P Board', () => MemoryDuel(c, r), glyph: '🃏'),
  Game('Hangman Duel', '2P Board', () => const HangmanDuel(), glyph: '🪢'),
  Game('Mastermind Duel', '2P Board', () => const MastermindDuel(), glyph: '🕵️'),
];

// ---------- shared grid helpers ----------

const _orth = [(0, 1), (0, -1), (1, 0), (-1, 0)];
const _diag = [(1, 1), (1, -1), (-1, 1), (-1, -1)];
const _knight = [(1, 2), (2, 1), (-1, 2), (-2, 1), (1, -2), (2, -1), (-1, -2), (-2, -1)];
const _light = Color(0xFFF0D9B5), _dark = Color(0xFFB58863), _wood = Color(0xFFDCB35C);

/// Squares from [i] outwards in direction (dr, dc) until the edge of an n×n board.
Iterable<int> _ray(int n, int i, int dr, int dc) sync* {
  var r = i ~/ n + dr, c = i % n + dc;
  while (r >= 0 && r < n && c >= 0 && c < n) {
    yield r * n + c;
    r += dr;
    c += dc;
  }
}

int? _step(int n, int i, int dr, int dc) {
  final r = i ~/ n + dr, c = i % n + dc;
  return r >= 0 && r < n && c >= 0 && c < n ? r * n + c : null;
}

Widget stone(Color c, {String label = '', double size = .8}) => FractionallySizedBox(
      widthFactor: size,
      heightFactor: size,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          border: Border.all(color: Colors.black45),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: label.isEmpty ? null : FittedBox(child: Padding(padding: const EdgeInsets.all(3), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ),
    );

/// A text-style chess glyph (︎ stops platforms turning ♟ into an emoji).
Widget glyph(String ch, Color c) => FittedBox(
      child: Text('$ch︎', style: TextStyle(fontSize: 40, height: 1.1, color: c, shadows: [Shadow(color: c == Colors.white ? Colors.black : Colors.white70, blurRadius: 3)])),
    );

Widget emoji(String e) => FittedBox(child: Padding(padding: const EdgeInsets.all(2), child: Text(e, style: const TextStyle(fontSize: 40))));

/// Board lines through the middle of a cell: [left, right, up, down] halves.
Widget gridLines(List<bool> f, Color bg) {
  Widget half(bool on, bool horiz) => Expanded(
        child: Center(child: on ? Container(width: horiz ? double.infinity : 1.5, height: horiz ? 1.5 : double.infinity, color: Colors.black87) : null),
      );
  return Container(
    color: bg,
    child: Stack(children: [
      Row(children: [half(f[0], true), half(f[1], true)]),
      Column(children: [half(f[2], false), half(f[3], false)]),
    ]),
  );
}

Widget passScreen(int player, String text, VoidCallback ready) => Container(
      color: duelColors[player].withValues(alpha: .25),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📱', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 24),
        FilledButton(onPressed: ready, child: Text("I'm ${duelNames[player]} — ready")),
      ]),
    );

// ---------- generic tap-to-move board ----------

/// Rules for a turn-based game on an n×n grid, driven by [ClassicBoard].
abstract class ClassicDuel {
  int get n;
  String get title;
  int turn = 0;
  int? forced; // piece that must keep moving (multi-jump, amazon's arrow)
  int? winner; // 0, 1, or 2 for a draw
  void next() => turn = 1 - turn;
  bool valid(int i) => true;
  List<int> movesFrom(int i) => const [];
  void play(int from, int to) {}
  bool tapEmpty(int i) => false; // placing / removing; true if a turn action happened
  Widget? pieceAt(int i) => null;
  Widget square(int i) => Container(color: (i ~/ n + i % n).isEven ? _light : _dark);
  String name(int p) => duelNames[p];
  String get status => "${name(turn)}'s turn";
  String? get info => null;
  String? get action => null;
  void doAction() {}
  String get endText => winner == 2 ? "It's a draw!" : '${name(winner!)} wins! 🎉';
  bool anyMove() => [for (var i = 0; i < n * n; i++) i].any((i) => movesFrom(i).isNotEmpty);
}

class ClassicBoard extends StatefulWidget {
  const ClassicBoard(this.create, {super.key});
  final ClassicDuel Function() create;
  @override
  State<ClassicBoard> createState() => _ClassicBoardState();
}

class _ClassicBoardState extends State<ClassicBoard> {
  late ClassicDuel g = widget.create();
  int? sel;
  List<int> targets = const [];

  void restart() => setState(() {
        g = widget.create();
        sel = null;
        targets = const [];
      });

  void after() {
    sfx('tap');
    setState(() {
      sel = g.forced;
      targets = sel == null ? const [] : g.movesFrom(sel!);
    });
    if (g.winner != null) showResult(context, g.endText, restart);
  }

  void tap(int i) {
    if (g.winner != null) return;
    if (sel != null && targets.contains(i)) {
      g.play(sel!, i);
      return after();
    }
    if (g.forced != null) return;
    if (g.tapEmpty(i)) return after();
    final m = g.movesFrom(i);
    setState(() {
      sel = m.isEmpty ? null : i;
      targets = m;
    });
  }

  @override
  Widget build(BuildContext context) => page(
        g.title,
        Column(children: [
          turnBanner(g.turn, g.status),
          if (g.info case final info?) Padding(padding: const EdgeInsets.all(6), child: Text(info, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(
            child: board(g.n, g.n * g.n, gap: 0, (i) {
              if (!g.valid(i)) return const SizedBox();
              return GestureDetector(
                onTap: () => tap(i),
                child: Stack(fit: StackFit.expand, children: [
                  g.square(i),
                  if (i == sel) Container(color: Colors.yellow.withValues(alpha: .45)),
                  if (g.pieceAt(i) case final p?) Center(child: p),
                  if (targets.contains(i))
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: .34,
                        heightFactor: .34,
                        child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent.withValues(alpha: .85))),
                      ),
                    ),
                ]),
              );
            }),
          ),
          if (g.action case final a?)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton.tonal(
                onPressed: g.winner == null
                    ? () {
                        g.doAction();
                        after();
                      }
                    : null,
                child: Text(a),
              ),
            ),
        ]),
      );
}

// ---------- Chess ----------

List<String> chess960Row(Random r) {
  final row = List.filled(8, '');
  row[r.nextInt(4) * 2] = 'B';
  row[r.nextInt(4) * 2 + 1] = 'B';
  List<int> free() => [for (var i = 0; i < 8; i++) if (row[i] == '') i];
  for (final p in ['Q', 'N', 'N']) {
    final f = free();
    row[f[r.nextInt(f.length)]] = p;
  }
  final f = free();
  row[f[0]] = 'R';
  row[f[1]] = 'K';
  row[f[2]] = 'R';
  return row;
}

/// Board: 64 strings, '' empty, uppercase white (player 0, bottom), lowercase black.
class Chess extends ClassicDuel {
  Chess({this.fischer = false}) {
    final back = fischer ? chess960Row(_r) : 'RNBQKBNR'.split('');
    for (var c = 0; c < 8; c++) {
      b[c] = back[c].toLowerCase();
      b[8 + c] = 'p';
      b[48 + c] = 'P';
      b[56 + c] = back[c];
    }
    rights = {for (var i = 0; i < 64; i++) if (b[i].toUpperCase() == 'R') i};
  }
  final bool fischer;
  List<String> b = List.filled(64, '');
  Set<int> rights = {}; // rook squares that may still castle
  int? ep; // en-passant target square

  @override
  int get n => 8;
  @override
  String get title => fischer ? 'Chess960' : 'Chess';
  @override
  String name(int p) => p == 0 ? 'White' : 'Black';
  @override
  String get status => '${name(turn)} to move${inCheck(turn) ? ' — check!' : ''}';
  @override
  String? get info => fischer ? 'Castle: king onto own rook' : null;

  static int side(String p) => p == '' ? -1 : (p == p.toUpperCase() ? 0 : 1);

  Iterable<int> _until(Iterable<int> ray) sync* {
    for (final j in ray) {
      yield j;
      if (b[j] != '') break;
    }
  }

  List<int> attacks(int i) {
    List<int> slide(List<(int, int)> dirs) => [for (final (dr, dc) in dirs) ..._until(_ray(8, i, dr, dc))];
    List<int> hop(List<(int, int)> dirs) => [for (final (dr, dc) in dirs) ..._ray(8, i, dr, dc).take(1)];
    return switch (b[i].toUpperCase()) {
      'N' => hop(_knight),
      'K' => hop([..._orth, ..._diag]),
      'B' => slide(_diag),
      'R' => slide(_orth),
      'Q' => slide([..._orth, ..._diag]),
      'P' => hop(side(b[i]) == 0 ? const [(-1, -1), (-1, 1)] : const [(1, -1), (1, 1)]),
      _ => const [],
    };
  }

  bool attacked(int sq, int by) => [for (var i = 0; i < 64; i++) i].any((i) => side(b[i]) == by && attacks(i).contains(sq));
  bool inCheck(int s) => attacked(b.indexOf(s == 0 ? 'K' : 'k'), 1 - s);

  List<int> pseudo(int i) {
    final s = side(b[i]);
    if (b[i].toUpperCase() != 'P') return [for (final t in attacks(i)) if (side(b[t]) != s) t];
    final dir = s == 0 ? -8 : 8, r = i ~/ 8, out = <int>[];
    if (b[i + dir] == '') {
      out.add(i + dir);
      if ((s == 0 && r == 6 || s == 1 && r == 1) && b[i + 2 * dir] == '') out.add(i + 2 * dir);
    }
    for (final t in attacks(i)) {
      if (side(b[t]) == 1 - s || t == ep) out.add(t);
    }
    return out;
  }

  void _shift(int from, int to) {
    if (b[from].toUpperCase() == 'P' && to == ep && b[to] == '') b[to + (side(b[from]) == 0 ? 8 : -8)] = '';
    b[to] = b[from];
    b[from] = '';
  }

  bool _intoCheck(int from, int to) {
    final saved = b.toList(), s = side(b[from]);
    _shift(from, to);
    final bad = inCheck(s);
    b = saved;
    return bad;
  }

  /// Castling moves for the king on [k]: tap target → rook square.
  /// Standard chess: target is the king's destination (c/g file). Chess960: target is the rook itself.
  Map<int, int> castles(int k) {
    final s = side(b[k]), row = s == 0 ? 56 : 0, out = <int, int>{};
    if (k ~/ 8 != row ~/ 8 || inCheck(s)) return out;
    for (final rook in rights) {
      if (rook ~/ 8 != row ~/ 8 || b[rook] != (s == 0 ? 'R' : 'r')) continue;
      final q = rook < k, kd = row + (q ? 2 : 6), rd = row + (q ? 3 : 5);
      final lo = [k, kd, rook, rd].reduce(min), hi = [k, kd, rook, rd].reduce(max);
      if ([for (var j = lo; j <= hi; j++) j].any((j) => j != k && j != rook && b[j] != '')) continue;
      if ([for (var j = min(k, kd); j <= max(k, kd); j++) j].any((j) => attacked(j, 1 - s))) continue;
      final saved = b.toList();
      b[k] = '';
      b[rook] = '';
      b[kd] = s == 0 ? 'K' : 'k';
      b[rd] = s == 0 ? 'R' : 'r';
      final ok = !inCheck(s);
      b = saved;
      if (ok) out[fischer ? rook : kd] = rook;
    }
    return out;
  }

  @override
  List<int> movesFrom(int i) {
    if (side(b[i]) != turn) return const [];
    final m = [for (final t in pseudo(i)) if (!_intoCheck(i, t)) t];
    if (b[i].toUpperCase() == 'K') m.addAll(castles(i).keys.where((t) => !m.contains(t)));
    return m;
  }

  @override
  void play(int from, int to) {
    final p = b[from], s = side(p), king = p.toUpperCase() == 'K';
    final rook = king ? castles(from)[to] : null;
    if (rook != null) {
      final row = s == 0 ? 56 : 0, q = rook < from;
      b[from] = '';
      b[rook] = '';
      b[row + (q ? 2 : 6)] = p;
      b[row + (q ? 3 : 5)] = s == 0 ? 'R' : 'r';
    } else {
      _shift(from, to);
      if (p.toUpperCase() == 'P' && (to < 8 || to >= 56)) b[to] = s == 0 ? 'Q' : 'q'; // ponytail: auto-queen, add a picker if under-promotion matters
    }
    ep = p.toUpperCase() == 'P' && (to - from).abs() == 16 ? (from + to) ~/ 2 : null;
    rights.removeWhere((r) => r == from || r == to || (king && r ~/ 8 == from ~/ 8));
    next();
    if (!anyMove()) {
      winner = inCheck(turn) ? 1 - turn : 2;
    } else if (b.where((x) => x != '').length == 2) {
      winner = 2; // bare kings
    }
  }

  @override
  Widget square(int i) {
    final checked = b[i].toUpperCase() == 'K' && side(b[i]) == turn && inCheck(turn);
    return Container(color: checked ? Colors.red.shade400 : ((i ~/ 8 + i % 8).isEven ? _light : _dark));
  }

  @override
  Widget? pieceAt(int i) => b[i] == '' ? null : glyph('♚♛♜♝♞♟'['KQRBNP'.indexOf(b[i].toUpperCase())], side(b[i]) == 0 ? Colors.white : Colors.black);
}

// ---------- Checkers ----------

/// 0 empty, 1/2 blue man/king (bottom, moves up), 3/4 red man/king.
class Checkers extends ClassicDuel {
  Checkers(this.n, {this.forcedCapture = true, this.giveaway = false}) {
    final rows = n == 10 ? 4 : 3;
    b = List.generate(n * n, (i) {
      final r = i ~/ n;
      if ((r + i % n).isEven) return 0;
      return r < rows ? 3 : (r >= n - rows ? 1 : 0);
    });
  }
  @override
  final int n;
  final bool forcedCapture, giveaway;
  late List<int> b;
  int quiet = 0; // plies without capture or crowning

  @override
  String get title => giveaway ? 'Giveaway Checkers' : (forcedCapture ? 'Checkers $n×$n' : 'Checkers Casual');
  @override
  String get status => forced != null ? '${name(turn)}: keep jumping!' : "${name(turn)}'s turn${giveaway ? ' — lose all to win' : ''}";

  static int owner(int v) => v == 0 ? -1 : (v <= 2 ? 0 : 1);

  List<(int, int)> dirs(int i) => b[i] == 2 || b[i] == 4 ? _diag : (owner(b[i]) == 0 ? const [(-1, 1), (-1, -1)] : const [(1, 1), (1, -1)]);

  List<int> jumps(int i) => [
        for (final (dr, dc) in dirs(i))
          if (_ray(n, i, dr, dc).take(2).toList() case [final o, final l] when owner(b[o]) == 1 - owner(b[i]) && b[l] == 0) l,
      ];

  List<int> steps(int i) => [
        for (final (dr, dc) in dirs(i))
          for (final t in _ray(n, i, dr, dc).take(1))
            if (b[t] == 0) t,
      ];

  @override
  List<int> movesFrom(int i) {
    if (owner(b[i]) != turn) return const [];
    if (forced != null) return i == forced ? jumps(i) : const [];
    final j = jumps(i);
    if (forcedCapture && j.isEmpty && [for (var k = 0; k < n * n; k++) k].any((k) => owner(b[k]) == turn && jumps(k).isNotEmpty)) return const [];
    return [...j, if (!forcedCapture || j.isEmpty) ...steps(i)];
  }

  @override
  void play(int from, int to) {
    final jump = (to ~/ n - from ~/ n).abs() == 2;
    if (jump) b[(from + to) ~/ 2] = 0;
    b[to] = b[from];
    b[from] = 0;
    final r = to ~/ n, crowned = (b[to] == 1 && r == 0) || (b[to] == 3 && r == n - 1);
    if (crowned) b[to]++;
    quiet = jump || crowned ? 0 : quiet + 1;
    if (jump && !crowned && jumps(to).isNotEmpty) {
      forced = to; // ponytail: multi-jumps are mandatory in every variant, incl. Casual
      return;
    }
    forced = null;
    next();
    if (!anyMove()) {
      winner = giveaway ? turn : 1 - turn;
    } else if (quiet >= 80) {
      winner = 2;
    }
  }

  @override
  Widget square(int i) => Container(color: (i ~/ n + i % n).isEven ? _light : const Color(0xFF8B5A2B));

  @override
  Widget? pieceAt(int i) => b[i] == 0 ? null : stone(duelColors[owner(b[i])].shade600, label: b[i].isEven ? '♛' : '');
}

// ---------- Go ----------

class Go extends ClassicDuel {
  Go(this.n) : b = List.filled(n * n, -1);
  @override
  final int n;
  List<int> b; // -1 empty, 0 black, 1 white
  String? ko; // position before the last move; recreating it is illegal
  int passes = 0;
  final caps = [0, 0];
  String result = '';

  @override
  String get title => 'Go $n×$n';
  @override
  String name(int p) => p == 0 ? 'Black' : 'White';
  @override
  String get status => '${name(turn)} to play${passes == 1 ? ' (opponent passed)' : ''}';
  @override
  String? get info => 'Captures ⚫${caps[0]} ⚪${caps[1]}';
  @override
  String? get action => 'Pass';
  @override
  String get endText => '${super.endText}\n$result';

  (Set<int>, Set<int>) group(int i) {
    final stones = {i}, libs = <int>{}, stack = [i];
    while (stack.isNotEmpty) {
      final j = stack.removeLast();
      for (final (dr, dc) in _orth) {
        final k = _step(n, j, dr, dc);
        if (k == null) continue;
        if (b[k] == -1) {
          libs.add(k);
        } else if (b[k] == b[i] && stones.add(k)) {
          stack.add(k);
        }
      }
    }
    return (stones, libs);
  }

  @override
  bool tapEmpty(int i) {
    if (b[i] != -1) return false;
    final before = b.toList();
    b[i] = turn;
    var taken = 0;
    for (final (dr, dc) in _orth) {
      final k = _step(n, i, dr, dc);
      if (k == null || b[k] != 1 - turn) continue;
      final (stones, libs) = group(k);
      if (libs.isNotEmpty) continue;
      for (final s in stones) {
        b[s] = -1;
      }
      taken += stones.length;
    }
    if (group(i).$2.isEmpty || b.join(',') == ko) {
      b = before; // suicide or ko
      sfx('wrong');
      return false;
    }
    ko = before.join(',');
    caps[turn] += taken;
    passes = 0;
    next();
    return true;
  }

  @override
  void doAction() {
    passes++;
    ko = null;
    next();
    if (passes < 2) return;
    final (black, white) = score();
    result = 'Black $black – White $white (komi 6.5)';
    winner = black > white ? 0 : 1;
  }

  /// Area scoring: stones + empty regions bordered by one colour only; white gets 6.5 komi.
  (double, double) score() {
    var black = 0.0, white = 6.5;
    final seen = <int>{};
    for (var i = 0; i < n * n; i++) {
      if (b[i] == 0) {
        black++;
      } else if (b[i] == 1) {
        white++;
      } else if (seen.add(i)) {
        final region = {i}, stack = [i], border = <int>{};
        while (stack.isNotEmpty) {
          final j = stack.removeLast();
          for (final (dr, dc) in _orth) {
            final k = _step(n, j, dr, dc);
            if (k == null) continue;
            if (b[k] == -1) {
              if (region.add(k)) stack.add(k);
            } else {
              border.add(b[k]);
            }
          }
        }
        seen.addAll(region);
        if (border.length == 1) border.first == 0 ? black += region.length : white += region.length;
      }
    }
    return (black, white);
  }

  @override
  Widget square(int i) => gridLines([i % n > 0, i % n < n - 1, i ~/ n > 0, i ~/ n < n - 1], _wood);

  @override
  Widget? pieceAt(int i) => b[i] < 0 ? null : stone(b[i] == 0 ? Colors.black : Colors.white, size: .92);
}

// ---------- Men's Morris ----------

class Morris extends ClassicDuel {
  Morris._(this.n, this.points, this.adj, this.mills, int pieces, this.fly, this.millWins, this.title) : inHand = [pieces, pieces] {
    for (final e in adj.entries) {
      for (final t in e.value) {
        final a = e.key, ra = a ~/ n, ca = a % n, rb = t ~/ n, cb = t % n;
        if (ra == rb) {
          for (var c = min(ca, cb); c <= max(ca, cb); c++) {
            final f = lines[ra * n + c] ??= [false, false, false, false];
            if (c > min(ca, cb)) f[0] = true;
            if (c < max(ca, cb)) f[1] = true;
          }
        } else if (ca == cb) {
          for (var r = min(ra, rb); r <= max(ra, rb); r++) {
            final f = lines[r * n + ca] ??= [false, false, false, false];
            if (r > min(ra, rb)) f[2] = true;
            if (r < max(ra, rb)) f[3] = true;
          }
        }
      }
    }
  }

  static List<int> ring(int m, int d) {
    final mid = m ~/ 2, e = m - 1 - d;
    return [for (final (r, c) in [(d, d), (d, mid), (d, e), (mid, e), (e, e), (e, mid), (e, d), (mid, d)]) r * m + c];
  }

  factory Morris._rings(int m, int k, int pieces, String title, {bool fly = false}) {
    final rings = [for (var d = 0; d < k; d++) ring(m, d)], adj = <int, List<int>>{}, mills = <List<int>>[];
    void link(int a, int b) {
      (adj[a] ??= []).add(b);
      (adj[b] ??= []).add(a);
    }

    for (final ring in rings) {
      for (var j = 0; j < 8; j++) {
        link(ring[j], ring[(j + 1) % 8]);
      }
      for (var j = 0; j < 8; j += 2) {
        mills.add([ring[j], ring[j + 1], ring[(j + 2) % 8]]);
      }
    }
    for (var j = 1; j < 8; j += 2) {
      for (var d = 0; d + 1 < k; d++) {
        link(rings[d][j], rings[d + 1][j]);
      }
      if (k == 3) mills.add([for (final ring in rings) ring[j]]);
    }
    return Morris._(m, [for (final r in rings) ...r], adj, mills, pieces, fly, false, title);
  }

  factory Morris.nine() => Morris._rings(7, 3, 9, "Nine Men's Morris", fly: true);
  factory Morris.six() => Morris._rings(5, 2, 6, "Six Men's Morris");
  factory Morris.three() => Morris._(
        3,
        List.generate(9, (i) => i),
        {
          for (var i = 0; i < 9; i++)
            i: [
              for (final (dr, dc) in [..._orth, ..._diag])
                if (_step(3, i, dr, dc) case final t? when i == 4 || t == 4 || dr == 0 || dc == 0) t,
            ],
        },
        const [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]],
        3,
        false,
        true,
        "Three Men's Morris",
      );

  @override
  final int n;
  @override
  final String title;
  final List<int> points;
  final Map<int, List<int>> adj;
  final List<List<int>> mills;
  final bool fly, millWins;
  final List<int> inHand;
  final owner = <int, int>{};
  final lines = <int, List<bool>>{};
  bool removing = false;

  int count(int p) => owner.values.where((o) => o == p).length;
  bool inMill(int pt) => mills.any((m) => m.contains(pt) && m.every((x) => owner[x] == owner[pt]));

  @override
  String get status {
    if (removing) return '${name(turn)}: remove a ${name(1 - turn)} piece';
    if (inHand[turn] > 0) return '${name(turn)}: place a piece (${inHand[turn]} left)';
    return '${name(turn)}: move a piece${fly && count(turn) == 3 ? ' (flying!)' : ''}';
  }

  @override
  bool tapEmpty(int i) {
    if (!points.contains(i)) return false;
    if (removing) {
      if (owner[i] != 1 - turn) return false;
      final theirs = [for (final p in points) if (owner[p] == 1 - turn) p];
      if (inMill(i) && !theirs.every(inMill)) return false;
      owner.remove(i);
      removing = false;
      endTurn();
      return true;
    }
    if (inHand[turn] == 0 || owner.containsKey(i)) return false;
    owner[i] = turn;
    inHand[turn]--;
    landed(i);
    return true;
  }

  @override
  List<int> movesFrom(int i) {
    if (removing || inHand[turn] > 0 || owner[i] != turn) return const [];
    return [for (final p in fly && count(turn) == 3 ? points : adj[i]!) if (!owner.containsKey(p)) p];
  }

  @override
  void play(int from, int to) {
    owner.remove(from);
    owner[to] = turn;
    landed(to);
  }

  void landed(int pt) {
    if (!inMill(pt)) return endTurn();
    if (millWins) {
      winner = turn;
    } else {
      removing = true;
    }
  }

  void endTurn() {
    final o = 1 - turn;
    if (!millWins && count(o) + inHand[o] < 3) {
      winner = turn;
      return;
    }
    next();
    if (inHand[turn] == 0 && !anyMove()) winner = 1 - turn;
  }

  @override
  Widget square(int i) => gridLines(lines[i] ?? const [false, false, false, false], _wood);

  @override
  Widget? pieceAt(int i) {
    final o = owner[i];
    if (o != null) return stone(duelColors[o].shade600);
    return points.contains(i) ? stone(Colors.black87, size: .25) : null;
  }
}

// ---------- Quoridor ----------

class Quoridor extends ClassicDuel {
  Quoridor(this.n, int wallsEach)
      : pawns = [(n - 1) * n + n ~/ 2, n ~/ 2],
        walls = [wallsEach, wallsEach];
  @override
  final int n;
  final List<int> pawns, walls;
  final h = <int>{}, v = <int>{}; // wall anchors: h under (r,c)+(r,c+1); v right of (r,c)+(r+1,c)
  int mode = 0; // 0 move, 1 horizontal wall, 2 vertical wall

  @override
  String get title => 'Quoridor $n×$n';
  @override
  String get status => mode == 0 ? '${name(turn)}: move (reach the far side)' : '${name(turn)}: tap a square to put a wall ${mode == 1 ? 'under' : 'right of'} it';
  @override
  String? get info => 'Walls 🔵${walls[0]} 🔴${walls[1]}';
  @override
  String? get action => ['Mode: Move', 'Mode: Wall ─', 'Mode: Wall │'][mode];
  @override
  void doAction() => mode = (mode + 1) % 3;

  bool blocked(int a, int b) {
    final ra = a ~/ n, ca = a % n, rb = b ~/ n, cb = b % n;
    if (ra == rb) {
      final c = min(ca, cb);
      return v.contains(ra * n + c) || (ra > 0 && v.contains((ra - 1) * n + c));
    }
    final r = min(ra, rb);
    return h.contains(r * n + ca) || (ca > 0 && h.contains(r * n + ca - 1));
  }

  List<int> pawnMoves(int p) {
    final me = pawns[p], opp = pawns[1 - p], out = <int>[];
    for (final (dr, dc) in _orth) {
      final t = _step(n, me, dr, dc);
      if (t == null || blocked(me, t)) continue;
      if (t != opp) {
        out.add(t);
        continue;
      }
      final j = _step(n, t, dr, dc);
      if (j != null && !blocked(t, j)) {
        out.add(j);
        continue;
      }
      for (final (er, ec) in dr == 0 ? const [(1, 0), (-1, 0)] : const [(0, 1), (0, -1)]) {
        final s = _step(n, t, er, ec);
        if (s != null && s != me && !blocked(t, s)) out.add(s);
      }
    }
    return out;
  }

  bool hasPath(int p) {
    final goal = p == 0 ? 0 : n - 1, seen = {pawns[p]}, queue = [pawns[p]];
    for (var q = 0; q < queue.length; q++) {
      final i = queue[q];
      if (i ~/ n == goal) return true;
      for (final (dr, dc) in _orth) {
        final t = _step(n, i, dr, dc);
        if (t != null && !blocked(i, t) && seen.add(t)) queue.add(t);
      }
    }
    return false;
  }

  bool canWall(bool horiz, int a) {
    if (a ~/ n >= n - 1 || a % n >= n - 1) return false;
    if (horiz ? (h.contains(a) || h.contains(a - 1) || h.contains(a + 1) || v.contains(a)) : (v.contains(a) || v.contains(a - n) || v.contains(a + n) || h.contains(a))) return false;
    final set = horiz ? h : v;
    set.add(a);
    final ok = hasPath(0) && hasPath(1);
    set.remove(a);
    return ok;
  }

  @override
  bool tapEmpty(int i) {
    if (mode == 0) return false;
    if (walls[turn] == 0 || !canWall(mode == 1, i)) {
      sfx('wrong');
      return false;
    }
    (mode == 1 ? h : v).add(i);
    walls[turn]--;
    mode = 0;
    next();
    return true;
  }

  @override
  List<int> movesFrom(int i) => mode == 0 && i == pawns[turn] ? pawnMoves(turn) : const [];

  @override
  void play(int from, int to) {
    pawns[turn] = to;
    if (to ~/ n == (turn == 0 ? 0 : n - 1)) winner = turn;
    next();
  }

  @override
  Widget square(int i) {
    final r = i ~/ n, c = i % n;
    const wall = BorderSide(color: Colors.amber, width: 4), thin = BorderSide(color: Colors.black26);
    return Container(
      decoration: BoxDecoration(
        color: r == 0 ? duelColors[0].shade900 : (r == n - 1 ? duelColors[1].shade900 : Colors.brown.shade700),
        border: Border(
          right: v.contains(i) || (r > 0 && v.contains(i - n)) ? wall : thin,
          bottom: h.contains(i) || (c > 0 && h.contains(i - 1)) ? wall : thin,
        ),
      ),
    );
  }

  @override
  Widget? pieceAt(int i) => i == pawns[0] ? stone(duelColors[0]) : (i == pawns[1] ? stone(duelColors[1]) : null);
}

// ---------- Hnefatafl family ----------

/// 0 empty, 1 attacker (player 0, moves first), 2 defender, 3 king (player 1).
class Tafl extends ClassicDuel {
  Tafl(this.n) : b = List.filled(n * n, 0) {
    final m = n ~/ 2;
    void put(int r, int c, int v) => b[r * n + c] = v;
    put(m, m, 3);
    for (final k in n == 9 ? [1, 2] : [1]) {
      put(m - k, m, 2);
      put(m + k, m, 2);
      put(m, m - k, 2);
      put(m, m + k, 2);
    }
    for (final (d, o) in n == 9 ? const [(0, -1), (0, 0), (0, 1), (1, 0)] : const [(0, 0), (1, 0)]) {
      put(d, m + o, 1);
      put(n - 1 - d, m + o, 1);
      put(m + o, d, 1);
      put(m + o, n - 1 - d, 1);
    }
  }
  @override
  final int n;
  final List<int> b;
  int get throne => n * n ~/ 2;
  List<int> get corners => [0, n - 1, n * (n - 1), n * n - 1];
  bool restricted(int i) => i == throne || corners.contains(i);
  bool escaped(int i) => n == 9 ? (i ~/ n == 0 || i ~/ n == n - 1 || i % n == 0 || i % n == n - 1) : corners.contains(i);
  static int owner(int v) => v == 0 ? -1 : (v == 1 ? 0 : 1);

  @override
  String get title => n == 9 ? 'Tablut' : 'Brandubh';
  @override
  String name(int p) => p == 0 ? 'Attackers' : 'Defenders';
  @override
  String? get info => n == 9 ? 'King escapes to any edge' : 'King escapes to a corner';

  @override
  List<int> movesFrom(int i) {
    if (owner(b[i]) != turn) return const [];
    final out = <int>[];
    for (final (dr, dc) in _orth) {
      for (final t in _ray(n, i, dr, dc)) {
        if (b[t] != 0 || (b[i] != 3 && restricted(t))) break;
        out.add(t);
      }
    }
    return out;
  }

  bool kingTaken(int k) {
    final nb = [for (final (dr, dc) in _orth) _step(n, k, dr, dc)];
    if (k == throne || nb.contains(throne)) return nb.every((x) => x != null && (b[x] == 1 || x == throne));
    bool hostile(int? x) => x != null && (b[x] == 1 || (restricted(x) && b[x] == 0));
    return (hostile(nb[0]) && hostile(nb[1])) || (hostile(nb[2]) && hostile(nb[3]));
  }

  @override
  void play(int from, int to) {
    b[to] = b[from];
    b[from] = 0;
    for (final (dr, dc) in _orth) {
      final a = _step(n, to, dr, dc), z = a == null ? null : _step(n, a, dr, dc);
      if (a != null && z != null && b[a] != 3 && owner(b[a]) == 1 - turn && (owner(b[z]) == turn || (restricted(z) && b[z] == 0))) b[a] = 0;
    }
    if (turn == 0 && kingTaken(b.indexOf(3))) {
      winner = 0;
    } else if (b[to] == 3 && escaped(to)) {
      winner = 1;
    } else {
      next();
      if (!anyMove()) winner = 1 - turn;
    }
  }

  @override
  Widget square(int i) => Container(
        decoration: BoxDecoration(
          color: restricted(i) ? Colors.brown.shade800 : ((i ~/ n + i % n).isEven ? _light : const Color(0xFFD9BF8C)),
          border: Border.all(color: Colors.black12),
        ),
      );

  @override
  Widget? pieceAt(int i) => switch (b[i]) {
        1 => stone(duelColors[0].shade700),
        2 => stone(duelColors[1].shade600),
        3 => stone(Colors.amber.shade700, label: '♚'),
        _ => null,
      };
}

// ---------- Breakthrough ----------

class Breakthrough extends ClassicDuel {
  Breakthrough(this.n) : b = List.generate(n * n, (i) => i < 2 * n ? 1 : (i >= n * n - 2 * n ? 0 : -1));
  @override
  final int n;
  final List<int> b; // -1 empty, 0 blue (bottom, moves up), 1 red

  @override
  String get title => 'Breakthrough $n×$n';
  @override
  String? get info => 'Reach the far row';

  @override
  List<int> movesFrom(int i) {
    if (b[i] != turn) return const [];
    return [
      for (final dc in [-1, 0, 1])
        for (final t in _ray(n, i, turn == 0 ? -1 : 1, dc).take(1))
          if (dc == 0 ? b[t] == -1 : b[t] != turn) t,
    ];
  }

  @override
  void play(int from, int to) {
    b[to] = turn;
    b[from] = -1;
    if (to ~/ n == (turn == 0 ? 0 : n - 1) || !b.contains(1 - turn)) {
      winner = turn;
      return;
    }
    next();
    if (!anyMove()) winner = 1 - turn;
  }

  @override
  Widget? pieceAt(int i) => b[i] < 0 ? null : stone(duelColors[b[i]].shade600);
}

// ---------- Amazons ----------

class Amazons extends ClassicDuel {
  Amazons(this.n) : b = List.filled(n * n, -1) {
    final start = n == 6 ? const [(5, 1), (5, 4)] : const [(5, 0), (7, 2), (7, 5), (5, 7)];
    for (final (r, c) in start) {
      b[r * n + c] = 0;
      b[(n - 1 - r) * n + c] = 1;
    }
  }
  @override
  final int n;
  final List<int> b; // -1 empty, 0/1 amazon, 2 arrow

  @override
  String get title => 'Amazons $n×$n';
  @override
  String get status => forced != null ? '${name(turn)}: shoot an arrow' : '${name(turn)}: move an amazon';
  @override
  String? get info => 'Last player able to move wins';

  List<int> reach(int i) => [
        for (final (dr, dc) in [..._orth, ..._diag])
          for (final t in _ray(n, i, dr, dc).takeWhile((t) => b[t] == -1)) t,
      ];

  @override
  List<int> movesFrom(int i) => (forced == null && b[i] == turn) || i == forced ? reach(i) : const [];

  @override
  void play(int from, int to) {
    if (forced == null) {
      b[to] = b[from];
      b[from] = -1;
      forced = to;
      return;
    }
    b[to] = 2;
    forced = null;
    next();
    if (!anyMove()) winner = 1 - turn;
  }

  @override
  Widget? pieceAt(int i) => switch (b[i]) {
        0 || 1 => stone(duelColors[b[i]].shade600, label: '♛'),
        2 => stone(Colors.black87, size: .45),
        _ => null,
      };
}

// ---------- Fox and Geese ----------

class FoxGeese extends ClassicDuel {
  FoxGeese() {
    for (var i = 0; i < 49; i++) {
      if (valid(i) && i ~/ 7 <= 2) b[i] = 0;
    }
    b[4 * 7 + 3] = 1;
  }
  final b = List.filled(49, -1); // -1 empty, 0 goose, 1 fox

  @override
  int get n => 7;
  @override
  String get title => 'Fox and Geese';
  @override
  String name(int p) => p == 0 ? 'Geese' : 'Fox';
  @override
  String get status => turn == 0 ? 'Geese: step down or sideways' : 'Fox: step or jump a goose';
  @override
  String? get info => 'Geese ${b.where((x) => x == 0).length} (fox wins below 6)';
  @override
  bool valid(int i) => (i ~/ 7 >= 2 && i ~/ 7 <= 4) || (i % 7 >= 2 && i % 7 <= 4);

  @override
  List<int> movesFrom(int i) {
    if (b[i] != turn) return const [];
    final out = <int>[];
    for (final (dr, dc) in turn == 0 ? const [(1, 0), (0, 1), (0, -1)] : _orth) {
      final t = _step(7, i, dr, dc);
      if (t == null || !valid(t)) continue;
      if (b[t] == -1) {
        out.add(t);
      } else if (turn == 1 && b[t] == 0) {
        final j = _step(7, t, dr, dc);
        if (j != null && valid(j) && b[j] == -1) out.add(j);
      }
    }
    return out;
  }

  // ponytail: orthogonal moves only and one jump per turn; add diagonals/multi-jumps for the full classic board.
  @override
  void play(int from, int to) {
    if ((to ~/ 7 - from ~/ 7).abs() == 2 || (to % 7 - from % 7).abs() == 2) b[(from + to) ~/ 2] = -1;
    b[to] = b[from];
    b[from] = -1;
    next();
    if (b.where((x) => x == 0).length < 6) {
      winner = 1;
    } else if (!anyMove()) {
      winner = 1 - turn;
    }
  }

  @override
  Widget square(int i) => Container(decoration: BoxDecoration(color: Colors.green.shade800, border: Border.all(color: Colors.green.shade900)));

  @override
  Widget? pieceAt(int i) => switch (b[i]) {
        0 => stone(Colors.white),
        1 => emoji('🦊'),
        _ => null,
      };
}

// ---------- Konane ----------

class Konane extends ClassicDuel {
  Konane(this.n) : b = List.generate(n * n, (i) => (i ~/ n + i % n) % 2) {
    final m = (n ~/ 2 - 1) * n + n ~/ 2 - 1;
    b[m] = -1; // ponytail: opening removals are automatic (two centre stones)
    b[m + 1] = -1;
  }
  @override
  final int n;
  final List<int> b;

  @override
  String get title => 'Konane $n×$n';
  @override
  String? get info => 'Jump in a straight line; no move = you lose';

  @override
  List<int> movesFrom(int i) {
    if (b[i] != turn) return const [];
    final out = <int>[];
    for (final (dr, dc) in _orth) {
      final path = _ray(n, i, dr, dc).toList();
      for (var k = 0; k + 1 < path.length && b[path[k]] == 1 - turn && b[path[k + 1]] == -1; k += 2) {
        out.add(path[k + 1]);
      }
    }
    return out;
  }

  @override
  void play(int from, int to) {
    final step = from ~/ n == to ~/ n ? (to > from ? 1 : -1) : (to > from ? n : -n);
    for (var j = from; j != to; j += step) {
      b[j] = -1;
    }
    b[to] = turn;
    next();
    if (!anyMove()) winner = 1 - turn;
  }

  @override
  Widget? pieceAt(int i) => b[i] < 0 ? null : stone(b[i] == 0 ? Colors.black : Colors.white);
  @override
  String name(int p) => p == 0 ? 'Black' : 'White';
}

// ---------- Lines of Action ----------

bool loaConnected(List<int> b, int n, int p) {
  final mine = [for (var i = 0; i < b.length; i++) if (b[i] == p) i];
  if (mine.isEmpty) return false;
  final seen = {mine.first}, stack = [mine.first];
  while (stack.isNotEmpty) {
    final i = stack.removeLast();
    for (final (dr, dc) in [..._orth, ..._diag]) {
      final t = _step(n, i, dr, dc);
      if (t != null && b[t] == p && seen.add(t)) stack.add(t);
    }
  }
  return seen.length == mine.length;
}

class LinesOfAction extends ClassicDuel {
  LinesOfAction() {
    for (var k = 1; k < 7; k++) {
      b[k] = 0;
      b[56 + k] = 0;
      b[k * 8] = 1;
      b[k * 8 + 7] = 1;
    }
  }
  final b = List.filled(64, -1);

  @override
  int get n => 8;
  @override
  String get title => 'Lines of Action';
  @override
  String? get info => 'Move exactly as far as pieces on that line. Connect all yours!';

  int line(int i, int dr, int dc) => 1 + [..._ray(8, i, dr, dc), ..._ray(8, i, -dr, -dc)].where((j) => b[j] >= 0).length;

  @override
  List<int> movesFrom(int i) {
    if (b[i] != turn) return const [];
    final out = <int>[];
    for (final (dr, dc) in [..._orth, ..._diag]) {
      final d = line(i, dr, dc), path = _ray(8, i, dr, dc).take(d).toList();
      if (path.length < d || path.take(d - 1).any((j) => b[j] == 1 - turn) || b[path.last] == turn) continue;
      out.add(path.last);
    }
    return out;
  }

  @override
  void play(int from, int to) {
    b[to] = b[from];
    b[from] = -1;
    if (loaConnected(b, 8, turn)) {
      winner = turn; // mover wins even if both connect
    } else if (loaConnected(b, 8, 1 - turn)) {
      winner = 1 - turn;
    } else {
      next();
      if (!anyMove()) winner = 1 - turn;
    }
  }

  @override
  Widget? pieceAt(int i) => b[i] < 0 ? null : stone(duelColors[b[i]].shade600);
}

// ---------- Battleship ----------

/// Random non-overlapping fleet: ship id per cell, -1 for water.
List<int> placeFleet(int n, List<int> sizes, Random r) {
  final f = List.filled(n * n, -1);
  for (var id = 0; id < sizes.length; id++) {
    while (true) {
      final horiz = r.nextBool(), len = sizes[id];
      final r0 = r.nextInt(horiz ? n : n - len + 1), c0 = r.nextInt(horiz ? n - len + 1 : n);
      final cells = [for (var k = 0; k < len; k++) horiz ? r0 * n + c0 + k : (r0 + k) * n + c0];
      if (cells.every((c) => f[c] == -1)) {
        for (final c in cells) {
          f[c] = id;
        }
        break;
      }
    }
  }
  return f;
}

class Battleship extends StatefulWidget {
  const Battleship(this.n, this.ships, {super.key});
  final int n;
  final List<int> ships;
  @override
  State<Battleship> createState() => _BattleshipState();
}

class _BattleshipState extends State<Battleship> {
  late List<List<int>> fleet;
  final shots = [<int>{}, <int>{}]; // shots fired AT player p
  int turn = 0;
  bool passing = true, busy = false;
  String msg = '';
  int get n => widget.n;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    fleet = [placeFleet(n, widget.ships, _r), placeFleet(n, widget.ships, _r)];
    shots[0].clear();
    shots[1].clear();
    turn = 0;
    passing = true;
    busy = false;
    msg = '';
  }

  Future<void> fire(int i) async {
    final foe = 1 - turn, f = fleet[foe], id = f[i];
    if (busy || shots[foe].contains(i)) return;
    setState(() {
      shots[foe].add(i);
      busy = true;
      msg = id < 0 ? 'Miss' : ([for (var j = 0; j < n * n; j++) if (f[j] == id) j].every(shots[foe].contains) ? 'Sunk! 💥' : 'Hit! 🔥');
    });
    sfx(id < 0 ? 'wrong' : 'right');
    if ([for (var j = 0; j < n * n; j++) if (f[j] >= 0) j].every(shots[foe].contains)) {
      showWinner(context, turn, () => setState(start));
      return;
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      turn = foe;
      passing = true;
      busy = false;
      msg = '';
    });
  }

  Widget grid(int owner, {required bool reveal, void Function(int)? onTap}) => Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: board(n, n * n, gap: 2, (i) {
            final hit = shots[owner].contains(i), ship = fleet[owner][i] >= 0;
            return GestureDetector(
              onTap: onTap == null ? null : () => onTap(i),
              child: Container(
                alignment: Alignment.center,
                color: hit ? (ship ? Colors.red.shade700 : Colors.blueGrey.shade600) : (reveal && ship ? Colors.grey.shade500 : Colors.blue.shade900),
                child: hit ? FittedBox(child: Text(ship ? '🔥' : '•')) : null,
              ),
            );
          }),
        ),
      );

  @override
  Widget build(BuildContext context) => page(
        'Battleship $n×$n',
        passing
            ? passScreen(turn, 'Pass the phone to ${duelNames[turn]}', () => setState(() => passing = false))
            : Column(children: [
                turnBanner(turn, '${duelNames[turn]}: fire at the enemy fleet'),
                Expanded(flex: 3, child: grid(1 - turn, reveal: false, onTap: fire)),
                Text(msg.isEmpty ? ' ' : msg, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('Your fleet', style: TextStyle(color: Colors.white70)),
                Expanded(flex: 2, child: grid(turn, reveal: true)),
              ]),
      );
}

// ---------- Memory Duel ----------

class MemoryDuel extends StatefulWidget {
  const MemoryDuel(this.cols, this.rows, {super.key});
  final int cols, rows;
  @override
  State<MemoryDuel> createState() => _MemoryDuelState();
}

class _MemoryDuelState extends State<MemoryDuel> {
  static const emojis = ['🐶', '🐱', '🦊', '🐼', '🐸', '🐵', '🦁', '🐙', '🦄', '🐝', '🐢', '🐧', '🍎', '🍕', '🚀', '⚽', '🎸', '🌈'];
  late List<String> cards;
  final open = <int>[], owner = <int, int>{}, score = [0, 0];
  int turn = 0;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    final picks = (emojis.toList()..shuffle(_r)).take(widget.cols * widget.rows ~/ 2);
    cards = [...picks, ...picks]..shuffle(_r);
    open.clear();
    owner.clear();
    score.fillRange(0, 2, 0);
    turn = 0;
  }

  void tap(int i) {
    if (open.length == 2 || open.contains(i) || owner.containsKey(i)) return;
    setState(() => open.add(i));
    if (open.length < 2) return;
    if (cards[open[0]] == cards[open[1]]) {
      sfx('right');
      setState(() {
        for (final j in open) {
          owner[j] = turn;
        }
        score[turn]++;
        open.clear();
      });
      if (owner.length == cards.length) showWinner(context, score[0] == score[1] ? null : (score[0] > score[1] ? 0 : 1), () => setState(start));
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          open.clear();
          turn = 1 - turn;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) => page(
        'Memory Duel',
        Column(children: [
          turnBanner(turn, "${duelNames[turn]}'s turn — a match plays again"),
          Expanded(
            child: board(widget.cols, cards.length, (i) {
              final o = owner[i], up = open.contains(i) || o != null;
              return tile(o != null ? duelColors[o].shade700 : (up ? Colors.indigo : Colors.blueGrey.shade700), text: up ? cards[i] : '', onTap: () => tap(i));
            }),
          ),
        ]),
        '🔵${score[0]}  🔴${score[1]}',
      );
}

// ---------- Hangman Duel ----------

class HangmanDuel extends StatefulWidget {
  const HangmanDuel({super.key});
  @override
  State<HangmanDuel> createState() => _HangmanDuelState();
}

class _HangmanDuelState extends State<HangmanDuel> {
  static const lives = 6;
  final ctrl = TextEditingController();
  final guessed = <String>{}, points = [0, 0];
  int round = 0; // round 0: Blue sets, Red guesses; round 1: swapped
  String phase = 'set', word = '', last = '';
  String? error;
  int get setter => round;
  int get guesser => 1 - round;
  int get wrong => guessed.where((l) => !word.contains(l)).length;
  bool get solved => word.split('').every(guessed.contains);

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void restart() => setState(() {
        round = 0;
        phase = 'set';
        last = '';
        points.fillRange(0, 2, 0);
      });

  void setWord() {
    final w = ctrl.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3,12}$').hasMatch(w)) return setState(() => error = '3–12 letters, A–Z only');
    setState(() {
      word = w;
      error = null;
      ctrl.clear();
      guessed.clear();
      phase = 'pass';
    });
  }

  void guess(String l) {
    if (guessed.contains(l)) return;
    sfx(word.contains(l) ? 'right' : 'wrong');
    setState(() => guessed.add(l));
    if (!solved && wrong < lives) return;
    if (solved) points[guesser] += lives - wrong + 1;
    final msg = solved ? '${duelNames[guesser]} guessed "$word"!' : 'The word was "$word".';
    if (round == 0) {
      setState(() {
        round = 1;
        phase = 'set';
        last = msg;
      });
      return;
    }
    final w = points[0] == points[1] ? "It's a draw!" : '${duelNames[points[0] > points[1] ? 0 : 1]} wins! 🎉';
    showResult(context, '$msg\n\nBlue ${points[0]} – Red ${points[1]}\n$w', restart);
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (phase) {
      'set' => ListView(padding: const EdgeInsets.all(24), children: [
          if (last.isNotEmpty) Text(last, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Text('${duelNames[setter]}: type a secret word.\n${duelNames[guesser]}, look away!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            obscureText: true,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'Secret word', errorText: error),
            onSubmitted: (_) => setWord(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: setWord, child: const Text('Hide & pass')),
        ]),
      'pass' => passScreen(guesser, 'Pass the phone to ${duelNames[guesser]}', () => setState(() => phase = 'guess')),
      _ => Column(children: [
          turnBanner(guesser, '${duelNames[guesser]}: guess the word'),
          const SizedBox(height: 16),
          Text('${'❤️' * (lives - wrong)}${'🖤' * wrong}', style: const TextStyle(fontSize: 24)),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FittedBox(child: Text(word.split('').map((l) => guessed.contains(l) ? l : '_').join(' '), style: const TextStyle(fontSize: 40, letterSpacing: 2))),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: [
              for (final l in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
                SizedBox(
                  width: 40,
                  height: 44,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: guessed.contains(l) ? (word.contains(l) ? Colors.green.shade800 : Colors.red.shade900) : null),
                    onPressed: guessed.contains(l) ? null : () => guess(l),
                    child: Text(l),
                  ),
                ),
            ]),
          ),
        ]),
    };
    return page('Hangman Duel', body, 'Round ${round + 1}/2 · 🔵${points[0]} 🔴${points[1]}');
  }
}

// ---------- Mastermind Duel ----------

class MastermindDuel extends StatefulWidget {
  const MastermindDuel({super.key});
  @override
  State<MastermindDuel> createState() => _MastermindDuelState();
}

class _MastermindDuelState extends State<MastermindDuel> {
  static const colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
  static const maxGuesses = 10;
  final cur = <int>[], guesses = <(List<int>, (int, int))>[], used = [0, 0];
  List<int> code = [];
  int round = 0; // round 0: Blue sets, Red guesses
  String phase = 'set', last = '';
  int get setter => round;
  int get guesser => 1 - round;

  void confirmCode() => setState(() {
        code = cur.toList();
        cur.clear();
        guesses.clear();
        phase = 'pass';
      });

  void check() {
    final fb = mastermindScore(code, cur);
    setState(() {
      guesses.add((cur.toList(), fb));
      cur.clear();
    });
    sfx(fb.$1 == 4 ? 'right' : 'tap');
    if (fb.$1 == 4) {
      finish(guesses.length);
    } else if (guesses.length == maxGuesses) {
      finish(maxGuesses + 1);
    }
  }

  void finish(int k) {
    used[guesser] = k;
    final msg = k > maxGuesses ? '${duelNames[guesser]} failed to crack it.' : '${duelNames[guesser]} cracked it in $k.';
    if (round == 0) {
      setState(() {
        round = 1;
        phase = 'set';
        last = msg;
      });
      return;
    }
    final w = used[0] == used[1] ? "It's a draw!" : '${duelNames[used[0] < used[1] ? 0 : 1]} wins! 🎉';
    showResult(context, '$msg\n\nGuesses — Blue ${used[0]}, Red ${used[1]}\n$w', () => setState(() {
          round = 0;
          phase = 'set';
          last = '';
          cur.clear();
        }));
  }

  Widget peg(int? c, {double size = 30}) => Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, color: c == null ? Colors.white10 : colors[c], border: Border.all(color: Colors.white24)),
      );

  Widget picker(VoidCallback onDone, String doneLabel) => Column(children: [
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
            OutlinedButton.icon(onPressed: cur.isEmpty ? null : () => setState(cur.removeLast), icon: const Icon(Icons.undo), label: const Text('Undo')),
            const SizedBox(width: 12),
            FilledButton(onPressed: cur.length == 4 ? onDone : null, child: Text(doneLabel)),
          ]),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final body = switch (phase) {
      'set' => Column(children: [
          turnBanner(setter, '${duelNames[setter]}: pick a secret code'),
          Expanded(
            child: Center(
              child: Text('${last.isEmpty ? '' : '$last\n\n'}${duelNames[guesser]}, look away!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
            ),
          ),
          picker(confirmCode, 'Hide & pass'),
        ]),
      'pass' => passScreen(guesser, 'Pass the phone to ${duelNames[guesser]}', () => setState(() => phase = 'guess')),
      _ => Column(children: [
          turnBanner(guesser, '${duelNames[guesser]}: crack the code (● right place, ○ right color)'),
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
          picker(check, 'Check'),
        ]),
    };
    return page('Mastermind Duel', body, phase == 'guess' ? '${guesses.length}/$maxGuesses' : 'Round ${round + 1}/2');
  }
}
