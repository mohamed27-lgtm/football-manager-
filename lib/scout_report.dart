import 'package:flutter/material.dart' hide Text;
import 'game_state.dart';
import 'i18n.dart';
import 'models.dart';
import 'widgets.dart';

/// تقرير الكشّاف قبل المباراة: قوة الخصم وأسلوبه ونجمه ونصائح تكتيكية
class ScoutCard extends StatelessWidget {
  final GameState gs;
  const ScoutCard({super.key, required this.gs});

  static const _ment = ['دفاعي', 'حذر', 'متوازن', 'هجومي', 'هجوم شامل'];

  double _line(Team t, Pos p, int k) {
    final xs = t.squad.where((x) => x.pos == p && x.available).map((x) => x.overall).toList()..sort((a, b) => b.compareTo(a));
    if (xs.isEmpty) return 30;
    return xs.take(k).reduce((a, b) => a + b) / (xs.length < k ? xs.length : k);
  }

  @override
  Widget build(BuildContext context) {
    final f = gs.userFixture;
    if (f == null || gs.fired || gs.seasonOver) return const SizedBox.shrink();
    Team opp;
    try {
      opp = gs.team(f.home == gs.user.id ? f.away : f.home);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final me = gs.user;
    final diff = opp.strength - me.strength;
    final verdict = diff > 4 ? 'خصم أقوى منك' : diff < -4 ? 'أنت الأقوى على الورق' : 'مباراة متكافئة';
    final lines = {Pos.gk: _line(opp, Pos.gk, 1), Pos.def: _line(opp, Pos.def, 4), Pos.mid: _line(opp, Pos.mid, 3), Pos.att: _line(opp, Pos.att, 3)};
    const names = {Pos.gk: 'حراسة المرمى', Pos.def: 'الدفاع', Pos.mid: 'الوسط', Pos.att: 'الهجوم'};
    final sorted = lines.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final weak = sorted.first.key, strong = sorted.last.key;
    final star = ([...opp.squad]..sort((a, b) => b.overall.compareTo(a.overall))).first;
    final tips = <String>[
      if (opp.defLine >= 2) 'يرفعون خط الدفاع: الكرات خلف المدافعين والسرعة سلاحك.',
      if (opp.pressing >= 2) 'يضغطون عالياً: تمريرات قصيرة سريعة أو تجاوز الضغط بكرات طويلة.',
      if (opp.mentality <= 1) 'يلعبون دفاعياً: اصبر ووسّع اللعب على الأطراف.',
      if (opp.mentality >= 3) 'هجومهم مفتوح: الضربات المرتدة فرصتك.',
      if (weak == Pos.def) 'دفاعهم هو الحلقة الأضعف: كثّف الهجوم.',
      if (weak == Pos.gk) 'حارسهم أضعف من المعتاد: التسديد من بعيد مجدٍ.',
    ];
    final fm = gs.formOf(opp);
    final form = fm.isEmpty ? '—' : fm.reversed.take(5).map((r) => r == 'W' ? '✅' : r == 'L' ? '❌' : '➖').join(' ');
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Text(k, style: const TextStyle(color: kMuted, fontSize: 13)),
            const Spacer(),
            Flexible(child: Text(v, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5))),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(2, 18, 2, 8), child: Text('تقرير الكشّاف', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الخصم: ${opp.name} — $verdict', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 6),
          row('القوة', '${opp.strength.round()} مقابل ${me.strength.round()}'),
          row('الأسلوب', '${_ment[opp.mentality.clamp(0, 4)]} • ضغط ${['منخفض', 'متوسط', 'عالٍ'][opp.pressing.clamp(0, 2)]}'),
          row('الأقوى / الأضعف', '${names[strong]} / ${names[weak]}'),
          row('نجمهم', '${star.name} (${star.overall})'),
          row('آخر 5 مباريات', form),
          if (tips.isNotEmpty) ...[
            const Divider(height: 18),
            for (final t in tips.take(3)) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $t', style: const TextStyle(fontSize: 13))),
          ],
        ]),
      ),
    ]);
  }
}
