import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'duel.dart';
import 'games.dart';

final _r = Random();
const _cat = '2P Action';

final duelActionGames = <Game>[
  Game('Pong Classic', _cat, () => const Pong('Pong Classic'), glyph: '🏓'),
  Game('Pong Fast', _cat, () => const Pong('Pong Fast', speed: 1.5), glyph: '🏓💨'),
  Game('Pong Two Balls', _cat, () => const Pong('Pong Two Balls', balls: 2), glyph: '⚪⚪'),
  Game('Pong Tiny Paddles', _cat, () => const Pong('Pong Tiny Paddles', paddle: .12), glyph: '▁▁'),
  Game('Pong Center Wall', _cat, () => const Pong('Pong Center Wall', wall: true), glyph: '▬ ▬'),
  Game('Pong Speed-Up Rally', _cat, () => const Pong('Pong Speed-Up Rally', speedUp: true), glyph: '⏩'),
  Game('Air Hockey Classic', _cat, () => const AirHockey('Air Hockey Classic'), glyph: '🏒'),
  Game('Air Hockey Big Goals', _cat, () => const AirHockey('Air Hockey Big Goals', goal: .6), glyph: '🥅'),
  Game('Air Hockey Ice', _cat, () => const AirHockey('Air Hockey Ice', friction: .97), glyph: '🧊'),
  Game('Air Hockey Heavy Puck', _cat, () => const AirHockey('Air Hockey Heavy Puck', puckR: .055, mass: 1.5, friction: .35), glyph: '🪨'),
  Game('Air Hockey Two Pucks', _cat, () => const AirHockey('Air Hockey Two Pucks', pucks: 2), glyph: '⚫⚫'),
  Game('Tron Classic', _cat, () => const GridDuel('Tron Classic'), glyph: '🏍️'),
  Game('Tron Fast', _cat, () => const GridDuel('Tron Fast', tickMs: 50), glyph: '🏍️💨'),
  Game('Tron Small Arena', _cat, () => const GridDuel('Tron Small Arena', cols: 18, rows: 26, tickMs: 100), glyph: '▫️'),
  Game('Tron Wrap-Around', _cat, () => const GridDuel('Tron Wrap-Around', wrap: true), glyph: '🔁'),
  Game('Tron Boost', _cat, () => const GridDuel('Tron Boost', boost: true), glyph: '🚀'),
  Game('Tron Obstacles', _cat, () => const GridDuel('Tron Obstacles', obstacles: true), glyph: '⛔'),
  Game('Snake Duel Classic', _cat, () => const GridDuel('Snake Duel Classic', tron: false, cols: 20, rows: 30, tickMs: 130, len: 3), glyph: '🐍'),
  Game('Snake Duel Fast', _cat, () => const GridDuel('Snake Duel Fast', tron: false, cols: 20, rows: 30, tickMs: 85, len: 3), glyph: '🐍💨'),
  Game('Snake Duel Wrap', _cat, () => const GridDuel('Snake Duel Wrap', tron: false, cols: 20, rows: 30, tickMs: 130, len: 3, wrap: true), glyph: '🐍🔁'),
  Game('Snake Duel Poison', _cat, () => const GridDuel('Snake Duel Poison', tron: false, cols: 20, rows: 30, tickMs: 130, len: 3, poison: true), glyph: '☠️'),
  Game('Snake Duel Long', _cat, () => const GridDuel('Snake Duel Long', tron: false, cols: 20, rows: 30, tickMs: 130, len: 10), glyph: '〰️'),
  Game('Tug of War', _cat, () => const TapBattle('Tug of War', 'tug'), glyph: '🪢'),
  Game('Tap Race 100', _cat, () => const TapBattle('Tap Race 100', 'race'), glyph: '👆'),
  Game('Hold & Release', _cat, () => const TapBattle('Hold & Release', 'hold'), glyph: '⏱️'),
  Game('Rhythm Duel', _cat, () => const TapBattle('Rhythm Duel', 'rhythm'), glyph: '🥁'),
  Game('Reflex Duel Classic', _cat, () => const ReflexDuel('Reflex Duel Classic', 'classic'), glyph: '🚦'),
  Game('Reflex Duel Stroop', _cat, () => const ReflexDuel('Reflex Duel Stroop', 'stroop'), glyph: '🌈'),
  Game('Reflex Duel Even', _cat, () => const ReflexDuel('Reflex Duel Even', 'even'), glyph: '2 4 6'),
  Game('Reflex Duel Shapes', _cat, () => const ReflexDuel('Reflex Duel Shapes', 'shape'), glyph: '▲▲'),
];

