import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'api_football.dart';
import 'bundled.dart';
import 'cups.dart';
import 'data_screen.dart';
import 'flags.dart';
import 'importer.dart';
import 'league_store.dart';
import 'models.dart';
import 'widgets.dart';

/// معالج لعبة جديدة: 1) الدولة  2) الدرجة والدوري  3) الفريق
class LeaguesScreen extends StatefulWidget {
  final StartReal onStart;
  const LeaguesScreen({super.key, required this.onStart});
  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  List<LeagueData>? leagues;
  bool busy = false;
  String? country; // الدولة المختارة (الخطوة 2)
  String query = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  Future<void> _init() async {
    final l = await Bundled.list();
    _set(() => leagues = l);
  }

  Future<void> _pick(LeagueData d) async {
    if (busy) return;
    _set(() => busy = true);
    try {
      await _pickInner(d);
    } finally {
      _set(() => busy = false);
    }
  }

  Future<void> _pickInner(LeagueData d) async {
    final local = await LeagueStore.load(d.id, d.season);
    final data = local ?? d;
    if (!mounted) return;
    final rng = Random();
    final teams = teamsFromLeague(data, rng);
    final same = (leagues ?? const <LeagueData>[]).where((x) => x.country == d.country && x.teams.length >= 8).toList();
    LeagueData? near(int dv) {
      final c = same.where((x) => x.div == dv).toList();
      return c.isEmpty ? null : c.first;
    }

    Future<List<Team>> load(LeagueData x) async => teamsFromLeague(await LeagueStore.load(x.id, x.season) ?? x, rng);
    final up = near(d.div - 1), lo = near(d.div + 1);
    // أندية قارية حقيقية من دوريات الاتحاد نفسه حسب مقاعد كل دولة
    final cf = confedOf(d.country);
    final userSlots = d.div == 1 ? continentalSlots(d.country) : 0;
    final userEl = d.div == 1 ? europaSlots(d.country) : 0;
    final userCo = d.div == 1 ? conferenceSlots(d.country) : 0;
    final big = cf.swiss ? 36 : 16;
    final tops = <String, LeagueData>{};
    for (final x in (leagues ?? const <LeagueData>[])) {
      if (x.div == 1 && x.country != d.country && x.teams.length >= 8 && confedOf(x.country).id == cf.id) tops[x.country] = x;
    }
    final order = [...cf.order.where(tops.containsKey), ...tops.keys.where((c) => !cf.order.contains(c))];
    final loaded = <String, List<ApiTeam>>{};
    Future<List<ApiTeam>> ranked(String c) async {
      if (loaded.containsKey(c)) return loaded[c]!;
      final src = tops[c]!;
      final full = await LeagueStore.load(src.id, src.season) ?? src;
      return loaded[c] = [...full.teams]..sort((a, b) => a.rank.compareTo(b.rank));
    }

    // مجموعات الأندية: 0 أبطال، 1 أوروبي/ثانية، 2 مؤتمر — لكل دولة نطاق مراكز مختلف فلا تتكرر الأندية
    final need = [big - userSlots, cf.swiss ? big - userEl : 0, cf.swiss ? big - userCo : big - userCo];
    final out = [<Team>[], <Team>[], <Team>[]];
    final used = <String>{};
    final cursor = <String, int>{};
    Future<void> addFrom(int tier, String c, int n, int offset) async {
      final sub = await ranked(c);
      final src = tops[c]!;
      final slice = sub.skip(offset).take(n.isOdd ? n + 1 : n).toList();
      if (slice.isEmpty) return;
      final copy = LeagueData(id: src.id, name: src.name, country: src.country, tier: src.tier, div: 1, season: src.season, teams: slice, fetchedAt: src.fetchedAt);
      var added = 0;
      for (final t in teamsFromLeague(copy, rng)) {
        if (added >= n || out[tier].length >= need[tier]) break;
        if (used.contains(t.name)) continue;
        used.add(t.name);
        out[tier].add(t);
        added++;
      }
    }

    int cntOf(String c, int tier) => tier == 0 ? continentalSlots(c) : (tier == 1 ? europaSlots(c) : conferenceSlots(c));
    int offOf(String c, int tier) {
      var o = 0;
      for (var k = 0; k < tier; k++) {
        o += cntOf(c, k);
      }
      return o;
    }

    for (var tier = 0; tier < 3; tier++) {
      for (final c in order) {
        final n = cntOf(c, tier);
        if (n > 0 && out[tier].length < need[tier]) await addFrom(tier, c, min(need[tier] - out[tier].length, n), offOf(c, tier));
      }
    }
    for (final c in order) {
      cursor[c] = cntOf(c, 0) + cntOf(c, 1) + cntOf(c, 2) + (cf.swiss ? 1 : 0); // +1 لبطل الكأس
    }
    // إكمال النقص بمراكز لاحقة (دورات متتالية)
    for (var pass = 0; pass < 6; pass++) {
      var grew = false;
      for (var tier = 0; tier < 3; tier++) {
        for (final c in order) {
          if (out[tier].length >= need[tier]) break;
          final before = out[tier].length;
          await addFrom(tier, c, 1, cursor[c]!);
          cursor[c] = cursor[c]! + 1;
          if (out[tier].length > before) grew = true;
        }
      }
      if (!grew) break;
    }
    final world = out[0], worldEl = out[1], worldCo = out[2];
    final pyramid = Pyramid(
      country: d.country,
      leagueId: d.id,
      world: world,
      worldEl: worldEl,
      worldCo: worldCo,
      userSlotsEl: userEl,
      userSlotsCo: userCo,
      userSlots: userSlots == 0 ? 3 : userSlots,
      div: d.div,
      upper: up == null ? const [] : await load(up),
      upperName: up?.name ?? '',
      lower: lo == null ? const [] : await load(lo),
      lowerName: lo?.name ?? '',
    );
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClubPickerScreen(teams: teams, leagueName: data.name, onStart: widget.onStart, pyramid: pyramid),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = leagues;
    return PopScope(
      canPop: country == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => country = null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لعبة جديدة'),
          centerTitle: true,
          actions: [Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Center(child: Text('${country == null ? 1 : 2}/3', style: const TextStyle(color: kMuted))))],
          bottom: WizardBar(country == null ? 1 : 2),
        ),
        body: SafeArea(
          child: l == null
              ? ListView(padding: const EdgeInsets.all(14), children: [
                  for (var i = 0; i < 7; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 64)),
                ])
              : l.isEmpty
                  ? const Center(child: Text('لا توجد دوريات في هذه النسخة بعد. حدّث التطبيق لاحقاً.', style: TextStyle(color: kMuted)))
                  : ListView(padding: const EdgeInsets.all(16), children: [
                      if (busy) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()),
                      if (country == null) ..._countryGrid(l) else ..._leagueList(l),
                    ]),
        ),
      ),
    );
  }

  List<Widget> _leagueList(List<LeagueData> l) {
    final mine = _ordered(l).where((x) => x.country == country).toList();
    final out = <Widget>[
      Row(children: [
        FlagBadge(country!, size: 40),
        const SizedBox(width: 12),
        Expanded(child: Text(country!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        TextButton(onPressed: () => setState(() => country = null), child: const Text('تغيير')),
      ]),
      const SizedBox(height: 8),
      const Text('اختر الدوري', style: TextStyle(color: kMuted, fontSize: 13)),
    ];
    int? lastDiv;
    for (final d in mine) {
      if (lastDiv != d.div) {
        lastDiv = d.div;
        out.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(_divLabel(d.div), style: const TextStyle(color: kAccent, fontWeight: FontWeight.w800, fontSize: 13)),
        ));
      }
      out.add(InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: busy ? null : () => _pick(d),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text('${d.teams.length} فريقاً • ${d.playerCount} لاعباً', style: const TextStyle(color: kMuted, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_left),
          ]),
        ),
      ));
    }
    return out;
  }

  List<Widget> _countryGrid(List<LeagueData> l) {
    final by = <String, List<LeagueData>>{};
    for (final d in _ordered(l)) {
      by.putIfAbsent(d.country, () => []).add(d);
    }
    final names = by.keys.where((c) => query.isEmpty || c.contains(query)).toList();
    return [
      const Text('اختر الدولة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      TextField(
        onChanged: (v) => setState(() => query = v.trim()),
        decoration: InputDecoration(
          hintText: tr('ابحث عن دولة'),
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: kCard2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 14),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
        children: [
          for (final c in names)
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => country = c),
              child: Container(
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
                padding: const EdgeInsets.all(8),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  FlagBadge(c, size: 52),
                  const SizedBox(height: 8),
                  Text(c, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text('${by[c]!.length} دوري', style: const TextStyle(color: kMuted, fontSize: 11)),
                ]),
              ),
            ),
        ],
      ),
    ];
  }

  static String _divLabel(int d) => d == 1 ? 'الدرجة الأولى' : (d == 2 ? 'الدرجة الثانية' : 'الدرجة الثالثة');

  /// ترتيب: الدولة الأقوى أولاً ثم الدرجات
  List<LeagueData> _ordered(List<LeagueData> l) {
    final best = <String, int>{};
    for (final d in l) {
      final t = d.tier;
      if (!best.containsKey(d.country) || t < best[d.country]!) best[d.country] = t;
    }
    return [...l]..sort((a, b) {
        final c = best[a.country]!.compareTo(best[b.country]!);
        if (c != 0) return c;
        final n = a.country.compareTo(b.country);
        return n != 0 ? n : a.div.compareTo(b.div);
      });
  }
}
