import 'package:flutter/material.dart' hide Text;
import 'game_state.dart';
import 'i18n.dart';
import 'match_pages.dart' show gameBar;
import 'national_team_screen.dart';
import 'ranking_screen.dart';
import 'widgets.dart';
import 'world_screens.dart';

/// عالم كرة القدم: الترتيب العالمي والمنتخبات ودوريات العالم وتدريب المنتخب (يُفتح بالضغط على شعار فريقك)
class WorldHubScreen extends StatelessWidget {
  final GameState gs;
  const WorldHubScreen({super.key, required this.gs});

  Widget _item(BuildContext c, IconData i, String t, String sub, Widget page, {bool dot = false}) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: dot ? kPrimary : kLine)),
          child: Row(children: [
            Badge(
              isLabelVisible: dot,
              smallSize: 10,
              backgroundColor: const Color(0xFFF0583A),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(i, color: kPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)), const SizedBox(height: 2), Text(sub, style: const TextStyle(color: kMuted, fontSize: 12))])),
            const Icon(Icons.chevron_left_rounded, color: kMuted),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: gameBar(context, gs, 'عالم الكرة'),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          if (gs.natJob != null) _item(context, Icons.flag_rounded, 'منتخبي: ${gs.natJob}', 'الاستدعاءات والمباريات الدولية والتشكيلة', NationScreen(gs: gs, nation: gs.natJob!), dot: true),
          _item(context, Icons.public_rounded, 'الترتيب العالمي والمنتخبات', 'أندية ومدربون ومنتخبات حقيقية، ويمكنك تدريب منتخب', RankingScreen(gs: gs)),
          _item(context, Icons.sports_soccer_rounded, 'دوريات العالم', 'نتائج وترتيب الدوريات الأخرى ولقب كل نادٍ', WorldLeaguesScreen(gs: gs)),
        ]),
      );
}
