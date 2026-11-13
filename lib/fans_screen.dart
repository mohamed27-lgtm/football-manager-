import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'club_screens.dart';
import 'game_state.dart';
import 'match_pages.dart';
import 'stadium_screen.dart';
import 'tickets_screen.dart';
import 'widgets.dart';
import 'club_ui.dart';

/// الجماهير: قاعدة الجماهير، النمو، الأعمار، الحملات
class FansScreen extends StatelessWidget {
  final GameState gs;
  const FansScreen({super.key, required this.gs});

  String _m(double v) => v >= 1 ? '${v.toStringAsFixed(1)}M' : '${(v * 1000).round()}K';

  Widget _want(String label, double pct) {
    final c = pct >= 70 ? const Color(0xFF1FA58A) : (pct >= 45 ? const Color(0xFF2F7BE6) : const Color(0xFFF5A524));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
        Expanded(child: Bar(pct / 100, c, h: 7)),
        const SizedBox(width: 10),
        SizedBox(width: 40, child: Text('${pct.round()}%', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: gameBar(context, gs, 'الجماهير'),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: gs,
            builder: (context, _) {
              final g = gs.seasonGrowth;
              final hist = [...gs.fanHist, gs.fans];
              final last = hist.length > 6 ? hist.sublist(hist.length - 6) : hist;
              final firstSeason = gs.season - last.length + 1;
              final ages = gs.fanAges;
              final young = gs.user.squad.where((p) => p.age <= 23).length;
              final att = (55 + (gs.user.mentality - 2) * 14).toDouble();
              final yng = (young * 100 / (gs.user.squad.isEmpty ? 1 : gs.user.squad.length) * 2.2).clamp(5, 100).toDouble();
              final cheap = (100 - gs.priceIndex * 60).clamp(5, 95).toDouble();
              final mx = last.reduce((a, b) => a > b ? a : b);
              final mn = last.reduce((a, b) => a < b ? a : b);
              return ListView(padding: const EdgeInsets.all(14), children: [
                StatTiles([
                  ('${g >= 0 ? '+' : ''}${g.toStringAsFixed(g.abs() >= 10 ? 0 : 1)}%', 'نمو الموسم', const Color(0xFF2F7BE6)),
                  ('${gs.loyalty}', 'الولاء', const Color(0xFF1FA58A)),
                  (_m(gs.fanBaseM), 'قاعدة الجماهير', kPrimary),
                ]),
                CardBox(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('نمو الجماهير', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        for (final e in last.indexed)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                Container(
                                  height: 24 + 80 * (mx == mn ? 0.5 : (e.$2 - mn) / (mx - mn)),
                                  decoration: BoxDecoration(color: e.$1 == last.length - 1 ? kPrimary : kPrimary.withOpacity(0.28), borderRadius: BorderRadius.circular(8)),
                                ),
                                const SizedBox(height: 6),
                                Text('${(firstSeason + 2025 + e.$1) % 100}', style: const TextStyle(color: kMuted, fontSize: 12)),
                              ]),
                            ),
                          ),
                      ]),
                    ),
                  ]),
                ),
                CardBox(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('الأعمار (تقدير)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    for (final e in const ['أقل من 18', '18-34', '35-54', '55+'].indexed) _want(e.$2, ages[e.$1].toDouble()),
                  ]),
                ),
                CardBox(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('ما تريده الجماهير', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 6),
                    _want('أسلوب هجومي', att),
                    _want('لاعبون شباب', yng),
                    _want('أسعار مخفضة', cheap),
                  ]),
                ),
                const SectionTitle('حملات نشطة'),
                if (gs.campaigns.isEmpty)
                  const CardBox(child: Text('لا حملات جارية. أطلق حملة من الأسفل لرفع الشعبية والولاء.', style: TextStyle(color: kMuted)))
                else
                  for (final c in gs.campaigns)
                    CardBox(
                      child: Column(children: [
                        Row(children: [
                          IconBox(Icons.star_border_rounded, kPrimary, size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(kCampaigns[c.kind]!.$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              Text(kCampaigns[c.kind]!.$5, style: const TextStyle(color: kMuted, fontSize: 12)),
                            ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            const Text('ينتهي بعد', style: TextStyle(color: kMuted, fontSize: 11)),
                            Text(weeksLabel(c.left), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB07A00))),
                          ]),
                        ]),
                        const SizedBox(height: 10),
                        Bar(c.progress, const Color(0xFFF5A524)),
                      ]),
                    ),
                const SectionTitle('إطلاق حملة'),
                for (final e in kCampaigns.entries)
                  CardBox(
                    child: Row(children: [
                      IconBox(Icons.campaign_outlined, const Color(0xFF2F7BE6), size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.value.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text('${money(e.value.$2)} • ${weeksLabel(e.value.$3)} • ${e.value.$5}', style: const TextStyle(color: kMuted, fontSize: 11.5)),
                        ]),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(64, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => snack(context, gs.startCampaign(e.key) ?? 'انطلقت الحملة 📣'),
                        child: const Text('ابدأ'),
                      ),
                    ]),
                  ),
                Row(children: [
                  Expanded(child: _nav(context, Icons.stadium_outlined, 'الملعب', StadiumScreen(gs: gs))),
                  const SizedBox(width: 8),
                  Expanded(child: _nav(context, Icons.confirmation_number_outlined, 'التذاكر', TicketsScreen(gs: gs))),
                  const SizedBox(width: 8),
                  Expanded(child: _nav(context, Icons.mic_none_rounded, 'الإعلام', MediaScreen(gs: gs))),
                ]),
              ]);
            },
          ),
        ),
      );

  Widget _nav(BuildContext c, IconData i, String l, Widget to) => GestureDetector(
        onTap: () => Navigator.of(c).push(MaterialPageRoute(builder: (_) => to)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          child: Column(children: [Icon(i, color: kPrimary), const SizedBox(height: 4), Text(l, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))]),
        ),
      );
}

String weeksLabel(int w) => w == 1 ? 'أسبوع' : (w == 2 ? 'أسبوعان' : '$w أسابيع');
