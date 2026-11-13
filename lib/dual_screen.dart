import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'lineup_pages.dart';
import 'match_pages.dart' show gameBar;
import 'widgets.dart';

/// لاعبون مزدوجو الجنسية يمكن إقناعهم بتمثيل منتخبك
class DualScreen extends StatelessWidget {
  final GameState gs;
  const DualScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final job = gs.natJob;
          if (job == null) return Scaffold(appBar: gameBar(context, gs, 'مزدوجو الجنسية'), body: const EmptyState(icon: Icons.flag_outlined, title: 'لا تدرّب منتخباً'));
          final l = gs.dualCandidates(job);
          return Scaffold(
            appBar: gameBar(context, gs, 'مزدوجو الجنسية'),
            body: ListView(padding: const EdgeInsets.all(14), children: [
              Text('لاعبون يحق لهم تمثيل $job بحكم الأصل ولم يلتزموا بمنتخب آخر. تتأثر فرصة الإقناع بقوة منتخبك مقارنة ببلده، وفرصه معه، وسمعتك وعمره.', style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.5)),
              const SizedBox(height: 10),
              if (l.isEmpty)
                const EmptyState(icon: Icons.groups_outlined, title: 'لا مرشحين حالياً', subtitle: 'لا يوجد لاعبون مزدوجو الجنسية متاحون لمنتخبك الآن.')
              else
                for (final e in l)
                  Builder(builder: (_) {
                    final p = e.$1;
                    final c = gs.persuadeChance(p, job);
                    final locked = p.swTry >= 3;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
                      child: Row(children: [
                        playerFace(p, 42),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text('${p.nat} • ${e.$2.name} • ${p.age}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
                            Text(locked ? 'رفض نهائياً' : 'فرصة الإقناع: ${gs.persuadeTier(c)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: locked ? const Color(0xFFE5533D) : (c >= 0.6 ? const Color(0xFF1FA58A) : (c >= 0.35 ? const Color(0xFFB07A00) : kMuted)))),
                          ]),
                        ),
                        ratingRing(p.overall, size: 36),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 78,
                          child: blueBtn('إقناع', () {
                            final r = gs.persuade(p);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.$2)));
                          }),
                        ),
                      ]),
                    );
                  }),
            ]),
          );
        },
      );
}
