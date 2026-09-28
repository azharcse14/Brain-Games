import 'dart:math';

import 'games.dart';
import 'quiz.dart';

Game q2(String name, String cat, String glyph, Gen gen) => Game(name, cat, () => QuizScreen(name, gen), glyph: glyph);

// ---------- data (fixed facts only) ----------

const flags = [
  ('🇧🇩', 'Bangladesh'), ('🇮🇳', 'India'), ('🇯🇵', 'Japan'), ('🇫🇷', 'France'), ('🇩🇪', 'Germany'), ('🇮🇹', 'Italy'), //
  ('🇪🇸', 'Spain'), ('🇧🇷', 'Brazil'), ('🇨🇦', 'Canada'), ('🇨🇳', 'China'), ('🇬🇧', 'United Kingdom'), ('🇺🇸', 'USA'),
  ('🇰🇷', 'South Korea'), ('🇹🇷', 'Turkey'), ('🇸🇦', 'Saudi Arabia'), ('🇵🇰', 'Pakistan'), ('🇳🇵', 'Nepal'), ('🇦🇺', 'Australia'),
  ('🇲🇽', 'Mexico'), ('🇦🇷', 'Argentina'), ('🇪🇬', 'Egypt'), ('🇳🇬', 'Nigeria'), ('🇸🇪', 'Sweden'), ('🇬🇷', 'Greece'),
];
const continentNames = ['Asia', 'Africa', 'Europe', 'North America', 'South America', 'Oceania'];
const continentOf = {
  'Japan': 'Asia', 'Nepal': 'Asia', 'Bangladesh': 'Asia', 'India': 'Asia', 'Thailand': 'Asia', 'Vietnam': 'Asia', //
  'Kenya': 'Africa', 'Nigeria': 'Africa', 'Egypt': 'Africa', 'Ghana': 'Africa', 'Morocco': 'Africa',
  'France': 'Europe', 'Germany': 'Europe', 'Italy': 'Europe', 'Norway': 'Europe', 'Poland': 'Europe',
  'Canada': 'North America', 'Mexico': 'North America', 'USA': 'North America', 'Cuba': 'North America',
  'Brazil': 'South America', 'Argentina': 'South America', 'Peru': 'South America', 'Chile': 'South America',
  'Australia': 'Oceania', 'New Zealand': 'Oceania', 'Fiji': 'Oceania',
};
const planetNames = ['Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune'];
const planetFacts = [
  ('Largest planet', 'Jupiter'), ('Smallest planet', 'Mercury'), ('Closest to the Sun', 'Mercury'),
  ('Farthest from the Sun', 'Neptune'), ('The Red Planet', 'Mars'), ('Hottest planet', 'Venus'), ('Our home planet', 'Earth'),
];
const elements = [
  ('Hydrogen', 'H'), ('Helium', 'He'), ('Lithium', 'Li'), ('Beryllium', 'Be'), ('Boron', 'B'), ('Carbon', 'C'), //
  ('Nitrogen', 'N'), ('Oxygen', 'O'), ('Fluorine', 'F'), ('Neon', 'Ne'), ('Sodium', 'Na'), ('Magnesium', 'Mg'),
  ('Aluminium', 'Al'), ('Silicon', 'Si'), ('Phosphorus', 'P'), ('Sulfur', 'S'), ('Chlorine', 'Cl'), ('Argon', 'Ar'),
  ('Potassium', 'K'), ('Calcium', 'Ca'), ('Titanium', 'Ti'), ('Chromium', 'Cr'), ('Manganese', 'Mn'), ('Iron', 'Fe'),
  ('Cobalt', 'Co'), ('Nickel', 'Ni'), ('Copper', 'Cu'), ('Zinc', 'Zn'), ('Silver', 'Ag'), ('Gold', 'Au'), ('Tin', 'Sn'),
  ('Lead', 'Pb'), ('Mercury', 'Hg'),
];

