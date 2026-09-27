import 'dart:math';

import 'package:flutter/material.dart';

import 'games.dart';

/// One multiple-choice question.
class Q {
  Q(this.prompt, this.answer, Iterable<String> wrongs, {this.ask, this.color})
      : options = ({answer, ...(wrongs.toList()..shuffle())}.take(4).toList()..shuffle());
  final String prompt, answer;
  final List<String> options;
  final String? ask;
  final Color? color;
}

/// Makes a question at difficulty [d] (1–4).
typedef Gen = Q Function(Random r, int d);

Game quiz(String name, String cat, Gen gen) => Game(name, cat, () => QuizScreen(name, gen));

class QuizScreen extends StatefulWidget {
  const QuizScreen(this.title, this.gen, {super.key});
  final String title;
  final Gen gen;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const total = 10;
  final _r = Random();
  int i = 0, score = 0;
  late Q q = widget.gen(_r, 1);
  String? picked;

  Future<void> pick(String o) async {
    if (picked != null) return;
    setState(() {
      picked = o;
      if (o == q.answer) score++;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (++i < total) {
      setState(() {
        picked = null;
        q = widget.gen(_r, 1 + i ~/ 3);
      });
      return;
    }
    showResult(context, 'Score: $score / $total', () => setState(() {
          i = score = 0;
          picked = null;
          q = widget.gen(_r, 1);
        }));
  }

  Color? colorFor(String o) {
    if (picked == null) return null;
    if (o == q.answer) return Colors.green.shade700;
    return o == picked ? Colors.red.shade700 : null;
  }

  @override
  Widget build(BuildContext context) => page(
        widget.title,
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                LinearProgressIndicator(value: i / total),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(children: [
                        if (q.ask != null) Text(q.ask!, style: const TextStyle(fontSize: 18, color: Colors.white70), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(q.prompt, textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: q.color)),
                      ]),
                    ),
                  ),
                ),
                for (final o in q.options)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(backgroundColor: colorFor(o)),
                        onPressed: () => pick(o),
                        child: Text(o, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        '${i + 1}/$total · ★$score',
      );
}

// ---------- helpers ----------

int rn(Random r, int lo, int hi) => lo + r.nextInt(hi - lo + 1);
T one<T>(Random r, List<T> l) => l[r.nextInt(l.length)];

/// Numeric question with nearby wrong answers.
Q n(String p, int a, Random r, {String? ask}) {
  final step = max(1, a.abs() ~/ 20), w = <String>{};
  while (w.length < 3) {
    final x = a + (r.nextInt(9) - 4) * step;
    if (x != a && (x >= 0 || a < 0)) w.add('$x');
  }
  return Q(p, '$a', w, ask: ask);
}

Q yn(String p, bool b, {String? ask}) => Q(p, b ? 'Yes' : 'No', [b ? 'No' : 'Yes'], ask: ask);
Q tf(String p, bool b) => Q(p, b ? 'True' : 'False', [b ? 'False' : 'True'], ask: 'True or false?');
Q choice(String p, String a, Iterable<String> pool, {String? ask}) => Q(p, a, pool.where((e) => e != a), ask: ask);

bool isPrime(int x) {
  if (x < 2) return false;
  for (var i = 2; i * i <= x; i++) {
    if (x % i == 0) return false;
  }
  return true;
}

String roman(int n) {
  const v = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
  const s = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
  final b = StringBuffer();
  for (var i = 0; i < v.length; i++) {
    for (; n >= v[i]; n -= v[i]) {
      b.write(s[i]);
    }
  }
  return '$b';
}

String scramble(String w, Random r) {
  String s;
  do {
    s = (w.split('')..shuffle(r)).join();
  } while (s == w);
  return s;
}

String swapAt(String w, int i) => w.substring(0, i) + w[i + 1] + w[i] + w.substring(i + 2);
Set<String> typos(String w) => {for (var i = 0; i < w.length - 1; i++) swapAt(w, i)}..remove(w);
List<String> nearLetters(int t) => [for (final j in [-2, -1, 1, 2]) if (t + j >= 0 && t + j < 26) abc[t + j]];
List<String> sample(Random r, List<String> l, int k) => (l.toList()..shuffle(r)).take(k).toList();

