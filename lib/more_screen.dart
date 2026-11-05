import 'package:flutter/material.dart';
import 'facilities_screen.dart';
import 'business_screens.dart';
import 'club_screens.dart';
import 'settings_screen.dart';
import 'cups_screen.dart';
import 'finance_screen.dart';
import 'game_state.dart';
import 'table_tab.dart';
import 'widgets.dart';

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
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [g.$3.withOpacity(0.4), g.$3.withOpacity(0.1)]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: g.$3.withOpacity(0.5)),
                    ),
                    child: Icon(g.$2, color: g.$3, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(g.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  Text('${g.$4.length}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: g.$4.isEmpty ? kMuted : g.$3)),
                ]),
                if (g.$4.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final x in g.$4)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(10)),
                        child: Text(x.replaceAll('🏆 ', '').replaceAll('—', '•'), style: const TextStyle(fontSize: 12)),
                      ),
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

class MoreTab extends StatelessWidget {
  final GameState gs;
  final VoidCallback onRestart;
  final VoidCallback onLogout;
  const MoreTab({super.key, required this.gs, required this.onRestart, required this.onLogout});

  Widget _tile(BuildContext c, IconData icon, String title, String sub, VoidCallback onTap, {Color color = kAccent}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.35), color.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.45)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.chevron_left, color: kMuted),
        ]),
      ),
    );
  }

  Widget _group(String title, List<Widget> tiles) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionTitle(title),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < tiles.length; i++) ...[
              tiles[i],
              if (i < tiles.length - 1) const Divider(height: 1, indent: 68),
            ],
          ]),
        ),
      ]);

  void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final u = gs.user;
    return ListView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 20), children: [
      Panel(
        child: Row(children: [
          teamBadge(u, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text('${gs.leagueName} • الموسم ${gs.season}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
              if (u.venue != null) Text(u.venue!, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          Column(children: [
            Text('${gs.honours.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGold)),
            const Text('لقب', style: TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ]),
      ),
      _group('الإدارة والمال', [
        _tile(context, Icons.account_balance_wallet_outlined, 'المالية', 'الرصيد ${money(gs.user.budget)} • الديون ${money(gs.fin.debt)}', () => _push(context, FinanceScreen(gs: gs)), color: kAccent),
        _tile(context, Icons.handshake_outlined, 'الرعاة', 'دخل الرعاة ${wageK(gs.dealsIncome)}/جولة', () => _push(context, SponsorsScreen(gs: gs)), color: kGold),
        _tile(context, Icons.gavel_outlined, 'اللعب المالي النظيف', 'الرواتب ${(gs.ffpRatio * 100).round()}% من الإيرادات', () => _push(context, FfpScreen(gs: gs)), color: const Color(0xFFFF5252)),
      ]),
      _group('النادي', [
        _tile(context, Icons.badge_outlined, 'الموظفون', 'المدربون والكشافة والأطباء والمحللون', () => _push(context, StaffScreen(gs: gs)), color: kGold),
        _tile(context, Icons.stadium_outlined, 'المنشآت', 'الملعب ومركز التدريب والأكاديمية', () => _push(context, FacilitiesScreen(gs: gs)), color: const Color(0xFF26C6DA)),
        _tile(context, Icons.school_outlined, 'الأكاديمية', 'المواهب الشابة وترقية الأكاديمية', () => _push(context, AcademyScreen(gs: gs)), color: kBlue),
        _tile(context, Icons.campaign_outlined, 'الإعلام والجماهير', 'شعبية النادي والصحافة', () => _push(context, MediaScreen(gs: gs)), color: const Color(0xFFFF8A65)),
      ]),
      _group('الإرث', [
        _tile(context, Icons.emoji_events_outlined, 'خزانة البطولات', '${gs.honours.length} لقباً', () => _push(context, TrophyScreen(gs: gs)), color: kGold),
        _tile(context, Icons.history_edu_outlined, 'تاريخ النادي', 'المواسم والأرقام القياسية', () => _push(context, HistoryScreen(gs: gs)), color: const Color(0xFFBA68C8)),
      ]),
      _group('النظام', [
        _tile(context, Icons.settings_outlined, 'الإعدادات', 'الحفظ والخروج والعرض', () => _push(context, SettingsScreen(gs: gs, onRestart: onRestart, onLogout: onLogout)), color: kMuted),
      ]),
    ]);
  }
}
