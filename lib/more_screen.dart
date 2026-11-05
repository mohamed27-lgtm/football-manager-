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
    return ListView(padding: const EdgeInsets.fromLTRB(14, 0, 14, 20), children: [
      _group('النادي', [
        _tile(context, Icons.stadium_outlined, 'المنشآت', 'الملعب ومركز التدريب والأكاديمية', () => _push(context, FacilitiesScreen(gs: gs)), color: const Color(0xFF26C6DA)),
        _tile(context, Icons.school_outlined, 'الأكاديمية', 'المواهب الشابة وترقية الأكاديمية', () => _push(context, AcademyScreen(gs: gs)), color: kBlue),
        _tile(context, Icons.badge_outlined, 'الطاقم الفني', 'المدربون والكشافة والأطباء', () => _push(context, StaffScreen(gs: gs)), color: kGold),
        _tile(context, Icons.campaign_outlined, 'الإعلام والجماهير', 'شعبية النادي والصحافة', () => _push(context, MediaScreen(gs: gs)), color: const Color(0xFFFF8A65)),
        _tile(context, Icons.history_edu_outlined, 'تاريخ النادي', 'الألقاب والأرقام القياسية', () => _push(context, HistoryScreen(gs: gs)), color: const Color(0xFFBA68C8)),
      ]),
      _group('الأعمال والمال', [
        _tile(context, Icons.account_balance_wallet_outlined, 'المالية', 'الرصيد ${money(gs.user.budget)} • الديون ${money(gs.fin.debt)}', () => _push(context, FinanceScreen(gs: gs)), color: kAccent),
        _tile(context, Icons.handshake_outlined, 'الرعاة', 'دخل الرعاة ${wageK(gs.dealsIncome)}/جولة', () => _push(context, SponsorsScreen(gs: gs)), color: kGold),
        _tile(context, Icons.gavel_outlined, 'اللعب المالي النظيف', 'الرواتب ${(gs.ffpRatio * 100).round()}% من الإيرادات', () => _push(context, FfpScreen(gs: gs)), color: const Color(0xFFFF5252)),
      ]),
      _group('المسابقات', [
        _tile(context, Icons.emoji_events_outlined, 'الدوري', 'ترتيب ${gs.leagueName} والهدافون',
            () => _push(context, Scaffold(
                  appBar: AppBar(title: Text(gs.leagueName)),
                  body: SafeArea(child: ListenableBuilder(listenable: gs, builder: (_, __) => TableTab(gs: gs))),
                )), color: kGold),
        _tile(context, Icons.military_tech_outlined, 'الكؤوس والبطولة القارية', 'كأس الدوري والبطولة القارية', () => _push(context, CupsScreen(gs: gs)), color: const Color(0xFFBA68C8)),
      ]),
      _group('النظام', [
        _tile(context, Icons.settings_outlined, 'الإعدادات', 'الحفظ والخروج والعرض', () => _push(context, SettingsScreen(gs: gs, onRestart: onRestart, onLogout: onLogout)), color: kMuted),
      ]),
    ]);
  }
}
