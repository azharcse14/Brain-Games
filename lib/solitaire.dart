import 'dart:math';

import 'package:flutter/material.dart';

import 'games.dart';
import 'tabletop.dart';

final _r = Random();

final solitaireGames = <Game>[
  Game('Klondike Draw 1', 'Cards', () => const Klondike(), glyph: 'K1', bn: 'ক্লনডাইক ড্র 1'),
  Game('Klondike Draw 3', 'Cards', () => const Klondike(draw: 3), glyph: 'K3', bn: 'ক্লনডাইক ড্র 3'),
  Game('Yukon', 'Cards', () => const Klondike(yukon: true), glyph: '🏔️', bn: 'ইউকন'),
  Game('FreeCell', 'Cards', () => const FreeCell(), glyph: '🆓', bn: 'ফ্রিসেল'),
  Game('Spider 1 Suit', 'Cards', () => const Spider(1), glyph: '🕷️', bn: 'স্পাইডার 1 স্যুট'),
  Game('Spider 2 Suits', 'Cards', () => const Spider(2), glyph: '🕸️', bn: 'স্পাইডার 2 স্যুট'),
  Game('Spider 4 Suits', 'Cards', () => const Spider(4), glyph: '🕷4', bn: 'স্পাইডার 4 স্যুট'),
  Game('Pyramid Solitaire', 'Cards', () => const Pyramid(), glyph: '🔺', bn: 'পিরামিড সলিটেয়ার'),
  Game('TriPeaks', 'Cards', () => const TriPeaks(), glyph: '⛰️', bn: 'ট্রাইপিকস'),
  Game('Golf Solitaire', 'Cards', () => const Golf(), glyph: '⛳', bn: 'গলফ সলিটেয়ার'),
  Game('Clock Solitaire', 'Cards', () => const ClockSolitaire(), glyph: '🕰️', bn: 'ঘড়ি সলিটেয়ার'),
  Game('Accordion', 'Cards', () => const Accordion(), glyph: '🪗', bn: 'অ্যাকর্ডিয়ন'),
  Game('Video Poker Jacks or Better', 'Cards', () => const VideoPoker(), glyph: '🎰', bn: 'ভিডিও পোকার জ্যাকস অর বেটার'),
  Game('Video Poker Deuces Wild', 'Cards', () => const VideoPoker(deuces: true), glyph: '2️⃣', bn: 'ভিডিও পোকার ডিউসেস ওয়াইল্ড'),
  Game('Baccarat', 'Cards', () => const Baccarat(), glyph: '🎴', bn: 'ব্যাকারা'),
  Game('Red Dog', 'Cards', () => const RedDog(), glyph: '🐕', bn: 'রেড ডগ'),
  Game('War', 'Cards', () => const War(), glyph: '⚔️🃏', bn: 'যুদ্ধ'),
  Game('Go Fish', 'Cards', () => const GoFish(), glyph: '🎣', bn: 'গো ফিশ'),
  Game('Old Maid', 'Cards', () => const OldMaid(), glyph: '👵', bn: 'ওল্ড মেইড'),
  Game('Yahtzee', 'Board', () => const Yahtzee(), glyph: '🎲🎲', bn: 'ইয়াতজি'),
  Game('Farkle', 'Board', () => const Farkle(), glyph: '🔥', bn: 'ফার্কল'),
  Game('Shut the Box', 'Board', () => const ShutTheBox(), glyph: '📦', bn: 'শাট দ্য বক্স'),
  Game('Dice Poker', 'Board', () => const DicePoker(), glyph: '🎲♠', bn: 'ডাইস পোকার'),
];

// ---------- shared ----------

/// Face-down cards are stored as card + [hidden].
const hidden = 100;
bool up(int c) => c < hidden;
bool isRed(int c) => suitOf(c % hidden) == 1 || suitOf(c % hidden) == 2;

bool canFound(int c, List<int> f) => f.isEmpty ? rankOf(c) == 1 : suitOf(f.last) == suitOf(c) && rankOf(f.last) + 1 == rankOf(c);

/// Klondike-style build: alternate colours, one rank down; only a King on an empty column.
bool canStack(int c, List<int> t) => t.isEmpty ? rankOf(c) == 13 : up(t.last) && isRed(t.last) != isRed(c) && rankOf(t.last) == rankOf(c) + 1;

/// Cards from [i] to the end form an alternating-colour descending run.
bool isAltRun(List<int> t, int i) {
  for (var k = i; k < t.length - 1; k++) {
    if (!up(t[k]) || isRed(t[k]) == isRed(t[k + 1]) || rankOf(t[k]) != rankOf(t[k + 1]) + 1) return false;
  }
  return i < t.length && up(t.last);
}

/// Cards from [i] to the end form a same-suit descending run (Spider).
bool isSuitRun(List<int> t, int i) {
  for (var k = i; k < t.length - 1; k++) {
    if (!up(t[k]) || suitOf(t[k]) != suitOf(t[k + 1]) || rankOf(t[k]) != rankOf(t[k + 1]) + 1) return false;
  }
  return i < t.length && up(t.last);
}

/// FreeCell supermove: (free cells + 1) × 2^(empty columns).
int freeCellMax(int freeCells, int emptyCols) => (freeCells + 1) << emptyCols;

/// Green card table. Always dark-themed, so text and buttons on it look the same whatever the phone's light/dark setting.
Widget felt(Widget child) => Theme(
      data: _feltTheme,
      child: DefaultTextStyle.merge(style: TextStyle(color: _feltTheme.colorScheme.onSurface), child: Container(color: Colors.green.shade900, child: child)),
    );
final _feltTheme = ThemeData(colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark);

/// A compact card with its label at the top, so overlapping stacks stay readable. null = empty slot.
Widget sCard(int? c, double w, {bool sel = false}) {
  final h = w * 1.4;
  if (c == null) {
    return Container(width: w, height: h, decoration: BoxDecoration(border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(5)));
  }
  return Container(
    width: w,
    height: h,
    alignment: Alignment.topCenter,
    padding: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      color: up(c) ? Colors.white : Colors.indigo,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: sel ? Colors.amber : Colors.black38, width: sel ? 3 : 1),
    ),
    child: up(c)
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(cardLabel(c), style: TextStyle(fontSize: w * .36, fontWeight: FontWeight.bold, color: isRed(c) ? Colors.red.shade700 : Colors.black)),
          )
        : null,
  );
}

/// A vertically fanned pile; [tap] gets the card index, or -1 for the empty slot.
Widget fan(List<int> pile, double w, void Function(int) tap, {int? selFrom}) {
  final h = w * 1.4, tops = <double>[];
  var y = 0.0;
  for (final c in pile) {
    tops.add(y);
    y += (up(c) ? .3 : .14) * h;
  }
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => tap(-1),
      child: SizedBox(
        width: w,
        height: pile.isEmpty ? h : tops.last + h,
        child: Stack(children: [
          if (pile.isEmpty) sCard(null, w),
          for (var i = 0; i < pile.length; i++)
            Positioned(top: tops[i], child: GestureDetector(onTap: () => tap(i), child: sCard(pile[i], w, sel: selFrom != null && i >= selFrom))),
        ]),
      ),
    ),
  );
}

/// Top card of a pile (or an empty slot).
Widget topOf(List<int> pile, double w, VoidCallback onTap, {bool sel = false, String? label}) => GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Stack(alignment: Alignment.center, children: [
          sCard(pile.isEmpty ? null : pile.last, w, sel: sel),
          if (label != null) Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        ]),
      ),
    );

Widget tools(VoidCallback undo, VoidCallback restart, [List<Widget> extra = const []]) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
        OutlinedButton.icon(onPressed: undo, icon: const Icon(Icons.undo), label: Text(tr('Undo', 'আনডু'))),
        OutlinedButton.icon(onPressed: restart, icon: const Icon(Icons.refresh), label: Text(tr('New', 'নতুন'))),
        ...extra,
      ]),
    );

/// Pile state with an undo history and a (pile, index) selection.
mixin Piles<T extends StatefulWidget> on State<T> {
  List<List<int>> p = [];
  final hist = <List<List<int>>>[];
  final sw = Stopwatch();
  (int, int)? sel;
  int moves = 0;

  void save() {
    hist.add([for (final x in p) x.toList()]);
    moves++;
  }

  void undo() {
    if (hist.isEmpty) return;
    setState(() {
      p = hist.removeLast();
      sel = null;
    });
  }

  void fresh() {
    hist.clear();
    sel = null;
    moves = 0;
    sw
      ..reset()
      ..start();
  }

  /// Moves cards [i].. of [from] onto [to] and turns up the newly exposed card.
  void shift(int from, int i, int to) {
    p[to].addAll(p[from].sublist(i));
    p[from].removeRange(i, p[from].length);
    if (p[from].isNotEmpty && !up(p[from].last)) p[from].last -= hidden;
  }

  void solved(VoidCallback again) {
    sw.stop();
    final s = sw.elapsed.inSeconds;
    showResult(context, score: s, lower: true, unit: ' s', tr('Solved in ${s ~/ 60}m ${s % 60}s · $moves moves', 'সমাধান ${s ~/ 60}মি ${s % 60}সে · $moves চাল'), () => setState(again));
  }
}

// ---------- Klondike & Yukon ----------

class Klondike extends StatefulWidget {
  const Klondike({super.key, this.draw = 1, this.yukon = false});
  final int draw;
  final bool yukon;
  @override
  State<Klondike> createState() => _KlondikeState();
}

// Piles: 0 stock, 1 waste, 2–5 foundations, 6–12 tableau.
class _KlondikeState extends State<Klondike> with Piles {
  @override
  void initState() {
    super.initState();
    deal();
  }

  void deal() {
    final d = newDeck();
    p = List.generate(13, (_) => <int>[]);
    for (var c = 0; c < 7; c++) {
      final n = widget.yukon && c > 0 ? c + 5 : c + 1;
      for (var k = 0; k < n; k++) {
        p[6 + c].add(d.removeLast() + (k < c ? hidden : 0));
      }
    }
    p[0] = [for (final c in d) c + hidden];
    fresh();
  }

