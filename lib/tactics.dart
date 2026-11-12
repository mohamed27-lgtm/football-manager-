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

class PitchView extends StatelessWidget {
  final Team team;
  final void Function(int idx)? onTap;
  const PitchView({super.key, required this.team, this.onTap});

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
                  Text('${p.fitness.round()}%',
                      style: TextStyle(
                          fontSize: 10,
                          color: p.fitness < 70 ? const Color(0xFFFF8A65) : Colors.white70)),
                ]),
              ),
            ));
          }
        }
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
          PitchView(team: t, onTap: (i) => pickPlayerForSlot(context, gs, i)),
          const SizedBox(height: 6),
          const Text('اضغط على أي لاعب لتغييره', style: TextStyle(color: kMuted, fontSize: 12)),
        ]),
      ),
      Panel(child: TacticsControls(gs: gs)),
    ]);
  }
}
