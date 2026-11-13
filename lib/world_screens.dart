import 'package:flutter/material.dart' hide Text;
import 'game_state.dart';
import 'i18n.dart';
import 'widgets.dart';
import 'flags.dart';
import 'models.dart';
import 'cups.dart';
import 'world.dart';
import 'national_team_screen.dart';

/// دوريات العالم تُلعب آلياً: آخر النتائج وجداول كل الدوريات
class WorldLeaguesScreen extends StatelessWidget {
  final GameState gs;
  const WorldLeaguesScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دوريات العالم')),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final ls = gs.wLeagues;
          if (ls.isEmpty) {
            return const Center(child: EmptyState(icon: Icons.public_rounded, title: 'ستبدأ الدوريات مع أول جولة', subtitle: 'تُلعب كل دوريات العالم آلياً كل أسبوع.'));
          }
          return ListView(padding: const EdgeInsets.all(14), children: [
            if (gs.worldFeed.isNotEmpty) ...[
              const Text('آخر نتائج الدوريات الكبرى', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 8),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(children: [
                  for (final r in gs.worldFeed.take(12))
                    Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Text(r, style: const TextStyle(fontSize: 12.5)))),
                ]),
              ),
              const SizedBox(height: 14),
            ],
            const Text('الدوريات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 8),
            for (final l in ls)
              Builder(builder: (_) {
                final o = l.order;
                final lead = l.names[o.first];
                final pts = l.st[o.first][6];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorldTableScreen(gs: gs, league: l))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                          Text(l.country, style: const TextStyle(color: kMuted, fontSize: 12)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(l.round == 0 ? '—' : lead, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        Text('جولة ${l.round}/${l.totalRounds}${l.round == 0 ? '' : ' • $pts نقطة'}', style: const TextStyle(color: kMuted, fontSize: 11.5)),
                      ]),
                      const Icon(Icons.chevron_left, color: kMuted),
                    ]),
                  ),
                );
              }),
          ]);
        },
      ),
    );
  }
}

class WorldTableScreen extends StatelessWidget {
  final GameState gs;
  final WorldLeague league;
  const WorldTableScreen({super.key, required this.gs, required this.league});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(league.name)),
        body: ListView(padding: const EdgeInsets.all(14), children: worldLeagueBody(context, gs, league)),
      );
}