  bool tryMove(int from, int i, int to) {
    final c = p[from][i], n = p[from].length - i;
    final ok = to >= 2 && to <= 5 ? n == 1 && canFound(c, p[to]) : to >= 6 && canStack(c, p[to]);
    if (!ok) return false;
    save();
    setState(() {
      shift(from, i, to);
      sel = null;
    });
    sfx('tap');
    if ([2, 3, 4, 5].every((f) => p[f].length == 13)) solved(deal);
    return true;
  }

  void drawStock() {
    if (p[0].isEmpty && p[1].isEmpty) return;
    save();
    setState(() {
      sel = null;
      if (p[0].isEmpty) {
        p[0] = [for (final c in p[1].reversed) c + hidden];
        p[1] = [];
      } else {
        for (var k = 0; k < widget.draw && p[0].isNotEmpty; k++) {
          p[1].add(p[0].removeLast() - hidden);
        }
      }
    });
  }

  void tap(int pile, int i) {
    if (pile == 0) return drawStock();
    final pl = p[pile], idx = pile >= 6 ? i : pl.length - 1, s = sel;
    if (s != null && s.$1 != pile && tryMove(s.$1, s.$2, pile)) return;
    if (s != null && s == (pile, idx)) {
      // second tap on the same card: send it to a foundation
      setState(() => sel = null);
      if (idx == pl.length - 1) {
        for (var f = 2; f <= 5; f++) {
          if (tryMove(pile, idx, f)) return;
        }
      }
      return;
    }
    setState(() => sel = idx >= 0 && idx < pl.length && up(pl[idx]) ? (pile, idx) : null);
  }

  Widget waste(double w) {
    final vis = p[1].length <= widget.draw ? p[1] : p[1].sublist(p[1].length - widget.draw);
    return GestureDetector(
      onTap: () => tap(1, p[1].length - 1),
      child: SizedBox(
        width: 2 * w + 8,
        height: w * 1.4 + 4,
        child: Stack(children: [
          if (vis.isEmpty) Positioned(left: 2, top: 2, child: sCard(null, w)),
          for (var k = 0; k < vis.length; k++) Positioned(left: 2 + k * w * .45, top: 2, child: sCard(vis[k], w, sel: sel?.$1 == 1 && k == vis.length - 1)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => page(
        widget.yukon ? tr('Yukon', 'ইউকন') : tr('Klondike · Draw ${widget.draw}', 'ক্লনডাইক · ড্র ${widget.draw}'),
        felt(LayoutBuilder(builder: (_, box) {
          final w = min(56.0, (box.maxWidth - 8) / 7 - 4);
          return Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!widget.yukon) ...[topOf(p[0], w, () => drawStock(), label: p[0].isEmpty ? '↻' : null), waste(w)],
              for (var f = 2; f <= 5; f++) topOf(p[f], w, () => tap(f, p[f].length - 1), sel: sel?.$1 == f),
            ]),
            Expanded(
              child: SingleChildScrollView(
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var t = 6; t < 13; t++) fan(p[t], w, (i) => tap(t, i), selFrom: sel?.$1 == t ? sel!.$2 : null),
                ]),
              ),
            ),
            tools(undo, () => setState(deal)),
          ]);
        })),
        tr('Moves $moves', 'চাল $moves'),
      );
}

// ---------- FreeCell ----------

class FreeCell extends StatefulWidget {
  const FreeCell({super.key});
  @override
  State<FreeCell> createState() => _FreeCellState();
}

// Piles: 0–3 free cells, 4–7 foundations, 8–15 tableau.
class _FreeCellState extends State<FreeCell> with Piles {
  @override
  void initState() {
    super.initState();
    deal();
  }

  void deal() {
    final d = newDeck();
    p = List.generate(16, (_) => <int>[]);
    for (var i = 0; i < 52; i++) {
      p[8 + i % 8].add(d[i]);
    }
    fresh();
  }

  int maxMove(int to) => freeCellMax(
        [for (var k = 0; k < 4; k++) if (p[k].isEmpty) k].length,
        [for (var k = 8; k < 16; k++) if (p[k].isEmpty && k != to) k].length,
      );

  bool tryMove(int from, int i, int to) {
    final c = p[from][i], n = p[from].length - i;
    final ok = to < 4
        ? n == 1 && p[to].isEmpty
        : to < 8
            ? n == 1 && canFound(c, p[to])
            : (p[to].isEmpty || canStack(c, p[to])) && n <= maxMove(to);
    if (!ok) return false;
    save();
    setState(() {
      shift(from, i, to);
      sel = null;
    });
    sfx('tap');
    if ([4, 5, 6, 7].every((f) => p[f].length == 13)) solved(deal);
    return true;
  }

  void tap(int pile, int i) {
    final pl = p[pile], idx = pile >= 8 ? i : pl.length - 1, s = sel;
    if (s != null && s.$1 != pile && tryMove(s.$1, s.$2, pile)) return;
    if (s != null && s == (pile, idx)) {
      setState(() => sel = null);
      if (idx == pl.length - 1) {
        for (var f = 4; f < 8; f++) {
          if (tryMove(pile, idx, f)) return;
        }
      }
      return;
    }
    setState(() => sel = idx >= 0 && idx < pl.length && (pile < 8 || isAltRun(pl, idx)) ? (pile, idx) : null);
  }

  @override
  Widget build(BuildContext context) => page(
        tr('FreeCell', 'ফ্রিসেল'),
        felt(LayoutBuilder(builder: (_, box) {
          final w = min(52.0, (box.maxWidth - 8) / 8 - 4);
          return Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var k = 0; k < 8; k++) topOf(p[k], w, () => tap(k, p[k].length - 1), sel: sel?.$1 == k),
            ]),
            Expanded(
              child: SingleChildScrollView(
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var t = 8; t < 16; t++) fan(p[t], w, (i) => tap(t, i), selFrom: sel?.$1 == t ? sel!.$2 : null),
                ]),
              ),
            ),
            tools(undo, () => setState(deal)),
          ]);
        })),
        tr('Moves $moves', 'চাল $moves'),
      );
}

// ---------- Spider ----------

/// A completed K→A same-suit run at the end of a column, or false.
bool spiderComplete(List<int> col) => col.length >= 13 && isSuitRun(col, col.length - 13) && rankOf(col[col.length - 13]) == 13;

class Spider extends StatefulWidget {
  const Spider(this.suits, {super.key});
  final int suits;
  @override
  State<Spider> createState() => _SpiderState();
}

// Piles: 0 stock, 1 completed runs, 2–11 tableau.
class _SpiderState extends State<Spider> with Piles {
  @override
  void initState() {
    super.initState();
    deal();
  }

  void deal() {
    final s = widget.suits;
    final cards = [
      for (var k = 0; k < 8; k++)
        for (var r = 0; r < 13; r++) (s == 1 ? 0 : (s == 2 ? k % 2 : k % 4)) * 13 + r,
    ]..shuffle(_r);
    p = List.generate(12, (_) => <int>[]);
    for (var c = 0; c < 10; c++) {
      final n = c < 4 ? 6 : 5;
      for (var k = 0; k < n; k++) {
        p[2 + c].add(cards.removeLast() + (k < n - 1 ? hidden : 0));
      }
    }
    p[0] = [for (final c in cards) c + hidden];
    fresh();
  }

  void collect(int t) {
    if (!spiderComplete(p[t])) return;
    p[1].add(p[t][p[t].length - 13]);
    p[t].removeRange(p[t].length - 13, p[t].length);
    if (p[t].isNotEmpty && !up(p[t].last)) p[t].last -= hidden;
    sfx('right');
  }

  void afterMove() {
    if (p[1].length == 8) solved(deal);
  }

  // ponytail: dealing is allowed even with an empty column (the classic rule forbids it).
  void dealRow() {
    if (p[0].isEmpty) return;
    save();
    setState(() {
      sel = null;
      for (var c = 2; c < 12 && p[0].isNotEmpty; c++) {
        p[c].add(p[0].removeLast() - hidden);
      }
      for (var c = 2; c < 12; c++) {
        collect(c);
      }
    });
    afterMove();
  }

  void tap(int pile, int i) {
    final s = sel;
    if (s != null && s.$1 != pile) {
      final c = p[s.$1][s.$2], t = p[pile];
      if (t.isEmpty || (up(t.last) && rankOf(t.last) == rankOf(c) + 1)) {
        save();
        setState(() {
          shift(s.$1, s.$2, pile);
          collect(pile);
          sel = null;
        });
        sfx('tap');
        afterMove();
        return;
      }
    }
    setState(() => sel = i >= 0 && s != (pile, i) && isSuitRun(p[pile], i) ? (pile, i) : null);
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Spider · ${widget.suits} Suit${widget.suits > 1 ? 's' : ''}', 'স্পাইডার · ${widget.suits} স্যুট'),
        felt(LayoutBuilder(builder: (_, box) {
          final w = min(44.0, (box.maxWidth - 8) / 10 - 4);
          return Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              topOf(p[0], w, dealRow, label: p[0].isEmpty ? null : '${p[0].length ~/ 10}'),
              Padding(padding: const EdgeInsets.all(8), child: Text(tr('Runs ${p[1].length}/8', 'সিরিজ ${p[1].length}/8'), style: const TextStyle(fontWeight: FontWeight.bold))),
            ]),
            Expanded(
              child: SingleChildScrollView(
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var t = 2; t < 12; t++) fan(p[t], w, (i) => tap(t, i), selFrom: sel?.$1 == t ? sel!.$2 : null),
                ]),
              ),
            ),
            tools(undo, () => setState(deal)),
          ]);
        })),
        tr('Moves $moves', 'চাল $moves'),
      );
}

// ---------- Pyramid ----------

int pyrRow(int i) {
  var r = 0;
  while ((r + 1) * (r + 2) ~/ 2 <= i) {
    r++;
  }
  return r;
}

/// Whether pyramid slot [i] is uncovered (both cards below it are gone). Removed slots are -1.
bool pyrFree(List<int> pyr, int i) {
  final r = pyrRow(i);
  if (r == 6) return true;
  final below = (r + 1) * (r + 2) ~/ 2 + i - r * (r + 1) ~/ 2;
  return pyr[below] < 0 && pyr[below + 1] < 0;
}

class Pyramid extends StatefulWidget {
  const Pyramid({super.key});
  @override
  State<Pyramid> createState() => _PyramidState();
}

