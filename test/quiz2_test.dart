import 'dart:math';

import 'package:brain_games/games.dart';
import 'package:brain_games/quiz.dart';
import 'package:brain_games/quiz2.dart';
import 'package:flutter_test/flutter_test.dart';

Gen genOf(String name) => (quizGames2.firstWhere((g) => g.name == name).build() as QuizScreen).gen;

void main() {
  test('30 games, unique names (also vs the rest of the app), glyphs set', () {
    expect(quizGames2.length, 30);
    final names = quizGames2.map((g) => g.name).toSet();
    expect(names.length, 30);
    final others = [...quizGames, ...otherGames].map((g) => g.name).toSet();
    expect(names.intersection(others), isEmpty);
    for (final g in quizGames2) {
      expect(g.glyph, isNotEmpty, reason: g.name);
    }
    expect(quizGames2.map((g) => g.glyph).toSet().length, 30);
  });

  test('every question offers its answer among 2–4 distinct options', () {
    final r = Random(3);
    for (final g in quizGames2) {
      final gen = (g.build() as QuizScreen).gen;
      for (var d = 1; d <= 4; d++) {
        for (var k = 0; k < 500; k++) {
          final q = gen(r, d);
          expect(q.options, contains(q.answer), reason: g.name);
          expect(q.options.toSet().length, q.options.length, reason: g.name);
          expect(q.options.length, inInclusiveRange(2, 4), reason: g.name);
        }
      }
    }
  });

  group('exactly one correct option', () {
    final r = Random(5);
    List<Q> many(String name) => [for (var k = 0; k < 2000; k++) genOf(name)(r, 1 + k % 4)];

    test('rhymes', () {
      for (final q in many('Rhyme Time')) {
        final fam = rhymeFamilies.firstWhere((f) => f.contains(q.prompt));
        expect(q.options.where(fam.contains).toList(), [q.answer]);
      }
    });

    test('homophones', () {
      for (final q in many('Homophones')) {
        final partners = {for (final (a, b) in homophones) ...{a: b, b: a}};
        expect(q.options.where((o) => partners[q.prompt] == o).toList(), [q.answer]);
      }
    });

    test('word ladder', () {
      for (final q in many('Word Ladder')) {
        expect(q.options.where((o) => letterDiff(q.prompt, o) == 1).toList(), [q.answer]);
      }
    });

    test('animal groups', () {
      for (final q in many('Animal Groups')) {
        final ok = animalGroups.firstWhere((e) => 'A group of ${e.$1}' == q.prompt).$3;
        expect(q.options.where(ok.contains).toList(), [q.answer]);
      }
    });

    test('mirror letters', () {
      for (final q in many('Mirror Letters')) {
        expect(q.options.where(mirrorSame.contains).toList(), [q.answer]);
      }
    });

    test('decimal fractions are all different values', () {
      final values = decimalFractions.map((e) => double.parse(e.$1)).toSet();
      expect(values.length, decimalFractions.length);
      for (final (dec, frac) in decimalFractions) {
        final parts = frac.split('/').map(int.parse).toList();
        expect(parts[0] / parts[1], closeTo(double.parse(dec), 1e-9));
      }
    });

    test('magic squares really are magic', () {
      for (final q in many('Magic Square')) {
        final cells = q.prompt.split(RegExp(r'\s+')).map((c) => c == '?' ? int.parse(q.answer) : int.parse(c)).toList();
        final lines = [
          [0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6],
        ].map((l) => l.fold(0, (s, i) => s + cells[i])).toSet();
        expect(lines.length, 1);
      }
    });
  });

  test('clock angle and day of year spot checks', () {
    int angle(int h, int m) {
      final a = (30 * (h % 12) - 5.5 * m).abs().round();
      return min(a, 360 - a);
    }

    expect(angle(3, 0), 90);
    expect(angle(6, 0), 180);
    expect(angle(12, 30), 165);
    expect(angle(9, 0), 90);
    expect(monthDays.fold(0, (s, x) => s + x), 365);
  });
}