Gen counting(List<String> sym) => (r, d) {
      final s = [for (var i = 0; i < 8 + 4 * d; i++) one(r, sym)], t = one(r, sym);
      return n(s.join(' '), s.where((x) => x == t).length, r, ask: 'How many $t ?');
    };

// ---------- data ----------

const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
final primes = [for (var i = 2; i < 300; i++) if (isPrime(i)) i];
const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const dirs = ['North', 'East', 'South', 'West'];
const names = ['Ali', 'Sara', 'Rafi', 'Nila', 'Omar', 'Tina'];
const words = [
  'PLANET', 'GARDEN', 'BRIDGE', 'CASTLE', 'ORANGE', 'PENCIL', 'ROCKET', 'SILVER', 'WINTER', 'JUNGLE', //
  'MARKET', 'DRAGON', 'FOREST', 'ISLAND', 'KITTEN', 'LEMON', 'MIRROR', 'PUZZLE', 'RABBIT', 'SUMMER',
  'TICKET', 'VALLEY', 'WINDOW', 'ANCHOR', 'BUTTER', 'CANDLE', 'DOCTOR', 'ENGINE', 'FLOWER', 'GUITAR',
  'HAMMER', 'INSECT', 'JACKET', 'LADDER', 'MONKEY', 'NATURE', 'OYSTER', 'PEPPER', 'QUEEN', 'RIVER',
  'SPIDER', 'TOMATO', 'UNCLE', 'VIOLIN', 'WALNUT', 'YELLOW', 'ZIPPER', 'BRAIN', 'CLOUD', 'OCEAN',
];
const antonyms = [
  ('HOT', 'COLD'), ('BIG', 'SMALL'), ('FAST', 'SLOW'), ('HAPPY', 'SAD'), ('LIGHT', 'DARK'), ('OPEN', 'CLOSED'),
  ('EARLY', 'LATE'), ('FULL', 'EMPTY'), ('HARD', 'SOFT'), ('HIGH', 'LOW'), ('RICH', 'POOR'), ('STRONG', 'WEAK'),
  ('YOUNG', 'OLD'), ('WET', 'DRY'), ('LOUD', 'QUIET'), ('PUSH', 'PULL'), ('WIN', 'LOSE'), ('BUY', 'SELL'),
];
const synonyms = [
  ('BIG', 'LARGE'), ('SMALL', 'TINY'), ('HAPPY', 'GLAD'), ('FAST', 'QUICK'), ('SMART', 'CLEVER'), ('ANGRY', 'MAD'),
  ('BEGIN', 'START'), ('END', 'FINISH'), ('SHUT', 'CLOSE'), ('BRAVE', 'BOLD'), ('EASY', 'SIMPLE'), ('HUGE', 'GIANT'),
  ('RICH', 'WEALTHY'), ('SCARED', 'AFRAID'), ('CHOOSE', 'PICK'), ('TALK', 'SPEAK'), ('JUMP', 'LEAP'), ('SHOUT', 'YELL'),
];
const capitals = [
  ('Bangladesh', 'Dhaka'), ('India', 'New Delhi'), ('Japan', 'Tokyo'), ('France', 'Paris'), ('Germany', 'Berlin'),
  ('Italy', 'Rome'), ('Spain', 'Madrid'), ('Egypt', 'Cairo'), ('Canada', 'Ottawa'), ('Australia', 'Canberra'),
  ('Brazil', 'Brasília'), ('China', 'Beijing'), ('Russia', 'Moscow'), ('Turkey', 'Ankara'), ('Kenya', 'Nairobi'),
  ('Nepal', 'Kathmandu'), ('Pakistan', 'Islamabad'), ('Thailand', 'Bangkok'), ('Norway', 'Oslo'),
  ('Argentina', 'Buenos Aires'), ('South Korea', 'Seoul'), ('Indonesia', 'Jakarta'), ('Saudi Arabia', 'Riyadh'),
  ('United Kingdom', 'London'), ('USA', 'Washington D.C.'),
];
const categories = {
  'fruit': ['APPLE', 'BANANA', 'MANGO', 'GRAPE', 'CHERRY', 'PEAR'],
  'animal': ['TIGER', 'HORSE', 'EAGLE', 'SHARK', 'ZEBRA', 'CAMEL'],
  'color': ['RED', 'BLUE', 'GREEN', 'PURPLE', 'PINK', 'BROWN'],
  'country': ['JAPAN', 'EGYPT', 'PERU', 'CHILE', 'KENYA', 'NEPAL'],
  'vehicle': ['TRAIN', 'TRUCK', 'PLANE', 'BOAT', 'BUS', 'BIKE'],
  'instrument': ['PIANO', 'DRUM', 'FLUTE', 'GUITAR', 'VIOLIN', 'HARP'],
};
const compounds = [
  ('SUN', 'FLOWER'), ('RAIN', 'BOW'), ('BUTTER', 'FLY'), ('FOOT', 'BALL'), ('TOOTH', 'BRUSH'), ('SNOW', 'MAN'),
  ('BED', 'ROOM'), ('FIRE', 'WORK'), ('HAND', 'BAG'), ('MOON', 'LIGHT'), ('KEY', 'BOARD'), ('NOTE', 'BOOK'),
  ('CUP', 'CAKE'), ('SEA', 'SHELL'), ('STAR', 'FISH'), ('WATER', 'FALL'),
];
const stroop = {'RED': Colors.red, 'BLUE': Colors.blue, 'GREEN': Colors.green, 'YELLOW': Colors.yellow, 'PURPLE': Colors.purple, 'ORANGE': Colors.orange};
const units = [('km', 'm', 1000), ('m', 'cm', 100), ('kg', 'g', 1000), ('hours', 'minutes', 60), ('minutes', 'seconds', 60), ('days', 'hours', 24), ('weeks', 'days', 7), ('L', 'mL', 1000)];

