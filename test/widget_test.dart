import 'dart:math';

import 'package:brain_games/games.dart';
import 'package:brain_games/main.dart';
import 'package:brain_games/quiz.dart';
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
}
