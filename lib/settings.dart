import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Brightness;
import 'package:shared_preferences/shared_preferences.dart';

/// إعدادات التطبيق (تُحفظ على الجهاز)
class AppSettings extends ChangeNotifier {
  static final AppSettings i = AppSettings._();
  AppSettings._();

  int speed = 1; // سرعة المباراة الافتراضية 1/2/4
  double textScale = 1.0;
  bool haptics = true;
  bool goalFlash = true;
  bool pitchAnim = true;
  bool notifs = true, matchNotifs = true, sounds = true; // تفضيلات محفوظة (الإشعارات والأصوات تُفعَّل لاحقاً)
  String themeMode = 'light'; // dark | light | system
  String lang = 'ar'; // ar | en | fr | es
  bool lightFor(Brightness b) => themeMode == 'light' || (themeMode == 'system' && b == Brightness.light);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      speed = p.getInt('s_speed') ?? 1;
      textScale = p.getDouble('s_text') ?? 1.0;
      haptics = p.getBool('s_haptics') ?? true;
      goalFlash = p.getBool('s_flash') ?? true;
      pitchAnim = p.getBool('s_pitch') ?? true;
      themeMode = p.getString('s_theme') ?? 'light';
      notifs = p.getBool('s_notifs') ?? true;
      matchNotifs = p.getBool('s_mnotifs') ?? true;
      sounds = p.getBool('s_sounds') ?? true;
      lang = p.getString('s_lang') ?? 'ar';
    } catch (_) {}
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('s_speed', speed);
      await p.setDouble('s_text', textScale);
      await p.setBool('s_haptics', haptics);
      await p.setBool('s_flash', goalFlash);
      await p.setBool('s_pitch', pitchAnim);
      await p.setString('s_theme', themeMode);
      await p.setString('s_lang', lang);
      await p.setBool('s_notifs', notifs);
      await p.setBool('s_mnotifs', matchNotifs);
      await p.setBool('s_sounds', sounds);
    } catch (_) {}
  }

  void set({int? speed, double? textScale, bool? haptics, bool? goalFlash, bool? pitchAnim, String? themeMode, String? lang, bool? notifs, bool? matchNotifs, bool? sounds}) {
    this.notifs = notifs ?? this.notifs;
    this.matchNotifs = matchNotifs ?? this.matchNotifs;
    this.sounds = sounds ?? this.sounds;
    this.speed = speed ?? this.speed;
    this.textScale = textScale ?? this.textScale;
    this.haptics = haptics ?? this.haptics;
    this.goalFlash = goalFlash ?? this.goalFlash;
    this.pitchAnim = pitchAnim ?? this.pitchAnim;
    this.themeMode = themeMode ?? this.themeMode;
    this.lang = lang ?? this.lang;
    _save();
  }
}
