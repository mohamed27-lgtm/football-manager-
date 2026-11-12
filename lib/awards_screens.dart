import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'flags.dart';
import 'game_state.dart';
import 'i18n.dart';
import 'models.dart';
import 'more_screen.dart';
import 'widgets.dart';

const _gold = Color(0xFFF5B83D);
const _deep = Color(0xFF0F1B33);

String _m(double v) => '${v.toStringAsFixed(v < 1 ? 2 : 1)}M';
List<Map> _noms(Map a) => (a['nom'] as List).cast<Map>();
Map? _award(GameState gs, String id) {
  for (final a in (gs.ceremony?['a'] as List? ?? const [])) {
    if (a['id'] == id) return a as Map;
  }
  return null;
}

List<Map> _all(GameState gs) => [for (final a in (gs.ceremony?['a'] as List? ?? const [])) a as Map];

/// الجائزة الحالية: أول جائزة لم تُعلن بعد
Map? _current(GameState gs) {
  for (final a in _all(gs)) {
    if (a['rev'] != true) return a;
  }
  return null;
}

Team? _teamOf(GameState gs, int? id) {
  if (id == null || id < 0) return null;
  if (id >= 1000) return gs.foreign[id];
  return id < gs.teams.length ? gs.teams[id] : null;
}

/// ميدالية ذهبية لكل جائزة (والكرة الذهبية بكرة على قاعدة)
class AwardMedal extends StatelessWidget {
  final String id;
  final double size;
  const AwardMedal(this.id, {super.key, this.size = 56});
  @override
  Widget build(BuildContext context) {
    final info = kAwardInfo[id]!;
    if (id == 'bd') return Unfilter(child: SizedBox(width: size, height: size, child: CustomPaint(painter: _BallTrophy())));
    return Unfilter(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE08A), Color(0xFFD99A1C)]),
          boxShadow: [BoxShadow(color: _gold.withOpacity(0.35), blurRadius: 10)],
        ),
        child: Text(info.icon, style: TextStyle(fontSize: size * 0.46)),
      ),
    );
  }
}

class _BallTrophy extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final base = Paint()..color = const Color(0xFF8A5A12);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.88, w * 0.44, h * 0.1), const Radius.circular(3)), base);
    c.drawRect(Rect.fromLTWH(w * 0.44, h * 0.62, w * 0.12, h * 0.27), Paint()..color = const Color(0xFFD99A1C));
    final r = w * 0.34;
    final ctr = Offset(w * 0.5, h * 0.36);
    c.drawCircle(ctr, r, Paint()..shader = const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFE9A0), Color(0xFFE0A526), Color(0xFFB87812)]).createShader(Rect.fromCircle(center: ctr, radius: r)));
    final line = Paint()
      ..color = const Color(0xFF9A6410)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    final pent = Path();
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5;
      final p = Offset(ctr.dx + cos(a) * r * 0.38, ctr.dy + sin(a) * r * 0.38);
      i == 0 ? pent.moveTo(p.dx, p.dy) : pent.lineTo(p.dx, p.dy);
      c.drawLine(Offset(ctr.dx + cos(a) * r * 0.38, ctr.dy + sin(a) * r * 0.38), Offset(ctr.dx + cos(a) * r * 0.95, ctr.dy + sin(a) * r * 0.95), line);
    }
    pent.close();
    c.drawPath(pent, line..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// وجه اللاعب (صورته أو أيقونة) أو شعار النادي/علم المنتخب لغير اللاعبين
class AwardFace extends StatelessWidget {
  final GameState gs;
  final Map n;
  final double size;
  final Color? ring;
  const AwardFace(this.gs, this.n, {super.key, this.size = 56, this.ring});

  @override
  Widget build(BuildContext context) {
    final k = n['k'];
    if (k == 'n') return FlagBadge(n['n'] as String, size: size);
    if (k == 'c' || k == 'b') {
      final t = _teamOf(gs, n['t'] as int?);
      if (t != null) return teamBadge(t, size: size);
    }
    final tid = (n['t'] as int?) ?? 0;
    final p = n['id'] == null ? null : gs.playerById(n['id'] as int);
    final hue = ((n['id'] as int? ?? 0) * 47 % 360).toDouble();
    final tone = HSLColor.fromAHSL(1, hue, 0.3, 0.42).toColor();
    final fb = Container(
      width: size,
      height: size,
      color: const Color(0xFFE7EAF3),
      child: Stack(alignment: Alignment.bottomCenter, children: [
        Positioned(top: size * 0.17, child: Container(width: size * 0.36, height: size * 0.36, decoration: BoxDecoration(color: const Color(0xFFC4CAD9), shape: BoxShape.circle))),
        Positioned(bottom: -size * 0.2, child: Container(width: size * 0.8, height: size * 0.6, decoration: BoxDecoration(color: tid >= 0 ? teamColor(tid) : tone, shape: BoxShape.circle))),
      ]),
    );
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring ?? teamColor(tid), width: 2.5)),
      child: ClipOval(child: p?.photo == null ? fb : appImage(p!.photo!, w: size, h: size, fit: BoxFit.cover, fallback: fb)),
    );
  }
}

