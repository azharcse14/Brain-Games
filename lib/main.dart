import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'games.dart';
import 'quiz.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  runApp(const App());
}

final allGames = [...quizGames, ...otherGames];

const cats = {
  'Math': (Icons.calculate, Colors.blue),
  'Logic': (Icons.psychology, Colors.purple),
  'Word': (Icons.abc, Colors.teal),
  'Memory': (Icons.memory, Colors.orange),
  'Focus': (Icons.center_focus_strong, Colors.red),
  'Puzzle': (Icons.extension, Colors.green),
};

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

  @override
  Widget build(BuildContext context) {
    final muted = prefs?.getBool('mute') ?? false;
    final list = allGames.where((g) => cat == null || g.cat == cat).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Brain Games · ${allGames.length}'), actions: [
        IconButton(
          tooltip: 'Sound',
          icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
          onPressed: () => setState(() => prefs?.setBool('mute', !muted)),
        ),
      ]),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in [null, ...cats.keys])
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: ChoiceChip(label: Text(c ?? 'All'), selected: cat == c, onSelected: (_) => setState(() => cat = c)),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.extent(
            maxCrossAxisExtent: 180,
            padding: const EdgeInsets.all(12),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
              for (final g in list)
                Card(
                  clipBehavior: Clip.antiAlias,
                  color: cats[g.cat]!.$2.withValues(alpha: .2),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: g.name), builder: (_) => g.build()));
                      if (mounted) setState(() {}); // refresh best scores
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(cats[g.cat]!.$1, size: 36, color: cats[g.cat]!.$2),
                        const SizedBox(height: 8),
                        Flexible(child: Text(g.name, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 3, style: const TextStyle(fontWeight: FontWeight.w600))),
                        if (prefs?.getString('bestText:${g.name}') case final best?) Text('Best: $best', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
