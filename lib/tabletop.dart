import 'dart:math';

import 'package:flutter/material.dart';

import 'games.dart';
import 'solitaire.dart';

final _r = Random();

final tabletopGames = <Game>[
  Game('Ludo 2 Players', 'Board', () => const Ludo([0, 2]), bn: 'লুডু 2 জন'),
  Game('Ludo 4 Players', 'Board', () => const Ludo([0, 1, 2, 3]), bn: 'লুডু 4 জন'),
  Game('Snakes & Ladders', 'Board', () => const SnakesLadders(), bn: 'সাপ লুডু'),
  Game('Blackjack', 'Cards', () => const Blackjack(), bn: 'ব্ল্যাকজ্যাক'),
  Game('Crazy Eights', 'Cards', () => const CrazyEights(), bn: 'ক্রেজি এইটস'),
  Game('Higher or Lower', 'Cards', () => const HigherLower(), bn: 'বড় না ছোট'),
];

// ---------- shared: dice & cards ----------

Widget dice(int? v, {double size = 56}) {
  const pips = {1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8]};
  final on = pips[v] ?? const <int>[];
  return Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size / 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size / 6), border: Border.all(color: Colors.black26)), // edge shows on a light page
    child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      for (var r = 0; r < 3; r++)
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var c = 0; c < 3; c++)
            Container(width: size / 6, height: size / 6, decoration: BoxDecoration(shape: BoxShape.circle, color: on.contains(r * 3 + c) ? Colors.black87 : null)),
        ]),
    ]),
  );
}

/// Shows a few random faces, then returns the final roll.
Future<int> rollDice(void Function(int) show) async {
  for (var k = 0; k < 7; k++) {
    show(_r.nextInt(6) + 1);
    await Future.delayed(const Duration(milliseconds: 60));
  }
  final v = _r.nextInt(6) + 1;
  show(v);
  return v;
}

// Cards are 0..51: rank = c % 13 + 1 (ace = 1), suit = c ~/ 13 (♠ ♥ ♦ ♣).
int rankOf(int c) => c % 13 + 1;
int suitOf(int c) => c ~/ 13;
const suits = '♠♥♦♣';
String cardLabel(int c) => '${const ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'][c % 13]}${suits[suitOf(c)]}';
List<int> newDeck() => List.generate(52, (i) => i)..shuffle(_r);

/// A card face, or its back when [c] is null.
Widget playingCard(int? c, {VoidCallback? onTap, bool dim = false, double w = 58}) => Opacity(
      opacity: dim ? .45 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: w,
          height: w * 1.45,
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c == null ? Colors.indigo : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: c == null
              ? const Text('🂠', style: TextStyle(fontSize: 26, color: Colors.white70))
              : Text(cardLabel(c), style: TextStyle(fontSize: w / 3, fontWeight: FontWeight.bold, color: suitOf(c) == 1 || suitOf(c) == 2 ? Colors.red.shade700 : Colors.black)),
        ),
      ),
    );

// ---------- Ludo ----------

const ludoColors = [Colors.red, Colors.green, Colors.amber, Colors.blue];
List<String> get ludoNames => [tr('You', 'আপনি'), tr('Green', 'সবুজ'), tr('Yellow', 'হলুদ'), tr('Blue', 'নীল')];

