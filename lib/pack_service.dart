import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_football.dart';
import 'league_store.dart';

/// غيّر هذا الرابط إلى مستودعك (أو عدّله من داخل اللعبة في شاشة الحزم)
const defaultPackBase =
    'https://github.com/mohamed27-lgtm/football-manager-/releases/download/data-latest';

class PackInfo {
  final int id, season, tier, teams, players, bytes;
  final String name, country, file;
  const PackInfo({
    required this.id,
    required this.season,
    required this.tier,
    required this.teams,
    required this.players,
    required this.bytes,
    required this.name,
    required this.country,
    required this.file,
  });

  factory PackInfo.fromJson(Map<String, dynamic> j) => PackInfo(
        id: j['id'] as int,
        season: j['season'] as int,
        tier: (j['tier'] as int?) ?? 3,
        teams: (j['teams'] as int?) ?? 0,
        players: (j['players'] as int?) ?? 0,
        bytes: (j['bytes'] as int?) ?? 0,
        name: j['name'] as String,
        country: (j['country'] as String?) ?? '',
        file: j['file'] as String,
      );

  String get sizeLabel => '${(bytes / 1e6).toStringAsFixed(1)} MB';
}

class PackService {
  static Future<String> getBase() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('pack_base') ?? defaultPackBase;
  }

  static Future<void> setBase(String s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('pack_base', s.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  static Future<List<PackInfo>> manifest(String base) async {
    final http.Response r;
    try {
      r = await http
          .get(Uri.parse('$base/manifest.json'))
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ApiException('تعذّر الاتصال بالإنترنت');
    }
    if (r.statusCode != 200) {
      throw ApiException(
          'تعذّر جلب قائمة الحزم (${r.statusCode}). تأكد من صحة الرابط ومن أن المستودع عام وأن الـ workflow أنهى أول استيراد.');
    }
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    return [
      for (final p in (j['packs'] as List? ?? []))
        PackInfo.fromJson(p as Map<String, dynamic>)
    ];
  }

  static String? _abs(String dir, String? s) {
    if (s == null || s.isEmpty) return null;
    if (s.startsWith('http')) return s;
    return '$dir/$s';
  }

  /// ينزّل الحزمة، يفك ضغطها في مجلد التطبيق، ويحفظ الدوري محلياً بمسارات صور محلية
  static Future<LeagueData> download(
      String base, PackInfo p, void Function(double) onProgress) async {
    final client = http.Client();
    try {
      final resp = await client
          .send(http.Request('GET', Uri.parse('$base/${p.file}')))
          .timeout(const Duration(seconds: 40));
      if (resp.statusCode != 200) {
        throw ApiException('فشل تنزيل الحزمة (${resp.statusCode})');
      }
      final total = (resp.contentLength ?? 0) > 0 ? resp.contentLength! : p.bytes;
      final buf = BytesBuilder(copy: false);
      var got = 0;
      await for (final chunk in resp.stream) {
        buf.add(chunk);
        got += chunk.length;
        if (total > 0) onProgress((got / total).clamp(0, 1).toDouble() * 0.8);
      }
      final bytes = buf.takeBytes();

      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/packs/${p.id}_${p.season}');
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);

      final arch = ZipDecoder().decodeBytes(bytes);
      Map<String, dynamic>? league;
      var i = 0;
      for (final f in arch) {
        i++;
        if (!f.isFile) continue;
        final name = f.name;
        if (name.contains('..') || name.startsWith('/')) continue;
        final content = f.content as List<int>;
        if (name == 'league.json') {
          league = jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
        } else {
          final out = File('${dir.path}/$name');
          await out.create(recursive: true);
          await out.writeAsBytes(content, flush: false);
        }
        if (i % 50 == 0) onProgress(0.8 + 0.2 * i / arch.length);
      }
      if (league == null) throw ApiException('الحزمة تالفة (league.json مفقود)');

      for (final t in league['teams'] as List) {
        t['logo'] = _abs(dir.path, t['logo'] as String?);
        for (final pl in t['players'] as List) {
          pl['ph'] = _abs(dir.path, pl['ph'] as String?);
        }
      }
      final data = LeagueData.fromJson(league);
      await LeagueStore.save(data);
      await LeagueStore.setSeason(p.season);
      onProgress(1);
      return data;
    } finally {
      client.close();
    }
  }
}