// Piles: 0 pyramid (28 slots, -1 = removed), 1 stock, 2 waste, 3 [recycles left].
class _PyramidState extends State<Pyramid> with Piles {
  @override
  void initState() {
    super.initState();
    deal();
  }

  void deal() {
    final d = newDeck();
    p = [d.sublist(0, 28), d.sublist(28), [], [2]];
    fresh();
  }

  List<int> avail() => [for (var i = 0; i < 28; i++) if (p[0][i] >= 0 && pyrFree(p[0], i)) p[0][i], if (p[2].isNotEmpty) p[2].last];

  int cardAt((int, int) s) => s.$1 == 0 ? p[0][s.$2] : p[2].last;

  void remove((int, int) s) => s.$1 == 0 ? p[0][s.$2] = -1 : p[2].removeLast();

  void tap(int pile, int i) {
    if (pile == 1) {
      if (p[1].isEmpty && (p[3][0] == 0 || p[2].isEmpty)) return;
      save();
      setState(() {
        sel = null;
        if (p[1].isNotEmpty) {
          p[2].add(p[1].removeLast());
        } else {
          p[1] = p[2].reversed.toList();
          p[2] = [];
          p[3][0]--;
        }
      });
      return check();
    }
    if (pile == 0 && (p[0][i] < 0 || !pyrFree(p[0], i))) return;
    if (pile == 2 && p[2].isEmpty) return;
    final here = (pile, pile == 0 ? i : p[2].length - 1), s = sel;
    if (rankOf(cardAt(here)) == 13) {
      save();
      setState(() {
        remove(here);
        sel = null;
      });
    } else if (s != null && s != here && rankOf(cardAt(s)) + rankOf(cardAt(here)) == 13) {
      save();
      setState(() {
        // remove the waste card last so pyramid indexes stay valid
        for (final x in s.$1 == 2 ? [here, s] : [s, here]) {
          remove(x);
        }
        sel = null;
      });
    } else {
      return setState(() => sel = s == here ? null : here);
    }
    sfx('right');
    check();
  }

  void check() {
    if (p[0].every((c) => c < 0)) return solved(deal);
    final a = avail();
    final canPair = a.any((x) => rankOf(x) == 13) || [for (var i = 0; i < a.length; i++) for (var j = i + 1; j < a.length; j++) rankOf(a[i]) + rankOf(a[j]) == 13].contains(true);
    if (!canPair && p[1].isEmpty && (p[3][0] == 0 || p[2].isEmpty)) {
      showResult(context, won: false, tr('No more moves · ${p[0].where((c) => c >= 0).length} cards left', 'আর চাল নেই · ${p[0].where((c) => c >= 0).length}টি তাস বাকি'), () => setState(deal));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Pyramid', 'পিরামিড'),
        felt(LayoutBuilder(builder: (_, box) {
          final w = min(50.0, (box.maxWidth - 16) / 7), h = w * 1.4;
          return Column(children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(tr('Remove pairs that add up to 13 (J=11, Q=12, K=13 alone)', 'যোগফল 13 হয় এমন জোড়া সরান (J=11, Q=12, K একাই 13)'), style: const TextStyle(color: Colors.white70))),
            SizedBox(
              width: 7 * w,
              height: 4 * h,
              child: Stack(children: [
                for (var i = 0; i < 28; i++)
                  if (p[0][i] >= 0)
                    Positioned(
                      left: (6 - pyrRow(i)) * w / 2 + (i - pyrRow(i) * (pyrRow(i) + 1) ~/ 2) * w,
                      top: pyrRow(i) * h * .5,
                      child: GestureDetector(onTap: () => tap(0, i), child: sCard(p[0][i], w - 2, sel: sel == (0, i))),
                    ),
              ]),
            ),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              topOf([for (final c in p[1]) c + hidden], w, () => tap(1, 0), label: p[1].isEmpty ? (p[3][0] > 0 ? '↻' : '✕') : '${p[1].length}'),
              topOf(p[2], w, () => tap(2, 0), sel: sel?.$1 == 2),
              Text(tr('  Recycles: ${p[3][0]}', '  আবার ঘোরানো: ${p[3][0]}')),
            ]),
            tools(undo, () => setState(deal)),
          ]);
        })),
        tr('Moves $moves', 'চাল $moves'),
      );
}

// ---------- TriPeaks ----------

/// For each of the 28 TriPeaks slots: the slots covering it, and its x position in card widths.
final triCover = () {
  final cover = List.generate(28, (_) => <int>[]);
  for (var j = 0; j < 9; j++) {
    cover[9 + j] = [18 + j, 19 + j];
  }
  for (var j = 0; j < 6; j++) {
    cover[3 + j] = [9 + j + j ~/ 2, 10 + j + j ~/ 2];
  }
  for (var k = 0; k < 3; k++) {
    cover[k] = [3 + 2 * k, 4 + 2 * k];
  }
  return cover;
}();

double triX(int i) => i >= 18 ? i - 18.0 : (i >= 9 ? i - 9 + .5 : (i >= 3 ? (i - 3) + (i - 3) ~/ 2 + 1.0 : 3 * i + 1.5));
int triRow(int i) => i >= 18 ? 3 : (i >= 9 ? 2 : (i >= 3 ? 1 : 0));
bool neighbours(int a, int b) => (rankOf(a) - rankOf(b)).abs() == 1 || (rankOf(a) - rankOf(b)).abs() == 12;

class TriPeaks extends StatefulWidget {
  const TriPeaks({super.key});
  @override
  State<TriPeaks> createState() => _TriPeaksState();
}

// Piles: 0 peaks (28 slots, -1 = removed), 1 stock, 2 waste.
class _TriPeaksState extends State<TriPeaks> with Piles {
  @override
  void initState() {
    super.initState();
    deal();
  }

  void deal() {
    final d = newDeck();
    p = [d.sublist(0, 28), d.sublist(29), [d[28]]];
    fresh();
  }

  bool free(int i) => triCover[i].every((j) => p[0][j] < 0);

  void tap(int i) {
    if (p[0][i] < 0 || !free(i) || !neighbours(p[0][i], p[2].last)) return sfx('wrong');
    save();
    setState(() {
      p[2].add(p[0][i]);
      p[0][i] = -1;
    });
    sfx('tap');
    check();
  }

  void draw() {
    if (p[1].isEmpty) return;
    save();
    setState(() => p[2].add(p[1].removeLast()));
    check();
  }

  void check() {
    if (p[0].every((c) => c < 0)) return solved(deal);
    final playable = [for (var i = 0; i < 28; i++) p[0][i] >= 0 && free(i) && neighbours(p[0][i], p[2].last)].contains(true);
    if (p[1].isEmpty && !playable) showResult(context, won: false, tr('No more moves · ${p[0].where((c) => c >= 0).length} cards left', 'আর চাল নেই · ${p[0].where((c) => c >= 0).length}টি তাস বাকি'), () => setState(deal));
  }

  @override
  Widget build(BuildContext context) => page(
        tr('TriPeaks', 'ট্রাইপিকস'),
        felt(LayoutBuilder(builder: (_, box) {
          final w = min(40.0, (box.maxWidth - 16) / 10), h = w * 1.4;
          return Column(children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(tr('Play a card one higher or lower than the pile (A–K wrap)', 'গাদার তাসের চেয়ে এক বড় বা এক ছোট তাস খেলুন (A–K ঘুরে আসে)'), style: const TextStyle(color: Colors.white70))),
            SizedBox(
              width: 10 * w,
              height: 3 * h * .5 + h,
              child: Stack(children: [
                for (var i = 0; i < 28; i++)
                  if (p[0][i] >= 0)
                    Positioned(
                      left: triX(i) * w,
                      top: triRow(i) * h * .5,
                      child: GestureDetector(onTap: () => tap(i), child: sCard(free(i) ? p[0][i] : p[0][i] + hidden, w - 2)),
                    ),
              ]),
            ),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              topOf([for (final c in p[1]) c + hidden], 50, draw, label: '${p[1].length}'),
              topOf(p[2], 50, () {}),
            ]),
            tools(undo, () => setState(deal)),
          ]);
        })),
        tr('Moves $moves', 'চাল $moves'),
      );
}

// ---------- Golf ----------

class Golf extends StatefulWidget {
  const Golf({super.key});
  @override
  State<Golf> createState() => _GolfState();
}

// Piles: 0–6 columns, 7 stock, 8 waste.
class _GolfState extends State<Golf> with Piles {
  @override
  void initState() {
    super.initState();
    deal();
  }

  void deal() {
    final d = newDeck();
    p = [for (var c = 0; c < 7; c++) d.sublist(c * 5, c * 5 + 5), d.sublist(36), [d[35]]];
    fresh();
  }

  bool fits(int c) => rankOf(p[8].last) != 13 && (rankOf(c) - rankOf(p[8].last)).abs() == 1;

  void tap(int col) {
    if (p[col].isEmpty || !fits(p[col].last)) return sfx('wrong');
    save();
    setState(() => p[8].add(p[col].removeLast()));
    sfx('tap');
    check();
  }

  void draw() {
    if (p[7].isEmpty) return;
    save();
    setState(() => p[8].add(p[7].removeLast()));
    check();
  }

  void check() {
    final left = [for (var c = 0; c < 7; c++) p[c].length].reduce((a, b) => a + b);
    final canPlay = [for (var c = 0; c < 7; c++) p[c].isNotEmpty && fits(p[c].last)].contains(true);
    if (left == 0 || (p[7].isEmpty && !canPlay)) {
      showResult(context, won: left == 0, score: left, lower: true, unit: ' left', left == 0 ? tr('Cleared! ⛳', 'সব সাফ! ⛳') : tr('$left cards left', '$leftটি তাস বাকি'), () => setState(deal));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Golf', 'গলফ'),
        felt(LayoutBuilder(builder: (_, box) {
          final w = min(52.0, (box.maxWidth - 8) / 7 - 4);
          return Column(children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(tr('Play column tops one higher or lower than the pile. Nothing goes on a King.', 'কলামের উপরের তাস গাদার চেয়ে এক বড় বা ছোট হলে খেলুন। K-এর উপর কিছু যায় না।'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
            Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var c = 0; c < 7; c++) fan(p[c], w, (_) => tap(c)),
            ]),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              topOf([for (final c in p[7]) c + hidden], 56, draw, label: '${p[7].length}'),
              topOf(p[8], 56, () {}),
            ]),
            tools(undo, () => setState(deal)),
          ]);
        })),
        tr('Moves $moves', 'চাল $moves'),
      );
}

