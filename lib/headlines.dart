import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import 'game_state.dart';
import 'i18n.dart';
import 'widgets.dart';

/// عناوين صحفية مولّدة من حالة اللعبة الفعلية: (أيقونة، نص)
List<(String, String)> headlinesOf(GameState gs) {
  final out = <(String, String)>[];
  if (gs.fired) return out;
  final u = gs.user;
  final tbl = gs.table;
  final pos = tbl.indexOf(u) + 1;
  if (gs.deadlineDay) out.add(('⏰', 'اليوم آخر يوم في الميركاتو: الأندية تتسابق على الصفقات'));
  if (tbl.isNotEmpty && u.won + u.drawn + u.lost > 0) {
    final lead = tbl.first;
    if (lead == u) {
      out.add(('🔝', '${u.name} يتصدر الدوري'));
    } else {
      out.add(('🔝', '${lead.name} يتصدر الدوري بفارق ${lead.points - u.points} نقاط عن ${u.name}'));
    }
  }
  final f = gs.formOf(u, 8);
  var w = 0, l = 0, unb = 0;
  for (final r in f.reversed) {
    if (r == 'W') {
      w++;
    } else {
      break;
    }
  }
  for (final r in f.reversed) {
    if (r == 'L') {
      l++;
    } else {
      break;
    }
  }
  for (final r in f.reversed) {
    if (r != 'L') {
      unb++;
    } else {
      break;
    }
  }
  if (w >= 3) {
    out.add(('🔥', 'سلسلة $w انتصارات متتالية لـ${u.name}'));
  } else if (unb >= 5) {
    out.add(('🛡️', '${u.name} لم يخسر في آخر $unb مباريات'));
  }
  if (l >= 3) out.add(('⚠️', 'أزمة: $l هزائم متتالية و${u.name} تحت الضغط'));
  if (u.won + u.drawn + u.lost >= 6 && tbl.length >= 8 && pos > tbl.length - 3) {
    out.add(('🔻', '${u.name} في دائرة الهبوط'));
  }
  final scorers = [...u.squad]..sort((a, b) => b.goals.compareTo(a.goals));
  if (scorers.isNotEmpty && scorers.first.goals >= 5) {
    out.add(('⚽', '${scorers.first.name} يتألق: ${scorers.first.goals} أهداف هذا الموسم'));
  }
  final inj = u.squad.where((p) => p.injuredWeeks > 0).length;
  if (inj >= 3) out.add(('🚑', 'قائمة المصابين تطول: $inj لاعبين خارج الخدمة'));
  if (gs.confidence <= 25) {
    out.add(('🏛️', 'الإدارة تفقد صبرها مع المدرب'));
  } else if (gs.confidence >= 85) {
    out.add(('🏛️', 'ثقة كبيرة من الإدارة بالمدرب بعد النتائج الأخيرة'));
  }
  final major = RegExp(r'^(📨|✍️|⚡|🔥|🏆|👋|📰)');
  for (final n in gs.news.take(12)) {
    if (out.length >= 9) break;
    if (major.hasMatch(n)) out.add((n.characters.first, n.replaceFirst(RegExp(r'^\S+\s*'), '')));
  }
  return out.take(9).toList();
}

/// شريط عاجل يبدّل العناوين كل بضع ثوانٍ، والضغط يفتح القائمة كاملة
class HeadlineTicker extends StatefulWidget {
  final GameState gs;
  const HeadlineTicker({super.key, required this.gs});

  @override
  State<HeadlineTicker> createState() => _HeadlineTickerState();
}

class _HeadlineTickerState extends State<HeadlineTicker> {
  Timer? _t;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hs = headlinesOf(widget.gs);
    if (hs.isEmpty) return const SizedBox.shrink();
    final h = hs[_i % hs.length];
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), shrinkWrap: true, children: [
            const Text('📰 آخر العناوين', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 10),
            for (final x in hs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(x.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(x.$2, style: const TextStyle(fontSize: 14, height: 1.4))),
                ]),
              ),
          ]),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            color: const Color(0xFFE5533D),
            child: const Text('عاجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                key: ValueKey('${_i % hs.length}-${h.$2}'),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('${h.$1} ${h.$2}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.keyboard_arrow_down_rounded, color: kMuted, size: 20)),
        ]),
      ),
    );
  }
}
