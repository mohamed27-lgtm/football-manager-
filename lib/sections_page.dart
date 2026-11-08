import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'i18n.dart';
import 'lang_sheet.dart';
import 'profile_screen.dart';
import 'settings.dart';
import 'widgets.dart';

/// قسم «الأقسام»: الإعدادات العامة خارج المباراة
class SectionsPage extends StatelessWidget {
  final String name, email;
  final List<SaveMeta> saves;
  final VoidCallback onLogout;
  const SectionsPage({super.key, required this.name, required this.email, required this.saves, required this.onLogout});

  static const _langNames = {'ar': 'العربية', 'en': 'English', 'fr': 'Français', 'es': 'Español'};

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.i;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final dark = !s.lightFor(MediaQuery.platformBrightnessOf(context));
        return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
          const Text('الإعدادات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          _title('العرض'),
          _group([
            _row(Icons.dark_mode_outlined, 'الوضع الليلي', trailing: Switch(value: dark, onChanged: (v) => s.set(themeMode: v ? 'dark' : 'light'))),
            _row(Icons.language, 'اللغة', value: _langNames[s.lang], onTap: () => showLanguageSheet(context)),
          ]),
          _title('المباراة'),
          _group([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [_ic(Icons.speed), const SizedBox(width: 12), const Text('سرعة المباراة الافتراضية')]),
                const SizedBox(height: 10),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 1, label: Text('عادية')),
                    ButtonSegment(value: 2, label: Text('سريعة')),
                    ButtonSegment(value: 4, label: Text('أسرع')),
                  ],
                  selected: {s.speed},
                  onSelectionChanged: (v) => s.set(speed: v.first),
                ),
              ]),
            ),
            _row(Icons.flag_outlined, 'لافتة الهدف على الملعب', trailing: Switch(value: s.goalFlash, onChanged: (v) => s.set(goalFlash: v))),
            _row(Icons.vibration, 'الاهتزاز عند الأهداف', trailing: Switch(value: s.haptics, onChanged: (v) => s.set(haptics: v))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [_ic(Icons.text_fields), const SizedBox(width: 12), Text('${tr('حجم الخط')} (${(s.textScale * 100).round()}%)')]),
                Slider(value: s.textScale, min: 0.85, max: 1.3, divisions: 9, onChanged: (v) => s.set(textScale: v)),
              ]),
            ),
          ]),
          _title('الحساب'),
          _group([
            _row(Icons.person_outline, 'الملف الشخصي', chevron: true, onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(name: name, email: email, saves: saves)));
            }),
            _row(Icons.share_outlined, 'مشاركة اللعبة', chevron: true, onTap: () async {
              await Clipboard.setData(const ClipboardData(text: 'https://github.com/mohamed27-lgtm/football-manager-/releases/latest'));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ رابط اللعبة')));
            }),
            _row(Icons.logout, 'تسجيل الخروج', danger: true, onTap: onLogout),
          ]),
          const SizedBox(height: 16),
          Text('${tr('مدرب كرة القدم')}\n${tr('أسماء الرعاة المعروضة في اللعبة لأغراض المحاكاة فقط ولا تمثّل أي ارتباط تجاري فعلي.')}',
              style: const TextStyle(color: kMuted, fontSize: 11.5, height: 1.6)),
        ]);
      },
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t, style: const TextStyle(color: kMuted, fontSize: 13)),
      );

  Widget _group(List<Widget> children) => Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1, indent: 14, endIndent: 14),
          ],
        ]),
      );

  Widget _ic(IconData i, {bool danger = false}) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: danger ? const Color(0x33FF5252) : kCard2, shape: BoxShape.circle),
        child: Icon(i, size: 20, color: danger ? const Color(0xFFFF8A80) : null),
      );

  Widget _row(IconData i, String title, {Widget? trailing, String? value, bool chevron = false, bool danger = false, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            _ic(i, danger: danger),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: danger ? const Color(0xFFFF8A80) : null))),
            if (value != null) Text(value, style: const TextStyle(color: kMuted, fontSize: 13)),
            if (trailing != null) trailing,
            if (chevron || value != null) const Icon(Icons.chevron_left, color: kMuted),
          ]),
        ),
      );
}
