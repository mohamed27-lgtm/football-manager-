import 'package:flutter/material.dart' hide Text;
import 'game_state.dart';
import 'i18n.dart';
import 'widgets.dart';
import 'flags.dart';
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
  Widget build(BuildContext context) {
    final l = league;
    final o = l.order;
    final champs = [
      for (final e in gs.worldChamps.entries)
        if (e.key.startsWith('${l.id}|')) (int.parse(e.key.split('|')[1]), e.value)
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return Scaffold(
      appBar: AppBar(title: Text(l.name)),
      body: ListView(padding: const EdgeInsets.all(14), children: [
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
      ]),
    );
  }
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


/// صفحة دولة: دورياتها ومتصدريها وتاريخ أبطالها ومنتخبها
class CountryScreen extends StatelessWidget {
  final GameState gs;
  final String country;
  const CountryScreen({super.key, required this.gs, required this.country});

  @override
  Widget build(BuildContext context) {
    final ls = gs.wLeagues.where((l) => l.country == country).toList();
    final champs = <(String, int, String)>[
      for (final l in ls)
        for (final e in gs.worldChamps.entries)
          if (e.key.startsWith('${l.id}|')) (l.name, int.parse(e.key.split('|')[1]), e.value)
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return Scaffold(
      appBar: AppBar(title: Text(country)),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Row(children: [
          FlagBadge(country, size: 56),
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
        const SizedBox(height: 14),
        if (ls.isEmpty)
          const Panel(child: EmptyState(icon: Icons.public_rounded, title: 'لا دوري محاكى لهذه الدولة', subtitle: 'تظهر هنا الدوريات التي تُلعب آلياً في اللعبة (الدوريات الكبرى في العالم).'))
        else ...[
          const Text('الدوريات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          for (final l in ls)
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WorldTableScreen(gs: gs, league: l))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                      Text('الدرجة ${l.tier} • جولة ${l.round}/${l.totalRounds}', style: const TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ),
                  Text(l.round == 0 ? '—' : l.names[l.order.first], style: const TextStyle(fontWeight: FontWeight.w800)),
                  const Icon(Icons.chevron_left_rounded, color: kMuted),
                ]),
              ),
            ),
          if (champs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('أبطال الدوري', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            Panel(
              child: Column(children: [
                for (final c in champs.take(15))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Expanded(child: Text('${c.$1} • الموسم ${c.$2}', style: const TextStyle(color: kMuted, fontSize: 12.5))),
                      Text(c.$3, style: const TextStyle(fontWeight: FontWeight.w900)),
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
