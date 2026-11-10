import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'compare.dart';
import 'game_state.dart';
import 'models.dart';
import 'negotiation.dart';
import 'transfers.dart';
import 'widgets.dart';
import 'trophies.dart';

String? statusOf(Player p) => p.injuredWeeks > 0
    ? 'مصاب (${p.injuredWeeks} أسبوع)'
    : p.suspendedMatches > 0
        ? 'موقوف'
        : !p.registered
            ? 'غير مسجّل'
            : null;

class PlayerTile extends StatelessWidget {
  final Player p;
  final VoidCallback onTap;
  final Widget? trailing;
  const PlayerTile({super.key, required this.p, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final st = statusOf(p);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          ratingRing(p.overall),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 3),
              Row(children: [
                PosChip(p.pos),
                const SizedBox(width: 8),
                Text('${p.age} سنة', style: const TextStyle(color: kMuted, fontSize: 12)),
                if (st != null) ...[
                  const SizedBox(width: 8),
                  Text(st, style: const TextStyle(color: Color(0xFFFF7043), fontSize: 12)),
                ],
              ]),
            ]),
          ),
          trailing ??
              SizedBox(
                width: 64,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${p.fitness.round()}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.fitness < 70 ? const Color(0xFFFF8A65) : kMuted)),
                    const SizedBox(width: 4),
                    Text(p.morale >= 75 ? '😄' : p.morale >= 50 ? '🙂' : '😟', style: const TextStyle(fontSize: 14)),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (p.fitness / 100).clamp(0.0, 1.0).toDouble(),
                      minHeight: 4,
                      color: p.fitness < 60 ? const Color(0xFFFF5252) : (p.fitness < 80 ? kGold : kAccent),
                      backgroundColor: kCard2,
                    ),
                  ),
                ]),
              ),
        ]),
      ),
    );
  }
}

void showPlayerSheet(BuildContext context, GameState gs, Player p, {bool market = false}) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PlayerCard(gs: gs, p: p, market: market, outer: context)));
}

