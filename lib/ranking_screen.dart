import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'widgets.dart';

/// الترتيب العالمي للأندية (Elo) — يتغير مع كل مباراة في الدوري والكأس
class RankingScreen extends StatelessWidget {
  final GameState gs;
  const RankingScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    final all = gs.worldRanking;
    final mine = all.indexOf(gs.user) + 1;
    return Scaffold(
      appBar: AppBar(title: const Text('🌍 الترتيب العالمي للأندية'), backgroundColor: kBg),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: all.length + 1,
        itemBuilder: (c, i) {
          if (i == 0) {
            return Panel(
              child: Row(children: [
                teamBadge(gs.user, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Text(gs.user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                Column(children: [
                  Text('#$mine', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kAccent)),
                  Text('من ${all.length}', style: const TextStyle(color: kMuted, fontSize: 11)),
                ]),
              ]),
            );
          }
          final t = all[i - 1];
          final me = t == gs.user;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: me ? const Color(0x3300E676) : kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: me ? kAccent : kLine),
            ),
            child: Row(children: [
              SizedBox(width: 32, child: Text('$i', style: TextStyle(fontWeight: FontWeight.w900, color: i <= 3 ? kGold : kMuted))),
              teamBadge(t, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('${gs.eloOf(t).round()}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
          );
        },
      ),
    );
  }
}
