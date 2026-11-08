import 'package:flutter/material.dart';
import 'game_state.dart';
import 'widgets.dart';

void _snack(BuildContext c, String? err, String ok) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err ?? ok)));

class StaffScreen extends StatelessWidget {
  final GameState gs;
  const StaffScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧑‍🏫 الطاقم الفني'), backgroundColor: kBg),
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
                      child: FilledButton.tonal(
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
      appBar: AppBar(title: const Text('📣 الإعلام والجماهير'), backgroundColor: kBg),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final done = gs.pressWeek == gs.week;
            final f = gs.fans;
            final label = f >= 80 ? 'عشق جماهيري' : f >= 60 ? 'شعبية كبيرة' : f >= 40 ? 'شعبية متوسطة' : 'جماهير فاترة';
            return ListView(padding: const EdgeInsets.all(14), children: [
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
      appBar: AppBar(title: const Text('📜 تاريخ النادي'), backgroundColor: kBg),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
            sectionTitle('الألقاب (${gs.honours.length})'),
            Panel(
              child: gs.honours.isEmpty
                  ? const Text('لا ألقاب بعد — الطريق طويل!', style: TextStyle(color: kMuted))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      for (final h in gs.honours) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(h)),
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
            sectionTitle('المواسم'),
            if (gs.history.isEmpty)
              const Panel(child: Text('يُسجَّل كل موسم بعد انتهائه.', style: TextStyle(color: kMuted))),
            for (final h in gs.history.reversed)
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الموسم ${h['s']} — المركز ${h['pos']} (${h['pts']} نقطة)', style: const TextStyle(fontWeight: FontWeight.w800)),
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
