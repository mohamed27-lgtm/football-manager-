import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'sponsors.dart';
import 'widgets.dart';
import 'club_ui.dart';
import 'match_pages.dart';

const _typeIcons = {'shirt': Icons.checkroom_rounded, 'kit': Icons.star_rounded, 'stadium': Icons.home_rounded};
const _typeCols = {'shirt': Color(0xFF2F7BE6), 'kit': Color(0xFFF5A524), 'stadium': Color(0xFF6A6FC4)};

class SponsorsScreen extends StatefulWidget {
  final GameState gs;
  const SponsorsScreen({super.key, required this.gs});
  @override
  State<SponsorsScreen> createState() => _SponsorsScreenState();
}

class _SponsorsScreenState extends State<SponsorsScreen> {
  GameState get gs => widget.gs;

  String _yr(int y) => y == 1 ? 'سنة' : (y == 2 ? 'سنتان' : '$y سنوات');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameBar(context, gs, 'الرعاة'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final types = sponsorTypes.keys.toList();
            final rounds = gs.rounds.isEmpty ? 38 : gs.rounds.length;
            final yearly = gs.dealsIncome * rounds;
            final offers = [for (final t in types) if (gs.deals.every((d) => d.type != t)) ...(gs.sponsorOffers[t] ?? const <SponsorOffer>[])];
            return ListView(padding: const EdgeInsets.all(14), children: [
              StatTiles([
                ('${offers.length}', 'عروض جديدة', kPrimary),
                ('${gs.deals.length}', 'عقود فعّالة', const Color(0xFF1FA58A)),
                (money(yearly), 'إيراد الرعاة/سنة', const Color(0xFF1FA58A)),
              ]),
              CardBox(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (final e in types.indexed) ...[
                    if (e.$1 > 0) const Divider(height: 1, color: kLine),
                    _slot(context, e.$2),
                  ],
                ]),
              ),
              if (offers.isNotEmpty) const SectionTitle('عروض جديدة'),
              for (final t in types)
                if (gs.deals.every((d) => d.type != t))
                  for (final o in gs.sponsorOffers[t] ?? const <SponsorOffer>[]) _offer(context, o),
              if (offers.isEmpty) const CardBox(child: Text('لا عروض حالياً. تتجدد العروض كل موسم، وترتفع جودتها مع الشعبية والنتائج.', style: TextStyle(color: kMuted, height: 1.5))),
              CardBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('الشعبية المطلوبة للعلامات الكبرى', style: TextStyle(fontWeight: FontWeight.w800))),
                    Text('${gs.fans.round()}%', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 8),
                  Bar(gs.fans / 100, const Color(0xFFF5A524)),
                  const SizedBox(height: 6),
                  const Text('العلامات الكبرى تتطلب شعبية أعلى، والعقود الأطول تمنح مكافأة توقيع.', style: TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _slot(BuildContext context, String type) {
    final cur = gs.deals.where((d) => d.type == type).toList();
    final col = _typeCols[type] ?? kPrimary;
    final rounds = gs.rounds.isEmpty ? 38 : gs.rounds.length;
    if (cur.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconBox(_typeIcons[type] ?? Icons.star_rounded, kMuted, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sponsorTypes[type]!, style: const TextStyle(color: kMuted, fontSize: 12)),
              const Text('موقع شاغر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('${(gs.sponsorOffers[type] ?? const []).length} عروض متاحة', style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
        ]),
      );
    }
    final d = cur.first;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        IconBox(_typeIcons[type] ?? Icons.star_rounded, col, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sponsorTypes[type]!, style: const TextStyle(color: kMuted, fontSize: 12)),
            Text(d.brand, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            GestureDetector(
              onTap: () => snack(context, gs.cancelSponsor(d) ?? 'تم إنهاء العقد'),
              child: Text('إنهاء العقد (${money(gs.cancelCost(d))})', style: const TextStyle(color: kPrimary, fontSize: 11.5)),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(money(d.weekly * rounds), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          Text('متبقٍ ${_yr(d.years)}', style: const TextStyle(color: kMuted, fontSize: 11.5)),
        ]),
      ]),
    );
  }

  Widget _offer(BuildContext context, SponsorOffer o) {
    final rounds = gs.rounds.isEmpty ? 38 : gs.rounds.length;
    final col = _typeCols[o.deal.type] ?? kPrimary;
    return CardBox(
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(sponsorTypes[o.deal.type]!, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12)),
              ]),
              const SizedBox(height: 2),
              Text(o.deal.brand, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              Text('${_yr(o.deal.years)}${o.bonus > 0 ? ' • مكافأة ${money(o.bonus)}' : ''}', style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${money(o.deal.weekly * rounds)}/سنة', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1FA58A))),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(70, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => snack(context, gs.declineSponsor(o) ?? 'رفضت العرض'),
            child: const Text('رفض'),
          ),
          const SizedBox(width: 8),
          Expanded(child: blueBtnS('تفاوض', () => snack(context, gs.negotiateSponsor(o) ?? 'جرى التفاوض'))),
          const SizedBox(width: 8),
          Expanded(child: GradientButton(label: 'قبول', onPressed: () => snack(context, gs.signSponsor(o) ?? 'تم توقيع الصفقة ✅'))),
        ]),
      ]),
    );
  }

  Widget blueBtnS(String l, VoidCallback on) => GestureDetector(
        onTap: on,
        child: Container(height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFA9D4F8), borderRadius: BorderRadius.circular(12)), child: Text(l, style: const TextStyle(color: Color(0xFF15233D), fontWeight: FontWeight.w900))),
      );
}

