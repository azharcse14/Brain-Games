import 'dart:math';

import 'package:brain_games/complex.dart' show slideLine;
import 'package:brain_games/games.dart';
import 'package:brain_games/puzzles2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'mute': true});
    prefs = await SharedPreferences.getInstance();
  });

  test('23 games with unique names and glyphs', () {
    expect(puzzleGames2.length, 23);
    expect(puzzleGames2.map((g) => g.name).toSet().length, 23);
    expect(puzzleGames2.every((g) => g.glyph != null), isTrue);
  });

  test('nonogram clues and solved check', () {
    expect(nonoRuns([true, true, false, true]), [2, 1]);
    expect(nonoRuns([false, false]), isEmpty);
    // Two different pictures with identical clues: either counts as solved.
    expect(nonoSolved([true, false, false, true], [false, true, true, false], 2), isTrue);
    expect(nonoSolved([true, false, false, true], [true, true, false, false], 2), isFalse);
  });

  test('word search words stay in bounds and are findable', () {
    final r = Random(3);
    for (final (n, k) in [(8, 6), (10, 8), (12, 10)]) {
      final made = wsMake(n, k, r);
      final g = made.$1, words = made.$2;
      expect(words.length, greaterThanOrEqualTo(k - 1));
      words.forEach((w, cells) {
        expect(cells.every((i) => i >= 0 && i < n * n), isTrue);
        expect(cells.map((i) => g[i]).join(), w);
        // consecutive cells are neighbours in one fixed direction (no wrapping)
        final dr = cells[1] ~/ n - cells[0] ~/ n, dc = cells[1] % n - cells[0] % n;
        for (var i = 1; i < cells.length; i++) {
          expect(cells[i] ~/ n - cells[i - 1] ~/ n, dr);
          expect(cells[i] % n - cells[i - 1] % n, dc);
        }
      });
    }
  });

  test('flood fill grows the region and greedy always finishes', () {
    final g = [0, 1, 1, 0];
    expect(floodRegion(g, 2), {0});
    floodFill(g, 2, 1);
    expect(floodRegion(g, 2), {0, 1, 2});
    final r = Random(5);
    final big = List.generate(14 * 14, (_) => r.nextInt(6));
    final moves = floodGreedy(big, 14, 6);
    expect(moves, inInclusiveRange(10, 40));
  });

  test('maze is perfect: every cell reachable, exactly cells-1 passages', () {
    for (final (w, h) in [(8, 12), (16, 24)]) {
      final open = mazeMake(w, h, Random(w));
      var passages = 0;
      for (final o in open) {
        passages += [1, 2, 4, 8].where((b) => (o & b) != 0).length;
      }
      expect(passages ~/ 2, w * h - 1);
      final seen = {0}, stack = [0];
      while (stack.isNotEmpty) {
        final c = stack.removeLast();
        for (final (bit, dx, dy, _) in mazeDirs) {
          if ((open[c] & bit) != 0 && seen.add(c + dy * w + dx)) stack.add(c + dy * w + dx);
        }
      }
      expect(seen.length, w * h);
    }
  });

  test('peg jumps', () {
    final holes = {for (var r = 0; r < 7; r++) for (var c = 0; c < 7; c++) if ((r >= 2 && r <= 4) || (c >= 2 && c <= 4)) (r, c)};
    final pegs = holes.difference({(3, 3)});
    expect(pegJump(holes, pegs, (1, 3), (3, 3), pegOrth), isTrue);
    expect(pegJump(holes, pegs, (1, 1), (3, 3), pegOrth), isFalse); // (1,1) isn't a hole, and diagonal
    expect(pegJump(holes, pegs, (3, 1), (3, 3), pegOrth), isTrue);
    expect(pegJump(holes, pegs, (3, 2), (3, 4), pegOrth), isFalse); // target occupied
    final tri = {for (var r = 0; r < 5; r++) for (var c = 0; c <= r; c++) (r, c)};
    final tp = tri.difference({(0, 0)});
    expect(pegJump(tri, tp, (2, 2), (0, 0), pegTriDirs), isTrue); // diagonal jump in the triangle
    expect(pegAnyJump(tri, {(0, 0)}, pegTriDirs), isFalse);
  });

  test('water sort pours and generated racks are solvable by construction', () {
    final t = [
      [0, 1, 1],
      [1],
      <int>[],
    ];
    expect(waterPour(t, 0, 1), 2);
    expect(t[1], [1, 1, 1]);
    expect(waterPour(t, 0, 1), 0); // colour mismatch
    expect(waterPour(t, 0, 2), 1);
    final r = Random(9);
    for (final colors in [4, 6, 8]) {
      final made = waterMake(colors, r);
      final rack = made.$1, moves = made.$2;
      expect(waterSorted(rack), isFalse);
      for (final (a, b, k) in moves.reversed) {
        expect(waterPour(rack, b, a), k);
      }
      expect(waterSorted(rack), isTrue);
    }
  });

  test('knight moves', () {
    expect(knightMoves(0, 5).toSet(), {7, 11});
    expect(knightMoves(12, 5).length, 8);
  });

  test('2048 slide works for any size', () {
    final (out, gained) = slideLine([2, 2, 2, 2, 2]);
    expect(out, [4, 4, 2, 0, 0]);
    expect(gained, 8);
  });

  test('skyscrapers: generated squares solve their own clues', () {
    expect(skyVisible([1, 3, 2, 4]), 3);
    expect(skyVisible([4, 3, 2, 1]), 1);
    final r = Random(2);
    for (var i = 0; i < 20; i++) {
      final g = skyMake(4, r);
      expect(skySolved(g, 4, skyClues(g, 4)), isTrue);
      final bad = g.toList()..[0] = g[1];
      expect(skySolved(bad, 4, skyClues(g, 4)), isFalse);
    }
  });

  testWidgets('every game renders and takes taps on a 360×640 phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final g in puzzleGames2) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: g.build()));
      for (final p in const [Offset(180, 300), Offset(60, 200), Offset(300, 450), Offset(180, 600), Offset(120, 380)]) {
        await tester.tapAt(p);
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull, reason: g.name);
    }
  });
}