class _PlayerCard extends StatefulWidget {
  final GameState gs;
  final Player p;
  final bool market;
  final BuildContext outer;
  const _PlayerCard({required this.gs, required this.p, required this.market, required this.outer});
  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard> {
  int tab = 0;

  Widget _compLogo(String name, bool indiv) {
    const files = {
      'دوري أبطال أوروبا': 'uefa_champions_league',
      'الدوري الأوروبي': 'uefa_europa_league',
      'دوري المؤتمر الأوروبي': 'uefa_conference_league',
      'كأس السوبر': 'uefa_super_cup',
    };
    final f = files[name];
    final fallback = Icon(indiv ? Icons.military_tech_rounded : Icons.shield_rounded, color: kMuted, size: 34);
    if (f == null) return fallback;
    return Unfilter(child: Image.asset('assets/competitions/$f.png', width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (_, __, ___) => fallback));
  }

  /// الجوائز: صف لكل بطولة، كأس لكل موسم فاز به اللاعب
  List<Widget> _awardsRows(Player p) {
    if (p.awards.isEmpty) {
      return [const EmptyState(icon: Icons.emoji_events_outlined, title: 'لا جوائز بعد', subtitle: 'ستظهر هنا البطولات والجوائز التي يفوز بها اللاعب.')];
    }
    final by = <String, List<Map<String, dynamic>>>{};
    for (final a in p.awards) {
      by.putIfAbsent(a['c'] as String, () => []).add(a);
    }
    final names = by.keys.toList()..sort((x, y) => by[y]!.length.compareTo(by[x]!.length));
    return [
      for (final n in names)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('${by[n]!.length}', style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimary, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  for (final a in by[n]!)
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      a['k'] == 'indiv'
                          ? const Icon(Icons.star_rounded, size: 40, color: Color(0xFF6A6FC4))
                          : trophyImage(trophyKey(n, widget.gs.leagueName, isLeague: a['k'] == 'league'), size: 46),
                      Text('${a['s']}', style: const TextStyle(color: kMuted, fontSize: 11)),
                    ]),
                ]),
              ]),
            ),
            _compLogo(n, by[n]!.first['k'] == 'indiv'),
          ]),
        ),
    ];
  }

  Color _attrColor(num v) => v >= 70 ? const Color(0xFF1FA58A) : v >= 55 ? const Color(0xFF2F7BE6) : v >= 45 ? const Color(0xFFF5A524) : const Color(0xFFE5533D);

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6, right: 4, left: 4),
        child: Text(t, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Widget _card(Widget child, {EdgeInsets pad = const EdgeInsets.symmetric(horizontal: 14, vertical: 6)}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: pad,
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: child,
      );

  Widget _bars(List<(String, num)> rows) => _card(Column(children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(width: 74, child: Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: (r.$2 / 100).clamp(0, 1).toDouble(), minHeight: 8, color: _attrColor(r.$2), backgroundColor: kCard2),
                ),
              ),
              SizedBox(width: 38, child: Text('${r.$2.round()}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
            ]),
          ),
      ]));

  Widget _tile(String l, String v, {Color? c}) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          child: Column(children: [
            Text(v, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c)),
            const SizedBox(height: 2),
            Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      );

  Widget _row(String l, String v, {Color? vc, String? sub}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              if (sub != null) Text(sub, style: const TextStyle(color: kMuted, fontSize: 11.5)),
            ]),
          ),
          Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: vc)),
        ]),
      );

  /// ترتيب اللاعب بين كل اللاعبين وبين من هم بمركزه في دوريه
  (int, int, int, int) _ranks(GameState gs, Player p) {
    final all = <Player>[for (final t in gs.teams) ...t.squad];
    final world = all.where((x) => x.overall > p.overall).length + 1;
    final samePos = all.where((x) => x.pos == p.pos).toList();
    final inPos = samePos.where((x) => x.overall > p.overall).length + 1;
    return (world, all.length, inPos, samePos.length);
  }

  void _controls(BuildContext ctx0) {
    final ctx = ctx0;
    final gs = widget.gs, p = widget.p, market = widget.market;
    final context = widget.outer;
    void snack(String? err, String ok) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? ok)));
    final actions = <Widget>[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showCompare(context, gs, p),
                icon: const Icon(Icons.compare_arrows),
                label: const Text('قارن مع لاعب آخر'),
              ),
            ),
          ),
          if (market)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    gs.toggleWatch(p);
                    Navigator.pop(ctx);
                  },
                  icon: Icon(gs.watch.contains(p.id) ? Icons.star : Icons.star_border, color: kGold),
                  label: Text(gs.watch.contains(p.id) ? 'إزالة من المراقبة' : 'إضافة إلى قائمة المراقبة'),
                ),
              ),
            ),
          if (market && p.free)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final err = gs.buy(p);
                  Navigator.pop(ctx);
                  snack(err, 'تم التوقيع ✅');
                },
                child: Text('توقيع حر — مكافأة ${money(gs.buyPrice(p))} + عمولة ${money(gs.agentFee(gs.buyPrice(p)))}'),
              ),
            )
          else if (market)
            Column(children: [
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    showNegotiation(context, gs, p);
                  },
                  child: Text('تفاوض (${money(gs.buyPrice(p))})'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final err = gs.loanIn(p);
                    Navigator.pop(ctx);
                    snack(err, 'تمت الإعارة ✅');
                  },
                  child: Text('إعارة ${money(gs.loanFee(p))}'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final err = gs.loanInOption(p);
                    Navigator.pop(ctx);
                    snack(err, 'تمت الإعارة بخيار شراء ✅');
                  },
                  child: const Text('إعارة بخيار شراء', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final err = gs.loanInOption(p, obligation: true);
                    Navigator.pop(ctx);
                    snack(err, 'تمت الإعارة بإلزامية شراء ✅');
                  },
                  child: const Text('إعارة بإلزامية شراء', style: TextStyle(fontSize: 12.5)),
                ),
              ),
            ]),
          ])
          else if (p.onLoan && p.optionFee != null)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                p.obligation
                    ? 'معار بإلزامية شراء: يُشترى تلقائياً نهاية الموسم مقابل ${money(p.optionFee!)}'
                    : 'معار بخيار شراء مقابل ${money(p.optionFee!)}',
                style: const TextStyle(color: kMuted),
              ),
              if (!p.obligation) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final err = gs.exerciseOption(p);
                      Navigator.pop(ctx);
                      snack(err, 'تم تفعيل خيار الشراء ✅');
                    },
                    child: Text('فعّل خيار الشراء (${money(p.optionFee!)})'),
                  ),
                ),
              ],
            ])
          else if (p.onLoan)
            const Text('لاعب معار — يعود إلى ناديه نهاية الموسم.', style: TextStyle(color: kMuted))
          else
            Column(children: [
              Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final ok = await confirmDialog(ctx,
                          title: 'بيع ${p.name}؟',
                          body: 'ستستلم ${money(gs.sellPrice(p))} وتخسر لاعباً تقييمه ${p.overall} وراتبه ${money(p.wage)}/أسبوع.',
                          confirm: 'بيع', danger: true);
                      if (!ok || !ctx.mounted) return;
                      final err = gs.sell(p);
                      Navigator.pop(ctx);
                      snack(err, 'تم البيع ✅');
                    },
                    child: Text('بيع ${money(gs.sellPrice(p))}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showRenewal(context, gs, p);
                    },
                    child: const Text('تجديد العقد'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final err = gs.toggleRegistration(p);
                    Navigator.pop(ctx);
                    snack(err, p.registered ? 'تم تسجيل اللاعب' : 'أُلغي تسجيل اللاعب');
                  },
                  child: Text(p.registered ? 'إلغاء التسجيل في القائمة' : 'تسجيل في القائمة (${gs.registeredCount}/${GameState.regLimit})'),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      gs.toggleListed(p);
                      Navigator.pop(ctx);
                      snack(null, p.listed ? 'عُرض للبيع' : 'أُزيل من قائمة البيع');
                    },
                    child: Text(p.listed ? 'إلغاء العرض للبيع' : 'عرض للبيع'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final err = gs.loanOut(p);
                      Navigator.pop(ctx);
                      snack(err, 'تمت الإعارة ✅');
                    },
                    child: Text('إعارة ${money(gs.loanOutFee(p))}'),
                  ),
                ),
              ]),
            ]),
    ];
    showModalBottomSheet<void>(
      context: ctx0,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: actions),
        ),
      ),
    ).then((_) {
      if (!market && !gs.user.squad.contains(p) && ctx0.mounted) Navigator.of(ctx0).pop();
    });
  }

  @override
  Widget build(BuildContext ctx) {
    final gs = widget.gs, p = widget.p, market = widget.market;
    final context = widget.outer;
    void snack(String? err, String ok) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? ok)));
    Widget info(String l, String v, {Color? c, bool last = false}) => Expanded(
          child: Container(
            decoration: BoxDecoration(border: last ? null : const BorderDirectional(end: BorderSide(color: kLine))),
            child: Column(children: [
              Text(l, style: const TextStyle(color: kMuted, fontSize: 11.5)),
              const SizedBox(height: 4),
              Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: c)),
            ]),
          ),
        );
    final tabs = ['السمات', 'الإحصاءات', 'العقد', 'المسيرة', 'الجوائز'];
    final avg = p.rated == 0 ? '—' : p.avgRating.toStringAsFixed(1);
    final (wr, wn, pr, pn) = _ranks(gs, p);
    final body = <Widget>[
      if (tab == 0) ...[
        _section('فنية'),
        _bars(p.pos == Pos.gk ? [('الحراسة', p.gk)] : [('الهجوم', p.atk), ('التمرير', p.pas), ('الدفاع', p.def)]),
        _section('بدنية'),
        _bars([('اللياقة', p.fitness)]),
        _section('ذهنية'),
        _bars([('المعنويات', p.morale)]),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('الإمكانية المتوقعة', style: TextStyle(fontWeight: FontWeight.w800))),
            Text('${p.overall} ← ${p.potential}', style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 8),
          Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (p.potential / 100).clamp(0, 1).toDouble(), minHeight: 10, color: const Color(0xFFBFE6DC), backgroundColor: kCard2)),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (p.overall / 100).clamp(0, 1).toDouble(), minHeight: 10, color: const Color(0xFF1FA58A), backgroundColor: Colors.transparent)),
          ]),
        ]), pad: const EdgeInsets.all(14)),
      ],
      if (tab == 1) ...[
        Row(children: [_tile('مباريات', '${p.apps}'), _tile('أهداف', '${p.goals}', c: const Color(0xFF1FA58A)), _tile('تمريرات حاسمة', '${p.assists}', c: const Color(0xFF2F7BE6))]),
        const SizedBox(height: 8),
        Row(children: [_tile('بطاقات', '${p.yellows}', c: const Color(0xFFF5A524)), _tile('إصابات', '${p.injuryCount}'), _tile('التقييم', avg, c: const Color(0xFF1FA58A))]),
        const SizedBox(height: 10),
        _card(Row(children: [
          SizedBox(
            width: 110,
            height: 70,
            child: CustomPaint(painter: _GaugePainter(1 - (wr - 1) / (wn <= 1 ? 1 : wn - 1)), child: const SizedBox.shrink()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('الترتيب بين كل اللاعبين', style: TextStyle(color: kMuted, fontSize: 12)),
              Text('#$wr', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              Text('من $wn • بين من بمركزه: $pr من $pn', style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
        ]), pad: const EdgeInsets.all(14)),
        if (p.injuredWeeks > 0) Text('🚑 مصاب — يعود بعد ${p.injuredWeeks} أسابيع', style: const TextStyle(color: Color(0xFFE5533D), fontSize: 13)),
        if (p.suspendedMatches > 0) Text('🟥 موقوف ${p.suspendedMatches} مباراة', style: const TextStyle(color: Color(0xFFE5533D), fontSize: 13)),
      ],
      if (tab == 2) ...[
        _card(Column(children: [
          _row('الراتب الأسبوعي', money(p.wage)),
          const Divider(height: 1),
          _row('القيمة السوقية', money(p.value)),
          const Divider(height: 1),
          if (!market) _row('ينتهي العقد', 'بعد ${p.contract} ${p.contract <= 1 ? 'سنة' : 'سنوات'}', vc: p.contract <= 1 ? const Color(0xFFE5533D) : null),
          if (market)
            _row(
              'رغبة اللاعب بالانضمام',
              switch (gs.joinOutlook(p)) { 0 => 'مرتفعة', 1 => 'متردد', _ => 'ضعيفة' },
              vc: switch (gs.joinOutlook(p)) { 0 => const Color(0xFF1FA58A), 1 => const Color(0xFFF5A524), _ => const Color(0xFFE5533D) },
            ),
        ])),
        if (p.onLoan) _card(Text(p.optionFee != null ? (p.obligation ? 'معار بإلزامية شراء: ${money(p.optionFee!)}' : 'معار بخيار شراء: ${money(p.optionFee!)}') : 'لاعب معار — يعود إلى ناديه نهاية الموسم.', style: const TextStyle(color: kMuted)), pad: const EdgeInsets.all(14)),
        if (!market)
          _card(Column(children: [
            Row(children: [
              const Expanded(child: Text('متاح للبيع', style: TextStyle(fontWeight: FontWeight.w800))),
              Switch(value: p.listed, onChanged: (_) { gs.toggleListed(p); setState(() {}); }),
            ]),
          ])),
      ],
      if (tab == 3) ...[
        if (p.career.isEmpty) const Text('لا توجد مسيرة مسجّلة بعد', style: TextStyle(color: kMuted)),
        if (p.career.isNotEmpty)
          _card(Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: const [
                SizedBox(width: 56, child: Text('الموسم', style: TextStyle(color: kMuted, fontSize: 12))),
                Expanded(child: Text('النادي', style: TextStyle(color: kMuted, fontSize: 12))),
                SizedBox(width: 44, child: Text('مباريات', style: TextStyle(color: kMuted, fontSize: 12))),
                SizedBox(width: 40, child: Text('أهداف', textAlign: TextAlign.end, style: TextStyle(color: kMuted, fontSize: 12))),
              ]),
            ),
            for (final c in p.career.reversed.take(8)) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  SizedBox(width: 56, child: Text('م${c['s']}', style: const TextStyle(color: kMuted, fontSize: 12.5))),
                  Expanded(child: Text('${c['t']}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                  SizedBox(width: 44, child: Text('${c['a']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                  SizedBox(width: 40, child: Text('${c['g']}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1FA58A)))),
                ]),
              ),
            ],
          ])),
      ],
      if (tab == 4) ..._awardsRows(p),
    ];
    Widget big(String label, Color bg, Color fg, VoidCallback f, {IconData? icon, int flex = 1}) => Expanded(
          flex: flex,
          child: GestureDetector(
            onTap: f,
            child: Container(
              height: 50,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Color.alphaBlend(Colors.black26, bg), offset: const Offset(0, 3))]),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 16)),
                if (icon != null) ...[const SizedBox(width: 6), Icon(icon, color: fg, size: 20)],
              ]),
            ),
          ),
        );
    const purple = Color(0xFF6A6FC4), sky = Color(0xFFA9D4F8), navy = Color(0xFF15233D);
    final bottom = <Widget>[
      if (market && p.free)
        big('توقيع حر', kPrimary, Colors.white, () {
          final err = gs.buy(p);
          Navigator.pop(ctx);
          snack(err, 'تم التوقيع ✅');
        }, icon: Icons.description_rounded, flex: 2)
      else if (market) ...[
        big('تفاوض', kPrimary, Colors.white, () {
          Navigator.pop(ctx);
          showNegotiation(context, gs, p);
        }, icon: Icons.description_rounded, flex: 2),
        const SizedBox(width: 10),
        big('إعارة', purple, Colors.white, () {
          final err = gs.loanIn(p);
          Navigator.pop(ctx);
          snack(err, 'تمت الإعارة ✅');
        }, icon: Icons.handshake_rounded),
      ] else if (!p.onLoan) ...[
        big('بيع', kPrimary, Colors.white, () async {
          final ok = await confirmDialog(ctx,
              title: 'بيع ${p.name}؟',
              body: 'ستستلم ${money(gs.sellPrice(p))} وتخسر لاعباً تقييمه ${p.overall} وراتبه ${money(p.wage)}/أسبوع.',
              confirm: 'بيع', danger: true);
          if (!ok || !ctx.mounted) return;
          final err = gs.sell(p);
          Navigator.pop(ctx);
          snack(err, 'تم البيع ✅');
        }, icon: Icons.attach_money_rounded),
        const SizedBox(width: 10),
        big('إعارة', purple, Colors.white, () {
          final err = gs.loanOut(p);
          Navigator.pop(ctx);
          snack(err, 'تمت الإعارة ✅');
        }, icon: Icons.handshake_rounded),
      ],
      if (market || !p.onLoan) const SizedBox(width: 10),
      big('التحكم', sky, navy, () => _controls(ctx)),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('بطاقة اللاعب')),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 10), child: Row(children: bottom))),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)),
          child: Row(children: [
            PlayerAvatar(p, size: 76),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kPrimary)),
                const SizedBox(height: 4),
                Text([if (p.club != null) p.club!, if (p.nat != null) p.nat!].join(' • '), style: const TextStyle(color: kMuted, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFBFE6DC), borderRadius: BorderRadius.circular(8)),
                  child: Text('${p.pos.label}${p.sub != null ? '\n${p.sub}' : ''}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF0B6E5A), fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ]),
            ),
            ratingRing(p.overall, size: 74),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Row(children: [
            info('القدم', p.foot ?? '—'),
            info('الطول', p.height != null ? '${(p.height! / 100).toStringAsFixed(2)}m' : '—'),
            info('العمر', '${p.age}'),
            info('الراتب', money(p.wage)),
            info('القيمة', money(p.value), c: const Color(0xFF1FA58A), last: true),
          ]),
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 2))),
          segments: [for (var i = 0; i < tabs.length; i++) ButtonSegment(value: i, label: Text(tabs[i], style: const TextStyle(fontSize: 13)))],
          selected: {tab},
          onSelectionChanged: (v) => setState(() => tab = v.first),
        ),
        const SizedBox(height: 4),
        ...body,
      ]),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double v;
  _GaugePainter(this.v);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(8, 8, size.width - 16, (size.height - 8) * 2);
    final bg = Paint()..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round..color = const Color(0xFFE3E6EE);
    final fg = Paint()..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round..color = const Color(0xFF1FA58A);
    canvas.drawArc(r, 3.14159, 3.14159, false, bg);
    canvas.drawArc(r, 3.14159, 3.14159 * v.clamp(0.02, 1.0), false, fg);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) => o.v != v;
}

