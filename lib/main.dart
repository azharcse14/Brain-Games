import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'complex.dart';
import 'duel_action.dart';
import 'duel_board.dart';
import 'duel_classic.dart';
import 'puzzles2.dart';
import 'games.dart';
import 'quiz.dart';
import 'quiz2.dart';
import 'solitaire.dart';
import 'tabletop.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every game is laid out for a phone held upright; rotation would also reset real-time games mid-rally.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  prefs = await SharedPreferences.getInstance();
  runApp(const App());
}

final allGames = [...quizGames, ...otherGames, ...complexGames, ...tabletopGames, ...duelActionGames, ...duelBoardGames, ...duelClassicGames, ...quizGames2, ...puzzleGames2, ...solitaireGames];

const cats = {
  'Math': (Icons.calculate, Colors.blue),
  'Logic': (Icons.psychology, Colors.purple),
  'Word': (Icons.abc, Colors.teal),
  'Knowledge': (Icons.public, Colors.lime),
  'Memory': (Icons.memory, Colors.orange),
  'Focus': (Icons.center_focus_strong, Colors.red),
  'Puzzle': (Icons.extension, Colors.green),
  'Board': (Icons.casino, Colors.brown),
  'Cards': (Icons.style, Colors.pink),
  '2P Action': (Icons.sports_esports, Colors.cyan),
  '2P Board': (Icons.people, Colors.indigo),
};

/// Card glyph per game. Variants ("Lights Out 4×4", "Sudoku Easy") fall back to their first two words, then the first word.
const glyphs = {
  // Math
  'Addition': '+', 'Subtraction': '−', 'Multiplication': '×', 'Division': '÷', 'Mixed Operations': '±',
  'Squares': 'x²', 'Cubes': 'x³', 'Square Roots': '√', 'Powers of Two': '2ⁿ', 'Percentages': '%',
  'Doubling': '×2', 'Halving': '½', 'Remainders': 'mod', 'Missing Addend': '?+', 'Missing Factor': '?×',
  'Digit Sum': 'Σ', 'Times Eleven': '×11', 'Times Five': '×5', 'Order of Operations': '( )', 'Triple Sum': '+++',
  'Rounding': '≈', 'Greatest Common Divisor': 'GCD', 'Least Common Multiple': 'LCM', 'Factorials': 'n!',
  'Negative Numbers': '−5', 'Averages': 'x̄', 'Clock Hours': '🕒', 'Making Change': '💵', 'Speed × Time': '🚗',
  'Bigger Product': '>', 'True or False': '✓✗', 'Even or Odd': '2|3', 'Prime or Not': '7?', 'Divisible by 3': '÷3',
  'Binary to Decimal': '101', 'Decimal to Binary': '0b', 'Hex to Decimal': '0x', 'Roman to Number': 'XIV',
  'Number to Roman': 'Ⅻ', 'Compare Fractions': '¾', 'Unit Conversion': '📏', 'Weekday Jump': '📅',
  'Month Jump': '🗓️', 'Celsius to Fahrenheit': '🌡️', 'Coin Counting': '🪙', 'Leap Year': '🐸',
  'Dice Opposites': '🎲', 'Make 100': '💯', 'Perimeter': '▭', 'Area': '▦', 'Triangle Angles': '📐',
  // Logic
  'Arithmetic Sequence': '1 3 5', 'Geometric Sequence': '2 4 8', 'Fibonacci-like': '🐚', 'Square Sequence': '1 4 9',
  'Alternating Sequence': '↕', 'Prime Sequence': '2 3 5', 'Letter Sequence': 'A C E', 'Not a Multiple': '≠',
  'Odd Word Out': '🙃', 'Number Rule': 'f(x)', 'Proportions': '⚖️', 'Age Puzzle': '🎂', 'Who Is Tallest': '🦒',
  'Compass Turns': '🧭',
  // Focus
  'Symbol Count': '★', 'Fruit Count': '🍎', 'Find the Odd Symbol': '🔍', 'Stroop: Ink Color': '🎨', 'Stroop: Word': '🖍️',
  'Reaction Time': '⚡', 'Schulte Table': '1→25', 'Aim Trainer': '🎯',
  // Word
  'Anagrams': '🔀', 'Missing Letter': 'A_C', 'Reverse Word': '⇄', 'Vowel Count': 'AEIOU', 'Letter Count': '#A',
  'Alphabet Position': 'A=1', 'Letter After': 'A→', 'Letter Before': '←Z', 'First in A–Z': 'A…', 'Last in A–Z': '…Z',
  'Longest Word': '📜', 'Opposites': '☯️', 'Synonyms': '≡', 'Spell Check': '✍️', 'Word Categories': '🗂️',
  'Capital Cities': '🏛️', 'Compound Words': '🧩', 'Starts With': '🅰️',
  // Memory & Puzzle
  'Simon Says': '🔴', 'Number Memory': '🔢', 'Pattern Memory': '🧠', 'Card Match': '🃏',
  'Sliding Puzzle': '🧱', 'Lights Out': '💡', 'Tic Tac Toe': '⭕', 'Guess the Number': '❓',
  // Complex
  '2048': '2048', 'Sudoku': '9×9', 'Minesweeper': '💣', 'Mastermind': '🕵️', 'Hanoi Tower': '🗼', 'Connect Four': '🟡🔴',
  // Board & Cards
  'Ludo': '🎲', 'Snakes & Ladders': '🐍🪜', 'Blackjack': '21', 'Crazy Eights': '8♠', 'Higher or Lower': '⬆️⬇️',
};

