import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'calendar.dart';
import 'widgets.dart';
import 'club_ui.dart';
import 'match_pages.dart';
import 'lineup_pages.dart';

const _standColors = [Color(0xFF6A6FC4), Color(0xFFA9D4F8), Color(0xFFF5A524), Color(0xFFE5533D)];
String _n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

/// التذاكر: مباراة واحدة (أسعار لكل مدرج) وبطاقات الموسم
class TicketsScreen extends StatefulWidget {
  final GameState gs;
  final int initialTab; // 0 مباراة واحدة، 1 بطاقات الموسم
  const TicketsScreen({super.key, required this.gs, this.initialTab = 0});
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  GameState get gs => widget.gs;
  late int tab = widget.initialTab;
  late List<double> draft = List.of(gs.standMult);

  /// توقّع بالأسعار المسوّدة دون تغيير الحالة
  TicketForecast _fc({double g = 1.0}) {
    final keep = List.of(gs.standMult);
    for (var i = 0; i < 4; i++) {
      gs.standMult[i] = draft[i];
    }
    final t = gs.ticketForecast(oppRep: gs.nextOppRep, globalMult: g);
    for (var i = 0; i < 4; i++) {
      gs.standMult[i] = keep[i];
    }
    return t;
  }

  bool get _dirty {
    for (var i = 0; i < 4; i++) {
      if ((draft[i] - gs.standMult[i]).abs() > 0.001) return true;
    }
    return false;
  }

