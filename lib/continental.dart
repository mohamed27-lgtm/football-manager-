import 'dart:math';
import 'api_football.dart';
import 'cups.dart';
import 'importer.dart';
import 'models.dart';

/// الأندية القارية (أبطال/أوروبي/مؤتمر) لدوري دولة معيّنة، من البيانات المضمّنة مباشرة (متزامن).
/// نفس منطق معالج «لعبة جديدة» لكن بلا تحميل من المخزن، ليُستعمل عند الانتقال للتدريب في دولة أخرى.
(List<Team>, List<Team>, List<Team>) buildContinentalPools(String country, List<LeagueData> leagues, Random rng) {
  final cf = confedOf(country);
  final userSlots = continentalSlots(country);
  final userEl = europaSlots(country);
  final userCo = conferenceSlots(country);
  final big = cf.swiss ? 36 : 16;
  final tops = <String, LeagueData>{};
  for (final x in leagues) {
    if (x.div == 1 && x.country != country && x.teams.length >= 8 && confedOf(x.country).id == cf.id) tops[x.country] = x;
  }
  final order = [...cf.order.where(tops.containsKey), ...tops.keys.where((c) => !cf.order.contains(c))];
  final need = [big - userSlots, cf.swiss ? big - userEl : 0, cf.swiss ? big - userCo : big - userCo];
  final out = [<Team>[], <Team>[], <Team>[]];
  final used = <String>{};
  final cursor = <String, int>{};

  List<ApiTeam> ranked(String c) => [...tops[c]!.teams]..sort((a, b) => a.rank.compareTo(b.rank));

  void addFrom(int tier, String c, int n, int offset) {
    final sub = ranked(c);
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
      if (n > 0 && out[tier].length < need[tier]) addFrom(tier, c, min(need[tier] - out[tier].length, n), offOf(c, tier));
    }
  }
  for (final c in order) {
    cursor[c] = cntOf(c, 0) + cntOf(c, 1) + cntOf(c, 2) + (cf.swiss ? 1 : 0);
  }
  for (var pass = 0; pass < 6; pass++) {
    var grew = false;
    for (var tier = 0; tier < 3; tier++) {
      for (final c in order) {
        if (out[tier].length >= need[tier]) break;
        final before = out[tier].length;
        addFrom(tier, c, 1, cursor[c]!);
        cursor[c] = cursor[c]! + 1;
        if (out[tier].length > before) grew = true;
      }
    }
    if (!grew) break;
  }
  return (out[0], out[1], out[2]);
}
