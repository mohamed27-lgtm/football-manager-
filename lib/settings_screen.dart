import 'package:flutter/material.dart' hide Text;
import 'auth.dart';
import 'game_state.dart';
import 'i18n.dart';
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('إلغاء'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('تأكيد'))),
        ],
      ),
    );
    if (ok == true) await action();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.i;
    return Scaffold(
      appBar: AppBar(title: Text('⚙️ ${tr('الإعدادات')}'), backgroundColor: kBg),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: s,
          builder: (context, _) => FutureBuilder<Account?>(
            future: AuthService.current(),
            builder: (context, snap) => ListView(padding: const EdgeInsets.all(14), children: [
              sectionTitle(tr('الحساب')),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(snap.data?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(snap.data?.email ?? '', style: const TextStyle(color: kMuted)),
                  Text(tr(AuthService.remote ? 'حساب سحابي' : 'حساب محلي على هذا الجهاز'), style: const TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _confirm(context, tr('تسجيل الخروج'), tr('ستُحفظ مسيرتك ثم تعود لشاشة الدخول.'), () async {
                      await gs.save();
                      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                      onLogout();
                    }),
                    icon: const Icon(Icons.logout),
                    label: Text(tr('تسجيل الخروج')),
                  ),
                ]),
              ),
              sectionTitle(tr('المباراة')),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('سرعة المباراة الافتراضية')),
                  const SizedBox(height: 6),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 1, label: Text(tr('عادية'))),
                      ButtonSegment(value: 2, label: Text(tr('سريعة'))),
                      ButtonSegment(value: 4, label: Text(tr('أسرع'))),
                    ],
                    selected: {s.speed},
                    onSelectionChanged: (v) => s.set(speed: v.first),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('لافتة الهدف على الملعب')),
                    value: s.goalFlash,
                    onChanged: (v) => s.set(goalFlash: v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('الاهتزاز عند الأهداف')),
                    value: s.haptics,
                    onChanged: (v) => s.set(haptics: v),
                  ),
                ]),
              ),
              sectionTitle(tr('المظهر')),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'dark', icon: const Icon(Icons.dark_mode_outlined, size: 18), label: Text(tr('داكن'))),
                      ButtonSegment(value: 'light', icon: const Icon(Icons.light_mode_outlined, size: 18), label: Text(tr('فاتح'))),
                      ButtonSegment(value: 'system', icon: const Icon(Icons.brightness_auto_outlined, size: 18), label: Text(tr('تلقائي'))),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => s.set(themeMode: v.first),
                  ),
                  const SizedBox(height: 14),
                  Text(tr('اللغة')),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final e in const {'ar': 'العربية', 'en': 'English', 'fr': 'Français', 'es': 'Español'}.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: s.lang == e.key,
                        onSelected: (_) => s.set(lang: e.key),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Text(tr('الترجمة الحالية تشمل الإعدادات والتنقل الرئيسي؛ بقية الشاشات تُترجم تدريجياً.'), style: const TextStyle(color: kMuted, fontSize: 11, height: 1.5)),
                ]),
              ),
              sectionTitle(tr('العرض')),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${tr('حجم الخط')} (${(s.textScale * 100).round()}%)'),
                  Slider(
                    value: s.textScale,
                    min: 0.85,
                    max: 1.3,
                    divisions: 9,
                    onChanged: (v) => s.set(textScale: v),
                  ),
                ]),
              ),
              sectionTitle(tr('اللعبة')),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('تُحفظ مسيرتك تلقائياً بعد كل مباراة وصفقة.'), style: TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await gs.save();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('تم الحفظ ✅'))));
                          }
                        },
                        child: Text(tr('حفظ الآن')),
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
                        child: Text(tr('حفظ وخروج للقائمة')),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _confirm(context, tr('استعادة النسخة الاحتياطية'), tr('ستُستبدل مسيرتك الحالية بآخر نسخة احتياطية تلقائية (أقدم بقليل). تُحفظ هذه النسخة كل بضع جولات.'), () async {
                      final ok = await GameState.restoreBackup();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(ok ? 'تمت الاستعادة — اختر «متابعة المسيرة»' : 'لا توجد نسخة احتياطية بعد'))));
                      if (ok) {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        onRestart();
                      }
                    }),
                    child: Text(tr('استعادة النسخة الاحتياطية')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF8A65)),
                    onPressed: () => _confirm(context, tr('حذف المسيرة'), tr('سيُحذف حفظ هذه المسيرة نهائياً ولا يمكن التراجع.'), () async {
                      await GameState.clearSave();
                      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                      onRestart();
                    }),
                    child: Text(tr('حذف المسيرة الحالية')),
                  ),
                ]),
              ),
              sectionTitle(tr('حول')),
              Panel(
                child: Text(
                  '${tr('مدرب كرة القدم')}\n${tr('أسماء الرعاة المعروضة في اللعبة لأغراض المحاكاة فقط ولا تمثّل أي ارتباط تجاري فعلي.')}',
                  style: const TextStyle(color: kMuted, fontSize: 12, height: 1.6),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
