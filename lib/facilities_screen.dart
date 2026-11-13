import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'squad.dart';
import 'calendar.dart';
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

  static const _info = {
    'stadium': (Icons.stadium_rounded, Color(0xFFE5533D), 'الملعب', 'السعة وإيراد التذاكر والضيافة'),
    'training': (Icons.fitness_center_rounded, Color(0xFF1FA58A), 'مركز التدريب', 'تطور اللاعبين وتعافٍ أسرع'),
    'academy': (Icons.school_rounded, Color(0xFF6A6FC4), 'الأكاديمية', 'مواهب شابة تتخرج كل موسم'),
    'medical': (Icons.medical_services_rounded, Color(0xFFE5533D), 'المركز الطبي', 'تعافٍ أسرع من الإصابات'),
    'fans': (Icons.groups_rounded, Color(0xFF2F7BE6), 'مرافق الجماهير', 'متجر وتجربة المشجعين: دخل وشعبية'),
  };

  String _n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  /// وصف الأثر عند مستوى معيّن
  String _effect(String kind, int l) => switch (kind) {
        'stadium' => 'سعة ${_n(12000 + 8000 * l)} متفرج',
        'training' => 'تعافٍ +${(1.5 * (l - 1)).toStringAsFixed(1)} لياقة أسبوعياً • تطور أسرع',
        'academy' => 'نحو ${(0.5 + 0.1 * l).toStringAsFixed(1)}+ خريج/موسم • إمكانات +${4 * l}',
        'medical' => 'تعافٍ +${(0.8 * (l - 1)).toStringAsFixed(1)} • ${7 * (l - 1)}% احتمال تقليص أسبوع إصابة',
        _ => 'دخل التذاكر +${4 * (l - 1)}% • الرعاية +${3 * (l - 1)}%',
      };

  String _when(Project p) {
    final w = GameCalendar.weekStart(gs.season, gs.week + p.left);
    return '${GameCalendar.fmtShort(w)} (بعد ${p.left} ${p.left == 1 ? 'أسبوع' : 'أسابيع'})';
  }

  Widget _fac(BuildContext context, String kind) {
    final i = _info[kind]!;
    final color = i.$2;
    final lvl = gs.facLevel(kind);
    final pr = gs.projectOf(kind);
    final cost = lvl < 5 ? gs.facCost(kind, lvl) : 0.0;
    final weeks = lvl < 5 ? gs.facWeeks(kind, lvl) : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(i.$1, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.$3, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              Text(i.$4, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          Text('مستوى $lvl/5', style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (var k = 0; k < 5; k++)
            Expanded(
              child: Container(
                height: 8,
                margin: const EdgeInsetsDirectional.only(end: 4),
                decoration: BoxDecoration(color: k < lvl ? color : (k == lvl && pr != null ? color.withOpacity(0.35) : kCard2), borderRadius: BorderRadius.circular(4)),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Text('الآن: ${_effect(kind, lvl)}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        if (lvl < 5) Text('التالي: ${_effect(kind, lvl + 1)}', style: const TextStyle(color: kMuted, fontSize: 12)),
        if (kind == 'stadium' && pr != null) const Padding(padding: EdgeInsets.only(top: 4), child: Text('⚠️ الملعب يعمل بسعة أقل 15% أثناء الأشغال', style: TextStyle(color: Color(0xFFE5533D), fontSize: 12))),
        const SizedBox(height: 10),
        if (pr != null) ...[
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pr.progress, minHeight: 9, color: color, backgroundColor: kCard2)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: Text('ينتهي ${_when(pr)}${pr.delays > 0 ? ' • تأخر ${pr.delays}×' : ''}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
            if (!pr.rushed && pr.left > 1)
              TextButton(
                onPressed: () => _snack(context, gs.rushProject(kind) ?? 'تم تسريع المشروع ⚡'),
                child: Text('تسريع (${money(gs.rushCost(pr))})'),
              ),
          ]),
        ] else if (lvl >= 5)
          const Text('وصلت إلى أقصى مستوى', style: TextStyle(color: kMuted))
        else
          Row(children: [
            Expanded(child: Text('التكلفة ${money(cost)} • المدة $weeks ${weeks == 1 ? 'أسبوع' : 'أسابيع'}', style: const TextStyle(color: kMuted, fontSize: 12.5))),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(96, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => _snack(context, gs.startProject(kind) ?? 'بدأ المشروع 🏗️'),
              child: const Text('بدء المشروع'),
            ),
          ]),
      ]),
    );
  }

  void _snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المنشآت')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final u = gs.user;
            final lv = u.stadium + u.trainingLvl + u.academy + u.medical + u.fanZone;
            final upkeep = 0.03 * (u.stadium + u.trainingLvl) + 0.02 * (u.academy + u.medical + u.fanZone) + 0.04 * gs.projects.length;
            return ListView(padding: const EdgeInsets.all(14), children: [
              SegmentedButton<int>(
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                segments: [
                  const ButtonSegment(value: 0, label: Text('المنشآت')),
                  ButtonSegment(value: 1, label: Text('المشاريع${gs.projects.isEmpty ? '' : ' (${gs.projects.length})'}')),
                  const ButtonSegment(value: 2, label: Text('التأثير')),
                ],
                selected: {tab},
                onSelectionChanged: (v) => setState(() => tab = v.first),
              ),
              const SizedBox(height: 12),
              Row(children: [
                _tile((lv / 2.5).toStringAsFixed(1), 'مستوى النادي', const Color(0xFF1FA58A)),
                _tile(money(upkeep), 'الصيانة الأسبوعية', kPrimary),
                _tile(money(u.budget), 'الميزانية', kAccent),
              ]),
              const SizedBox(height: 12),
              if (tab == 0) for (final k in kFacilityKinds) _fac(context, k),
              if (tab == 1) ...[
                if (gs.projects.isEmpty)
                  const EmptyState(icon: Icons.construction_rounded, title: 'لا مشاريع جارية', subtitle: 'ابدأ مشروعاً من تبويب المنشآت. يمكن تنفيذ مشروعين معاً كحد أقصى، وكل ترقية تستغرق أسابيع.')
                else
                  for (final p in gs.projects) _fac(context, p.kind),
                const SizedBox(height: 4),
                const Text('قد تتأخر المشاريع بسبب الطقس والتراخيص، وتسريعها يكلّف 35% من قيمتها.', style: TextStyle(color: kMuted, fontSize: 12)),
              ],
              if (tab == 2) ...[
                for (final k in kFacilityKinds)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                    child: Row(children: [
                      Icon(_info[k]!.$1, color: _info[k]!.$2),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_info[k]!.$3, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(_effect(k, gs.facLevel(k)), style: const TextStyle(color: kMuted, fontSize: 12)),
                        ]),
                      ),
                      Text('${gs.facLevel(k)}/5', style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimary)),
                    ]),
                  ),
              ],
              const Text('كل مستوى يزيد مصاريف الصيانة الأسبوعية، وأثناء المشاريع تُضاف تكلفة إشراف.', style: TextStyle(color: kMuted, fontSize: 12)),
            ]);
          },
        ),
      ),
    );
  }
}