/// صفحة دوري عالمي كاملة: شعار الدوري والكأس، جدول بالشعارات ومناطق التأهل والصعود والهبوط، الهدافون، الحركة بين الدرجات والأبطال
List<Widget> worldLeagueBody(BuildContext context, GameState gs, WorldLeague l) {
  const clC = Color(0xFF1B8F6A), elC = Color(0xFF6B4FBB), relC = Color(0xFFC62828), upC = Color(0xFF1B8F6A);
  final o = l.order;
  final div = worldDivOf(l);
  final sameC = gs.wLeagues.where((x) => x.country == l.country && x.id != l.id).toList();
  final upper = sameC.where((x) => worldDivOf(x) == div - 1).toList();
  final lower = sameC.where((x) => worldDivOf(x) == div + 1).toList();
  final relK = lower.isEmpty ? 0 : worldMoveCount(l, lower.first);
  final upK = upper.isEmpty ? 0 : worldMoveCount(upper.first, l);
  final cl = div == 1 ? (l.n >= 18 ? 4 : l.n >= 14 ? 2 : 1) : 0;
  final el = div == 1 && l.n >= 12 ? (l.n >= 16 ? 2 : 1) : 0;
  Color? zone(int i) {
    if (i < upK) return upC;
    if (i < cl) return clC;
    if (i < cl + el) return elC;
    if (relK > 0 && i >= l.n - relK) return relC;
    return null;
  }

  Widget c(String t, {bool bold = false, double w = 28}) => SizedBox(
        width: w,
        child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
      );

  final cupId = kDomesticCupId[l.id];
  final champs = [
    for (final e in gs.worldChamps.entries)
      if (e.key.startsWith('${l.id}|')) (int.parse(e.key.split('|')[1]), e.value)
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  final pairIds = {l.id, ...sameC.map((x) => x.id)};
  final moves = [
    for (final e in gs.worldMoves.entries)
      if (pairIds.contains(int.tryParse(e.key.split('|').first))) e
  ]..sort((a, b) => int.parse(b.key.split('|')[1]).compareTo(int.parse(a.key.split('|')[1])));
  final teams = gs.wTeams[l.id];
  final scorers = <(Player, String)>[
    if (teams != null)
      for (final e in teams.entries)
        for (final p in e.value.squad)
          if (p.goals > 0) (p, e.key)
  ]..sort((a, b) => b.$1.goals != a.$1.goals ? b.$1.goals.compareTo(a.$1.goals) : b.$1.assists.compareTo(a.$1.assists));

  Widget logoBox(int? id, IconData fb, Color col) => Unfilter(
        child: Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x1F000000))),
          child: CompLogo(id, fallback: fb, color: col, size: 40, unfilter: false),
        ),
      );

  Widget clubRow(String name, {String? lead, Color? tint}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          if (lead != null) SizedBox(width: 26, child: Text(lead, style: TextStyle(color: tint ?? kMuted, fontWeight: FontWeight.w900))),
          teamBadge(gs.clubNamed(name), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
        ]),
      );

  return [
    // رأس: شعار الدوري والكأس
    Panel(
      child: Row(children: [
        logoBox(l.id, Icons.emoji_events_outlined, kPrimary),
        if (cupId != null) ...[const SizedBox(width: 8), logoBox(cupId, Icons.emoji_events, kGold)],
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 2),
            Row(children: [
              FlagBadge(l.country, size: 18),
              const SizedBox(width: 6),
              Text(l.country, style: const TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
            const SizedBox(height: 2),
            Text('الجولة ${l.round} من ${l.totalRounds}${div > 1 ? ' • الدرجة $div' : ''}', style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
        if (l.round > 0)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('المتصدر', style: TextStyle(color: kMuted, fontSize: 11)),
            teamBadge(gs.clubNamed(l.names[o.first]), size: 30),
          ]),
      ]),
    ),
    const SizedBox(height: 12),
    // الجدول
    Panel(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 24),
          const SizedBox(width: 26),
          const Expanded(child: Text('النادي', style: TextStyle(color: kMuted, fontSize: 12))),
          c('لعب'), c('ف'), c('ت'), c('خ'), c('فرق', w: 34), c('نقاط', w: 34),
        ]),
        const Divider(height: 12),
        for (var i = 0; i < o.length; i++)
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClubCabinetScreen(gs: gs, club: l.names[o[i]]))),
            child: Container(
              decoration: BoxDecoration(
                color: zone(i)?.withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border(right: BorderSide(width: 4, color: zone(i) ?? Colors.transparent)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(children: [
                SizedBox(width: 24, child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: i == 0 && l.round > 0 ? kGold : null))),
                teamBadge(gs.clubNamed(l.names[o[i]]), size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(l.names[o[i]], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                c('${l.st[o[i]][0]}'), c('${l.st[o[i]][1]}'), c('${l.st[o[i]][2]}'), c('${l.st[o[i]][3]}'),
                c('${l.st[o[i]][4] - l.st[o[i]][5]}', w: 34), c('${l.st[o[i]][6]}', bold: true, w: 34),
              ]),
            ),
          ),
      ]),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Wrap(spacing: 14, runSpacing: 4, children: [
        for (final e in [
          if (upK > 0) (upC, 'الصعود'),
          if (cl > 0) (clC, 'التأهل القاري'),
          if (el > 0) (elC, 'التصفيات القارية'),
          if (relK > 0) (relC, 'الهبوط'),
        ])
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: e.$1, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 5),
            Text(e.$2, style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
      ]),
    ),
    // الهدافون
    sectionTitle('الهدافون'),
    Panel(
      child: scorers.isEmpty
          ? const Text('لا أهداف مسجّلة بعد', style: TextStyle(color: kMuted))
          : Column(children: [
              for (final e in scorers.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    playerFace(e.$1, 34),
                    const SizedBox(width: 8),
                    teamBadge(gs.clubNamed(e.$2), size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${e.$1.name} • ${e.$2}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                    Text('⚽ ${e.$1.goals}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Text('🎯 ${e.$1.assists}', style: const TextStyle(color: kMuted)),
                  ]),
                ),
            ]),
    ),
    // الصعود والهبوط بين الدرجات
    if (moves.isNotEmpty) ...[
      sectionTitle('الصعود والهبوط'),
      for (final e in moves.take(2))
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('نهاية الموسم ${e.key.split('|')[1]}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
            const SizedBox(height: 4),
            for (final x in e.value.where((x) => x.startsWith('+'))) clubRow(x.substring(1), lead: '🔼'),
            for (final x in e.value.where((x) => x.startsWith('-'))) clubRow(x.substring(1), lead: '🔽'),
          ]),
        ),
    ],
    // الأبطال السابقون
    if (champs.isNotEmpty) ...[
      sectionTitle('الأبطال السابقون'),
      Panel(
        child: Column(children: [
          for (final e in champs)
            Row(children: [
              SizedBox(width: 64, child: Text('الموسم ${e.$1}', style: const TextStyle(color: kMuted, fontSize: 12.5))),
              Expanded(child: clubRow(e.$2, lead: '🏆')),
            ]),
        ]),
      ),
    ],
  ];
}

