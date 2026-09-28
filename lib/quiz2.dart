import 'dart:math';

import 'games.dart';
import 'quiz.dart';

Game q2(String name, String cat, String glyph, Gen gen, {String? bn}) => Game(name, cat, () => QuizScreen(name, gen), glyph: glyph, bn: bn);

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

/// Bangla for the fact data above; the data stays English so tests and scores don't depend on the language.
const _bn = {
  // countries
  'Bangladesh': 'বাংলাদেশ', 'India': 'ভারত', 'Japan': 'জাপান', 'France': 'ফ্রান্স', 'Germany': 'জার্মানি', 'Italy': 'ইতালি',
  'Spain': 'স্পেন', 'Brazil': 'ব্রাজিল', 'Canada': 'কানাডা', 'China': 'চীন', 'United Kingdom': 'যুক্তরাজ্য', 'USA': 'যুক্তরাষ্ট্র',
  'South Korea': 'দক্ষিণ কোরিয়া', 'Turkey': 'তুরস্ক', 'Saudi Arabia': 'সৌদি আরব', 'Pakistan': 'পাকিস্তান', 'Nepal': 'নেপাল',
  'Australia': 'অস্ট্রেলিয়া', 'Mexico': 'মেক্সিকো', 'Argentina': 'আর্জেন্টিনা', 'Egypt': 'মিশর', 'Nigeria': 'নাইজেরিয়া',
  'Sweden': 'সুইডেন', 'Greece': 'গ্রিস', 'Thailand': 'থাইল্যান্ড', 'Vietnam': 'ভিয়েতনাম', 'Kenya': 'কেনিয়া', 'Ghana': 'ঘানা',
  'Morocco': 'মরক্কো', 'Norway': 'নরওয়ে', 'Poland': 'পোল্যান্ড', 'Cuba': 'কিউবা', 'Peru': 'পেরু', 'Chile': 'চিলি',
  'New Zealand': 'নিউজিল্যান্ড', 'Fiji': 'ফিজি', 'Russia': 'রাশিয়া', 'Indonesia': 'ইন্দোনেশিয়া',
  // capitals
  'Dhaka': 'ঢাকা', 'New Delhi': 'নয়াদিল্লি', 'Tokyo': 'টোকিও', 'Paris': 'প্যারিস', 'Berlin': 'বার্লিন', 'Rome': 'রোম',
  'Madrid': 'মাদ্রিদ', 'Cairo': 'কায়রো', 'Ottawa': 'অটোয়া', 'Canberra': 'ক্যানবেরা', 'Brasília': 'ব্রাসিলিয়া', 'Beijing': 'বেইজিং',
  'Moscow': 'মস্কো', 'Ankara': 'আঙ্কারা', 'Nairobi': 'নাইরোবি', 'Kathmandu': 'কাঠমান্ডু', 'Islamabad': 'ইসলামাবাদ',
  'Bangkok': 'ব্যাংকক', 'Oslo': 'অসলো', 'Buenos Aires': 'বুয়েনোস আইরেস', 'Seoul': 'সিউল', 'Jakarta': 'জাকার্তা',
  'Riyadh': 'রিয়াদ', 'London': 'লন্ডন', 'Washington D.C.': 'ওয়াশিংটন ডি.সি.',
  // continents, oceans, landmarks
  'Asia': 'এশিয়া', 'Africa': 'আফ্রিকা', 'Europe': 'ইউরোপ', 'North America': 'উত্তর আমেরিকা', 'South America': 'দক্ষিণ আমেরিকা',
  'Oceania': 'ওশেনিয়া', 'Antarctica': 'অ্যান্টার্কটিকা', 'Pacific': 'প্রশান্ত মহাসাগর', 'Atlantic': 'আটলান্টিক মহাসাগর',
  'Indian': 'ভারত মহাসাগর', 'Arctic': 'উত্তর মহাসাগর', 'Mount Everest': 'মাউন্ট এভারেস্ট', 'Kilimanjaro': 'কিলিমানজারো',
  'Mont Blanc': 'মঁ ব্লাঁ', 'Sahara': 'সাহারা', 'Gobi': 'গোবি', 'Kalahari': 'কালাহারি', 'Atacama': 'আতাকামা',
  'Largest ocean': 'সবচেয়ে বড় মহাসাগর', 'Smallest ocean': 'সবচেয়ে ছোট মহাসাগর', 'Largest continent': 'সবচেয়ে বড় মহাদেশ',
  'Smallest continent': 'সবচেয়ে ছোট মহাদেশ', 'Coldest continent': 'সবচেয়ে শীতল মহাদেশ', 'Highest mountain': 'সবচেয়ে উঁচু পর্বত',
  'Largest hot desert': 'সবচেয়ে বড় উষ্ণ মরুভূমি', 'Ocean between Europe and North America': 'ইউরোপ ও উত্তর আমেরিকার মাঝের মহাসাগর',
  'Ocean between Africa and Australia': 'আফ্রিকা ও অস্ট্রেলিয়ার মাঝের মহাসাগর',
  // planets
  'Mercury': 'বুধ', 'Venus': 'শুক্র', 'Earth': 'পৃথিবী', 'Mars': 'মঙ্গল', 'Jupiter': 'বৃহস্পতি', 'Saturn': 'শনি', 'Uranus': 'ইউরেনাস',
  'Neptune': 'নেপচুন', 'Largest planet': 'সবচেয়ে বড় গ্রহ', 'Smallest planet': 'সবচেয়ে ছোট গ্রহ', 'Closest to the Sun': 'সূর্যের সবচেয়ে কাছে',
  'Farthest from the Sun': 'সূর্য থেকে সবচেয়ে দূরে', 'The Red Planet': 'লাল গ্রহ', 'Hottest planet': 'সবচেয়ে উষ্ণ গ্রহ',
  'Our home planet': 'আমাদের নিজের গ্রহ',
  // animals
  'lions': 'সিংহ', 'wolves': 'নেকড়ে', 'fish': 'মাছ', 'crows': 'কাক', 'owls': 'পেঁচা', 'whales': 'তিমি', 'sheep': 'ভেড়া',
  'geese': 'রাজহাঁস', 'cows': 'গরু', 'ants': 'পিঁপড়া', 'bees': 'মৌমাছি',
  'Kangaroo': 'ক্যাঙারু', 'Cat': 'বিড়াল', 'Dog': 'কুকুর', 'Cow': 'গরু', 'Horse': 'ঘোড়া', 'Sheep': 'ভেড়া', 'Goat': 'ছাগল',
  'Frog': 'ব্যাঙ', 'Swan': 'মরাল', 'Goose': 'রাজহাঁস', 'Lion': 'সিংহ', 'Bear': 'ভালুক', 'Deer': 'হরিণ', 'Pig': 'শূকর',
  'Duck': 'পাতিহাঁস', 'Owl': 'পেঁচা', 'Eagle': 'ঈগল',
  // shapes, prefixes
  'Triangle': 'ত্রিভুজ', 'Quadrilateral': 'চতুর্ভুজ', 'Pentagon': 'পঞ্চভুজ', 'Hexagon': 'ষড়ভুজ', 'Heptagon': 'সপ্তভুজ',
  'Octagon': 'অষ্টভুজ', 'Nonagon': 'নবভুজ', 'Decagon': 'দশভুজ', 'Dodecagon': 'দ্বাদশভুজ',
  'kilo': 'কিলো', 'hecto': 'হেক্টো', 'deca': 'ডেকা', 'deci': 'ডেসি', 'centi': 'সেন্টি', 'milli': 'মিলি', 'mega': 'মেগা',
  'micro': 'মাইক্রো', 'giga': 'গিগা',
  // human body
  'Largest organ of the human body': 'মানবদেহের সবচেয়ে বড় অঙ্গ', 'Pumps blood around the body': 'সারা দেহে রক্ত পাম্প করে',
  'Bones in an adult human': 'প্রাপ্তবয়স্ক মানুষের হাড়ের সংখ্যা', 'Longest bone in the body': 'দেহের সবচেয়ে লম্বা হাড়',
  'Smallest bone (in the ear)': 'সবচেয়ে ছোট হাড় (কানে)', 'Chambers in the human heart': 'মানুষের হৃৎপিণ্ডের প্রকোষ্ঠ',
  'Teeth in a full adult set': 'প্রাপ্তবয়স্কের মোট দাঁত', 'Where oxygen enters the blood': 'যেখানে অক্সিজেন রক্তে মেশে',
  'The kneecap bone': 'হাঁটুর বাটির হাড়', 'Protects the brain': 'মস্তিষ্ককে রক্ষা করে',
  'Blood cells that fight infection': 'যে রক্তকণিকা সংক্রমণের সাথে লড়ে',
  'Skin': 'ত্বক', 'Liver': 'যকৃৎ', 'Heart': 'হৃৎপিণ্ড', 'Brain': 'মস্তিষ্ক', 'Lungs': 'ফুসফুস', 'Stomach': 'পাকস্থলী',
  'Kidneys': 'বৃক্ক', 'Femur': 'ফিমার', 'Tibia': 'টিবিয়া', 'Humerus': 'হিউমেরাস', 'Radius': 'রেডিয়াস', 'Stapes': 'স্টেপিস',
  'Patella': 'প্যাটেলা', 'Ulna': 'আলনা', 'Scapula': 'স্ক্যাপুলা', 'Skull': 'করোটি', 'Ribs': 'পাঁজর', 'Pelvis': 'শ্রোণিচক্র',
  'Kneecap': 'হাঁটুর বাটি', 'White blood cells': 'শ্বেত রক্তকণিকা', 'Red blood cells': 'লোহিত রক্তকণিকা',
  'Platelets': 'অণুচক্রিকা', 'Plasma': 'প্লাজমা',
  // months
  'January': 'জানুয়ারি', 'February': 'ফেব্রুয়ারি', 'March': 'মার্চ', 'April': 'এপ্রিল', 'May': 'মে', 'June': 'জুন',
  'July': 'জুলাই', 'August': 'আগস্ট', 'September': 'সেপ্টেম্বর', 'October': 'অক্টোবর', 'November': 'নভেম্বর', 'December': 'ডিসেম্বর',
};

