import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';

class TacticsControls extends StatelessWidget {
  final GameState gs;
  final bool allowFormation;
  const TacticsControls({super.key, required this.gs, this.allowFormation = true});

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t, style: const TextStyle(color: kMuted, fontSize: 13)),
      );

  Widget _seg(List<String> labels, int value, ValueChanged<int> on) =>
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          for (var i = 0; i < labels.length; i++)
            ButtonSegment(value: i, label: Text(labels[i], style: const TextStyle(fontSize: 13))),
        ],
        selected: {value},
        onSelectionChanged: (s) => on(s.first),
      );

  Widget _row(String label, List<String> labels, int value, ValueChanged<int> on) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
          SizedBox(
            width: 230,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact, padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4))),
              segments: [for (var i = 0; i < labels.length; i++) ButtonSegment(value: i, label: Text(labels[i], style: const TextStyle(fontSize: 12.5)))],
              selected: {value},
              onSelectionChanged: (s) => on(s.first),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gs,
      builder: (context, _) {
        final t = gs.user;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (allowFormation) ...[
            _label('التشكيلة'),
            Wrap(spacing: 8, children: [
              for (final f in formations)
                ChoiceChip(
                  label: Text(f.name),
                  selected: t.formation == f,
                  onSelected: (_) => gs.setFormation(f),
                ),
            ]),
          ],
          _label('العقلية'),
          _seg(['دفاعية', 'حذرة', 'متوازنة', 'هجومية', 'شاملة'], t.mentality, gs.setMentality),
          const SizedBox(height: 10),
          _row('الضغط', ['منخفض', 'متوسط', 'عالٍ'], t.pressing, gs.setPressing),
          _row('الإيقاع', ['بطيء', 'عادي', 'سريع'], t.tempo, gs.setTempo),
          _row('العرض', ['ضيّق', 'عادي', 'واسع'], t.width, gs.setWidth),
          _row('خط الدفاع', ['عميق', 'عادي', 'مرتفع'], t.defLine, gs.setDefLine),
          _row('أسلوب التمرير', ['قصير', 'مختلط', 'مباشر'], t.passing, gs.setPassing),
          const SizedBox(height: 8),
          const Text(
            'الضغط العالي والإيقاع السريع يرفعان السيطرة والفرص، لكنهما يستنزفان اللياقة ويزيدان الإنذارات.\n'
            '• اللعب العريض والتمرير المباشر: فرص أكثر لكن بدقة أقل.\n'
            '• الدفاع المرتفع: سيطرة أكبر في الوسط، لكنه يترك مساحات خلفك للهجمات المرتدة.\n'
            '• الدفاع المنخفض: يحمي مرماك لكنه يمنح الخصم الكرة.',
            style: TextStyle(color: kMuted, fontSize: 12, height: 1.5),
          ),
        ]);
      },
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF14532D), Color(0xFF166534)],
      ).createShader(Offset.zero & s);
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(14)), bg);
    final line = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    c.drawRect(Rect.fromLTWH(8, 8, s.width - 16, s.height - 16), line);
    c.drawLine(Offset(8, s.height / 2), Offset(s.width - 8, s.height / 2), line);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.12, line);
    final bw = s.width * 0.5, bh = s.height * 0.14;
    c.drawRect(Rect.fromLTWH((s.width - bw) / 2, 8, bw, bh), line);
    c.drawRect(Rect.fromLTWH((s.width - bw) / 2, s.height - 8 - bh, bw, bh), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// مواضع اللاعبين على الملعب (نسب 0..1): الهجوم أعلى والحارس أسفل
List<Offset> pitchSpots(Formation f, int count) {
  final groups = <(double, int, int)>[
    (0.13, 1 + f.d + f.m, f.a),
    (0.40, 1 + f.d, f.m),
    (0.67, 1, f.d),
    (0.89, 0, 1),
  ];
  final out = List<Offset>.filled(count, Offset.zero);
  for (final g in groups) {
    for (var i = 0; i < g.$3; i++) {
      final idx = g.$2 + i;
      if (idx < count) out[idx] = Offset((i + 1) / (g.$3 + 1), g.$1);
    }
  }
  return out;
}

class PitchView extends StatelessWidget {
  final Team team;
  final void Function(int idx)? onTap;

  /// رسم تكتيكي يوضع تحت اللاعبين، وعناصر تفاعلية فوقهم (للصفحة التكتيكية فقط)
  final CustomPainter? under;
  final List<Widget> Function(double w, double h)? over;
  final bool showRoles;
  const PitchView({super.key, required this.team, this.onTap, this.under, this.over, this.showRoles = false});

  @override
  Widget build(BuildContext context) {
    final f = team.formation;
    // (y, أول فهرس، العدد)
    final groups = <(double, int, int)>[
      (0.13, 1 + f.d + f.m, f.a),
      (0.40, 1 + f.d, f.m),
      (0.67, 1, f.d),
      (0.89, 0, 1),
    ];
    return AspectRatio(
      aspectRatio: 0.78,
      child: LayoutBuilder(builder: (context, cons) {
        final w = cons.maxWidth, h = cons.maxHeight;
        const nodeW = 64.0;
        final nodes = <Widget>[
          Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
          if (under != null) Positioned.fill(child: CustomPaint(painter: under)),
        ];
        for (final g in groups) {
          for (var i = 0; i < g.$3; i++) {
            final idx = g.$2 + i;
            if (idx >= team.lineup.length) continue;
            final p = team.lineup[idx];
            final x = (i + 1) / (g.$3 + 1);
            nodes.add(Positioned(
              left: x * w - nodeW / 2,
              top: g.$1 * h - 26,
              width: nodeW,
              child: GestureDetector(
                onTap: onTap == null ? null : () => onTap!(idx),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: posColor(p.pos),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text('${p.overall}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                  ),
                  const SizedBox(height: 2),
                  Text(p.name.split(' ').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  if (showRoles && team.roles[p.id] != null && kRoles[team.roles[p.id]] != null)
                    Text(kRoles[team.roles[p.id]]!.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: Color(0xFFFFEB3B), fontWeight: FontWeight.w700))
                  else
                    Text('${p.fitness.round()}%',
                        style: TextStyle(
                            fontSize: 10,
                            color: p.fitness < 70 ? const Color(0xFFFF8A65) : Colors.white70)),
                ]),
              ),
            ));
          }
        }
        if (over != null) nodes.addAll(over!(w, h));
        return Stack(children: nodes);
      }),
    );
  }
}