/// (animal, main collective noun, every noun that is also correct for it).
const animalGroups = [
  ('lions', 'pride', {'pride'}), ('wolves', 'pack', {'pack'}), ('fish', 'school', {'school'}),
  ('crows', 'murder', {'murder', 'flock'}), ('owls', 'parliament', {'parliament'}), ('whales', 'pod', {'pod', 'school'}),
  ('sheep', 'flock', {'flock', 'herd'}), ('geese', 'gaggle', {'gaggle', 'flock'}), ('cows', 'herd', {'herd'}),
  ('ants', 'colony', {'colony'}), ('bees', 'swarm', {'swarm', 'colony'}),
];
const babyAnimals = [
  ('Kangaroo', 'Joey'), ('Cat', 'Kitten'), ('Dog', 'Puppy'), ('Cow', 'Calf'), ('Horse', 'Foal'), ('Sheep', 'Lamb'),
  ('Goat', 'Kid'), ('Frog', 'Tadpole'), ('Swan', 'Cygnet'), ('Goose', 'Gosling'), ('Lion', 'Cub'), ('Bear', 'Cub'),
  ('Deer', 'Fawn'), ('Pig', 'Piglet'), ('Duck', 'Duckling'), ('Owl', 'Owlet'), ('Eagle', 'Eaglet'),
];
const polygons = [
  ('Triangle', 3), ('Quadrilateral', 4), ('Pentagon', 5), ('Hexagon', 6), ('Heptagon', 7), ('Octagon', 8),
  ('Nonagon', 9), ('Decagon', 10), ('Dodecagon', 12),
];
const metricPrefixes = [
  ('kilo', '1,000'), ('hecto', '100'), ('deca', '10'), ('deci', '0.1'), ('centi', '0.01'), ('milli', '0.001'),
  ('mega', '1,000,000'), ('micro', '0.000001'), ('giga', '1,000,000,000'),
];
const bodyFacts = [
  ('Largest organ of the human body', 'Skin', ['Liver', 'Heart', 'Brain']),
  ('Pumps blood around the body', 'Heart', ['Lungs', 'Liver', 'Stomach']),
  ('Bones in an adult human', '206', ['186', '212', '250']),
  ('Longest bone in the body', 'Femur', ['Tibia', 'Humerus', 'Radius']),
  ('Smallest bone (in the ear)', 'Stapes', ['Femur', 'Patella', 'Ulna']),
  ('Chambers in the human heart', '4', ['2', '3', '6']),
  ('Teeth in a full adult set', '32', ['28', '30', '36']),
  ('Where oxygen enters the blood', 'Lungs', ['Heart', 'Kidneys', 'Stomach']),
  ('The kneecap bone', 'Patella', ['Femur', 'Tibia', 'Scapula']),
  ('Protects the brain', 'Skull', ['Ribs', 'Pelvis', 'Kneecap']),
  ('Blood cells that fight infection', 'White blood cells', ['Red blood cells', 'Platelets', 'Plasma']),
];
const earthFacts = [
  ('Largest ocean', 'Pacific', ['Atlantic', 'Indian', 'Arctic']),
  ('Smallest ocean', 'Arctic', ['Pacific', 'Atlantic', 'Indian']),
  ('Largest continent', 'Asia', ['Africa', 'Europe', 'North America']),
  ('Smallest continent', 'Australia', ['Europe', 'Antarctica', 'South America']),
  ('Coldest continent', 'Antarctica', ['Europe', 'Asia', 'North America']),
  ('Highest mountain', 'Mount Everest', ['K2', 'Kilimanjaro', 'Mont Blanc']),
  ('Largest hot desert', 'Sahara', ['Gobi', 'Kalahari', 'Atacama']),
  ('Ocean between Europe and North America', 'Atlantic', ['Pacific', 'Indian', 'Arctic']),
  ('Ocean between Africa and Australia', 'Indian', ['Pacific', 'Atlantic', 'Arctic']),
];
const decimalFractions = [
  ('0.5', '1/2'), ('0.25', '1/4'), ('0.75', '3/4'), ('0.2', '1/5'), ('0.4', '2/5'), ('0.6', '3/5'), ('0.8', '4/5'),
  ('0.125', '1/8'), ('0.375', '3/8'), ('0.1', '1/10'), ('0.3', '3/10'), ('0.05', '1/20'),
];
const monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
const rhymeFamilies = [
  ['CAT', 'HAT', 'BAT', 'MAT', 'RAT'], ['LIGHT', 'NIGHT', 'FIGHT', 'RIGHT', 'SIGHT'], ['CAKE', 'LAKE', 'MAKE', 'BAKE', 'SNAKE'],
  ['MOON', 'SPOON', 'NOON', 'SOON', 'BALLOON'], ['KING', 'RING', 'SING', 'WING', 'SPRING'], ['CLOCK', 'SOCK', 'ROCK', 'LOCK', 'BLOCK'],
  ['TREE', 'BEE', 'SEE', 'FREE', 'KNEE'], ['RAIN', 'TRAIN', 'BRAIN', 'CHAIN', 'PLAIN'], ['DOG', 'FROG', 'LOG', 'FOG', 'JOG'],
  ['SUN', 'RUN', 'FUN', 'BUN', 'SPUN'],
];

