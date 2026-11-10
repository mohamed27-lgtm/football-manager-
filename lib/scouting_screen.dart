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
                ButtonSegment(value: 0, label: Text('مواهب مقترحة')),
                ButtonSegment(value: 1, label: Text('المراقبة')),
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
                const Text('الكشّاف يضيف مواهب أفضل إلى السوق كل 4 أسابيع.', style: TextStyle(color: kMuted, fontSize: 12.5)),
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
            if (tab == 0) _list(gems, 'لا مواهب حالياً', 'ترقية الكشّاف تضيف مواهب أفضل.'),
            if (tab == 1) _list(watched, 'لا لاعبين تحت المراقبة', 'أضف لاعباً من بطاقته إلى قائمة المراقبة.'),
          ]);
        },
      ),
    );
  }
}