void pickPlayerForSlot(BuildContext context, GameState gs, int idx) {
  final slot = gs.user.slots[idx];
  final cands = gs.user.squad.where((p) => p.available).toList()
    ..sort((a, b) {
      final sa = a.pos == slot ? 0 : 1;
      final sb = b.pos == slot ? 0 : 1;
      if (sa != sb) return sa.compareTo(sb);
      return b.effective.compareTo(a.effective);
    });
  showModalBottomSheet(
    context: context,
    backgroundColor: kCard,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.65,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('اختر لاعباً لمركز ${slot.label}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: ListView(children: [
            for (final p in cands)
              ListTile(
                leading: PlayerAvatar(p),
                title: Text(p.name),
                subtitle: Row(children: [
                  PosChip(p.pos),
                  const SizedBox(width: 8),
                  Text('لياقة ${p.fitness.round()}%', style: const TextStyle(fontSize: 12)),
                  if (p.pos != slot)
                    const Text('  • خارج مركزه', style: TextStyle(fontSize: 12, color: Color(0xFFFF8A65))),
                ]),
                trailing: gs.user.lineup.contains(p) ? const Icon(Icons.check, color: kAccent) : null,
                onTap: () {
                  gs.putInLineup(idx, p);
                  Navigator.pop(ctx);
                },
              ),
          ]),
        ),
      ]),
    ),
  );
}

