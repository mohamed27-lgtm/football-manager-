import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models.dart';

const kBg = Color(0xFF070B12);
const kCard = Color(0xFF0F1620);
const kCard2 = Color(0xFF172130);
const kAccent = Color(0xFF00E676);
const kGold = Color(0xFFFFC857);
const kBlue = Color(0xFF3D8BFF);
const kMuted = Color(0xFF8593A6);
const kLine = Color(0x1AFFFFFF);

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

Widget sectionTitle(String t, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
      child: Row(children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        if (trailing != null) trailing,
      ]),
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
          color: color,
          gradient: color == null
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF131C28), kCard],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kLine),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: child,
      );
}

/// زر رئيسي متدرّج
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final List<Color> colors;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.colors = const [Color(0xFF00E676), Color(0xFF00C853)],
  });

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    return Opacity(
      opacity: on ? 1 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, color: Colors.black, size: 22), const SizedBox(width: 8)],
                Text(label, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// نقاط آخر النتائج (W/D/L)
class FormDots extends StatelessWidget {
  final List<String> form;
  final int count;
  const FormDots(this.form, {super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final last = form.length > count ? form.sublist(form.length - count) : form;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < count; i++)
        Builder(builder: (_) {
          final r = i < last.length ? last[i] : null;
          final c = r == 'W'
              ? kAccent
              : r == 'L'
                  ? const Color(0xFFFF5252)
                  : r == 'D'
                      ? kGold
                      : kCard2;
          return Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.withOpacity(r == null ? 1 : 0.9), borderRadius: BorderRadius.circular(5)),
            child: Text(
              r == 'W' ? 'ف' : r == 'L' ? 'خ' : r == 'D' ? 'ت' : '',
              style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
            ),
          );
        }),
    ]);
  }
}

class _ShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(0, h * 0.14)
      ..quadraticBezierTo(w * 0.5, -h * 0.06, w, h * 0.14)
      ..lineTo(w, h * 0.56)
      ..quadraticBezierTo(w, h * 0.86, w * 0.5, h)
      ..quadraticBezierTo(0, h * 0.86, 0, h * 0.56)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

String _initials(String name) {
  final w = name
      .split(RegExp(r'[\s\-]+'))
      .where((e) => e.isNotEmpty && !const {'fc', 'cf', 'ac', 'as', 'sc', 'de', 'the', 'real', 'club', 'afc', 'rc'}.contains(e.toLowerCase()))
      .toList();
  if (w.isEmpty) return name.isEmpty ? '?' : name[0].toUpperCase();
  if (w.length == 1) return w.first.substring(0, w.first.length >= 3 ? 3 : w.first.length).toUpperCase();
  return (w[0][0] + w[1][0]).toUpperCase();
}

/// شعار نادٍ بديل على شكل درع عندما لا تتوفر صورة
class ClubCrest extends StatelessWidget {
  final Team team;
  final double size;
  const ClubCrest(this.team, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final c = teamColor(team.id);
    final dark = HSLColor.fromColor(c).withLightness(0.22).toColor();
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: ClipPath(
        clipper: _ShieldClipper(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c, dark]),
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(team.name),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
            ),
          ),
        ),
      ),
    );
  }
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
  final fallback = ClubCrest(t, size: size);
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

/// الراتب الأسبوعي بالآلاف
String wageK(double w) => '${(w * 1000).round()}K';

/// مبلغ بخانتين عشريتين
String money2(double v) => '${v.toStringAsFixed(2)}M';
