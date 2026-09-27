import 'package:flutter/material.dart';

import 'games.dart';
import 'quiz.dart';

void main() => runApp(const App());

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
    final list = allGames.where((g) => cat == null || g.cat == cat).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Brain Games · ${allGames.length}')),
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
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => g.build())),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(cats[g.cat]!.$1, size: 36, color: cats[g.cat]!.$2),
                        const SizedBox(height: 8),
                        Flexible(child: Text(g.name, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 3, style: const TextStyle(fontWeight: FontWeight.w600))),
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