// ---------- shared ----------

class _Painter extends CustomPainter {
  _Painter(this.draw);
  final void Function(Canvas, Size) draw;
  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Widget _canvas(void Function(Canvas, Size) draw) => CustomPaint(painter: _Painter(draw), child: const SizedBox.expand());

List<Widget> _scores(List<int> score) => [
      Align(alignment: const Alignment(.85, -.15), child: facingTop(Text('${score[1]}', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: duelColors[1].withValues(alpha: .7))))),
      Align(alignment: const Alignment(.85, .15), child: Text('${score[0]}', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: duelColors[0].withValues(alpha: .7)))),
    ];

/// Top half (Red, read upside-down) and bottom half (Blue), each tinted and showing [content].
Widget _halves(Widget Function(int p) content) => Column(children: [
      for (final p in [1, 0])
        Expanded(
          child: Container(
            color: duelColors[p].withValues(alpha: .18),
            alignment: Alignment.center,
            child: p == 1 ? facingTop(content(1)) : content(0),
          ),
        ),
    ]);

Widget _banner(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
      child: Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );

/// Routes every finger to the player whose half it started in (0 = bottom, 1 = top); positions are 0..1.
class _TouchSplit extends StatefulWidget {
  const _TouchSplit({required this.child, this.onTouch, this.onDown, this.onUp});
  final Widget child;
  final void Function(int player, Offset pos)? onTouch, onDown;
  final void Function(int player)? onUp;
  @override
  State<_TouchSplit> createState() => _TouchSplitState();
}

class _TouchSplitState extends State<_TouchSplit> {
  final owner = <int, int>{};

  void release(PointerEvent e) {
    final pl = owner.remove(e.pointer);
    if (pl != null) widget.onUp?.call(pl);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        Offset norm(Offset p) => Offset(p.dx / box.maxWidth, p.dy / box.maxHeight);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            final p = norm(e.localPosition), pl = p.dy < .5 ? 1 : 0;
            owner[e.pointer] = pl;
            widget.onDown?.call(pl, p);
            widget.onTouch?.call(pl, p);
          },
          onPointerMove: (e) {
            final pl = owner[e.pointer];
            if (pl != null) widget.onTouch?.call(pl, norm(e.localPosition));
          },
          onPointerUp: release,
          onPointerCancel: release,
          child: widget.child,
        );
      });
}

class _Body {
  _Body(this.p, this.v);
  Offset p, v;
}

double _dt(Duration now, Duration last) => min((now - last).inMicroseconds / 1e6, 1 / 30);

// ---------- Pong ----------

class Pong extends StatefulWidget {
  const Pong(this.title, {super.key, this.speed = .9, this.balls = 1, this.paddle = .24, this.wall = false, this.speedUp = false});
  final String title;
  final double speed, paddle;
  final int balls;
  final bool wall, speedUp;
  @override
  State<Pong> createState() => _PongState();
}

class _PongState extends State<Pong> with SingleTickerProviderStateMixin {
  static const target = 5, padY = .92, rx = .022, ry = .013;
  late final Ticker ticker = createTicker(tick);
  final pads = [.5, .5], score = [0, 0];
  late List<_Body> balls;
  Duration last = Duration.zero;
  double pause = 1;

