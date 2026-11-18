part of 'game_state.dart';

/// لاعب في الترتيب العالمي: لاعب حقيقي بناديه ودوريه وبلده
class WorldPlayer {
  final Player p;
  final Team team;
  final String country, league;
  const WorldPlayer(this.p, this.team, this.country, this.league);
}

/// موضع نادٍ في دوريه الحالي
class WorldClubInfo {
  final String country, league;
  final int div, pos, n; // pos = 0 إن لم يُعرف الترتيب الحي
  const WorldClubInfo(this.country, this.league, this.div, this.pos, this.n);
}

/// صف دوري في ترتيب الدوريات العالمي
class WorldLeagueRow {
  final String name, country, top;
  final int div, clubs;
  final double elo;
  const WorldLeagueRow(this.name, this.country, this.div, this.clubs, this.elo, this.top);
}

extension WorldRank on GameState {
  /// دولة/دوري/ترتيب كل نادٍ في العالم (هرمك الكامل + كل الدوريات المحاكاة)
  Map<String, WorldClubInfo> worldClubInfo() {
    final out = <String, WorldClubInfo>{};
    final tb = table;
    for (var i = 0; i < tb.length; i++) {
      out[tb[i].name] = WorldClubInfo(country, leagueName, div, i + 1, tb.length);
    }
    for (final t in upper) {
      out[t.name] = WorldClubInfo(country, upperName, max(1, div - 1), 0, upper.length);
    }
    for (final t in lower) {
      out[t.name] = WorldClubInfo(country, lowerName, div + 1, 0, lower.length);
    }
    for (final l in wLeagues) {
      final ord = l.order;
      final pos = <int, int>{for (var r = 0; r < ord.length; r++) ord[r]: r + 1};
      final started = l.round > 0;
      for (var i = 0; i < l.names.length; i++) {
        out.putIfAbsent(l.names[i], () => WorldClubInfo(l.country, l.name, worldDivOf(l), started ? (pos[i] ?? 0) : 0, l.n));
      }
    }
    return out;
  }

  /// كل لاعبي العالم الحقيقيين: هرمك + كل دوريات العالم المحاكاة (لا مولَّدين ولا عشوائيين)
  List<WorldPlayer> worldPlayers() {
    final key = '$season/$week/${wLeagues.length}/${wTeams.length}/$country';
    final have = wpCache;
    if (have != null && wpKey == key) return have;
    this._initWorldLeagues();
    for (final l in wLeagues) {
      this._teamsOfWorld(l);
    }
    final out = <WorldPlayer>[];
    final seen = <String>{};
    void add(Iterable<Team> ts, String c, String lg) {
      for (final t in ts) {
        if (!seen.add(t.name)) continue;
        for (final p in t.squad) {
          out.add(WorldPlayer(p, t, c, lg));
        }
      }
    }

    add(teams, country, leagueName);
    add(upper, country, upperName);
    add(lower, country, lowerName);
    for (final l in wLeagues) {
      final ts = wTeams[l.id];
      if (ts == null) continue;
      add([for (final n in l.names) ts[n]].whereType<Team>(), l.country, l.name);
    }
    // أندية قارية بتشكيلات حقيقية لم تُغطَّ في دوري محاكى
    add(foreign.values.where((t) => t.id < 3000 && hasRealSquad(t) && isRealClub(t)), '', '');
    wpKey = key;
    return wpCache = out;
  }

  /// ترتيب الدوريات: متوسط تصنيف Elo لأنديتها الحقيقية (يتحرك بنتائج المباريات المحاكاة)
  List<WorldLeagueRow> worldLeagueTable() {
    final out = <WorldLeagueRow>[];
    void mine(List<Team> ts, String name, int dv) {
      if (ts.isEmpty) return;
      final s = [...ts]..sort((a, b) => eloOf(b).compareTo(eloOf(a)));
      out.add(WorldLeagueRow(name, country, dv, ts.length, ts.fold<double>(0, (a, t) => a + eloOf(t)) / ts.length, s.first.name));
    }

    mine(teams, leagueName, div);
    mine(upper, upperName, max(1, div - 1));
    mine(lower, lowerName, div + 1);
    for (final l in wLeagues) {
      final es = [for (var i = 0; i < l.n; i++) (l.names[i], elo[l.names[i]] ?? this._seedElo(l.names[i], l.str[i]))]..sort((a, b) => b.$2.compareTo(a.$2));
      if (es.isEmpty) continue;
      out.add(WorldLeagueRow(l.name, l.country, worldDivOf(l), l.n, es.fold<double>(0, (a, e) => a + e.$2) / es.length, es.first.$1));
    }
    out.sort((a, b) => b.elo.compareTo(a.elo));
    return out;
  }
}