class SquadTab extends StatefulWidget {
  final GameState gs;
  const SquadTab({super.key, required this.gs});
  @override
  State<SquadTab> createState() => _SquadTabState();
}

class _SquadTabState extends State<SquadTab> {
  Pos? pos;
  bool absentOnly = false;

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final sq = gs.user.squad;
    final inj = sq.where((p) => !p.available).length;
    final order = {for (var i = 0; i < Pos.values.length; i++) Pos.values[i]: i};
    final list = sq.where((p) => (pos == null || p.pos == pos) && (!absentOnly || !p.available)).toList()
      ..sort((x, y) {
        final c = order[x.pos]!.compareTo(order[y.pos]!);
        return c != 0 ? c : y.overall.compareTo(x.overall);
      });
    Widget chip(String label, bool sel, VoidCallback f) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: ChoiceChip(label: Text(label), selected: sel, showCheckmark: false, onSelected: (_) => f()),
        );
    return ListView(padding: const EdgeInsets.all(14), children: [
      Panel(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _kv('اللاعبون', '${sq.length}'),
          _kv('التقييم', gs.user.strength.toStringAsFixed(1)),
          _kv('غائبون', '$inj'),
          _kv('الرواتب/أسبوع', money(gs.weeklyWages)),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          chip('الكل ${sq.length}', pos == null && !absentOnly, () => setState(() { pos = null; absentOnly = false; })),
          for (final ps in Pos.values) chip('${ps.plural} ${sq.where((x) => x.pos == ps).length}', pos == ps, () => setState(() { pos = ps; absentOnly = false; })),
          chip('غائبون $inj', absentOnly, () => setState(() { absentOnly = true; pos = null; })),
        ]),
      ),
      const SizedBox(height: 10),
      Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final p in list) PlayerTile(p: p, onTap: () => showPlayerSheet(context, gs, p)),
        ]),
      ),
    ]);
  }

  Widget _kv(String k, String v) => Column(children: [
        Text(v, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        Text(k, style: const TextStyle(color: kMuted, fontSize: 11)),
      ]);
}