Widget _chip(String t, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
      child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: fg)),
    );

String _sub(GameState gs, Map n) {
  if (n['k'] == 'p') return '${const ['حارس', 'مدافع', 'وسط', 'مهاجم'][n['pos'] as int]} • ${n['c']}';
  return '${n['c']}';
}

// ───────────────── 1) قائمة الحفل ─────────────────
class AwardsHubScreen extends StatelessWidget {
  final GameState gs;
  const AwardsHubScreen({super.key, required this.gs});

  void _open(BuildContext context, Map a) {
    final id = a['id'] as String;
    final Widget w = id == 'xi'
        ? TeamOfSeasonScreen(gs: gs)
        : (a['rev'] == true ? AwardWinnerScreen(gs: gs, id: id) : AwardNomineesScreen(gs: gs, id: id));
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gs,
      builder: (context, _) {
        final list = _all(gs);
        final done = list.where((a) => a['rev'] == true).length;
        final cur = _current(gs);
        return Scaffold(
          appBar: AppBar(title: Text(kEventTitle[gs.ceremony?['ev'] ?? 'season'] ?? 'جوائز الموسم', style: const TextStyle(fontSize: 16))),
          body: list.isEmpty
              ? const Center(child: EmptyState(icon: Icons.emoji_events_outlined, title: 'لا حفل جوائز الآن', subtitle: 'يقام الحفل عند نهاية كل موسم'))
              : ListView(padding: const EdgeInsets.all(14), children: [
                  Row(children: [
                    Expanded(child: Panel(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [const Text('موسم', style: TextStyle(color: kMuted)), const SizedBox(width: 8), Text('${gs.ceremony?['s'] ?? gs.season}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]))),
                    const SizedBox(width: 10),
                    _chip((gs.ceremony?['ev'] ?? 'season') == 'season' ? 'حفل نهاية الموسم' : 'حفل رسمي', const Color(0xFFFBEBB5), const Color(0xFF7A5A00)),
                  ]),
                  const SizedBox(height: 12),
                  Unfilter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF22345C), _deep])),
                      child: Row(children: [
                        const AwardMedal('bd', size: 92),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('حفل توزيع الجوائز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
                            const SizedBox(height: 4),
                            Text('${list.length} جوائز • أُعلنت $done', style: const TextStyle(color: Color(0xFF9FB0D0), fontSize: 12.5)),
                            const SizedBox(height: 8),
                            Row(children: [
                              for (var i = 0; i < list.length; i++)
                                Expanded(child: Container(height: 5, margin: const EdgeInsets.only(left: 3), decoration: BoxDecoration(color: i < done ? _gold : const Color(0xFF34476E), borderRadius: BorderRadius.circular(3)))),
                            ]),
                            const SizedBox(height: 12),
                            if (cur != null)
                              GradientButton(label: 'تابع الحفل', icon: Icons.auto_awesome, onPressed: () => _open(context, cur))
                            else
                              GradientButton(label: 'جوائز لاعبيك', icon: Icons.card_giftcard, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyAwardsScreen(gs: gs)))),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Panel(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: kLine),
                        _row(context, list[i], cur),
                      ],
                    ]),
                  ),
                  if (cur == null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyAwardsScreen(gs: gs))),
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text('جوائز لاعبيك'),
                    ),
                  ],
                ]),
        );
      },
    );
  }

  Widget _row(BuildContext context, Map a, Map? cur) {
    final id = a['id'] as String;
    final info = kAwardInfo[id]!;
    final rev = a['rev'] == true;
    final isCur = cur != null && cur['id'] == id;
    final locked = !rev && !isCur;
    final noms = _noms(a);
    final w = noms.first;
    final mine = id == 'xi' ? noms.any((n) => n['m'] == true) : w['m'] == true;
    return InkWell(
      onTap: locked ? null : () => _open(context, a),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(children: [
            AwardMedal(id, size: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(info.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                const SizedBox(height: 4),
                if (rev && id != 'xi')
                  Row(children: [
                    AwardFace(gs, w, size: 30),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${w['n']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                  ])
                else if (rev)
                  Text('${noms.where((n) => n['m'] == true).length} من لاعبيك', style: const TextStyle(color: kMuted, fontSize: 12.5))
                else
                  Text(locked ? (id == 'xi' ? 'بعد إعلان بقية الجوائز' : 'قريباً') : info.desc, style: const TextStyle(color: kMuted, fontSize: 12.5)),
              ]),
            ),
            if (mine && rev) _chip('فريقك', kPrimary, Colors.white),
            if (isCur) _chip('الآن', const Color(0xFFD6E8FB), const Color(0xFF1F5FA8)),
            if (locked) const Icon(Icons.lock_outline, color: kMuted, size: 20) else const Icon(Icons.chevron_left, color: kMuted),
          ]),
        ),
      ),
    );
  }
}

