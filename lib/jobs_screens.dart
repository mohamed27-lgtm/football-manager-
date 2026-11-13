import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'match_pages.dart' show whiteBtn, gameBar;
import 'widgets.dart';
import 'flags.dart';
import 'club_ui.dart';
import 'calendar.dart';

/// عقدي: ثقة الإدارة وسمعة المدرب، عروض الأندية الأخرى، والاستقالة
class JobsScreen extends StatefulWidget {
  final GameState gs;
  const JobsScreen({super.key, required this.gs});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  GameState get gs => widget.gs;
  final Set<String> _open = {};

  Widget _kv(String k, String v, {Color? c}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(color: kMuted, fontSize: 13.5))),
          Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: c)),
        ]),
      );

  Widget _goal(String t, double v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: [
          Row(children: [Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))), Text('${(v * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900))]),
          const SizedBox(height: 5),
          Bar(v, c),
        ]),
      );

  String _divName(int d) => d <= 1 ? 'الدرجة الأولى' : d == 2 ? 'الدرجة الثانية' : 'الدرجة $d';

  Future<void> _resign() async {
    final ok = await confirmDialog(context,
        title: 'الاستقالة من المنصب',
        body: 'ستعلن استقالتك من ${gs.user.name} وتنخفض سمعتك كمدرب إن كان عقدك سارياً. تستمر اللعبة كالمعتاد مع ناديك، وتصلك عروض من أندية أخرى تنتقل إليها متى شئت.',
        confirm: 'استقالة',
        danger: true);
    if (ok != true) return;
    gs.resign();
    if (mounted) setState(() {});
  }

  Future<void> _accept(JobOffer o) async {
    final later = gs.seasonOver && !gs.fired;
    final under = !gs.fired && !gs.resigned && gs.contractLeft > 1 && !later;
    final ok = await confirmDialog(context,
        title: 'قبول عرض ${o.club}',
        body: later
            ? 'ستنتقل لتدريب ${o.club} مع بداية الموسم القادم.'
            : under
                ? 'عقدك مع ${gs.user.name} ما زال سارياً، والمغادرة تخفض سمعتك. هل تقبل عرض ${o.club}؟'
                : 'ستصبح مدرباً لنادي ${o.club} فوراً.',
        confirm: 'قبول');
    if (ok != true) return;
    final err = gs.acceptJob(o);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? (later ? 'تم الاتفاق مع ${o.club} ✅' : 'مبروك! أصبحت مدرباً لنادي ${o.club} ✅'))));
    if (err == null && !later) Navigator.of(context).pop();
    setState(() {});
  }

  Widget _offer(JobOffer o) {
    final open = _open.contains(o.club);
    final club = gs.clubNamed(o.club);
    final tempting = club.reputation >= gs.user.reputation;
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          teamBadge(club, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.club, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              Text('${o.years} ${o.years == 1 ? 'سنة' : 'سنوات'} • ${money(gs.offerWeekly(o.club))}/أسبوع', style: const TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
          ),
          if (tempting) const Pill('مغرٍ', Color(0xFF1FA58A)),
        ]),
        if (open) ...[
          const SizedBox(height: 8),
          Text(o.reason, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 4),
          _kv('الدوري', _divName(o.div)),
          _kv('هدف الإدارة', 'المركز ${o.objective} أو أفضل'),
          _kv('ميزانية النادي', gs.money1(o.budget)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: whiteBtn('رفض', () {
            gs.rejectJob(o);
            setState(() {});
          })),
          const SizedBox(width: 8),
          Expanded(
            child: open
                ? GradientButton(label: 'قبول العرض', icon: Icons.check_rounded, onPressed: () => _accept(o))
                : GestureDetector(
                    onTap: () => setState(() => _open.add(o.club)),
                    child: Container(height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFA9D4F8), borderRadius: BorderRadius.circular(14)), child: const Text('تفاصيل', style: TextStyle(color: Color(0xFF15233D), fontWeight: FontWeight.w900, fontSize: 15))),
                  ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _acceptNat(JobOffer o) async {
    final ok = await confirmDialog(context,
        title: 'منتخب ${o.club}',
        body: gs.natJob != null
            ? 'تدرّب منتخباً بالفعل.'
            : 'تدريب المنتخب يعني ترك ${gs.user.name}: لا يمكن تدريب نادٍ ومنتخب معاً. يواصل ناديك اللعب آلياً دون تدخلك. هل تقبل؟',
        confirm: 'قبول وترك النادي',
        danger: true);
    if (ok != true) return;
    final err = gs.acceptNatOffer(o);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'أصبحت مدرباً لمنتخب ${o.club} ✅')));
    if (err == null) Navigator.of(context).pop();
    setState(() {});
  }

  Widget _natOffer(JobOffer o) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGold.withOpacity(0.7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            FlagBadge(o.club, size: 44),
            const SizedBox(width: 10),
            Expanded(child: Text('منتخب ${o.club}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
          ]),
          const SizedBox(height: 6),
          Text(o.reason, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 8),
          _kv('مدة العقد', '${o.years} مواسم'),
          _kv('هدف الاتحاد', 'تصنيف فيفا ${o.objective} أو أفضل'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: GradientButton(label: 'قبول العرض', icon: Icons.check_rounded, onPressed: () => _acceptNat(o))),
            const SizedBox(width: 8),
            Expanded(child: whiteBtn('رفض', () {
              gs.natOffers.remove(o);
              gs.touch();
              setState(() {});
            })),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final jobs = gs.availableJobs;
    final under = !gs.fired;
    return Scaffold(
      appBar: gameBar(context, gs, 'عقدي والعروض'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        CardBox(
          child: Column(children: [
            Row(children: [
              teamBadge(gs.user, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(gs.fired ? (gs.resigned ? 'مستقيل' : 'مُقال') : 'عقدي مع ${gs.user.name}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  if (under) Text('ينتهي ${GameCalendar.monthNames[5]} ${2025 + gs.season + gs.contractLeft} • ${money(gs.mgrWeekly)}/أسبوع', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                  Text('سمعتك: ${gs.mgrTier} (${gs.mgrRep.round()})', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                ]),
              ),
            ]),
            if (gs.pendingJob != null) _kv('وجهتك القادمة', gs.pendingJob!, c: kPrimary),
          ]),
        ),
        if (under)
          StatTiles([
            ('${gs.confidence.round()}%', 'ثقة الإدارة', gs.confidence >= 50 ? const Color(0xFF1FA58A) : const Color(0xFFE5533D)),
            (money(gs.mgrWeekly * 52 * 0.3), 'بند الفسخ', kPrimary),
            (money(gs.mgrWeekly * 52 * 0.055), 'مكافأة الهدف', const Color(0xFFF5A524)),
          ]),
        if (under)
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('أهداف الإدارة لهذا الموسم', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              _goal('إنهاء الدوري ضمن أول ${gs.objective}', gs.position <= gs.objective ? 1.0 : (1 - (gs.position - gs.objective) / max(1, gs.teams.length - gs.objective)).clamp(0.0, 1.0).toDouble(), const Color(0xFF1FA58A)),
              _goal('إبقاء الأجور تحت 85% من الإيرادات', (1 - (gs.ffpRatio - 0.6).clamp(0.0, 0.4) / 0.4).toDouble(), const Color(0xFF2F7BE6)),
              _goal('الحفاظ على ثقة الإدارة فوق 50%', (gs.confidence / 100).clamp(0.0, 1.0).toDouble(), const Color(0xFFF5A524)),
            ]),
          ),
        if (gs.renewal != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGold)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                teamBadge(gs.user, size: 40),
                const SizedBox(width: 10),
                const Expanded(child: Text('عرض تجديد العقد', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: kGold))),
              ]),
              const SizedBox(height: 6),
              Text(gs.renewal!.reason, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.5)),
              const SizedBox(height: 8),
              _kv('مدة العقد الجديدة', '${gs.renewal!.years} ${gs.renewal!.years == 1 ? 'موسم' : 'مواسم'}'),
              _kv('هدف الإدارة', 'المركز ${gs.renewal!.objective} أو أفضل'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GradientButton(label: 'تجديد العقد', icon: Icons.check_rounded, onPressed: () {
                  gs.acceptRenewal();
                  setState(() {});
                })),
                const SizedBox(width: 8),
                Expanded(child: whiteBtn('رفض', () {
                  gs.rejectRenewal();
                  setState(() {});
                })),
              ]),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Text('عروض من أندية أخرى (${jobs.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 8),
        if (jobs.isEmpty)
          const Panel(child: EmptyState(icon: Icons.work_outline_rounded, title: 'لا عروض حالياً', subtitle: 'تصلك العروض من الأندية بحسب سمعتك ونتائجك وحاجتها لمدرب.'))
        else
          for (final o in jobs) _offer(o),
        if (gs.natOffers.isNotEmpty && gs.natJob == null) ...[
          const SizedBox(height: 16),
          Text('عروض المنتخبات (${gs.natOffers.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          for (final o in gs.natOffers) _natOffer(o),
        ],
        if (under && !gs.resigned) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), foregroundColor: const Color(0xFFE5533D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _resign,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('استقالة / فسخ العقد'),
          ),
        ],
      ]),
    );
  }
}
