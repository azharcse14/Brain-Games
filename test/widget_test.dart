import 'dart:math';

import 'package:brain_games/complex.dart';
import 'package:brain_games/games.dart';
import 'package:brain_games/main.dart';
import 'package:brain_games/quiz.dart';
import 'package:brain_games/tabletop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('record keeps only better scores', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    expect(record(ctx, 5), isTrue);
    expect(record(ctx, 3), isFalse);
    expect(record(ctx, 7, unit: '/10'), isTrue);
    expect(prefs!.getString('bestText:/'), '7/10');
  });

  test('has 100+ games', () => expect(allGames.length, greaterThanOrEqualTo(100)));

  test('every quiz question has its answer among 2–4 distinct options', () {
    final r = Random(42);
    for (final g in quizGames) {
      final gen = (g.build() as QuizScreen).gen;
      for (var d = 1; d <= 4; d++) {
        for (var k = 0; k < 200; k++) {
          final q = gen(r, d);
          expect(q.options, contains(q.answer), reason: g.name);
          expect(q.options.toSet().length, q.options.length, reason: g.name);
          expect(q.options.length, inInclusiveRange(2, 4), reason: g.name);
        }
      }
    }
  });

  test('every game has its own card glyph', () {
    for (final g in allGames) {
      expect(glyphFor(g), isNotNull, reason: g.name);
    }
  });

  testWidgets('home lists games', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.textContaining('Brain Games'), findsOneWidget);
    expect(find.text('Addition'), findsOneWidget);
  });

  testWidgets('quiz: answering and timing out both advance', (tester) async {
    prefs!.setBool('mute', true);
    await tester.pumpWidget(MaterialApp(home: quizGames.first.build()));
    expect(find.textContaining('1/10'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('2/10'), findsOneWidget);
    await tester.pump(const Duration(seconds: 16)); // let the timer run out
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('3/10'), findsOneWidget);
  });

  test('2048 slide merges each pair once', () {
    expect(slideLine([2, 2, 2, 0]).$1, [4, 2, 0, 0]);
    expect(slideLine([2, 2, 2, 0]).$2, 4);
    expect(slideLine([2, 2, 4, 4]).$1, [4, 8, 0, 0]);
    expect(slideLine([2, 2, 4, 4]).$2, 12);
    expect(slideLine([0, 4, 0, 4]).$1, [8, 0, 0, 0]);
    expect(slideLine([0, 4, 0, 4]).$2, 8);
    expect(slideLine([2, 4, 8, 16]).$1, [2, 4, 8, 16]);
    expect(slideLine([2, 4, 8, 16]).$2, 0);
  });

  test('sudoku puzzles are valid and have the requested givens', () {
    final r = Random(7);
    for (final givens in [40, 28]) {
      final g = sudokuPuzzle(givens, r);
      expect(g.where((v) => v != 0).length, givens);
      for (var i = 0; i < 81; i++) {
        if (g[i] != 0) expect(sudokuOk(g, i, g[i]), isTrue);
      }
      expect(sudokuFill(g, r), isTrue); // still solvable
    }
  });

  test('mastermind feedback', () {
    expect(mastermindScore([0, 1, 2, 3], [0, 1, 2, 3]), (4, 0));
    expect(mastermindScore([0, 1, 2, 3], [3, 2, 1, 0]), (0, 4));
    expect(mastermindScore([0, 0, 1, 1], [0, 1, 0, 2]), (1, 2));
    expect(mastermindScore([0, 0, 0, 0], [0, 1, 1, 1]), (1, 0));
  });

  test('connect four detects lines in every direction', () {
    List<int> board(List<int> discs) => List.generate(42, (i) => discs.contains(i) ? 1 : 0);
    expect(connectFourWin(board([35, 36, 37, 38]), 38), isTrue); // horizontal
    expect(connectFourWin(board([14, 21, 28, 35]), 14), isTrue); // vertical
    expect(connectFourWin(board([35, 29, 23, 17]), 23), isTrue); // diagonal /
    expect(connectFourWin(board([14, 22, 30, 38]), 22), isTrue); // diagonal \
    expect(connectFourWin(board([35, 36, 37]), 37), isFalse);
    expect(connectFourWin(board([6, 7, 8, 9]), 7), isFalse); // wraps rows, not a line
  });

  testWidgets('complex, board and card games render and take a tap at phone size', (tester) async {
    prefs!.setBool('mute', true);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final g in [...complexGames, ...tabletopGames]) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: g.build()));
      await tester.tapAt(const Offset(200, 400));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: g.name);
    }
  });

  test('blackjack hand values count aces as 1 or 11', () {
    expect(handValue([0, 12]), 21); // A K
    expect(handValue([0, 13, 8]), 21); // A A 9
    expect(handValue([12, 11, 4]), 25); // K Q 5
    expect(handValue([0, 0 + 13, 0 + 26, 0 + 39]), 14); // four aces
  });

  test('ludo track is a closed loop and every player has a home run', () {
    expect(ludoTrack.length, 52);
    expect(ludoTrack.toSet().length, 52);
    for (var i = 0; i < 52; i++) {
      final (a, b) = ludoTrack[i];
      final (c, d) = ludoTrack[(i + 1) % 52];
      expect((a - c).abs() + (b - d).abs(), anyOf(1, 2), reason: 'step $i'); // adjacent or diagonal corner
    }
    for (var p = 0; p < 4; p++) {
      final (a, b) = ludoCell(p, 0, 50);
      final (c, d) = ludoCell(p, 0, 51);
      expect((a - c).abs() + (b - d).abs(), 1, reason: 'player $p enters home run');
    }
  });

  test('snakes & ladders numbers every square once', () {
    expect({for (var i = 0; i < 100; i++) slSquare(i)}.length, 100);
    expect(slSquare(90), 1); // bottom-left
    expect(slSquare(0), 100); // top-left
  });

  testWidgets('ludo and snakes & ladders survive many turns against the AI', (tester) async {
    prefs!.setBool('mute', true);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final g in [tabletopGames[1], tabletopGames[2]]) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: g.build()));
      for (var k = 0; k < 40; k++) {
        final roll = find.widgetWithText(FilledButton, 'Roll');
        if (roll.evaluate().isNotEmpty) await tester.tap(roll);
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 5));
        // Ludo waits for you to pick a token after a 6: pick the first glowing one.
        final state = tester.state(find.byType(g.build().runtimeType)) as dynamic;
        if (g.name.startsWith('Ludo') && (state.waiting as List).isNotEmpty) state.apply(state.waiting.first, state.die);
        expect(tester.takeException(), isNull, reason: '${g.name} turn $k');
      }
    }
  });
}
