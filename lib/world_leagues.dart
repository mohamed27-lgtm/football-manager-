part of 'game_state.dart';

/// دوري في العالم يُلعب آلياً كل أسبوع دون تدخل المستخدم (جدول حقيقي بأندية حقيقية)
class WorldLeague {
  final int id, tier;
  final String name, country;
  final List<String> names;
  final List<double> str;
  final List<List<int>> st; // لكل فريق: [لعب، فاز، تعادل، خسر، له، عليه، نقاط]
  int round = 0;
  bool done = false;

  WorldLeague(this.id, this.name, this.country, this.tier, this.names, this.str, [List<List<int>>? st])
      : st = st ?? [for (final _ in names) List<int>.filled(7, 0)];

  int get n => names.length;
  int get _m => (n.isOdd ? n + 1 : n) - 1; // عدد جولات نصف الموسم
  int get totalRounds => _m * 2;

  /// مباريات الجولة بطريقة الدائرة (الفريق الأخير ثابت)
  List<(int, int)> pairs(int r) {
    final ne = n.isOdd ? n + 1 : n;
    final m = ne - 1, k = r % m;
    final out = <(int, int)>[];
    for (var i = 0; i < ne ~/ 2; i++) {
      var a = i == 0 ? k % m : (k + i) % m;
      var b = i == 0 ? m : (k + m - i) % m;
      if (a >= n || b >= n) continue;
      if ((r ~/ m + (i == 0 ? k : i)) % 2 == 1) {
        final t = a;
        a = b;
        b = t;
      }
      out.add((a, b));
    }
    return out;
  }

  List<int> get order {
    final o = List<int>.generate(n, (i) => i);
    o.sort((a, b) {
      final c = st[b][6].compareTo(st[a][6]);
      if (c != 0) return c;
      final g = (st[b][4] - st[b][5]).compareTo(st[a][4] - st[a][5]);
      if (g != 0) return g;
      return st[b][4].compareTo(st[a][4]);
    });
    return o;
  }

  Map<String, dynamic> toJson() => {'i': id, 'n': name, 'c': country, 't': tier, 'nm': names, 's': str, 'st': st, 'r': round, 'd': done};

  factory WorldLeague.fromJson(Map<String, dynamic> j) => WorldLeague(
        j['i'] as int,
        j['n'] as String,
        j['c'] as String,
        j['t'] as int,
        (j['nm'] as List).cast<String>(),
        [for (final v in j['s'] as List) (v as num).toDouble()],
        [for (final r in j['st'] as List) (r as List).cast<int>()],
      )
        ..round = j['r'] as int
        ..done = (j['d'] as bool?) ?? false;
}

const _kTopLeagueIds = {39, 140, 135, 78, 61};

extension WorldLeagues on GameState {
  /// مفتاح موحّد لخزينة النادي (الاسم الإنجليزي إن وُجد له اسم عربي في السجل)
  String honourKey(String club) => kClubAlias[club] ?? club;

  /// يسجّل لقباً في خزينة النادي (أي نادٍ في العالم)
  void clubTitle(String club, String comp, [int? ss]) {
    final l = clubHonours.putIfAbsent(honourKey(club), () => []);
    final e = '$comp — الموسم ${ss ?? season}';
    if (!l.contains(e)) l.add(e);
  }

  static double _strengthOf(ApiTeam t, int rank, int n) {
    final ovs = [for (final p in t.players) if (p.ov != null) p.ov!]..sort((a, b) => b.compareTo(a));
    if (ovs.length >= 11) {
      final top = ovs.take(16).toList();
      return top.fold<double>(0, (a, b) => a + b.toDouble()) / top.length;
    }
    return (66 - 10 * (n <= 1 ? 0.5 : rank / (n - 1))).toDouble(); // لا تقييمات: من ترتيب الفريق
  }

  /// يبني دوريات العالم من البيانات المضمّنة (عدا دوريات بلد المستخدم فهي تُلعب كاملة)
  void _initWorldLeagues() {
    if (wLeagues.isNotEmpty) return;
    final src = Bundled.cached;
    if (src == null) return;
    for (final l in src) {
      if (l.country == country || l.teams.length < 6) continue;
      final ts = [...l.teams]..sort((a, b) => a.rank.compareTo(b.rank));
      wLeagues.add(WorldLeague(l.id, l.name, l.country, l.tier, [for (final t in ts) t.name], [for (var i = 0; i < ts.length; i++) _strengthOf(ts[i], i, ts.length)]));
    }
    wLeagues.sort((a, b) => a.tier != b.tier ? a.tier.compareTo(b.tier) : a.name.compareTo(b.name));
  }