// ───────────────── 2) المرشحون ─────────────────
class AwardNomineesScreen extends StatelessWidget {
  final GameState gs;
  final String id;
  const AwardNomineesScreen({super.key, required this.gs, required this.id});

  @override
  Widget build(BuildContext context) {
    final a = _award(gs, id)!;
    final info = kAwardInfo[id]!;
    final noms = _noms(a);
    return Scaffold(
      appBar: AppBar(title: Text(info.title)),
      body: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 100), children: [
        Unfilter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF22345C), _deep])),
            child: Column(children: [
              AwardMedal(id, size: 82),
              const SizedBox(height: 8),
              Text('المرشحون لـ${info.title}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
              Text('موسم ${gs.season} • أفضل ${noms.length} مرشحين', style: const TextStyle(color: Color(0xFF9FB0D0), fontSize: 12.5)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        for (final n in noms) _card(n),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: GradientButton(
            label: 'أعلن الفائز',
            icon: Icons.auto_awesome,
            onPressed: () {
              gs.revealAward(id);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AwardWinnerScreen(gs: gs, id: id)));
            },
          ),
        ),
      ),
    );
  }

  Widget _card(Map n) {
    final mine = n['m'] == true;
    final isP = n['k'] == 'p';
    final ov = n['ov'] as int?;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: mine ? kPrimary : kLine, width: mine ? 2 : 1)),
      child: Column(children: [
        Row(children: [
          AwardFace(gs, n, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text('${n['n']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                if (mine) ...[const SizedBox(width: 6), _chip('فريقك', kPrimary, Colors.white)],
              ]),
              const SizedBox(height: 4),
              Row(children: [
                if (n['nat'] != null) ...[FlagBadge('${n['nat']}', size: 18), const SizedBox(width: 6)],
                Expanded(child: Text(_sub(gs, n), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5))),
              ]),
            ]),
          ),
          if (isP && ov != null)
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: ratingColor(ov), border: Border.all(color: ratingColor(ov).withOpacity(0.3), width: 4)),
              child: Text('$ov', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [for (final s in _stats(n)) Expanded(child: _statBox(s.$1, s.$2))]),
      ]),
    );
  }
}

List<(String, String)> _stats(Map n) {
  if (n['st'] != null) return [for (final s in (n['st'] as List)) ((s as List)[0] as String, s[1] as String)];
  if (n['k'] == 'p') return [('تمريرة', '${n['a']}'), ('هدف', '${n['g']}'), ('التقييم', '${n['r']}')];
  return [for (final s in (n['st'] as List)) ((s as List)[0] as String, s[1] as String)];
}

Widget _statBox(String label, String value) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        Text(label, style: const TextStyle(color: kMuted, fontSize: 11.5)),
      ]),
    );

