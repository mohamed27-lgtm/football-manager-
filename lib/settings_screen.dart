import 'package:flutter/material.dart' hide Text;
import 'auth.dart';
import 'game_state.dart';
import 'i18n.dart';
import 'lang_sheet.dart';
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

  Widget _group(String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 14, bottom: 8, right: 4), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
        Container(
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Column(children: [
            for (var i = 0; i < rows.length; i++) ...[if (i > 0) const Divider(height: 1), rows[i]],
          ]),
        ),
      ]);

  Widget _tile(IconData icon, Color c, String label, {Widget? trailing, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: c, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
            if (trailing != null) trailing,
          ]),
        ),
      );

  Widget _val(String v) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(v, style: const TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_left_rounded, color: kMuted),
      ]);

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.i;
    const blue = Color(0xFF2F7BE6), red = Color(0xFFE5533D), teal = Color(0xFF1FA58A), amber = Color(0xFFF5A524), purple = Color(0xFF6A6FC4);
    return Scaffold(
      appBar: AppBar(title: Text(tr('الإعدادات'))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  await gs.save();
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                  onRestart();
                },
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 3))]),
                  child: Text(tr('خروج'), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: GradientButton(
                label: tr('حفظ اللعبة'),
                icon: Icons.check_rounded,
                onPressed: () async {
                  await gs.save();
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('تم الحفظ ✅'))));
                },
              ),
            ),
          ]),
        ),
      ),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => FutureBuilder<Account?>(
          future: AuthService.current(),
          builder: (context, snap) => ListView(padding: const EdgeInsets.fromLTRB(14, 0, 14, 20), children: [
            _group(tr('عام'), [
              _tile(Icons.language_rounded, blue, tr('اللغة'),
                  trailing: _val(const {'ar': 'العربية', 'en': 'English', 'fr': 'Français', 'es': 'Español'}[s.lang] ?? ''), onTap: () => showLanguageSheet(context)),
              _tile(Icons.notifications_none_rounded, red, tr('الإشعارات'), trailing: Switch(value: s.notifs, onChanged: (v) => s.set(notifs: v))),
              _tile(Icons.calendar_month_rounded, teal, tr('الإشعار بالمباريات'), trailing: Switch(value: s.matchNotifs, onChanged: (v) => s.set(matchNotifs: v))),
            ]),
            _group(tr('اللعب'), [
              _tile(Icons.bolt_rounded, amber, tr('سرعة المحاكاة'),
                  trailing: _val('x${s.speed}'), onTap: () => s.set(speed: s.speed == 1 ? 2 : (s.speed == 2 ? 4 : 1))),
              _tile(Icons.flag_rounded, teal, tr('لافتة الهدف على الملعب'), trailing: Switch(value: s.goalFlash, onChanged: (v) => s.set(goalFlash: v))),
              _tile(Icons.vibration_rounded, purple, tr('الاهتزاز عند الأهداف'), trailing: Switch(value: s.haptics, onChanged: (v) => s.set(haptics: v))),
              _tile(Icons.text_fields_rounded, blue, tr('حجم الخط'),
                  trailing: _val('${(s.textScale * 100).round()}%'), onTap: () => s.set(textScale: s.textScale >= 1.3 ? 0.85 : (s.textScale + 0.15).clamp(0.85, 1.3))),
            ]),
            _group(tr('المظهر والصوت'), [
              _tile(Icons.dark_mode_rounded, const Color(0xFF8A94A6), tr('الوضع الداكن'),
                  trailing: Switch(value: s.themeMode == 'dark', onChanged: (v) => s.set(themeMode: v ? 'dark' : 'light'))),
              _tile(Icons.volume_up_rounded, teal, tr('أصوات المباراة'), trailing: Switch(value: s.sounds, onChanged: (v) => s.set(sounds: v))),
            ]),
            _group(tr('الحساب'), [
              _tile(Icons.person_outline_rounded, blue, snap.data?.name ?? '', trailing: Text(snap.data?.email ?? '', style: const TextStyle(color: kMuted, fontSize: 12))),
              _tile(Icons.logout_rounded, red, tr('تسجيل الخروج'),
                  onTap: () => _confirm(context, tr('تسجيل الخروج'), tr('ستُحفظ مسيرتك ثم تعود لشاشة الدخول.'), () async {
                        await gs.save();
                        if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                        onLogout();
                      })),
            ]),
            _group(tr('البيانات'), [
              _tile(Icons.restore_rounded, amber, tr('استعادة النسخة الاحتياطية'),
                  onTap: () => _confirm(context, tr('استعادة النسخة الاحتياطية'), tr('ستُستبدل مسيرتك الحالية بآخر نسخة احتياطية تلقائية (أقدم بقليل). تُحفظ هذه النسخة كل بضع جولات.'), () async {
                        final ok = await GameState.restoreBackup();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(ok ? 'تمت الاستعادة — اختر «متابعة المسيرة»' : 'لا توجد نسخة احتياطية بعد'))));
                        if (ok) {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                          onRestart();
                        }
                      })),
              _tile(Icons.delete_outline_rounded, red, tr('حذف المسيرة الحالية'),
                  onTap: () => _confirm(context, tr('حذف المسيرة'), tr('سيُحذف حفظ هذه المسيرة نهائياً ولا يمكن التراجع.'), () async {
                        await GameState.clearSave();
                        if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                        onRestart();
                      })),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                '${tr('مدرب كرة القدم')}\n${tr('أسماء الرعاة المعروضة في اللعبة لأغراض المحاكاة فقط ولا تمثّل أي ارتباط تجاري فعلي.')}',
                style: const TextStyle(color: kMuted, fontSize: 12, height: 1.6),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