/// Element names apart from [_bn]: "Mercury" is বুধ as a planet but পারদ as an element.
const _bnElements = {
  'Hydrogen': 'হাইড্রোজেন', 'Helium': 'হিলিয়াম', 'Lithium': 'লিথিয়াম', 'Beryllium': 'বেরিলিয়াম', 'Boron': 'বোরন',
  'Carbon': 'কার্বন', 'Nitrogen': 'নাইট্রোজেন', 'Oxygen': 'অক্সিজেন', 'Fluorine': 'ফ্লোরিন', 'Neon': 'নিয়ন',
  'Sodium': 'সোডিয়াম', 'Magnesium': 'ম্যাগনেসিয়াম', 'Aluminium': 'অ্যালুমিনিয়াম', 'Silicon': 'সিলিকন', 'Phosphorus': 'ফসফরাস',
  'Sulfur': 'সালফার', 'Chlorine': 'ক্লোরিন', 'Argon': 'আর্গন', 'Potassium': 'পটাশিয়াম', 'Calcium': 'ক্যালসিয়াম',
  'Titanium': 'টাইটানিয়াম', 'Chromium': 'ক্রোমিয়াম', 'Manganese': 'ম্যাঙ্গানিজ', 'Iron': 'লোহা', 'Cobalt': 'কোবাল্ট',
  'Nickel': 'নিকেল', 'Copper': 'তামা', 'Zinc': 'দস্তা', 'Silver': 'রুপা', 'Gold': 'সোনা', 'Tin': 'টিন', 'Lead': 'সিসা',
  'Mercury': 'পারদ',
};

