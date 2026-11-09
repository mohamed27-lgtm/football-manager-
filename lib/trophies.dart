import 'package:flutter/material.dart' hide Text;
import 'widgets.dart';

/// صور الكؤوس (assets/trophies) حسب اسم البطولة وبلد دوري المستخدم
const _countries = <String, (String?, String?, String?)>{
  'الإنجليز': ('premier_league', 'fa_cup', 'community_shield'),
  'الإسبان': ('laliga', 'copa_del_rey', 'supercopa_de_espana'),
  'الإيطال': ('serie_a', 'coppa_italia', 'supercoppa_italiana'),
  'الألمان': ('bundesliga', 'dfb_pokal', 'dfl_supercup'),
  'الفرنس': ('ligue_1', 'coupe_de_france', 'trophee_des_champions'),
  'السعود': ('saudi_pro_league', 'kings_cup', 'saudi_super_cup'),
  'المغرب': ('botola_pro', 'moroccan_cup', null),
  'المصر': ('premier_league_egyption', 'egypt_cup', 'super_cup_egyption'),
  'البرتغال': ('liga_portugal', 'taca_de_portugal', 'supertaca_candido_de_oliveira'),
  'الهولند': ('eredivisie', 'knvb_cup', 'johan_cruyff_shield'),
  'الترك': ('super_lig', 'turkish_cup', 'turkish_super_cup'),
  'البلجيك': ('pro_league', 'belgian_cup', 'belgian_super_cup'),
  'الأوكران': ('ukrainian_premier_league', 'ukrainian_cup', 'ukrainian_super_cup'),
  'الروس': ('russian_premier_league', 'russian_cup', null),
  'النمساو': ('austrian_bundesliga', 'austrian_cup', null),
  'النرويج': ('eliteserien', 'norwegian_cup', null),
  'الإمارات': ('uae_pro_league', 'uae_presidents_cup', 'uae_super_cup'),
  'الياباني': ('j1_league', 'emperors_cup', null),
  'البرازيل': ('serie_a_brazil', 'copa_do_brasil', null),
};

const _euro = <String, String>{
  'دوري أبطال أوروبا': 'uefa_champions_league',
  'الدوري الأوروبي': 'uefa_europa_league',
  'دوري المؤتمر الأوروبي': 'uefa_conference_league',
};

/// اسم ملف الكأس: [comp] اسم البطولة، [leagueName] دوري المستخدم الحالي، [isLeague] كأس الدوري نفسه
String trophyKey(String comp, String leagueName, {bool isLeague = false}) {
  final e = _euro[comp];
  if (e != null) return e;
  (String?, String?, String?)? c;
  for (final k in _countries.entries) {
    if (leagueName.contains(k.key)) {
      c = k.value;
      break;
    }
  }
  if (c == null) return 'default_trophy';
  if (isLeague) {
    final top = !leagueName.contains('الدرجة') && !leagueName.contains('تشامبيونشيب');
    return (top ? c.$1 : null) ?? 'default_trophy';
  }
  if (comp == 'كأس السوبر') return c.$3 ?? 'default_trophy';
  return c.$2 ?? 'default_trophy';
}

Widget trophyImage(String key, {double size = 44}) => Unfilter(
      child: Image.asset('assets/trophies/$key.png', width: size, height: size, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.emoji_events_rounded, size: size * 0.8, color: const Color(0xFFE6B422))),
    );

/// يحلّل سطر لقب مثل "🏆 دوري أبطال أوروبا — الموسم 3" → (اسم البطولة، الموسم)
(String, int)? parseHonour(String h) {
  final m = RegExp(r'^🏆 (.+?) — الموسم (\d+)$').firstMatch(h);
  if (m == null) return null;
  return (m.group(1)!, int.parse(m.group(2)!));
}
