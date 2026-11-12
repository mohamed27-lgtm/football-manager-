import 'package:flutter/material.dart' hide Text;
import 'calendar.dart';
import 'finance.dart';
import 'game_state.dart';
import 'i18n.dart';
import 'lineup_pages.dart';
import 'match_pages.dart';
import 'widgets.dart';

/// معاملة واحدة في دفتر النادي (المبالغ بالملايين، موقّعة: + دخل / − مصروف)
class Tx {
  final int season, week, day;
  final String key, note;
  final double amt;
  double after = 0;
  Tx(this.season, this.week, this.day, this.key, this.amt, this.note);
  DateTime get date => GameCalendar.dateOf(season, week, day);
  double get before => after - amt;
  String get title => Finance.labels[key] ?? key;
  bool get income => amt > 0;
}

/// المعاملات من الأحدث إلى الأقدم، والرصيد بعد كل واحدة محسوب رجوعاً من الرصيد الحالي
List<Tx> txList(GameState gs) {
  final out = <Tx>[
    for (final e in gs.fin.ledger.reversed)
      Tx(e[0] as int, e[1] as int, e[2] as int, e[3] as String, (e[4] as num).toDouble(), (e.length > 5 ? e[5] as String : ''))
  ];
  var bal = gs.user.budget;
  for (final t in out) {
    t.after = bal;
    bal -= t.amt;
  }
  return out;
}

String amtText(double m, {bool sign = true}) {
  final a = m.abs();
  final s = a >= 1 ? '\$${a.toStringAsFixed(2)}M' : '\$${(a * 1000).round()}K';
  if (!sign) return s;
  return '${m >= 0 ? '+' : '-'}$s';
}

const _income = Color(0xFF1FA58A), _expense = Color(0xFFE5533D);

(IconData, Color) txStyle(String k) => switch (k) {
      'tickets' => (Icons.payments_outlined, const Color(0xFF1FA58A)),
      'broadcast' => (Icons.tv_rounded, const Color(0xFF2F7BE6)),
      'sponsor' => (Icons.star_border_rounded, const Color(0xFFF5A524)),
      'prize' => (Icons.emoji_events_outlined, const Color(0xFFF5A524)),
      'sales' => (Icons.swap_horiz_rounded, const Color(0xFF2F7BE6)),
      'loanout' => (Icons.swap_horiz_rounded, const Color(0xFF2F7BE6)),
      'purchases' || 'loanin' => (Icons.swap_horiz_rounded, const Color(0xFF2F7BE6)),
      'wages' || 'staff' => (Icons.groups_2_outlined, const Color(0xFFE5533D)),
      'maintenance' || 'upgrades' => (Icons.home_work_outlined, const Color(0xFF6A6FC4)),
      'interest' => (Icons.percent_rounded, const Color(0xFFE5533D)),
      _ => (Icons.receipt_long_outlined, const Color(0xFF8A93A6)),
    };

const _filters = <(String, String)>[
  ('all', 'الكل'),
  ('in', 'دخل'),
  ('out', 'مصروف'),
  ('wage', 'أجور'),
  ('xfer', 'انتقالات'),
  ('spon', 'رعاة'),
];

bool _match(Tx t, String f) => switch (f) {
      'in' => t.income,
      'out' => !t.income,
      'wage' => t.key == 'wages' || t.key == 'staff',
      'xfer' => const ['purchases', 'sales', 'loanin', 'loanout', 'renewals', 'severance', 'agents'].contains(t.key),
      'spon' => t.key == 'sponsor',
      _ => true,
    };

class LedgerScreen extends StatefulWidget {
  final GameState gs;
  const LedgerScreen({super.key, required this.gs});
  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  String filter = 'all', q = '';