/// (singular, plural, wrong plurals).
const plurals = [
  ('CHILD', 'CHILDREN', ['CHILDS', 'CHILDES', 'CHILDRENS']), ('MOUSE', 'MICE', ['MOUSES', 'MICES', 'MEESE']),
  ('GOOSE', 'GEESE', ['GOOSES', 'GEESES', 'GOOSEN']), ('TOOTH', 'TEETH', ['TOOTHS', 'TEETHS', 'TOOTHES']),
  ('FOOT', 'FEET', ['FOOTS', 'FEETS', 'FOOTES']), ('MAN', 'MEN', ['MANS', 'MANNS', 'MENS']),
  ('WOMAN', 'WOMEN', ['WOMANS', 'WOMENS', 'WOMANES']), ('OX', 'OXEN', ['OXES', 'OXS', 'OXENS']),
  ('LEAF', 'LEAVES', ['LEAFES', 'LEAVS', 'LEAVESS']), ('KNIFE', 'KNIVES', ['KNIFS', 'KNIVS', 'KNIFFS']),
  ('WOLF', 'WOLVES', ['WOLFS', 'WOLFES', 'WOLVS']), ('SHEEP', 'SHEEP', ['SHEEPS', 'SHEEPES', 'SHOOP']),
  ('DEER', 'DEER', ['DEERS', 'DEERES', 'DEERE']), ('BABY', 'BABIES', ['BABYS', 'BABYES', 'BABIS']),
  ('CITY', 'CITIES', ['CITYS', 'CITYES', 'CITIS']), ('BOX', 'BOXES', ['BOXS', 'BOXEN', 'BOXIES']),
  ('BUS', 'BUSES', ['BUSS', 'BUSIS', 'BUSEN']), ('HERO', 'HEROES', ['HEROIES', 'HEROSES', 'HEROEN']),
  ('POTATO', 'POTATOES', ['POTATOS', 'POTATOIES', 'POTATOSES']),
];
const homophones = [
  ('SEA', 'SEE'), ('KNIGHT', 'NIGHT'), ('FLOWER', 'FLOUR'), ('MAIL', 'MALE'), ('PAIR', 'PEAR'), ('SON', 'SUN'),
  ('WRITE', 'RIGHT'), ('BEAR', 'BARE'), ('HOUR', 'OUR'), ('WEEK', 'WEAK'), ('TAIL', 'TALE'), ('BLUE', 'BLEW'),
  ('ROSE', 'ROWS'), ('PLANE', 'PLAIN'), ('EIGHT', 'ATE'), ('MEET', 'MEAT'), ('ROAD', 'RODE'), ('HEAR', 'HERE'),
];
const ladderWords = [
  'CAT', 'BAT', 'HAT', 'COT', 'CUT', 'CAR', 'BAR', 'BAG', 'BIG', 'DIG', 'DOG', 'DOT', 'HOT', 'HIT', 'SIT', 'SAT', //
  'MAT', 'MAP', 'CAP', 'TAP', 'TIP', 'TOP', 'MOP', 'HOP', 'PIG', 'PIN', 'PAN', 'FAN', 'FUN', 'SUN',
];
const arrowSymbols = ['⬆', '⬇', '⬅', '➡'];
const mirrorSame = 'AHIMOTUVWXY', mirrorDifferent = 'BCDEFGJKLNPQRSZ';

int letterDiff(String a, String b) => [for (var i = 0; i < a.length; i++) if (a[i] != b[i]) i].length;

// ---------- games ----------