// ---------- Clock Solitaire ----------

class ClockSolitaire extends StatefulWidget {
  const ClockSolitaire({super.key});
  @override
  State<ClockSolitaire> createState() => _ClockSolitaireState();
}

// Piles 0–11 are the hours (A…Q), 12 the centre (K). Face-down cards sit on top of the face-up ones.
class _ClockSolitaireState extends State<ClockSolitaire> {
  late List<List<int>> p;
  int? held;

  @override
  void initState() {
    super.initState();
    deal();
  }

  void deal() {
    final d = newDeck();
    p = [for (var k = 0; k < 13; k++) [for (var j = 0; j < 4; j++) d[k * 4 + j] + hidden]];
    held = p[12].removeLast() - hidden;
  }

  void tap(int pile) {
    final h = held;
    if (h == null) return;
    if (rankOf(h) - 1 != pile) return sfx('wrong');
    sfx('tap');
    setState(() {
      p[pile].insert(0, h);
      held = !up(p[pile].last) ? p[pile].removeLast() - hidden : null;
    });
    if (held == null) {
      final won = p.every((x) => x.every(up));
      showResult(context, won: won, won ? tr('Every card is face up! 🕰️', 'সব তাস উল্টে গেছে! 🕰️') : tr('The fourth King came up too soon', 'চতুর্থ K খুব আগে উঠে গেছে'), () => setState(deal));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        'Clock Solitaire',
        felt(LayoutBuilder(builder: (_, box) {
          const w = 40.0;
          final size = min(box.maxWidth, box.maxHeight - 150), r = size / 2 - w;
          Widget pileAt(int k) => GestureDetector(
                onTap: () => tap(k),
                child: Stack(alignment: Alignment.center, children: [
                  sCard(p[k].isEmpty ? null : (p[k].any((c) => !up(c)) ? p[k].last : p[k].first), w),
                  Positioned(bottom: 2, child: Text(k == 12 ? 'K' : const ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q'][k], style: const TextStyle(fontSize: 10, color: Colors.amber))),
                ]),
              );
          return Column(children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(children: [
                for (var k = 0; k < 12; k++)
                  Positioned(left: size / 2 - w / 2 + r * cos((k + 1) * pi / 6 - pi / 2), top: size / 2 - w * .7 + r * sin((k + 1) * pi / 6 - pi / 2), child: pileAt(k)),
                Positioned(left: size / 2 - w / 2, top: size / 2 - w * .7, child: pileAt(12)),
              ]),
            ),
            Text(tr('Tap the pile that matches your card', 'আপনার তাসের সাথে মেলে এমন গাদায় চাপুন'), style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            if (held != null) sCard(held, 56),
          ]);
        })),
        tr('Kings out: ${p[12].where(up).length}', 'K উঠেছে: ${p[12].where(up).length}'),
      );
}

// ---------- Accordion ----------

bool accMatch(int a, int b) => suitOf(a) == suitOf(b) || rankOf(a) == rankOf(b);

bool accordionHasMove(List<int> row) => [for (var i = 1; i < row.length; i++) accMatch(row[i], row[i - 1]) || (i >= 3 && accMatch(row[i], row[i - 3]))].contains(true);

class Accordion extends StatefulWidget {
  const Accordion({super.key});
  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> with Piles {
  @override
  void initState() {
    super.initState();
    deal();
  }

  void deal() {
    p = [newDeck()];
    fresh();
  }

  void tap(int i) {
    final s = sel, row = p[0];
    if (s != null && (i == s.$2 - 1 || i == s.$2 - 3) && accMatch(row[s.$2], row[i])) {
      save();
      setState(() {
        p[0][i] = p[0][s.$2];
        p[0].removeAt(s.$2);
        sel = null;
      });
      sfx('tap');
      if (!accordionHasMove(p[0])) {
        final n = p[0].length;
        showResult(context, won: n == 1, score: n, lower: true, unit: ' piles', n == 1 ? tr('One pile left! 🪗', 'মাত্র একটি গাদা বাকি! 🪗') : tr('$n piles left', '$nটি গাদা বাকি'), () => setState(deal));
      }
      return;
    }
    setState(() => sel = s == (0, i) || i == 0 ? null : (0, i));
  }

  @override
  Widget build(BuildContext context) => page(
        tr('Accordion', 'অ্যাকর্ডিয়ন'),
        felt(Column(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(tr('Tap a card, then the card 1 or 3 places to its left with the same suit or rank', 'একটি তাসে চাপুন, তারপর বাঁয়ে 1 বা 3 ঘর দূরের একই স্যুট বা র‍্যাঙ্কের তাসে'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: [
                for (var i = 0; i < p[0].length; i++) GestureDetector(onTap: () => tap(i), child: sCard(p[0][i], 34, sel: sel == (0, i))),
              ]),
            ),
          ),
          tools(undo, () => setState(deal)),
        ])),
        tr('${p[0].length} piles', '${p[0].length} গাদা'),
      );
}

// ---------- Video Poker ----------

/// Whether the distinct ranks (ace = 1) fit in 5 consecutive values, with wild cards filling gaps.
bool straightFits(List<int> ranks) {
  if (ranks.toSet().length != ranks.length) return false;
  if (ranks.isEmpty) return true;
  bool fits(List<int> rs) => rs.reduce(max) - rs.reduce(min) <= 4;
  return fits(ranks) || fits([for (final r in ranks) r == 1 ? 14 : r]);
}

Map<int, int> rankCounts(Iterable<int> cards) {
  final m = <int, int>{};
  for (final c in cards) {
    m[rankOf(c)] = (m[rankOf(c)] ?? 0) + 1;
  }
  return m;
}

String? jobHand(List<int> h) {
  final ranks = h.map(rankOf).toList(), counts = rankCounts(h);
  final cs = counts.values.toList()..sort((a, b) => b - a);
  final flush = h.map(suitOf).toSet().length == 1, straight = straightFits(ranks);
  if (straight && flush) return ranks.every((r) => r == 1 || r >= 10) ? 'Royal Flush' : 'Straight Flush';
  if (cs[0] == 4) return 'Four of a Kind';
  if (cs[0] == 3 && cs[1] == 2) return 'Full House';
  if (flush) return 'Flush';
  if (straight) return 'Straight';
  if (cs[0] == 3) return 'Three of a Kind';
  if (cs[0] == 2 && cs[1] == 2) return 'Two Pair';
  if (counts.entries.any((e) => e.value == 2 && (e.key == 1 || e.key >= 11))) return 'Jacks or Better';
  return null;
}

String? deucesHand(List<int> h) {
  final wild = h.where((c) => rankOf(c) == 2).length, rest = h.where((c) => rankOf(c) != 2).toList();
  final ranks = rest.map(rankOf).toList(), counts = rankCounts(rest);
  final top = counts.values.fold(0, max), pairs = counts.values.where((v) => v == 2).length;
  final flush = rest.map(suitOf).toSet().length <= 1, straight = straightFits(ranks), royal = ranks.every((r) => r == 1 || r >= 10);
  if (wild == 0 && flush && straight && royal) return 'Natural Royal';
  if (wild == 4) return 'Four Deuces';
  if (flush && straight && royal) return 'Wild Royal';
  if (top + wild >= 5) return 'Five of a Kind';
  if (flush && straight) return 'Straight Flush';
  if (top + wild >= 4) return 'Four of a Kind';
  if ((top == 3 && pairs == 1) || (wild == 1 && pairs == 2)) return 'Full House';
  if (flush) return 'Flush';
  if (straight) return 'Straight';
  if (top + wild >= 3) return 'Three of a Kind';
  return null;
}

// Pays per coin at max bet (5 coins): 9/6 Jacks or Better and full-pay Deuces Wild.
/// Bangla display names for poker hands and Yahtzee boxes; the English names stay the keys.
const handBn = {
  'Royal Flush': 'রয়্যাল ফ্লাশ', 'Straight Flush': 'স্ট্রেইট ফ্লাশ', 'Four of a Kind': 'চারটি একই', 'Full House': 'ফুল হাউস',
  'Flush': 'ফ্লাশ', 'Straight': 'স্ট্রেইট', 'Three of a Kind': 'তিনটি একই', 'Two Pair': 'দুই জোড়া', 'Jacks or Better': 'জ্যাকস অর বেটার',
  'Natural Royal': 'ন্যাচারাল রয়্যাল', 'Four Deuces': 'চারটি 2', 'Wild Royal': 'ওয়াইল্ড রয়্যাল', 'Five of a Kind': 'পাঁচটি একই',
  'Nothing': 'কিছুই না', 'Pair': 'এক জোড়া', 'Ones': 'এক', 'Twos': 'দুই', 'Threes': 'তিন', 'Fours': 'চার', 'Fives': 'পাঁচ', 'Sixes': 'ছয়',
  '3 of a Kind': '3টি একই', '4 of a Kind': '4টি একই', 'Small Straight': 'ছোট স্ট্রেইট', 'Large Straight': 'বড় স্ট্রেইট', 'Yahtzee': 'ইয়াতজি', 'Chance': 'চান্স',
};

String handName(String h) => tr(h, handBn[h] ?? h);

const jobPay = {'Royal Flush': 800, 'Straight Flush': 50, 'Four of a Kind': 25, 'Full House': 9, 'Flush': 6, 'Straight': 4, 'Three of a Kind': 3, 'Two Pair': 2, 'Jacks or Better': 1};
const deucesPay = {
  'Natural Royal': 800, 'Four Deuces': 200, 'Wild Royal': 25, 'Five of a Kind': 15, 'Straight Flush': 9, 'Four of a Kind': 5, //
  'Full House': 3, 'Flush': 2, 'Straight': 2, 'Three of a Kind': 1,
};

class VideoPoker extends StatefulWidget {
  const VideoPoker({super.key, this.deuces = false});
  final bool deuces;
  @override
  State<VideoPoker> createState() => _VideoPokerState();
}

class _VideoPokerState extends State<VideoPoker> {
  static const bet = 5;
  List<int> deck = [], hand = [];
  List<bool> held = List.filled(5, false);
  int credits = 200;
  bool drawing = false; // true between Deal and Draw
  String msg = tr('Press Deal', '"তাস দিন" চাপুন');