  @override
  void initState() {
    super.initState();
    reset();
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void reset() {
    score.fillRange(0, 2, 0);
    balls = [for (var i = 0; i < widget.balls; i++) serve(i.isEven ? 0 : 1)];
    pause = 1;
    last = Duration.zero;
  }

  _Body serve(int toward) => _Body(const Offset(.5, .5), Offset((_r.nextDouble() - .5) * .6, toward == 0 ? 1 : -1) * widget.speed);

  void tick(Duration now) {
    final dt = _dt(now, last);
    last = now;
    if (pause > 0) {
      pause -= dt;
    } else {
      for (var i = 0; i < balls.length; i++) {
        final b = balls[i], steps = max(1, (b.v.distance * dt / .008).ceil());
        for (var s = 0; s < steps; s++) {
          final scorer = moveBall(b, dt / steps);
          if (scorer != null) {
            goal(scorer, i);
            break;
          }
        }
      }
    }
    setState(() {});
  }

  /// Advances one ball; returns the scoring player if it left the table.
  int? moveBall(_Body b, double dt) {
    final old = b.p;
    var p = old + b.v * dt, v = b.v;
    if (p.dx < rx || p.dx > 1 - rx) {
      v = Offset(-v.dx, v.dy);
      p = Offset(p.dx.clamp(rx, 1 - rx), p.dy);
    }
    if (widget.wall && (old.dy - .5) * (p.dy - .5) < 0 && (p.dx < .3 || p.dx > .7)) {
      v = Offset(v.dx, -v.dy);
      p = Offset(p.dx, old.dy);
    }
    for (var pl = 0; pl < 2; pl++) {
      final d = pl == 0 ? 1.0 : -1.0, surface = (pl == 0 ? padY : 1 - padY) - d * ry;
      if (v.dy * d > 0 && (surface - old.dy) * d >= 0 && (p.dy - surface) * d >= 0 && (p.dx - pads[pl]).abs() <= widget.paddle / 2 + rx) {
        final off = ((p.dx - pads[pl]) / (widget.paddle / 2)).clamp(-1.0, 1.0);
        final speed = min(v.distance * (widget.speedUp ? 1.12 : 1.03), 3.0), dir = Offset(off * .8, -d);
        v = dir / dir.distance * speed;
        p = Offset(p.dx, surface);
        sfx('tap');
      }
    }
    b
      ..p = p
      ..v = v;
    if (p.dy > 1) return 1;
    if (p.dy < 0) return 0;
    return null;
  }

  void goal(int scorer, int i) {
    if (!ticker.isActive) return;
    score[scorer]++;
    sfx('right');
    balls[i] = serve(1 - scorer);
    pause = .8;
    if (score[scorer] == target) {
      ticker.stop();
      showWinner(context, scorer, () => setState(() {
            reset();
            ticker.start();
          }));
    }
  }

  void draw(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF0B1020));
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), Paint()
      ..color = Colors.white24
      ..strokeWidth = 2);
    if (widget.wall) {
      final wall = Paint()..color = Colors.white70;
      c.drawRect(Rect.fromLTRB(0, s.height / 2 - 3, .3 * s.width, s.height / 2 + 3), wall);
      c.drawRect(Rect.fromLTRB(.7 * s.width, s.height / 2 - 3, s.width, s.height / 2 + 3), wall);
    }
    for (var pl = 0; pl < 2; pl++) {
      final y = (pl == 0 ? padY : 1 - padY) * s.height;
      final rect = Rect.fromCenter(center: Offset(pads[pl] * s.width, y), width: widget.paddle * s.width, height: 2 * ry * s.height);
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = duelColors[pl]);
    }
    for (final b in balls) {
      c.drawCircle(Offset(b.p.dx * s.width, b.p.dy * s.height), rx * s.width, Paint()..color = Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) => page(
        widget.title,
        _TouchSplit(
          onTouch: (pl, pos) => pads[pl] = pos.dx.clamp(widget.paddle / 2, 1 - widget.paddle / 2),
          child: Stack(children: [_canvas(draw), ..._scores(score)]),
        ),
        'First to $target',
      );
}

// ---------- Air Hockey ----------

/// Velocity of a body bouncing off a surface with normal [n] that moves at [surfaceV].
/// [massRatio] = body mass / striker mass: heavier bodies take less of the hit.
Offset bounceOff(Offset v, Offset n, Offset surfaceV, double e, double massRatio) {
  final rel = v - surfaceV, vn = rel.dx * n.dx + rel.dy * n.dy;
  if (vn >= 0) return v;
  return v - n * ((1 + e) * vn / (1 + massRatio));
}

class AirHockey extends StatefulWidget {
  const AirHockey(this.title, {super.key, this.goal = .36, this.friction = .55, this.puckR = .04, this.mass = .35, this.pucks = 1});
  final String title;
  final double goal, friction, puckR, mass; // friction = speed kept per second
  final int pucks;
  @override
  State<AirHockey> createState() => _AirHockeyState();
}

class _AirHockeyState extends State<AirHockey> with SingleTickerProviderStateMixin {
  static const target = 7, rm = .075, e = .9, maxSpeed = 3.5;
  late final Ticker ticker = createTicker(tick);
  final score = [0, 0];
  double a = 1.6; // table height / width; x runs 0..1, y runs 0..a
  late List<Offset> mallets, prev, malletV;
  late List<_Body> pucks;
  Duration last = Duration.zero;
  double pause = 1;

