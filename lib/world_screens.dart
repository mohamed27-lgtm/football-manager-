import 'package:flutter/material.dart' hide Text;
import 'game_state.dart';
import 'i18n.dart';
import 'widgets.dart';
import 'flags.dart';
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

/// جدول دوري عالمي وأبطاله السابقون (يُستخدم داخل صفحة الدولة مباشرة)
List<Widget> worldLeagueBody(BuildContext context, GameState gs, WorldLeague l) {
  final o = l.order;
  final champs = [
    for (final e in gs.worldChamps.entries)
      if (e.key.startsWith('${l.id}|')) (int.parse(e.key.split('|')[1]), e.value)
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  return [
    Text('${l.country} • الجولة ${l.round} من ${l.totalRounds}', style: const TextStyle(color: kMuted)),
    const SizedBox(height: 10),
    Panel(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < o.length; i++)
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClubCabinetScreen(gs: gs, club: l.names[o[i]]))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
              child: Row(children: [
                SizedBox(width: 26, child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: i == 0 ? kGold : kMuted))),
                Expanded(child: Text(l.names[o[i]], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width: 34, child: Text('${l.st[o[i]][0]}', textAlign: TextAlign.center, style: const TextStyle(color: kMuted))),
                SizedBox(width: 40, child: Text('${l.st[o[i]][4] - l.st[o[i]][5]}', textAlign: TextAlign.center, style: const TextStyle(color: kMuted))),
                SizedBox(width: 38, child: Text('${l.st[o[i]][6]}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900))),
              ]),
            ),
          ),
      ]),
    ),
    const SizedBox(height: 4),
    const Text('الأعمدة: لعب • فارق الأهداف • نقاط', style: TextStyle(color: kMuted, fontSize: 11)),
    if (champs.isNotEmpty) ...[
      sectionTitle('الأبطال السابقون'),
      Panel(child: Column(children: [for (final c in champs) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Text('الموسم ${c.$1}', style: const TextStyle(color: kMuted)), const Spacer(), Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w800))]))])),
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
    final moves = cur == null
        ? const <MapEntry<String, List<String>>>[]
        : (gs.worldMoves.entries.where((e) => e.key.startsWith('${cur.id}|')).toList()..sort((a, b) => int.parse(b.key.split('|')[1]).compareTo(int.parse(a.key.split('|')[1])))).take(3).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(country),
        actions: [
          IconButton(
            tooltip: 'تغيير الدولة',
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
            height: 46,
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
                        child: Text(ls[i].name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: sel == i ? Colors.white : kMuted)),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          ...worldLeagueBody(context, gs, cur),
          if (moves.isNotEmpty) ...[
            const SizedBox(height: 12),
            sectionTitle('الصعود والهبوط'),
            Panel(
              child: Column(children: [
                for (final e in moves)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('الموسم ${e.key.split('|')[1]}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                      Text('🔼 ${e.value.where((x) => x.startsWith('+')).map((x) => x.substring(1)).join('، ')}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('🔽 ${e.value.where((x) => x.startsWith('-')).map((x) => x.substring(1)).join('، ')}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
              ]),
            ),
          ],
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
          hintText: 'ابحث عن دولة...',
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