  /// لعب مباراة بنموذج بواسون من قوة الفريقين
  (int, int) _fastScore(double sh, double sa) {
    int pois(double lam) {
      final l = exp(-lam);
      var k = 0;
      var p = 1.0;
      do {
        k++;
        p *= rng.nextDouble();
      } while (p > l && k < 10);
      return k - 1;
    }

    final d = (sh - sa) / 24.0;
    return (pois(1.4 * exp(d) * 1.08), pois(1.15 * exp(-d)));
  }

  void _playRound(WorldLeague l, {List<String>? feed}) {
    if (l.done || l.round >= l.totalRounds) return;
    for (final (a, b) in l.pairs(l.round)) {
      final (gh, ga) = _fastScore(l.str[a], l.str[b]);
      void put(int t, int f, int ag) {
        final s = l.st[t];
        s[0]++;
        s[4] += f;
        s[5] += ag;
        if (f > ag) {
          s[1]++;
          s[6] += 3;
        } else if (f == ag) {
          s[2]++;
          s[6] += 1;
        } else {
          s[3]++;
        }
      }

      put(a, gh, ga);
      put(b, ga, gh);
      if (feed != null) feed.add('${l.name}: ${l.names[a]} $gh-$ga ${l.names[b]}');
    }
    l.round++;
  }

  /// كل أسبوع: تُلعب جولة في كل دوريات العالم
  void _worldTick() {
    _initWorldLeagues();
    if (wLeagues.isEmpty) return;
    final feed = <String>[];
    // نفس رتمك: توزَّع جولات كل دوري على أسابيع موسمك فينتهي الجميع معك
    final span = max(1, rounds.length);
    for (final l in wLeagues) {
      final target = (((week + 1) * l.totalRounds) / span).floor().clamp(1, l.totalRounds);
      var guard = 0;
      while (l.round < target && !l.done && guard++ < 8) {
        _playRound(l, feed: _kTopLeagueIds.contains(l.id) ? feed : null);
      }
    }
    if (feed.isNotEmpty) {
      worldFeed.insertAll(0, feed);
      if (worldFeed.length > 60) worldFeed.removeRange(60, worldFeed.length);
    }
  }

  /// كأس محلي سريع بين فرق الدوري (إقصاء مباشر مرجّح بالقوة)
  String _quickCup(WorldLeague l) {
    var alive = List<int>.generate(l.n, (i) => i)..shuffle(rng);
    while (alive.length > 1) {
      final next = <int>[];
      for (var i = 0; i + 1 < alive.length; i += 2) {
        final a = alive[i], b = alive[i + 1];
        var (gh, ga) = _fastScore(l.str[a], l.str[b]);
        if (gh == ga) {
          gh = rng.nextDouble() < 0.5 + (l.str[a] - l.str[b]) / 100 ? 1 : 0;
          ga = 1 - gh;
        }
        next.add(gh > ga ? a : b);
      }
      if (alive.length.isOdd) next.add(alive.last);
      alive = next;
    }
    return l.names[alive.first];
  }

  /// نهاية الموسم: إتمام الجولات المتبقية وتتويج الأبطال في خزائن أنديتهم، ثم تصفير الجداول
  void _worldLeaguesSeasonEnd() {
    if (wLeagues.isEmpty) return;
    for (final l in wLeagues) {
      while (!l.done && l.round < l.totalRounds) {
        _playRound(l);
      }
      final champ = l.names[l.order.first];
      clubTitle(champ, l.name);
      if (l.tier == 1) {
        clubTitle(_quickCup(l), 'كأس ${l.country}');
        if (_kTopLeagueIds.contains(l.id)) news.insert(0, '🏆 $champ بطل ${l.name}');
      }
      worldChamps['${l.id}|$season'] = champ;
      // تصفير الجدول وانجراف بسيط في القوة نحو المتوسط
      l.round = 0;
      for (var i = 0; i < l.n; i++) {
        l.st[i] = List<int>.filled(7, 0);
        l.str[i] = (l.str[i] + (rng.nextDouble() - 0.5) * 3 + 0.06 * (68 - l.str[i])).clamp(45, 90).toDouble();
      }
    }
  }
}
