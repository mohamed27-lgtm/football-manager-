import 'package:flutter/material.dart' hide Text;
import 'flags.dart';
import 'game_state.dart';
import 'i18n.dart';
import 'lineup_pages.dart';
import 'match_pages.dart' show whiteBtn;
import 'national_team_screen.dart';
import 'widgets.dart';

/// واجهة مدرب المنتخب: مختلفة عن واجهة النادي — تصنيف فيفا، النافذة الدولية القادمة، الاستدعاءات والنتائج
class NationalDashboard extends StatelessWidget {
  final GameState gs;
  const NationalDashboard({super.key, required this.gs});

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final n = gs.natJob!;
    gs.ensureNat();
    final rank = gs.nat.pubRanking;
    final pos = rank.indexOf(n) + 1;
    final pts = gs.nat.pub[n] ?? gs.nat.rating(n);
    final w = gs.nextWindow;
    final called = gs.natCalled;
    final r = gs.natRecord(n);
    final ok = gs.natObjective <= 0 || (pos > 0 && pos <= gs.natObjective);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF14543C), Color(0xFF0B2A20)]),
        ),
        child: Row(children: [
          FlagBadge(n, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('منتخب $n', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              Text('المدرب • ${gs.mgrTier}', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
              Text('هدف الاتحاد: تصنيف فيفا ${gs.natObjective > 0 ? gs.natObjective : '—'} أو أفضل', style: TextStyle(color: ok ? const Color(0xFF9FE6C6) : const Color(0xFFFFB4A6), fontSize: 12.5)),
            ]),
          ),
          Column(children: [
            Text(pos > 0 ? '#$pos' : '—', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kGold)),
            const Text('تصنيف فيفا', style: TextStyle(fontSize: 11, color: Colors.white70)),
            Text(pts.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: Row(children: [
          const Icon(Icons.event_rounded, color: kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('النافذة الدولية القادمة', style: TextStyle(fontWeight: FontWeight.w900)),
              Text(w == null ? 'لا نوافذ متبقية هذا الموسم' : _date(gs.windowDate(w)), style: const TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
          ),
          Text('${r.w}-${r.d}-${r.l}', style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimary)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: GradientButton(label: gs.seasonOver ? 'ابدأ موسماً جديداً' : 'متابعة الأسبوع', icon: Icons.play_arrow_rounded, onPressed: gs.seasonOver ? gs.startNewSeason : gs.spectateRound)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: whiteBtn('الاستدعاءات (${called.length})', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CallupScreen(gs: gs))), icon: Icons.groups_rounded)),
        const SizedBox(width: 8),
        Expanded(child: whiteBtn('صفحة المنتخب', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NationScreen(gs: gs, nation: n))), icon: Icons.flag_rounded)),
      ]),
      const SizedBox(height: 14),
      const Text('نتائج منتخبك', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      if (gs.natJobLog.isEmpty)
        const Panel(child: EmptyState(icon: Icons.sports_soccer_rounded, title: 'لا مباريات بعد', subtitle: 'تُلعب مباريات المنتخب في النوافذ الدولية بالمحرك الكامل. تابع الأسابيع.'))
      else
        for (final l in gs.natJobLog.take(8))
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
            child: Row(children: [
              FlagBadge('${l[1]}', size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text('${l[1]} • ${(l[4] as int) == 0 ? 'رسمية' : 'ودية'}', style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('${l[2]}-${l[3]}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: (l[2] as int) > (l[3] as int) ? const Color(0xFF1FA58A) : ((l[2] as int) < (l[3] as int) ? const Color(0xFFE5533D) : kMuted))),
            ]),
          ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), foregroundColor: const Color(0xFFE5533D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: () async {
          final ok = await confirmDialog(context, title: 'مغادرة المنتخب', body: 'ستتوقف عن تدريب منتخب $n وتبحث عن نادٍ جديد.', confirm: 'مغادرة', danger: true);
          if (ok == true) gs.leaveNatJob();
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('ترك المنتخب'),
      ),
    ]);
  }
}

/// صفحة النادي المقفلة أثناء تدريب منتخب
class NatLocked extends StatelessWidget {
  final GameState gs;
  const NatLocked({super.key, required this.gs});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline_rounded, size: 46, color: kMuted),
            const SizedBox(height: 12),
            Text('أنت مدرب منتخب ${gs.natJob}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            const Text('لا يمكن تدريب نادٍ ومنتخب معاً، وناديك السابق يلعب آلياً. أدِر المنتخب من الرئيسية.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, height: 1.5)),
          ]),
        ),
      );
}
