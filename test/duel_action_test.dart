import 'dart:math';

import 'package:brain_games/duel_action.dart';
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

  test('30 uniquely named 2P Action games, each with a glyph', () {
    expect(duelActionGames.length, 30);
    expect(duelActionGames.map((g) => g.name).toSet().length, 30);
    for (final g in duelActionGames) {
      expect(g.cat, '2P Action');
      expect(g.glyph, isNotNull, reason: g.name);
    }
  });

  test('grid steps stop at walls or wrap around', () {
    expect(gridStep((5, 5), (0, -1), 10, 10), (5, 4));
    expect(gridStep((0, 0), (-1, 0), 10, 10), isNull);
    expect(gridStep((9, 3), (1, 0), 10, 10), isNull);
    expect(gridStep((0, 0), (-1, 0), 10, 10, wrap: true), (9, 0));
    expect(gridStep((5, 9), (0, 1), 10, 10, wrap: true), (5, 0));
  });

  test('turns are relative to the heading', () {
    expect(turnLeft((0, -1)), (-1, 0)); // heading up, left = screen left
    expect(turnRight((0, -1)), (1, 0));
    expect(turnLeft((0, 1)), (1, 0)); // top player heading down: their left is screen right
    var d = (0, -1);
    for (var i = 0; i < 4; i++) {
      d = turnRight(d);
    }
    expect(d, (0, -1));
  });

  test('bounceOff reflects approaching bodies only; heavy ones less', () {
    final v = bounceOff(const Offset(0, -1), const Offset(0, 1), Offset.zero, 1, 0);
    expect(v.dy, closeTo(1, 1e-9));
    expect(bounceOff(const Offset(0, 1), const Offset(0, 1), Offset.zero, 1, 0), const Offset(0, 1));
    expect(bounceOff(const Offset(0, -1), const Offset(0, 1), Offset.zero, 1, 1.5).dy, lessThan(v.dy));
    // A striker moving into a resting puck launches it.
    expect(bounceOff(Offset.zero, const Offset(0, -1), const Offset(0, -2), .9, 0).dy, lessThan(0));
  });

  test('reflex stimuli are targets exactly when the rule holds', () {
    final r = Random(3);
    for (var i = 0; i < 300; i++) {
      final (w, ink, t) = reflexStimulus('stroop', r);
      expect(t, reflexInks[reflexWords.indexOf(w)] == ink);
      final (n, _, e) = reflexStimulus('even', r);
      expect(e, int.parse(n).isEven);
      final (s, _, same) = reflexStimulus('shape', r);
      final parts = s.split('  ');
      expect(same, parts[0] == parts[1]);
    }
  });

  testWidgets('every game runs with both players touching at phone size', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final g in duelActionGames) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: g.build()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.dragFrom(const Offset(200, 650), const Offset(80, -40));
      await tester.dragFrom(const Offset(200, 180), const Offset(-80, 40));
      await tester.tapAt(const Offset(60, 740));
      await tester.tapAt(const Offset(340, 90));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: g.name);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('matches play through to a result', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Game named(String n) => duelActionGames.firstWhere((g) => g.name == n);

    // Both paddles parked at the edges, so goals keep coming until someone reaches 5.
    await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: named('Pong Classic').build()));
    await tester.dragFrom(const Offset(200, 700), const Offset(-190, 0)); // park both paddles at the edges
    await tester.dragFrom(const Offset(200, 120), const Offset(190, 0));
    for (var i = 0; i < 600 && find.textContaining('wins').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('wins'), findsOneWidget);

    // Both cycles drive straight into the far walls on the same tick: a drawn round.
    await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: named('Tron Classic').build()));
    for (var i = 0; i < 100 && find.text('Both crashed!').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Both crashed!'), findsNWidgets(2));

    // Blue turns into the wall immediately and loses every round.
    await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: named('Snake Duel Classic').build()));
    for (var i = 0; i < 300 && find.textContaining('wins').evaluate().isEmpty; i++) {
      if (i % 20 == 13) {
        for (var k = 0; k < 2; k++) {
          await tester.tapAt(const Offset(60, 760)); // Blue ◀ twice → heads back down into itself/wall
        }
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Red wins! 🎉'), findsOneWidget);

    // Red hammers the top half in Tug of War.
    await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: named('Tug of War').build()));
    for (var i = 0; i < 25; i++) {
      await tester.tapAt(const Offset(200, 150));
    }
    await tester.pump();
    expect(find.text('Red wins! 🎉'), findsOneWidget);

    // Reflex: tapping while it still says WAIT hands the point to the other player.
    await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: named('Reflex Duel Classic').build()));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.tapAt(const Offset(200, 650));
    await tester.pump();
    expect(find.text('Blue fell for it!'), findsNWidgets(2));
    expect(find.text('1 / 5'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
