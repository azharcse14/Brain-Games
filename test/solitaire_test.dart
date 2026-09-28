import 'dart:math';

import 'package:brain_games/games.dart';
import 'package:brain_games/solitaire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Card code for rank 1–13 (A=1) and suit 0–3 (♠ ♥ ♦ ♣).
int c(int rank, [int suit = 0]) => suit * 13 + rank - 1;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'mute': true});
    prefs = await SharedPreferences.getInstance();
  });

  test('23 games, unique names and glyphs', () {
    expect(solitaireGames.length, 23);
    expect(solitaireGames.map((g) => g.name).toSet().length, 23);
    expect(solitaireGames.map((g) => g.glyph).toSet().length, 23);
  });

  test('jacks or better evaluator', () {
    expect(jobHand([c(1), c(13), c(12), c(11), c(10)]), 'Royal Flush');
    expect(jobHand([c(9, 1), c(13, 1), c(12, 1), c(11, 1), c(10, 1)]), 'Straight Flush');
    expect(jobHand([c(1, 2), c(2, 2), c(3, 2), c(4, 2), c(5, 2)]), 'Straight Flush'); // steel wheel
    expect(jobHand([c(7), c(7, 1), c(7, 2), c(7, 3), c(2)]), 'Four of a Kind');
    expect(jobHand([c(7), c(7, 1), c(7, 2), c(3, 3), c(3)]), 'Full House');
    expect(jobHand([c(2, 3), c(7, 3), c(9, 3), c(11, 3), c(4, 3)]), 'Flush');
    expect(jobHand([c(1), c(2, 1), c(3, 2), c(4, 3), c(5)]), 'Straight'); // wheel
    expect(jobHand([c(10), c(11, 1), c(12, 2), c(13, 3), c(1)]), 'Straight'); // broadway
    expect(jobHand([c(12), c(13, 1), c(1, 2), c(2, 3), c(3)]), isNull); // no wrap-around
    expect(jobHand([c(7), c(7, 1), c(7, 2), c(3, 3), c(9)]), 'Three of a Kind');
    expect(jobHand([c(7), c(7, 1), c(3, 2), c(3, 3), c(9)]), 'Two Pair');
    expect(jobHand([c(11), c(11, 1), c(3, 2), c(4, 3), c(9)]), 'Jacks or Better');
    expect(jobHand([c(10), c(10, 1), c(3, 2), c(4, 3), c(9)]), isNull);
  });

  test('deuces wild evaluator', () {
    expect(deucesHand([c(1), c(13), c(12), c(11), c(10)]), 'Natural Royal');
    expect(deucesHand([c(2), c(2, 1), c(2, 2), c(2, 3), c(9)]), 'Four Deuces');
    expect(deucesHand([c(2, 3), c(13), c(12), c(11), c(10)]), 'Wild Royal');
    expect(deucesHand([c(2, 3), c(2, 2), c(7), c(7, 1), c(7, 2)]), 'Five of a Kind');
    expect(deucesHand([c(2, 3), c(5, 1), c(6, 1), c(7, 1), c(9, 1)]), 'Straight Flush');
    expect(deucesHand([c(2, 3), c(2, 2), c(9), c(9, 1), c(13, 3)]), 'Four of a Kind');
    expect(deucesHand([c(2, 3), c(9), c(9, 1), c(13, 2), c(13, 3)]), 'Full House');
    expect(deucesHand([c(2, 3), c(3, 1), c(8, 1), c(11, 1), c(13, 1)]), 'Flush');
    expect(deucesHand([c(2, 3), c(1), c(3, 1), c(4, 2), c(5, 3)]), 'Straight');
    expect(deucesHand([c(2, 3), c(9), c(9, 1), c(4, 2), c(13, 3)]), 'Three of a Kind');
    expect(deucesHand([c(3), c(9, 1), c(11, 2), c(13, 3), c(5)]), isNull);
    expect(deucesHand([c(3), c(3, 1), c(11, 2), c(13, 3), c(5)]), isNull); // a pair doesn't pay
  });

  group('baccarat drawing rules', () {
    // Cards are dealt P, B, P, B, then player's third, then banker's third.
    (List<int>, List<int>) coup(List<int> order) => baccaratCoup(order.reversed.toList());

    test('a natural stops the draw', () {
      final (p, b) = coup([c(4), c(1), c(5), c(2), c(3), c(3)]);
      expect(p.length, 2);
      expect(b.length, 2);
    });
    test('banker on 3 stands when the player drew an 8', () {
      final (p, b) = coup([c(2), c(1), c(3), c(2), c(8), c(9)]);
      expect(p.length, 3);
      expect(b.length, 2);
    });
    test('player stands on 7, banker draws on 5', () {
      final (p, b) = coup([c(3), c(2), c(4), c(3), c(9)]);
      expect(p.length, 2);
      expect(b.length, 3);
    });
    test('banker on 6 draws only when the player drew a 6 or 7', () {
      expect(coup([c(13), c(3), c(12), c(3), c(6), c(1)]).$2.length, 3);
      expect(coup([c(13), c(3), c(12), c(3), c(5), c(1)]).$2.length, 2);
    });
    test('banker on 7 never draws', () {
      expect(coup([c(13), c(3), c(12), c(4), c(2), c(1)]).$2.length, 2);
    });
    test('hand values ignore tens and faces', () {
      expect(bacVal([c(13), c(9)]), 9);
      expect(bacVal([c(7), c(8)]), 5);
    });
  });

  test('yahtzee scoring', () {
    final fh = [3, 3, 3, 2, 2];
    expect(yahtzeeScore(2, fh), 9);
    expect(yahtzeeScore(6, fh), 13);
    expect(yahtzeeScore(7, fh), 0);
    expect(yahtzeeScore(8, fh), 25);
    expect(yahtzeeScore(9, [1, 2, 3, 4, 6]), 30);
    expect(yahtzeeScore(10, [1, 2, 3, 4, 6]), 0);
    expect(yahtzeeScore(10, [2, 3, 4, 5, 6]), 40);
    expect(yahtzeeScore(9, [2, 3, 4, 5, 6]), 30);
    expect(yahtzeeScore(11, [5, 5, 5, 5, 5]), 50);
    expect(yahtzeeScore(7, [5, 5, 5, 5, 1]), 21);
    expect(yahtzeeScore(12, [1, 2, 3, 4, 6]), 16);
    expect(yahtzeeTotal([3, 6, 9, 12, 15, 18, 0, 0, 0, 0, 0, 0, 0]), 63 + 35);
    expect(yahtzeeTotal([3, 6, 9, 12, 15, 17, 0, 0, 0, 0, 0, 0, 0]), 62);
  });

  test('farkle scoring', () {
    expect(farkleScore([1]), 100);
    expect(farkleScore([5, 5]), 100);
    expect(farkleScore([2]), 0);
    expect(farkleScore([1, 2]), 0);
    expect(farkleScore([1, 1, 1]), 1000);
    expect(farkleScore([2, 2, 2]), 200);
    expect(farkleScore([2, 2, 2, 2]), 400);
    expect(farkleScore([1, 2, 3, 4, 5, 6]), 1500);
    expect(farkleScore([2, 2, 3, 3, 4, 4]), 1500);
    expect(farkleScore([4, 4, 4, 1, 5]), 550);
    expect(farkleBest([2, 3, 4, 6, 6, 2]), isEmpty);
    expect(farkleBest([1, 5, 2, 3, 4, 6]).length, 6);
  });

  test('dice poker ranking', () {
    final order = [
      [3, 3, 3, 3, 3],
      [3, 3, 3, 3, 1],
      [2, 2, 2, 5, 5],
      [2, 3, 4, 5, 6],
      [4, 4, 4, 1, 2],
      [4, 4, 1, 1, 6],
      [6, 6, 1, 2, 3],
      [5, 5, 1, 2, 3],
      [1, 2, 3, 4, 6],
    ];
    for (var i = 0; i < order.length - 1; i++) {
      expect(compareRanks(dicePokerRank(order[i]), dicePokerRank(order[i + 1])), greaterThan(0), reason: '${order[i]} > ${order[i + 1]}');
    }
    expect(dicePokerRank([1, 2, 3, 4, 5])[0], 4);
  });

  test('klondike and freecell building rules', () {
    expect(canFound(c(1, 2), []), isTrue);
    expect(canFound(c(2, 2), [c(1, 2)]), isTrue);
    expect(canFound(c(2, 1), [c(1, 2)]), isFalse);
    expect(canStack(c(9, 1), [c(10)]), isTrue); // red 9 on black 10
    expect(canStack(c(9, 3), [c(10)]), isFalse); // black on black
    expect(canStack(c(13), []), isTrue);
    expect(canStack(c(12), []), isFalse);
    expect(canStack(c(9, 1), [c(10) + hidden]), isFalse); // face-down card
    expect(isAltRun([c(10), c(9, 1), c(8, 3)], 0), isTrue);
    expect(isAltRun([c(10), c(9, 3)], 0), isFalse);
    expect(freeCellMax(4, 0), 5);
    expect(freeCellMax(2, 1), 6);
    expect(freeCellMax(0, 2), 4);
  });

  test('spider completes only a same-suit King-to-Ace run', () {
    final run = [for (var r = 13; r >= 1; r--) c(r)];
    expect(spiderComplete([c(5, 1), ...run]), isTrue);
    expect(spiderComplete([...run.sublist(0, 12), c(1, 1)]), isFalse);
    expect(isSuitRun([c(6), c(5), c(4)], 0), isTrue);
    expect(isSuitRun([c(6), c(5, 1)], 0), isFalse);
  });

  test('pyramid and tripeaks coverage', () {
    final pyr = List.generate(28, (i) => i);
    expect([for (var i = 0; i < 28; i++) if (pyrFree(pyr, i)) i], [for (var i = 21; i < 28; i++) i]);
    pyr[1] = pyr[2] = -1;
    expect(pyrFree(pyr, 0), isTrue);
    expect(triCover[0], [3, 4]);
    for (var i = 0; i < 28; i++) {
      for (final j in triCover[i]) {
        expect(j > i && j < 28, isTrue);
      }
      expect(triCover[i].isEmpty, i >= 18);
    }
  });

  test('accordion, go fish, old maid, shut the box helpers', () {
    expect(accordionHasMove([c(3), c(9, 1)]), isFalse);
    expect(accordionHasMove([c(3), c(9)]), isTrue); // same suit
    expect(accordionHasMove([c(3), c(9, 1), c(10, 2), c(3, 3)]), isTrue); // same rank 3 back
    final hand = [c(5), c(5, 1), c(5, 2), c(5, 3), c(7)];
    expect(takeBooks(hand), 1);
    expect(hand, [c(7)]);
    final h2 = [c(4), c(4, 1), c(4, 2), c(9)];
    discardPairs(h2);
    expect(h2.length, 2);
    expect(canMake([1, 4, 6], 10), isTrue);
    expect(canMake([1, 4, 6], 9), isFalse);
    expect(straightFits([1, 3, 4, 5]), isTrue);
    expect(straightFits([1, 3, 3, 5]), isFalse);
  });

  testWidgets('every game renders and survives taps on a 360×640 phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final g in solitaireGames) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: g.build()));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '${g.name} (open)');
      for (final pt in const [Offset(180, 560), Offset(40, 120), Offset(180, 300), Offset(300, 400), Offset(60, 250), Offset(180, 600)]) {
        await tester.tapAt(pt);
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: '${g.name} tap $pt');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('random play: 60 taps per game never throws', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final r = Random(7);
    for (final g in solitaireGames) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: const SizedBox()));
      tester.state<NavigatorState>(find.byType(Navigator)).push(MaterialPageRoute(settings: RouteSettings(name: g.name), builder: (_) => g.build()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      for (var k = 0; k < 60; k++) {
        await tester.tapAt(Offset(r.nextDouble() * 360, 70 + r.nextDouble() * 570));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '${g.name} tap $k');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    }
  });

  testWidgets('klondike and freecell: double-tapping the last kings wins the game', (tester) async {
    for (final (g, found, firstTab) in [(solitaireGames[0], 2, 6), (solitaireGames[3], 4, 8)]) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: const SizedBox()));
      tester.state<NavigatorState>(find.byType(Navigator)).push(MaterialPageRoute(settings: RouteSettings(name: g.name), builder: (_) => g.build()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final st = tester.state(find.byWidgetPredicate((w) => w.runtimeType == g.build().runtimeType)) as dynamic;
      final List<List<int>> p = st.p;
      for (final x in p) {
        x.clear();
      }
      for (var s = 0; s < 4; s++) {
        p[found + s].addAll([for (var r = 1; r <= 12; r++) c(r, s)]);
        p[firstTab + s].add(c(13, s));
      }
      for (var s = 0; s < 4; s++) {
        st.tap(firstTab + s, 0);
        st.tap(firstTab + s, 0);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Solved'), findsOneWidget, reason: g.name);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    }
  });
}
