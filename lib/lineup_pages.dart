import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'match_pages.dart';
import 'models.dart';
import 'widgets.dart';

const _kBlueBtn = Color(0xFFA9D4F8);
const _kInk = Color(0xFF15233D);

Widget blueBtn(String label, VoidCallback on, {IconData? icon}) => GestureDetector(
      onTap: on,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _kBlueBtn, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x4400A0FF), offset: Offset(0, 3))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 20, color: _kInk), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(color: _kInk, fontWeight: FontWeight.w900, fontSize: 15)),
        ]),
      ),
    );

/// شريط سفلي بزرين: ثانوي أزرق + رئيسي برتقالي
Widget twoButtons({required Widget secondary, required Widget primary}) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Row(children: [
          Expanded(flex: 2, child: secondary),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: primary),
        ]),
      ),
    );

/// شرائح التشكيلة 4-3-3 …
Widget formationChips(GameState gs) => SizedBox(
      height: 44,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final f in formations)
          GestureDetector(
            onTap: () => gs.setFormation(f),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: gs.user.formation == f ? kPrimary : kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: gs.user.formation == f ? kPrimary : kLine),
              ),
              child: Text(f.name, style: TextStyle(fontWeight: FontWeight.w900, color: gs.user.formation == f ? Colors.white : null)),
            ),
          ),
      ]),
    );

/// ملعب أخضر بشرائط، يضع اللاعبين حسب التشكيلة
class LineupPitch extends StatelessWidget {
  final Team team;
  final bool showRating;
  final void Function(int idx)? onTap;
  const LineupPitch({super.key, required this.team, this.showRating = true, this.onTap});

  /// صفوف الملعب من الهجوم إلى المرمى: (بداية الفهرس، العدد)
  List<(int, int)> rows() {
    final f = team.formation;
    final a0 = 1 + f.d + f.m, m0 = 1 + f.d;
    if (f.name == '4-2-3-1') return [(a0, 1), (m0 + 2, 3), (m0, 2), (1, f.d), (0, 1)];
    return [(a0, f.a), (m0, f.m), (1, f.d), (0, 1)];
  }

  @override
  Widget build(BuildContext context) {
    final rs = rows();
    return AspectRatio(
      aspectRatio: 0.84,
      child: LayoutBuilder(builder: (context, bc) {
        final w = bc.maxWidth, h = bc.maxHeight;
        final nodes = <Widget>[Positioned.fill(child: CustomPaint(painter: _PitchPaint()))];
        for (var r = 0; r < rs.length; r++) {
          final y = 0.11 + (0.80 * r / (rs.length - 1));
          for (var i = 0; i < rs[r].$2; i++) {
            final idx = rs[r].$1 + i;
            if (idx >= team.lineup.length) continue;
            final p = team.lineup[idx];
            final x = (i + 1) / (rs[r].$2 + 1);
            nodes.add(Positioned(
              left: x * w - 36,
              top: y * h - 24,
              width: 72,
              child: GestureDetector(
                onTap: onTap == null ? null : () => onTap!(idx),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Stack(clipBehavior: Clip.none, children: [
                    statusFace(p, 38, ring: Colors.white, ringWidth: 2),
                    if (showRating)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: ratingColor(p.overall), borderRadius: BorderRadius.circular(8)),
                          child: Text('${p.overall}', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text(p.name.split(' ').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w800)),
                  if (p.fitness < 70) Text('${p.fitness.round()}%', style: const TextStyle(fontSize: 9.5, color: Color(0xFFFFB199))),
                ]),
              ),
            ));
          }
        }
        return Unfilter(child: Stack(children: nodes));
      }),
    );
  }
}

class _PitchPaint extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final rr = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(14));
    c.save();
    c.clipRRect(rr);
    const bands = 8;
    for (var i = 0; i < bands; i++) {
      c.drawRect(Rect.fromLTWH(0, s.height / bands * i, s.width, s.height / bands + 1), Paint()..color = i.isEven ? const Color(0xFF2E9A52) : const Color(0xFF34A65A));
    }
    final line = Paint()
      ..color = const Color(0x99FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    c.drawRect(Rect.fromLTWH(10, 10, s.width - 20, s.height - 20), line);
    c.drawLine(Offset(10, s.height / 2), Offset(s.width - 10, s.height / 2), line);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.13, line);
    final bw = s.width * 0.5, bh = s.height * 0.15;
    c.drawRect(Rect.fromLTWH((s.width - bw) / 2, 10, bw, bh), line);
    c.drawRect(Rect.fromLTWH((s.width - bw) / 2, s.height - 10 - bh, bw, bh), line);
    final sw = s.width * 0.24, sh = s.height * 0.06;
    c.drawRect(Rect.fromLTWH((s.width - sw) / 2, 10, sw, sh), line);
    c.drawRect(Rect.fromLTWH((s.width - sw) / 2, s.height - 10 - sh, sw, sh), line);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ───────────────────────── صفحة التشكيلة ─────────────────────────

