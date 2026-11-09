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
      appBar: AppBar(title: const Text('🌍 الترتيب العالمي للأندية')),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: all.length + 1,
        itemBuilder: (c, i) {
          if (i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kPrimary.withOpacity(0.35)),
              ),
              child: Row(children: [
                Text('#$mine', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kPrimary)),
                const SizedBox(width: 14),
                teamBadge(gs.user, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(gs.user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    Text('${gs.eloOf(gs.user).round()} نقطة • من ${all.length}', style: const TextStyle(color: kMuted, fontSize: 12)),
                  ]),
                ),
              ]),
            );
          }
          final t = all[i - 1];
          final me = t == gs.user;
          final medal = i == 1 ? const Color(0xFFE6B422) : i == 2 ? const Color(0xFFB8BECB) : i == 3 ? const Color(0xFFC98B5B) : null;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: me ? kPrimary.withOpacity(0.1) : kCard,
              border: const Border(bottom: BorderSide(color: kLine)),
            ),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: medal == null ? null : BoxDecoration(color: medal, shape: BoxShape.circle),
                child: Text('$i', style: TextStyle(fontWeight: FontWeight.w900, color: medal == null ? kMuted : Colors.white)),
              ),
              const SizedBox(width: 10),
              teamBadge(t, size: 30),
              const SizedBox(width: 10),
              Expanded(child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: me ? FontWeight.w900 : FontWeight.w700))),
              Text('${gs.eloOf(t).round()}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
          );
        },
      ),
    );
  }
}