/// Main loop on a 15×15 board, starting at red's start square.
const ludoTrack = [
  (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (5, 6), (4, 6), (3, 6), (2, 6), (1, 6), (0, 6), (0, 7), (0, 8), //
  (1, 8), (2, 8), (3, 8), (4, 8), (5, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14), (7, 14), (8, 14),
  (8, 13), (8, 12), (8, 11), (8, 10), (8, 9), (9, 8), (10, 8), (11, 8), (12, 8), (13, 8), (14, 8), (14, 7), (14, 6),
  (13, 6), (12, 6), (11, 6), (10, 6), (9, 6), (8, 5), (8, 4), (8, 3), (8, 2), (8, 1), (8, 0), (7, 0), (6, 0),
];
const ludoHomeRuns = [
  [(7, 1), (7, 2), (7, 3), (7, 4), (7, 5)],
  [(1, 7), (2, 7), (3, 7), (4, 7), (5, 7)],
  [(7, 13), (7, 12), (7, 11), (7, 10), (7, 9)],
  [(13, 7), (12, 7), (11, 7), (10, 7), (9, 7)],
];
const ludoBases = [(0, 0), (0, 9), (9, 9), (9, 0)];
const ludoSafe = {0, 8, 13, 21, 26, 34, 39, 47}; // start squares and stars
final ludoTrackAt = {for (var i = 0; i < ludoTrack.length; i++) ludoTrack[i]: i};

/// Progress: -1 in base, 0..50 on the loop, 51..55 home run, 56 finished.
(int, int) ludoCell(int p, int t, int pos) {
  if (pos < 0) return (ludoBases[p].$1 + [1, 1, 4, 4][t], ludoBases[p].$2 + [1, 4, 1, 4][t]);
  if (pos <= 50) return ludoTrack[(13 * p + pos) % 52];
  if (pos <= 55) return ludoHomeRuns[p][pos - 51];
  return (7, 7);
}

class Ludo extends StatefulWidget {
  const Ludo(this.players, {super.key});
  final List<int> players; // player 0 (red) is you
  @override
  State<Ludo> createState() => _LudoState();
}

class _LudoState extends State<Ludo> {
  late List<List<int>> pos;
  int turn = 0; // index into widget.players
  int? die;
  bool rolling = false, over = false;
  List<int> waiting = []; // your movable tokens after a roll

  int get cur => widget.players[turn];

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    pos = List.generate(4, (_) => List.filled(4, -1));
    turn = 0;
    die = null;
    over = rolling = false;
    waiting = [];
  }

  List<int> movable(int p, int d) => [for (var t = 0; t < 4; t++) if (pos[p][t] < 0 ? d == 6 : pos[p][t] + d <= 56) t];

  /// Loop index an opponent could be captured on, or null if safe / off the loop.
  int? target(int p, int np) {
    if (np > 50) return null;
    final idx = (13 * p + np) % 52;
    return ludoSafe.contains(idx) ? null : idx;
  }

  bool hasOpponentAt(int p, int idx) => widget.players.any((q) => q != p && pos[q].any((o) => o >= 0 && o <= 50 && (13 * q + o) % 52 == idx));

  int value(int p, int t, int d) {
    final c = pos[p][t], np = c < 0 ? 0 : c + d, idx = target(p, np);
    var v = np;
    if (c < 0) v += 40;
    if (np == 56) v += 80;
    if (c <= 50 && np > 50) v += 50;
    if (np <= 50 && idx == null) v += 20;
    if (idx != null && hasOpponentAt(p, idx)) v += 100;
    return v;
  }

  /// Moves a token; returns true if the player earns another turn.
  bool move(int p, int t, int d) {
    final np = pos[p][t] < 0 ? 0 : pos[p][t] + d, idx = target(p, np);
    pos[p][t] = np;
    var extra = d == 6 || np == 56;
    if (idx != null) {
      for (final q in widget.players) {
        for (var u = 0; u < 4; u++) {
          final o = pos[q][u];
          if (q != p && o >= 0 && o <= 50 && (13 * q + o) % 52 == idx) {
            pos[q][u] = -1;
            extra = true;
            sfx(p == 0 ? 'right' : 'wrong');
          }
        }
      }
    }
    return extra;
  }

  Future<void> roll() async {
    setState(() => rolling = true);
    final d = await rollDice((v) {
      if (mounted) setState(() => die = v);
    });
    if (!mounted) return;
    final opts = movable(cur, d); // `rolling` stays true until the turn is handled, so Roll can't fire twice

    if (opts.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) nextTurn(false);
    } else if (cur == 0) {
      setState(() {
        rolling = false;
        waiting = opts;
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      apply(opts.reduce((a, b) => value(cur, a, d) >= value(cur, b, d) ? a : b), d);
    }
  }

  void apply(int t, int d) {
    sfx('tap');
    final p = cur;
    late bool extra;
    setState(() {
      extra = move(p, t, d);
      waiting = [];
    });
    if (pos[p].every((x) => x == 56)) {
      over = true;
      showResult(context, won: p == 0, p == 0 ? tr('You win! 🎉', 'আপনি জিতেছেন! 🎉') : tr('${ludoNames[p]} wins', '${ludoNames[p]} জিতেছে'), () => setState(start));
      return;
    }
    nextTurn(extra);
  }

  void nextTurn(bool extra) {
    setState(() {
      rolling = false;
      if (!extra) turn = (turn + 1) % widget.players.length;
    });
    if (cur != 0 && !over) roll();
  }

  void tapCell(int r, int c) {
    for (final t in waiting) {
      if (ludoCell(0, t, pos[0][t]) == (r, c)) return apply(t, die!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final at = <(int, int), List<(int, int)>>{};
    for (final p in widget.players) {
      for (var t = 0; t < 4; t++) {
        (at[ludoCell(p, t, pos[p][t])] ??= []).add((p, t));
      }
    }
    Color bg(int r, int c) {
      if (r < 6 && c < 6) return ludoColors[0].shade300;
      if (r < 6 && c > 8) return ludoColors[1].shade300;
      if (r > 8 && c > 8) return ludoColors[2].shade300;
      if (r > 8 && c < 6) return ludoColors[3].shade300;
      if (r >= 6 && r <= 8 && c >= 6 && c <= 8) return Colors.grey.shade600;
      for (var p = 0; p < 4; p++) {
        if (ludoHomeRuns[p].contains((r, c)) || ludoTrackAt[(r, c)] == 13 * p) return ludoColors[p].shade400;
      }
      return Colors.grey.shade200;
    }

    return page(
      widget.players.length == 2 ? tr('Ludo · 2 Players', 'লুডু · 2 জন') : tr('Ludo · 4 Players', 'লুডু · 4 জন'),
      Column(children: [
        Expanded(
          child: board(15, 225, gap: 1, (i) {
            final r = i ~/ 15, c = i % 15, here = at[(r, c)] ?? const [];
            final star = ludoSafe.contains(ludoTrackAt[(r, c)]) && ludoTrackAt[(r, c)]! % 13 != 0;
            final mine = here.any((e) => e.$1 == 0 && waiting.contains(e.$2));
            return GestureDetector(
              onTap: () => tapCell(r, c),
              child: Container(
                color: bg(r, c),
                alignment: Alignment.center,
                child: here.isEmpty
                    ? (star ? const FittedBox(child: Text('★', style: TextStyle(color: Colors.black45))) : null)
                    : FractionallySizedBox(
                        widthFactor: .85,
                        heightFactor: .85,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ludoColors[here.first.$1],
                            border: Border.all(color: mine ? Colors.white : Colors.black54, width: mine ? 3 : 1),
                            boxShadow: mine ? const [BoxShadow(color: Colors.white, blurRadius: 6)] : null,
                          ),
                          child: here.length > 1 ? FittedBox(child: Text('${here.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))) : null,
                        ),
                      ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            dice(die),
            const SizedBox(width: 20),
            Flexible(
              child: FilledButton.icon(
                onPressed: cur == 0 && !rolling && waiting.isEmpty && !over ? roll : null,
                icon: const Icon(Icons.casino),
                label: Text(waiting.isNotEmpty ? tr('Pick a token', 'গুটি বাছুন') : tr('Roll', 'চাল দিন'), overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ),
      ]),
      cur == 0 ? tr('Your turn', 'আপনার পালা') : tr("${ludoNames[cur]}'s turn", '${ludoNames[cur]}-এর পালা'),
    );
  }
}

// ---------- Snakes & Ladders ----------

const slJumps = {4: 14, 9: 31, 21: 42, 28: 84, 51: 67, 72: 91, 80: 99, 17: 7, 54: 34, 62: 19, 64: 60, 87: 36, 93: 73, 95: 75, 98: 79};

/// Square number (1..100, boustrophedon from bottom-left) shown at grid cell [i] of a 10×10 board.
int slSquare(int i) {
  final fromBottom = 9 - i ~/ 10, c = i % 10;
  return fromBottom * 10 + (fromBottom.isEven ? c : 9 - c) + 1;
}

class SnakesLadders extends StatefulWidget {
  const SnakesLadders({super.key});
  @override
  State<SnakesLadders> createState() => _SnakesLaddersState();
}

class _SnakesLaddersState extends State<SnakesLadders> {
  final pos = [0, 0]; // 0 = you, 1 = AI; 0 means not on the board yet
  int turn = 0;
  int? die;
  bool busy = false;

  Future<void> play() async {
    setState(() => busy = true);
    final d = await rollDice((v) {
      if (mounted) setState(() => die = v);
    });
    if (!mounted) return;
    final p = turn;
    if (pos[p] + d <= 100) setState(() => pos[p] += d);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final jump = slJumps[pos[p]];
    if (jump != null) {
      sfx(jump > pos[p] == (p == 0) ? 'right' : 'wrong');
      setState(() => pos[p] = jump);
    }
    if (pos[p] == 100) {
      showResult(context, won: p == 0, p == 0 ? tr('You win! 🎉', 'আপনি জিতেছেন! 🎉') : tr('AI wins', 'কম্পিউটার জিতেছে'), () => setState(() {
            pos.fillRange(0, 2, 0);
            turn = 0;
            busy = false;
          }));
      return;
    }
    setState(() => turn = 1 - turn);
    if (turn == 1) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) play();
    } else {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Snakes & Ladders', 'সাপ লুডু'),
        Column(children: [
          Expanded(
            child: board(10, 100, gap: 2, (i) {
              final n = slSquare(i), jump = slJumps[n];
              return Container(
                decoration: BoxDecoration(color: (i ~/ 10 + i) .isEven ? Colors.teal.shade700 : Colors.teal.shade900, borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.all(2),
                child: Stack(children: [
                  Text('$n', style: const TextStyle(fontSize: 9, color: Colors.white60)),
                  if (jump != null)
                    Align(alignment: Alignment.bottomRight, child: FittedBox(child: Text(jump > n ? '🪜$jump' : '🐍$jump', style: const TextStyle(fontSize: 9, color: Colors.white)))),
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var p = 0; p < 2; p++)
                        if (pos[p] == n) Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: p == 0 ? Colors.lightBlueAccent : Colors.redAccent, border: Border.all(color: Colors.white))),
                    ]),
                  ),
                ]),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              dice(die),
              const SizedBox(width: 20),
              FilledButton.icon(onPressed: turn == 0 && !busy ? play : null, icon: const Icon(Icons.casino), label: Text(tr('Roll', 'চাল দিন'))),
            ]),
          ),
        ]),
        '🔵 ${pos[0]}  🔴 ${pos[1]}',
      );
}

// ---------- Blackjack ----------

int handValue(List<int> h) {
  var v = 0, aces = 0;
  for (final c in h) {
    final r = rankOf(c);
    if (r == 1) {
      aces++;
      v += 11;
    } else {
      v += min(r, 10);
    }
  }
  while (v > 21 && aces-- > 0) {
    v -= 10;
  }
  return v;
}

class Blackjack extends StatefulWidget {
  const Blackjack({super.key});
  @override
  State<Blackjack> createState() => _BlackjackState();
}

class _BlackjackState extends State<Blackjack> {
  List<int> deck = newDeck(), player = [], dealer = [];
  int chips = 100, bet = 10;
  bool playing = false;
  String msg = tr('Place your bet', 'বাজি ধরুন');

  int draw() {
    if (deck.isEmpty) deck = newDeck();
    return deck.removeLast();
  }

  void deal() {
    if (deck.length < 15) deck = newDeck();
    setState(() {
      player = [draw(), draw()];
      dealer = [draw(), draw()];
      playing = true;
      msg = '';
    });
    if (handValue(player) == 21 || handValue(dealer) == 21) stand();
  }

  void hit() {
    setState(() => player.add(draw()));
    if (handValue(player) > 21) settle(-bet, tr('Bust!', 'বাস্ট!'));
  }

  void stand() {
    while (handValue(dealer) < 17) {
      dealer.add(draw());
    }
    final p = handValue(player), d = handValue(dealer);
    final pNat = p == 21 && player.length == 2, dNat = d == 21 && dealer.length == 2;
    if (pNat && !dNat) {
      settle(bet * 3 ~/ 2, tr('Blackjack! +${bet * 3 ~/ 2}', 'ব্ল্যাকজ্যাক! +${bet * 3 ~/ 2}'));
    } else if (dNat && !pNat) {
      settle(-bet, tr('Dealer blackjack', 'ডিলারের ব্ল্যাকজ্যাক'));
    } else if (d > 21 || p > d) {
      settle(bet, tr('You win +$bet', 'আপনি জিতলেন +$bet'));
    } else if (p == d) {
      settle(0, tr('Push', 'সমান'));
    } else {
      settle(-bet, tr('Dealer wins', 'ডিলার জিতেছে'));
    }
  }

  void settle(int delta, String m) {
    sfx(delta > 0 ? 'right' : (delta < 0 ? 'wrong' : 'tap'));
    setState(() {
      chips += delta;
      playing = false;
      msg = m;
      bet = [bet, 25, 10].firstWhere((b) => b <= chips, orElse: () => 10); // stay on a real option
    });
    record(context, chips, unit: ' chips');
    if (chips < 10) {
      showResult(context, won: false, tr('Out of chips!', 'চিপ শেষ!'), () => setState(() {
            chips = 100;
            player = [];
            dealer = [];
            msg = tr('Place your bet', 'বাজি ধরুন');
          }));
    }
  }

  Widget hand(String who, List<int> h, {bool hideSecond = false}) => Column(children: [
        Text(h.isEmpty ? who : '$who · ${hideSecond ? '?' : handValue(h)}', style: const TextStyle(fontSize: 18, color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, children: [for (var i = 0; i < h.length; i++) playingCard(hideSecond && i == 1 ? null : h[i])]),
      ]);

  @override
  Widget build(BuildContext context) => page(
        tr('Blackjack', 'ব্ল্যাকজ্যাক'),
        felt(Container(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            hand(tr('Dealer', 'ডিলার'), dealer, hideSecond: playing),
            Expanded(child: Center(child: Text(msg, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)))),
            hand(tr('You', 'আপনি'), player),
            const SizedBox(height: 20),
            if (playing)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FilledButton(onPressed: hit, child: Text(tr('Hit', 'হিট'))),
                const SizedBox(width: 16),
                FilledButton.tonal(onPressed: () => setState(stand), child: Text(tr('Stand', 'স্ট্যান্ড'))),
              ])
            else
              Column(children: [
                SegmentedButton<int>(
                  segments: [for (final b in [10, 25, 50]) ButtonSegment(value: b, label: Text('$b'), enabled: b <= chips)],
                  selected: {bet},
                  onSelectionChanged: (s) => setState(() => bet = s.first),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: chips >= bet ? deal : null, icon: const Icon(Icons.style), label: Text(tr('Deal · bet $bet', 'বাঁটুন · বাজি $bet'))),
              ]),
          ]),
        )),
        '🪙 $chips',
      );
}

// ---------- Crazy Eights ----------

class CrazyEights extends StatefulWidget {
  const CrazyEights({super.key});
  @override
  State<CrazyEights> createState() => _CrazyEightsState();
}

class _CrazyEightsState extends State<CrazyEights> {
  late List<int> deck, pile, you, ai;
  late int suit; // current suit (an 8 can change it)
  bool yourTurn = true, over = false;
  String msg = '';

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    deck = newDeck();
    you = [for (var i = 0; i < 7; i++) deck.removeLast()];
    ai = [for (var i = 0; i < 7; i++) deck.removeLast()];
    var first = deck.removeLast();
    while (rankOf(first) == 8) {
      deck.insert(0, first);
      first = deck.removeLast();
    }
    pile = [first];
    suit = suitOf(first);
    yourTurn = true;
    over = false;
    msg = tr('Match suit or rank. 8s are wild!', 'রং বা মান মেলান। 8 যেকোনো জায়গায় চলে!');
  }

  bool playable(int c) => rankOf(c) == 8 || suitOf(c) == suit || rankOf(c) == rankOf(pile.last);

  int? draw() {
    if (deck.isEmpty && pile.length > 1) {
      deck = pile.sublist(0, pile.length - 1)..shuffle(_r);
      pile = [pile.last];
    }
    return deck.isEmpty ? null : deck.removeLast();
  }

  bool checkWin(List<int> hand, bool isYou) {
    if (hand.isNotEmpty) return false;
    over = true;
    showResult(context, won: isYou, isYou ? tr('You win! 🎉', 'আপনি জিতেছেন! 🎉') : tr('AI wins', 'কম্পিউটার জিতেছে'), () => setState(start));
    return true;
  }

  Future<void> youPlay(int c) async {
    if (!yourTurn || over || !playable(c)) return;
    var s = suitOf(c);
    if (rankOf(c) == 8) {
      final picked = await showDialog<int>(
        context: context,
        builder: (d) => SimpleDialog(title: Text(tr('Choose a suit', 'রং বাছুন')), children: [
          for (var k = 0; k < 4; k++) SimpleDialogOption(onPressed: () => Navigator.pop(d, k), child: Text(suits[k], style: TextStyle(fontSize: 32, color: k == 1 || k == 2 ? Colors.red : null))),
        ]),
      );
      if (picked == null || !mounted) return;
      s = picked;
    }
    sfx('tap');
    setState(() {
      you.remove(c);
      pile.add(c);
      suit = s;
    });
    if (!checkWin(you, true)) aiTurn();
  }

  void youDraw() {
    final c = draw();
    if (c == null) {
      aiTurn(); // nothing left to draw: pass
      return;
    }
    setState(() => you.add(c));
    if (!playable(c)) aiTurn();
  }

  Future<void> aiTurn() async {
    setState(() {
      yourTurn = false;
      msg = tr('AI is thinking…', 'কম্পিউটার ভাবছে…');
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    var options = ai.where(playable).toList()..sort((a, b) => (rankOf(a) == 8 ? 1 : 0) - (rankOf(b) == 8 ? 1 : 0)); // save 8s
    if (options.isEmpty) {
      final c = draw();
      if (c != null) ai.add(c);
      options = [if (c != null && playable(c)) c];
    }
    setState(() {
      if (options.isEmpty) {
        msg = tr('AI drew a card. Your turn!', 'কম্পিউটার একটা তাস তুলেছে। আপনার পালা!');
      } else {
        final c = options.first;
        ai.remove(c);
        pile.add(c);
        suit = suitOf(c);
        if (rankOf(c) == 8) {
          final counts = List.filled(4, 0);
          for (final h in ai) {
            counts[suitOf(h)]++;
          }
          suit = counts.indexOf(counts.reduce(max));
          msg = tr('AI played an 8 → ${suits[suit]}. Your turn!', 'কম্পিউটার 8 দিয়েছে → ${suits[suit]}। আপনার পালা!');
        } else {
          msg = tr('Your turn!', 'আপনার পালা!');
        }
      }
      yourTurn = true;
    });
    checkWin(ai, false);
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = you.any(playable);
    return page(
      tr('Crazy Eights', 'ক্রেজি এইটস'),
      felt(Container(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text(tr('AI · ${ai.length} cards', 'কম্পিউটার · ${ai.length}টি তাস'), style: const TextStyle(color: Colors.white70)),
          SizedBox(height: 70, child: Stack(alignment: Alignment.center, children: [for (var i = 0; i < ai.length; i++) Positioned(left: 20.0 + i * 14, child: playingCard(null, w: 40))])),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(onTap: yourTurn && !over && !canPlay ? youDraw : null, child: Column(children: [playingCard(null), Text(canPlay ? tr('Deck', 'ডেক') : tr('Tap to draw', 'তুলতে চাপুন'), style: const TextStyle(color: Colors.white70))])),
                const SizedBox(width: 24),
                Column(children: [playingCard(pile.last), Text(tr('Suit: ${suits[suit]}', 'রং: ${suits[suit]}'), style: const TextStyle(color: Colors.white70))]),
              ]),
              const SizedBox(height: 16),
              Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            ]),
          ),
          Text(tr('Your hand', 'আপনার তাস'), style: const TextStyle(color: Colors.white70)),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(alignment: WrapAlignment.center, children: [
                for (final c in you..sort()) playingCard(c, dim: !yourTurn || !playable(c), onTap: () => youPlay(c)),
              ]),
            ),
          ),
        ]),
      )),
      yourTurn ? tr('Your turn', 'আপনার পালা') : tr('AI turn', 'কম্পিউটারের পালা'),
    );
  }
}

