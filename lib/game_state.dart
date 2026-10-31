import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'engine.dart';
import 'models.dart';

class Fixture {
  final int home, away;
  int? hg, ag;
  Fixture(this.home, this.away);
  bool get played => hg != null;
}

const trainingModes = <String, String>{
  'balanced': 'متوازن',
  'attack': 'هجوم',
  'defense': 'دفاع',
  'passing': 'تمرير',
  'fitness': 'لياقة',
  'rest': 'راحة',
};

class GameState extends ChangeNotifier {
  static const _key = 'fm_save_v2';

  final Random rng = Random();
  late final List<Team> teams;
  late final Team user;
  late List<List<Fixture>> rounds;

  int season = 1;
  int week = 0;
  int objective = 6;
  String leagueName = 'الدوري الافتراضي';
  double confidence = 60;
  String training = 'balanced';
  bool fired = false;
  bool seasonOver = false;
  final List<String> news = [];
  final List<String> roundResults = [];
  List<Player> market = [];
  MatchSim? sim;

  Set<Player> _suspBefore = {};
  Set<Player> _injBefore = {};

  GameState(int userTeamId) {
    teams = createLeague(rng);
    user = teams.firstWhere((t) => t.id == userTeamId);
    _buildFixtures();
    market = generateMarket(rng);
    _setObjective();
    news.add('مرحباً بك مدرباً لنادي ${user.name}. هدف الإدارة: المركز $objective أو أفضل.');
  }

  GameState.fromData(List<Team> t, int userId, this.leagueName) {
    teams = t;
    user = teams.firstWhere((x) => x.id == userId);
    _buildFixtures();
    market = generateMarket(rng);
    _setObjective();
    news.add('مرحباً بك مدرباً لنادي ${user.name} في $leagueName. هدف الإدارة: المركز $objective أو أفضل.');
  }

  GameState.fromJson(Map<String, dynamic> j) {
    teams = [
      for (final t in j['teams'] as List) Team.fromJson(t as Map<String, dynamic>)
    ];
    user = teams.firstWhere((t) => t.id == j['user']);
    season = j['season'] as int;
    week = j['week'] as int;
    objective = j['objective'] as int;
    leagueName = (j['league'] as String?) ?? leagueName;
    confidence = (j['conf'] as num).toDouble();
    training = j['training'] as String;
    fired = j['fired'] as bool;
    seasonOver = j['over'] as bool;
    news.addAll((j['news'] as List).cast<String>());
    roundResults.addAll((j['results'] as List).cast<String>());
    market = [
      for (final p in j['market'] as List) Player.fromJson(p as Map<String, dynamic>)
    ];
    rounds = [
      for (final r in j['rounds'] as List)
        [
          for (final f in r as List)
            Fixture(f[0] as int, f[1] as int)
              ..hg = f[2] as int?
              ..ag = f[3] as int?
        ]
    ];
    var maxId = 0;
    for (final t in teams) {
      for (final p in t.squad) {
        maxId = max(maxId, p.id);
      }
    }
    for (final p in market) {
      maxId = max(maxId, p.id);
    }
    pidCounter = max(pidCounter, maxId);
  }

  Team team(int id) => teams[id];