class LineupScreen extends StatelessWidget {
  final GameState gs;
  const LineupScreen({super.key, required this.gs});

  Widget _tile(String v, String l, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          child: Column(children: [
            Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c)),
            Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      );

  void _swapFromBench(BuildContext context, Player b) {
    final t = gs.user;
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      showDragHandle: true,
      builder: (ctx) => ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(14, 0, 14, 20), children: [
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('أدخل ${b.name} بدلاً من:', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
        for (var i = 0; i < t.lineup.length; i++)
          ListTile(
            dense: true,
            leading: PlayerAvatar(t.lineup[i]),
            title: Text(t.lineup[i].name),
            subtitle: Text(t.slots[i].label),
            onTap: () {
              gs.putInLineup(i, b);
              Navigator.pop(ctx);
            },
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: gameBar(context, gs, 'التشكيلة'),
        bottomNavigationBar: twoButtons(
          secondary: blueBtn('تلقائي', gs.autoPickUser, icon: Icons.bolt_rounded),
          primary: GradientButton(
            label: 'تأكيد التشكيلة',
            icon: Icons.check_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التشكيلة ✅')));
            },
          ),
        ),
        body: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final t = gs.user;
            final fit = t.lineup.isEmpty ? 0 : t.lineup.fold<double>(0, (a, p) => a + p.fitness) / t.lineup.length;
            final ovr = t.lineup.isEmpty ? 0 : t.lineup.fold<int>(0, (a, p) => a + p.overall) / t.lineup.length;
            final bench = t.bench.take(8).toList();
            return ListView(padding: const EdgeInsets.all(14), children: [
              formationChips(gs),
              const SizedBox(height: 12),
              Row(children: [
                _tile('${ovr.round()}', 'التقييم العام', ratingColor(ovr)),
                _tile('${t.cohesion.round()}%', 'الانسجام', const Color(0xFFF5A524)),
                _tile('${fit.round()}%', 'اللياقة', const Color(0xFF1FA58A)),
              ]),
              const SizedBox(height: 12),
              LineupPitch(team: t, onTap: (i) => pickPlayerForSlotSheet(context, gs, i)),
              const Padding(padding: EdgeInsets.fromLTRB(4, 14, 4, 8), child: Text('دكة البدلاء', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
              if (bench.isEmpty) const Text('لا بدلاء متاحون', style: TextStyle(color: kMuted)),
              SizedBox(
                height: 82,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final p in bench)
                    GestureDetector(
                      onTap: () => _swapFromBench(context, p),
                      child: Container(
                        width: 62,
                        margin: const EdgeInsets.only(left: 8),
                        child: Column(children: [
                          statusFace(p, 46, ring: posColor(p.pos), ringWidth: 2),
                          const SizedBox(height: 3),
                          Text(p.name.split(' ').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          Text('${p.overall}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: ratingColor(p.overall))),
                        ]),
                      ),
                    ),
                ]),
              ),
            ]);
          },
        ),
      );
}

void pickPlayerForSlotSheet(BuildContext context, GameState gs, int idx) {
  final slot = gs.user.slots[idx];
  final cands = gs.user.squad.where((p) => p.available).toList()
    ..sort((a, b) {
      final sa = a.pos == slot ? 0 : 1, sb = b.pos == slot ? 0 : 1;
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
        Padding(padding: const EdgeInsets.all(8), child: Text('اختر لاعباً لمركز ${slot.label}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
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
                  if (p.pos != slot) const Text('  • خارج مركزه', style: TextStyle(fontSize: 12, color: Color(0xFFFF8A65))),
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

// ───────────────────────── صفحة التكتيك ─────────────────────────

class TacticsScreen extends StatelessWidget {
  final GameState gs;
  const TacticsScreen({super.key, required this.gs});

  Widget _seg(List<String> labels, int value, ValueChanged<int> on) => Container(
        height: 44,
        decoration: BoxDecoration(border: Border.all(color: kPrimary), borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => on(i),
                child: Container(
                  alignment: Alignment.center,
                  color: value == i ? kPrimary : Colors.transparent,
                  child: Text(labels[i], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: value == i ? Colors.white : kPrimary)),
                ),
              ),
            ),
        ]),
      );

  Widget _sec(String t, Widget c) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(bottom: 6, right: 2), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
          c,
        ]),
      );

  Widget _fam(Team t) {
    final f = t.familiarity;
    final label = f >= 85 ? 'انسجام تكتيكي ممتاز' : (f >= 65 ? 'جيدة' : (f >= 45 ? 'متوسطة: الفريق ما زال يتعلّم' : 'ضعيفة: تغييرات كثيرة أربكت الفريق'));
    final c = f >= 65 ? const Color(0xFF1FA58A) : (f >= 45 ? const Color(0xFFF5A524) : const Color(0xFFE5533D));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: c))),
        Text('${f.round()}%', style: TextStyle(fontWeight: FontWeight.w900, color: c)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: f / 100, minHeight: 8, color: c, backgroundColor: kLine)),
      const SizedBox(height: 6),
      const Text('تتراكم الألفة بإبقاء الخطة والتشكيلة، وتنخفض عند تغيير الخطة (بقوة) أو تبديل اللاعبين الأساسيين. تؤثر بين -3.5% و+2% في قوة الفريق.', style: TextStyle(color: kMuted, fontSize: 11.5, height: 1.5)),
    ]);
  }

  Widget _roles(Team t) {
    final ps = [...t.lineup.where((p) => p.pos != Pos.gk)];
    return Column(children: [
      for (final p in ps)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5))),
            DropdownButton<String>(
              value: kRoles[t.roles[p.id]]?.$2 == p.pos ? t.roles[p.id] : '',
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(value: '', child: Text('عادي')),
                for (final e in kRoles.entries)
                  if (e.value.$2 == p.pos) DropdownMenuItem(value: e.key, child: Text(e.value.$1)),
              ],
              onChanged: (v) => gs.setRole(p, v == null || v.isEmpty ? null : v),
            ),
          ]),
        ),
      const Text('كل دور يعزّز جانباً ويُضعف آخر بنسبة صغيرة: صانع الألعاب يقوّي الوسط ويُضعف الدفاع، والظهير المهاجم يقوّي الهجوم ويترك مساحة خلفه.', style: TextStyle(color: kMuted, fontSize: 11.5, height: 1.5)),
    ]);
  }

  Widget _takers(Team t) {
    final ps = [...t.lineup.where((p) => p.pos != Pos.gk)];
    Widget row(String label, int kind, int cur) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5))),
            DropdownButton<int>(
              value: ps.any((p) => p.id == cur) ? cur : 0,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(value: 0, child: Text('تلقائي (الأفضل)')),
                for (final p in ps) DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => gs.setTaker(kind, v ?? 0),
            ),
          ]),
        );
    return Column(children: [
      row('ركلات الجزاء', 0, t.penTaker),
      row('الركلات الحرة', 1, t.fkTaker),
      row('الركنيات', 2, t.cornerTaker),
      const Text('إن غاب المنفّذ المحدد عن الملعب يُختار الأفضل تلقائياً. اختيار لاعب ضعيف يخفض احتمال التسجيل.', style: TextStyle(color: kMuted, fontSize: 11.5, height: 1.5)),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: gameBar(context, gs, 'التكتيك'),
        bottomNavigationBar: twoButtons(
          secondary: blueBtn('إعادة ضبط', () {
            final t = gs.user;
            gs.setMentality(2);
            gs.setPressing(1);
            gs.setTempo(1);
            gs.setWidth(1);
            gs.setDefLine(1);
            gs.setPassing(1);
            t.autoPick();
          }),
          primary: GradientButton(
            label: 'تطبيق التكتيك',
            icon: Icons.check_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تطبيق التكتيك ✅')));
            },
          ),
        ),
        body: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final t = gs.user;
            return ListView(padding: const EdgeInsets.all(14), children: [
              formationChips(gs),
              const SizedBox(height: 12),
              LineupPitch(team: t, showRating: false),
              _sec('العقلية', _seg(const ['دفاعية', 'حذرة', 'متوازنة', 'هجومية', 'شاملة'], t.mentality, gs.setMentality)),
              _sec('الضغط', _seg(const ['منخفض', 'متوسط', 'عالٍ'], t.pressing, gs.setPressing)),
              _sec('الإيقاع', _seg(const ['بطيء', 'عادي', 'سريع'], t.tempo, gs.setTempo)),
              _sec('العرض', _seg(const ['ضيّق', 'عادي', 'عريض'], t.width, gs.setWidth)),
              _sec('خط الدفاع', _seg(const ['عميق', 'عادي', 'مرتفع'], t.defLine, gs.setDefLine)),
              _sec('أسلوب التمرير', _seg(const ['قصير', 'مختلط', 'مباشر'], t.passing, gs.setPassing)),
              _sec('الألفة التكتيكية', _fam(t)),
              _sec('أدوار اللاعبين', _roles(t)),
              _sec('منفّذو الكرات الثابتة', _takers(t)),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text('الضغط العالي والإيقاع السريع يرفعان الفرص لكنهما يستنزفان اللياقة. الدفاع المرتفع يمنح سيطرة أكبر لكنه يترك مساحات خلفك.', style: TextStyle(color: kMuted, fontSize: 12, height: 1.5)),
              ),
            ]);
          },
        ),
      );
}
