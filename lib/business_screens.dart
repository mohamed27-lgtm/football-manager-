import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'sponsors.dart';
import 'widgets.dart';

void _snack(BuildContext c, String? err, String ok) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err ?? ok)));

class SponsorsScreen extends StatefulWidget {
  final GameState gs;
  const SponsorsScreen({super.key, required this.gs});
  @override
  State<SponsorsScreen> createState() => _SponsorsScreenState();
}

class _SponsorsScreenState extends State<SponsorsScreen> {
  int tab = 0;
  GameState get gs => widget.gs;

  Widget _tile(String v, String l, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          child: Column(children: [
            Text(v, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: c)),
            Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      );

  static const _cols = [Color(0xFFF5A524), Color(0xFF2F7BE6), Color(0xFF1FA58A), Color(0xFFE5533D), Color(0xFF6A6FC4)];

  Widget _logo(String brand, int i) {
    final c = _cols[i % _cols.length];
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
      child: Text(brand.isEmpty ? '?' : brand.characters.first.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: c)),
    );
  }

  Widget _row(Widget logo, String title, String sub, Widget trailing) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          logo,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          trailing,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرعاة')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => setState(() => tab = 2),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFA9D4F8), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x4400A0FF), offset: Offset(0, 3))]),
                  child: const Text('السجل', style: TextStyle(color: Color(0xFF15233D), fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: GradientButton(label: 'استعراض العروض', icon: Icons.star_border_rounded, onPressed: () => setState(() => tab = 1))),
          ]),
        ),
      ),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final types = sponsorTypes.keys.toList();
          final filled = gs.deals.length;
          final offerCount = [for (final t in types) ...(gs.sponsorOffers[t] ?? const [])].length;
          return ListView(padding: const EdgeInsets.all(14), children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: 0, label: Text('الحاليون')),
                ButtonSegment(value: 1, label: Text('العروض')),
                ButtonSegment(value: 2, label: Text('السجل')),
              ],
              selected: {tab},
              onSelectionChanged: (v) => setState(() => tab = v.first),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _tile('${wageK(gs.dealsIncome)}', 'الدخل/جولة', const Color(0xFF1FA58A)),
              _tile('$filled', 'العقود', kPrimary),
              _tile(gs.fans >= 70 ? 'ممتاز' : (gs.fans >= 45 ? 'جيد' : 'ضعيف'), 'رضا الرعاة', const Color(0xFFF5A524)),
            ]),
            if (tab == 0) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Row(children: [
                  const Text('مواقع الرعاية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  const Spacer(),
                  Text('$filled من ${types.length}', style: const TextStyle(color: kMuted)),
                ]),
              ),
              Container(
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (var i = 0; i < types.length; i++)
                    Builder(builder: (_) {
                      final cur = gs.deals.where((d) => d.type == types[i]).toList();
                      if (cur.isNotEmpty) {
                        final d = cur.first;
                        return _row(
                          _logo(d.brand, i),
                          d.brand,
                          '${sponsorTypes[types[i]]} • ${d.years} ${d.years == 1 ? 'سنة' : 'سنوات'}',
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('+${wageK(d.weekly)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1FA58A))),
                            GestureDetector(
                              onTap: () => _snack(context, gs.cancelSponsor(d), 'تم إنهاء العقد'),
                              child: const Text('إنهاء', style: TextStyle(color: kMuted, fontSize: 11.5)),
                            ),
                          ]),
                        );
                      }
                      final n = (gs.sponsorOffers[types[i]] ?? const []).length;
                      return Container(
                        color: kPrimary.withOpacity(0.06),
                        child: _row(
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(border: Border.all(color: kPrimary.withOpacity(0.4)), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.star_border_rounded, color: kPrimary),
                          ),
                          sponsorTypes[types[i]]!,
                          'موقع شاغر — $n عروض متاحة',
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(64, 34), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => setState(() => tab = 1),
                            child: const Text('اختر'),
                          ),
                        ),
                      );
                    }),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('الشعبية المطلوبة للعلامات الكبرى', style: TextStyle(fontWeight: FontWeight.w800))),
                    Text('${gs.fans.round()}%', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (gs.fans / 100).clamp(0, 1).toDouble(), minHeight: 8, color: const Color(0xFFF5A524), backgroundColor: kCard2)),
                  const SizedBox(height: 6),
                  const Text('العلامات الكبرى تتطلب شعبية أعلى. العقود الأطول تمنح مكافأة توقيع.', style: TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ),
            ],
            if (tab == 1) ...[
              if (offerCount == 0) const Padding(padding: EdgeInsets.only(top: 20), child: EmptyState(icon: Icons.handshake_outlined, title: 'لا عروض حالياً', subtitle: 'تتجدد العروض كل موسم.')),
              for (var i = 0; i < types.length; i++) ...[
                if ((gs.sponsorOffers[types[i]] ?? const []).isNotEmpty && gs.deals.every((d) => d.type != types[i])) ...[
                  Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(sponsorTypes[types[i]]!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                  Container(
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      for (final o in gs.sponsorOffers[types[i]]!)
                        _row(
                          _logo(o.deal.brand, i),
                          o.deal.brand,
                          '${o.deal.years} ${o.deal.years == 1 ? 'سنة' : 'سنوات'}${o.bonus > 0 ? ' • مكافأة ${money(o.bonus)}' : ''}',
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('+${wageK(o.deal.weekly)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1FA58A))),
                            const SizedBox(width: 10),
                            FilledButton(
                              style: FilledButton.styleFrom(minimumSize: const Size(60, 34), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () => _snack(context, gs.signSponsor(o), 'تم توقيع الصفقة ✅'),
                              child: const Text('وقّع'),
                            ),
                          ]),
                        ),
                    ]),
                  ),
                ],
              ],
            ],
            if (tab == 2) const Padding(padding: EdgeInsets.only(top: 20), child: EmptyState(icon: Icons.history_rounded, title: 'لا سجل بعد', subtitle: 'سيظهر هنا سجل عقود الرعاية السابقة.')),
          ]);
        },
      ),
    );
  }
}

