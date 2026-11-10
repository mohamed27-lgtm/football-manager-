import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'squad.dart';
import 'widgets.dart';

class FacilitiesScreen extends StatefulWidget {
  final GameState gs;
  const FacilitiesScreen({super.key, required this.gs});
  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  GameState get gs => widget.gs;
  int tab = 0;
  Widget _tile(String v, String l, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          child: Column(children: [
            Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c)),
            Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      );

  Widget _fac(BuildContext context, String kind, IconData icon, Color color, String title, String desc, int lvl, {bool locked = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
      child: Row(children: [
        Column(children: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 34), padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: locked || lvl >= 5
                ? null
                : () {
                    final err = gs.upgrade(kind);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تمت الترقية ✅')));
                  },
            child: Text(locked ? 'قريباً' : (lvl >= 5 ? 'أقصى' : 'ترقية')),
          ),
          const SizedBox(height: 4),
          if (!locked && lvl < 5) Text(money(gs.upgradeCost(lvl)), style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('مستوى $lvl/5', style: const TextStyle(color: kMuted, fontSize: 12)),
              const Spacer(),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              for (var i = 0; i < 5; i++)
                Expanded(
                  child: Container(
                    height: 8,
                    margin: const EdgeInsetsDirectional.only(end: 4),
                    decoration: BoxDecoration(color: i < lvl ? color : kCard2, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
            ]),
            const SizedBox(height: 6),
            Text(desc, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 12),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color, size: 26),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المنشآت')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final lv = gs.user.stadium + gs.user.trainingLvl;
            final upkeep = lv * 0.02;
            Widget cards() => Column(children: [
                  _fac(context, 'stadium', Icons.stadium_rounded, const Color(0xFFE5533D), 'الملعب', 'يرفع دخل التذاكر في المباريات على أرضك', gs.user.stadium),
                  _fac(context, 'training', Icons.fitness_center_rounded, const Color(0xFF1FA58A), 'مركز التدريب', 'تطور اللاعبين وتعافٍ أسرع', gs.user.trainingLvl),
                  _fac(context, 'medical', Icons.medical_services_rounded, const Color(0xFFE5533D), 'المركز الطبي', 'مدة أقصر للإصابات', 1, locked: true),
                  _fac(context, 'scout', Icons.search_rounded, const Color(0xFFF5A524), 'شبكة الكشافة', 'مناطق بحث أكثر', 1, locked: true),
                  _fac(context, 'fans', Icons.groups_rounded, const Color(0xFF2F7BE6), 'مرافق الجماهير', 'دخل المباريات أعلى', 1, locked: true),
                ]);
            return ListView(padding: const EdgeInsets.all(14), children: [
              SegmentedButton<int>(
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(value: 0, label: Text('المنشآت')),
                  ButtonSegment(value: 1, label: Text('المشاريع')),
                  ButtonSegment(value: 2, label: Text('التأثير')),
                ],
                selected: {tab},
                onSelectionChanged: (v) => setState(() => tab = v.first),
              ),
              const SizedBox(height: 12),
              Row(children: [
                _tile('${(lv / 2).toStringAsFixed(1)}', 'مستوى النادي', const Color(0xFF1FA58A)),
                _tile(money(upkeep), 'الصيانة الأسبوعية', kPrimary),
                _tile(money(gs.user.budget), 'الميزانية', kAccent),
              ]),
              const SizedBox(height: 12),
              if (tab == 0) cards(),
              if (tab == 1) const EmptyState(icon: Icons.construction_rounded, title: 'لا مشاريع جارية', subtitle: 'الترقيات تُنفَّذ فورياً حالياً.'),
              if (tab == 2) ...[
                for (final e in [
                  ('الملعب', 'يرفع دخل التذاكر', gs.user.stadium),
                  ('مركز التدريب', 'يسرّع التطور', gs.user.trainingLvl),
                ])
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                    child: Row(children: [
                      Expanded(child: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w800))),
                      Text(e.$2, style: const TextStyle(color: kMuted, fontSize: 12.5)),
                      const SizedBox(width: 10),
                      Text('${e.$3}/5', style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimary)),
                    ]),
                  ),
              ],
              const Text('كل مستوى يزيد مصاريف الصيانة الأسبوعية قليلاً.', style: TextStyle(color: kMuted, fontSize: 12)),
            ]);
          },
        ),
      ),
    );
  }
}