  Map<String, int> get pay => widget.deuces ? deucesPay : jobPay;
  String? eval(List<int> h) => widget.deuces ? deucesHand(h) : jobHand(h);

  void deal() {
    if (credits < bet) return;
    deck = newDeck();
    setState(() {
      credits -= bet;
      hand = [for (var i = 0; i < 5; i++) deck.removeLast()];
      held = List.filled(5, false);
      drawing = true;
      msg = eval(hand) == null ? tr('Tap cards to hold', 'রাখতে চাইলে তাসে চাপুন') : handName(eval(hand)!);
    });
  }

  void draw() {
    setState(() {
      for (var i = 0; i < 5; i++) {
        if (!held[i]) hand[i] = deck.removeLast();
      }
      drawing = false;
      final h = eval(hand), win = h == null ? 0 : pay[h]! * bet;
      credits += win;
      msg = h == null ? tr('No win', 'জেতেননি') : '${handName(h)} · +$win';
      sfx(win > 0 ? 'right' : 'wrong');
    });
    record(context, credits, unit: ' credits');
    if (credits < bet) showResult(context, won: false, tr('Out of credits!', 'ক্রেডিট শেষ!'), () => setState(() => credits = 200));
  }

  @override
  Widget build(BuildContext context) {
    final current = hand.isEmpty ? null : eval(hand);
    return page(
      widget.deuces ? tr('Deuces Wild', 'ডিউসেস ওয়াইল্ড') : tr('Jacks or Better', 'জ্যাকস অর বেটার'),
      felt(Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            for (final e in pay.entries)
              Row(children: [
                Expanded(child: Text(handName(e.key), style: TextStyle(color: e.key == current ? Colors.amber : Colors.white70, fontWeight: e.key == current ? FontWeight.bold : null))),
                Text('${e.value * bet}', style: TextStyle(color: e.key == current ? Colors.amber : Colors.white70)),
              ]),
          ]),
        ),
        Text(msg, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < hand.length; i++)
            Column(children: [
              playingCard(hand[i], w: 58, onTap: drawing ? () => setState(() => held[i] = !held[i]) : null),
              Text(held[i] ? tr('HELD', 'রাখা') : '', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ]),
        ]),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(onPressed: drawing ? draw : (credits >= bet ? deal : null), child: Text(drawing ? tr('Draw', 'বদলান') : tr('Deal · bet $bet', 'তাস দিন · বাজি $bet'))),
        ),
      ])),
      '🪙 $credits',
    );
  }
}

// ---------- Baccarat ----------

int bacVal(List<int> h) => h.fold(0, (s, c) => s + (rankOf(c) >= 10 ? 0 : rankOf(c))) % 10;

/// Plays one coup with the standard drawing rules, dealing from the end of [deck]. Returns (player, banker).
(List<int>, List<int>) baccaratCoup(List<int> deck) {
  final pl = <int>[], bk = <int>[];
  for (var k = 0; k < 2; k++) {
    pl.add(deck.removeLast());
    bk.add(deck.removeLast());
  }
  final pv = bacVal(pl), bv = bacVal(bk);
  if (pv >= 8 || bv >= 8) return (pl, bk);
  int? t;
  if (pv <= 5) {
    pl.add(deck.removeLast());
    t = bacVal([pl.last]);
  }
  final bankerDraws = t == null
      ? bv <= 5
      : switch (bv) {
          <= 2 => true,
          3 => t != 8,
          4 => t >= 2 && t <= 7,
          5 => t >= 4 && t <= 7,
          6 => t == 6 || t == 7,
          _ => false,
        };
  if (bankerDraws) bk.add(deck.removeLast());
  return (pl, bk);
}

class Baccarat extends StatefulWidget {
  const Baccarat({super.key});
  @override
  State<Baccarat> createState() => _BaccaratState();
}

class _BaccaratState extends State<Baccarat> {
  static const bet = 10;
  List<int> deck = newDeck(), player = [], banker = [];
  int chips = 100;
  String msg = tr('Bet on Player, Banker or Tie', 'প্লেয়ার, ব্যাংকার বা টাই-এ বাজি ধরুন');

  void play(String on) {
    if (deck.length < 10) deck = newDeck();
    final (pl, bk) = baccaratCoup(deck);
    final pv = bacVal(pl), bv = bacVal(bk), result = pv > bv ? 'Player' : (bv > pv ? 'Banker' : 'Tie');
    final delta = on == result
        ? (on == 'Tie' ? bet * 8 : (on == 'Banker' ? bet * 19 ~/ 20 : bet))
        : (result == 'Tie' ? 0 : -bet); // Player/Banker bets push on a tie
    sfx(delta > 0 ? 'right' : (delta < 0 ? 'wrong' : 'tap'));
    setState(() {
      player = pl;
      banker = bk;
      chips += delta;
      msg = tr('$result wins · ${delta >= 0 ? '+' : ''}$delta', '${bac(result)} জিতেছে · ${delta >= 0 ? '+' : ''}$delta');
    });
    record(context, chips, unit: ' chips');
    if (chips < bet) showResult(context, won: false, tr('Out of chips!', 'চিপস শেষ!'), () => setState(() => chips = 100));
  }

  static String bac(String side) => tr(side, const {'Player': 'প্লেয়ার', 'Banker': 'ব্যাংকার', 'Tie': 'টাই'}[side]!);

  Widget hand(String who, List<int> h) => Column(children: [
        Text(h.isEmpty ? bac(who) : '${bac(who)} · ${bacVal(h)}', style: const TextStyle(fontSize: 18, color: Colors.white70)),
        Wrap(children: [for (final c in h) playingCard(c, w: 52)]),
      ]);

  @override
  Widget build(BuildContext context) => page(
        'Baccarat',
        felt(Column(children: [
          const SizedBox(height: 12),
          hand('Banker', banker),
          Expanded(child: Center(child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
          hand('Player', player),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
              for (final on in ['Player', 'Banker', 'Tie']) FilledButton(onPressed: chips >= bet ? () => play(on) : null, child: Text(bac(on))),
            ]),
          ),
          Text(tr('Bet 10 · Player 1:1 · Banker 0.95:1 · Tie 8:1', 'বাজি 10 · প্লেয়ার 1:1 · ব্যাংকার 0.95:1 · টাই 8:1'), style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
        ])),
        '🪙 $chips',
      );
}

// ---------- Red Dog ----------

int highRank(int c) => rankOf(c) == 1 ? 14 : rankOf(c);

/// Payout multiple for a Red Dog spread (cards strictly between the two).
int redDogPay(int spread) => switch (spread) { 1 => 5, 2 => 4, 3 => 2, _ => 1 };

class RedDog extends StatefulWidget {
  const RedDog({super.key});
  @override
  State<RedDog> createState() => _RedDogState();
}

class _RedDogState extends State<RedDog> {
  List<int> deck = newDeck(), cards = [];
  int chips = 100, bet = 10;
  bool deciding = false;
  String msg = tr('Will the third card fall between the first two?', 'তৃতীয় তাস কি প্রথম দুটির মাঝে পড়বে?');

  void settle(int delta, String m) {
    sfx(delta > 0 ? 'right' : (delta < 0 ? 'wrong' : 'tap'));
    setState(() {
      chips += delta;
      msg = m;
      deciding = false;
    });
    record(context, chips, unit: ' chips');
    if (chips < 10) showResult(context, won: false, tr('Out of chips!', 'চিপস শেষ!'), () => setState(() => chips = 100));
  }

  void deal() {
    if (deck.length < 6) deck = newDeck();
    bet = 10;
    setState(() => cards = [deck.removeLast(), deck.removeLast()]..sort((a, b) => highRank(a) - highRank(b)));
    final gap = highRank(cards[1]) - highRank(cards[0]);
    if (gap == 1) return settle(0, tr('Consecutive — push', 'পরপর — ড্র'));
    if (gap == 0) {
      setState(() => cards.add(deck.removeLast()));
      return highRank(cards[2]) == highRank(cards[0]) ? settle(bet * 11, tr('Three of a kind! +${bet * 11}', 'তিনটি একই! +${bet * 11}')) : settle(0, tr('Pair — push', 'জোড়া — ড্র'));
    }
    setState(() {
      deciding = true;
      msg = tr('Spread ${gap - 1} pays ${redDogPay(gap - 1)}:1', 'ফাঁক ${gap - 1} · পাবেন ${redDogPay(gap - 1)}:1');
    });
  }

  void third(bool raise) {
    if (raise && chips >= 2 * bet) bet *= 2;
    setState(() => cards.add(deck.removeLast()));
    final lo = highRank(cards[0]), hi = highRank(cards[1]), t = highRank(cards[2]), pay = redDogPay(hi - lo - 1);
    t > lo && t < hi ? settle(bet * pay, tr('Inside! +${bet * pay}', 'ভেতরে! +${bet * pay}')) : settle(-bet, tr('Outside · −$bet', 'বাইরে · −$bet'));
  }

  @override
  Widget build(BuildContext context) => page(
        'Red Dog',
        felt(Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final c in cards) playingCard(c, w: 80)]),
          const SizedBox(height: 32),
          if (deciding)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FilledButton.tonal(onPressed: () => third(false), child: Text(tr('Call', 'কল'))),
              const SizedBox(width: 16),
              FilledButton(onPressed: chips >= 2 * bet ? () => third(true) : null, child: Text(tr('Raise ×2', 'রেইজ ×2'))),
            ])
          else
            FilledButton(onPressed: chips >= 10 ? deal : null, child: Text(tr('Deal · bet 10', 'তাস দিন · বাজি 10'))),
          const SizedBox(height: 16),
          Text(tr('Aces high · spread 1 pays 5:1, 2 pays 4:1, 3 pays 2:1, 4+ pays 1:1', 'A সবচেয়ে বড় · ফাঁক 1 পায় 5:1, 2 পায় 4:1, 3 পায় 2:1, 4+ পায় 1:1'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
        ])),
        '🪙 $chips',
      );
}

// ---------- War ----------

class War extends StatefulWidget {
  const War({super.key});
  @override
  State<War> createState() => _WarState();
}

