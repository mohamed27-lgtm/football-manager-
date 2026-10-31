import 'package:flutter/material.dart';
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
              color: table[i] == gs.user ? const Color(0x2200E676) : null,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 24, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                teamBadge(table[i], size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(table[i].name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                _c('${table[i].played}'), _c('${table[i].won}'), _c('${table[i].drawn}'), _c('${table[i].lost}'),
                _c('${table[i].gd}', w: 34), _c('${table[i].points}', bold: true, w: 34),
              ]),
            ),
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
