import 'dart:math';
import 'package:flutter/material.dart' hide Text;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameBar(context, gs, 'المالية'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(children: [
            Expanded(flex: 2, child: blueBtn('الرعاة', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SponsorsScreen(gs: gs))), icon: Icons.star_border_rounded)),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: GradientButton(label: 'الميزانية', icon: Icons.account_balance_wallet_outlined, onPressed: () => setState(() => tab = 2))),
          ]),
        ),
      ),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final u = gs.user;
          final f = gs.fin;
          final played = gs.week.clamp(1, 99).toInt();
          final net = f.totalIncome - f.totalExpense;
          return ListView(padding: const EdgeInsets.all(14), children: [
            Container(
              height: 44,
              decoration: BoxDecoration(border: Border.all(color: kPrimary), borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias,
              child: Row(children: [
                for (final e in const ['نظرة عامة', 'الدخل', 'المصروفات'].indexed)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => tab = e.$1),
                      child: Container(alignment: Alignment.center, color: tab == e.$1 ? kPrimary : Colors.transparent, child: Text(e.$2, style: TextStyle(fontWeight: FontWeight.w900, color: tab == e.$1 ? Colors.white : kPrimary))),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            if (tab == 0) ...[
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('الرصيد الحالي', style: TextStyle(color: kMuted, fontSize: 12.5)),
                Text(money(u.budget), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: u.budget < 0 ? const Color(0xFFE5533D) : null)),
                const SizedBox(height: 10),
                Row(children: [
                  _tile('${(f.totalExpense / played).toStringAsFixed(1)}M', 'المصاريف/جولة', const Color(0xFFE5533D)),
                  _tile('${(f.totalIncome / played).toStringAsFixed(1)}M', 'الدخل/جولة', const Color(0xFF1FA58A)),
                ]),
              ])),
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('آخر 6 جولات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const Spacer(),
                  Text('صافي الموسم ${net >= 0 ? '+' : ''}${net.toStringAsFixed(1)}M', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: net >= 0 ? const Color(0xFF1FA58A) : const Color(0xFFE5533D))),
                ]),
                const SizedBox(height: 10),
                _chart(f.history),
              ])),
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('المصاريف حسب البند', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                _bars(Finance.expenseKeys, f.season, const Color(0xFF2F7BE6)),
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
            ],
            if (tab == 1) _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الإيرادات (${money(f.totalIncome)})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              _bars(Finance.incomeKeys, f.season, const Color(0xFF1FA58A)),
            ])),
            if (tab == 2) _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('المصاريف (${money(f.totalExpense)})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              _bars(Finance.expenseKeys, f.season, const Color(0xFFE5533D)),
              const SizedBox(height: 8),
              Text('الرواتب الأسبوعية ${money(gs.weeklyWages)} • قيمة التشكيلة ${money(gs.squadValue)}', style: const TextStyle(color: kMuted, fontSize: 12)),
            ])),
          ]);
        },
      ),
    );
  }
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