// ---------- Higher or Lower ----------

class HigherLower extends StatefulWidget {
  const HigherLower({super.key});
  @override
  State<HigherLower> createState() => _HigherLowerState();
}

class _HigherLowerState extends State<HigherLower> {
  List<int> deck = newDeck();
  late int card = deck.removeLast();
  int streak = 0;
  String msg = tr('Will the next card be higher or lower?', 'পরের তাস বড় হবে না ছোট?');

  void guess(bool higher) {
    if (deck.isEmpty) deck = newDeck();
    final next = deck.removeLast(), a = rankOf(card), b = rankOf(next);
    setState(() => card = next);
    if (a == b) {
      sfx('tap');
      setState(() => msg = tr('Same rank — free pass!', 'একই মান — ফ্রি পাস!'));
    } else if ((b > a) == higher) {
      sfx('right');
      setState(() {
        streak++;
        msg = tr('Correct!', 'ঠিক!');
      });
    } else {
      final s = streak;
      showResult(context, won: false, score: s, unit: ' streak', tr('Streak: $s', 'টানা: $s'), () => setState(() {
            streak = 0;
            deck = newDeck();
            card = deck.removeLast();
            msg = tr('Will the next card be higher or lower?', 'পরের তাস বড় হবে না ছোট?');
          }));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Higher or Lower', 'বড় না ছোট'),
        felt(Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(msg, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(card), child: playingCard(card, w: 120))),
            const SizedBox(height: 8),
            Text(tr('Aces are low', 'টেক্কা সবচেয়ে ছোট'), style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FilledButton.icon(onPressed: () => guess(true), icon: const Icon(Icons.arrow_upward), label: Text(tr('Higher', 'বড়'))),
              const SizedBox(width: 16),
              FilledButton.icon(onPressed: () => guess(false), icon: const Icon(Icons.arrow_downward), label: Text(tr('Lower', 'ছোট'))),
            ]),
          ])),
        tr('Streak $streak', 'টানা $streak'),
      );
}
