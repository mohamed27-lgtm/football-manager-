import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_football.dart';
import 'bundled.dart';
import 'league_store.dart';
import 'models.dart';

/// فهرس صور اللاعبين من الحزم المنزّلة: يربط صورة اللاعب بمعرّفه، أو بلقبه وأول حرف من اسمه وعمره
/// (أسماء Transfermarkt الكاملة مثل «Anthony Gordon» تطابق أسماء الـ API المختصرة «A. Gordon»)
class PhotoIndex {
  static final version = ValueNotifier<int>(0);
  static final Map<int, String> _byId = {};
  static final Map<String, List<(int, String)>> _byKey = {};
  static final Map<String, String> _logos = {};

  static String? logoOf(String club) => _logos[club.toLowerCase().trim()];

  static String _norm(String s) {
    const from = 'àáâãäåāçćčďèéêëēěìíîïíłñńňòóôõöøőŕřśšşťùúûüůűýÿźžż';
    const to = 'aaaaaaacccdeeeeeeiiiiilnnnooooooorrsssstuuuuuuyyzzz';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString().replaceAll(RegExp(r'[^a-z ]'), ' ').trim();
  }

  static String? _key(String name) {
    final parts = _norm(name).split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    if (parts.length < 2) return '${parts.first}|'; // اسم مفرد مثل Gavi
    return '${parts.last}|${parts.first[0]}';
  }

  static Future<void> build() async {
    try {
      final byId = <int, String>{};
      final byKey = <String, List<(int, String)>>{};
      final logos = <String, String>{};
      for (final l in await Bundled.list()) {
        final d = await LeagueStore.load(l.id, l.season);
        if (d == null) continue;
        for (final ApiTeam t in d.teams) {
          final lg = t.logo;
          if (lg != null && lg.isNotEmpty && !lg.startsWith('http') && File(lg).existsSync()) logos[t.name.toLowerCase().trim()] = lg;
          for (final p in t.players) {
            final ph = p.photo;
            if (ph == null || ph.isEmpty || ph.startsWith('http') || !File(ph).existsSync()) continue;
            final k = _key(p.name);
            if (k != null && p.age != null) byKey.putIfAbsent(k, () => []).add((p.age!, ph));
          }
        }
      }
      _byId
        ..clear()
        ..addAll(byId);
      _byKey
        ..clear()
        ..addAll(byKey);
      _logos
        ..clear()
        ..addAll(logos);
      version.value++;
    } catch (_) {}
  }

  /// مسار صورة محلية للاعب بلا صورة، أو null
  static String? lookup(Player p) {
    if (_byKey.isEmpty) return null;
    final k = _key(p.name);
    if (k == null) return null;
    final l = _byKey[k];
    if (l == null) return null;
    final age = p.age0 ?? p.age;
    // معرّف اللاعب في اللعبة عدّاد داخلي لا علاقة له بمعرّف الـ API، فلا يُستخدم للمطابقة.
    // نقبل فقط تطابقاً غير ملتبس: نفس اللقب والحرف الأول وفارق عمر ≤ 1 وصورة واحدة مرشّحة.
    final ok = {for (final e in l) if ((e.$1 - age).abs() <= 1) e.$2};
    return ok.length == 1 ? ok.first : null;
  }
}