class FfpScreen extends StatelessWidget {
  final GameState gs;
  const FfpScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameBar(context, gs, 'اللعب المالي النظيف'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final r = gs.ffpRatio;
            final b = gs.ffpBreaches;
            final score = (100 - (r > 0.6 ? (r - 0.6) / 0.4 * 70 : 0) - b * 8 - (gs.transferBan ? 10 : 0)).round().clamp(0, 100);
            final ok = score >= 75;
            final col = score >= 75 ? const Color(0xFF1FA58A) : (score >= 50 ? const Color(0xFFF5A524) : const Color(0xFFE5533D));
            final wk = gs.week < 1 ? 1 : gs.week;
            final total = gs.rounds.isEmpty ? 38 : gs.rounds.length;
            final projRev = gs.ffpRevenue / wk * total;
            final projWages = gs.ffpWages / wk * total;
            final room = 0.85 * projRev - projWages;
            final net = (gs.fin.season['purchases'] ?? 0) - (gs.fin.season['sales'] ?? 0);
            Widget ind(String l, String sub, double v, double limit, Color c, String right) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: Text(l, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
                      Text(right, style: const TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                    const SizedBox(height: 6),
                    Bar(limit == 0 ? 0 : v / limit, c, h: 9),
                    Align(alignment: AlignmentDirectional.centerStart, child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(sub, style: const TextStyle(color: kMuted, fontSize: 11.5)))),
                  ]),
                );
            return ListView(padding: const EdgeInsets.all(14), children: [
              CardBox(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ok ? 'ملتزم باللعب المالي النظيف' : (score >= 50 ? 'قريب من الحد' : 'مخالفة مالية'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: col)),
                      const SizedBox(height: 4),
                      Text('المراجعة في نهاية الموسم • الموسم ${gs.season}', style: const TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ),
                  Ring(value: score / 100, big: '$score', small: 'الالتزام', color: col, size: 108),
                ]),
              ),
              CardBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('المؤشرات الرئيسية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ind('الأجور من الإيرادات', 'الحد 85%', r, 0.85, r > 0.85 ? const Color(0xFFE5533D) : (r > 0.72 ? const Color(0xFFF5A524) : const Color(0xFF1FA58A)), '${(r * 100).round()}%'),
                  ind('المخالفات المتراكمة', 'الحد 3 مخالفات', b.toDouble(), 3, b >= 2 ? const Color(0xFFE5533D) : const Color(0xFF1FA58A), '$b'),
                  ind('صافي إنفاق الانتقالات (الموسم)', 'مؤشر للمتابعة فقط', net.clamp(0, 999).toDouble(), 80, const Color(0xFF2F7BE6), money(net)),
                ]),
              ),
              if (r > 0.72)
                CardBox(
                  color: const Color(0xFFFFF4D6),
                  border: const Color(0xFFF5A524),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFB07A00)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('الأجور ${(r * 100).round()}% من الإيرادات وتقترب من الحد (85%). أي صفقة جديدة قد ترفعها.', style: const TextStyle(color: Color(0xFF5B4300), fontWeight: FontWeight.w700, height: 1.4))),
                  ]),
                ),
              CardBox(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(children: [
                  KvRow('عقوبة تجاوز الحد', gs.transferBan ? 'حظر انتقالات' : (gs.pointsPenaltyNext > 0 ? 'خصم ${gs.pointsPenaltyNext} نقاط' : 'غرامة + حظر + خصم نقاط'), vc: gs.transferBan || gs.pointsPenaltyNext > 0 ? const Color(0xFFE5533D) : null),
                  const Divider(height: 1, color: kLine),
                  KvRow('المساحة المتاحة للأجور', room >= 0 ? '${money(room)} سنوياً' : '−${money(-room)}', vc: room >= 0 ? const Color(0xFF1FA58A) : const Color(0xFFE5533D), sub: 'متوقعة حتى نهاية الموسم'),
                  const Divider(height: 1, color: kLine),
                  KvRow('إيراد الرعاية هذا الموسم', money(gs.fin.season['sponsor'] ?? 0)),
                ]),
              ),
              const CardBox(
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