  void _detail(Tx t) {
    final (ic, col) = txStyle(t.key);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Container(width: 56, height: 56, decoration: BoxDecoration(color: col.withOpacity(0.16), borderRadius: BorderRadius.circular(18)), child: Icon(ic, color: col, size: 28)),
            const SizedBox(height: 8),
            Text(t.title, style: const TextStyle(color: kMuted, fontSize: 13)),
            Text(amtText(t.amt), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: t.income ? _income : _expense)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3), decoration: BoxDecoration(color: _income.withOpacity(0.14), borderRadius: BorderRadius.circular(8)), child: const Text('مكتملة', style: TextStyle(color: _income, fontWeight: FontWeight.w800, fontSize: 12))),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _kv('الفئة', t.income ? 'دخل' : 'مصروف'),
                _kv('التاريخ', '${GameCalendar.fmt(t.date)} • الموسم ${t.season}'),
                _kv('الجولة', '${t.week + 1}'),
                if (t.note.isNotEmpty) _kv('التفاصيل', t.note),
                _kv('الرصيد قبل', amtText(t.before, sign: false)),
                _kv('الرصيد بعد', amtText(t.after, sign: false)),
              ]),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: whiteBtn('إغلاق', () => Navigator.pop(c))),
          ]),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Text(k, style: const TextStyle(color: kMuted, fontSize: 13)),
          const Spacer(),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final all = txList(gs);
    final list = [
      for (final t in all)
        if (_match(t, filter) && (q.isEmpty || t.title.contains(q) || t.note.contains(q))) t
    ];
    final net = list.fold<double>(0, (a, t) => a + t.amt);
    // تجميع حسب اليوم
    final groups = <String, List<Tx>>{};
    for (final t in list) {
      groups.putIfAbsent(GameCalendar.fmt(t.date) + ' ${t.season}', () => []).add(t);
    }
    return Scaffold(
      appBar: gameBar(context, gs, 'السجل المالي'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        TextField(
          onChanged: (v) => setState(() => q = v.trim()),
          decoration: InputDecoration(
            hintText: 'ابحث في المعاملات',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: kCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kLine)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kLine)),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final f in _filters)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: GestureDetector(
                  onTap: () => setState(() => filter = f.$1),
                  child: Unfilter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(color: filter == f.$1 ? kNavy : const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: filter == f.$1 ? kNavy : const Color(0xFFD5DBE7))),
                      child: Text(f.$2, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: filter == f.$1 ? const Color(0xFFFFFFFF) : kNavy)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text('${list.length} معاملة', style: const TextStyle(color: kMuted, fontSize: 12.5)),
          const Spacer(),
          Text('الصافي ${amtText(net)}', style: TextStyle(color: net >= 0 ? _income : _expense, fontWeight: FontWeight.w900, fontSize: 12.5)),
        ]),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Panel(child: EmptyState(icon: Icons.receipt_long_outlined, title: 'لا معاملات', subtitle: 'ستظهر هنا بعد أول مباراة أو صفقة.'))
        else
          Container(
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
            child: Column(children: [
              for (final e in groups.entries) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: kCard2,
                  child: Row(children: [
                    Text(e.key, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800, fontSize: 12)),
                    const Spacer(),
                    Text(amtText(e.value.fold<double>(0, (a, t) => a + t.amt)), style: TextStyle(color: e.value.fold<double>(0, (a, t) => a + t.amt) >= 0 ? _income : _expense, fontWeight: FontWeight.w900, fontSize: 12)),
                  ]),
                ),
                for (final t in e.value) _row(t),
              ],
            ]),
          ),
      ]),
    );
  }

  Widget _row(Tx t) {
    final (ic, col) = txStyle(t.key);
    return InkWell(
      onTap: () => _detail(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: col.withOpacity(0.16), borderRadius: BorderRadius.circular(13)), child: Icon(ic, color: col, size: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
              Text(t.note.isEmpty ? 'الجولة ${t.week + 1}' : t.note, style: const TextStyle(color: kMuted, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amtText(t.amt), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: t.income ? _income : _expense)),
            Text(amtText(t.after, sign: false), style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}
