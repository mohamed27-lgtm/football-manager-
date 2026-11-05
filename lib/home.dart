import 'package:flutter/material.dart';
import 'data_screen.dart';
import 'cups_screen.dart';
import 'game_state.dart';
import 'match_screen.dart';
import 'models.dart';
import 'finance_screen.dart';
import 'matches_screen.dart';
import 'leagues_screen.dart';
import 'more_screen.dart';
import 'squad.dart';
import 'business_screens.dart';
import 'club_screens.dart';
import 'team_tab.dart';
import 'facilities_screen.dart';
import 'widgets.dart';

class StartScreen extends StatelessWidget {
  final bool hasSave;
  final VoidCallback onContinue;
  final StartReal onStartReal;
  final String coachName;
  final VoidCallback onLogout;
  const StartScreen({
    super.key,
    required this.hasSave,
    required this.onContinue,
    required this.onStartReal,
    required this.coachName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: Text('أهلاً $coachName 👋', style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF0E3B24), Color(0xFF071A12), kBg]),
              border: Border.all(color: kLine),
              boxShadow: const [BoxShadow(color: Color(0x4400E676), blurRadius: 30, offset: Offset(0, 10))],
            ),
            child: Column(children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00A152)])),
                child: const Icon(Icons.sports_soccer, size: 48, color: Colors.black),
              ),
              const SizedBox(height: 16),
              const Text('مدرب كرة القدم', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('قُد ناديك نحو المجد', style: TextStyle(color: kMuted, fontSize: 15)),
            ]),
          ),
          const SizedBox(height: 24),
          if (hasSave) ...[
            GradientButton(label: 'متابعة المسيرة المحفوظة', icon: Icons.play_arrow_rounded, onPressed: onContinue),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _newCareer(context),
              icon: const Icon(Icons.public),
              label: const Text('مسيرة جديدة — اختر دوري وفريق'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ] else
            GradientButton(label: 'ابدأ مسيرتك', icon: Icons.public, onPressed: () => _newCareer(context)),
          const SizedBox(height: 18),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Perk(Icons.groups_2_outlined, 'لاعبون حقيقيون'),
            _Perk(Icons.account_balance_outlined, 'إدارة وانتقالات'),
            _Perk(Icons.emoji_events_outlined, 'بطولات وكؤوس'),
          ]),
        ]),
      ),
    );
  }

  void _newCareer(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LeaguesScreen(onStart: onStartReal)),
      );
}

class _Perk extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Perk(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Icon(icon, color: kAccent),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
      ]);
}