  @override
  void initState() {
    super.initState();
    reset();
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void place() {
    mallets = [Offset(.5, a * .85), Offset(.5, a * .15)];
    prev = mallets.toList();
    malletV = [Offset.zero, Offset.zero];
    pucks = [for (var i = 0; i < widget.pucks; i++) _Body(Offset(widget.pucks == 1 ? .5 : .3 + .4 * i, a / 2), Offset.zero)];
  }

  void reset() {
    score.fillRange(0, 2, 0);
    place();
    pause = 1;
    last = Duration.zero;
  }

  void touch(int pl, Offset pos) {
    final y = pos.dy * a;
    mallets[pl] = Offset(pos.dx.clamp(rm, 1 - rm), pl == 0 ? y.clamp(a / 2 + rm, a - rm) : y.clamp(rm, a / 2 - rm));
  }

  void tick(Duration now) {
    final dt = _dt(now, last);
    last = now;
    if (dt <= 0) return;
    final from = prev.toList(), to = mallets.toList();
    for (var pl = 0; pl < 2; pl++) {
      final v = (to[pl] - from[pl]) / dt;
      malletV[pl] = v.distance > 6 ? v / v.distance * 6 : v;
      prev[pl] = to[pl];
    }
    if (pause > 0) {
      pause -= dt;
    } else {
      // Substeps cover the puck's travel AND each mallet's, and the mallets are swept along with the puck,
      // so a fast smash can't jump over it between frames.
      final reach = max((to[0] - from[0]).distance, (to[1] - from[1]).distance);
      for (var i = 0; i < pucks.length; i++) {
        final b = pucks[i], steps = min(30, max(1, ((b.v.distance * dt + reach) / (widget.puckR / 2)).ceil()));
        for (var s = 0; s < steps; s++) {
          for (var pl = 0; pl < 2; pl++) {
            mallets[pl] = Offset.lerp(from[pl], to[pl], (s + 1) / steps)!;
          }
          final scorer = movePuck(b, dt / steps);
          if (scorer != null) {
            goal(scorer, i);
            break;
          }
        }
        pucks[i].v *= pow(widget.friction, dt).toDouble();
      }
      mallets.setAll(0, to);
      if (pucks.length == 2) collidePucks();
    }
    setState(() {});
  }

  int? movePuck(_Body b, double dt) {
    final r = widget.puckR;
    var p = b.p + b.v * dt, v = b.v;
    if (p.dx < r || p.dx > 1 - r) {
      v = Offset(-v.dx, v.dy);
      p = Offset(p.dx.clamp(r, 1 - r), p.dy);
    }
    final inMouth = (p.dx - .5).abs() < widget.goal / 2 - r / 2;
    if (!inMouth && (p.dy < r || p.dy > a - r)) {
      v = Offset(v.dx, -v.dy);
      p = Offset(p.dx, p.dy.clamp(r, a - r));
    }
    for (var pl = 0; pl < 2; pl++) {
      final d = p - mallets[pl], dist = d.distance;
      if (dist < r + rm && dist > 0) {
        final n = d / dist;
        p = mallets[pl] + n * (r + rm);
        v = bounceOff(v, n, malletV[pl], e, widget.mass);
      }
    }
    if (v.distance > maxSpeed) v = v / v.distance * maxSpeed;
    b
      ..p = p
      ..v = v;
    if (p.dy < -r) return 0; // into Red's goal at the top
    if (p.dy > a + r) return 1;
    return null;
  }

  void collidePucks() {
    final x = pucks[0], y = pucks[1], d = y.p - x.p, dist = d.distance, touch = 2 * widget.puckR;
    if (dist >= touch || dist == 0) return;
    final n = d / dist, rel = x.v - y.v, vn = rel.dx * n.dx + rel.dy * n.dy;
    x.p -= n * ((touch - dist) / 2);
    y.p += n * ((touch - dist) / 2);
    if (vn > 0) {
      x.v -= n * vn;
      y.v += n * vn;
    }
  }

  void goal(int scorer, int i) {
    if (!ticker.isActive) return;
    score[scorer]++;
    sfx('right');
    pucks[i] = _Body(Offset(.5, a / 2 + (scorer == 0 ? -.12 : .12)), Offset.zero); // restart on the conceder's side
    pause = .8;
    if (score[scorer] == target) {
      ticker.stop();
      showWinner(context, scorer, () => setState(() {
            reset();
            ticker.start();
          }));
    }
  }

  void draw(Canvas c, Size s) {
    final na = s.height / s.width;
    if ((na - a).abs() > .001) {
      a = na;
      place();
    }
    final w = s.width;
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF0E2A47));
    final line = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(0, s.height / 2), Offset(w, s.height / 2), line);
    c.drawCircle(Offset(w / 2, s.height / 2), w * .12, line);
    for (var pl = 0; pl < 2; pl++) {
      c.drawRect(Rect.fromLTWH((.5 - widget.goal / 2) * w, pl == 0 ? s.height - 5 : 0, widget.goal * w, 5), Paint()..color = duelColors[pl]);
      c.drawCircle(mallets[pl] * w, rm * w, Paint()..color = duelColors[pl]);
      c.drawCircle(mallets[pl] * w, rm * w * .45, Paint()..color = Colors.white30);
    }
    for (final b in pucks) {
      c.drawCircle(b.p * w, widget.puckR * w, Paint()..color = Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) => page(
        widget.title,
        _TouchSplit(onTouch: touch, child: Stack(children: [_canvas(draw), ..._scores(score)])),
        'First to $target',
      );
}

