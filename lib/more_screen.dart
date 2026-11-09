import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'facilities_screen.dart';
import 'business_screens.dart';
import 'club_screens.dart';
import 'settings_screen.dart';
import 'finance_screen.dart';
import 'game_state.dart';
import 'ranking_screen.dart';
import 'widgets.dart';
import 'trophies.dart';
import 'squad.dart';
import 'tactics.dart';

class TrophyScreen extends StatelessWidget {
  final GameState gs;
  const TrophyScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    final h = gs.honours;
    bool has(String h, String k) => h.contains(k);
    final groups = <(String, IconData, Color, List<String>)>[
      ('الدوري', Icons.emoji_events, kGold, [for (final x in h) if (x.startsWith('🏆 الدوري')) x]),
      ('كأس الدوري', Icons.military_tech, const Color(0xFFBA68C8), [for (final x in h) if (has(x, 'كأس الدوري')) x]),
      ('البطولة القارية', Icons.public, kBlue, [for (final x in h) if (has(x, 'القاري')) x]),
      ('كأس السوبر', Icons.workspace_premium, kAccent, [for (final x in h) if (has(x, 'السوبر')) x]),
    ];
    final used = {for (final g in groups) ...g.$4};
    final other = [for (final x in h) if (!used.contains(x)) x];
    return Scaffold(
      appBar: AppBar(title: const Text('🏆 خزانة البطولات')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(14), children: [
          if (h.isEmpty)
            const Panel(child: EmptyState(icon: Icons.emoji_events_outlined, title: 'الخزانة فارغة', subtitle: 'ستُعرض هنا كل الألقاب التي تفوز بها. الطريق طويل!')),
          for (final g in groups)
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  trophyImage(trophyKey(g.$1 == 'الدوري' ? gs.leagueName : (g.$1 == 'البطولة القارية' ? 'دوري أبطال أوروبا' : g.$1), gs.leagueName, isLeague: g.$1 == 'الدوري'), size: 52),
                  const SizedBox(width: 12),
                  Expanded(child: Text(g.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  Text('${g.$4.length}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: g.$4.isEmpty ? kMuted : g.$3)),
                ]),
                if (g.$4.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 14, runSpacing: 10, children: [
                    for (final x in g.$4)
                      Builder(builder: (_) {
                        final ph = parseHonour(x);
                        final comp = ph?.$1 ?? g.$1;
                        return Column(mainAxisSize: MainAxisSize.min, children: [
                          trophyImage(trophyKey(comp == 'الدوري' ? gs.leagueName : comp, gs.leagueName, isLeague: comp == 'الدوري'), size: 46),
                          Text(ph == null ? x : 'م${ph.$2}', style: const TextStyle(color: kMuted, fontSize: 11)),
                        ]);
                      }),
                  ]),
                ],
              ]),
            ),
          if (other.isNotEmpty) ...[
            sectionTitle('جوائز فردية'),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final x in other) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(x)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class TrainingScreen extends StatelessWidget {
  final GameState gs;
  const TrainingScreen({super.key, required this.gs});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('التدريب')),
        body: ListenableBuilder(
          listenable: gs,
          builder: (ctx, _) => ListView(padding: const EdgeInsets.all(14), children: [
            const Text('التركيز الأسبوعي', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 10),
            for (final e in trainingModes.entries)
              InkWell(
                onTap: () => gs.setTraining(e.key),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gs.training == e.key ? kPrimary : kLine, width: gs.training == e.key ? 2 : 1),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    if (gs.training == e.key) const Icon(Icons.check_circle_rounded, color: kPrimary),
                  ]),
                ),
              ),
          ]),
        ),
      );
}

class MoreTab extends StatefulWidget {
  final GameState gs;
  final VoidCallback onRestart;
  final VoidCallback onLogout;
  final void Function(int)? onNavigate;
  const MoreTab({super.key, required this.gs, required this.onRestart, required this.onLogout, this.onNavigate});
  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  String q = '';
  GameState get gs => widget.gs;

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
  void _tab(int i) => widget.onNavigate?.call(i);

  @override
  Widget build(BuildContext context) {
    final groups = <(String, List<(IconData, String, VoidCallback)>)>[
      ('الفريق', [
        (Icons.groups_rounded, 'مركز الفريق', () => _tab(1)),
        (Icons.account_tree_rounded, 'التكتيك والتشكيلة', () => _push(Scaffold(appBar: AppBar(title: const Text('التشكيلة والتكتيك')), body: TacticsTab(gs: gs)))),
        (Icons.bolt_rounded, 'التدريب', () => _push(TrainingScreen(gs: gs))),
        (Icons.healing_rounded, 'الإصابات والعلاج', () => _tab(1)),
      ]),
      ('السوق', [
        (Icons.swap_horiz_rounded, 'الانتقالات', () => _tab(2)),
        (Icons.search_rounded, 'الكشافة', () => _push(StaffScreen(gs: gs))),
        (Icons.compare_arrows_rounded, 'الإعارات', () => _tab(2)),
        (Icons.description_rounded, 'العقود', () => _push(Scaffold(appBar: AppBar(title: const Text('العقود')), body: ContractsView(gs: gs)))),
      ]),
      ('النادي', [
        (Icons.account_balance_wallet_rounded, 'المالية', () => _push(FinanceScreen(gs: gs))),
        (Icons.handshake_rounded, 'الرعاة', () => _push(SponsorsScreen(gs: gs))),
        (Icons.campaign_rounded, 'الجماهير', () => _push(MediaScreen(gs: gs))),
        (Icons.stadium_rounded, 'المنشآت', () => _push(FacilitiesScreen(gs: gs))),
        (Icons.school_rounded, 'الأكاديمية', () => _push(AcademyScreen(gs: gs))),
        (Icons.gavel_rounded, 'اللعب المالي النظيف', () => _push(FfpScreen(gs: gs))),
        (Icons.history_edu_rounded, 'تاريخ النادي', () => _push(HistoryScreen(gs: gs))),
      ]),
      ('المنافسات', [
        (Icons.leaderboard_rounded, 'الدوري والترتيب', () => _tab(3)),
        (Icons.emoji_events_rounded, 'الكؤوس', () => _tab(3)),
        (Icons.calendar_month_rounded, 'الجدول', () => _tab(3)),
        (Icons.public_rounded, 'العالم', () => _push(RankingScreen(gs: gs))),
      ]),
    ];
    final ql = q.trim().toLowerCase();
    bool match(String t) => ql.isEmpty || t.toLowerCase().contains(ql) || tr(t).toLowerCase().contains(ql);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 20), children: [
      const Text('كل الصفحات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      TextField(
        onChanged: (v) => setState(() => q = v),
        decoration: InputDecoration(
          hintText: tr('ابحث عن صفحة'),
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: kCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 6),
      for (final g in groups)
        if (g.$2.any((i) => match(i.$2))) ...[
          Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(g.$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              for (final it in g.$2)
                if (match(it.$2))
                  InkWell(
                    onTap: it.$3,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                      child: Row(children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: Icon(it.$1, color: kPrimary, size: 19),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(it.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                      ]),
                    ),
                  ),
            ],
          ),
        ],
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => _push(SettingsScreen(gs: gs, onRestart: widget.onRestart, onLogout: widget.onLogout)),
            icon: const Icon(Icons.settings_rounded),
            label: const Text('الإعدادات'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => _push(TrophyScreen(gs: gs)),
            icon: const Icon(Icons.military_tech_rounded),
            label: const Text('الأوسمة والإنجازات'),
          ),
        ),
      ]),
    ]);
  }
}
