import 'package:flutter/material.dart' as m;
import 'settings.dart';
import 'translations.dart';

final RegExp _ar = RegExp(r'[؀-ۿ]');
final Map<String, String> _cache = {};
List<_Tpl>? _tpls;

class _Tpl {
  final RegExp re;
  final List<String> out;
  final int weight;
  _Tpl(this.re, this.out, this.weight);
}

List<_Tpl> _templates() {
  final l = <_Tpl>[];
  kTr.forEach((k, v) {
    if (!k.contains('{}')) return;
    final parts = k.split('{}');
    final lit = parts.join();
    if (!_ar.hasMatch(lit)) return;
    final src = '^${parts.map(RegExp.escape).join('(.*?)')}\$';
    l.add(_Tpl(RegExp(src, dotAll: true), v, lit.length));
  });
  l.sort((a, b) => b.weight.compareTo(a.weight));
  return l;
}

String _fill(String t, List<String> args) {
  var i = 0;
  return t.replaceAllMapped('{}', (_) => i < args.length ? args[i++] : '');
}

String _tr(String s, int idx, int depth) {
  final e = kTr[s];
  if (e != null) return e[idx];
  if (depth > 2) return s;
  final t = s.trim();
  if (t != s) {
    final e2 = kTr[t];
    if (e2 != null) return s.replaceFirst(t, e2[idx]);
  }
  _tpls ??= _templates();
  for (final tp in _tpls!) {
    final mt = tp.re.firstMatch(s);
    if (mt == null) continue;
    final args = <String>[
      for (var g = 1; g <= mt.groupCount; g++) _tr(mt.group(g) ?? '', idx, depth + 1),
    ];
    return _fill(tp.out[idx], args);
  }
  return s;
}

/// يترجم نصاً عربياً إلى اللغة المختارة (يبقى كما هو إن لم تتوفر ترجمة)
String tr(String ar) {
  final l = AppSettings.i.lang;
  if (l == 'ar' || ar.isEmpty || !_ar.hasMatch(ar)) return ar;
  final idx = l == 'en' ? 0 : l == 'fr' ? 1 : 2;
  final key = '$idx|$ar';
  final c = _cache[key];
  if (c != null) return c;
  final r = _tr(ar, idx, 0);
  if (_cache.length > 6000) _cache.clear();
  _cache[key] = r;
  return r;
}

/// بديل لـ Text يترجم النص تلقائياً وقت العرض
class Text extends m.StatelessWidget {
  final String data;
  final m.TextStyle? style;
  final m.TextAlign? textAlign;
  final int? maxLines;
  final m.TextOverflow? overflow;
  final bool? softWrap;
  final m.TextScaler? textScaler;
  final m.TextDirection? textDirection;
  final String? semanticsLabel;
  final m.StrutStyle? strutStyle;
  final m.TextWidthBasis? textWidthBasis;
  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaler,
    this.textDirection,
    this.semanticsLabel,
    this.strutStyle,
    this.textWidthBasis,
  });
  @override
  m.Widget build(m.BuildContext context) => m.Text(
        tr(data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        textScaler: textScaler,
        textDirection: textDirection,
        semanticsLabel: semanticsLabel,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
      );
}
