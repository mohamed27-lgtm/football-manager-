import 'package:flutter/material.dart';
import 'data.dart';
import 'data_screen.dart';
import 'game_state.dart';
import 'match_screen.dart';
import 'models.dart';
import 'finance_screen.dart';
import 'matches_screen.dart';
import 'more_screen.dart';
import 'squad.dart';
import 'team_tab.dart';
import 'facilities_screen.dart';
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
          DashboardTab(gs: gs, onRestart: widget.onRestart, onNavigate: (i) => setState(() => tab = i)),
          TeamTab(gs: gs),
          TransfersTab(gs: gs),
          MatchesTab(gs: gs),
          MoreTab(gs: gs, onRestart: widget.onRestart),
        ];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kBg,
            title: Text(gs.user.name),
            actions: [
              Center(
                child: Text('💰 ${money(gs.user.budget)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'المالية',
                icon: const Icon(Icons.account_balance_wallet_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FinanceScreen(gs: gs))),
              ),
            ],
          ),
          body: SafeArea(child: pages[tab]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
              NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'الفريق'),
              NavigationDestination(icon: Icon(Icons.swap_horiz), selectedIcon: Icon(Icons.swap_horiz), label: 'الانتقالات'),
              NavigationDestination(icon: Icon(Icons.sports_soccer_outlined), selectedIcon: Icon(Icons.sports_soccer), label: 'المباريات'),
              NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'المزيد'),
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
  final void Function(int) onNavigate;
  const DashboardTab({super.key, required this.gs, required this.onRestart, required this.onNavigate});

  Widget _kv(String k, String v, {Color? color}) => Column(children: [
        Text(v, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(k, style: const TextStyle(color: kMuted, fontSize: 11)),
      ]);

  Widget _header() {
    final u = gs.user;
    return Panel(
      child: Row(children: [
        teamBadge(u, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('${gs.leagueName} • الموسم ${gs.season}', style: const TextStyle(color: kMuted, fontSize: 13)),
            Text('الأسبوع ${(gs.week + 1).clamp(1, gs.rounds.length)} من ${gs.rounds.length}${u.venue != null ? ' • ${u.venue}' : ''}',
                style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _shortcuts(BuildContext context) {
    Widget chip(IconData i, String t, VoidCallback f) => ActionChip(avatar: Icon(i, size: 18), label: Text(t), onPressed: f);
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return Panel(
      child: Wrap(spacing: 8, runSpacing: 4, children: [
        chip(Icons.groups_outlined, 'التشكيلة', () => onNavigate(1)),
        chip(Icons.swap_horiz, 'السوق', () => onNavigate(2)),
        chip(Icons.sports_soccer_outlined, 'المباريات', () => onNavigate(3)),
        chip(Icons.account_balance_wallet_outlined, 'المالية', () => push(FinanceScreen(gs: gs))),
        chip(Icons.stadium_outlined, 'المنشآت', () => push(FacilitiesScreen(gs: gs))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = gs.user;
    final exp = gs.expiring;
    final showExp = exp.isNotEmpty && !gs.seasonOver && !gs.fired && gs.rounds.length - gs.week <= 8;
    return ListView(padding: const EdgeInsets.all(14), children: [
      _header(),
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
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _kv('الرصيد', money(u.budget), color: u.budget < 0 ? const Color(0xFFFF7043) : kAccent),
          _kv('قيمة التشكيلة', money(gs.squadValue)),
          _kv('المركز', '${gs.position}'),
          _kv('النقاط', '${u.points}'),
        ]),
      ),
      _shortcuts(context),
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تم تجديد العقد ✅')));
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
      sectionTitle('آخر الأخبار'),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final n in gs.news.take(6)) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(n)),
        ]),
      ),
    ]);
  }

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
            onPressed: () => playMatch(context, gs),
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
