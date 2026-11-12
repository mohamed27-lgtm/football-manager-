import 'dart:convert';
import 'package:flutter/services.dart';
import 'api_football.dart';

/// بيانات الدوريات المضمّنة داخل التطبيق (أسماء الأندية واللاعبين) بدون صور
class Bundled {
  static List<LeagueData>? _cache;
  static List<LeagueData>? get cached => _cache;

  static Map<String, dynamic> _stripImages(Map<String, dynamic> j) {
    j['logo'] = null;
    for (final t in j['teams'] as List) {
      t['logo'] = null;
      for (final p in t['players'] as List) {
        p['ph'] = null;
      }
    }
    return j;
  }

  /// فريق بالاسم الإنجليزي من الدوريات المضمّنة (يتطلب أن تكون القائمة محمّلة)
  static ApiTeam? teamByName(String name) {
    final c = _cache;
    if (c == null) return null;
    for (final l in c) {
      for (final t in l.teams) {
        if (t.name == name && t.players.isNotEmpty) return t;
      }
    }
    return null;
  }

  static Future<List<LeagueData>> list() async {
    if (_cache != null) return _cache!;
    final out = <LeagueData>[];
    try {
      final idx = jsonDecode(await rootBundle.loadString('assets/leagues/index.json')) as List;
      for (final e in idx) {
        try {
          final raw = jsonDecode(await rootBundle.loadString('assets/leagues/${e['file']}')) as Map<String, dynamic>;
          out.add(LeagueData.fromJson(_stripImages(raw)));
        } catch (_) {}
      }
    } catch (_) {}
    out.sort((a, b) => a.tier != b.tier ? a.tier.compareTo(b.tier) : a.name.compareTo(b.name));
    return _cache = out;
  }
}