  // ───────── الحفظ ─────────
  Map<String, dynamic> toJson() => {
        'v': 2,
        'user': user.id,
        'season': season,
        'week': week,
        'objective': objective,
        'league': leagueName,
        'conf': confidence,
        'training': training,
        'fired': fired,
        'over': seasonOver,
        'news': news,
        'results': roundResults,
        'teams': [for (final t in teams) t.toJson()],
        'market': [for (final p in market) p.toJson()],
        'rounds': [
          for (final r in rounds)
            [
              for (final f in r) [f.home, f.away, f.hg, f.ag]
            ]
        ],
      };

  Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(toJson()));
    } catch (_) {}
  }

  static Future<bool> hasSave() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.containsKey(_key);
    } catch (_) {
      return false;
    }
  }

  static Future<GameState?> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s == null) return null;
      return GameState.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSave() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_key);
    } catch (_) {}
  }

  // ───────── الجدول ─────────
  void _buildFixtures() {
    final arr = teams.map((t) => t.id).toList()..shuffle(rng);
    final n = arr.length;
    final first = <List<Fixture>>[];
    for (var r = 0; r < n - 1; r++) {
      final round = <Fixture>[];
      for (var i = 0; i < n ~/ 2; i++) {
        var h = arr[i], a = arr[n - 1 - i];
        if ((r + i).isOdd) {
          final t = h;
          h = a;
          a = t;
        }
        round.add(Fixture(h, a));
      }
      first.add(round);
      arr.insert(1, arr.removeLast());
    }
    final second = [
      for (final r in first) [for (final f in r) Fixture(f.away, f.home)]
    ];
    rounds = [...first, ...second];
  }

  void _setObjective() {
    final rank = (teams.toList()..sort((a, b) => b.strength.compareTo(a.strength)))
            .indexOf(user) +
        1;
    objective = max(1, min(teams.length - 1, rank - 1));
  }

  Fixture? get userFixture => week < rounds.length
      ? rounds[week].firstWhere((f) => f.home == user.id || f.away == user.id)
      : null;

  List<Team> get table => [...teams]..sort((a, b) {
      final c = b.points.compareTo(a.points);
      if (c != 0) return c;
      final g = b.gd.compareTo(a.gd);
      if (g != 0) return g;
      return b.gf.compareTo(a.gf);
    });

  int get position => table.indexOf(user) + 1;

  double get weeklyWages => user.squad.fold(0.0, (a, p) => a + p.wage);

  List<Player> get expiring => user.squad.where((p) => p.contract <= 1).toList();

  // ───────── التكتيك ─────────
  void setFormation(Formation f) {
    user.setFormation(f);
    notifyListeners();
  }

  void setMentality(int v) {
    user.mentality = v;
    notifyListeners();
  }

  void setPressing(int v) {
    user.pressing = v;
    notifyListeners();
  }

  void setTempo(int v) {
    user.tempo = v;
    notifyListeners();
  }

  void autoPickUser() {
    user.autoPick();
    notifyListeners();
  }

  void putInLineup(int idx, Player p) {
    final j = user.lineup.indexOf(p);
    final old = user.lineup[idx];
    user.lineup[idx] = p;
    if (j >= 0) user.lineup[j] = old;
    notifyListeners();
  }

  void setTraining(String t) {
    training = t;
    notifyListeners();
  }

  // ───────── المباراة ─────────
  void startMatch() {
    final f = userFixture;
    if (f == null) return;
    _suspBefore = {
      for (final t in teams) ...t.squad.where((p) => p.suspendedMatches > 0)
    };
    _injBefore = {
      for (final t in teams) ...t.squad.where((p) => p.injuredWeeks > 0)
    };
    final h = team(f.home), a = team(f.away);
    sim = MatchSim(h, a, userHome: h == user, userAway: a == user, random: rng);
    notifyListeners();
  }

  void _morale(Team t, double d) {
    for (final p in t.squad) {
      p.morale = (p.morale + d).clamp(20, 100).toDouble();
    }
  }

  void _applyResult(Fixture f, int hg, int ag) {
    f.hg = hg;
    f.ag = ag;
    final h = team(f.home), a = team(f.away);
    h.played++;
    a.played++;
    h.gf += hg;
    h.ga += ag;
    a.gf += ag;
    a.ga += hg;
    if (hg > ag) {
      h.won++;
      a.lost++;
      _morale(h, 4);
      _morale(a, -4);
    } else if (hg < ag) {
      a.won++;
      h.lost++;
      _morale(a, 4);
      _morale(h, -4);
    } else {
      h.drawn++;
      a.drawn++;
    }
  }

  void finishMatchday() {
    final s = sim;
    final f = userFixture;
    if (s == null || f == null) return;
    s.simulateAll();
    roundResults.clear();
    _applyResult(f, s.home.goals, s.away.goals);
    roundResults.add(
        '${team(f.home).name} ${s.home.goals} - ${s.away.goals} ${team(f.away).name}');

    for (final fx in rounds[week]) {
      if (identical(fx, f)) continue;
      final m = MatchSim(team(fx.home), team(fx.away), random: rng)..simulateAll();
      _applyResult(fx, m.home.goals, m.away.goals);
      roundResults.add(
          '${team(fx.home).name} ${m.home.goals} - ${m.away.goals} ${team(fx.away).name}');
    }

    final myG = f.home == user.id ? f.hg! : f.ag!;
    final opG = f.home == user.id ? f.ag! : f.hg!;
    final opp = team(f.home == user.id ? f.away : f.home);
    if (myG > opG) {
      confidence += 3;
      news.insert(0, '✅ فوز على ${opp.name} ($myG-$opG)');
    } else if (myG < opG) {
      confidence -= 3;
      news.insert(0, '❌ خسارة أمام ${opp.name} ($myG-$opG)');
    } else {
      news.insert(0, '➖ تعادل مع ${opp.name} ($myG-$opG)');
    }

    for (final t in teams) {
      for (final p in t.squad) {
        if (_suspBefore.contains(p) && p.suspendedMatches > 0) p.suspendedMatches--;
        if (_injBefore.contains(p) && p.injuredWeeks > 0) p.injuredWeeks--;
        var rec = 22.0;
        if (t == user) {
          if (training == 'rest') rec += 12;
          if (training == 'fitness') rec += 4;
          rec += 1.5 * (user.trainingLvl - 1);
          _train(p);
        }
        p.fitness = min(100, p.fitness + rec);
      }
    }
    for (final p in user.squad) {
      if (p.injuredWeeks > 0 && !_injBefore.contains(p)) {
        news.insert(0, '🚑 أُصيب ${p.name} لمدة ${p.injuredWeeks} أسابيع');
      }
    }

    final home = f.home == user.id;
    final gate = home ? (0.3 + 0.12 * user.reputation) * (0.7 + 0.15 * user.stadium) : 0.0;
    user.budget += 0.6 + 0.2 * user.reputation + gate - weeklyWages;

    if (week >= 4) {
      final expected = (teams.toList()..sort((a, b) => b.strength.compareTo(a.strength)))
              .indexOf(user) +
          1;
      confidence += (expected - position) * 0.5;
    }
    if (user.budget < -5) confidence -= 2;
    confidence = confidence.clamp(0, 100).toDouble();
    if (confidence <= 0) fired = true;

    week++;
    if (week % 4 == 0) market = generateMarket(rng);
    if (week >= rounds.length) seasonOver = true;
    sim = null;
    unawaited(save());
    notifyListeners();
  }

  void _train(Player p) {
    if (training == 'rest' || training == 'fitness') return;
    if (p.overall >= p.potential) return;
    final base = p.age <= 24 ? 0.14 : (p.age <= 29 ? 0.06 : 0.02);
    final chance = base * (1 + 0.25 * (user.trainingLvl - 1));
    if (rng.nextDouble() > chance) return;
    if (p.pos == Pos.gk) {
      p.gk = min(95, p.gk + 1);
      return;
    }
    switch (training) {
      case 'attack':
        p.atk = min(95, p.atk + 1);
      case 'defense':
        p.def = min(95, p.def + 1);
      case 'passing':
        p.pas = min(95, p.pas + 1);
      default:
        switch (p.pos) {
          case Pos.def:
            p.def = min(95, p.def + 1);
          case Pos.mid:
            p.pas = min(95, p.pas + 1);
          default:
            p.atk = min(95, p.atk + 1);
        }
    }
  }

  // ───────── الانتقالات والعقود ─────────
  double buyPrice(Player p) => (p.value * 1.15 * 10).round() / 10;
  double sellPrice(Player p) => (p.value * 0.85 * 10).round() / 10;
  double renewCost(Player p) => max(0.1, (p.value * 0.08 * 10).round() / 10);

  String? buy(Player p) {
    final price = buyPrice(p);
    if (user.squad.length >= 30) return 'التشكيلة ممتلئة (30 لاعباً كحد أقصى)';
    if (price > user.budget) return 'الميزانية غير كافية';
    user.budget -= price;
    user.squad.add(p);
    market.remove(p);
    p.morale = 75;
    news.insert(0, '💼 تعاقدت مع ${p.name} مقابل ${price.toStringAsFixed(1)}M');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? sell(Player p) {
    if (user.squad.length <= 16) return 'يجب ألا يقل عدد اللاعبين عن 16';
    if (p.pos == Pos.gk && user.squad.where((x) => x.pos == Pos.gk).length <= 2) {
      return 'تحتاج إلى حارسين على الأقل';
    }
    final price = sellPrice(p);
    user.squad.remove(p);
    user.repairLineup();
    user.budget += price;
    news.insert(0, '💰 بعت ${p.name} مقابل ${price.toStringAsFixed(1)}M');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? renew(Player p) {
    final cost = renewCost(p);
    if (cost > user.budget) return 'الميزانية غير كافية';
    user.budget -= cost;
    p.contract = 3;
    news.insert(0, '✍️ جدّدت عقد ${p.name} لـ 3 سنوات');
    unawaited(save());
    notifyListeners();
    return null;
  }

  // ───────── المنشآت ─────────
  double upgradeCost(int level) => 6.0 + 6.0 * level;

  String? upgrade(String kind) {
    final lvl = switch (kind) {
      'stadium' => user.stadium,
      'training' => user.trainingLvl,
      _ => user.academy,
    };
    if (lvl >= 5) return 'وصلت إلى أقصى مستوى';
    final cost = upgradeCost(lvl);
    if (cost > user.budget) return 'الميزانية غير كافية';
    user.budget -= cost;
    switch (kind) {
      case 'stadium':
        user.stadium++;
      case 'training':
        user.trainingLvl++;
      default:
        user.academy++;
    }
    news.insert(0, '🏗️ تمت ترقية المنشأة (${money1(cost)})');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String money1(double v) => '${v.toStringAsFixed(1)}M';

  // ───────── نهاية الموسم ─────────
  void _grow(Player p, int d) {
    int c(int v) => (v + d).clamp(20, 95).toInt();
    switch (p.pos) {
      case Pos.gk:
        p.gk = c(p.gk);
      case Pos.def:
        p.def = c(p.def);
        p.pas = c(p.pas);
      case Pos.mid:
        p.pas = c(p.pas);
        p.atk = c(p.atk);
        p.def = c(p.def);
      case Pos.att:
        p.atk = c(p.atk);
        p.pas = c(p.pas);
    }
  }

  void _topUp(Team t) => topUpSquad(t, rng);

  void startNewSeason() {
    final pos = position;
    if (pos <= objective) {
      confidence = min(100, confidence + 12);
      user.budget += 2;
      news.insert(0, '🎯 حققت هدف الإدارة (المركز $pos)! مكافأة 2.0M');
    } else {
      confidence = max(0, confidence - (pos > objective + 2 ? 15 : 10));
      news.insert(0, '😕 لم تحقق هدف الإدارة (المركز $pos بدل $objective)');
    }
    final prize = max(0.0, (teams.length + 1 - pos) * 0.9 * 12 / teams.length);
    user.budget += prize;
    news.insert(0, '🏆 أنهيت الموسم $season في المركز $pos — جائزة ${prize.toStringAsFixed(1)}M');

    for (final t in teams) {
      for (final p in [...t.squad]) {
        p.age++;
        p.contract--;
        if (p.age <= 24 && p.overall < p.potential) {
          _grow(p, 1 + rng.nextInt(3));
        } else if (p.age >= 31) {
          _grow(p, -rng.nextInt(3));
        }
        p.fitness = 100;
        p.morale = 70;
        p.injuredWeeks = 0;
        p.suspendedMatches = 0;
        p.goals = 0;
        p.assists = 0;
        p.apps = 0;
        p.yellows = 0;
        if (p.age >= 36) {
          t.squad.remove(p);
          if (t == user) news.insert(0, '👋 اعتزل ${p.name}');
        } else if (p.contract <= 0) {
          if (t == user) {
            t.squad.remove(p);
            news.insert(0, '📤 انتهى عقد ${p.name} ورحل عن النادي');
          } else {
            p.contract = 1 + rng.nextInt(4);
          }
        }
      }
      _topUp(t);
      t.played = 0;
      t.won = 0;
      t.drawn = 0;
      t.lost = 0;
      t.gf = 0;
      t.ga = 0;
      if (t == user) {
        t.repairLineup();
      } else {
        t.autoPick();
      }
    }

    final n = 1 + (user.academy - 1) ~/ 2;
    for (var i = 0; i < n && user.squad.length < 30; i++) {
      final p = makeAcademyPlayer(rng, Pos.values[rng.nextInt(4)], user.academy);
      user.squad.add(p);
      news.insert(0, '🌱 الأكاديمية: انضم الموهوب ${p.name} (${p.age} سنة، إمكانات ${p.potential})');
    }

    season++;
    week = 0;
    seasonOver = false;
    roundResults.clear();
    _buildFixtures();
    market = generateMarket(rng);
    _setObjective();
    if (confidence <= 0) fired = true;
    news.insert(0, '📋 هدف الإدارة للموسم $season: المركز $objective أو أفضل');
    unawaited(save());
    notifyListeners();
  }
}
