import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'widgets.dart';
import 'club_ui.dart';
import 'match_pages.dart';
import 'facilities_screen.dart';
import 'tickets_screen.dart';

String _n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

/// الملعب: مخطط المدرجات، الحالة، المشروع الجاري، المزايا وحقوق التسمية
class StadiumScreen extends StatelessWidget {
  final GameState gs;
  const StadiumScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameBar(context, gs, 'الملعب'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final lvl = gs.user.stadium;
            final cap = gs.stadiumCapacity;
            final pr = gs.projectOf('stadium');
            final tf = gs.ticketForecast(oppRep: gs.nextOppRep);
            final atmos = (gs.fans * 0.6 + tf.attendance / (cap == 0 ? 1 : cap) * 40).round().clamp(0, 100);
            final naming = gs.deals.where((d) => d.type == 'stadium').toList();
            final feats = <(IconData, Color, String, String, int)>[
              (Icons.tv_rounded, const Color(0xFF2F7BE6), 'الشاشة', lvl >= 2 ? 'شاشة LED عملاقة' : 'شاشة عادية', lvl),
              (Icons.bolt_rounded, const Color(0xFFF5A524), 'الإضاءة', lvl >= 3 ? 'ملعب ليلي • أجواء +${(lvl - 2) * 2}%' : 'إضاءة أساسية', lvl),
              (Icons.roofing_rounded, const Color(0xFF6A6FC4), 'السقف', 'تغطية ${(lvl * 20).clamp(0, 100)}% من المقاعد', lvl),
              (Icons.shield_outlined, const Color(0xFF1FA58A), 'الأمان', 'تصنيف ${const ['D', 'C', 'B', 'B', 'A', 'A'][lvl.clamp(0, 5)]}', lvl),
            ];
            return ListView(padding: const EdgeInsets.all(14), children: [
              CardBox(
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(gs.user.venue ?? 'ملعب ${gs.user.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(gs.user.name, style: const TextStyle(color: kMuted, fontSize: 12.5)),
                      ]),
                    ),
                    Pill('المستوى $lvl', const Color(0xFFB07A00)),
                  ]),
                  const SizedBox(height: 12),
                  const _Pitch(),
                  const SizedBox(height: 12),
                  Row(children: [
                    _stat(_n(cap), 'السعة', kPrimary),
                    _stat('$atmos', 'الأجواء', const Color(0xFF2F7BE6)),
                    _stat('${(tf.attendance * 100 / (cap == 0 ? 1 : cap)).round()}%', 'الإشغال', const Color(0xFF1FA58A)),
                    _stat(money(tf.revenue), 'دخل المباراة', const Color(0xFFF5A524)),
                  ]),
                ]),
              ),
              if (pr != null)
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectScreen(gs: gs, kind: 'stadium'))),
                  child: CardBox(
                    border: const Color(0xFFF5A524),
                    color: const Color(0xFFF5A524).withOpacity(0.08),
                    child: Column(children: [
                      Row(children: [
                        const IconBox(Icons.construction_rounded, Color(0xFFF5A524), size: 44),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('توسعة الملعب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            Text('إلى المستوى ${pr.toLevel} • السعة ${_n(12000 + 8000 * pr.toLevel)}', style: const TextStyle(color: kMuted, fontSize: 12)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('المتبقي', style: TextStyle(color: kMuted, fontSize: 11)),
                          Text(weeksText(pr.left), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB07A00))),
                        ]),
                      ]),
                      const SizedBox(height: 10),
                      Bar(pr.progress, const Color(0xFFF5A524), h: 9),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text('${(pr.progress * 100).round()}%', style: const TextStyle(color: kMuted, fontSize: 12)),
                        const Spacer(),
                        Text(pr.progress < 0.2 ? 'مرحلة الحفر' : (pr.progress < 0.45 ? 'مرحلة الأساسات' : (pr.progress < 0.75 ? 'مرحلة الهيكل' : 'التشطيب والفحص')), style: const TextStyle(color: kMuted, fontSize: 12)),
                      ]),
                    ]),
                  ),
                ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  for (final f in feats)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          IconBox(f.$1, f.$2, size: 32),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f.$3, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
                        ]),
                        const Spacer(),
                        LevelDots(level: f.$5, color: f.$2),
                        const SizedBox(height: 6),
                        Text(f.$4, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11.5)),
                      ]),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              CardBox(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(children: [
                  KvRow('حقوق تسمية الملعب', naming.isEmpty ? 'غير مُباع' : '${naming.first.brand}', sub: naming.isEmpty ? 'تُعرض عروض الرعاة في صفحة الرعاة' : 'متبقٍ ${naming.first.years} سنوات • ${money(naming.first.weekly * 52)} سنوياً', vc: naming.isEmpty ? kMuted : const Color(0xFF1FA58A)),
                  const Divider(height: 1, color: kLine),
                  KvRow('مشتركو بطاقات الموسم', _n(tf.subs), sub: 'معدل التجديد ${(gs.renewalRate * 100).round()}%'),
                  const Divider(height: 1, color: kLine),
                  KvRow('الصيانة الأسبوعية', money(0.03 * lvl + 0.04 * (pr == null ? 0 : 1))),
                ]),
              ),
              Row(children: [
                Expanded(child: blueBtn('التذاكر', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TicketsScreen(gs: gs))), icon: Icons.confirmation_number_outlined)),
                const SizedBox(width: 10),
                Expanded(child: GradientButton(label: 'المنشآت', icon: Icons.construction_rounded, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FacilitiesScreen(gs: gs))))),
              ]),
            ]);
          },
        ),
      ),
    );
  }

  Widget _stat(String v, String l, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: c))),
            Text(l, style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ),
      );
}