class FfpScreen extends StatelessWidget {
  final GameState gs;
  const FfpScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚖️ اللعب المالي النظيف')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final r = gs.ffpRatio;
            final color = r > 0.85 ? const Color(0xFFFF7043) : (r > 0.7 ? const Color(0xFFFFCA28) : kAccent);
            return ListView(padding: const EdgeInsets.all(14), children: [
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('نسبة الرواتب إلى الإيرادات', style: TextStyle(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${(r * 100).round()}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: (r / 1.0).clamp(0, 1).toDouble(), minHeight: 10, color: color, backgroundColor: kCard2),
                  ),
                  const SizedBox(height: 8),
                  Text('الحد المسموح 85%. إيرادات الموسم ${money(gs.ffpRevenue)} • رواتب وطاقم ${money(gs.ffpWages)}',
                      style: const TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('المخالفات المتراكمة: ${gs.ffpBreaches}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (gs.transferBan)
                    const Padding(padding: EdgeInsets.only(top: 6), child: Text('⛔ أنت تحت حظر انتقالات', style: TextStyle(color: Color(0xFFFF8A65)))),
                  if (gs.pointsPenaltyNext > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('⛔ سيُخصم ${gs.pointsPenaltyNext} نقاط في الموسم القادم', style: const TextStyle(color: Color(0xFFFF8A65))),
                    ),
                ]),
              ),
              const Panel(
                child: Text(
                  'كيف تعمل العقوبات؟\n'
                  '• تُراجَع الحسابات في نهاية كل موسم.\n'
                  '• تجاوز 85%: غرامة مالية تتضاعف مع كل مخالفة.\n'
                  '• مخالفتان متتاليتان: حظر انتقالات في الصيف التالي.\n'
                  '• تجاوز 100% أو 3 مخالفات: خصم 6 نقاط من الدوري.\n'
                  '• الموسم النظيف يقلل عدد المخالفات.',
                  style: TextStyle(height: 1.7, fontSize: 13),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
