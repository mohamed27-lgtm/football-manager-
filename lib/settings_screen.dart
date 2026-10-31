import 'package:flutter/material.dart';
import 'auth.dart';
import 'game_state.dart';
import 'settings.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  final GameState gs;
  final VoidCallback onRestart;
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.gs, required this.onRestart, required this.onLogout});

  Future<void> _confirm(BuildContext context, String title, String body, Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (ok == true) await action();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.i;
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ الإعدادات'), backgroundColor: kBg),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: s,
          builder: (context, _) => FutureBuilder<Account?>(
            future: AuthService.current(),
            builder: (context, snap) => ListView(padding: const EdgeInsets.all(14), children: [
              sectionTitle('الحساب'),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(snap.data?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(snap.data?.email ?? '', style: const TextStyle(color: kMuted)),
                  Text(AuthService.remote ? 'حساب سحابي' : 'حساب محلي على هذا الجهاز', style: const TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _confirm(context, 'تسجيل الخروج', 'ستُحفظ مسيرتك ثم تعود لشاشة الدخول.', () async {
                      await gs.save();
                      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                      onLogout();
                    }),
                    icon: const Icon(Icons.logout),
                    label: const Text('تسجيل الخروج'),
                  ),
                ]),
              ),
              sectionTitle('المباراة'),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('سرعة المباراة الافتراضية'),
                  const SizedBox(height: 6),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 1, label: Text('عادية')),
                      ButtonSegment(value: 2, label: Text('سريعة')),
                      ButtonSegment(value: 4, label: Text('أسرع')),
                    ],
                    selected: {s.speed},
                    onSelectionChanged: (v) => s.set(speed: v.first),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('لافتة الهدف على الملعب'),
                    value: s.goalFlash,
                    onChanged: (v) => s.set(goalFlash: v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الاهتزاز عند الأهداف'),
                    value: s.haptics,
                    onChanged: (v) => s.set(haptics: v),
                  ),
                ]),
              ),
              sectionTitle('العرض'),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('حجم الخط (${(s.textScale * 100).round()}%)'),
                  Slider(
                    value: s.textScale,
                    min: 0.85,
                    max: 1.3,
                    divisions: 9,
                    onChanged: (v) => s.set(textScale: v),
                  ),
                ]),
              ),
              sectionTitle('اللعبة'),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('تُحفظ مسيرتك تلقائياً بعد كل مباراة وصفقة.', style: TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await gs.save();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ ✅')));
                          }
                        },
                        child: const Text('حفظ الآن'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await gs.save();
                          if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                          onRestart();
                        },
                        child: const Text('حفظ وخروج للقائمة'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF8A65)),
                    onPressed: () => _confirm(context, 'حذف المسيرة', 'سيُحذف حفظ هذه المسيرة نهائياً ولا يمكن التراجع.', () async {
                      await GameState.clearSave();
                      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                      onRestart();
                    }),
                    child: const Text('حذف المسيرة الحالية'),
                  ),
                ]),
              ),
              sectionTitle('حول'),
              const Panel(
                child: Text(
                  'مدرب كرة القدم\nأسماء الرعاة المعروضة في اللعبة لأغراض المحاكاة فقط ولا تمثّل أي ارتباط تجاري فعلي.',
                  style: TextStyle(color: kMuted, fontSize: 12, height: 1.6),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
