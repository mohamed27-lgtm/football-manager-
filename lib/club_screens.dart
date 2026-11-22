import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart' show Pos;
import 'widgets.dart';
import 'trophies.dart';

void _snack(BuildContext c, String? err, String ok) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err ?? ok)));

class StaffScreen extends StatelessWidget {
  final GameState gs;
  const StaffScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧑‍🏫 الطاقم الفني')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
            Panel(
              child: Row(children: [
                const Text('💰 الميزانية', style: TextStyle(color: kMuted)),
                const Spacer(),
                Text(money(gs.user.budget), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kAccent)),
              ]),
            ),
            for (final e in GameState.staffRoles.entries)
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(e.value.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('المستوى ${gs.staff[e.key]}/5', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  Text(e.value.$2, style: const TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: gs.staff[e.key]! / 5, minHeight: 8, color: kAccent, backgroundColor: kCard2),
                  ),
                  const SizedBox(height: 10),
                  if (gs.staff[e.key]! < 5)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _snack(context, gs.upgradeStaff(e.key), 'تم ✅'),
                        child: Text(gs.staff[e.key] == 0 ? 'تعيين مقابل ${money(gs.staffCost(e.key))}' : 'ترقية مقابل ${money(gs.staffCost(e.key))}'),
                      ),
                    )
                  else
                    const Text('أقصى مستوى ✅', style: TextStyle(color: kMuted)),
                ]),
              ),
            Text('رواتب الطاقم الأسبوعية: ${money(gs.staffWages)}', style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class MediaScreen extends StatelessWidget {
  final GameState gs;
  const MediaScreen({super.key, required this.gs});

  static const _opts = <(String, String)>[
    ('ثقة بالفريق', 'تفاؤل: ثقة الإدارة +1 ومعنويات +2'),
    ('انتقاد الحكام', 'جماهير +1.5 لكن مخاطرة بغضب الإدارة'),
    ('مدح اللاعبين', 'معنويات اللاعبين +4'),
    ('تواضع واحترام', 'ثقة الإدارة +2'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📣 الإعلام والجماهير')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final done = gs.pressWeek == gs.week;
            final f = gs.fans;
            final label = f >= 80 ? 'عشق جماهيري' : f >= 60 ? 'شعبية كبيرة' : f >= 40 ? 'شعبية متوسطة' : 'جماهير فاترة';
            Widget tile(String v, String l, Color c) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
                    child: Column(children: [
                      Text(v, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: c)),
                      Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ),
                );
            return ListView(padding: const EdgeInsets.all(14), children: [
              Row(children: [
                tile('${f.round()}%', 'الشعبية', kPrimary),
                tile('${gs.attendance}', 'الحضور المتوقع', const Color(0xFF1FA58A)),
                tile(f >= 60 ? 'ممتاز' : (f >= 40 ? 'جيد' : 'ضعيف'), 'رضا الجماهير', const Color(0xFFF5A524)),
              ]),
              const SizedBox(height: 12),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('شعبية النادي', style: TextStyle(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${f.round()}% • $label', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: f / 100, minHeight: 10, color: kAccent, backgroundColor: kCard2),
                  ),
                  const SizedBox(height: 8),
                  const Text('ترفع الشعبية دخل التذاكر والرعاة. تزيد بالفوز والألقاب وتنقص بالخسارة.',
                      style: TextStyle(color: kMuted, fontSize: 12, height: 1.4)),
                ]),
              ),
              sectionTitle('المؤتمر الصحفي'),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(done ? 'عقدت مؤتمرك لهذا الأسبوع.' : 'اختر رسالتك للصحافة (مرة كل أسبوع):',
                      style: const TextStyle(color: kMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _opts.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: done ? null : () => _snack(context, gs.pressConference(i), 'تم المؤتمر الصحفي 🎤'),
                          child: Column(children: [
                            Text(_opts[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(_opts[i].$2, style: const TextStyle(color: kMuted, fontSize: 11)),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
              sectionTitle('عناوين الصحف'),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final n in gs.news.where((n) => n.startsWith('📰') || n.startsWith('🎤')).take(8))
                    Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(n)),
                  if (!gs.news.any((n) => n.startsWith('📰'))) const Text('لا عناوين بعد', style: TextStyle(color: kMuted)),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final GameState gs;
  const HistoryScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📜 تاريخ النادي')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
            sectionTitle('الألقاب (${gs.honours.length})'),
            Panel(
              child: gs.honours.isEmpty
                  ? const Text('لا ألقاب بعد — الطريق طويل!', style: TextStyle(color: kMuted))
                  : Wrap(spacing: 14, runSpacing: 10, children: [
                      for (final h in gs.honours)
                        Builder(builder: (_) {
                          final ph = parseHonour(h);
                          if (ph == null) return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(h));
                          return Column(mainAxisSize: MainAxisSize.min, children: [
                            trophyImage(trophyKey(ph.$1 == 'الدوري' ? gs.leagueName : ph.$1, gs.leagueName, isLeague: ph.$1 == 'الدوري'), size: 46),
                            Text('م${ph.$2}', style: const TextStyle(color: kMuted, fontSize: 11)),
                          ]);
                        }),
                    ]),
            ),
            sectionTitle('أرقام قياسية'),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(gs.bigWin.isEmpty ? 'أكبر فوز: —' : 'أكبر فوز (+${gs.bigWinD}): ${gs.bigWin}'),
                const SizedBox(height: 6),
                Text(gs.bigLoss.isEmpty ? 'أكبر خسارة: —' : 'أكبر خسارة (-${gs.bigLossD}): ${gs.bigLoss}'),
              ]),
            ),
            sectionTitle('🏛️ قاعة الشهرة'),
            Builder(builder: (_) {
              final hf = gs.hallOfFame;
              if (hf.isEmpty) return const Panel(child: Text('يدخل القاعة من يلعب 40 مباراة مع ناديك أو يصنع تاريخاً بأهدافه وتمريراته.', style: TextStyle(color: kMuted)));
              final top = ([...gs.legends.values]..sort((a, b) => (b['g'] as int).compareTo(a['g'] as int))).first;
              final most = ([...gs.legends.values]..sort((a, b) => (b['a'] as int).compareTo(a['a'] as int))).first;
              return Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الهداف التاريخي: ${top['n']} (${top['g']} هدفاً)', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('الأكثر مشاركة: ${most['n']} (${most['a']} مباراة)', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const Divider(height: 18),
                  for (var i = 0; i < hf.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        SizedBox(width: 24, child: Text('${i + 1}', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w900))),
                        PosChip(Pos.values[(hf[i]['p'] as int).clamp(0, Pos.values.length - 1)]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${hf[i]['n']}${(hf[i]['sc'] as num) >= 250 ? '  ⭐ أسطورة' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text('${hf[i]['f']}–${hf[i]['l']} • ${hf[i]['a']} مباراة • ${hf[i]['g']} هدف • ${hf[i]['s']} تمريرة', style: const TextStyle(color: kMuted, fontSize: 11.5)),
                          ]),
                        ),
                      ]),
                    ),
                ]),
              );
            }),
            sectionTitle('المواسم'),
            if (gs.history.isEmpty)
              const Panel(child: Text('يُسجَّل كل موسم بعد انتهائه.', style: TextStyle(color: kMuted))),
            for (final h in gs.history.reversed)
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('الموسم ${h['s']} — المركز ${h['pos']} (${h['pts']} نقطة)', style: const TextStyle(fontWeight: FontWeight.w800))),
                    for (final x in gs.honours)
                      Builder(builder: (_) {
                        final ph = parseHonour(x);
                        if (ph == null || ph.$2 != h['s']) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(start: 6),
                          child: trophyImage(trophyKey(ph.$1 == 'الدوري' ? gs.leagueName : ph.$1, gs.leagueName, isLeague: ph.$1 == 'الدوري'), size: 34),
                        );
                      }),
                  ]),
                  const SizedBox(height: 4),
                  Text('فوز ${h['w']} • تعادل ${h['d']} • خسارة ${h['l']} • له ${h['gf']} / عليه ${h['ga']}',
                      style: const TextStyle(color: kMuted, fontSize: 12)),
                  Text('الكأس: ${h['cup']}', style: const TextStyle(fontSize: 13)),
                  Text('أبطال أوروبا: ${h['con']}', style: const TextStyle(fontSize: 13)),
                  if ((h['eur'] ?? '-') != '-' && h['eur'] != 'لم يتأهل') Text('الدوري الأوروبي: ${h['eur']}', style: const TextStyle(fontSize: 13)),
                  if ((h['uecl'] ?? '-') != '-' && h['uecl'] != 'لم يتأهل') Text('دوري المؤتمر: ${h['uecl']}', style: const TextStyle(fontSize: 13)),
                  Text('هداف الفريق: ${h['scorer']}', style: const TextStyle(fontSize: 13)),
                  if ((h['awards'] as List?)?.isNotEmpty ?? false) ...[
                    const Divider(),
                    const Text('جوائز الموسم', style: TextStyle(fontWeight: FontWeight.w700, color: kAccent)),
                    for (final a in (h['awards'] as List))
                      Padding(padding: const EdgeInsets.only(top: 3), child: Text('$a', style: const TextStyle(fontSize: 12.5, height: 1.4))),
                  ],
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
