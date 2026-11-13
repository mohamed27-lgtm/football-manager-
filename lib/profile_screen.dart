import 'package:flutter/material.dart' hide Text;
import 'game_state.dart';
import 'i18n.dart';
import 'widgets.dart';

class _Hex extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

/// الملف الشخصي: إحصاءات من المسيرات المحفوظة وإنجازات بسيطة
class ProfileScreen extends StatelessWidget {
  final String name, email;
  final List<SaveMeta> saves;
  const ProfileScreen({super.key, required this.name, required this.email, required this.saves});

  @override
  Widget build(BuildContext context) {
    final weeks = saves.fold<int>(0, (a, m) => a + m.week);
    final mb = saves.fold<int>(0, (a, m) => a + m.bytes) / 1e6;
    final ach = <(IconData, String, Color, bool)>[
      (Icons.flag, 'البداية', const Color(0xFFFFB74D), saves.isNotEmpty),
      (Icons.groups, 'المدرب', kAccent, saves.length >= 2),
      (Icons.timelapse, 'المخضرم', const Color(0xFFFF7043), saves.any((m) => m.week >= 20)),
      (Icons.lock_outline, 'مقفل', kMuted, false),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kAccent.withOpacity(0.5), width: 2)),
            child: const CoachAvatar(radius: 46),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
        Center(child: Text(email, style: const TextStyle(color: kMuted))),
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: const Color(0x33FFC857), borderRadius: BorderRadius.circular(20)),
            child: const Text('المدرب', style: TextStyle(color: kGold, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _stat('${saves.length}', 'المسيرات', kAccent)),
          const SizedBox(width: 8),
          Expanded(child: _stat('$weeks', 'الأسابيع', kGold)),
          const SizedBox(width: 8),
          Expanded(child: _stat('${mb.toStringAsFixed(1)} MB', 'التخزين', null)),
        ]),
        const SizedBox(height: 22),
        const Text('الإنجازات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          for (final a in ach)
            Column(children: [
              ClipPath(
                clipper: _Hex(),
                child: Container(
                  width: 62,
                  height: 68,
                  color: a.$4 ? a.$3 : kCard2,
                  child: Icon(a.$1, color: a.$4 ? Colors.black : kMuted, size: 28),
                ),
              ),
              const SizedBox(height: 6),
              Text(a.$2, style: TextStyle(fontSize: 12, color: a.$4 ? null : kMuted)),
            ]),
        ]),
        const SizedBox(height: 22),
        const Text('الحساب المرتبط', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: kCard2, shape: BoxShape.circle), child: const Icon(Icons.mail_outline)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(email, style: const TextStyle(color: kMuted, fontSize: 13)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String v, String l, Color? c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
        child: Column(children: [
          Text(v, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: c)),
          const SizedBox(height: 2),
          Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
      );
}