const _kDefY = [0.80, 0.69, 0.57]; // موضع خط الدفاع: عميق، عادي، مرتفع
const _kPressY = [0.55, 0.40, 0.22]; // أعلى حدود الضغط: منخفض، متوسط، عالٍ

/// رسم الخطوط التكتيكية فوق الملعب: منطقة الضغط، خط الدفاع، ممرات العرض، أسهم التمرير والأدوار
class TacticsOverlayPainter extends CustomPainter {
  final Team t;
  TacticsOverlayPainter(this.t);

  void _dash(Canvas c, Offset a, Offset b, Paint p) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    final u = d / len;
    for (var x = 0.0; x < len; x += 11) {
      c.drawLine(a + u * x, a + u * min(x + 6, len), p);
    }
  }

  void _arrow(Canvas c, Offset a, Offset b, Paint p) {
    c.drawLine(a, b, p);
    final d = (b - a);
    if (d.distance < 6) return;
    final u = d / d.distance;
    final n = Offset(-u.dy, u.dx);
    final h = Path()
      ..moveTo(b.dx, b.dy)
      ..lineTo(b.dx - u.dx * 8 + n.dx * 4, b.dy - u.dy * 8 + n.dy * 4)
      ..lineTo(b.dx - u.dx * 8 - n.dx * 4, b.dy - u.dy * 8 - n.dy * 4)
      ..close();
    c.drawPath(h, Paint()..color = p.color..style = PaintingStyle.fill);
  }

  void _label(Canvas c, String s, Offset at, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: col, fontSize: 10.5, fontWeight: FontWeight.w800, shadows: const [Shadow(color: Colors.black87, blurRadius: 3)])),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(c, at);
  }

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // منطقة الضغط: من مرمى الخصم حتى حدّ الضغط
    final py = _kPressY[t.pressing.clamp(0, 2)] * h;
    c.drawRect(Rect.fromLTWH(8, 8, w - 16, py - 8), Paint()..color = const Color(0x33E5533D));
    _dash(c, Offset(8, py), Offset(w - 8, py), Paint()..color = const Color(0xCCFF8A65)..strokeWidth = 1.5);
    _label(c, 'بداية الضغط', Offset(12, py - 14), const Color(0xFFFFAB91));
    // ممرات العرض
    final half = [0.22, 0.38, 0.47][t.width.clamp(0, 2)];
    final lane = Paint()..color = const Color(0x99B3E5FC)..strokeWidth = 1.5;
    for (final sgn in [-1, 1]) {
      final x = w * (0.5 + sgn * half);
      _dash(c, Offset(x, h * 0.18), Offset(x, h * 0.82), lane);
      _arrow(c, Offset(x - sgn * 16, h * 0.5), Offset(x + sgn * 4, h * 0.5), lane);
    }
    _label(c, 'عرض اللعب', Offset(w * 0.5 - 22, h * 0.5 + 18), const Color(0xFFB3E5FC));
    // خط الدفاع
    final dy = _kDefY[t.defLine.clamp(0, 2)] * h;
    final dl = Paint()..color = const Color(0xFFFFEB3B)..strokeWidth = 2.2;
    _dash(c, Offset(8, dy), Offset(w - 8, dy), dl);
    _label(c, 'خط الدفاع', Offset(w - 70, dy - 14), const Color(0xFFFFEB3B));
    // أسهم التمرير: قصير بين الخطوط المتجاورة، مباشر من الدفاع إلى الهجوم
    final spots = pitchSpots(t.formation, t.lineup.length);
    final f = t.formation;
    List<int> rng(int a, int n) => [for (var i = 0; i < n; i++) a + i];
    final att = rng(1 + f.d + f.m, f.a), mid = rng(1 + f.d, f.m), def = rng(1, f.d);
    Offset at(int i) => Offset(spots[i].dx * w, spots[i].dy * h);
    final pass = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1.2 + t.tempo * 0.7;
    void link(List<int> from, List<int> to) {
      for (final a in from) {
        if (to.isEmpty) continue;
        var best = to.first;
        for (final b in to) {
          if ((spots[b].dx - spots[a].dx).abs() < (spots[best].dx - spots[a].dx).abs()) best = b;
        }
        final A = at(a), B = at(best);
        final u = (B - A) / (B - A).distance;
        _arrow(c, A + u * 22, B - u * 24, pass);
      }
    }
    if (t.passing <= 1) {
      link(def, mid);
      link(mid, att);
    }
    if (t.passing >= 1) {
      final long = Paint()..color = const Color(0xCCFFEB3B)..strokeWidth = 1.2 + t.tempo * 0.7;
      for (final a in def) {
        if (att.isEmpty) continue;
        var best = att.first;
        for (final b in att) {
          if ((spots[b].dx - spots[a].dx).abs() < (spots[best].dx - spots[a].dx).abs()) best = b;
        }
        final A = at(a), B = at(best);
        final u = (B - A) / (B - A).distance;
        _dash(c, A + u * 22, B - u * 26, long);
      }
    }
    // أسهم الأدوار الفردية
    for (var i = 0; i < t.lineup.length && i < spots.length; i++) {
      final r = t.roles[t.lineup[i].id];
      if (r == null) continue;
      final A = at(i);
      final v = switch (r) {
        'attfb' || 'poacher' || 'targetman' => const Offset(0, -34),
        'falsenine' => const Offset(0, 30),
        'playmaker' => const Offset(0, 28),
        'box2box' => const Offset(0, -30),
        'ballwinner' || 'stopper' => const Offset(0, 28),
        _ => Offset.zero,
      };
      if (v != Offset.zero) _arrow(c, A + Offset(26, v.dy < 0 ? -6 : 6), A + Offset(26, v.dy), Paint()..color = const Color(0xFFFFEB3B)..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant TacticsOverlayPainter old) => true;
}