class _WarState extends State<War> {
  static const maxRounds = 400;
  late List<int> you, ai;
  int? a, b;
  int rounds = 0;
  String msg = tr('Tap Flip', '"উল্টান" চাপুন');

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    final d = newDeck();
    you = d.sublist(0, 26);
    ai = d.sublist(26);
    a = b = null;
    rounds = 0;
    msg = tr('Tap Flip', '"উল্টান" চাপুন');
  }

  void battle() {
    final pot = <int>[];
    var wars = 0;
    while (you.isNotEmpty && ai.isNotEmpty) {
      a = you.removeAt(0);
      b = ai.removeAt(0);
      pot.addAll([a!, b!]);
      if (highRank(a!) != highRank(b!)) {
        (highRank(a!) > highRank(b!) ? you : ai).addAll(pot..shuffle(_r));
        final mine = highRank(a!) > highRank(b!);
        msg = tr('${wars > 0 ? 'War ×$wars! ' : ''}${mine ? 'You take' : 'AI takes'} ${pot.length}', '${wars > 0 ? 'যুদ্ধ ×$wars! ' : ''}${mine ? 'আপনি পেলেন' : 'AI পেল'} ${pot.length}');
        return;
      }
      wars++;
      for (var k = 0; k < 3; k++) {
        if (you.length > 1) pot.add(you.removeAt(0));
        if (ai.length > 1) pot.add(ai.removeAt(0));
      }
    }
    (you.isEmpty ? ai : you).addAll(pot); // someone ran out mid-war
  }

  void flip(int times) {
    setState(() {
      for (var k = 0; k < times && you.isNotEmpty && ai.isNotEmpty && rounds < maxRounds; k++) {
        battle();
        rounds++;
      }
    });
    sfx('tap');
    if (you.isEmpty || ai.isEmpty || rounds >= maxRounds) {
      final won = you.length > ai.length;
      showResult(context, won: won, tr('${won ? 'You win' : (you.length == ai.length ? 'Draw' : 'AI wins')} · $rounds rounds\n${you.length} vs ${ai.length} cards', '${won ? 'আপনি জিতেছেন' : (you.length == ai.length ? 'ড্র' : 'AI জিতেছে')} · $rounds রাউন্ড\n${you.length} বনাম ${ai.length} তাস'), () => setState(start));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        tr('War', 'যুদ্ধ'),
        felt(Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(tr('AI · ${ai.length} cards', 'AI · ${ai.length}টি তাস'), style: const TextStyle(fontSize: 18)),
          playingCard(b, w: 80),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          playingCard(a, w: 80),
          Text(tr('You · ${you.length} cards', 'আপনি · ${you.length}টি তাস'), style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton(onPressed: () => flip(1), child: Text(tr('Flip', 'উল্টান'))),
            const SizedBox(width: 12),
            FilledButton.tonal(onPressed: () => flip(10), child: Text(tr('Flip ×10', 'উল্টান ×10'))),
          ]),
          const SizedBox(height: 8),
          Text(tr('Round $rounds / $maxRounds', 'রাউন্ড $rounds / $maxRounds'), style: const TextStyle(color: Colors.white54)),
        ])),
        tr('Aces high', 'A সবচেয়ে বড়'),
      );
}

// ---------- Go Fish ----------

/// Removes every complete set of four from [hand]; returns how many books were made.
int takeBooks(List<int> hand) {
  var n = 0;
  for (final e in rankCounts(hand).entries) {
    if (e.value == 4) {
      hand.removeWhere((c) => rankOf(c) == e.key);
      n++;
    }
  }
  return n;
}

const rankNames = ['Aces', '2s', '3s', '4s', '5s', '6s', '7s', '8s', '9s', '10s', 'Jacks', 'Queens', 'Kings'];
const rankNamesBn = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

class GoFish extends StatefulWidget {
  const GoFish({super.key});
  @override
  State<GoFish> createState() => _GoFishState();
}

class _GoFishState extends State<GoFish> {
  late List<int> deck, you, ai;
  int yourBooks = 0, aiBooks = 0;
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
    yourBooks = takeBooks(you);
    aiBooks = takeBooks(ai);
    yourTurn = true;
    over = false;
    msg = tr('Tap a card to ask the AI for that rank', 'তাসে চাপুন, AI-র কাছে সেই র‍্যাঙ্কটি চাইতে');
  }

  void refill(List<int> h) {
    if (h.isEmpty && deck.isNotEmpty) h.add(deck.removeLast());
  }

  bool checkEnd() {
    // books are removed at once, so with an empty deck and an empty hand no more books can form
    if (yourBooks + aiBooks < 13 && !(deck.isEmpty && (you.isEmpty || ai.isEmpty))) return false;
    over = true;
    showResult(context, won: yourBooks > aiBooks, tr('Books: you $yourBooks · AI $aiBooks', 'বুক: আপনি $yourBooks · AI $aiBooks'), () => setState(start));
    return true;
  }

  /// [asker] asks [other] for [rank]. Returns true if the asker goes again.
  bool ask(List<int> asker, List<int> other, int rank, bool isYou) {
    final got = other.where((c) => rankOf(c) == rank).toList();
    var again = got.isNotEmpty;
    final who = isYou ? tr('You', 'আপনি') : 'AI', r = tr(rankNames[rank - 1], rankNamesBn[rank - 1]);
    if (again) {
      other.removeWhere((c) => rankOf(c) == rank);
      asker.addAll(got);
      msg = tr('$who got ${got.length} $r', '$who ${got.length}টি $r পেল');
    } else if (deck.isNotEmpty) {
      final c = deck.removeLast();
      asker.add(c);
      again = rankOf(c) == rank;
      msg = tr('$who asked for $r · Go fish!${again ? ' Lucky catch!' : ''}', '$who $r চাইল · গো ফিশ!${again ? ' ভাগ্যক্রমে মিলে গেল!' : ''}');
    } else {
      msg = tr('$who asked for $r · Go fish! (deck empty)', '$who $r চাইল · গো ফিশ! (ডেক খালি)');
    }
    final books = takeBooks(asker);
    if (isYou) {
      yourBooks += books;
    } else {
      aiBooks += books;
    }
    refill(you);
    refill(ai);
    return again;
  }

  Future<void> youAsk(int rank) async {
    if (!yourTurn || over) return;
    sfx('tap');
    late bool again;
    setState(() => again = ask(you, ai, rank, true));
    if (checkEnd()) return;
    if (again && you.isNotEmpty) return;
    setState(() => yourTurn = false);
    while (mounted && !over && ai.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => again = ask(ai, you, rankOf(ai[_r.nextInt(ai.length)]), false));
      if (checkEnd() || !again) break;
    }
    if (mounted && !over) setState(() => yourTurn = true);
  }

  @override
  Widget build(BuildContext context) => page(
        'Go Fish',
        felt(Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Text(tr('AI · ${ai.length} cards · $aiBooks books', 'AI · ${ai.length}টি তাস · $aiBooks বুক'), style: const TextStyle(color: Colors.white70)),
            SizedBox(height: 64, child: Stack(children: [for (var i = 0; i < ai.length; i++) Positioned(left: i * 12.0, child: playingCard(null, w: 40))])),
            Expanded(
              child: Center(
                child: Text(tr('$msg\n\nDeck: ${deck.length}', '$msg\n\nডেক: ${deck.length}'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              ),
            ),
            Text(tr('You · $yourBooks books', 'আপনি · $yourBooks বুক'), style: const TextStyle(color: Colors.white70)),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(alignment: WrapAlignment.center, children: [
                  for (final c in you..sort((a, b) => rankOf(a) - rankOf(b))) playingCard(c, w: 46, dim: !yourTurn, onTap: () => youAsk(rankOf(c))),
                ]),
              ),
            ),
          ]),
        )),
        yourTurn ? tr('Your turn', 'আপনার পালা') : tr('AI turn', 'AI-র পালা'),
      );
}

// ---------- Old Maid ----------

/// Discards pairs of the same rank from [hand].
void discardPairs(List<int> hand) {
  for (final e in rankCounts(hand).entries) {
    var n = e.value - e.value % 2;
    hand.removeWhere((c) => rankOf(c) == e.key && n-- > 0);
  }
}

class OldMaid extends StatefulWidget {
  const OldMaid({super.key});
  @override
  State<OldMaid> createState() => _OldMaidState();
}

class _OldMaidState extends State<OldMaid> {
  static const maid = 3 * 13 + 11; // Q♣ is removed, leaving one unpaired queen
  late List<int> you, ai;
  bool yourTurn = true, over = false;
  String msg = '';

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    final d = newDeck()..remove(maid);
    you = [for (var i = 0; i < d.length; i += 2) d[i]];
    ai = [for (var i = 1; i < d.length; i += 2) d[i]];
    discardPairs(you);
    discardPairs(ai);
    ai.shuffle(_r);
    yourTurn = true;
    over = false;
    msg = tr('Take a card from the AI', 'AI-র কাছ থেকে একটি তাস নিন');
  }

  bool checkEnd() {
    if (you.isNotEmpty && ai.isNotEmpty) return false;
    over = true;
    showResult(context, won: you.isEmpty, you.isEmpty ? tr('The AI is stuck with the Old Maid!', 'ওল্ড মেইড রয়ে গেল AI-র হাতে!') : tr('You are left with the Old Maid 👵', 'ওল্ড মেইড রয়ে গেল আপনার হাতে 👵'), () => setState(start));
    return true;
  }

  Future<void> take(int i) async {
    if (!yourTurn || over) return;
    sfx('tap');
    setState(() {
      final c = ai.removeAt(i);
      you.add(c);
      discardPairs(you);
      msg = tr('You drew ${cardLabel(c)}', 'আপনি পেলেন ${cardLabel(c)}');
      yourTurn = false;
    });
    if (checkEnd()) return;
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      final c = you.removeAt(_r.nextInt(you.length));
      ai
        ..add(c)
        ..shuffle(_r);
      discardPairs(ai);
      msg = tr('AI took your ${cardLabel(c)}', 'AI আপনার ${cardLabel(c)} নিল');
      yourTurn = true;
    });
    checkEnd();
  }

  @override
  Widget build(BuildContext context) => page(
        'Old Maid',
        felt(Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Text(tr('AI · ${ai.length} cards — tap one to take it', 'AI · ${ai.length}টি তাস — একটিতে চাপ দিয়ে নিন'), style: const TextStyle(color: Colors.white70)),
            Wrap(alignment: WrapAlignment.center, children: [for (var i = 0; i < ai.length; i++) playingCard(null, w: 40, onTap: () => take(i))]),
            Expanded(child: Center(child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)))),
            Text(tr('Your hand', 'আপনার হাত'), style: const TextStyle(color: Colors.white70)),
            Wrap(alignment: WrapAlignment.center, children: [for (final c in you..sort((a, b) => rankOf(a) - rankOf(b))) playingCard(c, w: 44)]),
          ]),
        )),
        yourTurn ? tr('Your turn', 'আপনার পালা') : tr('AI turn', 'AI-র পালা'),
      );
}

