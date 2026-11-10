import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'club_screens.dart';
import 'game_state.dart';
import 'lineup_pages.dart';
import 'match_pages.dart';
import 'stadium_screen.dart';
import 'widgets.dart';

/// الجماهير: نظرة عامة • الحضور • الحملات
class FansScreen extends StatefulWidget {
  final GameState gs;
  const FansScreen({super.key, required this.gs});
  @override
  State<FansScreen> createState() => _FansScreenState();
}

class _FansScreenState extends State<FansScreen> {
  int tab = 0;
  GameState get gs => widget.gs;

  Widget _card(Widget c) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: c,
      );

  Widget _want(String label, double pct) {
    final c = pct >= 70 ? const Color(0xFF1FA58A) : (pct >= 45 ? const Color(0xFF2F7BE6) : const Color(0xFFF5A524));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: (pct / 100).clamp(0, 1).toDouble(), minHeight: 7, color: c, backgroundColor: kCard2))),
        const SizedBox(width: 10),
        Text('${pct.round()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: gameBar(context, gs, 'الجماهير'),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(children: [
              Expanded(flex: 2, child: blueBtn('المرافق', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StadiumScreen(gs: gs))), icon: Icons.stadium_outlined)),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: GradientButton(
                  label: 'حملة تسويقية',
                  icon: Icons.campaign_outlined,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(gs.runCampaign() ?? 'انطلقت الحملة: الشعبية +3 (1.0M)'))),
                ),
              ),
            ]),
          ),
        ),
        body: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final f = gs.fans;
            final cap = gs.stadiumCapacity;
            final avg = gs.attHist.isEmpty ? gs.attendance : (gs.attHist.reduce((a, b) => a + b) / gs.attHist.length).round();
            final young = gs.user.squad.where((p) => p.age <= 23).length;
            final att = (55 + (gs.user.mentality - 2) * 14).toDouble();
            final yng = (young * 100 / (gs.user.squad.isEmpty ? 1 : gs.user.squad.length) * 2.2).clamp(5, 100).toDouble();
            final cheap = const [90.0, 55.0, 20.0][gs.ticketLevel];
            final price = const [36, 45, 56][gs.ticketLevel];
            return ListView(padding: const EdgeInsets.all(14), children: [
              Container(
                height: 44,
                decoration: BoxDecoration(border: Border.all(color: kPrimary), borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.antiAlias,
                child: Row(children: [
                  for (final e in const ['نظرة عامة', 'الحضور', 'الحملات'].indexed)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => tab = e.$1),
                        child: Container(alignment: Alignment.center, color: tab == e.$1 ? kPrimary : Colors.transparent, child: Text(e.$2, style: TextStyle(fontWeight: FontWeight.w900, color: tab == e.$1 ? Colors.white : kPrimary))),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              if (tab == 0) ...[
                _card(Row(children: [
                  Stack(alignment: Alignment.center, children: [
                    SizedBox(width: 96, height: 96, child: CircularProgressIndicator(value: f / 100, strokeWidth: 10, color: const Color(0xFF1FA58A), backgroundColor: kCard2)),
                    Column(mainAxisSize: MainAxisSize.min, children: [Text('${f.round()}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const Text('الرضا', style: TextStyle(color: kMuted, fontSize: 11))]),
                  ]),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('متوسط الحضور', style: TextStyle(color: kMuted, fontSize: 12)),
                      Text(_fmt(avg), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      const Text('سعة الملعب', style: TextStyle(color: kMuted, fontSize: 12)),
                      Text(_fmt(cap), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ])),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('الحضور في آخر 8 مباريات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 10),
                  _attBars(),
                ])),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ما تريده الجماهير', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  _want('أسلوب هجومي', att),
                  _want('لاعبون شباب', yng),
                  _want('أسعار مخفضة', cheap),
                ])),
                _card(Row(children: [
                  _sqb(Icons.remove_rounded, gs.ticketLevel > 0 ? () => gs.setTicketLevel(gs.ticketLevel - 1) : null, false),
                  Expanded(child: Column(children: [const Text('سعر التذكرة', style: TextStyle(color: kMuted, fontSize: 12)), Text('\$$price', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))])),
                  _sqb(Icons.add_rounded, gs.ticketLevel < 2 ? () => gs.setTicketLevel(gs.ticketLevel + 1) : null, true),
                ])),
              ],
              if (tab == 1) ...[
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('الحضور المتوقع في المباراة القادمة', style: TextStyle(color: kMuted, fontSize: 12.5)),
                  Text(_fmt(gs.attendance), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: gs.fillRate, minHeight: 9, color: const Color(0xFF1FA58A), backgroundColor: kCard2)),
                  const SizedBox(height: 6),
                  Text('نسبة الامتلاء ${(gs.fillRate * 100).round()}% من ${_fmt(cap)}', style: const TextStyle(color: kMuted, fontSize: 12)),
                ])),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('آخر مباريات على أرضك', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 10),
                  _attBars(),
                ])),
              ],
              if (tab == 2) ...[
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('حملة تسويقية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('تكلفة 1.0M وترفع شعبية النادي +3 (مرة كل 4 جولات).', style: TextStyle(color: kMuted, fontSize: 12.5)),
                ])),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MediaScreen(gs: gs))),
                  child: _card(Row(children: [
                    const Icon(Icons.mic_none_rounded, color: kPrimary),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('المؤتمر الصحفي والإعلام', style: TextStyle(fontWeight: FontWeight.w900))),
                    const Icon(Icons.chevron_left_rounded, color: kMuted),
                  ])),
                ),
              ],
            ]);
          },
        ),
      );

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  Widget _sqb(IconData i, VoidCallback? on, bool primary) => GestureDetector(
        onTap: on,
        child: Container(width: 44, height: 44, decoration: BoxDecoration(color: primary ? kPrimary : const Color(0xFFA9D4F8), borderRadius: BorderRadius.circular(10)), child: Icon(i, color: primary ? Colors.white : const Color(0xFF15233D))),
      );

  Widget _attBars() {
    final h = gs.attHist.length > 8 ? gs.attHist.sublist(gs.attHist.length - 8) : gs.attHist;
    if (h.isEmpty) return const SizedBox(height: 60, child: Center(child: Text('تظهر بعد أول مباراة على أرضك', style: TextStyle(color: kMuted, fontSize: 12.5))));
    final mx = gs.stadiumCapacity.toDouble();
    return SizedBox(
      height: 90,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final v in h)
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Container(height: 10 + 70 * v / mx, decoration: BoxDecoration(color: const Color(0xFF1FA58A), borderRadius: BorderRadius.circular(4))))),
      ]),
    );
  }
}
