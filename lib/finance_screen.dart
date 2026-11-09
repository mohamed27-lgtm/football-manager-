import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'finance.dart';
import 'game_state.dart';
import 'widgets.dart';

class FinanceScreen extends StatelessWidget {
  final GameState gs;
  const FinanceScreen({super.key, required this.gs});

  void _snack(BuildContext c, String? err, String ok) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err ?? ok)));

  Widget _kv(String k, String v, {Color? color}) => Column(children: [
        Text(v, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(k, style: const TextStyle(color: kMuted, fontSize: 11)),
      ]);

  Widget _breakdown(String title, List<String> keys, Map<String, double> data, Color color) {
    final rows = <(String, double)>[
      for (final k in keys)
        if ((data[k] ?? 0) > 0.0001) (k, data[k]!)
    ];
    final mx = rows.fold(0.0, (a, r) => r.$2 > a ? r.$2 : a);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Text('لا بيانات بعد — ستظهر بعد أول مباراة', style: TextStyle(color: kMuted, fontSize: 13))
        else
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 96, child: Text(Finance.labels[r.$1] ?? r.$1, style: const TextStyle(fontSize: 13))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: mx == 0 ? 0 : r.$2 / mx,
                      minHeight: 8,
                      color: color,
                      backgroundColor: kCard2,
                    ),
                  ),
                ),
                SizedBox(
                  width: 62,
                  child: Text(money(r.$2), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),
            ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('💰 المركز المالي')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final u = gs.user;
            final f = gs.fin;
            final net = f.totalIncome - f.totalExpense;
            final weeklyCost = gs.weeklyWages + 0.03 * (u.stadium + u.trainingLvl + u.academy);
            final runway = u.budget > 0 && weeklyCost > 0 ? (u.budget / weeklyCost).floor() : 0;
            return ListView(padding: const EdgeInsets.all(14), children: [
              Panel(
                child: Column(children: [
                  const Text('الرصيد الحالي', style: TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(money(u.budget),
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: u.budget < 0 ? const Color(0xFFFF7043) : kAccent)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _kv('قيمة التشكيلة', money(gs.squadValue)),
                    _kv('الرواتب/أسبوع', money(gs.weeklyWages)),
                    _kv('الديون', money(f.debt), color: f.debt > 0 ? const Color(0xFFFFCA28) : null),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    u.budget < 0
                        ? '⚠️ الرصيد سالب: الإدارة تفقد ثقتها بك كل أسبوع.'
                        : 'يكفي لتغطية الرواتب والصيانة نحو $runway أسبوعاً بدون إيرادات.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ]),
              ),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('تطوّر الرصيد', style: TextStyle(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('صافي الموسم: ${net >= 0 ? '+' : ''}${net.toStringAsFixed(1)}M',
                        style: TextStyle(fontWeight: FontWeight.w700, color: net >= 0 ? kAccent : const Color(0xFFFF7043))),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: f.history.length < 2
                        ? const Center(child: Text('سيظهر المنحنى بعد مباراتين', style: TextStyle(color: kMuted, fontSize: 13)))
                        : CustomPaint(painter: _LinePainter(f.history)),
                  ),
                ]),
              ),
              _breakdown('الإيرادات (${money(f.totalIncome)})', Finance.incomeKeys, f.season, kAccent),
              _breakdown('المصاريف (${money(f.totalExpense)})', Finance.expenseKeys, f.season, const Color(0xFFFF7043)),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('🏦 القروض', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('الدين الحالي ${money(f.debt)} من أصل سقف ${GameState.maxDebt.toStringAsFixed(0)}M • فائدة أسبوعية 0.4%',
                      style: const TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton(onPressed: () => _snack(context, gs.takeLoan(5), 'تم اقتراض 5.0M'), child: const Text('اقتراض 5M')),
                    FilledButton(onPressed: () => _snack(context, gs.takeLoan(10), 'تم اقتراض 10.0M'), child: const Text('اقتراض 10M')),
                    OutlinedButton(onPressed: () => _snack(context, gs.repay(5), 'تم سداد 5.0M'), child: const Text('سداد 5M')),
                    OutlinedButton(onPressed: () => _snack(context, gs.repay(f.debt), 'تم سداد كل الديون'), child: const Text('سداد الكل')),
                  ]),
                ]),
              ),
            ]);
          },
        ),
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
