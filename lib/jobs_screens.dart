import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'match_pages.dart' show whiteBtn;
import 'widgets.dart';

/// عقدي: ثقة الإدارة وسمعة المدرب، عروض الأندية الأخرى، والاستقالة
class JobsScreen extends StatefulWidget {
  final GameState gs;
  const JobsScreen({super.key, required this.gs});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  GameState get gs => widget.gs;

  Widget _kv(String k, String v, {Color? c}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(color: kMuted, fontSize: 13.5))),
          Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: c)),
        ]),
      );

  String _divName(int d) => d <= 1 ? 'الدرجة الأولى' : d == 2 ? 'الدرجة الثانية' : 'الدرجة $d';

  Future<void> _resign() async {
    final ok = await confirmDialog(context,
        title: 'الاستقالة من المنصب',
        body: 'ستترك تدريب ${gs.user.name} فوراً وتنخفض سمعتك كمدرب إن كان عقدك سارياً. ستصلك بعدها عروض من أندية أخرى في الدوري.',
        confirm: 'استقالة',
        danger: true);
    if (ok != true) return;
    gs.resign();
    if (mounted) setState(() {});
  }

  Future<void> _accept(JobOffer o) async {
    final later = gs.seasonOver && !gs.fired;
    final under = !gs.fired && gs.contractLeft > 1 && !later;
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

  Widget _offer(JobOffer o) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kPrimary.withOpacity(0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(o.club, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 4),
          Text(o.reason, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 8),
          _kv('الدوري', _divName(o.div)),
          _kv('مدة العقد', '${o.years} مواسم'),
          _kv('هدف الإدارة', 'المركز ${o.objective} أو أفضل'),
          _kv('ميزانية النادي', gs.money1(o.budget)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: GradientButton(label: 'قبول العرض', icon: Icons.check_rounded, onPressed: () => _accept(o))),
            const SizedBox(width: 8),
            Expanded(child: whiteBtn('رفض', () {
              gs.rejectJob(o);
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
      appBar: AppBar(title: const Text('عقدي والعروض')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Column(children: [
            _kv('النادي الحالي', gs.fired ? (gs.resigned ? 'مستقيل' : 'مُقال') : gs.user.name),
            _kv('سمعتك كمدرب', '${gs.mgrTier} (${gs.mgrRep.round()})'),
            if (under) _kv('ثقة الإدارة', '${gs.confidence.round()}%', c: gs.confidence >= 50 ? const Color(0xFF1FA58A) : const Color(0xFFE5533D)),
            if (under) _kv('المواسم المتبقية في العقد', '${gs.contractLeft}'),
            if (gs.pendingJob != null) _kv('وجهتك القادمة', gs.pendingJob!, c: kPrimary),
          ]),
        ),
        const SizedBox(height: 16),
        Text('عروض التدريب (${jobs.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 8),
        if (jobs.isEmpty)
          const Panel(child: EmptyState(icon: Icons.work_outline_rounded, title: 'لا عروض حالياً', subtitle: 'تصلك العروض من الأندية بحسب سمعتك ونتائجك وحاجتها لمدرب.'))
        else
          for (final o in jobs) _offer(o),
        if (under) ...[
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
