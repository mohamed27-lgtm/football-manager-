import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'engine.dart';
import 'models.dart';
import 'widgets.dart';

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    const stripes = 10;
    final h = s.height / stripes;
    for (var i = 0; i < stripes; i++) {
      c.drawRect(
        Rect.fromLTWH(0, i * h, s.width, h),
        Paint()..color = i.isEven ? const Color(0xFF1B6B3A) : const Color(0xFF1F7A42),
      );
    }
    final line = Paint()
      ..color = const Color(0x99FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const m = 10.0;
    c.drawRect(Rect.fromLTWH(m, m, s.width - 2 * m, s.height - 2 * m), line);
    c.drawLine(Offset(m, s.height / 2), Offset(s.width - m, s.height / 2), line);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.13, line);
    c.drawCircle(Offset(s.width / 2, s.height / 2), 3, Paint()..color = const Color(0x99FFFFFF));
    final bw = s.width * 0.56, bh = s.height * 0.15;
    final sw = s.width * 0.26, sh = s.height * 0.06;
    final gw = s.width * 0.18;
    for (final top in [true, false]) {
      c.drawRect(Rect.fromLTWH((s.width - bw) / 2, top ? m : s.height - m - bh, bw, bh), line);
      c.drawRect(Rect.fromLTWH((s.width - sw) / 2, top ? m : s.height - m - sh, sw, sh), line);
      c.drawRect(
        Rect.fromLTWH((s.width - gw) / 2, top ? m - 7 : s.height - m, gw, 7),
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

typedef _Placed = ({Slot slot, double x, double y});

class LivePitch extends StatelessWidget {
  final MatchSim sim;
  final Duration anim;
  const LivePitch({super.key, required this.sim, required this.anim});

  List<_Placed> _layout(Side s) {
    final ballD = s.isHome ? 1 - sim.ballY : sim.ballY;
    const base = {Pos.gk: 0.05, Pos.def: 0.22, Pos.mid: 0.45, Pos.att: 0.68};
    final out = <_Placed>[];
    for (final pos in Pos.values) {
      final line = s.slots.where((e) => e.pos == pos).toList();
      for (var i = 0; i < line.length; i++) {
        final id = line[i].p.id;
        final shift = (pos == Pos.gk ? 0.05 : 0.3) * (ballD - 0.5);
        final d = (base[pos]! + shift + sin(sim.minute * 0.7 + id) * 0.012).clamp(0.03, 0.97).toDouble();
        final x = ((i + 1) / (line.length + 1)) * 0.82 +
            0.09 +
            (sim.ballX - 0.5) * 0.12 +
            cos(sim.minute * 0.5 + id) * 0.012;
        out.add((slot: line[i], x: x.clamp(0.06, 0.94).toDouble(), y: s.isHome ? 1 - d : d));
      }
    }
    return out;
  }

  Widget _dot(Slot sl, Color color, bool carrier, double r) {
    final isGk = sl.pos == Pos.gk;
    final nm = sl.p.name.split(' ').last;
    return OverflowBox(
      maxWidth: 80,
      maxHeight: 2 * r + 16,
      alignment: Alignment.topCenter,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _dotCircle(sl, color, carrier, r, isGk),
        SizedBox(
          width: 70,
          child: Text(
            nm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 3)]),
          ),
        ),
      ]),
    );
  }

  Widget _dotCircle(Slot sl, Color color, bool carrier, double r, bool isGk) {
    return Container(
      width: 2 * r,
      height: 2 * r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isGk ? const Color(0xFFFFB300) : color,
        border: Border.all(
          color: carrier ? const Color(0xFFFFEB3B) : Colors.white,
          width: carrier ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: carrier ? 8 : 2,
            color: carrier ? const Color(0xAAFFEB3B) : Colors.black45,
          ),
        ],
      ),
      child: Text(
        isGk ? 'GK' : '${sl.p.overall}',
        style: TextStyle(
          fontSize: r * 0.85,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: LayoutBuilder(builder: (context, cons) {
        final w = cons.maxWidth, h = cons.maxHeight;
        final r = (w * 0.032).clamp(10.0, 15.0).toDouble();
        final sides = [sim.home, sim.away];
        final layouts = [for (final s in sides) _layout(s)];

        // حامل الكرة: أقرب لاعب من الفريق المهاجم
        final attIdx = sim.attackHome ? 0 : 1;
        var carrierSlot = -1;
        var best = double.infinity;
        for (var i = 0; i < layouts[attIdx].length; i++) {
          final p = layouts[attIdx][i];
          if (p.slot.pos == Pos.gk) continue;
          final dx = (p.x - sim.ballX) * w, dy = (p.y - sim.ballY) * h;
          final dist = dx * dx + dy * dy;
          if (dist < best) {
            best = dist;
            carrierSlot = i;
          }
        }

        final nodes = <Widget>[
          Positioned.fill(child: CustomPaint(painter: _FieldPainter())),
        ];
        for (var si = 0; si < 2; si++) {
          var color = teamColor(sides[si].team.id);
          if (si == 1 && color == teamColor(sides[0].team.id)) {
            color = HSLColor.fromColor(color).withLightness(0.22).toColor();
          }
          for (var i = 0; i < layouts[si].length; i++) {
            final p = layouts[si][i];
            final isCarrier = si == attIdx && i == carrierSlot;
            var x = p.x, y = p.y;
            if (isCarrier) {
              x = sim.ballX;
              y = (sim.ballY + (sim.attackHome ? 0.018 : -0.018)).clamp(0.06, 0.94).toDouble();
            }
            nodes.add(AnimatedPositioned(
              key: ValueKey('p${p.slot.p.id}'),
              duration: anim,
              curve: Curves.easeInOut,
              left: x * w - r,
              top: y * h - r,
              width: 2 * r,
              height: 2 * r,
              child: _dot(p.slot, color, isCarrier, r),
            ));
          }
        }
        nodes.add(AnimatedPositioned(
          duration: anim,
          curve: Curves.easeInOut,
          left: sim.ballX * w - 6,
          top: sim.ballY * h - 6,
          width: 12,
          height: 12,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black87, width: 1.5),
              boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ));
        return Stack(children: nodes);
      }),
    );
  }
}
