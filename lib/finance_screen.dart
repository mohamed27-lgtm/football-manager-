import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'calendar.dart';
import 'finance_ledger.dart';
import 'i18n.dart';
import 'finance.dart';
import 'game_state.dart';
import 'widgets.dart';
import 'business_screens.dart';
import 'lineup_pages.dart';
import 'match_pages.dart';

class FinanceScreen extends StatefulWidget {
  final GameState gs;
  const FinanceScreen({super.key, required this.gs});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int tab = 0;
  GameState get gs => widget.gs;

  void _snack(BuildContext c, String? err, String ok) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err ?? ok)));

  Widget _tile(String v, String l, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: c)),
            Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      );

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: child,
      );

  Widget _bars(List<String> keys, Map<String, double> data, Color color) {
    final rows = <(String, double)>[
      for (final k in keys)
        if ((data[k] ?? 0) > 0.0001) (k, data[k]!)
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final mx = rows.fold(0.0, (a, r) => r.$2 > a ? r.$2 : a);
    if (rows.isEmpty) return const Text('لا بيانات بعد — ستظهر بعد أول مباراة', style: TextStyle(color: kMuted, fontSize: 13));
    return Column(children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(children: [
            Row(children: [
              Text(Finance.labels[r.$1] ?? r.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              const Spacer(),
              Text(money(r.$2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
            ]),
            const SizedBox(height: 5),
            ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: mx == 0 ? 0 : r.$2 / mx, minHeight: 7, color: color, backgroundColor: kCard2)),
          ]),
        ),
    ]);
  }

  Widget _chart(List<double> h) {
    final d = <double>[];
    for (var i = 1; i < h.length; i++) {
      d.add(h[i] - h[i - 1]);
    }
    final last = d.length > 6 ? d.sublist(d.length - 6) : d;
    if (last.isEmpty) return const SizedBox(height: 90, child: Center(child: Text('سيظهر الرسم بعد أول مباراة', style: TextStyle(color: kMuted, fontSize: 13))));
    final mx = last.fold(0.1, (a, v) => v.abs() > a ? v.abs() : a);
    return SizedBox(
      height: 110,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final v in last)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: kMuted)),
                const SizedBox(height: 2),
                Container(height: 8 + 70 * v.abs() / mx, decoration: BoxDecoration(color: v >= 0 ? const Color(0xFF1FA58A) : const Color(0xFFE5533D), borderRadius: BorderRadius.circular(4))),
              ]),
            ),
          ),
      ]),
    );
  }

  int _gk(Tx t) => switch (tab) {
        2 => t.season * 100 + t.week,
        1 => t.date.year * 12 + t.date.month,
        _ => t.season,
      };

  /// معاملات الفترة الحالية (الأحدث) والسابقة لها
  (List<Tx>, List<Tx>) _periods(List<Tx> all) {
    if (all.isEmpty) return (<Tx>[], <Tx>[]);
    final cur = _gk(all.first);
    int? prev;
    for (final t in all) {
      if (_gk(t) != cur) {
        prev = _gk(t);
        break;
      }
    }
    return ([for (final t in all) if (_gk(t) == cur) t], [for (final t in all) if (prev != null && _gk(t) == prev) t]);
  }

  double _inc(List<Tx> l) => l.where((t) => t.income).fold(0.0, (a, t) => a + t.amt);
  double _exp(List<Tx> l) => l.where((t) => !t.income).fold(0.0, (a, t) => a - t.amt);

  Widget _flow(String label, double v, double prev, bool income) {
    final col = income ? const Color(0xFF1FA58A) : const Color(0xFFE5533D);
    final pct = prev > 0 ? ((v - prev) / prev * 100).round() : null;
    final good = pct == null ? true : (income ? pct >= 0 : pct <= 0);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(income ? Icons.north_rounded : Icons.south_rounded, size: 15, color: col)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: kMuted, fontSize: 12.5)),
          ]),
          const SizedBox(height: 8),
          Text(amtText(v, sign: false), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(pct == null ? 'لا مقارنة بعد' : '${pct >= 0 ? '+' : ''}$pct% عن الفترة السابقة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: pct == null ? kMuted : (good ? const Color(0xFF1FA58A) : const Color(0xFFE5533D)))),
        ]),
      ),
    );
  }

  static const _grp = <String, (String, Color)>{
    'wages': ('الأجور', Color(0xFF2F7BE6)),
    'staff': ('الأجور', Color(0xFF2F7BE6)),
    'purchases': ('الانتقالات', Color(0xFFF0583A)),
    'loanin': ('الانتقالات', Color(0xFFF0583A)),
    'renewals': ('الانتقالات', Color(0xFFF0583A)),
    'severance': ('الانتقالات', Color(0xFFF0583A)),
    'agents': ('الانتقالات', Color(0xFFF0583A)),
    'maintenance': ('المرافق والصيانة', Color(0xFF1FA58A)),
    'upgrades': ('المرافق والصيانة', Color(0xFF1FA58A)),
  };

  Widget _donut(List<Tx> cur) {
    final by = <String, double>{};
    final colors = <String, Color>{};
    for (final t in cur.where((t) => !t.income)) {
      final g = _grp[t.key] ?? ('أخرى', const Color(0xFF9AA3B5));
      by[g.$1] = (by[g.$1] ?? 0) - t.amt;
      colors[g.$1] = g.$2;
    }
    final total = by.values.fold(0.0, (a, v) => a + v);
    final rows = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('أين ذهب المصروف؟', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      const SizedBox(height: 10),
      if (total <= 0)
        const Text('لا مصروفات في هذه الفترة', style: TextStyle(color: kMuted, fontSize: 13))
      else
        Row(children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _DonutPainter([for (final e in rows) (e.value / total, colors[e.key]!)], kLine),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(amtText(total, sign: false), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), const Text('المجموع', style: TextStyle(color: kMuted, fontSize: 10.5))])),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(children: [
              for (final e in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key], borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const Spacer(),
                    Text('${(e.value / total * 100).round()}%  ${amtText(e.value, sign: false)}', style: const TextStyle(color: kMuted, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
          ),
        ]),
    ]));
  }

  Widget _forecast(List<Tx> all) {
    final cur = all.where((t) => t.season == gs.season).toList();
    final weeks = {for (final t in cur) t.week}.length;
    if (weeks == 0) return const SizedBox.shrink();
    final net = cur.fold(0.0, (a, t) => a + t.amt) / weeks;
    final left = max(0, gs.rounds.length - gs.week);
    final proj = gs.user.budget + net * left;
    final delta = net * left;
    final good = delta >= 0;
    final col = good ? const Color(0xFF1FA58A) : const Color(0xFFE5533D);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10)), child: Text(amtText(delta), style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: 13))),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('توقّع نهاية الموسم', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
          Text('رصيد متوقع ${amtText(proj, sign: false)} إن استمر الأداء', style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(width: 10),
        Icon(Icons.insights_rounded, color: col),
      ]),
    );
  }

  Widget _hero(GameState gs) {
    final u = gs.user;
    final h = gs.fin.history;
    final mo = h.length >= 5 ? h.last - h[h.length - 5] : (h.length >= 2 ? h.last - h.first : 0.0);
    return Unfilter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${amtText(mo)} آخر 4 جولات', style: TextStyle(color: mo >= 0 ? const Color(0xFF3DD6B0) : const Color(0xFFFF8A75), fontWeight: FontWeight.w900, fontSize: 12.5)),
            const Spacer(),
            const Text('الرصيد الحالي', style: TextStyle(color: Color(0xFFB8C4DE), fontSize: 12.5)),
          ]),
          Align(alignment: Alignment.centerRight, child: Text(amtText(u.budget, sign: false), style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: u.budget < 0 ? const Color(0xFFFF8A75) : const Color(0xFFFFFFFF)))),
          const SizedBox(height: 8),
          SizedBox(height: 86, width: double.infinity, child: CustomPaint(painter: _AreaPainter(h.length > 30 ? h.sublist(h.length - 30) : h))),
        ]),
      ),
    );
  }

  String _csv() {
    final b = StringBuffer('الموسم,الجولة,التاريخ,البند,المبلغ (M),الرصيد بعد (M),ملاحظة\n');
    for (final t in txList(gs).reversed) {
      b.writeln('${t.season},${t.week + 1},${GameCalendar.fmtShort(t.date)},${t.title},${t.amt.toStringAsFixed(3)},${t.after.toStringAsFixed(3)},${t.note}');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameBar(context, gs, 'المالية'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(children: [
            Expanded(
                flex: 2,
                child: blueBtn('تصدير', () async {
                  await Clipboard.setData(ClipboardData(text: _csv()));
                  if (context.mounted) _snack(context, null, 'نُسخ السجل المالي (CSV) إلى الحافظة');
                }, icon: Icons.download_rounded)),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: GradientButton(label: 'دفتر المعاملات', icon: Icons.list_alt_rounded, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LedgerScreen(gs: gs))))),
          ]),
        ),
      ),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final f = gs.fin;
          final all = txList(gs);
          final (cur, prev) = _periods(all);
          return ListView(padding: const EdgeInsets.all(14), children: [
            Container(
              height: 44,
              decoration: BoxDecoration(border: Border.all(color: kPrimary), borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias,
              child: Row(children: [
                for (final e in const ['موسم', 'شهر', 'أسبوع'].indexed)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => tab = e.$1),
                      child: Container(alignment: Alignment.center, color: tab == e.$1 ? kPrimary : Colors.transparent, child: Text(e.$2, style: TextStyle(fontWeight: FontWeight.w900, color: tab == e.$1 ? Colors.white : kPrimary))),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            _hero(gs),
            const SizedBox(height: 12),
            Row(children: [
              _flow('المصروف', _exp(cur), _exp(prev), false),
              _flow('الدخل', _inc(cur), _inc(prev), true),
            ]),
            const SizedBox(height: 12),
            _donut(cur),
            _forecast(all),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الإيرادات (${money(f.totalIncome)})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              _bars(Finance.incomeKeys, f.season, const Color(0xFF1FA58A)),
            ])),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('المصاريف (${money(f.totalExpense)})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              _bars(Finance.expenseKeys, f.season, const Color(0xFFE5533D)),
              const SizedBox(height: 8),
              Text('الرواتب الأسبوعية ${money(gs.weeklyWages)} • قيمة التشكيلة ${money(gs.squadValue)}', style: const TextStyle(color: kMuted, fontSize: 12)),
            ])),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('القروض', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              Text('الدين الحالي ${money(f.debt)} من سقف ${GameState.maxDebt.toStringAsFixed(0)}M • فائدة أسبوعية 0.4%', style: const TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton(onPressed: () => _snack(context, gs.takeLoan(5), 'تم اقتراض 5.0M'), child: const Text('اقتراض 5M')),
                FilledButton(onPressed: () => _snack(context, gs.takeLoan(10), 'تم اقتراض 10.0M'), child: const Text('اقتراض 10M')),
                OutlinedButton(onPressed: () => _snack(context, gs.repay(5), 'تم سداد 5.0M'), child: const Text('سداد 5M')),
                OutlinedButton(onPressed: () => _snack(context, gs.repay(f.debt), 'تم سداد كل الديون'), child: const Text('سداد الكل')),
              ]),
            ])),
            blueBtn('الرعاة', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SponsorsScreen(gs: gs))), icon: Icons.star_border_rounded),
            const SizedBox(height: 12),
          ]);
        },
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> parts;
  final Color bg;
  _DonutPainter(this.parts, this.bg);
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(10, 10, s.width - 20, s.height - 20);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..color = bg;
    c.drawArc(r, 0, 2 * pi, false, base);
    var a = -pi / 2;
    for (final p in parts) {
      final sw = 2 * pi * p.$1;
      c.drawArc(
          r,
          a,
          max(0.0, sw - 0.04),
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 16
            ..strokeCap = StrokeCap.butt
            ..color = p.$2);
      a += sw;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

class _AreaPainter extends CustomPainter {
  final List<double> v;
  _AreaPainter(this.v);
  @override
  void paint(Canvas c, Size s) {
    if (v.length < 2) return;
    var lo = v.reduce(min), hi = v.reduce(max);
    if (hi - lo < 0.5) {
      hi += 0.5;
      lo -= 0.5;
    }
    double x(int i) => s.width * i / (v.length - 1);
    double y(double val) => s.height * 0.92 - (val - lo) / (hi - lo) * s.height * 0.8;
    final line = Path()..moveTo(x(0), y(v[0]));
    for (var i = 1; i < v.length; i++) {
      line.lineTo(x(i), y(v[i]));
    }
    final fill = Path.from(line)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(fill, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x553DD6B0), Color(0x003DD6B0)]).createShader(Offset.zero & s));
    c.drawPath(
        line,
        Paint()
          ..color = const Color(0xFF3DD6B0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);
    c.drawCircle(Offset(x(v.length - 1), y(v.last)), 4.5, Paint()..color = const Color(0xFF3DD6B0));
  }

  @override
  bool shouldRepaint(covariant _AreaPainter old) => true;
}

class _LinePainter extends CustomPainter {
  final List<double> v;
  _LinePainter(this.v);

  @override
  void paint(Canvas c, Size s) {
    if (v.length < 2) return;
    var lo = v.reduce(min);
    var hi = v.reduce(max);
    if (hi - lo < 1) {
      hi += 1;
      lo -= 1;
    }
    double x(int i) => s.width * i / (v.length - 1);
    double y(double val) => s.height * 0.93 - (val - lo) / (hi - lo) * s.height * 0.86;

    if (lo < 0 && hi > 0) {
      c.drawLine(
        Offset(0, y(0)),
        Offset(s.width, y(0)),
        Paint()
          ..color = const Color(0x66FF7043)
          ..strokeWidth = 1,
      );
    }
    final path = Path()..moveTo(x(0), y(v[0]));
    for (var i = 1; i < v.length; i++) {
      path.lineTo(x(i), y(v[i]));
    }
    c.drawPath(
      path,
      Paint()
        ..color = kAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawCircle(Offset(x(v.length - 1), y(v.last)), 4, Paint()..color = kAccent);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
