import 'package:flutter/material.dart';
import 'cups_screen.dart';
import 'flags.dart';
import 'game_state.dart';
import 'table_tab.dart';
import 'widgets.dart';

/// صفحة المسابقات بطابع Super Kickoff: رأس الدولة + شريط بطولات + محتوى البطولة
class CompetitionsView extends StatefulWidget {
  final GameState gs;
  const CompetitionsView({super.key, required this.gs});
  @override
  State<CompetitionsView> createState() => _CompetitionsViewState();
}

class _CompetitionsViewState extends State<CompetitionsView> {
  int sel = 0;

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final items = <(String, IconData, Color, int?)>[
      (gs.leagueName, Icons.emoji_events, kGold, gs.leagueId),
      ('كأس الدوري', Icons.military_tech, const Color(0xFFE53935), kDomesticCupId[gs.leagueId]),
      ('دوري الأبطال', Icons.stars, const Color(0xFF3D8BFF), 2),
      if (gs.europa != null) ('الدوري الأوروبي', Icons.star_half, const Color(0xFFFF8F00), 3),
      if (gs.conference != null) ('دوري المؤتمر', Icons.star_border, const Color(0xFF43A047), 848),
      if (gs.superCup != null) ('كأس السوبر', Icons.workspace_premium, const Color(0xFF00BFA5), kSuperCupId[gs.leagueId] ?? 531),
    ];
    if (sel >= items.length) sel = 0;
    return Column(children: [
      Container(
        color: kCard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          if (gs.country.isNotEmpty) FlagBadge(gs.country, size: 34) else const Icon(Icons.public),
          const SizedBox(width: 12),
          Expanded(child: Text(gs.country.isEmpty ? gs.leagueName : gs.country, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          Text('الموسم ${gs.season}', style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
      ),
      SizedBox(
        height: 74,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), children: [
          for (var i = 0; i < items.length; i++)
            GestureDetector(
              onTap: () => setState(() => sel = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: sel == i ? items[i].$3.withOpacity(0.22) : kCard2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel == i ? items[i].$3 : kLine, width: sel == i ? 1.6 : 1),
                ),
                child: Row(children: [
                  CompLogo(items[i].$4, fallback: items[i].$2, color: items[i].$3, size: 34),
                  if (sel == i) ...[
                    const SizedBox(width: 8),
                    Text(items[i].$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ]),
              ),
            ),
        ]),
      ),
      Expanded(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) => sel == 0 ? TableTab(gs: gs) : CupView(gs: gs, cup: gs.allCups[sel - 1]),
        ),
      ),
    ]);
  }
}