/// خزينة ألقاب أي نادٍ في العالم
class ClubCabinetScreen extends StatelessWidget {
  final GameState gs;
  final String club;
  const ClubCabinetScreen({super.key, required this.gs, required this.club});

  @override
  Widget build(BuildContext context) {
    final list = gs.clubHonours[gs.honourKey(club)] ?? const <String>[];
    final byComp = <String, List<int>>{};
    for (final h in list) {
      final p = h.split(' — الموسم ');
      byComp.putIfAbsent(p[0], () => []).add(int.tryParse(p.length > 1 ? p[1] : '') ?? 0);
    }
    final comps = byComp.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Scaffold(
      appBar: AppBar(title: Text(club)),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Panel(
          child: Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 12),
            Expanded(child: Text('${list.length} لقباً مسجّلاً', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
          ]),
        ),
        const SizedBox(height: 10),
        if (comps.isEmpty)
          const Panel(child: EmptyState(icon: Icons.emoji_events_outlined, title: 'الخزينة فارغة', subtitle: 'تُسجَّل الألقاب من هذا الموسم فصاعداً.'))
        else
          for (final c in comps)
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(c.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                  Text('${c.value.length}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: kGold)),
                ]),
                const SizedBox(height: 4),
                Text(([...c.value]..sort()).map((s) => 'م$s').join(' • '), style: const TextStyle(color: kMuted, fontSize: 12)),
              ]),
            ),
      ]),
    );
  }
}


/// صفحة دولة: شريط دوريات أفقي وجدول الدوري المختار مباشرة، وتبديل سريع بين الدول
class CountryScreen extends StatefulWidget {
  final GameState gs;
  final String country;
  const CountryScreen({super.key, required this.gs, required this.country});
  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  int sel = 0;

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs, country = widget.country;
    final ls = gs.wLeagues.where((l) => l.country == country).toList()..sort((a, b) => a.tier.compareTo(b.tier));
    final cur = ls.isEmpty ? null : ls[sel.clamp(0, ls.length - 1)];
    return Scaffold(
      appBar: AppBar(
        title: Text(country),
        actions: [
          IconButton(
            tooltip: tr('تغيير الدولة'),
            icon: const Icon(Icons.public_rounded),
            onPressed: () => showCountrySwitcher(context, gs, current: country, replace: true),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Row(children: [
          FlagBadge(country, size: 52),
          const SizedBox(width: 14),
          Expanded(child: Text(country, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22))),
          if (gs.nat.pts.containsKey(country))
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NationScreen(gs: gs, nation: country))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: const Text('المنتخب', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900)),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        if (country == gs.country)
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('هذه دولتك', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 4),
              const Text('دوريك وكؤوسك المحلية في صفحة المسابقات، وبقية دوريات الدولة تُلعب آلياً.', style: TextStyle(color: kMuted, fontSize: 12.5)),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('العودة إلى المسابقات')),
            ]),
          ),
        if (cur == null && country != gs.country)
          const Panel(child: EmptyState(icon: Icons.public_rounded, title: 'لا دوري محاكى لهذه الدولة', subtitle: 'تظهر هنا الدوريات التي تُلعب آلياً في اللعبة. يمكنك فتح المنتخب أو التنقل لدولة أخرى.'))
        else if (cur != null) ...[
          SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (var i = 0; i < ls.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => sel = i),
                    child: Unfilter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel == i ? const Color(0xFF15233D) : kCard,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: sel == i ? const Color(0xFF15233D) : kLine),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 26,
                            height: 26,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7)),
                            child: CompLogo(ls[i].id, fallback: Icons.emoji_events_outlined, color: kPrimary, size: 20, unfilter: false),
                          ),
                          const SizedBox(width: 8),
                          Text(ls[i].name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: sel == i ? Colors.white : kMuted)),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          ...worldLeagueBody(context, gs, cur),
        ],
      ]),
    );
  }
}

