import 'package:flutter/material.dart';
import 'game_state.dart';
import 'sponsors.dart';
import 'widgets.dart';

void _snack(BuildContext c, String? err, String ok) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err ?? ok)));

class SponsorsScreen extends StatelessWidget {
  final GameState gs;
  const SponsorsScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🤝 الرعاة'), backgroundColor: kBg),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
            Panel(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Column(children: [
                  Text('${wageK(gs.dealsIncome)}/جولة', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kAccent)),
                  const Text('دخل الرعاة', style: TextStyle(color: kMuted, fontSize: 11)),
                ]),
                Column(children: [
                  Text('${gs.fans.round()}%', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const Text('الشعبية', style: TextStyle(color: kMuted, fontSize: 11)),
                ]),
              ]),
            ),
            const Text('العلامات الكبرى تتطلب شعبية أعلى. العقود الأطول تمنح مكافأة توقيع.', style: TextStyle(color: kMuted, fontSize: 12)),
            for (final type in sponsorTypes.keys) ...[
              sectionTitle(sponsorTypes[type]!),
              ...() {
                final cur = gs.deals.where((d) => d.type == type).toList();
                if (cur.isNotEmpty) {
                  final d = cur.first;
                  return [
                    Panel(
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d.brand, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text('${wageK(d.weekly)} / جولة • متبقٍ ${d.years} ${d.years == 1 ? 'سنة' : 'سنوات'}',
                                style: const TextStyle(color: kMuted, fontSize: 12)),
                          ]),
                        ),
                        OutlinedButton(
                          onPressed: () => _snack(context, gs.cancelSponsor(d), 'تم إنهاء العقد'),
                          child: Text('إنهاء (${money2(gs.cancelCost(d))})'),
                        ),
                      ]),
                    ),
                  ];
                }
                final offers = gs.sponsorOffers[type] ?? const [];
                if (offers.isEmpty) {
                  return [const Panel(child: Text('لا عروض حالياً — تتجدد كل موسم', style: TextStyle(color: kMuted)))];
                }
                return [
                  for (final o in offers)
                    Panel(
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(o.deal.brand, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text(
                                '${wageK(o.deal.weekly)} / جولة • ${o.deal.years} ${o.deal.years == 1 ? 'سنة' : 'سنوات'}'
                                '${o.bonus > 0 ? ' • مكافأة ${money(o.bonus)}' : ''}',
                                style: const TextStyle(color: kMuted, fontSize: 12)),
                          ]),
                        ),
                        FilledButton(onPressed: () => _snack(context, gs.signSponsor(o), 'تم توقيع الصفقة ✅'), child: const Text('وقّع')),
                      ]),
                    ),
                ];
              }(),
            ],
          ]),
        ),
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
      appBar: AppBar(title: const Text('⚖️ اللعب المالي النظيف'), backgroundColor: kBg),
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