class TransfersTab extends StatefulWidget {
  final GameState gs;
  const TransfersTab({super.key, required this.gs});
  @override
  State<TransfersTab> createState() => _TransfersTabState();
}

class _TransfersTabState extends State<TransfersTab> {
  int mode = 0; // 0 سوق 1 مجانيون 2 بيع 3 عروض
  Pos? filter;
  int sort = 0; // 0 تقييم 1 سعر 2 عمر
  int minOvr = 0;
  bool watchOnly = false;

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final src = switch (mode) {
      0 => gs.market.where((p) => !p.free),
      1 => gs.market.where((p) => p.free),
      _ => gs.user.squad,
    };
    final list = src
        .where((p) => (filter == null || p.pos == filter) && p.overall >= minOvr && (!watchOnly || gs.watch.contains(p.id)))
        .toList()
      ..sort((a, b) => switch (sort) {
            1 => (mode >= 2 ? gs.sellPrice(b) : gs.buyPrice(b)).compareTo(mode >= 2 ? gs.sellPrice(a) : gs.buyPrice(a)),
            2 => a.age.compareTo(b.age),
            _ => b.overall.compareTo(a.overall),
          });
    return ListView(padding: const EdgeInsets.all(14), children: [
      Panel(
        child: Row(children: [
          const Text('💰 الميزانية', style: TextStyle(color: kMuted)),
          const Spacer(),
          AnimatedMoney(gs.user.budget,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: gs.user.budget < 0 ? const Color(0xFFFF7043) : kPrimary)),
        ]),
      ),
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          const ButtonSegment(value: 0, label: Text('السوق')),
          const ButtonSegment(value: 1, label: Text('أحرار')),
          const ButtonSegment(value: 2, label: Text('بيع')),
          ButtonSegment(value: 3, label: Text(gs.offers.isEmpty ? 'عروض' : 'عروض (${gs.offers.length})')),
        ],
        selected: {mode},
        onSelectionChanged: (s) => setState(() => mode = s.first),
      ),
      const SizedBox(height: 8),
      Text('${gs.windowOpen ? '🟢' : '🔴'} ${gs.windowLabel}${gs.transferBan ? ' • ⛔ حظر انتقالات' : ''}',
          style: TextStyle(color: gs.windowOpen ? const Color(0xFF1FA58A) : const Color(0xFFFF8A65), fontSize: 12)),
      const SizedBox(height: 8),
      if (mode == 3) ..._offers(context, gs) else ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: FilterChip(label: const Text('⭐ المراقبة'), selected: watchOnly, onSelected: (v) => setState(() => watchOnly = v)),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: ChoiceChip(label: const Text('الكل'), selected: filter == null, onSelected: (_) => setState(() => filter = null)),
            ),
            for (final p in Pos.values)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: ChoiceChip(label: Text(p.label), selected: filter == p, onSelected: (_) => setState(() => filter = p)),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        Row(children: [
          const Text('ترتيب:', style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(width: 6),
          for (final e in const [(0, 'التقييم'), (1, 'السعر'), (2, 'العمر')])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: ChoiceChip(label: Text(e.$2), selected: sort == e.$1, onSelected: (_) => setState(() => sort = e.$1)),
            ),
        ]),
        Row(children: [
          Text('الحد الأدنى للتقييم: $minOvr', style: const TextStyle(color: kMuted, fontSize: 12)),
          Expanded(
            child: Slider(
              value: minOvr.toDouble(),
              min: 0,
              max: 85,
              divisions: 17,
              onChanged: (v) => setState(() => minOvr = v.round()),
            ),
          ),
        ]),
        if (mode < 2)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('يتجدد السوق كل 4 أسابيع، وقد تخطف الأندية الأخرى لاعبين قبلك.', style: TextStyle(color: kMuted, fontSize: 12)),
          ),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            if (list.isEmpty)
              const EmptyState(icon: Icons.search_off, title: 'لا نتائج', subtitle: 'جرّب تخفيف الفلاتر أو تغيير المركز.'),
            for (final p in list)
              PlayerTile(
                p: p,
                onTap: () => showPlayerSheet(context, gs, p, market: mode < 2),
                trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    money(mode < 2 ? gs.buyPrice(p) : gs.sellPrice(p)),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimary),
                  ),
                  if (p.club != null && mode < 2) Text(p.club!, style: const TextStyle(color: kMuted, fontSize: 11)),
                  if (p.listed) const Text('معروض للبيع', style: TextStyle(color: Color(0xFFFFCA28), fontSize: 11)),
                  if (p.onLoan) const Text('معار', style: TextStyle(color: kMuted, fontSize: 11)),
                  const SizedBox(height: 3),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(60, 28), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    onPressed: () => showPlayerSheet(context, gs, p, market: mode < 2),
                    child: Text(mode < 2 ? 'تفاوض' : 'بيع'),
                  ),
                ]),
              ),
          ]),
        ),
      ],
    ]);
  }

  List<Widget> _offers(BuildContext context, GameState gs) {
    if (gs.offers.isEmpty) {
      return const [
        Panel(child: EmptyState(icon: Icons.mark_email_unread_outlined, title: 'لا عروض حالياً', subtitle: 'اعرض لاعبين للبيع لزيادة احتمال وصول العروض.')),
      ];
    }
    return [
      for (final Offer o in List<Offer>.of(gs.offers))
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${o.club} يريد ${o.player.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('العرض ${money(o.amount)} • القيمة ${money(o.player.value)} • ينتهي بعد ${o.weeksLeft} جولات',
                style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final ok = await confirmDialog(context,
                        title: 'قبول عرض ${o.club}؟',
                        body: 'ستبيع ${o.player.name} مقابل ${money(o.amount)} (قيمته السوقية ${money(o.player.value)}).',
                        confirm: 'قبول وبيع', danger: true);
                    if (!ok || !context.mounted) return;
                    final err = gs.acceptOffer(o);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تم البيع ✅')));
                  },
                  child: const Text('قبول'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => gs.rejectOffer(o), child: const Text('رفض'))),
            ]),
          ]),
        ),
    ];
  }
}

