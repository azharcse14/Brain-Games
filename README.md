# Brain Games 🧠

A Flutter app with **300 games**: brain-training quizzes, general knowledge, memory and focus trainers, puzzles, solitaire, casino, board and dice games, plus **100 two-player games** you play together on one device. The app runs on Android, iOS, web, macOS, Windows and Linux.

## Features

- **300 games in 11 categories**, with search, category filters and a 🎲 *Surprise me* button that opens a random game
- **Best scores** saved for every game, shown on each game card with a 🏆 *New best!* on a record
- **Adaptive quizzes**: 10 questions that get harder as you go, a 15-second timer per question and a 🔥 streak counter
- **100 same-device 2-player games**: action games where both players control their own half of the screen at the same time, and pass-and-play board games (Chess, Go, Checkers and more)
- **Computer opponents** in Ludo, Connect Four, Tic Tac Toe (can't be beaten), Crazy Eights and Snakes & Ladders
- **English and বাংলা**: every game, instruction and result in both languages, following the phone's language until you pick one on the home screen (English word games keep their English words)
- **Light and dark theme**, following the phone's setting
- **Recently played** row on the home screen
- **Sound effects and haptics** with a mute toggle
- **Plays fair in the background**: real-time games and solve timers pause when you leave the app, and back asks before quitting a game in progress
- **Endless variety**: every question, puzzle, deck and board is generated at random

## Games

| Category | Count | Games |
|---|---:|---|
| ➗ **Math** | 59 | Addition, Subtraction, Multiplication, Division, Mixed Operations, Squares, Cubes, Square Roots, Powers of Two, Percentages, Doubling, Halving, Remainders, Missing Addend, Missing Factor, Digit Sum, Times Eleven, Times Five, Order of Operations, Triple Sum, Rounding, GCD, LCM, Factorials, Negative Numbers, Averages, Clock Hours, Making Change, Speed × Time, Bigger Product, True or False, Even or Odd, Prime or Not, Divisible by 3, Binary ↔ Decimal, Hex to Decimal, Roman ↔ Number, Compare Fractions, Unit Conversion, Weekday Jump, Month Jump, Celsius to Fahrenheit, Coin Counting, Leap Year, Dice Opposites, Make 100, Perimeter, Area, Triangle Angles, Fraction of Number, Decimal to Fraction, Simple Interest, Ratio Split, Next Prime, Time Difference, Clock Angle, Day of the Year |
| 🧩 **Logic** | 27 | Arithmetic / Geometric / Square / Alternating / Prime / Letter Sequences, Fibonacci-like, Not a Multiple, Odd Word Out, Number Rule, Proportions, Age Puzzle, Who Is Tallest, Compass Turns, Magic Square, Number Pyramid, Code Breaker, Balance Scale, **Sudoku** (Easy, Hard), **Minesweeper** (9×9, 12×12), **Mastermind**, **Nonogram** (5×5, 7×7, 10×10), Skyscrapers 4×4 |
| 🔤 **Word** | 25 | Anagrams, Missing Letter, Reverse Word, Vowel Count, Letter Count, Alphabet Position, Letter After, Letter Before, First / Last in A–Z, Longest Word, Opposites, Synonyms, Spell Check, Word Categories, Capital Cities, Compound Words, Starts With, Rhyme Time, Plurals, Homophones, Word Ladder, **Word Search** (8×8, 10×10, 12×12) |
| 🌍 **Knowledge** | 12 | Country Flags, Capital to Country, Continents, Planets, Chemical Symbols, Symbol to Element, Animal Groups, Baby Animals, Polygon Sides, Metric Prefixes, Human Body, Oceans & Continents |
| 🎯 **Focus** | 12 | Symbol Count, Fruit Count, Find the Odd Symbol, Stroop (Ink Color, Word), Reaction Time, Schulte Table (3×3, 4×4, 5×5), Aim Trainer, Most Common Arrow, Mirror Letters |
| 🧠 **Memory** | 8 | Simon Says, Number Memory, Pattern Memory (3×3, 4×4, 5×5), Card Match (6, 8, 10 pairs) |
| 🧱 **Puzzle** | 28 | **2048** (3×3, 4×4, 5×5, 6×6), Tower of Hanoi (3, 4, 5 disks), Connect Four, Sliding Puzzle (3×3, 4×4), Lights Out (3×3, 4×4, 5×5), Flood It (10×10, 14×14, 18×18), Maze (Small, Medium, Large), Peg Solitaire (Cross, Triangle), Water Sort (4, 6, 8 colors), Knight's Tour (5×5, 6×6), Tic Tac Toe, Guess the Number |
| 🎲 **Board** | 7 | **Ludo** (2 or 4 players), Snakes & Ladders, Yahtzee, Farkle, Shut the Box, Dice Poker |
| 🃏 **Cards** | 22 | **Klondike** (Draw 1, Draw 3), Yukon, **FreeCell**, **Spider** (1, 2, 4 suits), Pyramid, TriPeaks, Golf, Clock, Accordion, Video Poker (Jacks or Better, Deuces Wild), Baccarat, Blackjack, Red Dog, Crazy Eights, War, Go Fish, Old Maid, Higher or Lower |
| 🎮 **2P Action** | 30 | Pong (Classic, Fast, Two Balls, Tiny Paddles, Center Wall, Speed-Up Rally), Air Hockey (Classic, Big Goals, Ice, Heavy Puck, Two Pucks), Tron (Classic, Fast, Small Arena, Wrap-Around, Boost, Obstacles), Snake Duel (Classic, Fast, Wrap, Poison, Long), Tug of War, Tap Race 100, Hold & Release, Rhythm Duel, Reflex Duel (Classic, Stroop, Even, Shapes) |
| 👥 **2P Board** | 70 | **Chess**, **Chess960**, **Go** (9×9, 13×13), Checkers (English, Casual, 10×10, Giveaway), Nine / Six / Three Men's Morris, Quoridor (9×9, 7×7), Battleship (8×8, 10×10), Tablut, Brandubh, Breakthrough (6×6, 8×8), Amazons (6×6, 8×8), Fox and Geese, Konane (6×6, 8×8), Lines of Action, Memory Duel (3 sizes), Hangman Duel, Mastermind Duel, Tic Tac Toe (3×3, 4×4, 5×5, Misère), Ultimate Tic Tac Toe, Gomoku (9×9, 11×11, 15×15, Gravity 10×10), Connect Three / Four / Five, Reversi (6×6, 8×8, 10×10), Dots and Boxes (4 sizes), Mancala (3, 4, 6 seeds), Hex (5×5, 7×7, 9×9), Domineering (3 sizes), Nim (3-4-5, 1-3-5-7, Misère), 21 Sticks, Chomp (2 sizes), Pig (to 50, to 100), Pentago, Isolation, Knight Isolation |

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
- the 2-player rules work: chess (castling, en passant, checkmate, stalemate), Go (capture, ko, suicide), checkers forced jumps, Quoridor wall blocking, Reversi flips, Mancala captures, Hex connections and more; action games play complete matches
- solitaire and casino rules: poker hand evaluation (incl. Deuces Wild), Baccarat third-card rules, Yahtzee and Farkle scoring, Klondike/FreeCell/Spider moves
- puzzles are always solvable: generated Water Sort, Maze, Nonogram, Word Search and Flood It boards are checked
- a monkey test opens all 300 games on a small 360×640 phone and taps each one randomly, in English and Bangla, catching crashes and layout overflows
- every game has a Bangla name, and quizzes are valid in both languages

CI runs `flutter analyze` and `flutter test` on every push and pull request.

## Project structure

```
lib/
├── main.dart      # App entry, home screen (search, categories, game cards)
├── quiz.dart      # Quiz engine + 88 question generators (Math, Logic, Focus, Word)
├── quiz2.dart     # 30 more quizzes incl. the Knowledge category
├── puzzles2.dart  # Nonogram, Word Search, Flood It, Maze, Peg Solitaire, Water Sort, Knight's Tour, 2048 sizes
├── solitaire.dart # Klondike, FreeCell, Spider, Pyramid, TriPeaks, Video Poker, Baccarat, Yahtzee, Farkle, …
├── games.dart     # Shared UI helpers, language (tr) and theme (ink/dim) helpers, best scores, sound, memory/focus/puzzle games
├── complex.dart   # 2048, Sudoku, Minesweeper, Mastermind, Tower of Hanoi, Connect Four
├── tabletop.dart  # Ludo, Snakes & Ladders, Blackjack, Crazy Eights, Higher or Lower
├── duel.dart          # Shared 2-player helpers (colours, turn banner, winner dialog)
├── duel_action.dart   # 30 real-time split-screen games (Pong, Air Hockey, Tron, …)
├── duel_board.dart    # 40 pass-and-play games (Gomoku, Reversi, Mancala, Hex, …)
└── duel_classic.dart  # 30 classic board games (Chess, Go, Checkers, Quoridor, …)
assets/
├── icon.png       # App icon source (generated with flutter_launcher_icons)
└── sfx/           # Sound effects
test/
├── widget_test.dart
├── monkey_test.dart
├── quiz2_test.dart
├── puzzles2_test.dart
├── solitaire_test.dart
├── duel_action_test.dart
├── duel_board_test.dart
└── duel_classic_test.dart
```

### Adding a quiz game

Most games are just a question generator. To add one, add an entry to `quizGames` in `lib/quiz.dart`:

```dart
quiz('Triple It', 'Math', bn: 'তিনগুণ', (r, d) {
  final x = rn(r, 2, 10 * d);          // d = difficulty, 1–4
  return n('3 × $x', 3 * x, r);        // n() builds a question with nearby wrong answers
}),
```

Then give it a card icon in the `glyphs` map in `lib/main.dart`. The tests check that every game has one, and a Bangla name (`bn:`). Wrap any other text a player sees in `tr('English', 'বাংলা')`.

## Built with

- [Flutter](https://flutter.dev)
- [shared_preferences](https://pub.dev/packages/shared_preferences) for best scores and settings
- [audioplayers](https://pub.dev/packages/audioplayers) for sound effects
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) to generate app icons
