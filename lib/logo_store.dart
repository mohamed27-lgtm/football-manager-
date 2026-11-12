import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// شعارات الدوريات والبطولات المنزّلة من صفحة التنزيلات (تُحفظ في docs/logos)
class LogoStore {
  static const ids = <int>[1,103,106,113,114,119,120,128,129,135,136,137,140,141,143,144,145,147,15,169,179,180,186,197,2,200,201,202,203,204,206,207,208,218,219,233,235,253,255,262,263,292,3,301,305,307,308,333,345,39,4,40,41,45,5,526,528,529,531,547,556,61,62,66,71,72,78,79,80,81,848,88,89,9,90,94,95,96,960,98,1, 2, 3, 4, 5, 6, 7, 9, 11, 12, 13, 15, 16, 17, 22, 848, 531];
  static final _files = <int, File>{};
  static final version = ValueNotifier<int>(0);
  static Directory? _dir;

  static int get count => _files.length;
  static File? file(int id) => _files[id];

  static Future<Directory> _d() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    return _dir = Directory('${docs.path}/logos')..createSync(recursive: true);
  }

  static Future<void> init() async {
    try {
      final d = await _d();
      _files.clear();
      for (final f in d.listSync()) {
        if (f is File && f.path.endsWith('.png') && f.lengthSync() > 200) {
          final id = int.tryParse(f.uri.pathSegments.last.replaceAll('.png', ''));
          if (id != null) _files[id] = f;
        }
      }
      version.value++;
    } catch (_) {}
  }

  /// ينزّل الشعارات الناقصة؛ يعيد عدد الإخفاقات
  static Future<int> download(void Function(double) progress) async {
    final d = await _d();
    final todo = ids.toSet().toList();
    var fail = 0;
    for (var i = 0; i < todo.length; i++) {
      final id = todo[i];
      progress(i / todo.length);
      if (_files.containsKey(id)) continue;
      try {
        final r = await http.get(Uri.parse('https://media.api-sports.io/football/leagues/$id.png')).timeout(const Duration(seconds: 20));
        if (r.statusCode == 200 && r.bodyBytes.length > 200 && r.bodyBytes[0] == 0x89) {
          final f = File('${d.path}/$id.png');
          await f.writeAsBytes(r.bodyBytes);
          _files[id] = f;
        } else {
          fail++;
        }
      } catch (_) {
        fail++;
      }
    }
    progress(1);
    version.value++;
    return fail;
  }

  static Future<void> remove() async {
    try {
      final d = await _d();
      if (await d.exists()) await d.delete(recursive: true);
      _dir = null;
    } catch (_) {}
    _files.clear();
    version.value++;
  }
}
