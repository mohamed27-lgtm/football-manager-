import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'cup_tree.dart';
import 'cups.dart';
import 'flags.dart';
import 'game_state.dart';
import 'models.dart';
import 'national_screen.dart';
import 'scorers_screen.dart';
import 'world.dart';
import 'world_screens.dart';
import 'widgets.dart';

const _kGreen = Color(0xFF1FA58A);
const _kRed = Color(0xFFE5533D);
const _kPurple = Color(0xFF6A6FC4);
const _kOrange = Color(0xFFF5A524);

/// صفحة المسابقات: اختيار البطولة ← الدوري/الكأس/المجموعات/مرحلة الدوري/الشجرة
class CompetitionsView extends StatefulWidget {
  final GameState gs;
  const CompetitionsView({super.key, required this.gs});
  @override
  State<CompetitionsView> createState() => _CompetitionsViewState();
}

class _Comp {
  final String id, title;
  final IconData icon;
  final Color color;
  final Cup? cup;
  const _Comp(this.id, this.title, this.icon, this.color, [this.cup]);
}

class _CompetitionsViewState extends State<CompetitionsView> {
  String? sel; // null = صفحة اختيار البطولة
  Map<String, int?> _barLogos = {};
  int sub = 0; // 0 جدول/مجموعات، 1 شجرة
  GameState get gs => widget.gs;

  List<_Comp> get comps => [
        _Comp('league', gs.leagueName, Icons.emoji_events_rounded, const Color(0xFFE5533D)),
        if (gs.domestic != null) _Comp('dom', 'الكأس المحلية', Icons.emoji_events_rounded, const Color(0xFFE6A11D), gs.domestic),
        if (gs.continental != null) _Comp('con', gs.continental!.name, Icons.emoji_events_rounded, const Color(0xFF2F5FB4), gs.continental),
        if (gs.europa != null) _Comp('uel', gs.europa!.name, Icons.emoji_events_rounded, const Color(0xFFE8841C), gs.europa),
        if (gs.conference != null) _Comp('uecl', gs.conference!.name, Icons.emoji_events_rounded, _kGreen, gs.conference),
        if (gs.superCup != null) _Comp('sup', 'كأس السوبر', Icons.emoji_events_rounded, _kPurple, gs.superCup),
        if (gs.upper.isNotEmpty && gs.upperName.isNotEmpty) _Comp('up', gs.upperName, Icons.emoji_events_rounded, const Color(0xFF1FA58A)),
        if (gs.lower.isNotEmpty && gs.lowerName.isNotEmpty) _Comp('lo', gs.lowerName, Icons.emoji_events_rounded, const Color(0xFF6A6FC4)),
        if (gs.ic != null) _Comp('ic', gs.ic!.name, Icons.emoji_events_rounded, const Color(0xFFA6812E), gs.ic),
        if (gs.cwc != null) _Comp('cwc', gs.cwc!.name, Icons.emoji_events_rounded, const Color(0xFFE6B422), gs.cwc),
      ];