/// [s] in the current language (unknown text, like numbers, passes through).
String _b(String s) => tr(s, _bn[s] ?? s);
String _el(String s) => tr(s, _bnElements[s] ?? s);

// ---------- games ----------

final quizGames2 = <Game>[
  // Knowledge
  q2('Country Flags', 'Knowledge', '🚩', bn: 'দেশের পতাকা', (r, d) {
    final (f, c) = one(r, flags);
    return choice(f, _b(c), flags.map((e) => _b(e.$2)), ask: tr('Which country?', 'কোন দেশ?'));
  }),
  q2('Capital to Country', 'Knowledge', '🏙️', bn: 'রাজধানী থেকে দেশ', (r, d) {
    final (c, cap) = one(r, capitals);
    return choice(_b(cap), _b(c), capitals.map((e) => _b(e.$1)), ask: tr('Capital of which country?', 'কোন দেশের রাজধানী?'));
  }),
  q2('Continents', 'Knowledge', '🌍', bn: 'মহাদেশ', (r, d) {
    final c = one(r, continentOf.keys.toList());
    return choice(_b(c), _b(continentOf[c]!), continentNames.map(_b), ask: tr('Which continent?', 'কোন মহাদেশে?'));
  }),
  q2('Planets', 'Knowledge', '🪐', bn: 'গ্রহ', (r, d) {
    if (r.nextBool()) {
      final i = r.nextInt(8);
      return choice(tr('Planet #${i + 1} from the Sun', 'সূর্য থেকে ${i + 1} নম্বর গ্রহ'), _b(planetNames[i]), planetNames.map(_b));
    }
    final (q, a) = one(r, planetFacts);
    return choice(_b(q), _b(a), planetNames.map(_b));
  }),
  q2('Chemical Symbols', 'Knowledge', '⚗️', bn: 'রাসায়নিক প্রতীক', (r, d) {
    final (name, sym) = one(r, elements);
    return choice(_el(name), sym, elements.map((e) => e.$2), ask: tr('Chemical symbol?', 'রাসায়নিক প্রতীক?'));
  }),
  q2('Symbol to Element', 'Knowledge', '🧪', bn: 'প্রতীক থেকে মৌল', (r, d) {
    final (name, sym) = one(r, elements);
    return choice(sym, _el(name), elements.map((e) => _el(e.$1)), ask: tr('Which element?', 'কোন মৌল?'));
  }),
  q2('Animal Groups', 'Knowledge', '🦁', bn: 'প্রাণীর দল', (r, d) {
    final (animal, group, ok) = one(r, animalGroups);
    return choice(tr('A group of $animal', 'এক দল ${_b(animal)}'), group, animalGroups.map((e) => e.$2).where((x) => !ok.contains(x)),
        ask: tr('Collective noun?', 'ইংরেজিতে দলের নাম?'));
  }),
  q2('Baby Animals', 'Knowledge', '🐣', bn: 'প্রাণীর বাচ্চা', (r, d) {
    final (animal, baby) = one(r, babyAnimals);
    return choice(_b(animal), baby, babyAnimals.map((e) => e.$2), ask: tr('Its baby is called', 'ইংরেজিতে এর বাচ্চার নাম'));
  }),
  q2('Polygon Sides', 'Knowledge', '🔷', bn: 'বহুভুজের বাহু', (r, d) {
    final (name, sides) = one(r, polygons);
    return r.nextBool()
        ? choice(_b(name), '$sides', polygons.map((e) => '${e.$2}'), ask: tr('How many sides?', 'কয়টি বাহু?'))
        : choice(tr('$sides sides', '$sides বাহু'), _b(name), polygons.map((e) => _b(e.$1)), ask: tr('Which shape?', 'কোন আকৃতি?'));
  }),
  q2('Metric Prefixes', 'Knowledge', 'k·m', bn: 'মেট্রিক উপসর্গ', (r, d) {
    final (p, v) = one(r, metricPrefixes);
    return choice(_b(p), v, metricPrefixes.map((e) => e.$2), ask: tr('This prefix means ×', 'এই উপসর্গের মান ×'));
  }),
  q2('Human Body', 'Knowledge', '🫀', bn: 'মানবদেহ', (r, d) {
    final (q, a, w) = one(r, bodyFacts);
    return Q(_b(q), _b(a), w.map(_b));
  }),
  q2('Oceans & Continents', 'Knowledge', '🌊', bn: 'মহাসাগর ও মহাদেশ', (r, d) {
    final (q, a, w) = one(r, earthFacts);
    return Q(_b(q), _b(a), w.map(_b));
  }),

  // Math
  q2('Fraction of Number', 'Math', '¾×', bn: 'সংখ্যার ভগ্নাংশ', (r, d) {
    final b = rn(r, 2, 4 + d), a = rn(r, 1, b - 1), x = b * rn(r, 2, 5 * d);
    return n(tr('$a/$b of $x', '$x-এর $a/$b'), a * x ~/ b, r);
  }),
  q2('Decimal to Fraction', 'Math', '0.5', bn: 'দশমিক থেকে ভগ্নাংশ', (r, d) {
    final (dec, frac) = one(r, decimalFractions);
    return choice(dec, frac, decimalFractions.map((e) => e.$2), ask: tr('As a fraction', 'ভগ্নাংশে'));
  }),
  q2('Simple Interest', 'Math', '💰', bn: 'সরল সুদ', (r, d) {
    final p = rn(r, 1, 10 * d) * 100, rate = rn(r, 1, 10), t = rn(r, 1, 5);
    return n(tr('$p at $rate% for $t years', '$p টাকা, $rate% হারে $t বছর'), p * rate * t ~/ 100, r, ask: tr('Simple interest?', 'সরল সুদ কত?'));
  }),
  q2('Ratio Split', 'Math', '1:2', bn: 'অনুপাতে ভাগ', (r, d) {
    final a = rn(r, 1, 5), b = rn(r, 1, 5), k = rn(r, 2, 5 * d);
    return n(tr('Split ${(a + b) * k} in $a:$b', '${(a + b) * k} কে $a:$b অনুপাতে ভাগ'), a * k, r, ask: tr('First share?', 'প্রথম ভাগ কত?'));
  }),
  q2('Next Prime', 'Math', '→7', bn: 'পরের মৌলিক সংখ্যা', (r, d) {
    final x = rn(r, 2, 20 * d * d);
    var p = x + 1;
    while (!isPrime(p)) {
      p++;
    }
    return n('$x', p, r, ask: tr('Next prime after', 'এর পরের মৌলিক সংখ্যা'));
  }),
  q2('Time Difference', 'Math', '⌚', bn: 'সময়ের পার্থক্য', (r, d) {
    final s = rn(r, 0, 16 * 12) * 5, dur = rn(r, 1, 12 * (1 + d)) * 5;
    String hm(int m) => '${'${m ~/ 60}'.padLeft(2, '0')}:${'${m % 60}'.padLeft(2, '0')}';
    String len(int m) => tr('${m ~/ 60}h ${m % 60}m', '${m ~/ 60} ঘণ্টা ${m % 60} মিনিট');
    return Q('${hm(s)} → ${hm(s + dur)}', len(dur), [for (final k in [-60, -10, -5, 5, 10, 60]) if (dur + k > 0) len(dur + k)], ask: tr('How long?', 'কতক্ষণ?'));
  }),
  q2('Clock Angle', 'Math', '∠', bn: 'ঘড়ির কাঁটার কোণ', (r, d) {
    final h = rn(r, 1, 12), m = d == 1 ? 0 : rn(r, 0, 5) * 10;
    final a = (30 * (h % 12) - 5.5 * m).abs().round();
    return n('$h:${'$m'.padLeft(2, '0')}', min(a, 360 - a), r, ask: tr('Angle between the clock hands (°)?', 'ঘড়ির দুই কাঁটার মাঝের কোণ (°)?'));
  }),
  q2('Day of the Year', 'Math', '📆', bn: 'বছরের কততম দিন', (r, d) {
    final mi = r.nextInt(12), day = rn(r, 1, monthDays[mi]);
    return n(tr('${months[mi]} $day', '$day ${_b(months[mi])}'), monthDays.take(mi).fold(0, (s, x) => s + x) + day, r, ask: tr('Day number in a non-leap year?', 'অধিবর্ষ নয় এমন বছরে এটি কততম দিন?'));
  }),

  // Logic
  q2('Magic Square', 'Logic', '🔮', bn: 'ম্যাজিক স্কয়ার', (r, d) {
    var g = [8, 1, 6, 3, 5, 7, 4, 9, 2];
    for (var k = r.nextInt(4); k > 0; k--) {
      g = [for (var i = 0; i < 9; i++) g[(2 - i % 3) * 3 + i ~/ 3]]; // rotate 90°
    }
    if (r.nextBool()) g = [for (var i = 0; i < 9; i++) g[i ~/ 3 * 3 + 2 - i % 3]]; // mirror
    final m = rn(r, 1, d), add = rn(r, 0, 5 * d), hide = r.nextInt(9);
    g = [for (final x in g) x * m + add];
    final rows = [for (var row = 0; row < 3; row++) [for (var c = 0; c < 3; c++) row * 3 + c == hide ? '?' : '${g[row * 3 + c]}'].join('   ')];
    return n(rows.join('\n'), g[hide], r, ask: tr('Rows, columns and diagonals all add up the same. Missing?', 'প্রতিটি সারি, কলাম ও কর্ণের যোগফল সমান। ? কত?'));
  }),
  q2('Number Pyramid', 'Logic', '🔺', bn: 'সংখ্যার পিরামিড', (r, d) {
    final rows = [
      [for (var i = 0; i < (d < 3 ? 3 : 4); i++) rn(r, 1, 5 * d)],
    ];
    while (rows.last.length > 1) {
      rows.add([for (var i = 0; i + 1 < rows.last.length; i++) rows.last[i] + rows.last[i + 1]]);
    }
    return n([for (final row in rows.reversed) row.length == 1 ? '?' : row.join('  ')].join('\n'), rows.last.first, r,
        ask: tr('Each block is the sum of the two below it. Top?', 'প্রতিটি ঘর তার নিচের দুটির যোগফল। চূড়ায় কত?'));
  }),
  q2('Code Breaker', 'Logic', '🔐', bn: 'কোড ভাঙো', (r, d) {
    final w = one(r, words);
    return n(w, w.codeUnits.fold(0, (s, c) => s + c - 64), r, ask: tr('A=1, B=2 … Z=26. Word total?', 'A=1, B=2 … Z=26। শব্দের যোগফল?'));
  }),
  q2('Balance Scale', 'Logic', '🧮', bn: 'দাঁড়িপাল্লা', (r, d) {
    final a = rn(r, 2, 2 + d), b = rn(r, 2, 2 + d);
    return n('1 🍉 = $b 🍌\n1 🍌 = $a 🍎', a * b, r, ask: tr('How many 🍎 balance 1 🍉?', 'কয়টি 🍎 দিলে 1 🍉-এর সমান হবে?'));
  }),

  // Word
  q2('Rhyme Time', 'Word', '🎵', bn: 'ছন্দ মেলাও', (r, d) {
    final f = one(r, rhymeFamilies), w = one(r, f);
    return Q(w, one(r, f.where((x) => x != w).toList()), [for (final g in rhymeFamilies) if (g != f) ...g], ask: tr('Which word rhymes with', 'কোন শব্দের সাথে ছন্দ মেলে'));
  }),
  q2('Plurals', 'Word', '📚', bn: 'বহুবচন', (r, d) {
    final (s, p, w) = one(r, plurals);
    return Q(s, p, w, ask: tr('Plural of', 'বহুবচন কী'));
  }),
  q2('Homophones', 'Word', '👂', bn: 'একই উচ্চারণের শব্দ', (r, d) {
    final (a, b) = one(r, homophones);
    final all = [for (final (x, y) in homophones) ...[x, y]];
    return r.nextBool()
        ? Q(a, b, all.where((x) => x != a && x != b), ask: tr('Sounds the same as', 'একই উচ্চারণ কোনটির'))
        : Q(b, a, all.where((x) => x != a && x != b), ask: tr('Sounds the same as', 'একই উচ্চারণ কোনটির'));
  }),
  q2('Word Ladder', 'Word', '🪜', bn: 'শব্দের সিঁড়ি', (r, d) {
    final w = one(r, ladderWords);
    final near = ladderWords.where((x) => letterDiff(w, x) == 1).toList();
    return Q(w, one(r, near), ladderWords.where((x) => letterDiff(w, x) >= 2), ask: tr('Change ONE letter of', 'মাত্র একটি অক্ষর বদলাও'));
  }),

  // Focus
  q2('Most Common Arrow', 'Focus', '⬆⬇', bn: 'সবচেয়ে বেশি তীর', (r, d) {
    List<String> s;
    List<int> counts;
    do {
      s = [for (var i = 0; i < 8 + 4 * d; i++) one(r, arrowSymbols)];
      counts = [for (final a in arrowSymbols) s.where((x) => x == a).length];
    } while (counts.where((c) => c == counts.reduce(max)).length > 1);
    return choice(s.join(' '), arrowSymbols[counts.indexOf(counts.reduce(max))], arrowSymbols, ask: tr('Which arrow appears most?', 'কোন তীর সবচেয়ে বেশি আছে?'));
  }),
  q2('Mirror Letters', 'Focus', '🪞', bn: 'আয়নার অক্ষর', (r, d) {
    return Q(tr('Looks the same in a mirror?', 'কোনটি আয়নায় একই দেখায়?'), mirrorSame[r.nextInt(mirrorSame.length)], mirrorDifferent.split(''));
  }),
];
