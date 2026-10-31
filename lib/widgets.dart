import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models.dart';

const kBg = Color(0xFF0B0F14);
const kCard = Color(0xFF141A22);
const kCard2 = Color(0xFF1B232E);
const kAccent = Color(0xFF00E676);
const kMuted = Color(0xFF8A96A6);
const kLine = Color(0x14FFFFFF);

const _teamColors = [
  Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFFFDD835), Color(0xFF8E24AA),
  Color(0xFF00ACC1), Color(0xFFFB8C00), Color(0xFF43A047), Color(0xFFD81B60),
  Color(0xFF6D4C41), Color(0xFF3949AB), Color(0xFF00897B), Color(0xFF7CB342),
];
Color teamColor(int id) => _teamColors[id % _teamColors.length];

Color posColor(Pos p) => switch (p) {
      Pos.gk => const Color(0xFFFFB300),
      Pos.def => const Color(0xFF1E88E5),
      Pos.mid => const Color(0xFF43A047),
      Pos.att => const Color(0xFFE53935),
    };

Color ratingColor(num v) => v >= 75
    ? const Color(0xFF00E676)
    : v >= 68
        ? const Color(0xFF9CCC65)
        : v >= 60
            ? const Color(0xFFFFCA28)
            : const Color(0xFFFF7043);

String money(double v) => '${v.toStringAsFixed(1)}M';

Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: child,
      );
}

class RatingBadge extends StatelessWidget {
  final int value;
  final double size;
  const RatingBadge(this.value, {super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final c = ratingColor(value);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withOpacity(0.15),
        border: Border.all(color: c, width: 2),
      ),
      child: Text('$value',
          style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: size * 0.4)),
    );
  }
}

class StatBar extends StatelessWidget {
  final String label;
  final num value;
  final Color? color;
  const StatBar(this.label, this.value, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? ratingColor(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: kMuted, fontSize: 13))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0, 1).toDouble(),
              minHeight: 8,
              color: c,
              backgroundColor: kCard2,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text('${value.round()}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class PosChip extends StatelessWidget {
  final Pos pos;
  const PosChip(this.pos, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: posColor(pos).withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(pos.short,
            style: TextStyle(color: posColor(pos), fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

/// صورة من ملف محلي (حزمة منزّلة) أو من الشبكة
Widget appImage(String path,
    {required double w, required double h, BoxFit fit = BoxFit.contain, required Widget fallback}) {
  if (path.startsWith('/')) {
    return Image.file(
      File(path),
      width: w,
      height: h,
      fit: fit,
      cacheWidth: (w * 3).round(),
      errorBuilder: (_, __, ___) => fallback,
    );
  }
  return CachedNetworkImage(
    imageUrl: path,
    width: w,
    height: h,
    fit: fit,
    placeholder: (_, __) => fallback,
    errorWidget: (_, __, ___) => fallback,
  );
}

Widget teamBadge(Team t, {double size = 24}) {
  final fallback = CircleAvatar(radius: size / 2, backgroundColor: teamColor(t.id));
  if (t.badge == null) return fallback;
  return SizedBox(
    width: size,
    height: size,
    child: appImage(t.badge!, w: size, h: size, fallback: fallback),
  );
}

class PlayerAvatar extends StatelessWidget {
  final Player p;
  final double size;
  const PlayerAvatar(this.p, {super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    if (p.photo == null) return RatingBadge(p.overall, size: size);
    final fb = RatingBadge(p.overall, size: size);
    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Stack(clipBehavior: Clip.none, children: [
        ClipOval(child: appImage(p.photo!, w: size, h: size, fit: BoxFit.cover, fallback: fb)),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: ratingColor(p.overall), borderRadius: BorderRadius.circular(8)),
            child: Text('${p.overall}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black)),
          ),
        ),
      ]),
    );
  }
}