  void _open(String id) => setState(() {
        sel = id;
        sub = 0;
      });

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ───────── رأس فرعي: اسم الصفحة + زر العودة لاختيار البطولة ─────────
  Widget _subHeader(String title, Widget lead) => Container(
        color: kCard,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(children: [
          lead,
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          GestureDetector(
            onTap: () => setState(() => sel = null),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kPrimary, width: 2)),
              child: const Icon(Icons.public_rounded, color: kPrimary),
            ),
          ),
        ]),
      );

  /// شعار البطولة الحقيقي إن توفّر (مُنزَّل أو مضمّن) وإلا الكأس الملوّنة
  Widget _logoChip(int? id, Color c, {double size = 46}) {
    if (id == null) return _trophyChip(c, size: size);
    return Unfilter(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white, border: Border.all(color: const Color(0x1F000000))),
        child: CompLogo(id, fallback: Icons.emoji_events_outlined, color: c, size: size * 0.76, unfilter: false),
      ),
    );
  }

  int? _logoOf(String key) {
    final cf = confedOf(gs.country);
    switch (key) {
      case 'league':
        return gs.leagueId == 0 ? null : gs.leagueId;
      case 'dom':
        return kDomesticCupId[gs.leagueId];
      case 'con':
        return kConfedCupLogoId[cf.id];
      case 'uel':
        return kConfedSecondLogoId[cf.id];
      case 'uecl':
        return cf.id == 'uefa' ? 848 : null;
      case 'sup':
        return kSuperCupId[gs.leagueId] ?? 531;
      case 'cwc':
        return 15;
    }
    return null;
  }

  Widget _trophyChip(Color c, {double size = 46}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.withOpacity(0.75), c])),
        child: Icon(Icons.emoji_events_outlined, color: Colors.white, size: size * 0.5),
      );

  // ───────── صفحة اختيار البطولة ─────────
  Widget _hub() {
    final cf = confedOf(gs.country);
    bool inCup(Cup? c) => c != null && !c.done && (c.alive.contains(gs.user.id) || c.byes.contains(gs.user.id));
    final club = <(String, Color, String?, bool)>[
      (cf.cl, const Color(0xFF2F5FB4), 'con', inCup(gs.continental)),
      if (gs.europa != null) (gs.europa!.name, const Color(0xFFE8841C), 'uel', inCup(gs.europa)),
      if (gs.conference != null) (gs.conference!.name, _kGreen, 'uecl', inCup(gs.conference)),
      if (gs.superCup != null) ('كأس السوبر', _kPurple, 'sup', inCup(gs.superCup)),
      ('كأس العالم للأندية', const Color(0xFFE6B422), 'cwc', inCup(gs.cwc)),
      ('كأس إنتركونتيننتال', const Color(0xFFA6812E), 'ic', inCup(gs.ic)),
    ];
    final nations = <String>[
      if (gs.country.isNotEmpty) gs.country,
      ...kContinentalOrder.where((c) => c != gs.country).take(7),
    ];
    Widget card(String t, Widget lead, {bool mark = false, bool hi = false, required VoidCallback onTap}) => GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: hi ? _kGreen.withOpacity(0.18) : kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
            child: Row(children: [
              lead,
              const SizedBox(width: 10),
              Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
              if (mark) Container(width: 10, height: 10, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
            ]),
          ),
        );
    Widget grid(List<Widget> l) => GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: l,
        );
    Widget head(String t, {bool dot = false}) => Padding(
          padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
          child: Row(children: [
            Text(t, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800, fontSize: 13)),
            const Spacer(),
            if (dot) ...[
              Container(width: 9, height: 9, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('تشارك فيها', style: TextStyle(color: kMuted, fontSize: 12)),
            ],
          ]),
        );
    return Column(children: [
      _subHeaderPlain('اختر البطولة'),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(14, 0, 14, 20), children: [
          head('بطولات الأندية', dot: true),
          grid([
            for (final e in club)
              card(e.$1, _logoChip(_logoOf(e.$3!), e.$2, size: 38), mark: e.$4, hi: e.$3 == 'sup' && e.$4, onTap: () => _open(e.$3!)),
          ]),
          head('دوريات الدول'),
          grid([
            for (final n in nations)
              card(n, SizedBox(width: 46, child: FlagBadge(n, size: 34)), mark: n == gs.country, onTap: () {
                if (n == gs.country) {
                  _open('league');
                } else {
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CountryScreen(gs: gs, country: n)));
                }
              }),
          ]),
          const SizedBox(height: 14),
          head('بطولات المنتخبات'),
          grid([
            for (final d in kNatTours)
              card(d.name, _logoChip(kNatTourLogoId[d.key], const Color(0xFF2F5FB4), size: 38), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NatTourScreen(gs: gs, tourKey: d.key)))),
          ]),
        ]),
      ),
    ]);
  }

  Widget _subHeaderPlain(String t) => Container(
        color: kCard,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(children: [
          Expanded(child: Text(t, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kPrimary, width: 2)),
            child: const Icon(Icons.public_rounded, color: kPrimary),
          ),
        ]),
      );

  // ───────── شريط البطولات / الأقسام ─────────
  Widget _chipBar(List<(String, String, IconData, Color, bool, VoidCallback)> items) => SizedBox(
        height: 84,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), children: [
          for (final it in items)
            GestureDetector(
              onTap: it.$6,
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                padding: EdgeInsets.symmetric(horizontal: it.$5 ? 12 : 10),
                width: it.$5 ? null : 58,
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: it.$5 ? kPrimary : kLine, width: it.$5 ? 2 : 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: it.$4.withOpacity(it.$5 ? 1 : 0.0)),
                    child: _barLogos[it.$1] != null
                        ? Padding(padding: const EdgeInsets.all(3), child: Unfilter(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.all(3), child: CompLogo(_barLogos[it.$1], fallback: it.$3, color: it.$4, size: 28, unfilter: false))))
                        : Icon(it.$3, color: it.$5 ? Colors.white : it.$4, size: 24),
                  ),
                  if (it.$5) ...[
                    const SizedBox(width: 10),
                    Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(it.$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                      Text(it.$2, style: const TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ],
                ]),
              ),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          if (sel == null) return _hub();
          final cs = comps;
          final cur = cs.where((c) => c.id == sel).toList();
          final c = cur.isEmpty ? null : cur.first;
          // بطولات بلا بيانات (كأس العالم للأندية / إنتركونتيننتال)
          if ((sel == 'cwc' && gs.cwc == null) || (sel == 'ic' && gs.ic == null)) return _placeholder(sel == 'cwc');
          if (c == null) return _hub();
          final cup = c.cup;
          final Widget body;
          final String chipSub;
          if (c.id == 'league') {
            body = _leagueBody();
            chipSub = 'الجولة ${(gs.week + (gs.seasonOver ? 0 : 1)).clamp(1, gs.rounds.length).toInt()} من ${gs.rounds.length}';
          } else if (c.id == 'up' || c.id == 'lo') {
            body = _divBody(c.id == 'up' ? gs.upper : gs.lower, c.id == 'up');
            chipSub = c.id == 'up' ? 'الدرجة الأعلى' : 'الدرجة الأدنى';
          } else if (c.id == 'sup') {
            body = _superBody(cup!);
            chipSub = cup.done ? 'انتهت' : cup.roundName;
          } else if (cup!.kind > 0) {
            final inLp = cup.inGroups;
            if (sub == 0) {
              body = cup.kind == 2 ? _swissBody(cup) : _groupsBody(cup);
              chipSub = inLp ? (cup.kind == 2 ? 'المباراة ${cup.round + 1} من ${cup.lpRounds}' : 'الجولة ${cup.round + 1} من ${cup.lpRounds}') : 'انتهت';
            } else {
              body = _bracketBody(cup);
              chipSub = cup.kind == 2 ? 'الملحق من دور الـ16' : (cup.groups.length > 4 ? 'من دور الـ16' : 'من ربع النهائي');
            }
          } else {
            body = _bracketBody(cup);
            chipSub = cup.done ? 'انتهت' : cup.roundName;
          }
          final bar = <(String, String, IconData, Color, bool, VoidCallback)>[];
          if (cup != null && cup.kind > 0 && c.id != 'sup') {
            bar
              ..add((cup.kind == 2 ? 'مرحلة الدوري' : 'مرحلة المجموعات', chipSub, Icons.emoji_events_outlined, c.color, sub == 0, () => setState(() => sub = 0)))
              ..add(('الأدوار الإقصائية', chipSub, Icons.account_tree_outlined, c.color, sub == 1, () => setState(() => sub = 1)));
            // العنوان المعروض في الشريحة المحددة
            bar[0] = (bar[0].$1, cup.inGroups ? (cup.kind == 2 ? 'المباراة ${cup.round + 1} من ${cup.lpRounds}' : 'الجولة ${cup.round + 1} من ${cup.lpRounds}') : 'انتهت', bar[0].$3, c.color, sub == 0, bar[0].$6);
            bar[1] = (bar[1].$1, cup.kind == 2 ? 'الملحق ثم دور الـ16' : (cup.groups.length > 4 ? 'من دور الـ16' : 'من ربع النهائي'), bar[1].$3, c.color, sub == 1, bar[1].$6);
          } else {
            const domIds = ['league', 'dom', 'sup', 'up', 'lo'];
            final isDom = domIds.contains(c.id);
            final shownCs = [for (final o in cs) if (domIds.contains(o.id) == isDom) o];
            shownCs.sort((a, b) => (isDom ? domIds : const ['con', 'uel', 'uecl', 'cwc', 'ic']).indexOf(a.id).compareTo((isDom ? domIds : const ['con', 'uel', 'uecl', 'cwc', 'ic']).indexOf(b.id)));
            _barLogos = {for (final o in shownCs) o.title: _logoOf(o.id)};
            for (final o in shownCs) {
              bar.add((o.title, o.id == sel ? chipSub : '', Icons.emoji_events_outlined, o.color, o.id == sel, () => setState(() {
                    sel = o.id;
                    sub = 0;
                  })));
            }
          }
          final lead = c.id == 'league' && gs.country.isNotEmpty ? FlagBadge(gs.country, size: 40) : _logoChip(_logoOf(c.id), c.color, size: 44);
          final title = c.id == 'league' ? (gs.country.isEmpty ? gs.leagueName : gs.country) : c.title;
          return Column(children: [
            _subHeader(title, lead),
            _chipBar(bar),
            Expanded(child: body),
            if (c.id != 'ic' || gs.ic != null) _statsStrip(c.id, c.id == 'league' ? gs.leagueName : c.title),
          ]);
        },
      );

  // ───────── درجات الدوري الأخرى ─────────
  Widget _divBody(List<Team> teams, bool upper) {
    final l = [...teams]..sort((a, b) => b.reputation.compareTo(a.reputation));
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 14), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
        child: Text(upper ? 'أندية الدرجة الأعلى — يصعد إليها أبطال دوريك بنهاية الموسم' : 'أندية الدرجة الأدنى — يهبط إليها أصحاب المراكز الأخيرة', style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.5)),
      ),
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < l.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: kLine))),
              child: Row(children: [
                SizedBox(width: 26, child: Text('${i + 1}', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800))),
                teamBadge(l[i], size: 30),
                const SizedBox(width: 10),
                Expanded(child: Text(l[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                Text('${l[i].reputation}', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800)),
              ]),
            ),
        ]),
      ),
    ]);
  }

  // ───────── دوري الدولة ─────────
  Widget _leagueBody() {
    final table = gs.table;
    final zones = gs.qualZones();
    final reg = gs.lower.isNotEmpty && table.length >= 12 ? 3 : 0;
    final cf = confedOf(gs.country);
    final names = [cf.swiss ? 'دوري الأبطال' : cf.cl, cf.swiss ? 'الدوري الأوروبي' : cf.second, 'دوري المؤتمر'];
    final present = <int>{...zones.values};
    return ListView(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), children: [
      _legend([
        for (final z in [0, 1, 2])
          if (present.contains(z)) (_zoneColor(z), names[z]),
        if (reg > 0) (_kRed, 'الهبوط'),
      ]),
      _tableHead(),
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < table.length; i++)
            _row(
              rank: i + 1,
              team: table[i],
              form: gs.formOf(table[i]),
              nums: [table[i].played, table[i].won, table[i].drawn, table[i].lost],
              gd: table[i].gd,
              pts: table[i].points,
              tint: i >= table.length - reg && reg > 0 ? _kRed : (zones[table[i].id] == null ? null : _zoneColor(zones[table[i].id]!)),
              me: table[i] == gs.user,
            ),
        ]),
      ),
    ]);
  }

  Color _zoneColor(int z) => z == 0 ? _kGreen : (z == 1 ? _kPurple : _kOrange);

  Widget _legend(List<(Color, String)> items) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Wrap(spacing: 14, runSpacing: 4, children: [
          for (final e in items)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 18, height: 18, decoration: BoxDecoration(color: e.$1.withOpacity(0.22), borderRadius: BorderRadius.circular(5))),
              const SizedBox(width: 6),
              Text(e.$2, style: const TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
        ]),
      );

  Widget _hc(String t, double w) => SizedBox(width: w, child: Text(t, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800, fontSize: 13)));

  Widget _tableHead() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
        child: Row(children: [
          const Spacer(),
          _hc('ل', 28), _hc('ف', 28), _hc('ت', 28), _hc('خ', 28), _hc('فا', 38), _hc('ن', 38),
        ]),
      );

  Widget _formIcon(String r) {
    final c = r == 'W' ? _kGreen : (r == 'L' ? _kRed : const Color(0xFF9AA1B5));
    return Container(
      width: 17,
      height: 17,
      margin: const EdgeInsets.only(left: 3),
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      child: Icon(r == 'W' ? Icons.check_rounded : (r == 'L' ? Icons.close_rounded : Icons.remove_rounded), size: 12, color: Colors.white),
    );
  }

  Widget _n(String t, double w, {bool bold = false, Color? c}) => SizedBox(
        width: w,
        child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w900 : FontWeight.w500, color: c ?? (bold ? null : kMuted))),
      );

  Widget _row({required int rank, required Team team, required List<String> form, required List<int> nums, required int gd, required int pts, Color? tint, bool me = false}) {
    final last = form.length > 5 ? form.sublist(form.length - 5) : form;
    return Container(
      decoration: BoxDecoration(
        color: tint?.withOpacity(0.2),
        border: Border(right: BorderSide(width: 4, color: me ? kPrimary : Colors.transparent), bottom: const BorderSide(color: kLine, width: 0.6)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 7, 8, 7),
      child: Row(children: [
        SizedBox(width: 22, child: Text('$rank', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
        teamBadge(team, size: 34),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(team.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: me ? kPrimary : null)),
            const SizedBox(height: 3),
            Row(children: [for (final r in last) _formIcon(r)]),
          ]),
        ),
        for (final v in nums) _n('$v', 28),
        _n(gd > 0 ? '+$gd' : '$gd', 38),
        _n('$pts', 38, bold: true),
      ]),
    );
  }

  List<String> _cupForm(Cup c, int id) {
    final out = <String>[];
    for (final t in c.gdone) {
      if (t.home != id && t.away != id) continue;
      final mine = t.home == id ? t.hg! : t.ag!;
      final opp = t.home == id ? t.ag! : t.hg!;
      out.add(mine > opp ? 'W' : (mine < opp ? 'L' : 'D'));
    }
    return out;
  }

  // ───────── مرحلة الدوري (36 فريقاً) ─────────
  Widget _swissBody(Cup c) {
    final tb = groupTable(c, c.groups[0]);
    final done = !c.inGroups;
    return ListView(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), children: [
      _legend([(_kGreen, 'دور الـ16 مباشرة'), (_kPurple, 'الملحق')]),
      _tableHead(),
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < tb.length; i++) ...[
            if (i == 8) _cutLine('خط التأهل المباشر', _kGreen),
            if (i == 24) _cutLine('خط الإقصاء', _kRed),
            _row(
              rank: i + 1,
              team: gs.team(tb[i].id),
              form: _cupForm(c, tb[i].id),
              nums: [tb[i].p, tb[i].w, tb[i].d, tb[i].l],
              gd: tb[i].gd,
              pts: tb[i].pts,
              tint: i < 8 ? _kGreen : (i < 24 ? _kPurple : null),
              me: tb[i].id == gs.user.id,
            ),
          ],
        ]),
      ),
      if (done) const Padding(padding: EdgeInsets.only(top: 10), child: Text('انتهت مرحلة الدوري — تابع الأدوار الإقصائية من الشريحة الثانية', style: TextStyle(color: kMuted, fontSize: 12))),
    ]);
  }

  Widget _cutLine(String t, Color c) => Container(
        color: c.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        child: Row(children: [
          Expanded(child: Container(height: 1, color: c.withOpacity(0.5))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12))),
          Expanded(child: Container(height: 1, color: c.withOpacity(0.5))),
        ]),
      );

  // ───────── دور المجموعات ─────────
  Widget _groupsBody(Cup c) {
    Widget card(int gi) {
      final tb = groupTable(c, c.groups[gi]);
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Unfilter(
              child: Container(
                color: const Color(0xFF15233D),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(children: [
                  Text('المجموعة ${String.fromCharCode(65 + gi)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  const Spacer(),
                  const Text('نقاط', style: TextStyle(color: Color(0xFF9AA6BD), fontSize: 11)),
                ]),
              ),
            ),
            for (var i = 0; i < tb.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                decoration: BoxDecoration(color: i < 2 ? _kGreen.withOpacity(0.2) : null, border: tb[i].id == gs.user.id ? const Border(right: BorderSide(color: kPrimary, width: 4)) : null),
                child: Row(children: [
                  SizedBox(width: 14, child: Text('${i + 1}', style: const TextStyle(color: kMuted, fontSize: 12))),
                  teamBadge(gs.team(tb[i].id), size: 30),
                  const SizedBox(width: 6),
                  Expanded(child: Text(gs.team(tb[i].id).name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: tb[i].id == gs.user.id ? kPrimary : null))),
                  Text('${tb[i].pts}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ]),
              ),
          ]),
        ),
      );
    }

    return ListView(padding: const EdgeInsets.fromLTRB(9, 0, 9, 12), children: [
      Padding(padding: const EdgeInsets.fromLTRB(6, 4, 6, 8), child: _legend([(_kGreen, 'يتأهل لربع النهائي')])),
      for (var r = 0; r + 1 < c.groups.length; r += 2) Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [card(r), card(r + 1)])),
    ]);
  }

  // ───────── شجرة الأدوار الإقصائية ─────────
  Widget _bracketBody(Cup c) {
    final waiting = c.inGroups && c.kind > 0;
    return ListView(padding: const EdgeInsets.fromLTRB(10, 0, 10, 12), children: [
      if (waiting)
        Container(
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _kOrange.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFFA06A00), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(c.kind == 2 ? 'تُحدَّد المواجهات بعد انتهاء مرحلة الدوري' : 'تُحدَّد المواجهات بعد انتهاء دور المجموعات', style: const TextStyle(color: Color(0xFFA06A00), fontWeight: FontWeight.w800))),
          ]),
        ),
      CupTree(gs: gs, cup: c),
      if (!c.done && !c.inGroups && c.ties.isNotEmpty) ...[
        sectionTitle('قرعة ${c.roundName}'),
        Panel(
          child: Column(children: [
            for (final t in c.ties)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  teamBadge(gs.team(t.home), size: 24),
                  const SizedBox(width: 8),
                  Expanded(child: Text(gs.team(t.home).name, style: TextStyle(fontWeight: t.home == gs.user.id ? FontWeight.w900 : FontWeight.w500))),
                  Text(t.played ? '${t.hg} - ${t.ag}' : 'ضد', style: const TextStyle(color: kMuted)),
                  Expanded(child: Text(gs.team(t.away).name, textAlign: TextAlign.end, style: TextStyle(fontWeight: t.away == gs.user.id ? FontWeight.w900 : FontWeight.w500))),
                  const SizedBox(width: 8),
                  teamBadge(gs.team(t.away), size: 24),
                ]),
              ),
            for (final b in c.byes)
              Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [teamBadge(gs.team(b), size: 22), const SizedBox(width: 8), Text('${gs.team(b).name} — تأهل مباشرة', style: const TextStyle(color: kMuted, fontSize: 12.5))])),
          ]),
        ),
      ],
    ]);
  }

  // ───────── كأس السوبر ─────────
  Widget _superBody(Cup c) {
    Team? champ = c.champion == null ? null : gs.team(c.champion!);
    String? score;
    Team? a, b;
    if (c.ties.isNotEmpty) {
      final t = c.ties.first;
      a = gs.team(t.home);
      b = gs.team(t.away);
      if (t.played) score = '${t.hg} - ${t.ag}';
    } else if (c.log.isNotEmpty) {
      score = null;
    }
    return ListView(padding: const EdgeInsets.all(14), children: [
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Column(children: [
            Text(champ == null ? 'المباراة النهائية' : 'البطل', style: const TextStyle(color: kMuted, fontSize: 13)),
            Text(champ?.name ?? (a != null ? '${a.name} × ${b!.name}' : '—'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kPrimary)),
          ]),
        ),
      ),
      const SizedBox(height: 22),
      if (champ != null) Center(child: teamBadge(champ, size: 150)),
      if (a != null && b != null) ...[
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          teamBadge(a, size: 64),
          const SizedBox(width: 18),
          Text(score ?? 'ضد', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(width: 18),
          teamBadge(b, size: 64),
        ]),
      ],
      const SizedBox(height: 26),
      Center(child: Icon(Icons.emoji_events_rounded, size: 150, color: const Color(0xFFE6B422).withOpacity(0.95))),
    ]);
  }

  // ───────── كأس العالم للأندية / إنتركونتيننتال ─────────
  Widget _placeholder(bool cwc) {
    final key = cwc ? 'cwc' : 'ic';
    final left = cwc ? ((3 - gs.season) % 4 + 4) % 4 : 0;
    final hist = [for (final h in gs.cupHist) if (h['k'] == key) h].reversed.toList();
    final color = cwc ? const Color(0xFFE6B422) : const Color(0xFFA6812E);
    final name = cwc ? 'كأس العالم للأندية' : 'كأس إنتركونتيننتال';
    return Column(children: [
      _subHeader(name, _logoChip(_logoOf(key), color)),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.emoji_events_rounded, color: color, size: 34),
                const SizedBox(width: 10),
                Expanded(child: Text(cwc ? (left == 0 ? 'تنطلق النسخة هذا الموسم' : 'النسخة القادمة بعد $left ${left == 1 ? 'موسم' : 'مواسم'}') : 'النسخة القادمة مع الموسم المقبل', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
              ]),
              const SizedBox(height: 10),
              Text(
                cwc
                    ? '32 نادياً: 12 من أوروبا، 6 من أمريكا الجنوبية، 4 من أفريقيا، 4 من آسيا، 5 من أمريكا الشمالية والوسطى، وناد من أوقيانوسيا. يتأهل أبطال الاتحادات في آخر 4 مواسم ثم الأعلى تصنيفاً (Elo). 8 مجموعات ثم أدوار إقصائية.'
                    : 'أبطال الاتحادات الستة: يدخل الأقوى تصنيفاً مباشرةً إلى نصف النهائي، ويلعب البقية دوراً أول ثم نصف النهائي والنهائي.',
                style: const TextStyle(color: kMuted, height: 1.6, fontSize: 13),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          const Text('الأبطال السابقون', style: TextStyle(color: kMuted, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (hist.isEmpty)
            Container(padding: const EdgeInsets.all(20), alignment: Alignment.center, decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)), child: const Text('لا توجد سجلات بعد — ستظهر النتائج هنا.', style: TextStyle(color: kMuted)))
          else
            Container(
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
              child: Column(children: [
                for (var i = 0; i < hist.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: kLine))),
                    child: Row(children: [
                      SizedBox(width: 56, child: Text('م${hist[i]['s']}', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800))),
                      Icon(Icons.emoji_events_rounded, color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${hist[i]['n']}', style: const TextStyle(fontWeight: FontWeight.w900))),
                      Text('الوصيف: ${hist[i]['r']}', style: const TextStyle(color: kMuted, fontSize: 11.5)),
                    ]),
                  ),
              ]),
            ),
        ]),
      ),
    ]);
  }

  // ───────── شريط الهدّاف وصانع الألعاب ─────────
  /// أفضل هدّاف وصانع ألعاب في البطولة الحالية؛ الضغط يفتح القائمة الكاملة
  Widget _statsStrip(String key, String title) {
    final stats = gs.compStats[key] ?? const <int, List<int>>{};
    final players = <int, Player>{};
    final clubs = <String, Team>{};
    for (final t in [...gs.teams, ...gs.upper, ...gs.lower, ...gs.foreign.values]) {
      clubs[t.name] = t;
      for (final p in t.squad) {
        players[p.id] = p;
      }
    }
    (int, List<int>)? best(int i) {
      (int, List<int>)? b;
      for (final e in stats.entries) {
        if (e.value[i] > 0 && (b == null || e.value[i] > b.$2[i] || (e.value[i] == b.$2[i] && e.value[1 - i] > b.$2[1 - i]))) b = (e.key, e.value);
      }
      return b;
    }

    void open(int tab) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ScorersScreen(gs: gs, compKey: key, title: title, initialTab: tab)));

    Widget card(String label, (int, List<int>)? b, int i, Color c, IconData ic) {
      final p = b == null ? null : players[b.$1];
      final nm = b == null ? null : gs.compNames[b.$1];
      final t = nm == null ? null : clubs[nm[1]];
      return Expanded(
        child: GestureDetector(
          onTap: () => open(i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border(bottom: BorderSide(color: c, width: 3))),
            child: Row(children: [
              if (p != null) playerFace(p, 44, ring: c, ringWidth: 2) else Container(width: 44, height: 44, decoration: BoxDecoration(color: kCard2, shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: kMuted)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: const TextStyle(color: kMuted, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  Text(p?.name ?? nm?[0] ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  if (nm != null) Row(children: [if (t != null) ...[teamBadge(t, size: 16), const SizedBox(width: 4)], Expanded(child: Text(nm[1], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11)))]),
                ]),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(ic, color: c, size: 18),
                Text('${b?.$2[i] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ]),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
      child: Row(children: [
        card('الهدّاف', best(0), 0, kPrimary, Icons.sports_soccer_rounded),
        card('صانع الألعاب', best(1), 1, _kGreen, Icons.trending_flat_rounded),
      ]),
    );
  }
}