final quizGames2 = <Game>[
  // Knowledge
  q2('Country Flags', 'Knowledge', '🚩', (r, d) {
    final (f, c) = one(r, flags);
    return choice(f, c, flags.map((e) => e.$2), ask: 'Which country?');
  }),
  q2('Capital to Country', 'Knowledge', '🏙️', (r, d) {
    final (c, cap) = one(r, capitals);
    return choice(cap, c, capitals.map((e) => e.$1), ask: 'Capital of which country?');
  }),
  q2('Continents', 'Knowledge', '🌍', (r, d) {
    final c = one(r, continentOf.keys.toList());
    return choice(c, continentOf[c]!, continentNames, ask: 'Which continent?');
  }),
  q2('Planets', 'Knowledge', '🪐', (r, d) {
    if (r.nextBool()) {
      final i = r.nextInt(8);
      return choice('Planet #${i + 1} from the Sun', planetNames[i], planetNames);
    }
    final (q, a) = one(r, planetFacts);
    return choice(q, a, planetNames);
  }),
  q2('Chemical Symbols', 'Knowledge', '⚗️', (r, d) {
    final (name, sym) = one(r, elements);
    return choice(name, sym, elements.map((e) => e.$2), ask: 'Chemical symbol?');
  }),
  q2('Symbol to Element', 'Knowledge', '🧪', (r, d) {
    final (name, sym) = one(r, elements);
    return choice(sym, name, elements.map((e) => e.$1), ask: 'Which element?');
  }),
  q2('Animal Groups', 'Knowledge', '🦁', (r, d) {
    final (animal, group, ok) = one(r, animalGroups);
    return choice('A group of $animal', group, animalGroups.map((e) => e.$2).where((x) => !ok.contains(x)), ask: 'Collective noun?');
  }),
  q2('Baby Animals', 'Knowledge', '🐣', (r, d) {
    final (animal, baby) = one(r, babyAnimals);
    return choice(animal, baby, babyAnimals.map((e) => e.$2), ask: 'Its baby is called');
  }),
  q2('Polygon Sides', 'Knowledge', '🔷', (r, d) {
    final (name, sides) = one(r, polygons);
    return r.nextBool()
        ? choice(name, '$sides', polygons.map((e) => '${e.$2}'), ask: 'How many sides?')
        : choice('$sides sides', name, polygons.map((e) => e.$1), ask: 'Which shape?');
  }),
  q2('Metric Prefixes', 'Knowledge', 'k·m', (r, d) {
    final (p, v) = one(r, metricPrefixes);
    return choice(p, v, metricPrefixes.map((e) => e.$2), ask: 'This prefix means ×');
  }),
  q2('Human Body', 'Knowledge', '🫀', (r, d) {
    final (q, a, w) = one(r, bodyFacts);
    return Q(q, a, w);
  }),
  q2('Oceans & Continents', 'Knowledge', '🌊', (r, d) {
    final (q, a, w) = one(r, earthFacts);
    return Q(q, a, w);
  }),

  // Math
  q2('Fraction of Number', 'Math', '¾×', (r, d) {
    final b = rn(r, 2, 4 + d), a = rn(r, 1, b - 1), x = b * rn(r, 2, 5 * d);
    return n('$a/$b of $x', a * x ~/ b, r);
  }),
  q2('Decimal to Fraction', 'Math', '0.5', (r, d) {
    final (dec, frac) = one(r, decimalFractions);
    return choice(dec, frac, decimalFractions.map((e) => e.$2), ask: 'As a fraction');
  }),
  q2('Simple Interest', 'Math', '💰', (r, d) {
    final p = rn(r, 1, 10 * d) * 100, rate = rn(r, 1, 10), t = rn(r, 1, 5);
    return n('$p at $rate% for $t years', p * rate * t ~/ 100, r, ask: 'Simple interest?');
  }),
  q2('Ratio Split', 'Math', '1:2', (r, d) {
    final a = rn(r, 1, 5), b = rn(r, 1, 5), k = rn(r, 2, 5 * d);
    return n('Split ${(a + b) * k} in $a:$b', a * k, r, ask: 'First share?');
  }),
  q2('Next Prime', 'Math', '→7', (r, d) {
    final x = rn(r, 2, 20 * d * d);
    var p = x + 1;
    while (!isPrime(p)) {
      p++;
    }
    return n('$x', p, r, ask: 'Next prime after');
  }),
  q2('Time Difference', 'Math', '⌚', (r, d) {
    final s = rn(r, 0, 16 * 12) * 5, dur = rn(r, 1, 12 * (1 + d)) * 5;
    String hm(int m) => '${'${m ~/ 60}'.padLeft(2, '0')}:${'${m % 60}'.padLeft(2, '0')}';
    String len(int m) => '${m ~/ 60}h ${m % 60}m';
    return Q('${hm(s)} → ${hm(s + dur)}', len(dur), [for (final k in [-60, -10, -5, 5, 10, 60]) if (dur + k > 0) len(dur + k)], ask: 'How long?');
  }),
  q2('Clock Angle', 'Math', '∠', (r, d) {
    final h = rn(r, 1, 12), m = d == 1 ? 0 : rn(r, 0, 5) * 10;
    final a = (30 * (h % 12) - 5.5 * m).abs().round();
    return n('$h:${'$m'.padLeft(2, '0')}', min(a, 360 - a), r, ask: 'Angle between the clock hands (°)?');
  }),
  q2('Day of the Year', 'Math', '📆', (r, d) {
    final mi = r.nextInt(12), day = rn(r, 1, monthDays[mi]);
    return n('${months[mi]} $day', monthDays.take(mi).fold(0, (s, x) => s + x) + day, r, ask: 'Day number in a non-leap year?');
  }),

  // Logic
  q2('Magic Square', 'Logic', '🔮', (r, d) {
    var g = [8, 1, 6, 3, 5, 7, 4, 9, 2];
    for (var k = r.nextInt(4); k > 0; k--) {
      g = [for (var i = 0; i < 9; i++) g[(2 - i % 3) * 3 + i ~/ 3]]; // rotate 90°
    }
    if (r.nextBool()) g = [for (var i = 0; i < 9; i++) g[i ~/ 3 * 3 + 2 - i % 3]]; // mirror
    final m = rn(r, 1, d), add = rn(r, 0, 5 * d), hide = r.nextInt(9);
    g = [for (final x in g) x * m + add];
    final rows = [for (var row = 0; row < 3; row++) [for (var c = 0; c < 3; c++) row * 3 + c == hide ? '?' : '${g[row * 3 + c]}'].join('   ')];
    return n(rows.join('\n'), g[hide], r, ask: 'Rows, columns and diagonals all add up the same. Missing?');
  }),
  q2('Number Pyramid', 'Logic', '🔺', (r, d) {
    final rows = [
      [for (var i = 0; i < (d < 3 ? 3 : 4); i++) rn(r, 1, 5 * d)],
    ];
    while (rows.last.length > 1) {
      rows.add([for (var i = 0; i + 1 < rows.last.length; i++) rows.last[i] + rows.last[i + 1]]);
    }
    return n([for (final row in rows.reversed) row.length == 1 ? '?' : row.join('  ')].join('\n'), rows.last.first, r,
        ask: 'Each block is the sum of the two below it. Top?');
  }),
  q2('Code Breaker', 'Logic', '🔐', (r, d) {
    final w = one(r, words);
    return n(w, w.codeUnits.fold(0, (s, c) => s + c - 64), r, ask: 'A=1, B=2 … Z=26. Word total?');
  }),
  q2('Balance Scale', 'Logic', '🧮', (r, d) {
    final a = rn(r, 2, 2 + d), b = rn(r, 2, 2 + d);
    return n('1 🍉 = $b 🍌\n1 🍌 = $a 🍎', a * b, r, ask: 'How many 🍎 balance 1 🍉?');
  }),

  // Word
  q2('Rhyme Time', 'Word', '🎵', (r, d) {
    final f = one(r, rhymeFamilies), w = one(r, f);
    return Q(w, one(r, f.where((x) => x != w).toList()), [for (final g in rhymeFamilies) if (g != f) ...g], ask: 'Which word rhymes with');
  }),
  q2('Plurals', 'Word', '📚', (r, d) {
    final (s, p, w) = one(r, plurals);
    return Q(s, p, w, ask: 'Plural of');
  }),
  q2('Homophones', 'Word', '👂', (r, d) {
    final (a, b) = one(r, homophones);
    final all = [for (final (x, y) in homophones) ...[x, y]];
    return r.nextBool()
        ? Q(a, b, all.where((x) => x != a && x != b), ask: 'Sounds the same as')
        : Q(b, a, all.where((x) => x != a && x != b), ask: 'Sounds the same as');
  }),
  q2('Word Ladder', 'Word', '🪜', (r, d) {
    final w = one(r, ladderWords);
    final near = ladderWords.where((x) => letterDiff(w, x) == 1).toList();
    return Q(w, one(r, near), ladderWords.where((x) => letterDiff(w, x) >= 2), ask: 'Change ONE letter of');
  }),

  // Focus
  q2('Most Common Arrow', 'Focus', '⬆⬇', (r, d) {
    List<String> s;
    List<int> counts;
    do {
      s = [for (var i = 0; i < 8 + 4 * d; i++) one(r, arrowSymbols)];
      counts = [for (final a in arrowSymbols) s.where((x) => x == a).length];
    } while (counts.where((c) => c == counts.reduce(max)).length > 1);
    return choice(s.join(' '), arrowSymbols[counts.indexOf(counts.reduce(max))], arrowSymbols, ask: 'Which arrow appears most?');
  }),
  q2('Mirror Letters', 'Focus', '🪞', (r, d) {
    return Q('Looks the same in a mirror?', mirrorSame[r.nextInt(mirrorSame.length)], mirrorDifferent.split(''));
  }),
];