// ───────────────── 3) إعلان الفائز ─────────────────
class AwardWinnerScreen extends StatelessWidget {
  final GameState gs;
  final String id;
  const AwardWinnerScreen({super.key, required this.gs, required this.id});

  @override
  Widget build(BuildContext context) {
    final a = _award(gs, id)!;
    final info = kAwardInfo[id]!;
    final noms = _noms(a);
    final w = noms.first;
    final list = _all(gs);
    final idx = list.indexOf(list.firstWhere((x) => x['id'] == id));
    final next = idx + 1 < list.length ? list[idx + 1] : null;
    Widget nameRow = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (w['k'] == 'p') Text(const ['حارس', 'مدافع', 'وسط', 'مهاجم'][w['pos'] as int], style: const TextStyle(color: Color(0xFF9FB0D0))),
      if (w['k'] == 'p') const Text('  •  ', style: TextStyle(color: Color(0xFF6E7FA3))),
      if (w['nat'] != null) FlagBadge('${w['nat']}', size: 22),
      const SizedBox(width: 8),
      Flexible(child: Text('${w['c']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9FB0D0)))),
    ]);
    return Unfilter(
      child: Scaffold(
        backgroundColor: _deep,
        appBar: AppBar(backgroundColor: _deep, foregroundColor: Colors.white, elevation: 0, title: Text(info.title, style: const TextStyle(color: Colors.white))),
        body: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _Confetti(id.hashCode))),
          ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 100), children: [
            Center(child: Text('⭐ ${info.title} ${gs.ceremony?['s'] ?? gs.season} ⭐', style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 15))),
            const SizedBox(height: 14),
            Center(
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 5), boxShadow: [BoxShadow(color: _gold.withOpacity(0.35), blurRadius: 30)]),
                  child: AwardFace(gs, w, size: 150, ring: Colors.transparent),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Center(child: AwardMedal(id, size: 60)),
            const SizedBox(height: 8),
            Center(child: Text('${w['n']}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30))),
            const SizedBox(height: 4),
            nameRow,
            if (w['m'] == true) ...[
              const SizedBox(height: 8),
              Center(child: _chip('🎉 من فريقك', kPrimary, Colors.white)),
            ],
            const SizedBox(height: 16),
            Row(children: [
              for (final s in _stats(w))
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x33FFFFFF))),
                    child: Column(children: [
                      Text(s.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
                      Text(w['k'] == 'p' && s.$1 == 'التقييم' ? 'متوسط التقييم' : s.$1, style: const TextStyle(color: Color(0xFF9FB0D0), fontSize: 12)),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('نتيجة التصويت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                for (var i = 0; i < noms.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      SizedBox(width: 120, child: Text('${noms[i]['n']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: (noms[i]['v'] as int) / 100, minHeight: 9, backgroundColor: const Color(0xFF2A3B63), valueColor: AlwaysStoppedAnimation(i == 0 ? _gold : const Color(0xFF6B7BB0))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(width: 38, child: Text('${noms[i]['v']}%', style: TextStyle(color: i == 0 ? _gold : const Color(0xFF9FB0D0), fontWeight: FontWeight.w900, fontSize: 13))),
                    ]),
                  ),
              ]),
            ),
          ]),
        ]),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Row(children: [
              Expanded(
                child: GradientButton(
                  label: next == null ? 'جوائز لاعبيك' : 'الجائزة التالية',
                  icon: Icons.chevron_left,
                  onPressed: () {
                    final nav = Navigator.of(context);
                    if (next == null) {
                      nav.pushReplacement(MaterialPageRoute(builder: (_) => MyAwardsScreen(gs: gs)));
                    } else if (next['id'] == 'xi') {
                      gs.revealAward('xi');
                      nav.pushReplacement(MaterialPageRoute(builder: (_) => TeamOfSeasonScreen(gs: gs)));
                    } else {
                      nav.pushReplacement(MaterialPageRoute(builder: (_) => AwardNomineesScreen(gs: gs, id: next['id'] as String)));
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x55FFFFFF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '🏆 ${info.title} ${gs.ceremony?['s'] ?? gs.season}: ${w['n']} (${w['c']})'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النتيجة')));
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('شارك'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Confetti extends CustomPainter {
  final int seed;
  _Confetti(this.seed);
  @override
  void paint(Canvas c, Size s) {
    final r = Random(seed);
    const cols = [Color(0xFFF0583A), Color(0xFFF5B83D), Color(0xFF1FA58A), Color(0xFFA9D4F8), Color(0xFF6A6FC4), Colors.white];
    for (var i = 0; i < 38; i++) {
      final p = Paint()..color = cols[r.nextInt(cols.length)].withOpacity(0.85);
      c.save();
      c.translate(r.nextDouble() * s.width, r.nextDouble() * s.height * 0.62);
      c.rotate(r.nextDouble() * pi);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, 7 + r.nextDouble() * 7, 12 + r.nextDouble() * 6), const Radius.circular(2)), p);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ───────────────── 4) فريق الموسم ─────────────────
class TeamOfSeasonScreen extends StatelessWidget {
  final GameState gs;
  const TeamOfSeasonScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    final a = _award(gs, 'xi');
    final xi = a == null ? <Map>[] : _noms(a);
    final mine = xi.where((n) => n['m'] == true).length;
    // خطوط الملعب من الأعلى (الهجوم) إلى الأسفل (الحارس)
    final rows = <(List<Map>, double)>[
      (xi.where((n) => n['pos'] == 3).toList(), 0.12),
      (xi.where((n) => n['pos'] == 2).toList(), 0.43),
      (xi.where((n) => n['pos'] == 1).toList(), 0.73),
      (xi.where((n) => n['pos'] == 0).toList(), 0.93),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('فريق الموسم')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Row(children: [
          _chip('4-3-3', const Color(0xFFD6E8FB), const Color(0xFF1F5FA8)),
          const Spacer(),
          Text('$mine من لاعبيك في التشكيلة', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 10),
        Unfilter(
          child: AspectRatio(
            aspectRatio: 0.78,
            child: LayoutBuilder(builder: (context, bc) {
              final w = bc.maxWidth, h = bc.maxHeight;
              final kids = <Widget>[Positioned.fill(child: CustomPaint(painter: _PitchPainter()))];
              for (final r in rows) {
                final l = r.$1;
                for (var i = 0; i < l.length; i++) {
                  final x = (i + 1) / (l.length + 1);
                  final dy = l.length == 3 && i == 1 && r.$2 < 0.5 ? (r.$2 < 0.2 ? -0.02 : 0.05) : 0.0;
                  kids.add(Positioned(left: x * w - 40, top: (r.$2 + dy) * h - 38, width: 80, child: _pitchPlayer(l[i])));
                }
              }
              return ClipRRect(borderRadius: BorderRadius.circular(22), child: Stack(children: kids));
            }),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: GradientButton(label: 'جوائز لاعبيك', icon: Icons.chevron_left, onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MyAwardsScreen(gs: gs)))),
        ),
      ),
    );
  }

  Widget _pitchPlayer(Map n) {
    final name = (n['n'] as String).split(' ').last;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        AwardFace(gs, n, size: 52, ring: n['m'] == true ? kPrimary : Colors.white),
        Positioned(
          left: -6,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFF1FA58A), borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white, width: 1.5)),
            child: Text('${n['ov']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ),
      ]),
      const SizedBox(height: 3),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFF14523A), borderRadius: BorderRadius.circular(6)),
        child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
      ),
    ]);
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    for (var i = 0; i < 8; i++) {
      c.drawRect(Rect.fromLTWH(0, h * i / 8, w, h / 8), Paint()..color = i.isEven ? const Color(0xFF2F9A58) : const Color(0xFF2B8F53));
    }
    final l = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawRect(Rect.fromLTWH(w * 0.03, h * 0.02, w * 0.94, h * 0.96), l);
    c.drawLine(Offset(w * 0.03, h * 0.5), Offset(w * 0.97, h * 0.5), l);
    c.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.12, l);
    c.drawRect(Rect.fromLTWH(w * 0.27, h * 0.02, w * 0.46, h * 0.13), l);
    c.drawRect(Rect.fromLTWH(w * 0.27, h * 0.85, w * 0.46, h * 0.13), l);
    c.drawRect(Rect.fromLTWH(w * 0.38, h * 0.02, w * 0.24, h * 0.05), l);
    c.drawRect(Rect.fromLTWH(w * 0.38, h * 0.93, w * 0.24, h * 0.05), l);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ───────────────── 5) جوائز لاعبيك ─────────────────