/// مخطط الملعب من الأعلى مع المدرجات الأربعة
class _Pitch extends StatelessWidget {
  const _Pitch();
  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 2.1,
        child: CustomPaint(painter: _PitchPainter()),
      );
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final bg = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(18));
    c.drawRRect(bg, Paint()..color = kNavy);
    RRect r(double l, double t, double w, double h) => RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), const Radius.circular(10));
    final pw = s.width, ph = s.height;
    // مدرجا الطول (الشعبي والشرفة)
    for (final y in [ph * 0.06, ph * 0.80]) {
      c.drawRRect(r(pw * 0.08, y, pw * 0.84, ph * 0.14), Paint()..color = const Color(0xFF6A6FC4));
      c.drawRRect(r(pw * 0.14, y + ph * 0.03, pw * 0.72, ph * 0.08), Paint()..color = const Color(0xFFF5A524));
    }
    c.drawRRect(r(pw * 0.01, ph * 0.22, pw * 0.08, ph * 0.56), Paint()..color = const Color(0xFFA9D4F8));
    c.drawRRect(r(pw * 0.91, ph * 0.22, pw * 0.08, ph * 0.56), Paint()..color = const Color(0xFFE5533D));
    final f = Rect.fromLTWH(pw * 0.13, ph * 0.23, pw * 0.74, ph * 0.54);
    c.drawRRect(RRect.fromRectAndRadius(f, const Radius.circular(8)), Paint()..color = const Color(0xFF21A988));
    final line = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 1.6;
    c.drawRRect(RRect.fromRectAndRadius(f, const Radius.circular(8)), line);
    c.drawLine(Offset(f.center.dx, f.top), Offset(f.center.dx, f.bottom), line);
    c.drawCircle(f.center, ph * 0.11, line);
    c.drawRect(Rect.fromLTWH(f.left, f.center.dy - ph * 0.12, pw * 0.07, ph * 0.24), line);
    c.drawRect(Rect.fromLTWH(f.right - pw * 0.07, f.center.dy - ph * 0.12, pw * 0.07, ph * 0.24), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