  void _step(int s, int dir) {
    final ref = gs.refPrice(s);
    final cur = (ref * draft[s]).roundToDouble();
    final stp = ref >= 150 ? 10.0 : 5.0;
    final np = (cur + dir * stp).clamp(ref * 0.4, ref * 2.5).toDouble();
    setState(() => draft[s] = np / ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameBar(context, gs, tab == 0 ? 'التذاكر' : 'بطاقات الموسم'),
      bottomNavigationBar: tab == 0 ? _bottom() : null,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
            Container(
              height: 46,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(border: Border.all(color: kPrimary), borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Row(children: [
                for (final e in const ['بطاقات الموسم', 'مباراة واحدة'].indexed)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => tab = e.$1 == 0 ? 1 : 0),
                      child: Container(alignment: Alignment.center, color: (e.$1 == 0 ? tab == 1 : tab == 0) ? kPrimary : Colors.transparent, child: Text(e.$2, style: TextStyle(fontWeight: FontWeight.w900, color: (e.$1 == 0 ? tab == 1 : tab == 0) ? Colors.white : kPrimary))),
                    ),
                  ),
              ]),
            ),
            if (tab == 0) ..._single() else ..._season(),
          ]),
        ),
      ),
    );
  }

  // ───────────── مباراة واحدة ─────────────
  List<Widget> _single() {
    final f = gs.nextHomeFixture;
    final opp = f == null ? null : gs.team(f.away);
    final sug = gs.suggestedMults(oppRep: gs.nextOppRep);
    final tf = _fc();
    final fm = gs.formOf(gs.user, 5);
    final wins = fm.where((e) => e == 'W').length, loses = fm.where((e) => e == 'L').length;
    final oppRep = gs.nextOppRep;
    final slot = f == null ? null : GameCalendar.dateOf(gs.season, gs.nextHomeWeek, 5);
    Widget chip(String text, bool good) => Container(
          margin: const EdgeInsetsDirectional.only(end: 6, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: (good ? const Color(0xFF1FA58A) : const Color(0xFFE5533D)).withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(good ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: good ? const Color(0xFF1FA58A) : const Color(0xFFE5533D)),
            const SizedBox(width: 3),
            Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: good ? const Color(0xFF1FA58A) : const Color(0xFFE5533D))),
          ]),
        );
    return [
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(opp == null ? 'لا مباراة قادمة على أرضك' : '${gs.user.name} ضد ${opp.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
          ]),
          if (slot != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(GameCalendar.fmt(slot), style: const TextStyle(color: kMuted, fontSize: 12))),
          const SizedBox(height: 10),
          Wrap(children: [
            if (oppRep >= 4) chip('خصم قوي', true) else if (oppRep <= 2) chip('خصم ضعيف', false),
            if (wins - loses >= 2) chip('شكل الفريق', true) else if (loses - wins >= 2) chip('شكل الفريق', false),
            if (gs.fans >= 65) chip('شعبية عالية', true) else if (gs.fans < 40) chip('شعبية منخفضة', false),
            if (gs.stadiumBuilding) chip('أشغال بالملعب', false),
          ]),
        ]),
      ),
      _curve(),
      CardBox(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var s = 3; s >= 0; s--) ...[
            if (s < 3) const Divider(height: 1, color: kLine),
            _standRow(s, tf.stands[s], sug[s]),
          ],
        ]),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: Text('النسبة هي امتلاء المدرج المتوقع. الأسعار الأعلى ترفع الإيراد حتى نقطة ثم يهرب الجمهور، وترفع/تخفض رضا الجماهير مع الوقت. الأرقام تقدير للمحاكاة.', style: TextStyle(color: kMuted, fontSize: 12, height: 1.5)),
      ),
    ];
  }

  Widget _standRow(int s, StandRow r, double sug) {
    final price = (gs.refPrice(s) * draft[s]).roundToDouble();
    final pc = r.fill >= 0.85 ? const Color(0xFF1FA58A) : (r.fill >= 0.6 ? const Color(0xFFF5A524) : const Color(0xFFE5533D));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: _standColors[s], borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kStandNames[s], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            Text('${_n(r.cap)} مقعد${r.subs > 0 ? ' • ${_n(r.subs)} اشتراك' : ''}', style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
        _sq(Icons.remove_rounded, () => _step(s, -1), false),
        SizedBox(width: 66, child: Center(child: Text('\$${price.round()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
        _sq(Icons.add_rounded, () => _step(s, 1), true),
        SizedBox(width: 50, child: Text('${(r.fill * 100).round()}%', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: pc))),
      ]),
    );
  }

  Widget _sq(IconData i, VoidCallback on, bool primary) => GestureDetector(
        onTap: on,
        child: Container(width: 38, height: 38, decoration: BoxDecoration(color: primary ? kPrimary : const Color(0xFFA9D4F8), borderRadius: BorderRadius.circular(10)), child: Icon(i, color: primary ? Colors.white : const Color(0xFF15233D), size: 22)),
      );

  Widget _curve() {
    final pts = [for (final m in List.generate(27, (i) => 0.5 + 0.05 * i)) (m, _fc(g: m).revenue)];
    var bi = 0;
    for (var i = 0; i < pts.length; i++) {
      if (pts[i].$2 > pts[bi].$2) bi = i;
    }
    final curI = pts.indexWhere((p) => (p.$1 - 1.0).abs() < 0.001);
    final t1 = _fc();
    final avg = t1.attendance == 0 ? 0.0 : t1.stands.fold<double>(0, (a, r) => a + r.price * (r.att - r.subs)) / max(1, t1.attendance - t1.subs);
    final bestPrice = avg * pts[bi].$1;
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('الإيراد مقابل متوسط السعر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const Spacer(),
          Text('الأمثل \$${bestPrice.round()}', style: const TextStyle(color: Color(0xFF1FA58A), fontWeight: FontWeight.w900, fontSize: 12.5)),
        ]),
        const SizedBox(height: 8),
        SizedBox(height: 130, width: double.infinity, child: CustomPaint(painter: _CurvePainter([for (final p in pts) p.$2], bi, curI))),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final i in [0, 7, 13, 20, 26]) Text('\$${(avg * pts[i].$1).round()}', style: const TextStyle(color: kMuted, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _bottom() {
    final t = _fc();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        decoration: const BoxDecoration(color: kCard, border: Border(top: BorderSide(color: kLine))),
        child: Row(children: [
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الحضور المتوقع • ${_n(t.attendance)}', style: const TextStyle(color: kMuted, fontSize: 12)),
              Text(money(t.revenue), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1FA58A))),
            ]),
          ),
          SizedBox(
            width: 104,
            child: blueBtn('المقترح', () {
              final m = gs.suggestedMults(oppRep: gs.nextOppRep);
              setState(() {
                for (var i = 0; i < 4; i++) {
                  draft[i] = m[i];
                }
              });
            }),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: GradientButton(
              label: _dirty ? 'حفظ' : 'محفوظ',
              onPressed: () {
                for (var i = 0; i < 4; i++) {
                  gs.standMult[i] = draft[i];
                }
                gs.setStandPrice(0, gs.refPrice(0) * draft[0]);
                snack(context, 'حُفظت أسعار التذاكر');
                setState(() {});
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ───────────── بطاقات الموسم ─────────────
  List<Widget> _season() {
    final t = gs.ticketForecast(oppRep: gs.nextOppRep);
    final subs = t.subs;
    return [
      StatTiles([
        ('${(gs.renewalRate * 100).round()}%', 'معدل التجديد', const Color(0xFF2F7BE6)),
        (money(t.seasonRev * kHomeMatches), 'إيراد الموسم', const Color(0xFF1FA58A)),
        (_n(subs), 'مشتركون', kPrimary),
      ]),
      CardBox(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('الأسعار الديناميكية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 2),
              const Text('تُعدَّل أسعار التذاكر المنفردة تلقائياً حسب الطلب', style: TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          Switch(value: gs.dynPricing, onChanged: (v) {
            gs.dynPricing = v;
            gs.setSeasonMult(gs.seasonMult);
          }),
        ]),
      ),
      CardBox(
        child: Row(children: [
          _sq(Icons.remove_rounded, () => gs.setSeasonMult(gs.seasonMult - 0.05), false),
          Expanded(child: Column(children: [const Text('مستوى أسعار البطاقات', style: TextStyle(color: kMuted, fontSize: 12)), Text('×${gs.seasonMult.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))])),
          _sq(Icons.add_rounded, () => gs.setSeasonMult(gs.seasonMult + 0.05), true),
        ]),
      ),
      for (final tier in kSeasonTiers.indexed) _tier(tier.$2, t),
      const Padding(
        padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: Text('رفع سعر البطاقات يزيد الإيراد لكن يقلل المشتركين ومعدل التجديد. تُجدَّد الأرقام عند بداية كل موسم.', style: TextStyle(color: kMuted, fontSize: 12, height: 1.5)),
      ),
    ];
  }

  Widget _tier((String, int, double, double) tier, TicketForecast t) {
    final s = tier.$2;
    final row = t.stands[s];
    final col = _standColors[s];
    final names = {'ذهبية': 'مقعد VIP • لقاء اللاعبين', 'فضية': 'الشرفة • خصم المتجر 10%', 'عادية': 'المدرج الشعبي'};
    return CardBox(
      child: Column(children: [
        Row(children: [
          IconBox(Icons.confirmation_number_outlined, col, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tier.$1, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              Text(names[tier.$1] ?? '', style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${_n(gs.seasonPrice(tier).round())}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const Text('للموسم', style: TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 10),
        Bar(row.cap == 0 ? 0 : row.subs / row.cap, col),
        const SizedBox(height: 6),
        Row(children: [
          Text('${_n(row.subs)} / ${_n(row.cap)}', style: const TextStyle(color: kMuted, fontSize: 12)),
          const Spacer(),
          Text('تجديد ${(gs.renewalRate * 100 + (tier.$1 == 'ذهبية' ? 3 : (tier.$1 == 'عادية' ? -4 : 0))).clamp(0, 99).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1FA58A))),
        ]),
      ]),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<double> v;
  final int best, cur;
  _CurvePainter(this.v, this.best, this.cur);
  @override
  void paint(Canvas c, Size s) {
    final mx = v.reduce((a, b) => a > b ? a : b), mn = v.reduce((a, b) => a < b ? a : b);
    final span = (mx - mn) == 0 ? 1.0 : (mx - mn);
    Offset p(int i) => Offset(s.width * i / (v.length - 1), s.height - 14 - (s.height - 34) * (v[i] - mn) / span);
    final path = Path()..moveTo(p(0).dx, s.height);
    for (var i = 0; i < v.length; i++) {
      path.lineTo(p(i).dx, p(i).dy);
    }
    path.lineTo(s.width, s.height);
    path.close();
    c.drawPath(path, Paint()..color = kPrimary.withOpacity(0.12));
    final line = Path()..moveTo(p(0).dx, p(0).dy);
    for (var i = 1; i < v.length; i++) {
      line.lineTo(p(i).dx, p(i).dy);
    }
    c.drawPath(line, Paint()..color = kPrimary..style = PaintingStyle.stroke..strokeWidth = 3..strokeJoin = StrokeJoin.round);
    final g = const Color(0xFF1FA58A);
    final bp = p(best);
    var y = 0.0;
    while (y < s.height) {
      c.drawLine(Offset(bp.dx, y), Offset(bp.dx, y + 4), Paint()..color = g..strokeWidth = 1.5);
      y += 8;
    }
    c.drawCircle(bp, 6, Paint()..color = g);
    if (cur >= 0) {
      final cp = p(cur);
      c.drawCircle(cp, 6, Paint()..color = Colors.white);
      c.drawCircle(cp, 6, Paint()..color = kPrimary..style = PaintingStyle.stroke..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter o) => true;
}