class MyAwardsScreen extends StatelessWidget {
  final GameState gs;
  const MyAwardsScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gs,
      builder: (context, _) {
        final wins = gs.myAwardWins();
        final paid = gs.ceremony?['paid'] == true;
        final money = wins.fold<double>(0, (a, w) => a + w.money);
        final value = wins.fold<double>(0, (a, w) => a + w.value);
        final players = wins.where((w) => w.id != 'xi' && w.pid != null).toList();
        final single = [for (final w in wins) if (w.id != 'xi') w];
        final xiMine = wins.where((w) => w.id == 'xi').toList();
        return Scaffold(
          appBar: AppBar(title: const Text('جوائز لاعبيك')),
          body: wins.isEmpty
              ? const Center(child: EmptyState(icon: Icons.emoji_events_outlined, title: 'لم يفز أحد من لاعبيك', subtitle: 'تألق في الموسم القادم لتنافس على الجوائز'))
              : ListView(padding: const EdgeInsets.all(14), children: [
                  Row(children: [
                    _top('فائزون', '${wins.length}', kPrimary),
                    _top('مكافآت', '+${_m(money)}', const Color(0xFFB8860B)),
                    _top('قيمة سوقية', '+${_m(value)}', const Color(0xFF1FA58A)),
                  ]),
                  const SizedBox(height: 12),
                  Panel(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      for (var i = 0; i < single.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: kLine),
                        _winRow(single[i]),
                      ],
                      if (xiMine.isNotEmpty) ...[
                        if (single.isNotEmpty) const Divider(height: 1, color: kLine),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            const AwardMedal('xi', size: 54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('فريق الموسم', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                                Text('${xiMine.length} من لاعبيك: ${xiMine.map((w) => w.name).join('، ')}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                                const SizedBox(height: 6),
                                Wrap(spacing: 6, children: [
                                  _chip('+${_m(0.1)} لكل لاعب', const Color(0xFFFBEBB5), const Color(0xFF7A5A00)),
                                  _chip('+${kAwardInfo['xi']!.morale} معنويات', const Color(0xFFD7F2E9), const Color(0xFF0B6B53)),
                                ]),
                              ]),
                            ),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFE8F1FB), borderRadius: BorderRadius.circular(14)),
                    child: Row(children: const [
                      Icon(Icons.emoji_events_outlined, size: 18, color: Color(0xFF1F5FA8)),
                      SizedBox(width: 8),
                      Expanded(child: Text('تُضاف الجوائز تلقائياً إلى رف الجوائز الفردية في الخزينة', style: TextStyle(color: Color(0xFF1F5FA8), fontSize: 12.5))),
                    ]),
                  ),
                  if (players.isEmpty && single.isNotEmpty) const SizedBox.shrink(),
                ]),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Row(children: [
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    label: paid ? 'تم الاستلام ✓' : 'استلام المكافآت',
                    icon: Icons.check,
                    onPressed: wins.isEmpty || paid ? null : gs.claimAwardRewards,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TrophyScreen(gs: gs))),
                      icon: const Icon(Icons.emoji_events_outlined, size: 18),
                      label: const Text('إلى الخزينة'),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _top(String label, String v, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Column(children: [
            Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: c)),
            Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      );

  Widget _winRow(({String id, int? pid, String name, double money, int morale, double value}) w) {
    final info = kAwardInfo[w.id]!;
    final n = <String, dynamic>{'k': w.pid == null ? 'b' : 'p', 'id': w.pid, 't': gs.user.id, 'n': w.name};
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        AwardMedal(w.id, size: 54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
            const SizedBox(height: 4),
            Row(children: [
              if (w.pid != null) ...[AwardFace(gs, n, size: 28), const SizedBox(width: 6)],
              Expanded(child: Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (w.money > 0) _chip('+${_m(w.money)} مكافأة', const Color(0xFFFBEBB5), const Color(0xFF7A5A00)),
              if (w.morale > 0) _chip('+${w.morale} معنويات', const Color(0xFFD7F2E9), const Color(0xFF0B6B53)),
              if (w.value > 0) _chip('+${_m(w.value)} قيمة', const Color(0xFFD6E8FB), const Color(0xFF1F5FA8)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
