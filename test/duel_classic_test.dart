import 'dart:math';

import 'package:brain_games/duel_classic.dart';
import 'package:brain_games/games.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chess square from algebraic notation, e.g. 'e2'.
int sq(String s) => (8 - int.parse(s[1])) * 8 + s.codeUnitAt(0) - 97;

Chess emptyChess() => Chess()
  ..b = List.filled(64, '')
  ..rights = {};

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    prefs!.setBool('mute', true);
  });

  test('30 games with glyphs and unique names', () {
    expect(duelClassicGames.length, 30);
    expect(duelClassicGames.map((g) => g.name).toSet().length, 30);
    expect(duelClassicGames.every((g) => g.glyph != null), isTrue);
  });

  group('chess', () {
    void mv(Chess g, String a, String b) {
      expect(g.movesFrom(sq(a)), contains(sq(b)), reason: '$a$b');
      g.play(sq(a), sq(b));
    }

    test("fool's mate is checkmate", () {
      final g = Chess();
      mv(g, 'f2', 'f3');
      mv(g, 'e7', 'e5');
      mv(g, 'g2', 'g4');
      mv(g, 'd8', 'h4');
      expect(g.winner, 1);
    });

    test('en passant captures the passed pawn', () {
      final g = Chess();
      mv(g, 'e2', 'e4');
      mv(g, 'a7', 'a6');
      mv(g, 'e4', 'e5');
      mv(g, 'd7', 'd5');
      mv(g, 'e5', 'd6');
      expect(g.b[sq('d5')], '');
      expect(g.b[sq('d6')], 'P');
    });

    test('castling: allowed when clear, refused through an attacked square', () {
      final g = emptyChess();
      g.b[sq('e1')] = 'K';
      g.b[sq('h1')] = 'R';
      g.b[sq('e8')] = 'k';
      g.rights = {sq('h1')};
      expect(g.movesFrom(sq('e1')), contains(sq('g1')));
      g.b[sq('f8')] = 'r'; // attacks f1
      expect(g.movesFrom(sq('e1')), isNot(contains(sq('g1'))));
      g.b[sq('f8')] = '';
      g.play(sq('e1'), sq('g1'));
      expect(g.b[sq('g1')], 'K');
      expect(g.b[sq('f1')], 'R');
    });

    test("a king walking along the enemy's back rank keeps the enemy's castling rights", () {
      final g = emptyChess();
      g.b[sq('c8')] = 'K';
      g.b[sq('e8')] = 'k';
      g.b[sq('h8')] = 'r';
      g.rights = {sq('h8')};
      g.play(sq('c8'), sq('b8'));
      expect(g.rights, contains(sq('h8')));
    });

    test('king and knight against king is a draw', () {
      final g = emptyChess();
      g.b[sq('e1')] = 'K';
      g.b[sq('b1')] = 'N';
      g.b[sq('e8')] = 'k';
      g.b[sq('c3')] = 'p';
      mv(g, 'b1', 'c3');
      expect(g.winner, 2);
    });

    test('chess960 castles by moving the king onto its rook', () {
      final g = Chess(fischer: true)
        ..b = List.filled(64, '')
        ..rights = {};
      g.b[sq('b1')] = 'K';
      g.b[sq('a1')] = 'R';
      g.b[sq('h8')] = 'k';
      g.rights = {sq('a1')};
      expect(g.movesFrom(sq('b1')), contains(sq('a1')));
      g.play(sq('b1'), sq('a1'));
      expect(g.b[sq('c1')], 'K');
      expect(g.b[sq('d1')], 'R');
    });

    test('king cannot step into check', () {
      final g = emptyChess();
      g.b[sq('e1')] = 'K';
      g.b[sq('d8')] = 'r';
      g.b[sq('h8')] = 'k';
      final m = g.movesFrom(sq('e1'));
      expect(m, isNot(contains(sq('d1'))));
      expect(m, isNot(contains(sq('d2'))));
      expect(m, contains(sq('f1')));
    });

    test('stalemate is a draw', () {
      final g = emptyChess();
      g.b[sq('a8')] = 'k';
      g.b[sq('c6')] = 'K';
      g.b[sq('d7')] = 'Q';
      g.play(sq('d7'), sq('c7'));
      expect(g.winner, 2);
    });

    test('chess960 rows are legal', () {
      final r = Random(3);
      for (var k = 0; k < 200; k++) {
        final row = chess960Row(r);
        final bs = [for (var i = 0; i < 8; i++) if (row[i] == 'B') i];
        expect(bs[0] % 2 != bs[1] % 2, isTrue);
        final rs = [for (var i = 0; i < 8; i++) if (row[i] == 'R') i];
        expect(rs[0] < row.indexOf('K') && row.indexOf('K') < rs[1], isTrue);
      }
    });
  });

  test('checkers: capture is forced and multi-jumps continue', () {
    final g = Checkers(8);
    int at(int r, int c) => r * 8 + c;
    g.b.fillRange(0, 64, 0);
    g.b[at(5, 2)] = 1;
    g.b[at(5, 6)] = 1;
    g.b[at(4, 3)] = 3;
    g.b[at(2, 5)] = 3;
    expect(g.movesFrom(at(5, 6)), isEmpty); // another piece must capture
    expect(g.movesFrom(at(5, 2)), [at(3, 4)]);
    g.play(at(5, 2), at(3, 4));
    expect(g.forced, at(3, 4));
    expect(g.turn, 0);
    expect(g.movesFrom(at(3, 4)), [at(1, 6)]);
    g.play(at(3, 4), at(1, 6));
    expect(g.winner, 0);
  });

  group('go', () {
    int at(int r, int c) => r * 9 + c;
    test('captures a stone out of liberties', () {
      final g = Go(9);
      g.b[at(0, 0)] = 1;
      g.b[at(0, 1)] = 0;
      expect(g.tapEmpty(at(1, 0)), isTrue);
      expect(g.b[at(0, 0)], -1);
      expect(g.caps[0], 1);
    });
    test('suicide is illegal', () {
      final g = Go(9)..turn = 1;
      g.b[at(0, 1)] = 0;
      g.b[at(1, 0)] = 0;
      expect(g.tapEmpty(at(0, 0)), isFalse);
      expect(g.b[at(0, 0)], -1);
    });
    test('immediate ko recapture is illegal', () {
      final g = Go(9);
      for (final (r, c) in [(0, 1), (1, 0), (2, 1)]) {
        g.b[at(r, c)] = 0;
      }
      for (final (r, c) in [(0, 2), (1, 3), (2, 2), (1, 1)]) {
        g.b[at(r, c)] = 1;
      }
      expect(g.tapEmpty(at(1, 2)), isTrue); // black takes the ko
      expect(g.b[at(1, 1)], -1);
      expect(g.tapEmpty(at(1, 1)), isFalse); // white may not retake at once
    });
    test('two passes end the game with area scoring', () {
      final g = Go(9);
      g.doAction();
      g.doAction();
      expect(g.winner, 1); // empty board: komi decides
    });
  });

  test('morris: a mill lets you remove a piece', () {
    final g = Morris.nine();
    final ring = Morris.ring(7, 0);
    final inner = Morris.ring(7, 2);
    expect(g.tapEmpty(ring[0]), isTrue);
    expect(g.tapEmpty(inner[0]), isTrue);
    expect(g.tapEmpty(ring[1]), isTrue);
    expect(g.tapEmpty(inner[4]), isTrue);
    expect(g.tapEmpty(ring[2]), isTrue);
    expect(g.removing, isTrue);
    expect(g.turn, 0);
    expect(g.tapEmpty(inner[0]), isTrue);
    expect(g.owner.containsKey(inner[0]), isFalse);
    expect(g.turn, 1);
  });

  test('quoridor rejects a wall that seals off every path', () {
    final g = Quoridor(9, 10)..pawns[1] = 40; // Red in the middle, outside the walled area
    g.h.addAll([0, 2, 4, 6]); // row 0/1 boundary, columns 0–7
    g.v.add(7); // right of (0,7)-(1,7)
    expect(g.canWall(true, 9 + 7), isFalse); // would seal (0,8)/(1,8) off
    expect(g.canWall(true, 5 * 9), isTrue);
  });

  group('tafl', () {
    test('custodial capture and king capture', () {
      final g = Tafl(7);
      int at(int r, int c) => r * 7 + c;
      g.b.fillRange(0, 49, 0);
      g.b[at(1, 4)] = 2;
      g.b[at(1, 3)] = 1;
      g.b[at(5, 5)] = 1;
      g.b[at(6, 2)] = 1;
      g.b[at(1, 0)] = 1;
      g.b[at(1, 1)] = 3; // king away from the throne
      g.play(at(5, 5), at(1, 5));
      expect(g.b[at(1, 4)], 0);
      expect(g.winner, isNull);
      g.turn = 0;
      g.play(at(6, 2), at(1, 2)); // sandwiches the king between (1,0) and (1,2)
      expect(g.winner, 0);
    });
  });

  test('tafl: a king that steps between two attackers is not captured by an unrelated move', () {
    final g = Tafl(7);
    int at(int r, int c) => r * 7 + c;
    g.b.fillRange(0, 49, 0);
    g.b[at(2, 2)] = 3;
    g.b[at(1, 1)] = 1;
    g.b[at(1, 3)] = 1;
    g.b[at(5, 5)] = 1;
    g.turn = 1;
    g.play(at(2, 2), at(1, 2)); // king steps between the two attackers itself
    g.play(at(5, 5), at(5, 4)); // attackers move elsewhere
    expect(g.winner, isNull);
  });

  test('lines of action connectivity', () {
    final b = List.filled(64, -1);
    b[0] = 0;
    b[9] = 0;
    b[18] = 0;
    expect(loaConnected(b, 8, 0), isTrue);
    b[20] = 0;
    expect(loaConnected(b, 8, 0), isFalse);
    final g = LinesOfAction();
    expect(g.movesFrom(1), contains(2 * 8 + 1)); // 2 pieces in column b → move exactly 2
  });

  test('battleship fleets never overlap', () {
    final r = Random(1);
    for (var k = 0; k < 50; k++) {
      final f = placeFleet(10, [5, 4, 3, 3, 2], r);
      expect(f.where((x) => x >= 0).length, 17);
    }
  });

  test('random legal play never crashes any ruleset', () {
    final r = Random(11);
    final makers = <ClassicDuel Function()>[
      Chess.new, () => Chess(fischer: true), () => Checkers(8), () => Checkers(8, forcedCapture: false), () => Checkers(10),
      () => Checkers(8, giveaway: true), () => Go(9), Morris.nine, Morris.six, Morris.three, () => Quoridor(9, 10), () => Quoridor(7, 7),
      () => Tafl(9), () => Tafl(7), () => Breakthrough(6), () => Breakthrough(8), () => Amazons(6), () => Amazons(8), FoxGeese.new,
      () => Konane(6), () => Konane(8), LinesOfAction.new,
    ];
    for (final make in makers) {
      for (var game = 0; game < 3; game++) {
        final g = make();
        for (var ply = 0; ply < 300 && g.winner == null; ply++) {
          final f = g.forced;
          if (f != null) {
            final m = g.movesFrom(f);
            g.play(f, m[r.nextInt(m.length)]);
            continue;
          }
          final cells = List.generate(g.n * g.n, (i) => i)..shuffle(r);
          if (r.nextInt(4) == 0 && g is Quoridor) g.mode = 1 + r.nextInt(2);
          if (cells.any(g.tapEmpty)) continue;
          if (g is Quoridor) g.mode = 0;
          final moves = [for (final i in cells) for (final t in g.movesFrom(i)) (i, t)];
          if (moves.isNotEmpty) {
            final (a, b) = moves[r.nextInt(moves.length)];
            g.play(a, b);
          } else if (g.action != null) {
            g.doAction();
          } else {
            fail('${g.title}: no move but no winner');
          }
        }
      }
    }
  });

  testWidgets('every classic duel renders and survives taps at phone size', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final g in duelClassicGames) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: g.build()));
      for (final p in const [Offset(200, 400), Offset(120, 300), Offset(200, 700), Offset(200, 400)]) {
        await tester.tapAt(p);
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pump(const Duration(seconds: 2));
      final e = tester.takeException();
      expect(e, isNull, reason: '${g.name}: $e');
    }
  });
}