// ---------- Tron & Snake Duel ----------

typedef Cell = (int, int);

/// Moves [c] one step in direction [d]; null when it leaves the board (unless [wrap]).
Cell? gridStep(Cell c, Cell d, int cols, int rows, {bool wrap = false}) {
  final x = c.$1 + d.$1, y = c.$2 + d.$2;
  if (wrap) return ((x + cols) % cols, (y + rows) % rows);
  return x < 0 || y < 0 || x >= cols || y >= rows ? null : (x, y);
}

Cell turnLeft(Cell d) => (d.$2, -d.$1);
Cell turnRight(Cell d) => (-d.$2, d.$1);

class GridDuel extends StatefulWidget {
  const GridDuel(this.title,
      {super.key, this.tron = true, this.cols = 30, this.rows = 44, this.tickMs = 80, this.wrap = false, this.boost = false, this.obstacles = false, this.poison = false, this.len = 1});
  final String title;
  final bool tron, wrap, boost, obstacles, poison; // tron: trails never shrink, no food
  final int cols, rows, tickMs, len;
  @override
  State<GridDuel> createState() => _GridDuelState();
}

class _GridDuelState extends State<GridDuel> {
  static const target = 3;
  final score = [0, 0], boostLeft = [0, 0], boosting = [0, 0];
  final pending = [<Cell>[], <Cell>[]];
  late List<List<Cell>> bodies; // head = last
  late List<Cell> dirs;
  Set<Cell> blocks = {};
  Cell? food, poison;
  Timer? timer, roundTimer;
  int phase = 0;
  String? msg;
  int get cols => widget.cols;
  int get rows => widget.rows;

  @override
  void initState() {
    super.initState();
    startRound();
    // Half-rate ticks: normal movers step every other tick, boosted ones every tick.
    timer = Timer.periodic(Duration(milliseconds: widget.tickMs ~/ 2), (_) => step());
  }

  @override
  void dispose() {
    timer?.cancel();
    roundTimer?.cancel();
    super.dispose();
  }

