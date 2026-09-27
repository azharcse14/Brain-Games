import 'dart:math';

import 'package:brain_games/games.dart';
import 'package:brain_games/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens every game on a small phone and taps it randomly, looking for crashes and layout overflows.
void main() {
  testWidgets('every game survives random taps on a 360×640 phone', (tester) async {
    SharedPreferences.setMockInitialValues({'mute': true});
    prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final r = Random(1);
    final failures = <String>[];
    for (final g in allGames) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: const SizedBox()));
      tester.state<NavigatorState>(find.byType(Navigator)).push(MaterialPageRoute(settings: RouteSettings(name: g.name), builder: (_) => g.build()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      for (var k = 0; k < 25; k++) {
        await tester.tapAt(Offset(r.nextDouble() * 360, 80 + r.nextDouble() * 540));
        await tester.pump(const Duration(milliseconds: 350));
        final e = tester.takeException();
        if (e != null) {
          failures.add('${g.name} (tap $k): ${e.toString().split('\n').first}');
          break;
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5)); // let delayed callbacks of the closed game finish
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
