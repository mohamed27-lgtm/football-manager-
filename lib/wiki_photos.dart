import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'photo_index.dart';

/// صور لاعبين حرة من ويكيميديا كومنز (عبر ويكيداتا): حزمة واحدة اختيارية تُنزَّل على الجهاز.
/// الصورة تخص اللاعب عبر معرّف Transfermarkt (Player.tm)، ولكل صورة مصوّر وترخيص يُعرضان في بطاقته.
class WikiPhotos {
  static const url = 'https://github.com/mohamed27-lgtm/football-manager-/releases/download/data-latest/photos_wikidata.zip';

  static String? _dir;
  static final Set<int> _have = {};
  static Map<int, String> _credits = {};

  static int get count => _have.length;

  static Future<String> _root() async {
    final d = await getApplicationDocumentsDirectory();
    return '${d.path}/wd_photos';
  }

  /// يقرأ ما نُزّل سابقاً (يُستدعى عند فتح التطبيق وبعد التنزيل/الحذف)
  static Future<void> load() async {
    try {
      final root = await _root();
      final have = <int>{};
      final dir = Directory('$root/p');
      if (await dir.exists()) {
        await for (final f in dir.list()) {
          final n = f.path.split(Platform.pathSeparator).last;
          if (n.endsWith('.jpg')) {
            final id = int.tryParse(n.substring(0, n.length - 4));
            if (id != null) have.add(id);
          }
        }
      }
      var credits = <int, String>{};
      final cf = File('$root/credits.json');
      if (await cf.exists()) {
        final j = jsonDecode(await cf.readAsString()) as Map<String, dynamic>;
        credits = {
          for (final e in j.entries)
            if (int.tryParse(e.key) != null) int.parse(e.key): e.value as String
        };
      }
      _dir = root;
      _have
        ..clear()
        ..addAll(have);
      _credits = credits;
      PhotoIndex.version.value++;
    } catch (_) {}
  }

  /// مسار صورة اللاعب المحلية أو null
  static String? pathFor(Player p) {
    final t = p.tm;
    if (t == null || _dir == null || !_have.contains(t)) return null;
    return '$_dir/p/$t.jpg';
  }

  /// نص الاعتماد (المصوّر — الترخيص) المطلوب قانونياً
  static String? credit(Player p) {
    final t = p.tm;
    if (t == null || !_have.contains(t)) return null;
    return _credits[t];
  }

  static Future<void> download(void Function(double) onProgress) async {
    final root = await _root();
    final tmp = File('$root.zip.part');
    final client = http.Client();
    try {
      await Directory(root).parent.create(recursive: true);
      final resp = await client.send(http.Request('GET', Uri.parse(url))).timeout(const Duration(seconds: 40));
      if (resp.statusCode != 200) throw Exception('http ${resp.statusCode}');
      final total = resp.contentLength ?? 0;
      var got = 0;
      final sink = tmp.openWrite();
      await for (final c in resp.stream) {
        sink.add(c);
        got += c.length;
        if (total > 0) onProgress((got / total * 0.85).clamp(0.0, 0.85).toDouble());
      }
      await sink.close();
      final dir = Directory(root);
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
      await extractFileToDisk(tmp.path, root);
      onProgress(1);
    } finally {
      client.close();
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
    }
    await load();
  }

  static Future<void> remove() async {
    try {
      final dir = Directory(await _root());
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
    await load();
  }
}
