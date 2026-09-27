# Brain Games 🧠

A Flutter app with **124 brain-training games**: quick-fire math and word quizzes, memory and focus trainers, classic puzzles, board games and card games. The app runs on Android, iOS, web, macOS, Windows and Linux.

## Features

- **124 games in 8 categories**, with search, category filters and a 🎲 *Surprise me* button that opens a random game
- **Best scores** saved for every game, shown on each game card with a 🏆 *New best!* on a record
- **Adaptive quizzes**: 10 questions that get harder as you go, a 15-second timer per question and a 🔥 streak counter
- **Computer opponents** in Ludo, Connect Four, Tic Tac Toe (can't be beaten), Crazy Eights and Snakes & Ladders
- **Sound effects** with a mute toggle
- **Endless variety**: every question, puzzle, deck and board is generated at random

## Games

| Category | Count | Games |
|---|---:|---|
| ➗ **Math** | 51 | Addition, Subtraction, Multiplication, Division, Mixed Operations, Squares, Cubes, Square Roots, Powers of Two, Percentages, Doubling, Halving, Remainders, Missing Addend, Missing Factor, Digit Sum, Times Eleven, Times Five, Order of Operations, Triple Sum, Rounding, GCD, LCM, Factorials, Negative Numbers, Averages, Clock Hours, Making Change, Speed × Time, Bigger Product, True or False, Even or Odd, Prime or Not, Divisible by 3, Binary ↔ Decimal, Hex to Decimal, Roman ↔ Number, Compare Fractions, Unit Conversion, Weekday Jump, Month Jump, Celsius to Fahrenheit, Coin Counting, Leap Year, Dice Opposites, Make 100, Perimeter, Area, Triangle Angles |
| 🧩 **Logic** | 19 | Arithmetic / Geometric / Square / Alternating / Prime / Letter Sequences, Fibonacci-like, Not a Multiple, Odd Word Out, Number Rule, Proportions, Age Puzzle, Who Is Tallest, Compass Turns, **Sudoku** (Easy, Hard), **Minesweeper** (9×9, 12×12), **Mastermind** |
| 🔤 **Word** | 18 | Anagrams, Missing Letter, Reverse Word, Vowel Count, Letter Count, Alphabet Position, Letter After, Letter Before, First / Last in A–Z, Longest Word, Opposites, Synonyms, Spell Check, Word Categories, Capital Cities, Compound Words, Starts With |
| 🎯 **Focus** | 10 | Symbol Count, Fruit Count, Find the Odd Symbol, Stroop (Ink Color, Word), Reaction Time, Schulte Table (3×3, 4×4, 5×5), Aim Trainer |
| 🧠 **Memory** | 8 | Simon Says, Number Memory, Pattern Memory (3×3, 4×4, 5×5), Card Match (6, 8, 10 pairs) |
| 🧱 **Puzzle** | 12 | **2048**, Tower of Hanoi (3, 4, 5 disks), **Connect Four**, Sliding Puzzle (3×3, 4×4), Lights Out (3×3, 4×4, 5×5), Tic Tac Toe, Guess the Number |
| 🎲 **Board** | 3 | **Ludo** (2 or 4 players), Snakes & Ladders |
| 🃏 **Cards** | 3 | Blackjack, Crazy Eights, Higher or Lower |

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.1 or newer).

```bash
git clone https://github.com/azharcse14/Brain-Games.git
cd Brain-Games
flutter pub get
flutter run            # pick a connected device, emulator or browser
```

Build a release:

```bash
flutter build apk      # Android
flutter build ios      # iOS (on macOS)
flutter build web      # Web
```

## Tests

```bash
flutter analyze
flutter test
```

The tests check that:

- every quiz question at every difficulty always offers the correct answer
- the game logic is correct: 2048 merging, Sudoku generation, Mastermind scoring, Connect Four win detection, Blackjack hand values and the Ludo and Snakes & Ladders boards
- the bigger games open, and Ludo and Snakes & Ladders play many turns against the AI, all without layout errors on a phone-sized screen

## Project structure

```
lib/
├── main.dart      # App entry, home screen (search, categories, game cards)
├── quiz.dart      # Quiz engine + 88 question generators (Math, Logic, Focus, Word)
├── games.dart     # Shared UI helpers, best scores, sound, memory/focus/puzzle games
├── complex.dart   # 2048, Sudoku, Minesweeper, Mastermind, Tower of Hanoi, Connect Four
└── tabletop.dart  # Ludo, Snakes & Ladders, Blackjack, Crazy Eights, Higher or Lower
assets/
├── icon.png       # App icon source (generated with flutter_launcher_icons)
└── sfx/           # Sound effects
test/
└── widget_test.dart
```

### Adding a quiz game

Most games are just a question generator. To add one, add an entry to `quizGames` in `lib/quiz.dart`:

```dart
quiz('Triple It', 'Math', (r, d) {
  final x = rn(r, 2, 10 * d);          // d = difficulty, 1–4
  return n('3 × $x', 3 * x, r);        // n() builds a question with nearby wrong answers
}),
```

Then give it a card icon in the `glyphs` map in `lib/main.dart`. The tests check that every game has one.

## Built with

- [Flutter](https://flutter.dev)
- [shared_preferences](https://pub.dev/packages/shared_preferences) for best scores and settings
- [audioplayers](https://pub.dev/packages/audioplayers) for sound effects
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) to generate app icons