class HomeShell extends StatefulWidget {
  final GameState gs;
  final VoidCallback onRestart;
  final VoidCallback onLogout;
  const HomeShell({super.key, required this.gs, required this.onRestart, required this.onLogout});
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
        if (gs.celebration != null) {
          final name = gs.celebration!;
          gs.celebration = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (c) => Dialog(
                backgroundColor: kCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: kGold)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.2, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                      child: const Text('🏆', style: TextStyle(fontSize: 84)),
                    ),
                    const SizedBox(height: 8),
                    const Text('مبروك! بطل', style: TextStyle(color: kMuted)),
                    Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kGold)),
                    const SizedBox(height: 6),
                    Text('أُضيف اللقب إلى خزانة البطولات', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                    const SizedBox(height: 16),
                    GradientButton(label: 'رائع!', onPressed: () => Navigator.pop(c)),
                  ]),
                ),
              ),
            );
          });
        }
        final pages = <Widget>[
          DashboardTab(gs: gs, onRestart: widget.onRestart, onNavigate: (i) => setState(() => tab = i)),
          TeamTab(gs: gs),
          TransfersTab(gs: gs),
          MatchesTab(gs: gs),
          MoreTab(gs: gs, onRestart: widget.onRestart, onLogout: widget.onLogout),
        ];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kBg,
            titleSpacing: 14,
            title: Row(children: [
              teamBadge(gs.user, size: 26),
              const SizedBox(width: 10),
              Expanded(child: Text(gs.user.name, overflow: TextOverflow.ellipsis)),
            ]),
            actions: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FinanceScreen(gs: gs))),
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kCard2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kLine),
                  ),
                  child: Row(children: [
                    const Text('💰 ', style: TextStyle(fontSize: 13)),
                    AnimatedMoney(gs.user.budget,
                        style: TextStyle(fontWeight: FontWeight.w900, color: gs.user.budget < 0 ? const Color(0xFFFF7043) : kAccent)),
                  ]),
                ),
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
              NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'المسابقات'),
              NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'النادي'),
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

  void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  Widget _hero() {
    final u = gs.user;
    final c = teamColor(u.id);
    final dark = HSLColor.fromColor(c).withLightness(0.16).toColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c.withOpacity(0.85), dark]),
        boxShadow: [BoxShadow(color: c.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        teamBadge(u, size: 64),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${gs.leagueName} • الموسم ${gs.season}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('الأسبوع ${(gs.week + 1).clamp(1, gs.rounds.length)} من ${gs.rounds.length}${u.venue != null ? ' • ${u.venue}' : ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text('${gs.position}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kGold)),
            const Text('المركز', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ),
      ]),
    );
  }

  Widget _tile(IconData i, String label, String value, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kLine),
          ),
          child: Column(children: [
            Icon(i, color: color, size: 20),
            const SizedBox(height: 6),
            FittedBox(child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ),
      );

  Widget _board(BuildContext context) {
    final b = GameState.boardTitles[gs.boardKind!]!;
    return Panel(
      color: const Color(0xFF1E1A10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance, color: kGold, size: 20),
          const SizedBox(width: 8),
          Text(b.$1, style: const TextStyle(fontWeight: FontWeight.w900, color: kGold)),
        ]),
        const SizedBox(height: 8),
        Text(b.$2, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () => gs.answerBoard(true), child: Text(b.$3))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () => gs.answerBoard(false), child: Text(b.$4))),
        ]),
      ]),
    );
  }

  Widget _offersCard() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onNavigate(2),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kGold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kGold.withOpacity(0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.notifications_active, color: kGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('لديك ${gs.offers.length} عرض لشراء لاعبيك', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${gs.offers.first.club} يعرض ${money(gs.offers.first.amount)} على ${gs.offers.first.player.name}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.chevron_left, color: kGold),
            ]),
          ),
        ),
      );

  Widget _recent() {
    final r = gs.recentResults();
    if (r.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionTitle('آخر النتائج'),
      Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final e in r.reversed)
            () {
              final f = e.$1, home = e.$2;
              final my = home ? f.hg! : f.ag!, op = home ? f.ag! : f.hg!;
              final c = my > op ? kAccent : (my < op ? const Color(0xFFFF5252) : const Color(0xFFFFB300));
              final l = my > op ? 'ف' : (my < op ? 'خ' : 'ت');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(children: [
                  teamBadge(gs.team(f.home), size: 24),
                  const SizedBox(width: 8),
                  Expanded(child: Text(gs.team(f.home).name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(8)),
                    child: Text('${f.hg} - ${f.ag}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  Expanded(child: Text(gs.team(f.away).name, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  const SizedBox(width: 8),
                  teamBadge(gs.team(f.away), size: 24),
                  const SizedBox(width: 8),
                  CircleAvatar(radius: 11, backgroundColor: c, child: Text(l, style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w900))),
                ]),
              );
            }(),
        ]),
      ),
    ]);
  }

  Widget _stats() {
    final u = gs.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        _tile(Icons.account_balance_wallet_outlined, 'الرصيد', money(u.budget), u.budget < 0 ? const Color(0xFFFF7043) : kAccent),
        _tile(Icons.diamond_outlined, 'قيمة التشكيلة', money(gs.squadValue), kBlue),
        _tile(Icons.flag_outlined, 'النقاط', '${u.points}', kGold),
        _tile(Icons.trending_up, 'فارق الأهداف', '${u.gd >= 0 ? '+' : ''}${u.gd}', Colors.white),
      ]),
    );
  }

  Widget _actions(BuildContext context) {
    Widget a(IconData i, String t, Color c, VoidCallback f) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: f,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.withOpacity(0.35), c.withOpacity(0.12)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.withOpacity(0.5)),
                  ),
                  child: Icon(i, color: c, size: 26),
                ),
                const SizedBox(height: 6),
                Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        );
    Widget tile(IconData i, String t, String sub, Color c, VoidCallback f) => InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: f,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kLine),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(i, color: c, size: 25),
              ),
              const SizedBox(height: 8),
              Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: kMuted)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: [
          tile(Icons.account_balance_wallet_outlined, 'المالية', money(gs.user.budget), kGold, () => _push(context, FinanceScreen(gs: gs))),
          tile(Icons.groups_outlined, 'التشكيلة', 'الفريق والتكتيك', kAccent, () => onNavigate(1)),
          tile(Icons.swap_horiz, 'الانتقالات', gs.offers.isEmpty ? 'سوق اللاعبين' : '${gs.offers.length} عرض جديد', kBlue, () => onNavigate(2)),
          tile(Icons.stadium_outlined, 'الملعب', 'المنشآت والأكاديمية', const Color(0xFF26C6DA), () => _push(context, FacilitiesScreen(gs: gs))),
          tile(Icons.handshake_outlined, 'الرعاة', 'دخل ${wageK(gs.dealsIncome)}', kGold, () => _push(context, SponsorsScreen(gs: gs))),
          tile(Icons.badge_outlined, 'الطاقم', 'مدربون وكشافة', const Color(0xFFBA68C8), () => _push(context, StaffScreen(gs: gs))),
          tile(Icons.emoji_events_outlined, 'المسابقات', gs.leagueName, kAccent, () => onNavigate(3)),
          tile(Icons.shield_outlined, 'النادي', 'الإرث والإعدادات', const Color(0xFFFF8A65), () => onNavigate(4)),
        ],
      ),
    );
  }

  Widget _miniTable() {
    final t = gs.table;
    final i = t.indexOf(gs.user);
    var from = (i - 2).clamp(0, t.length - 1);
    final to = (from + 5).clamp(0, t.length);
    from = (to - 5).clamp(0, t.length);
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        for (var k = from; k < to; k++)
          Container(
            decoration: BoxDecoration(
              color: t[k] == gs.user ? const Color(0x2200E676) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            child: Row(children: [
              SizedBox(width: 26, child: Text('${k + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: k < 4 ? kAccent : (k >= t.length - 3 ? const Color(0xFFFF5252) : kMuted)))),
              teamBadge(t[k], size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(t[k].name, style: TextStyle(fontWeight: t[k] == gs.user ? FontWeight.w800 : FontWeight.w600))),
              Text('${t[k].played} لعب', style: const TextStyle(color: kMuted, fontSize: 11)),
              const SizedBox(width: 12),
              SizedBox(width: 30, child: Text('${t[k].points}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900))),
            ]),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = gs.user;
    final exp = gs.expiring;
    final showExp = exp.isNotEmpty && !gs.seasonOver && !gs.fired && gs.rounds.length - gs.week <= 8;
    return ListView(padding: const EdgeInsets.all(14), children: [
      _hero(),
      if (gs.fired)
        Panel(
          color: const Color(0xFF2A1414),
          child: Column(children: [
            const Text('🚫 تمت إقالتك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('فقدت ثقة مجلس الإدارة.', style: TextStyle(color: kMuted)),
            const SizedBox(height: 12),
            GradientButton(
              label: 'ابدأ مسيرة جديدة',
              onPressed: () async {
                await GameState.clearSave();
                onRestart();
              },
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
            GradientButton(label: 'ابدأ موسماً جديداً', icon: Icons.play_arrow, onPressed: gs.startNewSeason),
          ]),
        )
      else
        _nextMatch(context),
      if (gs.offers.isNotEmpty) _offersCard(),
      _actions(context),
      if (gs.boardKind != null) _board(context),
      _stats(),
      _recent(),
      sectionTitle('الترتيب', trailing: TextButton(onPressed: () => onNavigate(3), child: const Text('الجدول كاملاً'))),
      _miniTable(),
      Panel(
        child: Column(children: [
          Row(children: [
            const Icon(Icons.verified_user_outlined, size: 18, color: kMuted),
            const SizedBox(width: 8),
            const Text('ثقة الإدارة', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${gs.confidence.round()}%', style: TextStyle(fontWeight: FontWeight.w900, color: ratingColor(gs.confidence))),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: gs.confidence / 100,
              minHeight: 10,
              color: ratingColor(gs.confidence),
              backgroundColor: kCard2,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('🎯 هدف الموسم: المركز ${gs.objective} أو أفضل',
                style: TextStyle(color: gs.position <= gs.objective ? kAccent : kGold, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      if (showExp) ...[
        sectionTitle('عقود تنتهي هذا الموسم'),
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
          for (final n in gs.news.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 7, left: 8), decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle)),
                Expanded(child: Text(n, style: const TextStyle(height: 1.4))),
              ]),
            ),
        ]),
      ),
      SizedBox(height: u.budget < 0 ? 0 : 6),
    ]);
  }

  Widget _nextMatch(BuildContext context) {
    final pc = gs.pendingCup;
    if (pc != null) return CupMatchCard(gs: gs, cup: pc);
    final f = gs.userFixture!;
    final u = gs.user;
    final isHome = f.home == u.id;
    final opp = gs.team(isHome ? f.away : f.home);
    final lineupFit = u.lineup.isEmpty ? 100 : u.lineup.fold(0.0, (a, p) => a + p.fitness) / u.lineup.length;
    final absent = u.squad.where((p) => !p.available).length;
    final my = u.strength, op = opp.strength;
    final share = (my / (my + op)).clamp(0.2, 0.8).toDouble();
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(20)),
          child: Text('الجولة ${gs.week + 1} من ${gs.rounds.length} • ${isHome ? 'على أرضك' : 'خارج أرضك'}',
              style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _teamBox(isHome ? u : opp, strong: isHome)),
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('VS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kGold)),
          ),
          Expanded(child: _teamBox(isHome ? opp : u, strong: !isHome)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Text(my.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, color: kAccent)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(children: [
                Expanded(flex: (share * 100).round(), child: Container(height: 8, color: kAccent)),
                Expanded(flex: 100 - (share * 100).round(), child: Container(height: 8, color: const Color(0xFFFF5252))),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Text(op.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5252))),
        ]),
        const SizedBox(height: 4),
        const Text('القوة: أنت (أخضر) / الخصم (أحمر)', style: TextStyle(color: kMuted, fontSize: 11)),
        if (lineupFit < 80) ...[
          const SizedBox(height: 8),
          Text('⚠️ متوسط لياقة التشكيلة ${lineupFit.round()}% — فكّر في التدوير', style: const TextStyle(color: kGold, fontSize: 12)),
        ],
        if (absent > 0) ...[
          const SizedBox(height: 4),
          Text('🚑 $absent لاعبين غائبين (إصابة/إيقاف)', style: const TextStyle(color: Color(0xFFFF8A65), fontSize: 12)),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: GradientButton(label: 'ادخل المباراة', icon: Icons.play_arrow_rounded, onPressed: () => playMatch(context, gs)),
        ),
      ]),
    );
  }

  Widget _teamBox(Team t, {bool strong = false}) => Column(children: [
        teamBadge(t, size: 58),
        const SizedBox(height: 8),
        Text(t.name, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.w700)),
        const SizedBox(height: 6),
        FormDots(t.form),
      ]);
}
