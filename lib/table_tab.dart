import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';

class TableTab extends StatelessWidget {
  final GameState gs;
  const TableTab({super.key, required this.gs});

  Widget _c(String t, {bool bold = false, double w = 28}) => SizedBox(
        width: w,
        child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
      );

  @override
  Widget build(BuildContext context) {
    final table = gs.table;
    final cl = gs.div == 1 ? gs.userSlots : 0;
    final el = gs.div == 1 ? 2 : 0;
    final relegZone = table.length >= 12 ? 3 : 2;
    const clC = Color(0xFF1B8F6A), elC = Color(0xFF6B4FBB), relC = Color(0xFFC62828);
    Color? zone(int i) => i < cl ? clC : (i < cl + el ? elC : (i >= table.length - relegZone && gs.div >= 1 ? relC : null));
    final scorers = <Player, Team>{
      for (final t in gs.teams)
        for (final p in t.squad) p: t
    }.entries.where((e) => e.key.goals > 0).toList()
      ..sort((a, b) => b.key.goals.compareTo(a.key.goals));
    return ListView(padding: const EdgeInsets.all(14), children: [
      Panel(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(children: [
          Row(children: [
            const SizedBox(width: 24),
            const SizedBox(width: 26),
            const Expanded(child: Text('النادي', style: TextStyle(color: kMuted, fontSize: 12))),
            _c('لعب'), _c('ف'), _c('ت'), _c('خ'), _c('فرق', w: 34), _c('نقاط', w: 34),
          ]),
          const Divider(height: 12),
          for (var i = 0; i < table.length; i++)
            Container(
              decoration: BoxDecoration(
                color: table[i] == gs.user ? const Color(0x3300E676) : zone(i)?.withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border(right: BorderSide(width: 4, color: zone(i) ?? Colors.transparent)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 24, child: Text('${i + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                teamBadge(table[i], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(table[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Transform.scale(scale: 0.62, alignment: Alignment.centerRight, child: FormDots(table[i].form)),
                  ]),
                ),
                _c('${table[i].played}'), _c('${table[i].won}'), _c('${table[i].drawn}'), _c('${table[i].lost}'),
                _c('${table[i].gd}', w: 34), _c('${table[i].points}', bold: true, w: 34),
              ]),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Wrap(spacing: 14, runSpacing: 4, children: [
          for (final e in [
            if (cl > 0) (clC, 'دوري الأبطال'),
            if (el > 0) (elC, 'الدوري الأوروبي'),
            (relC, 'الهبوط'),
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: e.$1, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 5),
              Text(e.$2, style: const TextStyle(color: kMuted, fontSize: 11)),
            ]),
        ]),
      ),
      sectionTitle('الهدافون'),
      Panel(
        child: scorers.isEmpty
            ? const Text('لا أهداف بعد', style: TextStyle(color: kMuted))
            : Column(children: [
                for (final e in scorers.take(8))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      teamBadge(e.value, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${e.key.name} • ${e.value.name}', style: const TextStyle(fontSize: 13))),
                      Text('⚽ ${e.key.goals}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Text('🎯 ${e.key.assists}', style: const TextStyle(color: kMuted)),
                    ]),
                  ),
              ]),
      ),
    ]);
  }
}
