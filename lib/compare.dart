import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';

/// اختيار لاعب ثانٍ ثم مقارنة الاثنين وجهاً لوجه
Future<void> showCompare(BuildContext context, GameState gs, Player a) async {
  final pool = [...gs.user.squad, ...gs.market].where((x) => x.id != a.id).toList()
    ..sort((x, y) => y.overall.compareTo(x.overall));
  final b = await showModalBottomSheet<Player>(
    context: context,
    backgroundColor: kCard,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => SizedBox(
      height: MediaQuery.of(c).size.height * 0.7,
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(8), child: Text('اختر لاعباً للمقارنة', style: TextStyle(fontWeight: FontWeight.w800))),
        Expanded(
          child: ListView(children: [
            for (final p in pool)
              ListTile(
                leading: PlayerAvatar(p, size: 40),
                title: Text(p.name),
                subtitle: Text('${p.pos.label} • ${p.age} سنة', style: const TextStyle(color: kMuted)),
                trailing: Text('${p.overall}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                onTap: () => Navigator.pop(c, p),
              ),
          ]),
        ),
      ]),
    ),
  );
  if (b == null || !context.mounted) return;
  Widget row(String l, num x, num y, {bool lowerBetter = false, String Function(num)? f}) {
    final fm = f ?? (n) => '${n.round()}';
    final aw = lowerBetter ? x < y : x > y, bw = lowerBetter ? y < x : y > x;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 62, child: Text(fm(x), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: aw ? kAccent : null))),
        Expanded(child: Text(l, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13))),
        SizedBox(width: 62, child: Text(fm(y), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: bw ? kAccent : null))),
      ]),
    );
  }

  showDialog(
    context: context,
    builder: (c) => Dialog(
      backgroundColor: kCard,
      insetPadding: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: Column(children: [PlayerAvatar(a, size: 52), const SizedBox(height: 4), Text(a.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))])),
            const Text('VS', style: TextStyle(color: kMuted)),
            Expanded(child: Column(children: [PlayerAvatar(b, size: 52), const SizedBox(height: 4), Text(b.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))])),
          ]),
          const Divider(height: 22),
          row('التقييم', a.overall, b.overall),
          row('الإمكانات', a.potential, b.potential),
          row('هجوم', a.atk, b.atk),
          row('دفاع', a.def, b.def),
          row('تمرير', a.pas, b.pas),
          row('اللياقة', a.fitness, b.fitness),
          row('المعنويات', a.morale, b.morale),
          row('العمر', a.age, b.age, lowerBetter: true),
          row('القيمة', a.value, b.value, f: (n) => money(n.toDouble())),
          row('الراتب الأسبوعي', a.wage, b.wage, lowerBetter: true, f: (n) => money2(n.toDouble())),
          row('الأهداف', a.goals, b.goals),
          row('الصناعة', a.assists, b.assists),
          row('متوسط التقييم', a.avgRating, b.avgRating, f: (n) => n == 0 ? '—' : n.toStringAsFixed(1)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق')),
        ]),
      ),
    ),
  );
}
