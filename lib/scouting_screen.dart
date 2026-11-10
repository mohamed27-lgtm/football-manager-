import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart';
import 'squad.dart';
import 'widgets.dart';

/// الكشافة: قائمة المراقبة + مواهب مقترحة من السوق + مستوى الكشّاف
class ScoutingScreen extends StatefulWidget {
  final GameState gs;
  const ScoutingScreen({super.key, required this.gs});
  @override
  State<ScoutingScreen> createState() => _ScoutingScreenState();
}

class _ScoutingScreenState extends State<ScoutingScreen> {
  GameState get gs => widget.gs;
  int tab = 0;

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

  Widget _list(List<Player> ps, String emptyTitle, String emptySub) {
    if (ps.isEmpty) return EmptyState(icon: Icons.search_rounded, title: emptyTitle, subtitle: emptySub);
    return Container(
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (final p in ps)
          PlayerTile(
            p: p,
            onTap: () => showPlayerSheet(context, gs, p),
            trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('إمكانات ${p.potential}', style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w800, fontSize: 12.5)),
              Text(money(p.value), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 12.5)),
            ]),
          ),
      ]),
    );
  }

  int _weeks = 4;

  List<Widget> _missions() {
    final slots = gs.scoutSlots;
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('الكشّافون النشطون', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const Spacer(),
            Text('${gs.missions.length}/$slots', style: const TextStyle(color: kMuted)),
          ]),
          const SizedBox(height: 8),
          if (gs.missions.isEmpty) const Text('لا مهام جارية.', style: TextStyle(color: kMuted)),
          for (final m in gs.missions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                const Icon(Icons.travel_explore_rounded, color: kPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['c'] as String, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('يعود بعد ${(m['e'] as int) - gs.week} أسابيع', style: const TextStyle(color: kMuted, fontSize: 12)),
                  ]),
                ),
                TextButton(onPressed: () => gs.cancelMission(m), child: const Text('إلغاء')),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إرسال كشّاف جديد', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: [for (final w in GameState.scoutDurations) ButtonSegment(value: w, label: Text('$w أسابيع'))],
            selected: {_weeks},
            onSelectionChanged: (v) => setState(() => _weeks = v.first),
          ),
          const SizedBox(height: 6),
          Text('التكلفة ${money(gs.missionCost(_weeks))} • يكتشف ${2 + _weeks ~/ 2 + (gs.staff['scout'] ?? 0) ~/ 2} لاعبين شباباً تقريباً.', style: const TextStyle(color: kMuted, fontSize: 12.5)),
          const SizedBox(height: 8),
          for (final e in gs.scoutCountries.take(12))
            InkWell(
              onTap: () {
                final err = gs.startMission(e.key, _weeks);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'انطلق الكشّاف ✅')));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(children: [
                  const Icon(Icons.flag_rounded, size: 18, color: kMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text('${e.value} موهبة', style: const TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(width: 10),
                  const Icon(Icons.send_rounded, size: 16, color: kPrimary),
                ]),
              ),
            ),
        ]),
      ),
      if (gs.scoutLog.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تقارير الكشّافين', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 8),
            for (final l in gs.scoutLog.take(6)) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(l, style: const TextStyle(fontSize: 12.5, height: 1.4))),
          ]),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الكشافة')),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final lvl = gs.staff['scout'] ?? 0;
          final watched = gs.market.where((p) => gs.watch.contains(p.id)).toList();
          final gems = gs.market.where((p) => p.age <= 23 && p.potential >= 75).toList()..sort((a, b) => b.potential.compareTo(a.potential));
          return ListView(padding: const EdgeInsets.all(14), children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: 0, label: Text('المهام')),
                ButtonSegment(value: 1, label: Text('مواهب مقترحة')),
                ButtonSegment(value: 2, label: Text('المراقبة')),
              ],
              selected: {tab},
              onSelectionChanged: (v) => setState(() => tab = v.first),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _tile('$lvl/5', 'مستوى الكشّاف', kPrimary),
              _tile('${gems.length}', 'مواهب متاحة', const Color(0xFF1FA58A)),
              _tile('${gs.watch.length}', 'تحت المراقبة', const Color(0xFF6A6FC4)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('الكشّاف الدائم يضيف مواهب إلى السوق كل 4 أسابيع. المهام تضيف مواهب من بلد تختاره.', style: TextStyle(color: kMuted, fontSize: 12.5)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: lvl >= 5 ? 'أقصى مستوى ✅' : 'ترقية الكشّاف (${money(gs.staffCost('scout'))})',
                    icon: lvl >= 5 ? null : Icons.upgrade_rounded,
                    onPressed: lvl >= 5
                        ? null
                        : () {
                            final err = gs.upgradeStaff('scout');
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تمت الترقية ✅')));
                          },
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            if (tab == 0) ..._missions(),
            if (tab == 1) _list(gems, 'لا مواهب حالياً', 'ترقية الكشّاف تضيف مواهب أفضل.'),
            if (tab == 2) _list(watched, 'لا لاعبين تحت المراقبة', 'أضف لاعباً من بطاقته إلى قائمة المراقبة.'),
          ]);
        },
      ),
    );
  }
}
