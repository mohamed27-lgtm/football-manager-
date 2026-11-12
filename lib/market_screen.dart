import 'dart:math' show min;
import 'package:flutter/material.dart' hide Text;
import 'calendar.dart';
import 'flags.dart';
import 'game_state.dart';
import 'i18n.dart';
import 'loans_screen.dart';
import 'models.dart';
import 'negotiation.dart';
import 'squad.dart';
import 'transfers.dart';
import 'widgets.dart';

const _okGreen = Color(0xFF1FA58A);
const _sky = Color(0xFFA9D4F8);

/// سوق الانتقالات: السوق / عروضي / المفضّلة / الإعارات
class TransfersTab extends StatefulWidget {
  final GameState gs;
  const TransfersTab({super.key, required this.gs});
  @override
  State<TransfersTab> createState() => _TransfersTabState();
}

class _Filters {
  Set<Pos> pos = {};
  bool buy = true, loan = false, free = true;
  RangeValues age = const RangeValues(16, 40), rate = const RangeValues(50, 99), price = const RangeValues(0, 100);

  int get active =>
      (pos.isNotEmpty ? 1 : 0) +
      ((buy && !loan && free) ? 0 : 1) +
      (age.start > 16 || age.end < 40 ? 1 : 0) +
      (rate.start > 50 || rate.end < 99 ? 1 : 0) +
      (price.start > 0 || price.end < 100 ? 1 : 0);

  void reset() {
    pos = {};
    buy = true;
    loan = false;
    free = true;
    age = const RangeValues(16, 40);
    rate = const RangeValues(50, 99);
    price = const RangeValues(0, 100);
  }
}

class _TransfersTabState extends State<TransfersTab> {
  GameState get gs => widget.gs;
  int mode = 0; // 0 السوق 1 عروضي 2 المفضلة 3 الإعارات
  int sort = 0;
  final f = _Filters();
  final q = TextEditingController();

  static const _sorts = ['الأعلى تقييمًا', 'الأقل سعرًا', 'الأصغر سنًا', 'الأعلى إمكانات'];

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  bool _isMarket(Player p) => gs.market.any((x) => x.id == p.id);

  bool _pass(Player p) {
    if (f.pos.isNotEmpty && !f.pos.contains(p.pos)) return false;
    if (p.free ? !f.free : !(f.buy || f.loan)) return false;
    if (p.age < f.age.start || p.age > f.age.end) return false;
    if (p.overall < f.rate.start || p.overall > f.rate.end) return false;
    final pr = gs.buyPrice(p);
    if (pr < f.price.start || (f.price.end < 100 && pr > f.price.end)) return false;
    final t = q.text.trim().toLowerCase();
    if (t.isNotEmpty && !('${p.name} ${p.club ?? ''}'.toLowerCase().contains(t))) return false;
    return true;
  }

  List<Player> _list() {
    final src = mode == 2 ? [...gs.market, ...gs.user.squad].where((p) => gs.watch.contains(p.id)).toList() : gs.market.toList();
    final out = src.where(mode == 2 ? (p) => true : _pass).toList();
    out.sort((a, b) => switch (sort) {
          1 => gs.buyPrice(a).compareTo(gs.buyPrice(b)),
          2 => a.age.compareTo(b.age),
          3 => b.potential.compareTo(a.potential),
          _ => b.overall.compareTo(a.overall),
        });
    return out;
  }