Widget _lineHandle(double w, double h, double y, Color col, String label, List<double> ys, void Function(int) set, {bool right = false}) {
  return Positioned(
    left: right ? null : 2,
    right: right ? 2 : null,
    top: y * h - 16,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) {
        final ny = (y * h + d.delta.dy) / h;
        var best = 0;
        for (var i = 1; i < ys.length; i++) {
          if ((ys[i] - ny).abs() < (ys[best] - ny).abs()) best = i;
        }
        set(best);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.unfold_more, size: 14, color: Colors.black87),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87)),
        ]),
      ),
    ),
  );
}

class TacticsTab extends StatelessWidget {
  final GameState gs;
  const TacticsTab({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    final t = gs.user;
    return ListView(padding: const EdgeInsets.all(14), children: [
      Panel(
        child: Column(children: [
          Row(children: [
            Text('التشكيلة ${t.formation.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: gs.autoPickUser,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('اختيار تلقائي'),
            ),
          ]),
          ListenableBuilder(
            listenable: gs,
            builder: (context, _) => PitchView(
              team: t,
              showRoles: true,
              under: TacticsOverlayPainter(t),
              onTap: (i) => pickPlayerForSlot(context, gs, i),
              over: (w, h) => [
                _lineHandle(w, h, _kDefY[t.defLine.clamp(0, 2)], const Color(0xFFFFEB3B), 'خط الدفاع', _kDefY, gs.setDefLine),
                _lineHandle(w, h, _kPressY[t.pressing.clamp(0, 2)], const Color(0xFFFF8A65), 'الضغط', _kPressY, gs.setPressing, right: true),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text('اضغط على أي لاعب لتغييره • اسحب المقبضين الجانبيين لتحريك خط الدفاع وحدّ الضغط', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('أبيض: تمريرات قصيرة • أصفر متقطع: تمريرات مباشرة • أحمر: منطقة الضغط • أزرق: ممرات العرض', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 11)),
        ]),
      ),
      Panel(child: TacticsControls(gs: gs)),
    ]);
  }
}
