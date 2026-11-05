import 'package:flutter/material.dart';
import 'cups.dart';
import 'game_state.dart';
import 'match_screen.dart';
import 'models.dart';
import 'widgets.dart';

/// بطاقة مباراة الكأس المستحقة (تحلّ محل مباراة الدوري حتى تُلعب)
class CupMatchCard extends StatelessWidget {
  final GameState gs;
  final Cup cup;
  const CupMatchCard({super.key, required this.gs, required this.cup});

  @override
  Widget build(BuildContext context) {
    final t = cup.userTie(gs.user.id)!;
    final home = gs.team(t.home), away = gs.team(t.away);
    return Panel(
      child: Column(children: [
        Text('🏆 ${cup.name} • ${cup.roundName}', style: const TextStyle(fontWeight: FontWeight.w800, color: kAccent)),
        const Text('مباراة إقصائية — التعادل يُحسم بركلات الترجيح', style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _box(home)),
          const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: kMuted)),
          Expanded(child: _box(away)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('ادخل مباراة الكأس'),
            onPressed: () => playMatch(context, gs),
          ),
        ),
      ]),
    );
  }

  Widget _box(Team t) => Column(children: [
        teamBadge(t, size: 40),
        const SizedBox(height: 6),
        Text(t.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('قوة ${t.strength.toStringAsFixed(1)}', style: const TextStyle(color: kMuted, fontSize: 12)),
      ]);
}

class CupsScreen extends StatelessWidget {
  final GameState gs;
  const CupsScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🏆 البطولات'), backgroundColor: kBg),
        body: SafeArea(child: CupsBody(gs: gs)),
      );
}

/// محتوى البطولات (يُستخدم داخل تبويب المسابقات)
class CupsBody extends StatelessWidget {
  final GameState gs;
  const CupsBody({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    final cups = [gs.domestic!, gs.continental!, if (gs.superCup != null) gs.superCup!];
    return DefaultTabController(
      length: cups.length,
      child: Column(children: [
        TabBar(tabs: [
          const Tab(text: 'كأس الدوري'),
          const Tab(text: 'القاري'),
          if (cups.length > 2) const Tab(text: 'السوبر'),
        ]),
        Expanded(
          child: ListenableBuilder(
            listenable: gs,
            builder: (context, _) => TabBarView(children: [
              for (final c in cups) _CupView(gs: gs, cup: c),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CupView extends StatelessWidget {
  final GameState gs;
  final Cup cup;
  const _CupView({required this.gs, required this.cup});

  @override
  Widget build(BuildContext context) {
    final uid = gs.user.id;
    final inCup = cup.alive.contains(uid);
    final everIn = inCup || cup.log.any((l) => l.contains(gs.user.name));
    String status;
    if (cup.done) {
      status = cup.champion == uid ? '🏆 أنت البطل!' : 'البطل: ${gs.team(cup.champion!).name}';
    } else if (inCup) {
      status = cup.byes.contains(uid) ? 'تأهلت مباشرة من ${cup.roundName}' : 'ما زلت في المنافسة — ${cup.roundName}';
    } else if (everIn) {
      status = 'خرجت من البطولة';
    } else {
      status = cup.continental ? 'لم تتأهل هذا الموسم (يتأهل أول 3 في الدوري)' : (cup.key == 'sup' ? 'لا تشارك في السوبر' : 'خرجت من البطولة');
    }
    final due = cup.dueWeek;
    final logs = <String, List<String>>{};
    for (final l in cup.log) {
      final i = l.indexOf('|');
      logs.putIfAbsent(l.substring(0, i), () => []).add(l.substring(i + 1));
    }
    return ListView(padding: const EdgeInsets.all(14), children: [
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cup.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(status, style: const TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
          if (!cup.done && due != null)
            Text('الدور القادم (${cup.roundName}) قبل جولة الدوري ${due + 1}', style: const TextStyle(color: kMuted, fontSize: 12)),
          Text('${cup.alive.length} فرق متبقية', style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
      ),
      if (cup.groups.isNotEmpty)
        for (var gi = 0; gi < cup.groups.length; gi++) ...[
          sectionTitle('المجموعة ${String.fromCharCode(65 + gi)}'),
          Panel(
            child: Column(children: [
              const Row(children: [
                Expanded(child: Text('', style: TextStyle(fontSize: 11))),
                SizedBox(width: 26, child: Text('لعب', style: TextStyle(color: kMuted, fontSize: 11))),
                SizedBox(width: 30, child: Text('فارق', style: TextStyle(color: kMuted, fontSize: 11))),
                SizedBox(width: 30, child: Text('نقاط', style: TextStyle(color: kMuted, fontSize: 11))),
              ]),
              for (final (i, r) in groupTable(cup, cup.groups[gi]).indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        '${i + 1}. ${gs.team(r.id).name}',
                        style: TextStyle(
                          fontWeight: r.id == uid ? FontWeight.w800 : FontWeight.w400,
                          color: i < 2 ? kAccent : null,
                        ),
                      ),
                    ),
                    SizedBox(width: 26, child: Text('${r.p}')),
                    SizedBox(width: 30, child: Text('${r.gd}')),
                    SizedBox(width: 30, child: Text('${r.pts}', style: const TextStyle(fontWeight: FontWeight.w800))),
                  ]),
                ),
            ]),
          ),
        ],
      if (!cup.done) ...[
        sectionTitle('قرعة ${cup.roundName}'),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final t in cup.ties)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${gs.team(t.home).name}  ×  ${gs.team(t.away).name}',
                  style: TextStyle(fontWeight: (t.home == uid || t.away == uid) ? FontWeight.w800 : FontWeight.w400),
                ),
              ),
            for (final b in cup.byes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${gs.team(b).name} — تأهل مباشرة', style: const TextStyle(color: kMuted)),
              ),
          ]),
        ),
      ],
      for (final e in logs.entries.toList().reversed) ...[
        sectionTitle(e.key),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final r in e.value) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(r)),
          ]),
        ),
      ],
    ]);
  }
}
