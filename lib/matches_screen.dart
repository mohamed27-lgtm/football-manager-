import 'package:flutter/material.dart';
import 'game_state.dart';
import 'match_screen.dart';
import 'models.dart';
import 'table_tab.dart';
import 'widgets.dart';

/// مركز المباريات: الجدول والنتائج • الترتيب والهدافون
class MatchesTab extends StatefulWidget {
  final GameState gs;
  const MatchesTab({super.key, required this.gs});
  @override
  State<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> {
  int view = 0;

  Widget _next(BuildContext context) {
    final gs = widget.gs;
    final f = gs.userFixture;
    if (f == null || gs.fired || gs.seasonOver) {
      return Panel(
        child: Text(gs.fired ? 'تمت إقالتك' : 'انتهى الموسم — ابدأ موسماً جديداً من الرئيسية',
            style: const TextStyle(color: kMuted)),
      );
    }
    final u = gs.user;
    final isHome = f.home == u.id;
    final opp = gs.team(isHome ? f.away : f.home);
    return Panel(
      child: Column(children: [
        Text('الجولة ${gs.week + 1} • ${isHome ? 'على أرضك' : 'خارج أرضك'}',
            style: const TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _teamCol(u)),
          const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: kMuted)),
          Expanded(child: _teamCol(opp)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('ادخل المباراة'),
            onPressed: () => playMatch(context, gs),
          ),
        ),
      ]),
    );
  }

  Widget _teamCol(Team t) => Column(children: [
        teamBadge(t, size: 40),
        const SizedBox(height: 6),
        Text(t.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('قوة ${t.strength.toStringAsFixed(1)}', style: const TextStyle(color: kMuted, fontSize: 12)),
      ]);

  Widget _fixtures(BuildContext context) {
    final gs = widget.gs;
    final u = gs.user;
    return ListView(padding: const EdgeInsets.all(14), children: [
      _next(context),
      if (gs.roundResults.isNotEmpty) ...[
        sectionTitle('نتائج الجولة الأخيرة'),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final r in gs.roundResults)
              Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(r, style: const TextStyle(fontSize: 13))),
          ]),
        ),
      ],
      sectionTitle('جدول الموسم ${gs.season}'),
      Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < gs.rounds.length; i++) _row(i, gs, u),
        ]),
      ),
    ]);
  }

  Widget _row(int i, GameState gs, Team u) {
    final f = gs.rounds[i].firstWhere((x) => x.home == u.id || x.away == u.id);
    final isHome = f.home == u.id;
    final opp = gs.team(isHome ? f.away : f.home);
    Widget result;
    if (f.played) {
      final my = isHome ? f.hg! : f.ag!;
      final op = isHome ? f.ag! : f.hg!;
      final c = my > op ? kAccent : (my < op ? const Color(0xFFFF7043) : const Color(0xFFFFCA28));
      result = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: c.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
        child: Text('$my - $op', style: TextStyle(color: c, fontWeight: FontWeight.w800)),
      );
    } else {
      result = const Text('—', style: TextStyle(color: kMuted));
    }
    return Container(
      color: i == gs.week && !gs.seasonOver ? const Color(0x2200E676) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        SizedBox(width: 26, child: Text('${i + 1}', style: const TextStyle(color: kMuted, fontSize: 12))),
        teamBadge(opp, size: 24),
        const SizedBox(width: 10),
        Expanded(child: Text(opp.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        Text(isHome ? 'أرضك' : 'خارج', style: const TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(width: 10),
        result,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('المباريات')),
              ButtonSegment(value: 1, label: Text('الترتيب والهدافون')),
            ],
            selected: {view},
            onSelectionChanged: (s) => setState(() => view = s.first),
          ),
        ),
      ),
      Expanded(child: view == 0 ? _fixtures(context) : TableTab(gs: gs)),
    ]);
  }
}
