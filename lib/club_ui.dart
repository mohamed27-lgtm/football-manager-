import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'widgets.dart';

/// مكوّنات واجهة مشتركة لصفحات النادي (بطاقات، حلقات تقدم، نقاط مستوى...)
class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color, border;
  final EdgeInsets margin;
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color, this.border, this.margin = const EdgeInsets.only(bottom: 12)});
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(color: color ?? kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: border ?? kLine)),
        child: child,
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      );
}

/// صف بطاقات إحصاء (قيمة كبيرة + عنوان)
class StatTiles extends StatelessWidget {
  final List<(String, String, Color)> items;
  const StatTiles(this.items, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          for (final e in items)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                child: Column(children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(e.$1, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: e.$3))),
                  const SizedBox(height: 2),
                  Text(e.$2, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 11.5)),
                ]),
              ),
            ),
        ]),
      );
}

/// حلقة تقدم بنسبة في الوسط
class Ring extends StatelessWidget {
  final double value;
  final String big, small;
  final Color color;
  final double size;
  const Ring({super.key, required this.value, required this.big, required this.small, required this.color, this.size = 104});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: size, height: size, child: CircularProgressIndicator(value: value.clamp(0.0, 1.0).toDouble(), strokeWidth: size / 10, strokeCap: StrokeCap.round, color: color, backgroundColor: kCard2)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(big, style: TextStyle(fontSize: size / 3.6, fontWeight: FontWeight.w900)),
            Text(small, style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ]),
      );
}

/// نقاط مستوى (5 مربعات صغيرة)
class LevelDots extends StatelessWidget {
  final int level, max;
  final Color color;
  final bool building;
  const LevelDots({super.key, required this.level, this.max = 5, required this.color, this.building = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < max; i++)
          Container(
            width: 22,
            height: 6,
            margin: const EdgeInsetsDirectional.only(end: 4),
            decoration: BoxDecoration(color: i < level ? color : (building && i == level ? color.withOpacity(0.35) : kCard2), borderRadius: BorderRadius.circular(3)),
          ),
      ]);
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, this.color, {super.key, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
      );
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBox(this.icon, this.color, {super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(size / 3.2)),
        child: Icon(icon, color: color, size: size * 0.5),
      );
}

/// شريط تقدم أفقي ملوّن
class Bar extends StatelessWidget {
  final double value;
  final Color color;
  final double h;
  const Bar(this.value, this.color, {super.key, this.h = 8});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(h), child: LinearProgressIndicator(value: value.clamp(0.0, 1.0).toDouble(), minHeight: h, color: color, backgroundColor: kCard2));
}

/// صف مفتاح/قيمة داخل بطاقة
class KvRow extends StatelessWidget {
  final String k, v;
  final Color? vc;
  final String? sub;
  const KvRow(this.k, this.v, {super.key, this.vc, this.sub});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(color: kMuted))),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: vc)),
            if (sub != null) Text(sub!, style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ]),
      );
}

/// متطلب بعلامة صح/خطأ
class Req extends StatelessWidget {
  final String text;
  final bool ok;
  const Req(this.text, this.ok, {super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.check_rounded : Icons.close_rounded, size: 16, color: ok ? const Color(0xFF1FA58A) : const Color(0xFFE5533D)),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 12, color: kMuted)),
      ]);
}

void snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
