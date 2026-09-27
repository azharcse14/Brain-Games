import 'package:flutter/material.dart';

import 'games.dart';

/// Shared bits for 2-player (same device) games. Player 0 = Blue, player 1 = Red.
const duelColors = [Colors.blue, Colors.red];
const duelNames = ['Blue', 'Red'];

/// Ends a 2-player match; [winner] is 0, 1 or null for a draw.
void showWinner(BuildContext context, int? winner, VoidCallback again) =>
    showResult(context, winner == null ? "It's a draw!" : '${duelNames[winner]} wins! 🎉', again);

/// "Blue's turn" banner tinted with the current player's colour.
Widget turnBanner(int player, [String? text]) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: duelColors[player].withValues(alpha: .35),
      child: Text(text ?? "${duelNames[player]}'s turn", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );

/// Rotates [child] 180° so the player sitting on the far side of the phone can read it.
Widget facingTop(Widget child) => RotatedBox(quarterTurns: 2, child: child);
