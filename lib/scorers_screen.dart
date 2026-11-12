import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';

/// قوائم الهدافين وصنّاع الألعاب لبطولة واحدة: كل من ساهم، مرتبين
class ScorersScreen extends StatefulWidget {
  final GameState gs;
  final String compKey, title;
  final int initialTab;
  const ScorersScreen({super.key, required this.gs, required this.compKey, required this.title, this.initialTab = 0});
  @override
  State<ScorersScreen> createState() => _ScorersScreenState();
}

class _ScorersScreenState extends State<ScorersScreen> {
  late int tab = widget.initialTab;
  GameState get gs => widget.gs;

  @override
  Widget build(BuildContext context) {
    final stats = gs.compStats[widget.compKey] ?? const <int, List<int>>{};
    final players = <int, Player>{};
    final clubs = <String, Team>{};
    for (final t in [...gs.teams, ...gs.upper, ...gs.lower, ...gs.foreign.values]) {
      clubs[t.name] = t;
      for (final p in t.squad) {
        players[p.id] = p;
      }
    }
    final rows = <(int, List<int>)>[for (final e in stats.entries) if (e.value[tab] > 0) (e.key, e.value)]
      ..sort((a, b) {
        final c = b.$2[tab].compareTo(a.$2[tab]);
        if (c != 0) return c;
        final d = b.$2[1 - tab].compareTo(a.$2[1 - tab]);
        return d != 0 ? d : a.$1.compareTo(b.$1);
      });
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(value: 0, label: Text('الهدافون'), icon: Icon(Icons.sports_soccer_rounded, size: 18)),
              ButtonSegment(value: 1, label: Text('صنّاع الألعاب'), icon: Icon(Icons.trending_flat_rounded, size: 18)),
            ],
            selected: {tab},
            onSelectionChanged: (s) => setState(() => tab = s.first),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? const EmptyState(icon: Icons.sports_soccer_rounded, title: 'لا إحصاءات بعد', subtitle: 'تظهر هنا بعد أول مباراة في هذه البطولة.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    final p = players[r.$1];
                    final nm = gs.compNames[r.$1];
                    final club = nm == null ? null : clubs[nm[1]];
                    final mine = p != null && gs.user.squad.contains(p);
                    final rank = i + 1;
                    final medal = rank <= 3 ? const [Color(0xFFE6B422), Color(0xFFB8BECB), Color(0xFFC98B5B)][rank - 1] : null;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: mine ? kPrimary.withOpacity(0.1) : kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
                      child: Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: medal == null ? null : BoxDecoration(color: medal, shape: BoxShape.circle),
                          child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w900, color: medal == null ? kMuted : Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        if (p != null) playerFace(p, 40) else Container(width: 40, height: 40, decoration: BoxDecoration(color: kCard2, shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: kMuted)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p?.name ?? nm?[0] ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            Row(children: [
                              if (club != null) ...[teamBadge(club, size: 16), const SizedBox(width: 4)],
                              Expanded(child: Text(nm?[1] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11.5))),
                            ]),
                          ]),
                        ),
                        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${r.$2[tab]}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                          Text(tab == 0 ? '🎯 ${r.$2[1]}' : '⚽ ${r.$2[0]}', style: const TextStyle(color: kMuted, fontSize: 11.5)),
                        ]),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
