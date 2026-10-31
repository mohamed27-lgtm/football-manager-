import 'package:flutter/material.dart';
import 'data.dart';
import 'data_screen.dart';
import 'game_state.dart';
import 'match_screen.dart';
import 'models.dart';
import 'squad.dart';
import 'tactics.dart';
import 'widgets.dart';

class StartScreen extends StatelessWidget {
  final void Function(int teamId) onStart;
  final bool hasSave;
  final VoidCallback onContinue;
  final StartReal onStartReal;
  const StartScreen({super.key, required this.onStart, required this.hasSave, required this.onContinue, required this.onStartReal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SizedBox(height: 12),
          const Text('⚽ مدرب كرة القدم',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('قُد ناديك نحو المجد', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
          const SizedBox(height: 18),
          if (hasSave)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.play_arrow),
                label: const Text('متابعة المسيرة المحفوظة'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DataScreen(onStart: onStartReal)),
              ),
              icon: const Icon(Icons.public),
              label: const Text('🌍 دوريات وأندية ولاعبون حقيقيون (تنزيل)'),
            ),
          ),
          sectionTitle(hasSave ? 'أو ابدأ مسيرة جديدة بالأندية الافتراضية' : 'أو اختر نادياً افتراضياً'),
          for (var i = 0; i < clubTemplates.length; i++)
            Panel(
              padding: EdgeInsets.zero,
              child: ListTile(
                onTap: () => onStart(i),
                leading: CircleAvatar(backgroundColor: teamColor(i), radius: 16),
                title: Text(clubTemplates[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${'★' * clubTemplates[i].$2}  •  ميزانية ${12 + clubTemplates[i].$2 * 8}M  •  '
                  '${clubTemplates[i].$2 >= 4 ? 'سهل' : clubTemplates[i].$2 == 3 ? 'متوسط' : 'تحدٍّ صعب'}',
                ),
                trailing: const Icon(Icons.chevron_left),
              ),
            ),
        ]),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final GameState gs;
  final VoidCallback onRestart;
  const HomeShell({super.key, required this.gs, required this.onRestart});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gs,
      builder: (context, _) {
        final gs = widget.gs;
        final pages = <Widget>[
          DashboardTab(gs: gs, onRestart: widget.onRestart),
          SquadTab(gs: gs),
          TacticsTab(gs: gs),
          TableTab(gs: gs),
          TransfersTab(gs: gs),
        ];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kBg,
            title: Text(gs.user.name),
            actions: [
              Center(
                child: Text('💰 ${money(gs.user.budget)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              PopupMenuButton<int>(
                onSelected: (_) async {
                  await gs.save();
                  widget.onRestart();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 0, child: Text('حفظ والخروج للقائمة')),
                ],
              ),
            ],
          ),
          body: SafeArea(child: pages[tab]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
              NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'التشكيلة'),
              NavigationDestination(icon: Icon(Icons.sports_soccer_outlined), selectedIcon: Icon(Icons.sports_soccer), label: 'التكتيك'),
              NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard), label: 'الترتيب'),
              NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: 'النادي'),
            ],
          ),
        );
      },
    );
  }
}