  void startRound() {
    final n = widget.len, x0 = cols ~/ 3, x1 = cols - 1 - cols ~/ 3, y0 = rows - 1 - n, y1 = n;
    bodies = [
      [for (var k = n - 1; k >= 0; k--) (x0, y0 + k)],
      [for (var k = n - 1; k >= 0; k--) (x1, y1 - k)],
    ];
    dirs = [(0, -1), (0, 1)];
    pending[0].clear();
    pending[1].clear();
    boostLeft.fillRange(0, 2, widget.boost ? 3 : 0);
    boosting.fillRange(0, 2, 0);
    blocks = {};
    food = poison = null;
    if (widget.obstacles) {
      while (blocks.length < cols * rows ~/ 40) {
        final c = (_r.nextInt(cols), _r.nextInt(rows));
        if (c.$2 > n + 3 && c.$2 < rows - n - 4) blocks.add(c); // keep the starting lanes clear
      }
    }
    if (!widget.tron) food = freeCell();
    if (widget.poison) poison = freeCell();
    phase = 0;
    msg = 'Get ready!';
    roundTimer?.cancel();
    roundTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => msg = null);
    });
  }

  Cell freeCell() {
    final taken = {...blocks, ...bodies[0], ...bodies[1], if (food != null) food!, if (poison != null) poison!};
    while (true) {
      final c = (_r.nextInt(cols), _r.nextInt(rows));
      if (!taken.contains(c)) return c;
    }
  }

  void turn(int p, bool left) {
    if (pending[p].length >= 2) return;
    final base = pending[p].isEmpty ? dirs[p] : pending[p].last;
    pending[p].add(left ? turnLeft(base) : turnRight(base));
  }

  void boost(int p) {
    if (boostLeft[p] == 0 || boosting[p] > 0) return;
    sfx('tap');
    setState(() {
      boostLeft[p]--;
      boosting[p] = 8;
    });
  }

  void step() {
    if (msg != null) return;
    phase++;
    final movers = [for (var p = 0; p < 2; p++) if (phase.isEven || boosting[p] > 0) p];
    if (movers.isEmpty) return;
    final heads = <int, Cell?>{};
    for (final p in movers) {
      if (pending[p].isNotEmpty) dirs[p] = pending[p].removeAt(0);
      if (boosting[p] > 0) boosting[p]--;
      final h = gridStep(bodies[p].last, dirs[p], cols, rows, wrap: widget.wrap);
      heads[p] = h;
      if (h == null) continue;
      bodies[p].add(h);
      if (widget.tron) continue;
      if (h == food) {
        food = freeCell(); // grow: keep the tail
        sfx('tap');
        continue;
      }
      bodies[p].removeAt(0);
      if (h == poison) {
        for (var k = 0; k < 3 && bodies[p].length > 2; k++) {
          bodies[p].removeAt(0);
        }
        poison = freeCell();
        sfx('wrong');
      }
    }
    final count = <Cell, int>{};
    for (final b in bodies) {
      for (final c in b) {
        count[c] = (count[c] ?? 0) + 1;
      }
    }
    final crashed = <int>[];
    for (final p in movers) {
      final h = heads[p];
      if (h == null || blocks.contains(h) || count[h]! > 1) crashed.add(p);
    }
    setState(() {});
    if (crashed.isEmpty) return;
    sfx('wrong');
    final winner = crashed.length == 2 ? null : 1 - crashed.first;
    setState(() {
      if (winner != null) score[winner]++;
      msg = winner == null ? 'Both crashed!' : '${duelNames[winner]} takes the round';
    });
    if (winner != null && score[winner] == target) {
      showWinner(context, winner, () => setState(() {
            score.fillRange(0, 2, 0);
            startRound();
          }));
      return;
    }
    roundTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(startRound);
    });
  }

  void draw(Canvas c, Size s) {
    final cs = min(s.width / cols, s.height / rows), ox = (s.width - cs * cols) / 2, oy = (s.height - cs * rows) / 2;
    Rect cell(Cell k) => Rect.fromLTWH(ox + k.$1 * cs, oy + k.$2 * cs, cs, cs);
    final board = Rect.fromLTWH(ox, oy, cs * cols, cs * rows);
    c.drawRect(board, Paint()..color = const Color(0xFF0B1020));
    c.drawRect(board, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = widget.wrap ? Colors.greenAccent.withValues(alpha: .4) : Colors.white38);
    for (final b in blocks) {
      c.drawRect(cell(b).deflate(.5), Paint()..color = Colors.grey);
    }
    if (food != null) c.drawOval(cell(food!).deflate(cs * .15), Paint()..color = Colors.greenAccent);
    if (poison != null) c.drawOval(cell(poison!).deflate(cs * .15), Paint()..color = Colors.purpleAccent);
    for (var p = 0; p < 2; p++) {
      final body = bodies[p], trail = Paint()..color = duelColors[p].withValues(alpha: .8);
      for (var i = 0; i < body.length; i++) {
        final head = i == body.length - 1;
        c.drawRect(cell(body[i]).deflate(widget.tron && !head ? 0 : 1), head ? (Paint()..color = duelColors[p].shade100) : trail);
      }
    }
  }

  Widget controls(int p) {
    Widget btn(String label, VoidCallback onDown) => Expanded(
          child: GestureDetector(
            onTapDown: (_) => onDown(),
            child: Container(
              height: 64,
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: duelColors[p].withValues(alpha: .5), borderRadius: BorderRadius.circular(14)),
              child: Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            ),
          ),
        );
    return Row(children: [
      btn('◀', () => turn(p, true)),
      if (widget.boost) btn('⚡${boostLeft[p]}', () => boost(p)),
      btn('▶', () => turn(p, false)),
    ]);
  }

  @override
  Widget build(BuildContext context) => page(
        widget.title,
        Column(children: [
          facingTop(controls(1)),
          Expanded(
            child: Stack(children: [
              _canvas(draw),
              if (msg != null) Center(child: Column(mainAxisSize: MainAxisSize.min, children: [facingTop(_banner(msg!)), const SizedBox(height: 24), _banner(msg!)])),
            ]),
          ),
          controls(0),
        ]),
        '🔵 ${score[0]} – ${score[1]} 🔴 · to $target',
      );
}

// ---------- Tap battles ----------

class TapBattle extends StatefulWidget {
  const TapBattle(this.title, this.mode, {super.key});
  final String title, mode; // tug | race | hold | rhythm
  @override
  State<TapBattle> createState() => _TapBattleState();
}