  ({int left, int total}) _window() {
    final h = gs.rounds.length ~/ 2;
    if (gs.week < 4) return (left: 4 - gs.week, total: 4);
    if (gs.week >= h - 1 && gs.week < h + 3) return (left: h + 3 - gs.week, total: 4);
    return (left: 0, total: 4);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gs,
      builder: (context, _) {
        final tabs = ['السوق', 'عروضي', 'المفضّلة', 'الإعارات'];
        final badge = gs.offers.length;
        return Column(children: [
          Container(
            color: kCard,
            child: Row(children: [
              for (final e in tabs.indexed)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => mode = e.$1),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: mode == e.$1 ? kPrimary : Colors.transparent, width: 3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(e.$2, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: mode == e.$1 ? kPrimary : kMuted)),
                        if (e.$1 == 1 && badge > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                            child: Unfilter(child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900))),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: switch (mode) {
              3 => LoansBody(gs: gs),
              1 => _mine(context),
              _ => _market(context),
            },
          ),
        ]);
      },
    );
  }

  // ───────── السوق والمفضلة ─────────
  Widget _market(BuildContext context) {
    final list = _list();
    final w = _window();
    Widget chip(String label, bool sel, VoidCallback on) => GestureDetector(
          onTap: on,
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            height: 40,
            decoration: BoxDecoration(color: sel ? kNavy : kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? kNavy : kLine)),
            child: sel ? Unfilter(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))) : Text(label, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        );
    return ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 24), children: [
      if (mode == 0) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
          child: Column(children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: (gs.windowOpen ? _okGreen : const Color(0xFFF5A524)).withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.schedule_rounded, color: gs.windowOpen ? _okGreen : const Color(0xFFF5A524)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(gs.windowOpen ? 'النافذة مفتوحة' : 'النافذة مغلقة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: gs.windowOpen ? _okGreen : const Color(0xFFE5533D))),
                  Text(gs.windowOpen ? 'تُغلق بعد ${w.left * 7} يومًا' : (gs.transferBan ? '⛔ حظر انتقالات' : 'تفتح في الفترة القادمة'), style: const TextStyle(color: kMuted, fontSize: 13)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('ميزانية الانتقالات', style: TextStyle(color: kMuted, fontSize: 12)),
                AnimatedMoney(gs.user.budget, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: gs.user.budget < 0 ? const Color(0xFFE5533D) : kPrimary)),
              ]),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: gs.windowOpen ? (1 - w.left / w.total).clamp(0.05, 1.0).toDouble() : 0, minHeight: 7, color: _okGreen, backgroundColor: kCard2),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
              child: Row(children: [
                const Icon(Icons.search, color: kMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: q,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(border: InputBorder.none, hintText: tr('ابحث عن لاعب أو نادٍ...'), hintStyle: const TextStyle(color: kMuted)),
                  ),
                ),
                if (q.text.isNotEmpty) GestureDetector(onTap: () => setState(q.clear), child: const Icon(Icons.close, size: 18, color: kMuted)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _filterSheet(context),
            child: Badge(
              isLabelVisible: f.active > 0,
              label: Text('${f.active}'),
              backgroundColor: kPrimary,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(16)),
                child: const Unfilter(child: Icon(Icons.tune_rounded, color: Colors.white)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            chip('الكل', f.pos.isEmpty && f.free && f.buy && !f.loan, () => setState(() {
                  f.pos = {};
                  f.buy = true;
                  f.free = true;
                  f.loan = false;
                })),
            for (final p in Pos.values) chip(p.plural, f.pos.length == 1 && f.pos.contains(p), () => setState(() => f.pos = {p})),
            chip('أحرار', f.free && !f.buy && !f.loan, () => setState(() {
                  f.free = true;
                  f.buy = false;
                  f.loan = false;
                })),
          ]),
        ),
      ],
      const SizedBox(height: 10),
      Row(children: [
        PopupMenuButton<int>(
          onSelected: (v) => setState(() => sort = v),
          itemBuilder: (_) => [for (final e in _sorts.indexed) PopupMenuItem(value: e.$1, child: Text(e.$2))],
          child: Row(children: [
            const Icon(Icons.keyboard_arrow_down_rounded, color: kMuted),
            Text('الترتيب: ${_sorts[sort]}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
        ),
        const Spacer(),
        Text('${list.length} لاعبًا ${mode == 2 ? '' : 'مطابقًا'}', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 8),
      if (list.isEmpty)
        Panel(child: EmptyState(icon: mode == 2 ? Icons.favorite_border : Icons.search_off, title: mode == 2 ? 'المفضّلة فارغة' : 'لا نتائج', subtitle: mode == 2 ? 'اضغط القلب في بطاقة لاعب لإضافته هنا.' : 'جرّب تخفيف الفلاتر أو تغيير المركز.'))
      else
        for (final p in list) _card(context, p),
      const Padding(padding: EdgeInsets.only(top: 6), child: Text('يتجدد السوق كل 4 أسابيع، وقد تخطف الأندية الأخرى لاعبين قبلك.', style: TextStyle(color: kMuted, fontSize: 12))),
    ]);
  }

  Team? _teamNamed(String? n) {
    if (n == null) return null;
    for (final t in [...gs.teams, ...gs.foreign.values, ...gs.upper, ...gs.lower]) {
      if (t.name == n) return t;
    }
    return null;
  }

  bool _hot(Player p) => p.listed || (p.free && p.overall >= 68) || (!p.free && p.contract <= 1 && p.overall >= 72);

  Widget _card(BuildContext context, Player p) {
    final inMarket = _isMarket(p);
    final t = _teamNamed(p.club);
    final year = GameCalendar.seasonStart(gs.season).year + p.contract;
    final watched = gs.watch.contains(p.id);
    Widget stat(String l, String v) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: const TextStyle(color: kMuted, fontSize: 12.5)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ]),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kLine)),
      child: Column(children: [
        InkWell(
          onTap: () => showPlayerSheet(context, gs, p, market: inMarket),
          child: Row(children: [
            playerFace(p, 62, ring: posColor(p.pos), ringWidth: 2),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
                  if (_hot(p)) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFFD9D2), borderRadius: BorderRadius.circular(8)),
                      child: Text(p.free ? 'حر' : 'صفقة ساخنة', style: const TextStyle(color: Color(0xFFD5432E), fontWeight: FontWeight.w800, fontSize: 11.5)),
                    ),
                  ],
                ]),
                const SizedBox(height: 5),
                Wrap(spacing: 6, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if (p.nat != null && p.nat!.isNotEmpty) FlagBadge(p.nat!, size: 18),
                  if (t != null) teamBadge(t, size: 18),
                  if (p.club != null) Text(p.club!, style: const TextStyle(color: kMuted, fontSize: 12.5)),
                  Text('•', style: const TextStyle(color: kMuted)),
                  Text('${p.age} سنة', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            Column(children: [
              Container(
                width: 48,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: ratingColor(p.overall), borderRadius: BorderRadius.circular(12)),
                child: Unfilter(child: Text('${p.overall}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21))),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: posColor(p.pos).withOpacity(0.16), borderRadius: BorderRadius.circular(8)),
                child: Text(p.pos.label, style: TextStyle(color: posColor(p.pos), fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ]),
          ]),
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kLine)),
        Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                stat('القيمة', money(p.value)),
                stat('الراتب/أسبوع', wageK(p.wage)),
                stat('العقد', '$year'),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => gs.toggleWatch(p),
            child: Container(width: 46, height: 46, decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(14)), child: Icon(watched ? Icons.favorite : Icons.favorite_border, color: kPrimary)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => inMarket ? _offerSheet(context, p) : showPlayerSheet(context, gs, p),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x66C2412A), offset: Offset(0, 3))]),
              child: const Unfilter(child: Text('عرض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))),
            ),
          ),
        ]),
      ]),
    );
  }

  // ───────── لوحة العرض السفلية ─────────
  String _fit(Player p) {
    final mine = gs.user.squad.where((x) => x.pos == p.pos && !x.onLoan).toList()..sort((a, b) => b.overall.compareTo(a.overall));
    final starters = switch (p.pos) { Pos.gk => 1, Pos.def => 4, Pos.mid => 3, Pos.att => 3 };
    if (mine.length < starters + 1) return 'تحتاجه في ${p.pos.label}: عمق التشكيلة قليل في هذا المركز';
    final weakest = mine[starters - 1];
    if (p.overall > weakest.overall) return 'يناسب خطتك: سيدخل التشكيلة الأساسية بدل ${weakest.name} (${weakest.overall})';
    if (p.overall >= mine[min(starters, mine.length - 1)].overall) return 'بديل جيد في ${p.pos.label} يعزّز عمق التشكيلة';
    return 'أقل من مستوى لاعبيك الأساسيين في ${p.pos.label}';
  }

  void _offerSheet(BuildContext context, Player p) {
    final year = GameCalendar.seasonStart(gs.season).year + p.contract;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final watched = gs.watch.contains(p.id);
        final bars = p.pos == Pos.gk ? [('الحراسة', p.gk), ('الإمكانات', p.potential)] : [('الهجوم', p.atk), ('التمرير', p.pas), ('الدفاع', p.def), ('الإمكانات', p.potential)];
        Widget box(String l, String v, {Color? c}) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: c)),
                  const SizedBox(height: 2),
                  Text(l, style: const TextStyle(color: kMuted, fontSize: 11.5)),
                ]),
              ),
            );
        void snack(String? err, String ok) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? ok)));
        return Container(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(color: kBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 48, height: 5, decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 14),
            Row(children: [
              playerFace(p, 68, ring: posColor(p.pos), ringWidth: 2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    if (p.nat != null && p.nat!.isNotEmpty) FlagBadge(p.nat!, size: 18),
                    if (p.club != null) Text(p.club!, style: const TextStyle(color: kMuted)),
                    const Text('•', style: TextStyle(color: kMuted)),
                    Text(p.pos.label, style: const TextStyle(color: kMuted)),
                    const Text('•', style: TextStyle(color: kMuted)),
                    Text('${p.age} سنة', style: const TextStyle(color: kMuted)),
                  ]),
                ]),
              ),
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: ratingColor(p.overall), borderRadius: BorderRadius.circular(14)),
                child: Unfilter(child: Text('${p.overall}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24))),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              box('السعر المطلوب', money(gs.buyPrice(p)), c: kPrimary),
              box('الراتب/أسبوع', wageK(p.wage)),
              box('نهاية العقد', '$year'),
              box('القيمة السوقية', money(p.value), c: _okGreen),
            ]),
            const SizedBox(height: 14),
            for (final b in bars)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  SizedBox(width: 30, child: Text('${b.$2}', style: const TextStyle(fontWeight: FontWeight.w900))),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: (b.$2 / 100).clamp(0.0, 1.0).toDouble(), minHeight: 8, backgroundColor: kCard2, color: b.$2 >= 80 ? _okGreen : const Color(0xFF3B82F6)))),
                  const SizedBox(width: 12),
                  SizedBox(width: 70, child: Text(b.$1, textAlign: TextAlign.end, style: const TextStyle(color: kMuted, fontSize: 14))),
                ]),
              ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF3D0), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.star_border_rounded, color: Color(0xFFD99A1C)),
                const SizedBox(width: 8),
                Expanded(child: Text(_fit(p), style: const TextStyle(color: Color(0xFF6B4A00), fontWeight: FontWeight.w700, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              GestureDetector(
                onTap: () {
                  gs.toggleWatch(p);
                  set(() {});
                },
                child: Container(width: 54, height: 54, decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(16)), child: Icon(watched ? Icons.favorite : Icons.favorite_border, color: kPrimary)),
              ),
              const SizedBox(width: 10),
              if (!p.free) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final err = gs.loanIn(p);
                      Navigator.pop(ctx);
                      snack(err, 'تمت الإعارة ✅');
                    },
                    child: Container(height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: _sky, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x558EBCE6), offset: Offset(0, 3))]), child: const Unfilter(child: Text('إعارة', style: TextStyle(color: Color(0xFF15233D), fontWeight: FontWeight.w900, fontSize: 16)))),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    if (p.free) {
                      final err = gs.buy(p);
                      snack(err, 'تم التوقيع ✅');
                    } else {
                      showNegotiation(context, gs, p);
                    }
                  },
                  child: Container(height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x66C2412A), offset: Offset(0, 3))]), child: Unfilter(child: Text(p.free ? 'توقيع حر' : 'تقديم عرض', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)))),
                ),
              ),
            ]),
          ]),
        );
      }),
    );
  }

  // ───────── لوحة التصفية ─────────
  void _filterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        void both(VoidCallback fn) {
          fn();
          set(() {});
          setState(() {});
        }
        final count = gs.market.where(_pass).length;
        Widget sec(String t) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)));
        Widget pill(String label, bool sel, VoidCallback on) => GestureDetector(
              onTap: () => both(on),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(color: sel ? kNavy : kCard2, borderRadius: BorderRadius.circular(22)),
                child: sel ? Unfilter(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))) : Text(label, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800)),
              ),
            );
        Widget range(String title, String label, RangeValues v, double mn, double mx, ValueChanged<RangeValues> on, String lo, String hi) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(label, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 17)),
                const Spacer(),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ]),
              SliderTheme(
                data: SliderTheme.of(ctx).copyWith(activeTrackColor: kPrimary, inactiveTrackColor: kCard2, thumbColor: Colors.white, overlayColor: kPrimary.withOpacity(0.12), rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 12)),
                child: RangeSlider(values: v, min: mn, max: mx, onChanged: (r) => both(() => on(r))),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [Text(lo, style: const TextStyle(color: kMuted)), const Spacer(), Text(hi, style: const TextStyle(color: kMuted))])),
            ]);
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
          padding: EdgeInsets.fromLTRB(18, 10, 18, 14 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(color: kBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 48, height: 5, decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 12),
            Row(children: [
              const Text('تصفية اللاعبين', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21)),
              const Spacer(),
              GestureDetector(onTap: () => both(f.reset), child: const Text('إعادة ضبط', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900))),
            ]),
            Flexible(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  sec('المركز'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    pill('الكل', f.pos.isEmpty, () => f.pos = {}),
                    for (final p in Pos.values)
                      pill(p.plural, f.pos.contains(p), () {
                        f.pos = {...f.pos};
                        f.pos.contains(p) ? f.pos.remove(p) : f.pos.add(p);
                      }),
                  ]),
                  sec('نوع الصفقة'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    pill('شراء', f.buy, () => f.buy = !f.buy),
                    pill('إعارة', f.loan, () => f.loan = !f.loan),
                    pill('لاعب حر', f.free, () => f.free = !f.free),
                  ]),
                  const SizedBox(height: 6),
                  range('العمر', '${f.age.start.round()} – ${f.age.end.round()}', f.age, 16, 40, (r) => f.age = RangeValues(r.start.roundToDouble(), r.end.roundToDouble()), '16', '40'),
                  range('التقييم', '${f.rate.start.round()} – ${f.rate.end.round()}', f.rate, 50, 99, (r) => f.rate = RangeValues(r.start.roundToDouble(), r.end.roundToDouble()), '50', '99'),
                  range('السعر', '\$${f.price.start.round()}M – ${f.price.end >= 100 ? '+\$100M' : '\$${f.price.end.round()}M'}', f.price, 0, 100, (r) => f.price = RangeValues(r.start.roundToDouble(), r.end.roundToDouble()), '\$0', '\$100M'),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            GradientButton(label: 'عرض $count لاعبًا', onPressed: () => Navigator.pop(ctx)),
          ]),
        );
      }),
    );
  }

  // ───────── عروضي ─────────
  Widget _mine(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 24), children: [
      const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('العروض الواردة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
      ..._offers(context),
      const SizedBox(height: 16),
      const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('سجل الصفقات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
      Panel(
        child: gs.oplog.isEmpty
            ? const EmptyState(icon: Icons.history_rounded, title: 'لا سجل بعد', subtitle: 'تظهر هنا صفقاتك وعمليات الشراء والبيع والإعارة.')
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final l in gs.oplog.take(40)) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(l, style: const TextStyle(fontSize: 13.5)))]),
      ),
    ]);
  }

  List<Widget> _offers(BuildContext context) {
    if (gs.offers.isEmpty) {
      return const [Panel(child: EmptyState(icon: Icons.mark_email_unread_outlined, title: 'لا عروض حالياً', subtitle: 'اعرض لاعبين للبيع لزيادة احتمال وصول العروض.'))];
    }
    return [
      for (final Offer o in List<Offer>.of(gs.offers))
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              playerFace(o.player, 52, ring: posColor(o.player.pos), ringWidth: 2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${o.club} يريد ${o.player.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text('العرض ${money(o.amount)} • القيمة ${money(o.player.value)} • ينتهي بعد ${o.weeksLeft} جولات', style: const TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final ok = await confirmDialog(context,
                        title: 'قبول عرض ${o.club}؟',
                        body: 'ستبيع ${o.player.name} مقابل ${money(o.amount)} (قيمته السوقية ${money(o.player.value)}).',
                        confirm: 'قبول وبيع',
                        danger: true);
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