// ---------- Yahtzee ----------

const yahtzeeCats = ['Ones', 'Twos', 'Threes', 'Fours', 'Fives', 'Sixes', '3 of a Kind', '4 of a Kind', 'Full House', 'Small Straight', 'Large Straight', 'Yahtzee', 'Chance'];

int yahtzeeScore(int cat, List<int> d) {
  final counts = List.filled(7, 0);
  for (final v in d) {
    counts[v]++;
  }
  final sum = d.fold(0, (a, b) => a + b);
  bool has(int n) => counts.any((c) => c >= n);
  bool run(int len) => [for (var s = 1; s + len - 1 <= 6; s++) List.generate(len, (k) => counts[s + k] > 0).every((x) => x)].contains(true);
  return switch (cat) {
    < 6 => counts[cat + 1] * (cat + 1),
    6 => has(3) ? sum : 0,
    7 => has(4) ? sum : 0,
    8 => counts.contains(3) && counts.contains(2) ? 25 : 0,
    9 => run(4) ? 30 : 0,
    10 => run(5) ? 40 : 0,
    11 => has(5) ? 50 : 0,
    _ => sum,
  };
}

/// Total with the 35-point upper bonus for 63+ in Ones–Sixes.
int yahtzeeTotal(List<int?> s) {
  final upper = s.take(6).fold(0, (a, b) => a + (b ?? 0));
  return s.fold(0, (a, b) => a + (b ?? 0)) + (upper >= 63 ? 35 : 0);
}

class Yahtzee extends StatefulWidget {
  const Yahtzee({super.key});
  @override
  State<Yahtzee> createState() => _YahtzeeState();
}

class _YahtzeeState extends State<Yahtzee> {
  List<int> d = List.filled(5, 0);
  List<bool> held = List.filled(5, false);
  List<int?> score = List.filled(13, null);
  int rolls = 3;
  bool rolling = false;

  void reset() {
    d = List.filled(5, 0);
    held = List.filled(5, false);
    score = List.filled(13, null);
    rolls = 3;
  }

  Future<void> roll() async {
    if (rolls == 0 || rolling) return;
    rolling = true;
    for (var k = 0; k < 6; k++) {
      setState(() {
        for (var i = 0; i < 5; i++) {
          if (!held[i] || d[i] == 0) d[i] = _r.nextInt(6) + 1;
        }
      });
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
    }
    setState(() {
      rolls--;
      rolling = false;
    });
  }

  void pick(int cat) {
    if (score[cat] != null || rolls == 3 || rolling) return;
    sfx('tap');
    setState(() {
      score[cat] = yahtzeeScore(cat, d);
      d = List.filled(5, 0);
      held = List.filled(5, false);
      rolls = 3;
    });
    if (!score.contains(null)) {
      final t = yahtzeeTotal(score);
      showResult(context, score: t, tr('Final score: $t', 'চূড়ান্ত স্কোর: $t'), () => setState(reset));
    }
  }

  @override
  Widget build(BuildContext context) {
    final upper = score.take(6).fold(0, (a, b) => a + (b ?? 0));
    return page(
      'Yahtzee',
      Column(children: [
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 5; i++)
            GestureDetector(
              onTap: rolls < 3 && !rolling ? () => setState(() => held[i] = !held[i]) : null,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(border: Border.all(color: held[i] ? Colors.amber : Colors.transparent, width: 3), borderRadius: BorderRadius.circular(10)),
                child: dice(d[i] == 0 ? null : d[i], size: 50),
              ),
            ),
        ]),
        FilledButton.icon(onPressed: rolls > 0 && !rolling ? roll : null, icon: const Icon(Icons.casino), label: Text(tr('Roll ($rolls left)', 'চালুন ($rolls বাকি)'))),
        Expanded(
          child: ListView(children: [
            for (var c = 0; c < 13; c++)
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(handName(yahtzeeCats[c])),
                onTap: () => pick(c),
                trailing: Text(
                  score[c] != null ? '${score[c]}' : (rolls < 3 ? '${yahtzeeScore(c, d)}' : ''),
                  style: TextStyle(fontSize: 16, fontWeight: score[c] != null ? FontWeight.bold : null, color: score[c] != null ? null : Colors.amber),
                ),
              ),
            ListTile(dense: true, title: Text(tr('Upper bonus (63+) · $upper/63', 'উপরের বোনাস (63+) · $upper/63')), trailing: Text(upper >= 63 ? '35' : '0')),
            ListTile(title: Text(tr('Total', 'মোট'), style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text('${yahtzeeTotal(score)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ]),
        ),
      ]),
      tr('Round ${min(13, score.where((s) => s != null).length + 1)}/13', 'রাউন্ড ${min(13, score.where((s) => s != null).length + 1)}/13'),
    );
  }
}

// ---------- Farkle ----------

/// Score of a set-aside selection, or 0 if any die in it doesn't score.
int farkleScore(List<int> d) {
  if (d.isEmpty) return 0;
  final c = List.filled(7, 0);
  for (final v in d) {
    c[v]++;
  }
  if (d.length == 6 && c.skip(1).every((n) => n == 1)) return 1500; // 1-2-3-4-5-6
  if (d.length == 6 && c.skip(1).where((n) => n == 2).length == 3) return 1500; // three pairs
  var s = 0;
  for (var f = 1; f <= 6; f++) {
    final n = c[f];
    if (n >= 3) {
      s += (f == 1 ? 1000 : f * 100) << (n - 3); // each extra die doubles
    } else if (f == 1) {
      s += 100 * n;
    } else if (f == 5) {
      s += 50 * n;
    } else if (n > 0) {
      return 0;
    }
  }
  return s;
}

/// Indices of the highest-scoring selection from a roll (empty = Farkle).
List<int> farkleBest(List<int> roll) {
  var best = <int>[], bestScore = 0;
  for (var m = 1; m < 1 << roll.length; m++) {
    final idx = [for (var i = 0; i < roll.length; i++) if (m & (1 << i) != 0) i];
    final s = farkleScore([for (final i in idx) roll[i]]);
    if (s > bestScore || (s == bestScore && s > 0 && idx.length < best.length)) {
      best = idx;
      bestScore = s;
    }
  }
  return best;
}

class Farkle extends StatefulWidget {
  const Farkle({super.key});
  @override
  State<Farkle> createState() => _FarkleState();
}

class _FarkleState extends State<Farkle> {
  static const target = 5000;
  final scores = [0, 0];
  int turn = 0, turnPts = 0;
  List<int> roll = [];
  Set<int> chosen = {};
  bool busy = false, over = false;
  String msg = tr('Roll six dice. Set aside scoring dice, then roll again or bank.', 'ছয়টি ছক্কা চালুন। স্কোর হওয়া ছক্কা আলাদা রাখুন, তারপর আবার চালুন বা জমা করুন।');

  int get selScore => farkleScore([for (final i in chosen) roll[i]]);

  void throwDice(int n) {
    setState(() {
      roll = List.generate(n, (_) => _r.nextInt(6) + 1);
      chosen = {};
    });
    sfx('tap');
  }

  void newGame() {
    scores.fillRange(0, 2, 0);
    turn = turnPts = 0;
    roll = [];
    chosen = {};
    over = busy = false;
  }

  Future<void> endTurn({bool bank = false}) async {
    if (bank) scores[turn] += turnPts;
    if (scores[turn] >= target) {
      over = true;
      setState(() {});
      showResult(context, won: turn == 0, tr('${turn == 0 ? 'You win' : 'AI wins'} · ${scores[0]} to ${scores[1]}', '${turn == 0 ? 'আপনি জিতেছেন' : 'AI জিতেছে'} · ${scores[0]} বনাম ${scores[1]}'), () => setState(newGame));
      return;
    }
    setState(() {
      turn = 1 - turn;
      turnPts = 0;
      roll = [];
      chosen = {};
    });
    if (turn == 1) await aiTurn();
  }

