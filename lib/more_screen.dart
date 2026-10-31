import 'package:flutter/material.dart';
import 'facilities_screen.dart';
import 'club_screens.dart';
import 'cups_screen.dart';
import 'finance_screen.dart';
import 'game_state.dart';
import 'table_tab.dart';
import 'widgets.dart';

class MoreTab extends StatelessWidget {
  final GameState gs;
  final VoidCallback onRestart;
  const MoreTab({super.key, required this.gs, required this.onRestart});

  void _soon(BuildContext c, String what) => ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text('$what — قيد التطوير في المراحل القادمة')));

  Widget _tile(BuildContext c, IconData icon, String title, String sub, VoidCallback onTap, {bool soon = false}) {
    return Panel(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: kCard2,
          child: Icon(icon, color: soon ? kMuted : kAccent, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
        trailing: soon
            ? const Text('قريباً', style: TextStyle(color: kMuted, fontSize: 12))
            : const Icon(Icons.chevron_left),
      ),
    );
  }

  void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  void _settings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الإعدادات'),
        content: const Text('تُحفظ اللعبة تلقائياً بعد كل مباراة وكل صفقة.'),
        actions: [
          TextButton(
            onPressed: () async {
              await gs.save();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ ✅')));
              }
            },
            child: const Text('حفظ الآن'),
          ),
          FilledButton(
            onPressed: () async {
              await gs.save();
              if (ctx.mounted) Navigator.pop(ctx);
              onRestart();
            },
            child: const Text('حفظ والخروج للقائمة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(14), children: [
      _tile(context, Icons.account_balance_wallet_outlined, 'المالية',
          'الرصيد ${money(gs.user.budget)} • الديون ${money(gs.fin.debt)}', () => _push(context, FinanceScreen(gs: gs))),
      _tile(context, Icons.stadium_outlined, 'المنشآت', 'الملعب ومركز التدريب والأكاديمية', () => _push(context, FacilitiesScreen(gs: gs))),
      _tile(context, Icons.school_outlined, 'الأكاديمية', 'المواهب الشابة وترقية الأكاديمية', () => _push(context, AcademyScreen(gs: gs))),
      _tile(context, Icons.emoji_events_outlined, 'المسابقات', 'ترتيب ${gs.leagueName} والهدافون',
          () => _push(context, Scaffold(
                appBar: AppBar(title: Text(gs.leagueName), backgroundColor: kBg),
                body: SafeArea(child: ListenableBuilder(listenable: gs, builder: (_, __) => TableTab(gs: gs))),
              ))),
      _tile(context, Icons.military_tech_outlined, 'البطولات', 'كأس الدوري والبطولة القارية', () => _push(context, CupsScreen(gs: gs))),
      _tile(context, Icons.badge_outlined, 'الموظفون', 'المدربون والكشافة والأطباء', () => _push(context, StaffScreen(gs: gs))),
      _tile(context, Icons.campaign_outlined, 'الإعلام والجماهير', 'شعبية النادي والصحافة', () => _push(context, MediaScreen(gs: gs))),
      _tile(context, Icons.history_edu_outlined, 'تاريخ النادي', 'الألقاب والأرقام القياسية', () => _push(context, HistoryScreen(gs: gs))),
      _tile(context, Icons.settings_outlined, 'الإعدادات', 'حفظ والخروج', () => _settings(context)),
    ]);
  }
}