String? glyphFor(Game g) => g.glyph ?? glyphs[g.name] ?? glyphs[g.name.split(' ').take(2).join(' ')] ?? glyphs[g.name.split(' ').first];

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Brain Games',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? cat;
  String query = '';

  bool opening = false;

  List<String> get recent => prefs?.getStringList('recent') ?? [];

  Future<void> open(Game g) async {
    if (opening) return; // a quick double tap would push the game twice
    opening = true;
    prefs?.setStringList('recent', [g.name, ...recent.where((n) => n != g.name)].take(8).toList());
    await Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: g.name), builder: (_) => g.build()));
    opening = false;
    if (mounted) setState(() {}); // refresh best scores
  }

  @override
  Widget build(BuildContext context) {
    final muted = prefs?.getBool('mute') ?? false;
    final list = allGames.where((g) => (cat == null || g.cat == cat) && g.name.toLowerCase().contains(query.toLowerCase())).toList();
    final byName = {for (final g in allGames) g.name: g};
    final played = cat == null && query.isEmpty ? [for (final n in recent) if (byName[n] case final g?) g] : <Game>[]; // renamed games drop out
    return Scaffold(
      appBar: AppBar(title: Text('Brain Games · ${allGames.length}'), actions: [
        IconButton(
          tooltip: 'Sound',
          icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
          onPressed: () => setState(() => prefs?.setBool('mute', !muted)),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: list.isEmpty ? null : () => open(list[Random().nextInt(list.length)]),
        icon: const Icon(Icons.casino),
        label: const Text('Surprise me'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SearchBar(hintText: 'Search games', leading: const Icon(Icons.search), onChanged: (v) => setState(() => query = v)),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in [null, ...cats.keys])
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: ChoiceChip(
                    avatar: c == null ? null : Icon(cats[c]!.$1, size: 18),
                    label: Text(c ?? 'All'),
                    selected: cat == c,
                    onSelected: (_) => setState(() => cat = c),
                  ),
                ),
            ],
          ),
        ),
        if (played.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 6), child: Align(alignment: Alignment.centerLeft, child: Text('Recently played'))),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: played.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(width: 114, child: GameCard(played[i], onTap: () => open(played[i]))),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .95),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
            itemCount: list.length,
            itemBuilder: (_, i) => TweenAnimationBuilder<double>(
              key: ValueKey('$cat|$query|${list[i].name}'), // re-animate when the filter changes
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 250 + 40 * min(i, 12)),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Opacity(opacity: v.clamp(0, 1), child: Transform.translate(offset: Offset(0, (1 - v) * 30), child: child)),
              child: GameCard(list[i], onTap: () => open(list[i])),
            ),
          ),
        ),
      ]),
    );
  }
}

class GameCard extends StatefulWidget {
  const GameCard(this.g, {super.key, required this.onTap});
  final Game g;
  final VoidCallback onTap;
  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool down = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.g, color = cats[g.cat]!.$2, best = prefs?.getString('bestText:${g.name}');
    return AnimatedScale(
      scale: down ? .93 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.shade400, color.shade900]),
          boxShadow: [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onHighlightChanged: (v) => setState(() => down = v),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      child: Text(glyphFor(g) ?? '?', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
                Text(g.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                Text(best == null ? 'New' : '🏆 $best', style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
