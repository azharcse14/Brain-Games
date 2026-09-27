import 'package:brain_games/duel_board.dart';
import 'package:brain_games/games.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    prefs!.setBool('mute', true);
  });

  test('40 games with unique names and glyphs', () {
    expect(duelBoardGames.length, 40);
    expect(duelBoardGames.map((g) => g.name).toSet().length, 40);
    expect(duelBoardGames.every((g) => g.glyph != null && g.cat == '2P Board'), isTrue);
  });

  test('n-in-a-row finds lines in every direction but not across row wraps', () {
    List<int> b(List<int> stones, [int cols = 5]) => List.generate(cols * cols, (i) => stones.contains(i) ? 1 : 0);
    expect(lineAt(b([5, 6, 7, 8]), 5, 5, 7, 4), isTrue); // row
    expect(lineAt(b([1, 6, 11, 16]), 5, 5, 11, 4), isTrue); // column
    expect(lineAt(b([0, 6, 12, 18]), 5, 5, 12, 4), isTrue); // diagonal \
    expect(lineAt(b([4, 8, 12, 16]), 5, 5, 8, 4), isTrue); // diagonal /
    expect(lineAt(b([3, 4, 5, 6]), 5, 5, 4, 4), isFalse); // wraps onto next row
    expect(hasLine(b([0, 6, 12]), 5, 5, 3, 1), isTrue);
    expect(hasLine(b([0, 6, 12]), 5, 5, 3, 2), isFalse);
  });

  test('ultimate tic tac toe small-board winner ignores drawn boards', () {
    expect(tttWinner([2, 2, 2, 0, 0, 0, 0, 0, 0]), 2);
    expect(tttWinner([3, 3, 3, 0, 0, 0, 0, 0, 0]), 0);
    expect(tttWinner([1, 0, 0, 0, 1, 0, 0, 0, 1]), 1);
  });

  test('reversi flips sandwiched discs only', () {
    final c = List.filled(64, 0);
    c[27] = c[36] = 2; // (3,3) (4,4)
    c[28] = c[35] = 1; // (3,4) (4,3)
    expect(reversiFlips(c, 8, 19, 1), [27]); // (2,3) flips (3,3)
    expect(reversiFlips(c, 8, 0, 1), isEmpty);
    expect(reversiFlips(c, 8, 27, 1), isEmpty); // occupied
    expect(reversiCanMove(c, 8, 1), isTrue);
    expect(reversiCanMove(List.filled(64, 1), 8, 2), isFalse);
  });

  test('dots and boxes closes a box on its fourth side', () {
    // 1×1 boxes: 3×3 grid, box at 4, edges 1 (top), 3 (left), 5 (right), 7 (bottom).
    expect(closedBoxes({1, 3, 5, 7}, 3, 7), [4]);
    expect(closedBoxes({1, 3, 7}, 3, 7), isEmpty);
    // 2×2 boxes (5×5 grid): the shared edge 7 closes boxes 6 and 8 at once.
    expect(closedBoxes({1, 3, 5, 9, 11, 13, 7}, 5, 7)..sort(), [6, 8]);
  });

  test('mancala sowing: store bonus, capture, skipping the rival store, end sweep', () {
    final p = List.generate(14, (i) => i == 6 || i == 13 ? 0 : 4);
    expect(kalahSow(p, 2, 0), isTrue); // 3,4,5,store
    expect(p[6], 1);

    final c = List.filled(14, 0)..[0] = 1..[11] = 5..[8] = 1;
    expect(kalahSow(c, 0, 0), isFalse);
    expect(c[6], 6); // 5 captured + the landing seed
    expect(c[1] + c[11], 0);

    final r = List.filled(14, 0)..[12] = 9;
    kalahSow(r, 12, 1); // 13, 0–5, (skips 6), 7, 8 — lands in empty pit 8, captures pit 4
    expect(r[6], 0); // Red skips Blue's store
    expect(r[13], 3);
    expect(r[8] + r[4], 0);

    final e = List.filled(14, 0)..[9] = 3..[6] = 10;
    expect(kalahEnd(e), isTrue);
    expect(e[13], 3);
    expect(kalahEnd(List.generate(14, (i) => 1)), isFalse);
  });

  test('hex connections', () {
    List<int> b(List<int> cells, int p) => List.generate(9, (i) => cells.contains(i) ? p : 0);
    expect(hexWon(b([0, 3, 6], 1), 3, 1), isTrue); // straight down
    expect(hexWon(b([2, 4, 6], 1), 3, 1), isTrue); // along the (1,-1) hex neighbour
    expect(hexWon(b([0, 4, 8], 1), 3, 1), isFalse); // (1,1) is not a hex neighbour
    expect(hexWon(b([3, 4, 5], 2), 3, 2), isTrue); // left to right
    expect(hexWon(b([0, 3], 1), 3, 1), isFalse);
  });

  test('domineering, nim and chomp end conditions', () {
    expect(domCanPlace([0, 0, 1, 1], 2, true), isFalse);
    expect(domCanPlace([0, 0, 1, 1], 2, false), isTrue);
    expect(nimWinner([0, 0, 0], 0, false), 0);
    expect(nimWinner([0, 0, 0], 0, true), 1);
    expect(nimWinner([0, 1], 0, false), isNull);
    final eaten = List.filled(9, false);
    chomp(eaten, 3, 1, 1);
    expect([for (var i = 0; i < 9; i++) if (eaten[i]) i], [4, 5, 7, 8]);
  });

  test('pentago rotation and isolation moves', () {
    final b = List.filled(36, 0)..[0] = 1;
    rotateQuadrant(b, 0, true);
    expect(b[2], 1); // top-left corner → top-right of the quadrant
    rotateQuadrant(b, 0, false);
    expect(b[0], 1);
    final q = List.generate(36, (i) => i % 3);
    final copy = q.toList();
    for (var k = 0; k < 4; k++) {
      rotateQuadrant(q, 3, true);
    }
    expect(q, copy);

    expect(isoMoves({}, 8, 0, true)..sort(), [10, 17]);
    expect(isoMoves({}, 3, 0, false).length, 6);
    expect(isoMoves({1, 3, 4}, 3, 0, false), isEmpty);
  });

  testWidgets('every 2P board game renders and takes taps at phone size', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final g in duelBoardGames) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: g.build()));
      for (final o in const [Offset(200, 400), Offset(120, 300), Offset(280, 500), Offset(200, 250), Offset(60, 600)]) {
        await tester.tapAt(o);
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(tester.takeException(), isNull, reason: g.name);
    }
  });
}