class DashboardTab extends StatelessWidget {
  final GameState gs;
  final VoidCallback onRestart;
  const DashboardTab({super.key, required this.gs, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final u = gs.user;
    final exp = gs.expiring;
    final showExp = exp.isNotEmpty && !gs.seasonOver && !gs.fired && gs.rounds.length - gs.week <= 8;
    return ListView(padding: const EdgeInsets.all(14), children: [
      if (gs.fired)
        Panel(
          color: const Color(0xFF2A1414),
          child: Column(children: [
            const Text('🚫 تمت إقالتك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('فقدت ثقة مجلس الإدارة.', style: TextStyle(color: kMuted)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await GameState.clearSave();
                onRestart();
              },
              child: const Text('ابدأ مسيرة جديدة'),
            ),
          ]),
        )
      else if (gs.seasonOver)
        Panel(
          child: Column(children: [
            Text('🏁 انتهى الموسم ${gs.season}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('أنهيت الدوري في المركز ${gs.position} (الهدف: ${gs.objective})', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 12),
            FilledButton(onPressed: gs.startNewSeason, child: const Text('ابدأ موسماً جديداً')),
          ]),
        )
      else
        _nextMatch(context),
      Panel(
        child: Column(children: [
          Row(children: [
            const Text('ثقة الإدارة'),
            const Spacer(),
            Text('${gs.confidence.round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: gs.confidence / 100,
              minHeight: 10,
              color: ratingColor(gs.confidence),
              backgroundColor: kCard2,
            ),
          ),
          const SizedBox(height: 10),
          Text('🎯 هدف الموسم: المركز ${gs.objective} أو أفضل',
              style: TextStyle(color: gs.position <= gs.objective ? kAccent : const Color(0xFFFFCA28), fontSize: 13)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _kv('المركز', '${gs.position}'),
            _kv('النقاط', '${u.points}'),
            _kv('الموسم', '${gs.season}'),
            _kv('الرواتب/أسبوع', money(gs.weeklyWages)),
          ]),
        ]),
      ),
      if (showExp) ...[
        sectionTitle('⏳ عقود تنتهي هذا الموسم'),
        Panel(
          child: Column(children: [
            for (final p in exp)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  RatingBadge(p.overall, size: 30),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.name)),
                  TextButton(
                    onPressed: () {
                      final err = gs.renew(p);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err ?? 'تم تجديد العقد ✅')));
                    },
                    child: Text('جدّد ${money(gs.renewCost(p))}'),
                  ),
                ]),
              ),
          ]),
        ),
      ],
      sectionTitle('التدريب الأسبوعي'),
      Panel(
        child: Wrap(spacing: 8, runSpacing: 4, children: [
          for (final e in trainingModes.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: gs.training == e.key,
              onSelected: (_) => gs.setTraining(e.key),
            ),
        ]),
      ),
      if (gs.roundResults.isNotEmpty) ...[
        sectionTitle('نتائج الجولة الماضية'),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final r in gs.roundResults)
              Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(r, style: const TextStyle(fontSize: 13))),
          ]),
        ),
      ],
      sectionTitle('آخر الأخبار'),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final n in gs.news.take(6))
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(n)),
        ]),
      ),
    ]);
  }

  Widget _kv(String k, String v) => Column(children: [
        Text(v, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        Text(k, style: const TextStyle(color: kMuted, fontSize: 11)),
      ]);

  Widget _nextMatch(BuildContext context) {
    final f = gs.userFixture!;
    final u = gs.user;
    final isHome = f.home == u.id;
    final opp = gs.team(isHome ? f.away : f.home);
    final lineupFit = u.lineup.isEmpty ? 100 : u.lineup.fold(0.0, (a, p) => a + p.fitness) / u.lineup.length;
    final absent = u.squad.where((p) => !p.available).length;
    return Panel(
      child: Column(children: [
        Text('الجولة ${gs.week + 1} من ${gs.rounds.length} • ${isHome ? 'على أرضك' : 'خارج أرضك'}',
            style: const TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _teamBox(u)),
          const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: kMuted)),
          Expanded(child: _teamBox(opp)),
        ]),
        const SizedBox(height: 10),
        if (lineupFit < 80)
          Text('⚠️ متوسط لياقة التشكيلة ${lineupFit.round()}% — فكّر في التدوير',
              style: const TextStyle(color: Color(0xFFFFCA28), fontSize: 12)),
        if (absent > 0)
          Text('🚑 $absent لاعبين غائبين (إصابة/إيقاف)', style: const TextStyle(color: Color(0xFFFF8A65), fontSize: 12)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('ادخل المباراة'),
            onPressed: () async {
              gs.startMatch();
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchScreen(gs: gs)));
            },
          ),
        ),
      ]),
    );
  }

  Widget _teamBox(Team t) => Column(children: [
        teamBadge(t, size: 40),
        const SizedBox(height: 6),
        Text(t.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('قوة ${t.strength.toStringAsFixed(1)}', style: const TextStyle(color: kMuted, fontSize: 12)),
      ]);
}

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
