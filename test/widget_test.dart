import 'dart:math';

import 'package:brain_games/main.dart';
import 'package:brain_games/quiz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('home lists games', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.textContaining('Brain Games'), findsOneWidget);
    expect(find.text('Addition'), findsOneWidget);
  });
}