/// نافذة سريعة لاختيار دولة (بحث + قارات) تنقلك دون العودة للخلف
Future<void> showCountrySwitcher(BuildContext context, GameState gs, {String? current, bool replace = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBg,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, sc) => CountryList(
        gs: gs,
        controller: sc,
        current: current,
        onPick: (c) {
          Navigator.of(ctx).pop();
          final route = MaterialPageRoute<void>(builder: (_) => CountryScreen(gs: gs, country: c));
          if (replace) {
            Navigator.of(context).pushReplacement(route);
          } else {
            Navigator.of(context).push(route);
          }
        },
      ),
    ),
  );
}

/// شاشة كاملة لتصفح كل دول العالم
class WorldExplorerScreen extends StatelessWidget {
  final GameState gs;
  const WorldExplorerScreen({super.key, required this.gs});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('دول العالم')),
        body: CountryList(gs: gs, onPick: (c) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CountryScreen(gs: gs, country: c)))),
      );
}

/// قائمة الدول: بحث + شرائح القارات + صفوف بعلم وعدد الدوريات
class CountryList extends StatefulWidget {
  final GameState gs;
  final ValueChanged<String> onPick;
  final ScrollController? controller;
  final String? current;
  const CountryList({super.key, required this.gs, required this.onPick, this.controller, this.current});
  @override
  State<CountryList> createState() => _CountryListState();
}

class _CountryListState extends State<CountryList> {
  String q = '', conf = 'all';

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    gs.ensureNat();
    final seen = <String>{};
    final all = <String>[
      if (gs.country.isNotEmpty) gs.country,
      ...kContinentalOrder,
      for (final c in kConfeds) ...c.order,
      for (final l in gs.wLeagues) l.country,
      ...gs.nat.pts.keys,
    ].where((c) => c.isNotEmpty && seen.add(c)).toList();
    int leagues(String c) => gs.wLeagues.where((l) => l.country == c).length;
    String confOf(String c) => gs.nat.conf[c] ?? confedOf(c).id;
    final list = [
      for (final c in all)
        if ((conf == 'all' || confOf(c) == conf) && (q.isEmpty || c.contains(q))) c
    ];
    // الدول ذات الدوريات أولاً
    list.sort((a, b) {
      final x = (b == gs.country ? 99 : leagues(b)).compareTo(a == gs.country ? 99 : leagues(a));
      return x;
    });
    return ListView(controller: widget.controller, padding: const EdgeInsets.all(14), children: [
      TextField(
        onChanged: (v) => setState(() => q = v.trim()),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: tr('ابحث عن دولة...'),
          filled: true,
          fillColor: kCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final e in [('all', 'الكل'), ...kConfNames.entries.map((x) => (x.key, x.value))])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: GestureDetector(
                onTap: () => setState(() => conf = e.$1),
                child: Unfilter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: conf == e.$1 ? const Color(0xFF15233D) : kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: conf == e.$1 ? const Color(0xFF15233D) : kLine),
                    ),
                    child: Text(e.$2, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: conf == e.$1 ? Colors.white : kMuted)),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 10),
      Text('${list.length} دولة', style: const TextStyle(color: kMuted, fontSize: 12)),
      const SizedBox(height: 6),
      Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final c in list)
            InkWell(
              onTap: () => widget.onPick(c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
                child: Row(children: [
                  FlagBadge(c, size: 30),
                  const SizedBox(width: 12),
                  Expanded(child: Text(c, style: TextStyle(fontWeight: c == widget.current || c == gs.country ? FontWeight.w900 : FontWeight.w700))),
                  if (c == gs.country)
                    const Text('دولتك', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w800))
                  else if (leagues(c) > 0)
                    Text('${leagues(c)} ${leagues(c) == 1 ? 'دوري' : 'دوريات'}', style: const TextStyle(color: kMuted, fontSize: 12)),
                  const Icon(Icons.chevron_left_rounded, color: kMuted),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }
}