class _TapBattleState extends State<TapBattle> with SingleTickerProviderStateMixin {
  static const beat = 600, beats = 16, lead = 3, holdRounds = 3;
  final sw = Stopwatch();
  final taps = [0, 0], score = [0, 0], points = [0, 0];
  final hitBeats = [<int>{}, <int>{}];
  final held = <double?>[null, null];
  final pressAt = <Duration?>[null, null];
  Ticker? ticker;
  Timer? next;
  double rope = 0, goal = 0; // rope: +1 Blue wins, -1 Red wins
  int lastBeat = -99;
  bool over = false;

  @override
  void initState() {
    super.initState();
    reset();
    if (widget.mode == 'rhythm') ticker = createTicker((_) => onBeatTick())..start();
  }

  @override
  void dispose() {
    ticker?.dispose();
    next?.cancel();
    super.dispose();
  }

  void reset() {
    taps.fillRange(0, 2, 0);
    score.fillRange(0, 2, 0);
    points.fillRange(0, 2, 0);
    hitBeats[0].clear();
    hitBeats[1].clear();
    rope = 0;
    lastBeat = -99;
    over = false;
    newHoldRound();
    sw
      ..reset()
      ..start();
  }

  void newHoldRound() {
    goal = 1.5 + _r.nextInt(26) / 10;
    held.fillRange(0, 2, null);
    pressAt.fillRange(0, 2, null);
  }

  void finish(int? w) {
    over = true;
    ticker?.stop();
    sw.stop();
    showWinner(context, w, () => setState(() {
          reset();
          ticker?.start();
        }));
  }

  void down(int pl) {
    if (over) return;
    switch (widget.mode) {
      case 'tug':
        setState(() => rope += pl == 0 ? .05 : -.05);
        if (rope.abs() >= 1) finish(rope > 0 ? 0 : 1);
      case 'race':
        setState(() => taps[pl]++);
        if (taps[pl] >= 100) finish(pl);
      case 'hold':
        if (held[pl] == null && pressAt[pl] == null) setState(() => pressAt[pl] = sw.elapsed);
      case 'rhythm':
        final t = sw.elapsedMilliseconds - lead * beat, k = (t / beat).round();
        if (k < 0 || k >= beats || !hitBeats[pl].add(k)) return;
        setState(() => points[pl] += max(0, 150 - (t - k * beat).abs()));
    }
  }

  void up(int pl) {
    final s = pressAt[pl];
    if (widget.mode != 'hold' || over || s == null || held[pl] != null) return;
    setState(() => held[pl] = (sw.elapsed - s).inMilliseconds / 1000);
    if (held[0] == null || held[1] == null) return;
    final e0 = (held[0]! - goal).abs(), e1 = (held[1]! - goal).abs();
    if (e0 != e1) score[e0 < e1 ? 0 : 1]++;
    sfx('right');
    if (score.contains(holdRounds)) {
      finish(score.indexOf(holdRounds));
      return;
    }
    next = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(newHoldRound);
    });
  }

  void onBeatTick() {
    final t = sw.elapsedMilliseconds - lead * beat, k = (t / beat).floor();
    if (k != lastBeat) {
      lastBeat = k;
      if (k < beats) sfx('tap');
    }
    if (k >= beats && !over) finish(points[0] == points[1] ? null : (points[0] > points[1] ? 0 : 1));
    setState(() {});
  }

  String text(int p) {
    switch (widget.mode) {
      case 'tug':
        return 'TAP FAST\nto pull the knot to your side!';
      case 'race':
        return '${taps[p]} / 100';
      case 'hold':
        final h = held[p], both = held[0] != null && held[1] != null;
        final line = h == null
            ? (pressAt[p] == null ? 'Hold for ${goal.toStringAsFixed(1)} s\nthen let go' : 'Holding…')
            : (both ? '${h.toStringAsFixed(2)} s  (target ${goal.toStringAsFixed(1)} s)' : 'Released!');
        return '$line\n\nRounds: ${score[p]} / $holdRounds';
      default:
        final k = ((sw.elapsedMilliseconds - lead * beat) / beat).floor() + 1;
        return '${k <= 0 ? 'Get ready… ${1 - k}' : 'Beat ${min(k, beats)} / $beats'}\nTap on the beat!\n${points[p]} pts';
    }
  }

  void draw(Canvas c, Size s) {
    final mid = Offset(s.width / 2, s.height / 2);
    switch (widget.mode) {
      case 'tug':
        c.drawLine(Offset(mid.dx, s.height * .05), Offset(mid.dx, s.height * .95), Paint()
          ..color = Colors.brown.shade300
          ..strokeWidth = 8);
        for (final y in [.075, .925]) {
          c.drawLine(Offset(mid.dx - 60, s.height * y), Offset(mid.dx + 60, s.height * y), Paint()
            ..color = Colors.white54
            ..strokeWidth = 3);
        }
        c.drawCircle(Offset(mid.dx, mid.dy + rope * s.height * .425), 18, Paint()..color = Colors.white);
      case 'race':
        for (var p = 0; p < 2; p++) {
          final f = taps[p] / 100 * s.height / 2;
          c.drawRect(p == 0 ? Rect.fromLTWH(0, s.height - f, 14, f) : Rect.fromLTWH(s.width - 14, 0, 14, f), Paint()..color = duelColors[p]);
        }
      case 'rhythm':
        final t = sw.elapsedMilliseconds % beat / beat;
        c.drawCircle(mid, 30 + 30 * (1 - t), Paint()..color = Colors.white.withValues(alpha: .3 + .5 * (1 - t)));
    }
  }

  @override
  Widget build(BuildContext context) => page(
        widget.title,
        _TouchSplit(
          onDown: (pl, _) => down(pl),
          onUp: up,
          child: Stack(children: [
            _halves((p) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(text(p), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                )),
            _canvas(draw),
          ]),
        ),
        '🔵 vs 🔴',
      );
}

