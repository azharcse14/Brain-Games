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

Game quiz(String name, String cat, Gen gen, {String? bn}) => Game(name, cat, () => QuizScreen(name, gen), bn: bn);

class QuizScreen extends StatefulWidget {
  const QuizScreen(this.title, this.gen, {super.key});
  final String title;
  final Gen gen;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const total = 10, seconds = 15;
  final _r = Random();
  int i = 0, score = 0, streak = 0;
  late Q q = widget.gen(_r, 1);
  String? picked;

  Future<void> pick(String o) async {
    if (picked != null) return;
    setState(() {
      picked = o;
      if (o == q.answer) {
        score++;
        streak++;
      } else {
        streak = 0;
      }
    });
    sfx(o == q.answer ? 'right' : 'wrong');
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (++i < total) {
      setState(() {
        picked = null;
        q = widget.gen(_r, 1 + i ~/ 3);
      });
      return;
    }
    showResult(context, won: score >= total ~/ 2, score: score, unit: '/$total', tr('Score: $score / $total', 'স্কোর: $score / $total'), () => setState(() {
          i = score = streak = 0;
          picked = null;
          q = widget.gen(_r, 1);
        }));
  }

  double timeLeft = 1; // last shown countdown value, kept so the bar freezes after a pick

  Widget timeBar(double v) => LinearProgressIndicator(value: v, minHeight: 6, color: Color.lerp(Colors.red, Colors.amber, v), borderRadius: BorderRadius.circular(3));

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
                const SizedBox(height: 8),
                // Per-question countdown; running out counts as a wrong answer.
                if (picked != null)
                  timeBar(timeLeft)
                else
                  TweenAnimationBuilder<double>(
                    key: ObjectKey(q),
                    tween: Tween(begin: 1, end: 0),
                    duration: const Duration(seconds: seconds),
                    onEnd: () => pick(''),
                    builder: (_, v, __) => timeBar(timeLeft = v),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('$i$picked'), // shakes after a wrong pick
                        tween: Tween(begin: 0, end: picked != null && picked != q.answer ? 1 : 0),
                        duration: const Duration(milliseconds: 450),
                        builder: (_, v, child) => Transform.translate(offset: Offset(sin(v * pi * 6) * 12 * (1 - v), 0), child: child),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, a) => SlideTransition(
                            position: Tween(begin: const Offset(.3, 0), end: Offset.zero).animate(a),
                            child: FadeTransition(opacity: a, child: child),
                          ),
                          child: Column(key: ObjectKey(q), children: [
                            if (q.ask != null) Text(q.ask!, style: const TextStyle(fontSize: 18, color: Colors.white70), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Text(q.prompt, textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: q.color)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final o in q.options)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: AnimatedScale(
                        scale: picked != null && o == q.answer ? 1.05 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(backgroundColor: colorFor(o)),
                          onPressed: () => pick(o),
                          child: Text(o, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        '${streak >= 2 ? '🔥$streak  ' : ''}${min(i + 1, total)}/$total · ★$score',
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

Q yn(String p, bool b, {String? ask}) {
  final y = tr('Yes', 'হ্যাঁ'), no = tr('No', 'না');
  return Q(p, b ? y : no, [b ? no : y], ask: ask);
}

Q tf(String p, bool b) {
  final t = tr('True', 'সত্য'), f = tr('False', 'মিথ্যা');
  return Q(p, b ? t : f, [b ? f : t], ask: tr('True or false?', 'সত্য না মিথ্যা?'));
}
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

/// Real words that a distractor could accidentally spell (typo, scramble, missing letter or compound).
const realWords = {
  'BATTER', 'BETTER', 'BITTER', 'HANDLE', 'DONKEY', 'POCKET', 'SOCKET', 'LOCKET', 'MITTEN', 'BITTEN', 'PACKET', //
  'RACKET', 'MUZZLE', 'NUZZLE', 'GUZZLE', 'DRAIN', 'TRAIN', 'GRAIN', 'ALOUD', 'LIVER', 'DIVER', 'GIVER', 'FIVER',
  'SIMMER', 'SLIVER', 'LIVERS', 'MELON', 'SNOWBALL', 'SNOWFALL', 'FIREMAN', 'FIREFLY', 'FIREBALL', 'SUNLIGHT',
  'SUNFISH', 'RAINFALL', 'HANDBOOK', 'HANDBALL', 'CUPBOARD', 'STARLIGHT', 'FOOTFALL', 'SEAMAN',
};

String scramble(String w, Random r) {
  String s;
  do {
    s = (w.split('')..shuffle(r)).join();
  } while (s == w || realWords.contains(s));
  return s;
}

String swapAt(String w, int i) => w.substring(0, i) + w[i + 1] + w[i] + w.substring(i + 2);
Set<String> typos(String w) => {for (var i = 0; i < w.length - 1; i++) swapAt(w, i)}..remove(w)..removeAll(realWords);
List<String> nearLetters(int t) => [for (final j in [-2, -1, 1, 2]) if (t + j >= 0 && t + j < 26) abc[t + j]];
List<String> sample(Random r, List<String> l, int k) => (l.toList()..shuffle(r)).take(k).toList();

Gen counting(List<String> sym) => (r, d) {
      final s = [for (var i = 0; i < 8 + 4 * d; i++) one(r, sym)], t = one(r, sym);
      return n(s.join(' '), s.where((x) => x == t).length, r, ask: tr('How many $t ?', 'কয়টি $t ?'));
    };

// ---------- data ----------

const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
final primes = [for (var i = 2; i < 300; i++) if (isPrime(i)) i];
const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const dirs = ['North', 'East', 'South', 'West'];
const names = ['Ali', 'Sara', 'Rafi', 'Nila', 'Omar', 'Tina'];
const daysBn = ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'];
const monthsBn = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
const dirsBn = ['উত্তর', 'পূর্ব', 'দক্ষিণ', 'পশ্চিম'];
const namesBn = ['আলী', 'সারা', 'রাফি', 'নীলা', 'ওমর', 'টিনা'];
const words = [
  'PLANET', 'GARDEN', 'BRIDGE', 'CASTLE', 'ORANGE', 'PENCIL', 'ROCKET', 'SILVER', 'WINTER', 'JUNGLE', //
  'MARKET', 'DRAGON', 'FOREST', 'ISLAND', 'KITTEN', 'LEMON', 'MIRROR', 'PUZZLE', 'RABBIT', 'SUMMER',
  'TICKET', 'VALLEY', 'WINDOW', 'ANCHOR', 'BUTTER', 'CANDLE', 'DOCTOR', 'ENGINE', 'FLOWER', 'GUITAR',
  'HAMMER', 'INSECT', 'JACKET', 'LADDER', 'MONKEY', 'NATURE', 'OYSTER', 'PEPPER', 'QUEEN', 'RIVER',
  'SPIDER', 'TOMATO', 'UNCLE', 'VIOLIN', 'WALNUT', 'YELLOW', 'ZIPPER', 'BRAIN', 'CLOUD', 'OCEAN',
];
const antonyms = [
  ('HOT', 'COLD'), ('BIG', 'SMALL'), ('FAST', 'SLOW'), ('HAPPY', 'SAD'), ('LIGHT', 'DARK'), ('OPEN', 'CLOSED'),
  ('EARLY', 'LATE'), ('FULL', 'EMPTY'), ('HARD', 'EASY'), ('HIGH', 'LOW'), ('RICH', 'POOR'), ('STRONG', 'WEAK'),
  ('YOUNG', 'OLD'), ('WET', 'DRY'), ('LOUD', 'QUIET'), ('PUSH', 'PULL'), ('WIN', 'LOSE'), ('BUY', 'SELL'),
];
const synonyms = [
  ('BIG', 'LARGE'), ('SMALL', 'TINY'), ('HAPPY', 'GLAD'), ('FAST', 'QUICK'), ('SMART', 'CLEVER'), ('ANGRY', 'MAD'),
  ('BEGIN', 'START'), ('END', 'FINISH'), ('SHUT', 'CLOSE'), ('BRAVE', 'BOLD'), ('EASY', 'SIMPLE'), ('GIFT', 'PRESENT'),
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
/// Bangla names of the countries and capitals in [capitals].
const placesBn = {
  'Bangladesh': 'বাংলাদেশ', 'Dhaka': 'ঢাকা', 'India': 'ভারত', 'New Delhi': 'নয়াদিল্লি', 'Japan': 'জাপান', 'Tokyo': 'টোকিও', //
  'France': 'ফ্রান্স', 'Paris': 'প্যারিস', 'Germany': 'জার্মানি', 'Berlin': 'বার্লিন', 'Italy': 'ইতালি', 'Rome': 'রোম',
  'Spain': 'স্পেন', 'Madrid': 'মাদ্রিদ', 'Egypt': 'মিশর', 'Cairo': 'কায়রো', 'Canada': 'কানাডা', 'Ottawa': 'অটোয়া',
  'Australia': 'অস্ট্রেলিয়া', 'Canberra': 'ক্যানবেরা', 'Brazil': 'ব্রাজিল', 'Brasília': 'ব্রাসিলিয়া', 'China': 'চীন', 'Beijing': 'বেইজিং',
  'Russia': 'রাশিয়া', 'Moscow': 'মস্কো', 'Turkey': 'তুরস্ক', 'Ankara': 'আঙ্কারা', 'Kenya': 'কেনিয়া', 'Nairobi': 'নাইরোবি',
  'Nepal': 'নেপাল', 'Kathmandu': 'কাঠমান্ডু', 'Pakistan': 'পাকিস্তান', 'Islamabad': 'ইসলামাবাদ', 'Thailand': 'থাইল্যান্ড', 'Bangkok': 'ব্যাংকক',
  'Norway': 'নরওয়ে', 'Oslo': 'অসলো', 'Argentina': 'আর্জেন্টিনা', 'Buenos Aires': 'বুয়েনস আইরেস', 'South Korea': 'দক্ষিণ কোরিয়া', 'Seoul': 'সিউল',
  'Indonesia': 'ইন্দোনেশিয়া', 'Jakarta': 'জাকার্তা', 'Saudi Arabia': 'সৌদি আরব', 'Riyadh': 'রিয়াদ', 'United Kingdom': 'যুক্তরাজ্য', 'London': 'লন্ডন',
  'USA': 'যুক্তরাষ্ট্র', 'Washington D.C.': 'ওয়াশিংটন ডি.সি.',
};
String place(String s) => tr(s, placesBn[s]!);

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
const categoriesBn = {'fruit': 'ফল', 'animal': 'প্রাণী', 'color': 'রং', 'country': 'দেশ', 'vehicle': 'যানবাহন', 'instrument': 'বাদ্যযন্ত্র'};
const stroopBn = {'RED': 'লাল', 'BLUE': 'নীল', 'GREEN': 'সবুজ', 'YELLOW': 'হলুদ', 'PURPLE': 'বেগুনি', 'ORANGE': 'কমলা'};
String colorName(String k) => tr(k, stroopBn[k]!);
const unitsBn = {'hours': 'ঘণ্টা', 'minutes': 'মিনিট', 'seconds': 'সেকেন্ড', 'days': 'দিন', 'weeks': 'সপ্তাহ'};
const units = [('km', 'm', 1000), ('m', 'cm', 100), ('kg', 'g', 1000), ('hours', 'minutes', 60), ('minutes', 'seconds', 60), ('days', 'hours', 24), ('weeks', 'days', 7), ('L', 'mL', 1000)];

// ---------- games ----------

final quizGames = <Game>[
  // Math
  quiz('Addition', 'Math', bn: 'যোগ', (r, d) {
    final a = rn(r, 1, 10 * d * d), b = rn(r, 1, 10 * d * d);
    return n('$a + $b', a + b, r);
  }),
  quiz('Subtraction', 'Math', bn: 'বিয়োগ', (r, d) {
    final a = rn(r, 5, 10 * d * d + 5), b = rn(r, 1, a);
    return n('$a − $b', a - b, r);
  }),
  quiz('Multiplication', 'Math', bn: 'গুণ', (r, d) {
    final a = rn(r, 2, 3 + 3 * d), b = rn(r, 2, 9 + d);
    return n('$a × $b', a * b, r);
  }),
  quiz('Division', 'Math', bn: 'ভাগ', (r, d) {
    final b = rn(r, 2, 5 + 2 * d), q = rn(r, 2, 5 + 2 * d);
    return n('${b * q} ÷ $b', q, r);
  }),
  quiz('Mixed Operations', 'Math', bn: 'মিশ্র অঙ্ক', (r, d) {
    final a = rn(r, 2, 10 * d), b = rn(r, 2, 10 * d), c = b % 10 + 2;
    return switch (r.nextInt(4)) {
      0 => n('$a + $b', a + b, r),
      1 => n('${a + b} − $b', a, r),
      2 => n('$a × $c', a * c, r),
      _ => n('${a * c} ÷ $c', a, r),
    };
  }),
  quiz('Squares', 'Math', bn: 'বর্গ', (r, d) {
    final x = rn(r, 2, 5 + 5 * d);
    return n('$x²', x * x, r);
  }),
  quiz('Cubes', 'Math', bn: 'ঘন', (r, d) {
    final x = rn(r, 2, 3 + 2 * d);
    return n('$x³', x * x * x, r);
  }),
  quiz('Square Roots', 'Math', bn: 'বর্গমূল', (r, d) {
    final x = rn(r, 2, 5 + 5 * d);
    return n('√${x * x}', x, r);
  }),
  quiz('Powers of Two', 'Math', bn: '2-এর ঘাত', (r, d) {
    final e = rn(r, 1, 4 + 3 * d);
    return n('2^$e', 1 << e, r);
  }),
  quiz('Percentages', 'Math', bn: 'শতকরা', (r, d) {
    final p = one(r, [10, 20, 25, 50, 75]), x = rn(r, 1, 5 * d) * 20;
    return n(tr('$p% of $x', '$x-এর $p%'), p * x ~/ 100, r);
  }),
  quiz('Doubling', 'Math', bn: 'দ্বিগুণ', (r, d) {
    final x = rn(r, 10, 50 * d * d);
    return n(tr('Double $x', '$x-এর দ্বিগুণ'), 2 * x, r);
  }),
  quiz('Halving', 'Math', bn: 'অর্ধেক', (r, d) {
    final x = rn(r, 5, 50 * d * d) * 2;
    return n(tr('Half of $x', '$x-এর অর্ধেক'), x ~/ 2, r);
  }),
  quiz('Remainders', 'Math', bn: 'ভাগশেষ', (r, d) {
    final a = rn(r, 10, 30 * d), b = rn(r, 2, 3 + 2 * d);
    return n('$a ÷ $b', a % b, r, ask: tr('Remainder?', 'ভাগশেষ কত?'));
  }),
  quiz('Missing Addend', 'Math', bn: 'যোগের ফাঁকা ঘর', (r, d) {
    final a = rn(r, 1, 10 * d * d), b = rn(r, 1, 10 * d * d);
    return n('$a + ? = ${a + b}', b, r);
  }),
  quiz('Missing Factor', 'Math', bn: 'গুণের ফাঁকা ঘর', (r, d) {
    final a = rn(r, 2, 5 + d), b = rn(r, 2, 5 + 2 * d);
    return n('$a × ? = ${a * b}', b, r);
  }),
  quiz('Digit Sum', 'Math', bn: 'অঙ্কের যোগফল', (r, d) {
    final x = rn(r, 10, pow(10, d + 1).toInt() - 1);
    return n('$x', '$x'.split('').fold(0, (s, c) => s + int.parse(c)), r, ask: tr('Sum of digits?', 'অঙ্কগুলোর যোগফল?'));
  }),
  quiz('Times Eleven', 'Math', bn: '11 দিয়ে গুণ', (r, d) {
    final x = rn(r, 11, d < 3 ? 99 : 999);
    return n('$x × 11', x * 11, r);
  }),
  quiz('Times Five', 'Math', bn: '5 দিয়ে গুণ', (r, d) {
    final x = rn(r, 10, 50 * d);
    return n('$x × 5', x * 5, r);
  }),
  quiz('Order of Operations', 'Math', bn: 'সরল অঙ্ক', (r, d) {
    final a = rn(r, 2, 5 + 2 * d), b = rn(r, 2, 5 + 2 * d), c = rn(r, 2, 5 + 2 * d);
    return r.nextBool() ? n('$a + $b × $c', a + b * c, r) : n('$a × $b − $c', a * b - c, r);
  }),
  quiz('Triple Sum', 'Math', bn: 'তিন সংখ্যার যোগ', (r, d) {
    final a = rn(r, 1, 20 * d), b = rn(r, 1, 20 * d), c = rn(r, 1, 20 * d);
    return n('$a + $b + $c', a + b + c, r);
  }),
  quiz('Rounding', 'Math', bn: 'আসন্ন মান', (r, d) {
    final x = rn(r, 11, 100 * d * d);
    return n('$x', (x + 5) ~/ 10 * 10, r, ask: tr('Round to nearest 10', 'নিকটতম দশকে আসন্ন মান'));
  }),
  quiz('Greatest Common Divisor', 'Math', bn: 'গসাগু', (r, d) {
    final g = rn(r, 2, 3 + 2 * d), a = g * rn(r, 1, 6), b = g * rn(r, 1, 6);
    return n(tr('GCD($a, $b)', 'গসাগু($a, $b)'), a.gcd(b), r);
  }),
  quiz('Least Common Multiple', 'Math', bn: 'লসাগু', (r, d) {
    final a = rn(r, 2, 4 + 2 * d), b = rn(r, 2, 4 + 2 * d);
    return n(tr('LCM($a, $b)', 'লসাগু($a, $b)'), a * b ~/ a.gcd(b), r);
  }),
  quiz('Factorials', 'Math', bn: 'ফ্যাক্টোরিয়াল', (r, d) {
    final x = rn(r, 1, 3 + d);
    return n('$x!', List.generate(x, (i) => i + 1).fold(1, (a, b) => a * b), r);
  }),
  quiz('Negative Numbers', 'Math', bn: 'ঋণাত্মক সংখ্যা', (r, d) {
    final a = rn(r, -10 * d, 10 * d), b = rn(r, -10 * d, 10 * d);
    return n('$a + ($b)', a + b, r);
  }),
  quiz('Averages', 'Math', bn: 'গড়', (r, d) {
    final m = rn(r, 5, 20 * d), o = rn(r, 1, 5 * d), l = [m - o, m, m + o]..shuffle(r);
    return n(l.join(', '), m, r, ask: tr('Average?', 'গড় কত?'));
  }),
  quiz('Clock Hours', 'Math', bn: 'ঘড়ির ঘণ্টা', (r, d) {
    final h = rn(r, 1, 12), k = rn(r, 1, 6 * d);
    return choice(tr("$h o'clock + $k h", '$hটা + $k ঘণ্টা'), '${(h + k - 1) % 12 + 1}', [for (var i = 1; i <= 12; i++) '$i'], ask: tr('What hour will it be?', 'তখন কয়টা বাজবে?'));
  }),
  quiz('Making Change', 'Math', bn: 'ফেরত টাকা', (r, d) {
    final price = rn(r, 1, 99 * d), pay = (price ~/ 100 + 1) * 100;
    return n(tr('Pay $pay for $price', '$price-এর জন্য $pay দিলে'), pay - price, r, ask: tr('Change?', 'কত ফেরত?'));
  }),
  quiz('Speed × Time', 'Math', bn: 'গতি × সময়', (r, d) {
    final s = rn(r, 2, 12) * 5, t = rn(r, 1, 2 + d);
    return n(tr('$s km/h for $t h', '$s km/h বেগে $t ঘণ্টা'), s * t, r, ask: tr('Distance in km?', 'দূরত্ব কত km?'));
  }),
  quiz('Bigger Product', 'Math', bn: 'বড় গুণফল', (r, d) {
    int a, b, c, e;
    do {
      a = rn(r, 2, 5 + 3 * d);
      b = rn(r, 2, 5 + 3 * d);
      c = rn(r, 2, 5 + 3 * d);
      e = rn(r, 2, 5 + 3 * d);
    } while (a * b == c * e);
    final x = '$a × $b', y = '$c × $e';
    return Q(tr('Which is bigger?', 'কোনটি বড়?'), a * b > c * e ? x : y, [a * b > c * e ? y : x]);
  }),
  quiz('True or False', 'Math', bn: 'সত্য না মিথ্যা', (r, d) {
    final a = rn(r, 2, 5 + 2 * d), b = rn(r, 2, 5 + 2 * d), shown = r.nextBool() ? a * b : a * b + one(r, [-2, -1, 1, 2]);
    return tf('$a × $b = $shown', shown == a * b);
  }),
  quiz('Even or Odd', 'Math', bn: 'জোড় না বিজোড়', (r, d) {
    final x = rn(r, 100, pow(10, d + 2).toInt());
    return Q('$x', x.isEven ? tr('Even', 'জোড়') : tr('Odd', 'বিজোড়'), [tr('Even', 'জোড়'), tr('Odd', 'বিজোড়')], ask: tr('Even or odd?', 'জোড় না বিজোড়?'));
  }),
  quiz('Prime or Not', 'Math', bn: 'মৌলিক কি না', (r, d) {
    final x = r.nextBool() ? one(r, primes.where((p) => p < 20 * d * d).toList()) : rn(r, 4, 20 * d * d);
    return yn('$x', isPrime(x), ask: tr('Is it prime?', 'এটি কি মৌলিক সংখ্যা?'));
  }),
  quiz('Divisible by 3', 'Math', bn: '3 দিয়ে বিভাজ্য', (r, d) {
    final x = rn(r, 100, pow(10, d + 2).toInt());
    return yn('$x', x % 3 == 0, ask: tr('Divisible by 3?', '3 দিয়ে বিভাজ্য?'));
  }),
  quiz('Binary to Decimal', 'Math', bn: 'বাইনারি থেকে দশমিক', (r, d) {
    final x = rn(r, 1, 1 << (2 + d));
    return n(x.toRadixString(2), x, r, ask: tr('Binary → decimal', 'বাইনারি → দশমিক'));
  }),
  quiz('Decimal to Binary', 'Math', bn: 'দশমিক থেকে বাইনারি', (r, d) {
    final x = rn(r, 3, 1 << (2 + d));
    return Q('$x', x.toRadixString(2), [for (final k in [-2, -1, 1, 2, 3]) if (x + k > 0) (x + k).toRadixString(2)], ask: tr('Decimal → binary', 'দশমিক → বাইনারি'));
  }),
  quiz('Hex to Decimal', 'Math', bn: 'হেক্স থেকে দশমিক', (r, d) {
    final x = rn(r, 10, 16 * d * d);
    return n(x.toRadixString(16).toUpperCase(), x, r, ask: tr('Hex → decimal', 'হেক্স → দশমিক'));
  }),
  quiz('Roman to Number', 'Math', bn: 'রোমান থেকে সংখ্যা', (r, d) {
    final x = rn(r, 1, 50 * d);
    return n(roman(x), x, r, ask: tr('Roman → number', 'রোমান → সংখ্যা'));
  }),
  quiz('Number to Roman', 'Math', bn: 'সংখ্যা থেকে রোমান', (r, d) {
    final x = rn(r, 4, 50 * d);
    return Q('$x', roman(x), [for (final k in [-2, -1, 1, 2, 10]) roman(x + k)], ask: tr('Number → Roman', 'সংখ্যা → রোমান'));
  }),
  quiz('Compare Fractions', 'Math', bn: 'ভগ্নাংশের তুলনা', (r, d) {
    int a, b, c, e;
    do {
      b = rn(r, 2, 5 + d);
      e = rn(r, 2, 5 + d);
      a = rn(r, 1, b - 1);
      c = rn(r, 1, e - 1);
    } while (a * e == c * b);
    final x = '$a/$b', y = '$c/$e';
    return Q(tr('Which is bigger?', 'কোনটি বড়?'), a * e > c * b ? x : y, [a * e > c * b ? y : x]);
  }),
  quiz('Unit Conversion', 'Math', bn: 'একক রূপান্তর', (r, d) {
    final (f, t, k) = one(r, units);
    final x = rn(r, 1, 5 * d);
    return n('$x ${tr(f, unitsBn[f] ?? f)} = ? ${tr(t, unitsBn[t] ?? t)}', x * k, r);
  }),
  quiz('Weekday Jump', 'Math', bn: 'বারের হিসাব', (r, d) {
    final s = r.nextInt(7), k = rn(r, 1, 10 * d), ds = bangla.value ? daysBn : days;
    return choice(tr('${ds[s]} + $k days', '${ds[s]} + $k দিন'), ds[(s + k) % 7], ds, ask: tr('Which day?', 'কোন বার?'));
  }),
  quiz('Month Jump', 'Math', bn: 'মাসের হিসাব', (r, d) {
    final s = r.nextInt(12), k = rn(r, 1, 6 * d), ms = bangla.value ? monthsBn : months;
    return choice(tr('${ms[s]} + $k months', '${ms[s]} + $k মাস'), ms[(s + k) % 12], ms, ask: tr('Which month?', 'কোন মাস?'));
  }),
  quiz('Celsius to Fahrenheit', 'Math', bn: 'সেলসিয়াস থেকে ফারেনহাইট', (r, d) {
    final c = rn(r, -4, 8 * d) * 5;
    return n('$c°C', c * 9 ~/ 5 + 32, r, ask: tr('In °F?', '°F-এ কত?'));
  }),
  quiz('Coin Counting', 'Math', bn: 'কয়েন গোনা', (r, d) {
    final a = rn(r, 1, 2 + d), b = rn(r, 0, 2 + d), c = rn(r, 0, 2 + d), e = rn(r, 0, 2 + d);
    return n('$a×10 + $b×5 + $c×2 + $e×1', a * 10 + b * 5 + c * 2 + e, r, ask: tr('Total coin value?', 'কয়েনগুলোর মোট মান?'));
  }),
  quiz('Leap Year', 'Math', bn: 'অধিবর্ষ', (r, d) {
    final y = rn(r, 1800, 2400);
    return yn('$y', y % 4 == 0 && (y % 100 != 0 || y % 400 == 0), ask: tr('Leap year?', 'অধিবর্ষ?'));
  }),
  quiz('Dice Opposites', 'Math', bn: 'ছক্কার উল্টো পিঠ', (r, d) {
    final v = rn(r, 1, 6);
    return choice(tr('Opposite of $v', '$v-এর উল্টো পিঠে'), '${7 - v}', ['1', '2', '3', '4', '5', '6'], ask: tr('On a standard die', 'সাধারণ ছক্কায়'));
  }),
  quiz('Make 100', 'Math', bn: '100 বানাও', (r, d) {
    final t = d < 3 ? 100 : 1000, x = rn(r, 1, t - 1);
    return n('$x + ? = $t', t - x, r);
  }),
  quiz('Perimeter', 'Math', bn: 'পরিসীমা', (r, d) {
    final w = rn(r, 2, 5 + 5 * d), h = rn(r, 2, 5 + 5 * d);
    return n(tr('Rectangle $w × $h', 'আয়তক্ষেত্র $w × $h'), 2 * (w + h), r, ask: tr('Perimeter?', 'পরিসীমা কত?'));
  }),
  quiz('Area', 'Math', bn: 'ক্ষেত্রফল', (r, d) {
    final w = rn(r, 2, 5 + 3 * d), h = rn(r, 2, 5 + 3 * d);
    return n(tr('Rectangle $w × $h', 'আয়তক্ষেত্র $w × $h'), w * h, r, ask: tr('Area?', 'ক্ষেত্রফল কত?'));
  }),
  quiz('Triangle Angles', 'Math', bn: 'ত্রিভুজের কোণ', (r, d) {
    final a = rn(r, 20, 100), b = rn(r, 10, 170 - a);
    return n(tr('$a° and $b°', '$a° ও $b°'), 180 - a - b, r, ask: tr('Third angle of the triangle?', 'ত্রিভুজের তৃতীয় কোণ?'));
  }),

  // Logic
  quiz('Arithmetic Sequence', 'Logic', bn: 'সমান্তর ধারা', (r, d) {
    final a = rn(r, 1, 20 * d), s = rn(r, 1, 2 + 3 * d) * (r.nextBool() ? 1 : -1);
    return n('${[for (var i = 0; i < 4; i++) a + i * s].join(', ')}, ?', a + 4 * s, r);
  }),
  quiz('Geometric Sequence', 'Logic', bn: 'গুণোত্তর ধারা', (r, d) {
    final a = rn(r, 1, 3 + d), q = rn(r, 2, 2 + d), l = [a];
    while (l.length < 5) {
      l.add(l.last * q);
    }
    return n('${l.take(4).join(', ')}, ?', l[4], r);
  }),
  quiz('Fibonacci-like', 'Logic', bn: 'ফিবোনাচ্চি ধারা', (r, d) {
    final l = [rn(r, 1, 5 * d), rn(r, 1, 5 * d)];
    while (l.length < 6) {
      l.add(l[l.length - 1] + l[l.length - 2]);
    }
    return n('${l.take(5).join(', ')}, ?', l[5], r);
  }),
  quiz('Square Sequence', 'Logic', bn: 'বর্গের ধারা', (r, d) {
    final s = rn(r, 1, 5 * d);
    return n('${[for (var i = 0; i < 4; i++) (s + i) * (s + i)].join(', ')}, ?', (s + 4) * (s + 4), r);
  }),
  quiz('Alternating Sequence', 'Logic', bn: 'একান্তর ধারা', (r, d) {
    final p = rn(r, 2, 5 + 2 * d), m = rn(r, 1, p - 1), l = [rn(r, 10, 30 * d)];
    for (var i = 0; i < 5; i++) {
      l.add(l.last + (i.isEven ? p : -m));
    }
    return n('${l.take(5).join(', ')}, ?', l[5], r);
  }),
  quiz('Prime Sequence', 'Logic', bn: 'মৌলিক ধারা', (r, d) {
    final i = rn(r, 0, 8 * d);
    return n('${primes.sublist(i, i + 4).join(', ')}, ?', primes[i + 4], r);
  }),
  quiz('Letter Sequence', 'Logic', bn: 'অক্ষরের ধারা', (r, d) {
    final st = rn(r, 1, 1 + d), s = rn(r, 0, 25 - 4 * st);
    return Q('${[for (var k = 0; k < 4; k++) abc[s + k * st]].join(' ')} ?', abc[s + 4 * st], nearLetters(s + 4 * st));
  }),
  quiz('Not a Multiple', 'Logic', bn: 'গুণিতক নয়', (r, d) {
    final k = rn(r, 3, 4 + 2 * d), m = <String>{};
    while (m.length < 3) {
      m.add('${k * rn(r, 2, 12)}');
    }
    int x;
    do {
      x = rn(r, 10, 12 * k);
    } while (x % k == 0);
    return Q(tr('Not a multiple of $k?', '$k-এর গুণিতক নয় কোনটি?'), '$x', m);
  }),
  quiz('Odd Word Out', 'Logic', bn: 'বেমানান শব্দ', (r, d) {
    final cats = sample(r, categories.keys.toList(), 2);
    return Q(tr("Which doesn't belong?", 'কোনটি বেমানান?'), one(r, categories[cats[1]]!), sample(r, categories[cats[0]]!, 3));
  }),
  quiz('Number Rule', 'Logic', bn: 'সংখ্যার নিয়ম', (r, d) {
    final k = rn(r, 2, 9);
    final f = one(r, <int Function(int)>[(x) => x * k, (x) => x + k, (x) => x * x, (x) => x * k - 1, (x) => x * x + k]);
    // Three examples pin down every rule above (two can't: x*x+k vs x*k look alike).
    final xs = sample(r, [for (var i = 1; i <= 6 + 2 * d; i++) '$i'], 4).map(int.parse).toList();
    return n('${[for (final x in xs.take(3)) '$x → ${f(x)}'].join('\n')}\n${xs[3]} → ?', f(xs[3]), r);
  }),
  quiz('Proportions', 'Logic', bn: 'অনুপাত', (r, d) {
    final a = rn(r, 2, 5), p = rn(r, 2, 10 * d), b = rn(r, 2, 12);
    return n(tr('$a pens cost ${a * p}', '$aটি কলমের দাম ${a * p}'), b * p, r, ask: tr('How much do $b pens cost?', '$bটি কলমের দাম কত?'));
  }),
  quiz('Age Puzzle', 'Logic', bn: 'বয়সের ধাঁধা', (r, d) {
    final x = rn(r, 5, 30), y = rn(r, 1, 10 * d), z = rn(r, 1, 10);
    return n(tr('Tom is $x.\nAnn is $y years older.', 'টমের বয়স $x।\nঅ্যান $y বছরের বড়।'), x + y + z, r, ask: tr("Ann's age in $z years?", '$z বছর পর অ্যানের বয়স?'));
  }),
  quiz('Who Is Tallest', 'Logic', bn: 'কে সবচেয়ে লম্বা', (r, d) {
    final o = sample(r, bangla.value ? namesBn : names, min(2 + d, 5));
    final st = [for (var i = 0; i < o.length - 1; i++) tr('${o[i]} is taller than ${o[i + 1]}', '${o[i]} ${o[i + 1]}-এর চেয়ে লম্বা')]..shuffle(r);
    final tall = r.nextBool();
    return choice(st.join('\n'), tall ? o.first : o.last, o, ask: tall ? tr('Who is tallest?', 'সবচেয়ে লম্বা কে?') : tr('Who is shortest?', 'সবচেয়ে খাটো কে?'));
  }),
  quiz('Compass Turns', 'Logic', bn: 'কম্পাসের মোড়', (r, d) {
    final t = [for (var i = 0; i < d + 1; i++) r.nextBool()];
    final pos = t.fold(0, (s, right) => s + (right ? 1 : -1)) % 4;
    final turns = t.map((b) => b ? tr('right', 'ডানে') : tr('left', 'বামে')).join(', '), ds = bangla.value ? dirsBn : dirs;
    return choice(tr('Face North.\nTurn $turns.', 'উত্তর দিকে মুখ করুন।\nঘুরুন: $turns।'), ds[pos], ds, ask: tr('Which way now?', 'এখন কোন দিকে?'));
  }),

  // Focus
  quiz('Symbol Count', 'Focus', bn: 'চিহ্ন গোনা', counting(['★', '●', '▲', '■'])),
  quiz('Fruit Count', 'Focus', bn: 'ফল গোনা', counting(['🍎', '🍌', '🍇', '🍒', '🍋'])),
  quiz('Find the Odd Symbol', 'Focus', bn: 'আলাদা চিহ্ন খোঁজো', (r, d) {
    final p = one(r, [('O', 'Q'), ('b', 'd'), ('E', 'F'), ('8', 'B'), ('M', 'N'), ('p', 'q'), ('6', '9')]);
    final s = List.filled(6 + 3 * d, p.$1), pos = r.nextInt(s.length);
    s[pos] = p.$2;
    return n(s.join(' '), pos + 1, r, ask: tr('Position of the odd one?', 'আলাদাটি কত নম্বরে?'));
  }),
  quiz('Stroop: Ink Color', 'Focus', bn: 'স্ট্রুপ: কালির রং', (r, d) {
    final c = stroop.keys.toList(), w = one(r, c);
    final ink = one(r, c.where((x) => x != w).toList());
    return Q(colorName(w), colorName(ink), c.map(colorName), ask: tr('Tap the INK color', 'কালির রং কোনটি?'), color: stroop[ink]);
  }),
  quiz('Stroop: Word', 'Focus', bn: 'স্ট্রুপ: শব্দ', (r, d) {
    final c = stroop.keys.toList(), w = one(r, c);
    final ink = one(r, c.where((x) => x != w).toList());
    return Q(colorName(w), colorName(w), c.map(colorName), ask: tr('What does the word SAY?', 'শব্দে কী লেখা?'), color: stroop[ink]);
  }),

  // Word
  quiz('Anagrams', 'Word', bn: 'অ্যানাগ্রাম', (r, d) {
    final w = one(r, words);
    return choice(scramble(w, r), w, words.where((x) => x.length == w.length), ask: tr('Unscramble', 'অক্ষর সাজিয়ে শব্দ বানান'));
  }),
  quiz('Missing Letter', 'Word', bn: 'হারানো অক্ষর', (r, d) {
    final w = one(r, words), i = r.nextInt(w.length);
    return Q(w.replaceRange(i, i + 1, '_'), w[i], abc.split('').where((c) => !realWords.contains(w.replaceRange(i, i + 1, c))), ask: tr('Fill the blank', 'খালি ঘর পূরণ করুন'));
  }),
  quiz('Reverse Word', 'Word', bn: 'উল্টো শব্দ', (r, d) {
    final w = one(r, words), rev = w.split('').reversed.join();
    return Q(w, rev, typos(rev), ask: tr('Spell it backwards', 'উল্টো করে বানান'));
  }),
  quiz('Vowel Count', 'Word', bn: 'স্বরবর্ণ গোনা', (r, d) {
    final w = one(r, words);
    return n(w, w.split('').where('AEIOU'.contains).length, r, ask: tr('How many vowels?', 'কয়টি স্বরবর্ণ (vowel)?'));
  }),
  quiz('Letter Count', 'Word', bn: 'অক্ষর গোনা', (r, d) {
    final w = one(r, words), ch = w[r.nextInt(w.length)];
    return n(w, ch.allMatches(w).length, r, ask: tr('How many "$ch"?', '"$ch" কয়টি?'));
  }),
  quiz('Alphabet Position', 'Word', bn: 'বর্ণমালায় অবস্থান', (r, d) {
    final i = r.nextInt(26);
    return n(abc[i], i + 1, r, ask: tr('Position in the alphabet?', 'বর্ণমালায় কত নম্বর?'));
  }),
  quiz('Letter After', 'Word', bn: 'পরের অক্ষর', (r, d) {
    final k = rn(r, 1, 2 + d), i = rn(r, 0, 25 - k);
    return Q('${abc[i]} + $k', abc[i + k], nearLetters(i + k), ask: tr('Which letter?', 'কোন অক্ষর?'));
  }),
  quiz('Letter Before', 'Word', bn: 'আগের অক্ষর', (r, d) {
    final k = rn(r, 1, 2 + d), i = rn(r, k, 25);
    return Q('${abc[i]} − $k', abc[i - k], nearLetters(i - k), ask: tr('Which letter?', 'কোন অক্ষর?'));
  }),
  quiz('First in A–Z', 'Word', bn: 'A–Z-এ প্রথম', (r, d) {
    final ws = sample(r, words, 4);
    return Q(tr('First alphabetically?', 'বর্ণানুক্রমে প্রথম?'), (ws.toList()..sort()).first, ws);
  }),
  quiz('Last in A–Z', 'Word', bn: 'A–Z-এ শেষ', (r, d) {
    final ws = sample(r, words, 4);
    return Q(tr('Last alphabetically?', 'বর্ণানুক্রমে শেষ?'), (ws.toList()..sort()).last, ws);
  }),
  quiz('Longest Word', 'Word', bn: 'সবচেয়ে লম্বা শব্দ', (r, d) {
    List<String> ws;
    do {
      ws = sample(r, words, 4)..sort((a, b) => b.length - a.length);
    } while (ws[0].length == ws[1].length);
    return Q(tr('Longest word?', 'সবচেয়ে লম্বা শব্দ?'), ws[0], ws);
  }),
  quiz('Opposites', 'Word', bn: 'বিপরীত শব্দ', (r, d) {
    final (a, b) = one(r, antonyms);
    return r.nextBool()
        ? choice(a, b, antonyms.map((e) => e.$2), ask: tr('Opposite of', 'বিপরীত শব্দ'))
        : choice(b, a, antonyms.map((e) => e.$1), ask: tr('Opposite of', 'বিপরীত শব্দ'));
  }),
  quiz('Synonyms', 'Word', bn: 'সমার্থক শব্দ', (r, d) {
    final (a, b) = one(r, synonyms);
    return choice(a, b, synonyms.map((e) => e.$2), ask: tr('Same meaning as', 'সমার্থক শব্দ'));
  }),
  quiz('Spell Check', 'Word', bn: 'বানান যাচাই', (r, d) {
    final w = one(r, words);
    return Q(tr('Correct spelling?', 'সঠিক বানান কোনটি?'), w, typos(w));
  }),
  quiz('Word Categories', 'Word', bn: 'শব্দের শ্রেণি', (r, d) {
    final cats = sample(r, categories.keys.toList(), 4);
    return Q(tr('Pick the ${cats[0]}', '${categoriesBn[cats[0]]} কোনটি?'), one(r, categories[cats[0]]!), [for (final c in cats.skip(1)) one(r, categories[c]!)]);
  }),
  quiz('Capital Cities', 'Word', bn: 'রাজধানী', (r, d) {
    final (c, cap) = one(r, capitals);
    return choice(place(c), place(cap), capitals.map((e) => place(e.$2)), ask: tr('Capital city?', 'রাজধানী কোনটি?'));
  }),
  quiz('Compound Words', 'Word', bn: 'যুক্ত শব্দ', (r, d) {
    final (a, b) = one(r, compounds);
    return choice('$a + ?', b, compounds.map((e) => e.$2).where((x) => !realWords.contains(a + x)), ask: tr('Make a word', 'শব্দ বানান'));
  }),
  quiz('Starts With', 'Word', bn: 'শুরুর অক্ষর', (r, d) {
    final w = one(r, words);
    return Q(w[0], w, words.where((x) => x[0] != w[0]), ask: tr('Which word starts with', 'কোন শব্দ শুরু হয়'));
  }),
];
