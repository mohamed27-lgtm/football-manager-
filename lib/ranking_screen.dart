import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';

/// الترتيب العالمي: أندية (Elo) / دول (من جنسيات اللاعبين) / لاعبون / مدربون
class RankingScreen extends StatefulWidget {
  final GameState gs;
  const RankingScreen({super.key, required this.gs});
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  GameState get gs => widget.gs;
  int tab = 0;
  int region = 0; // 0 الكل، 1 محلي، 2 أجنبي

  static const _medals = [Color(0xFFE6B422), Color(0xFFB8BECB), Color(0xFFC98B5B)];

  Widget _rank(int i, bool me) {
    final medal = i <= 3 ? _medals[i - 1] : null;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: medal == null ? null : BoxDecoration(color: medal, shape: BoxShape.circle),
      child: Text('$i', style: TextStyle(fontWeight: FontWeight.w900, color: medal == null ? kMuted : Colors.white)),
    );
  }

  Widget _row(int i, Widget lead, String title, String sub, Widget trail, {bool me = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: me ? kPrimary.withOpacity(0.1) : kCard, border: const Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          _rank(i, me),
          const SizedBox(width: 10),
          lead,
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: me ? FontWeight.w900 : FontWeight.w700)),
              if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11.5)),
            ]),
          ),
          trail,
        ]),
      );

  Widget _summary(int rank, Widget lead, String title, String sub) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: kPrimary.withOpacity(0.35))),
        child: Row(children: [
          Text('#$rank', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kPrimary)),
          const SizedBox(width: 14),
          lead,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
        ]),
      );

  List<Widget> _clubs() {
    final all = gs.worldRanking;
    final mine = all.indexOf(gs.user) + 1;
    final shown = <(int, Team)>[
      for (var i = 0; i < all.length; i++)
        if (region == 0 || (region == 1 ? !gs.foreign.containsKey(all[i].id) || all[i].id < 1000 : gs.foreign.containsKey(all[i].id) && all[i].id >= 1000)) (i + 1, all[i])
    ];
    return [
      _summary(mine, teamBadge(gs.user, size: 44), gs.user.name, '${gs.eloOf(gs.user).round()} نقطة • من ${all.length}'),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(spacing: 8, children: [
          for (final e in const [(0, 'الكل'), (1, 'محلي'), (2, 'أجنبي')])
            ChoiceChip(label: Text(e.$2), selected: region == e.$1, onSelected: (_) => setState(() => region = e.$1)),
        ]),
      ),
      for (final e in shown)
        _row(e.$1, teamBadge(e.$2, size: 30), e.$2.name, '', Text('${gs.eloOf(e.$2).round()}', style: const TextStyle(fontWeight: FontWeight.w900)), me: e.$2 == gs.user),
    ];
  }

  List<Player> _allPlayers() => [for (final t in gs.worldRanking) ...t.squad];

  List<Widget> _countries() {
    final by = <String, List<int>>{};
    for (final p in _allPlayers()) {
      final n = p.nat;
      if (n == null || n.isEmpty) continue;
      by.putIfAbsent(n, () => []).add(p.overall);
    }
    final rows = <(String, double, int)>[];
    by.forEach((k, v) {
      if (v.length < 5) return;
      v.sort((a, b) => b.compareTo(a));
      final top = v.take(11).toList();
      rows.add((k, top.reduce((a, b) => a + b) / top.length, v.length));
    });
    rows.sort((a, b) => b.$2.compareTo(a.$2));
    if (rows.isEmpty) return [const EmptyState(icon: Icons.flag_outlined, title: 'لا بيانات', subtitle: 'لا توجد جنسيات كافية.')];
    return [
      for (var i = 0; i < rows.length && i < 60; i++)
        _row(i + 1, const CircleAvatar(radius: 15, backgroundColor: kCard2, child: Icon(Icons.flag_rounded, size: 16, color: kMuted)), rows[i].$1, '${rows[i].$3} لاعباً', ratingRing(rows[i].$2, size: 34)),
    ];
  }

  List<Widget> _players() {
    final all = _allPlayers()..sort((a, b) => b.overall.compareTo(a.overall));
    final club = {for (final t in gs.worldRanking) for (final p in t.squad) p.id: t};
    return [
      for (var i = 0; i < all.length && i < 100; i++)
        _row(
          i + 1,
          teamBadge(club[all[i].id] ?? gs.user, size: 30),
          all[i].name,
          '${club[all[i].id]?.name ?? ''} • ${all[i].nat ?? ''}',
          ratingRing(all[i].overall, size: 34),
          me: gs.user.squad.contains(all[i]),
        ),
    ];
  }

  List<Widget> _coaches() {
    final all = gs.worldRanking;
    return [
      for (var i = 0; i < all.length && i < 60; i++)
        _row(i + 1, teamBadge(all[i], size: 30), 'مدرب ${all[i].name}', '${all[i].won} فوز • ${all[i].drawn} تعادل • ${all[i].lost} خسارة', Text('${gs.eloOf(all[i]).round()}', style: const TextStyle(fontWeight: FontWeight.w900)), me: all[i] == gs.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (tab) { 0 => _clubs(), 1 => _countries(), 2 => _players(), _ => _coaches() };
    return Scaffold(
      appBar: AppBar(title: const Text('الترتيب العالمي')),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(value: 0, label: Text('الأندية', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 1, label: Text('الدول', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 2, label: Text('اللاعبون', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 3, label: Text('المدربون', style: TextStyle(fontSize: 12))),
            ],
            selected: {tab},
            onSelectionChanged: (v) => setState(() => tab = v.first),
          ),
          const SizedBox(height: 12),
          ...body,
        ]),
      ),
    );
  }
}