/// قائمة العقود: الأقرب انتهاءً أولاً، مع تجديد أو إنهاء العقد
class ContractsView extends StatelessWidget {
  final GameState gs;
  const ContractsView({super.key, required this.gs});

  Future<void> _release(BuildContext context, Player p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء العقد'),
        content: Text('إنهاء عقد ${p.name} يكلّفك تعويضاً قدره ${money(gs.releaseCost(p))}. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنهاء')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = gs.release(p);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تم إنهاء العقد')));
  }

  @override
  Widget build(BuildContext context) {
    final list = [...gs.user.squad]
      ..sort((a, b) {
        final c = a.contract.compareTo(b.contract);
        return c != 0 ? c : b.overall.compareTo(a.overall);
      });
    return ListView(padding: const EdgeInsets.all(14), children: [
      Panel(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [
            Text(money(gs.weeklyWages), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const Text('الرواتب/أسبوع', style: TextStyle(color: kMuted, fontSize: 11)),
          ]),
          Column(children: [
            Text('${gs.expiring.length}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: gs.expiring.isEmpty ? null : const Color(0xFFFFCA28))),
            const Text('عقود تنتهي هذا الموسم', style: TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ]),
      ),
      Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final p in list)
            PlayerTile(
              p: p,
              onTap: () => showPlayerSheet(context, gs, p),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${p.contract} ${p.contract == 1 ? 'سنة' : 'سنوات'}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.contract <= 1 ? const Color(0xFFFFCA28) : null)),
                  Text('${money(p.wage)}/أسبوع', style: const TextStyle(color: kMuted, fontSize: 11)),
                ]),
                const SizedBox(width: 6),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(56, 30), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () => showRenewal(context, gs, p),
                  child: const Text('تفاوض'),
                ),
                IconButton(
                  tooltip: tr('إنهاء العقد'),
                  icon: const Icon(Icons.logout, size: 20, color: Color(0xFFFF8A65)),
                  onPressed: () => _release(context, p),
                ),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
