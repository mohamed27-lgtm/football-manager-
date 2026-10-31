import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_football.dart';

/// تخزين بيانات الدوريات محلياً (ملف JSON لكل دوري/موسم) ليعمل التطبيق دون إنترنت بعد التنزيل
class LeagueStore {
  static Future<Directory> _dir() async {
    final d = await getApplicationDocumentsDirectory();
    final dir = Directory('${d.path}/leagues');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _file(int id, int season) async =>
      File('${(await _dir()).path}/league_${id}_$season.json');

  static Future<void> save(LeagueData d) async {
    final f = await _file(d.id, d.season);
    await f.writeAsString(jsonEncode(d.toJson()));
  }

  static Future<LeagueData?> load(int id, int season) async {
    try {
      final f = await _file(id, season);
      if (!await f.exists()) return null;
      return LeagueData.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> delete(int id, int season) async {
    try {
      final f = await _file(id, season);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static Future<String> getKey() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('api_key') ?? '';
  }

  static Future<void> setKey(String k) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('api_key', k);
  }

  static Future<int> getSeason() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt('api_season') ?? 2023;
  }

  static Future<void> setSeason(int s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('api_season', s);
  }
}