// ---------- Reflex Duel ----------

typedef Stimulus = (String text, Color color, bool target);

const reflexWords = ['RED', 'BLUE', 'GREEN', 'YELLOW'];
const reflexInks = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
const reflexShapes = ['●', '■', '▲', '★'];

/// A random stimulus for the stroop / even / shape modes; about a third are targets.
Stimulus reflexStimulus(String mode, Random r) {
  final target = r.nextDouble() < .35, a = r.nextInt(4), b = target ? a : (a + 1 + r.nextInt(3)) % 4;
  switch (mode) {
    case 'stroop':
      return (reflexWords[a], reflexInks[b], target);
    case 'even':
      return ('${2 * (1 + r.nextInt(49)) - (target ? 0 : 1)}', Colors.white, target);
    default:
      return ('${reflexShapes[a]}  ${reflexShapes[b]}', Colors.white, target);
  }
}

class ReflexDuel extends StatefulWidget {
  const ReflexDuel(this.title, this.mode, {super.key});
  final String title, mode; // classic | stroop | even | shape
  @override
  State<ReflexDuel> createState() => _ReflexDuelState();
}

class _ReflexDuelState extends State<ReflexDuel> {
  static const target = 5;
  static const ready = ('GET READY', Colors.white70, false);
  final score = [0, 0];
  Stimulus stim = ready;
  String? msg;
  Timer? t;

  @override
  void initState() {
    super.initState();
    t = Timer(const Duration(seconds: 1), show);
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  void show() {
    if (!mounted) return;
    if (widget.mode == 'classic') {
      final go = stim.$1 == 'WAIT';
      setState(() => stim = go ? ('TAP!', Colors.greenAccent, true) : ('WAIT', Colors.redAccent, false));
      t = Timer(go ? const Duration(seconds: 2) : Duration(milliseconds: 1500 + _r.nextInt(3000)), show);
    } else {
      setState(() => stim = reflexStimulus(widget.mode, _r));
      t = Timer(const Duration(milliseconds: 1300), show);
    }
  }

  void restart() {
    msg = null;
    stim = ready;
    t = Timer(const Duration(seconds: 1), show);
  }

  void tap(int pl) {
    if (msg != null || stim == ready) return;
    t?.cancel();
    final hit = stim.$3, scorer = hit ? pl : 1 - pl;
    score[scorer]++;
    sfx(hit ? 'right' : 'wrong');
    setState(() => msg = hit ? '${duelNames[pl]} was fastest!' : '${duelNames[pl]} fell for it!');
    if (score[scorer] == target) {
      showWinner(context, scorer, () => setState(() {
            score.fillRange(0, 2, 0);
            restart();
          }));
      return;
    }
    t = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(restart);
    });
  }

  String get rule => switch (widget.mode) {
        'classic' => 'Tap when it turns GREEN',
        'stroop' => 'Tap when the INK matches the word',
        'even' => 'Tap on EVEN numbers',
        _ => 'Tap when both shapes MATCH',
      };

  @override
  Widget build(BuildContext context) => page(
        widget.title,
        _TouchSplit(
          onDown: (pl, _) => tap(pl),
          child: _halves((p) => Column(mainAxisSize: MainAxisSize.min, children: [
                Text(rule, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 16),
                msg == null
                    ? Text(stim.$1, style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: stim.$2))
                    : Text(msg!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('${score[p]} / $target', style: TextStyle(fontSize: 22, color: duelColors[p].shade200)),
              ])),
        ),
        '🔵 ${score[0]} – ${score[1]} 🔴',
      );
}