  Future<void> youRoll() async {
    final left = roll.isEmpty ? 6 : (roll.length - chosen.length == 0 ? 6 : roll.length - chosen.length);
    if (roll.isNotEmpty) turnPts += selScore;
    throwDice(left);
    if (farkleBest(roll).isEmpty) {
      setState(() {
        msg = tr('Farkle! You lose $turnPts points', 'ফার্কল! আপনি $turnPts পয়েন্ট হারালেন');
        busy = true;
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      busy = false;
      await endTurn();
    } else {
      setState(() => msg = tr('Tap dice to set aside', 'আলাদা রাখতে ছক্কায় চাপুন'));
    }
  }

  Future<void> aiTurn() async {
    setState(() => busy = true);
    var left = 6;
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      throwDice(left);
      final best = farkleBest(roll);
      if (best.isEmpty) {
        setState(() => msg = tr('AI farkled and loses $turnPts', 'AI ফার্কল করে $turnPts হারাল'));
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        setState(() => busy = false);
        return endTurn();
      }
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        chosen = best.toSet();
        turnPts += selScore;
        msg = tr('AI sets aside ${best.length} · turn $turnPts', 'AI ${best.length}টি আলাদা রাখল · এই দানে $turnPts');
      });
      left -= best.length;
      if (left == 0) left = 6; // hot dice
      // ponytail: simple banking rule; tune thresholds if the AI feels too timid or reckless
      if (scores[1] + turnPts >= target || turnPts >= 1000 || (turnPts >= 350 && left <= 2)) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        setState(() {
          msg = tr('AI banks $turnPts', 'AI $turnPts জমা করল');
          busy = false;
        });
        return endTurn(bank: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = turn == 0 && !busy && !over, valid = selScore > 0;
    return page(
      'Farkle',
      felt(Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(tr('You ${scores[0]}   ·   AI ${scores[1]}   (to $target)', 'আপনি ${scores[0]}   ·   AI ${scores[1]}   (লক্ষ্য $target)'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, children: [
          for (var i = 0; i < roll.length; i++)
            GestureDetector(
              onTap: mine ? () => setState(() => chosen.contains(i) ? chosen.remove(i) : chosen.add(i)) : null,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(border: Border.all(color: chosen.contains(i) ? Colors.amber : Colors.transparent, width: 3), borderRadius: BorderRadius.circular(10)),
                child: dice(roll[i], size: 46),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Text('${tr('Turn', 'এই দান')}: $turnPts${chosen.isNotEmpty ? ' + ${valid ? selScore : '✕'}' : ''}', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        Wrap(spacing: 12, alignment: WrapAlignment.center, children: [
          FilledButton(onPressed: mine && (roll.isEmpty || valid) ? youRoll : null, child: Text(roll.isEmpty ? tr('Roll', 'চালুন') : tr('Roll again', 'আবার চালুন'))),
          FilledButton.tonal(
            onPressed: mine && valid
                ? () {
                    turnPts += selScore;
                    endTurn(bank: true);
                  }
                : null,
            child: Text(tr('Bank', 'জমা')),
          ),
        ]),
        const SizedBox(height: 16),
        Text(tr('1 = 100 · 5 = 50 · three of a kind = face × 100 (1s = 1000), each extra die doubles · straight or three pairs = 1500', '1 = 100 · 5 = 50 · তিনটি একই = মান × 100 (1 হলে 1000), প্রতিটি বাড়তি ছক্কায় দ্বিগুণ · স্ট্রেইট বা তিন জোড়া = 1500'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ])),
      turn == 0 ? tr('Your turn', 'আপনার পালা') : tr('AI turn', 'AI-র পালা'),
    );
  }
}

// ---------- Shut the Box ----------

/// Whether some subset of the open tiles adds up to [n].
bool canMake(List<int> open, int n) => [for (var m = 1; m < 1 << open.length; m++) [for (var i = 0; i < open.length; i++) if (m & (1 << i) != 0) open[i]].fold(0, (a, b) => a + b) == n].contains(true);

class ShutTheBox extends StatefulWidget {
  const ShutTheBox({super.key});
  @override
  State<ShutTheBox> createState() => _ShutTheBoxState();
}

class _ShutTheBoxState extends State<ShutTheBox> {
  List<int> open = List.generate(9, (i) => i + 1);
  Set<int> picked = {};
  List<int> dv = [];

  int get need => dv.fold(0, (a, b) => a + b);

  void roll() {
    final one = !open.any((t) => t >= 7); // 7, 8 and 9 shut: roll a single die
    setState(() {
      dv = [for (var k = 0; k < (one ? 1 : 2); k++) _r.nextInt(6) + 1];
      picked = {};
    });
    sfx('tap');
    if (!canMake(open, need)) {
      final left = open.fold(0, (a, b) => a + b);
      showResult(context, won: false, score: left, lower: true, unit: ' pts', tr('No tiles make $need\nScore: $left (lower is better)', 'কোনো টাইলে $need হয় না\nস্কোর: $left (কম হলে ভালো)'), () => setState(() {
            open = List.generate(9, (i) => i + 1);
            dv = [];
          }));
    }
  }

  void tapTile(int t) {
    if (dv.isEmpty || !open.contains(t)) return;
    setState(() => picked.contains(t) ? picked.remove(t) : picked.add(t));
    final s = picked.fold(0, (a, b) => a + b);
    if (s > need) {
      sfx('wrong');
      setState(() => picked = {});
    } else if (s == need) {
      sfx('right');
      setState(() {
        open.removeWhere(picked.contains);
        picked = {};
        dv = [];
      });
      if (open.isEmpty) {
        showResult(context, score: 0, lower: true, unit: ' pts', tr('You shut the box! 📦', 'বাক্স বন্ধ করেছেন! 📦'), () => setState(() => open = List.generate(9, (i) => i + 1)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => page(
        'Shut the Box',
        felt(Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(tr('Shut tiles that add up to your roll', 'চালের সমান যোগফলের টাইলগুলো বন্ধ করুন'), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
            for (var t = 1; t <= 9; t++)
              GestureDetector(
                onTap: () => tapTile(t),
                child: Container(
                  width: 34,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !open.contains(t) ? Colors.brown.shade900 : (picked.contains(t) ? Colors.amber : Colors.brown.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(open.contains(t) ? '$t' : '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final v in dv) Padding(padding: const EdgeInsets.all(6), child: dice(v))]),
          if (dv.isNotEmpty) Text(tr('Make $need', '$need বানান'), style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: dv.isEmpty ? roll : null, icon: const Icon(Icons.casino), label: Text(tr('Roll', 'চালুন'))),
        ])),
        tr('Open: ${open.fold(0, (a, b) => a + b)}', 'খোলা: ${open.fold(0, (a, b) => a + b)}'),
      );
}

// ---------- Dice Poker ----------

const dicePokerNames = ['Nothing', 'Pair', 'Two Pair', 'Three of a Kind', 'Straight', 'Full House', 'Four of a Kind', 'Five of a Kind'];

/// [category, tie-break values…]; compare lexicographically.
List<int> dicePokerRank(List<int> d) {
  final c = List.filled(7, 0);
  for (final v in d) {
    c[v]++;
  }
  final groups = [for (var f = 6; f >= 1; f--) if (c[f] > 0) (c[f], f)]..sort((a, b) => a.$1 != b.$1 ? b.$1 - a.$1 : b.$2 - a.$2);
  final n = groups.map((g) => g.$1).toList();
  final straight = n.length == 5 && (c[1] == 0 || c[6] == 0);
  final cat = n[0] == 5
      ? 7
      : n[0] == 4
          ? 6
          : n[0] == 3 && n[1] == 2
              ? 5
              : straight
                  ? 4
                  : n[0] == 3
                      ? 3
                      : n[0] == 2 && n[1] == 2
                          ? 2
                          : n[0] == 2
                              ? 1
                              : 0;
  return [cat, ...groups.map((g) => g.$2)];
}

int compareRanks(List<int> a, List<int> b) {
  for (var i = 0; i < min(a.length, b.length); i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return 0;
}

class DicePoker extends StatefulWidget {
  const DicePoker({super.key});
  @override
  State<DicePoker> createState() => _DicePokerState();
}

class _DicePokerState extends State<DicePoker> {
  List<int> you = [], ai = [];
  Set<int> held = {};
  int phase = 0; // 0 roll, 1 hold & reroll, 2 round result
  final wins = [0, 0];
  String msg = tr('First to 3 rounds', 'যে আগে 3 রাউন্ড জিতবে');

  List<int> five() => List.generate(5, (_) => _r.nextInt(6) + 1);

  void rollBoth() {
    sfx('tap');
    setState(() {
      you = five();
      ai = five();
      held = {};
      phase = 1;
      msg = tr('Tap dice to keep, then reroll the rest', 'রাখার ছক্কায় চাপুন, বাকিগুলো আবার চালুন');
    });
  }

  void reroll() {
    // AI keeps any value it has two or more of, or everything once it has a straight or better.
    final r = dicePokerRank(ai), keep = r[0] >= 4 ? {1, 2, 3, 4, 5, 6} : {for (final v in ai) if (ai.where((x) => x == v).length >= 2) v};
    setState(() {
      you = [for (var i = 0; i < 5; i++) held.contains(i) ? you[i] : _r.nextInt(6) + 1];
      ai = [for (final v in ai) keep.contains(v) ? v : _r.nextInt(6) + 1];
      final cmp = compareRanks(dicePokerRank(you), dicePokerRank(ai));
      if (cmp != 0) wins[cmp > 0 ? 0 : 1]++;
      msg = '${handName(dicePokerNames[dicePokerRank(you)[0]])} ${tr('vs', 'বনাম')} ${handName(dicePokerNames[dicePokerRank(ai)[0]])} · ${cmp > 0 ? tr('you win the round', 'রাউন্ড আপনার') : (cmp < 0 ? tr('AI wins the round', 'রাউন্ড AI-র') : tr('tie', 'টাই'))}';
      phase = 2;
    });
    sfx('tap');
    if (wins.contains(3)) {
      showResult(context, won: wins[0] == 3, tr('${wins[0] == 3 ? 'You win' : 'AI wins'} ${wins[0]}–${wins[1]}', '${wins[0] == 3 ? 'আপনি জিতেছেন' : 'AI জিতেছে'} ${wins[0]}–${wins[1]}'), () => setState(() {
            wins.fillRange(0, 2, 0);
            phase = 0;
            you = [];
            ai = [];
          }));
    }
  }

  Widget row(List<int> d, {bool mine = false}) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < d.length; i++)
          GestureDetector(
            onTap: mine && phase == 1 ? () => setState(() => held.contains(i) ? held.remove(i) : held.add(i)) : null,
            child: Container(
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(border: Border.all(color: mine && held.contains(i) ? Colors.amber : Colors.transparent, width: 3), borderRadius: BorderRadius.circular(10)),
              child: dice(d[i], size: 50),
            ),
          ),
      ]);

  @override
  Widget build(BuildContext context) => page(
        'Dice Poker',
        felt(Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('AI${ai.isEmpty ? '' : ' · ${handName(dicePokerNames[dicePokerRank(ai)[0]])}'}', style: const TextStyle(fontSize: 18)),
          row(ai),
          const SizedBox(height: 24),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          row(you, mine: true),
          Text('${tr('You', 'আপনি')}${you.isEmpty ? '' : ' · ${handName(dicePokerNames[dicePokerRank(you)[0]])}'}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          FilledButton(onPressed: phase == 1 ? reroll : rollBoth, child: Text(phase == 1 ? tr('Reroll', 'আবার চালুন') : (phase == 2 ? tr('Next round', 'পরের রাউন্ড') : tr('Roll', 'চালুন')))),
        ])),
        tr('You ${wins[0]} · AI ${wins[1]}', 'আপনি ${wins[0]} · AI ${wins[1]}'),
      );
}
