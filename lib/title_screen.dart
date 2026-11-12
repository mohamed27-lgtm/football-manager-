import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'cabinet_screen.dart' show seasonLabel;
import 'game_state.dart';
import 'i18n.dart';
import 'trophies.dart';
import 'widgets.dart';

/// شاشة نسخ لقب معيّن: كأس كبير مع أسهم للتنقل بين النسخ الفائزة وإحصاءات الموسم
class TitleScreen extends StatefulWidget {
  final GameState gs;
  final String comp;
  final int? season;
  const TitleScreen({super.key, required this.gs, required this.comp, this.season});
  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  late List<int> eds; // الموسم الأحدث أولاً
  int idx = 0;

  @override
  void initState() {
    super.initState();
    final key = widget.comp;
    eds = [
      for (final h in widget.gs.honours)
        if (parseHonour(h) case final p? when p.$1 == key) p.$2
    ]..sort((a, b) => b.compareTo(a));
    if (eds.isEmpty) eds = [widget.season ?? widget.gs.celebStats?['s'] ?? widget.gs.season];
    final i = widget.season == null ? 0 : eds.indexOf(widget.season!);
    idx = i < 0 ? 0 : i;
  }

  Widget _stat(String v, String l, {bool wide = false}) => Expanded(
        flex: wide ? 3 : 2,
        child: Column(children: [
          Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          Text(l, style: const TextStyle(color: Color(0xFF8FA0C0), fontSize: 13)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final comp = widget.comp;
    final isLeague = comp == 'الدوري';
    final name = isLeague ? gs.leagueName : comp;
    final key = trophyKey(name, gs.leagueName, isLeague: isLeague);
    final s = eds[idx];
    final st = gs.titleStats['$comp|$s'] ?? (gs.celebStats != null && gs.celebStats!['s'] == s && gs.celebration == comp ? gs.celebStats : null);
    final scorer = gs.titleScorers['$comp|$s'];
    final isNew = idx == 0 && (s == gs.season || (s == gs.season - 1 && gs.seasonOver));
    void go(int d) => setState(() => idx = (idx + d).clamp(0, eds.length - 1));
    Widget arrow(IconData i, int d) => GestureDetector(
          onTap: eds.length > 1 ? () => go(d) : null,
          child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF232B3E), shape: BoxShape.circle), child: Icon(i, color: Colors.white.withOpacity(eds.length > 1 ? 1 : 0.25))),
        );
    return Scaffold(
      appBar: gameBar(context, gs, 'خزينة البطولات'),
      body: Unfilter(
        child: Container(
          color: const Color(0xFF080C16),
          child: ListView(padding: const EdgeInsets.fromLTRB(22, 16, 22, 24), children: [
            Column(children: [
              Text(isNew ? 'النسخة الحالية' : 'نسخة سابقة', style: const TextStyle(color: Color(0xFF8FA0C0), fontSize: 15)),
              const SizedBox(height: 2),
              Text('بطل $name', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE6B422), fontWeight: FontWeight.w900, fontSize: 26)),
            ]),
            const SizedBox(height: 16),
            Stack(alignment: Alignment.center, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B3F4B), Color(0xFF151A27)]), border: Border.all(color: const Color(0xFF2C3650))),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(s),
                      tween: Tween(begin: 0.4, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                      child: Image.asset('assets/trophies/$key.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Text('🏆', style: TextStyle(fontSize: 110)))),
                    ),
                  ),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [arrow(Icons.chevron_right_rounded, 1), arrow(Icons.chevron_left_rounded, -1)]),
            ]),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: const Color(0xFF05080F),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                color: const Color(0xFFF1F4F9),
                child: Column(children: [
                  Text(name, style: const TextStyle(color: Color(0xFF111A30), fontWeight: FontWeight.w900, fontSize: 20)),
                  Text('${seasonLabel(s)} • النسخة ${eds.length - idx}', style: const TextStyle(color: Color(0xFF59647A), fontSize: 15)),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              decoration: BoxDecoration(color: const Color(0xFF161C2B), borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                if (st != null)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (isLeague) _stat('${st['pts'] ?? 0}', 'النقاط'),
                    if (isLeague) _stat('${(st['gf'] ?? 0) - (st['ga'] ?? 0) >= 0 ? '+' : ''}${(st['gf'] ?? 0) - (st['ga'] ?? 0)}', 'الفارق') else _stat('${st['pl'] ?? 0}', 'مباريات الموسم'),
                    _stat(scorer == null || scorer.isEmpty ? '${st['top'] ?? 0}' : '${st['top'] ?? 0} $scorer', 'الهدّاف', wide: true),
                  ])
                else
                  const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('لا توجد إحصاءات محفوظة لهذه النسخة (تُسجَّل الإحصاءات من هذا التحديث فصاعداً)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8FA0C0), fontSize: 12.5))),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  for (var i = 0; i < eds.length && i < 12; i++)
                    GestureDetector(
                      onTap: () => setState(() => idx = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF232B3E), borderRadius: BorderRadius.circular(10), border: i == idx ? Border.all(color: const Color(0xFFE6B422)) : null),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (i == idx) Container(width: 9, height: 9, margin: const EdgeInsets.only(left: 6), decoration: const BoxDecoration(color: Color(0xFF6C8CFF), shape: BoxShape.circle)),
                          Text(seasonLabel(eds[i]), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                        ]),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)), child: const Text('إغلاق', style: TextStyle(color: Color(0xFF111A30), fontWeight: FontWeight.w900, fontSize: 17))),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: '🏆 ${gs.user.name} بطل $name — ${seasonLabel(s)} (اللقب رقم ${eds.length - idx})'));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نُسخ نص اللقب إلى الحافظة')));
                },
                child: Container(width: 54, height: 54, decoration: BoxDecoration(color: const Color(0xFF232B3E), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.ios_share_rounded, color: Colors.white)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