// ---------- games ----------

final quizGames = <Game>[
  // Math
  quiz('Addition', 'Math', (r, d) {
    final a = rn(r, 1, 10 * d * d), b = rn(r, 1, 10 * d * d);
    return n('$a + $b', a + b, r);
  }),
  quiz('Subtraction', 'Math', (r, d) {
    final a = rn(r, 5, 10 * d * d + 5), b = rn(r, 1, a);
    return n('$a − $b', a - b, r);
  }),
  quiz('Multiplication', 'Math', (r, d) {
    final a = rn(r, 2, 3 + 3 * d), b = rn(r, 2, 9 + d);
    return n('$a × $b', a * b, r);
  }),
  quiz('Division', 'Math', (r, d) {
    final b = rn(r, 2, 5 + 2 * d), q = rn(r, 2, 5 + 2 * d);
    return n('${b * q} ÷ $b', q, r);
  }),
  quiz('Mixed Operations', 'Math', (r, d) {
    final a = rn(r, 2, 10 * d), b = rn(r, 2, 10 * d), c = b % 10 + 2;
    return switch (r.nextInt(4)) {
      0 => n('$a + $b', a + b, r),
      1 => n('${a + b} − $b', a, r),
      2 => n('$a × $c', a * c, r),
      _ => n('${a * c} ÷ $c', a, r),
    };
  }),
  quiz('Squares', 'Math', (r, d) {
    final x = rn(r, 2, 5 + 5 * d);
    return n('$x²', x * x, r);
  }),
  quiz('Cubes', 'Math', (r, d) {
    final x = rn(r, 2, 3 + 2 * d);
    return n('$x³', x * x * x, r);
  }),
  quiz('Square Roots', 'Math', (r, d) {
    final x = rn(r, 2, 5 + 5 * d);
    return n('√${x * x}', x, r);
  }),
  quiz('Powers of Two', 'Math', (r, d) {
    final e = rn(r, 1, 4 + 3 * d);
    return n('2^$e', 1 << e, r);
  }),
  quiz('Percentages', 'Math', (r, d) {
    final p = one(r, [10, 20, 25, 50, 75]), x = rn(r, 1, 5 * d) * 20;
    return n('$p% of $x', p * x ~/ 100, r);
  }),
  quiz('Doubling', 'Math', (r, d) {
    final x = rn(r, 10, 50 * d * d);
    return n('Double $x', 2 * x, r);
  }),
  quiz('Halving', 'Math', (r, d) {
    final x = rn(r, 5, 50 * d * d) * 2;
    return n('Half of $x', x ~/ 2, r);
  }),
  quiz('Remainders', 'Math', (r, d) {
    final a = rn(r, 10, 30 * d), b = rn(r, 2, 3 + 2 * d);
    return n('$a ÷ $b', a % b, r, ask: 'Remainder?');
  }),
  quiz('Missing Addend', 'Math', (r, d) {
    final a = rn(r, 1, 10 * d * d), b = rn(r, 1, 10 * d * d);
    return n('$a + ? = ${a + b}', b, r);
  }),
  quiz('Missing Factor', 'Math', (r, d) {
    final a = rn(r, 2, 5 + d), b = rn(r, 2, 5 + 2 * d);
    return n('$a × ? = ${a * b}', b, r);
  }),
  quiz('Digit Sum', 'Math', (r, d) {
    final x = rn(r, 10, pow(10, d + 1).toInt() - 1);
    return n('$x', '$x'.split('').fold(0, (s, c) => s + int.parse(c)), r, ask: 'Sum of digits?');
  }),
  quiz('Times Eleven', 'Math', (r, d) {
    final x = rn(r, 11, d < 3 ? 99 : 999);
    return n('$x × 11', x * 11, r);
  }),
  quiz('Times Five', 'Math', (r, d) {
    final x = rn(r, 10, 50 * d);
    return n('$x × 5', x * 5, r);
  }),
  quiz('Order of Operations', 'Math', (r, d) {
    final a = rn(r, 2, 5 + 2 * d), b = rn(r, 2, 5 + 2 * d), c = rn(r, 2, 5 + 2 * d);
    return r.nextBool() ? n('$a + $b × $c', a + b * c, r) : n('$a × $b − $c', a * b - c, r);
  }),
  quiz('Triple Sum', 'Math', (r, d) {
    final a = rn(r, 1, 20 * d), b = rn(r, 1, 20 * d), c = rn(r, 1, 20 * d);
    return n('$a + $b + $c', a + b + c, r);
  }),
  quiz('Rounding', 'Math', (r, d) {
    final x = rn(r, 11, 100 * d * d);
    return n('$x', (x + 5) ~/ 10 * 10, r, ask: 'Round to nearest 10');
  }),
  quiz('Greatest Common Divisor', 'Math', (r, d) {
    final g = rn(r, 2, 3 + 2 * d), a = g * rn(r, 1, 6), b = g * rn(r, 1, 6);
    return n('GCD($a, $b)', a.gcd(b), r);
  }),
  quiz('Least Common Multiple', 'Math', (r, d) {
    final a = rn(r, 2, 4 + 2 * d), b = rn(r, 2, 4 + 2 * d);
    return n('LCM($a, $b)', a * b ~/ a.gcd(b), r);
  }),
  quiz('Factorials', 'Math', (r, d) {
    final x = rn(r, 1, 3 + d);
    return n('$x!', List.generate(x, (i) => i + 1).fold(1, (a, b) => a * b), r);
  }),
  quiz('Negative Numbers', 'Math', (r, d) {
    final a = rn(r, -10 * d, 10 * d), b = rn(r, -10 * d, 10 * d);
    return n('$a + ($b)', a + b, r);
  }),
  quiz('Averages', 'Math', (r, d) {
    final m = rn(r, 5, 20 * d), o = rn(r, 1, 5 * d), l = [m - o, m, m + o]..shuffle(r);
    return n(l.join(', '), m, r, ask: 'Average?');
  }),
  quiz('Clock Hours', 'Math', (r, d) {
    final h = rn(r, 1, 12), k = rn(r, 1, 6 * d);
    return choice("$h o'clock + $k h", '${(h + k - 1) % 12 + 1}', [for (var i = 1; i <= 12; i++) '$i'], ask: 'What hour will it be?');
  }),
  quiz('Making Change', 'Math', (r, d) {
    final price = rn(r, 1, 99 * d), pay = (price ~/ 100 + 1) * 100;
    return n('Pay $pay for $price', pay - price, r, ask: 'Change?');
  }),
  quiz('Speed × Time', 'Math', (r, d) {
    final s = rn(r, 2, 12) * 5, t = rn(r, 1, 2 + d);
    return n('$s km/h for $t h', s * t, r, ask: 'Distance in km?');
  }),
  quiz('Bigger Product', 'Math', (r, d) {
    int a, b, c, e;
    do {
      a = rn(r, 2, 5 + 3 * d);
      b = rn(r, 2, 5 + 3 * d);
      c = rn(r, 2, 5 + 3 * d);
      e = rn(r, 2, 5 + 3 * d);
    } while (a * b == c * e);
    final x = '$a × $b', y = '$c × $e';
    return Q('Which is bigger?', a * b > c * e ? x : y, [a * b > c * e ? y : x]);
  }),
  quiz('True or False', 'Math', (r, d) {
    final a = rn(r, 2, 5 + 2 * d), b = rn(r, 2, 5 + 2 * d), shown = r.nextBool() ? a * b : a * b + one(r, [-2, -1, 1, 2]);
    return tf('$a × $b = $shown', shown == a * b);
  }),
  quiz('Even or Odd', 'Math', (r, d) {
    final x = rn(r, 100, pow(10, d + 2).toInt());
    return Q('$x', x.isEven ? 'Even' : 'Odd', ['Even', 'Odd'], ask: 'Even or odd?');
  }),
  quiz('Prime or Not', 'Math', (r, d) {
    final x = r.nextBool() ? one(r, primes.where((p) => p < 20 * d * d).toList()) : rn(r, 4, 20 * d * d);
    return yn('$x', isPrime(x), ask: 'Is it prime?');
  }),
  quiz('Divisible by 3', 'Math', (r, d) {
    final x = rn(r, 100, pow(10, d + 2).toInt());
    return yn('$x', x % 3 == 0, ask: 'Divisible by 3?');
  }),
  quiz('Binary to Decimal', 'Math', (r, d) {
    final x = rn(r, 1, 1 << (2 + d));
    return n(x.toRadixString(2), x, r, ask: 'Binary → decimal');
  }),
  quiz('Decimal to Binary', 'Math', (r, d) {
    final x = rn(r, 3, 1 << (2 + d));
    return Q('$x', x.toRadixString(2), [for (final k in [-2, -1, 1, 2, 3]) if (x + k > 0) (x + k).toRadixString(2)], ask: 'Decimal → binary');
  }),
  quiz('Hex to Decimal', 'Math', (r, d) {
    final x = rn(r, 10, 16 * d * d);
    return n(x.toRadixString(16).toUpperCase(), x, r, ask: 'Hex → decimal');
  }),
  quiz('Roman to Number', 'Math', (r, d) {
    final x = rn(r, 1, 50 * d);
    return n(roman(x), x, r, ask: 'Roman → number');
  }),
  quiz('Number to Roman', 'Math', (r, d) {
    final x = rn(r, 4, 50 * d);
    return Q('$x', roman(x), [for (final k in [-2, -1, 1, 2, 10]) roman(x + k)], ask: 'Number → Roman');
  }),
  quiz('Compare Fractions', 'Math', (r, d) {
    int a, b, c, e;
    do {
      b = rn(r, 2, 5 + d);
      e = rn(r, 2, 5 + d);
      a = rn(r, 1, b - 1);
      c = rn(r, 1, e - 1);
    } while (a * e == c * b);
    final x = '$a/$b', y = '$c/$e';
    return Q('Which is bigger?', a * e > c * b ? x : y, [a * e > c * b ? y : x]);
  }),
  quiz('Unit Conversion', 'Math', (r, d) {
    final (f, t, k) = one(r, units);
    final x = rn(r, 1, 5 * d);
    return n('$x $f = ? $t', x * k, r);
  }),
  quiz('Weekday Jump', 'Math', (r, d) {
    final s = r.nextInt(7), k = rn(r, 1, 10 * d);
    return choice('${days[s]} + $k days', days[(s + k) % 7], days, ask: 'Which day?');
  }),
  quiz('Month Jump', 'Math', (r, d) {
    final s = r.nextInt(12), k = rn(r, 1, 6 * d);
    return choice('${months[s]} + $k months', months[(s + k) % 12], months, ask: 'Which month?');
  }),
  quiz('Celsius to Fahrenheit', 'Math', (r, d) {
    final c = rn(r, -4, 8 * d) * 5;
    return n('$c°C', c * 9 ~/ 5 + 32, r, ask: 'In °F?');
  }),
  quiz('Coin Counting', 'Math', (r, d) {
    final a = rn(r, 1, 2 + d), b = rn(r, 0, 2 + d), c = rn(r, 0, 2 + d), e = rn(r, 0, 2 + d);
    return n('$a×10 + $b×5 + $c×2 + $e×1', a * 10 + b * 5 + c * 2 + e, r, ask: 'Total coin value?');
  }),
  quiz('Leap Year', 'Math', (r, d) {
    final y = rn(r, 1800, 2400);
    return yn('$y', y % 4 == 0 && (y % 100 != 0 || y % 400 == 0), ask: 'Leap year?');
  }),
  quiz('Dice Opposites', 'Math', (r, d) {
    final v = rn(r, 1, 6);
    return choice('Opposite of $v', '${7 - v}', ['1', '2', '3', '4', '5', '6'], ask: 'On a standard die');
  }),
  quiz('Make 100', 'Math', (r, d) {
    final t = d < 3 ? 100 : 1000, x = rn(r, 1, t - 1);
    return n('$x + ? = $t', t - x, r);
  }),
  quiz('Perimeter', 'Math', (r, d) {
    final w = rn(r, 2, 5 + 5 * d), h = rn(r, 2, 5 + 5 * d);
    return n('Rectangle $w × $h', 2 * (w + h), r, ask: 'Perimeter?');
  }),
  quiz('Area', 'Math', (r, d) {
    final w = rn(r, 2, 5 + 3 * d), h = rn(r, 2, 5 + 3 * d);
    return n('Rectangle $w × $h', w * h, r, ask: 'Area?');
  }),
  quiz('Triangle Angles', 'Math', (r, d) {
    final a = rn(r, 20, 100), b = rn(r, 10, 170 - a);
    return n('$a° and $b°', 180 - a - b, r, ask: 'Third angle of the triangle?');
  }),

  // Logic
  quiz('Arithmetic Sequence', 'Logic', (r, d) {
    final a = rn(r, 1, 20 * d), s = rn(r, 1, 2 + 3 * d) * (r.nextBool() ? 1 : -1);
    return n('${[for (var i = 0; i < 4; i++) a + i * s].join(', ')}, ?', a + 4 * s, r);
  }),
  quiz('Geometric Sequence', 'Logic', (r, d) {
    final a = rn(r, 1, 3 + d), q = rn(r, 2, 2 + d), l = [a];
    while (l.length < 5) {
      l.add(l.last * q);
    }
    return n('${l.take(4).join(', ')}, ?', l[4], r);
  }),
  quiz('Fibonacci-like', 'Logic', (r, d) {
    final l = [rn(r, 1, 5 * d), rn(r, 1, 5 * d)];
    while (l.length < 6) {
      l.add(l[l.length - 1] + l[l.length - 2]);
    }
    return n('${l.take(5).join(', ')}, ?', l[5], r);
  }),
  quiz('Square Sequence', 'Logic', (r, d) {
    final s = rn(r, 1, 5 * d);
    return n('${[for (var i = 0; i < 4; i++) (s + i) * (s + i)].join(', ')}, ?', (s + 4) * (s + 4), r);
  }),
  quiz('Alternating Sequence', 'Logic', (r, d) {
    final p = rn(r, 2, 5 + 2 * d), m = rn(r, 1, p - 1), l = [rn(r, 10, 30 * d)];
    for (var i = 0; i < 5; i++) {
      l.add(l.last + (i.isEven ? p : -m));
    }
    return n('${l.take(5).join(', ')}, ?', l[5], r);
  }),
  quiz('Prime Sequence', 'Logic', (r, d) {
    final i = rn(r, 0, 8 * d);
    return n('${primes.sublist(i, i + 4).join(', ')}, ?', primes[i + 4], r);
  }),
  quiz('Letter Sequence', 'Logic', (r, d) {
    final st = rn(r, 1, 1 + d), s = rn(r, 0, 25 - 4 * st);
    return Q('${[for (var k = 0; k < 4; k++) abc[s + k * st]].join(' ')} ?', abc[s + 4 * st], nearLetters(s + 4 * st));
  }),
  quiz('Not a Multiple', 'Logic', (r, d) {
    final k = rn(r, 3, 4 + 2 * d), m = <String>{};
    while (m.length < 3) {
      m.add('${k * rn(r, 2, 12)}');
    }
    int x;
    do {
      x = rn(r, 10, 12 * k);
    } while (x % k == 0);
    return Q('Not a multiple of $k?', '$x', m);
  }),
  quiz('Odd Word Out', 'Logic', (r, d) {
    final cats = sample(r, categories.keys.toList(), 2);
    return Q("Which doesn't belong?", one(r, categories[cats[1]]!), sample(r, categories[cats[0]]!, 3));
  }),
  quiz('Number Rule', 'Logic', (r, d) {
    final k = rn(r, 2, 9);
    final f = one(r, <int Function(int)>[(x) => x * k, (x) => x + k, (x) => x * x, (x) => x * k - 1, (x) => x * x + k]);
    final xs = sample(r, [for (var i = 1; i <= 6 + 2 * d; i++) '$i'], 3).map(int.parse).toList();
    return n('${xs[0]} → ${f(xs[0])}\n${xs[1]} → ${f(xs[1])}\n${xs[2]} → ?', f(xs[2]), r);
  }),
  quiz('Proportions', 'Logic', (r, d) {
    final a = rn(r, 2, 5), p = rn(r, 2, 10 * d), b = rn(r, 2, 12);
    return n('$a pens cost ${a * p}', b * p, r, ask: 'How much do $b pens cost?');
  }),
  quiz('Age Puzzle', 'Logic', (r, d) {
    final x = rn(r, 5, 30), y = rn(r, 1, 10 * d), z = rn(r, 1, 10);
    return n('Tom is $x.\nAnn is $y years older.', x + y + z, r, ask: "Ann's age in $z years?");
  }),
  quiz('Who Is Tallest', 'Logic', (r, d) {
    final o = sample(r, names, min(2 + d, 5));
    final st = [for (var i = 0; i < o.length - 1; i++) '${o[i]} is taller than ${o[i + 1]}']..shuffle(r);
    final tall = r.nextBool();
    return choice(st.join('\n'), tall ? o.first : o.last, o, ask: tall ? 'Who is tallest?' : 'Who is shortest?');
  }),
  quiz('Compass Turns', 'Logic', (r, d) {
    final t = [for (var i = 0; i < d + 1; i++) r.nextBool()];
    final pos = t.fold(0, (s, right) => s + (right ? 1 : -1)) % 4;
    return choice('Face North.\nTurn ${t.map((b) => b ? 'right' : 'left').join(', ')}.', dirs[pos], dirs, ask: 'Which way now?');
  }),

  // Focus
  quiz('Symbol Count', 'Focus', counting(['★', '●', '▲', '■'])),
  quiz('Fruit Count', 'Focus', counting(['🍎', '🍌', '🍇', '🍒', '🍋'])),
  quiz('Find the Odd Symbol', 'Focus', (r, d) {
    final p = one(r, [('O', 'Q'), ('b', 'd'), ('E', 'F'), ('8', 'B'), ('M', 'N'), ('p', 'q'), ('6', '9')]);
    final s = List.filled(6 + 3 * d, p.$1), pos = r.nextInt(s.length);
    s[pos] = p.$2;
    return n(s.join(' '), pos + 1, r, ask: 'Position of the odd one?');
  }),
  quiz('Stroop: Ink Color', 'Focus', (r, d) {
    final c = stroop.keys.toList(), w = one(r, c);
    final ink = one(r, c.where((x) => x != w).toList());
    return Q(w, ink, c, ask: 'Tap the INK color', color: stroop[ink]);
  }),
  quiz('Stroop: Word', 'Focus', (r, d) {
    final c = stroop.keys.toList(), w = one(r, c);
    final ink = one(r, c.where((x) => x != w).toList());
    return Q(w, w, c, ask: 'What does the word SAY?', color: stroop[ink]);
  }),

  // Word
  quiz('Anagrams', 'Word', (r, d) {
    final w = one(r, words);
    return choice(scramble(w, r), w, words.where((x) => x.length == w.length), ask: 'Unscramble');
  }),
  quiz('Missing Letter', 'Word', (r, d) {
    final w = one(r, words), i = r.nextInt(w.length);
    return Q(w.replaceRange(i, i + 1, '_'), w[i], abc.split(''), ask: 'Fill the blank');
  }),
  quiz('Reverse Word', 'Word', (r, d) {
    final w = one(r, words), rev = w.split('').reversed.join();
    return Q(w, rev, typos(rev), ask: 'Spell it backwards');
  }),
  quiz('Vowel Count', 'Word', (r, d) {
    final w = one(r, words);
    return n(w, w.split('').where('AEIOU'.contains).length, r, ask: 'How many vowels?');
  }),
  quiz('Letter Count', 'Word', (r, d) {
    final w = one(r, words), ch = w[r.nextInt(w.length)];
    return n(w, ch.allMatches(w).length, r, ask: 'How many "$ch"?');
  }),
  quiz('Alphabet Position', 'Word', (r, d) {
    final i = r.nextInt(26);
    return n(abc[i], i + 1, r, ask: 'Position in the alphabet?');
  }),
  quiz('Letter After', 'Word', (r, d) {
    final k = rn(r, 1, 2 + d), i = rn(r, 0, 25 - k);
    return Q('${abc[i]} + $k', abc[i + k], nearLetters(i + k), ask: 'Which letter?');
  }),
  quiz('Letter Before', 'Word', (r, d) {
    final k = rn(r, 1, 2 + d), i = rn(r, k, 25);
    return Q('${abc[i]} − $k', abc[i - k], nearLetters(i - k), ask: 'Which letter?');
  }),
  quiz('First in A–Z', 'Word', (r, d) {
    final ws = sample(r, words, 4);
    return Q('First alphabetically?', (ws.toList()..sort()).first, ws);
  }),
  quiz('Last in A–Z', 'Word', (r, d) {
    final ws = sample(r, words, 4);
    return Q('Last alphabetically?', (ws.toList()..sort()).last, ws);
  }),
  quiz('Longest Word', 'Word', (r, d) {
    List<String> ws;
    do {
      ws = sample(r, words, 4)..sort((a, b) => b.length - a.length);
    } while (ws[0].length == ws[1].length);
    return Q('Longest word?', ws[0], ws);
  }),
  quiz('Opposites', 'Word', (r, d) {
    final (a, b) = one(r, antonyms);
    return r.nextBool()
        ? choice(a, b, antonyms.map((e) => e.$2), ask: 'Opposite of')
        : choice(b, a, antonyms.map((e) => e.$1), ask: 'Opposite of');
  }),
  quiz('Synonyms', 'Word', (r, d) {
    final (a, b) = one(r, synonyms);
    return choice(a, b, synonyms.map((e) => e.$2), ask: 'Same meaning as');
  }),
  quiz('Spell Check', 'Word', (r, d) {
    final w = one(r, words);
    return Q('Correct spelling?', w, typos(w));
  }),
  quiz('Word Categories', 'Word', (r, d) {
    final cats = sample(r, categories.keys.toList(), 4);
    return Q('Pick the ${cats[0]}', one(r, categories[cats[0]]!), [for (final c in cats.skip(1)) one(r, categories[c]!)]);
  }),
  quiz('Capital Cities', 'Word', (r, d) {
    final (c, cap) = one(r, capitals);
    return choice(c, cap, capitals.map((e) => e.$2), ask: 'Capital city?');
  }),
  quiz('Compound Words', 'Word', (r, d) {
    final (a, b) = one(r, compounds);
    return choice('$a + ?', b, compounds.map((e) => e.$2), ask: 'Make a word');
  }),
  quiz('Starts With', 'Word', (r, d) {
    final w = one(r, words);
    return Q(w[0], w, words.where((x) => x[0] != w[0]), ask: 'Which word starts with');
  }),
];
