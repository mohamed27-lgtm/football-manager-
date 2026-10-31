import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cups.dart';
import 'data.dart';
import 'engine.dart';
import 'finance.dart';
import 'models.dart';
import 'transfers.dart';

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
  /// يُضبط عند تسجيل الدخول ليكون لكل حساب حفظه الخاص
  static String slot = '';
  static String get _key => 'fm_save_v2$slot';

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
  Finance fin = Finance();
  final List<Offer> offers = [];
  final List<Player> loanedOut = [];
  final Map<int, double> _reserve = {};
  Cup? domestic, continental;
  Cup? activeCup;
  final Map<int, Team> foreign = {};
  final List<String> honours = [];
  final Map<String, int> staff = {'coach': 0, 'scout': 0, 'doctor': 0};
  double fans = 50;
  final List<Map<String, dynamic>> history = [];
  String bigWin = '', bigLoss = '';
  int bigWinD = 0, bigLossD = 0;
  int pressWeek = -1;

  Set<Player> _suspBefore = {};
  Set<Player> _injBefore = {};

  GameState(int userTeamId) {
    teams = createLeague(rng);
    user = teams.firstWhere((t) => t.id == userTeamId);
    _buildFixtures();
    _setupCups(null);
    fans = 20.0 + user.reputation * 12;
    market = generateMarket(rng);
    _setObjective();
    news.add('مرحباً بك مدرباً لنادي ${user.name}. هدف الإدارة: المركز $objective أو أفضل.');
  }

  GameState.fromData(List<Team> t, int userId, this.leagueName) {
    teams = t;
    user = teams.firstWhere((x) => x.id == userId);
    _buildFixtures();
    _setupCups(null);
    fans = 20.0 + user.reputation * 12;
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
    if (j['fin'] != null) fin = Finance.fromJson(j['fin'] as Map<String, dynamic>);
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
    for (final o in (j['offers'] as List?) ?? const []) {
      final hit = user.squad.where((p) => p.id == o['pid']);
      if (hit.isNotEmpty) {
        offers.add(Offer(hit.first, o['club'] as String, (o['amt'] as num).toDouble(), o['w'] as int));
      }
    }
    for (final p in (j['loanedOut'] as List?) ?? const []) {
      loanedOut.add(Player.fromJson(p as Map<String, dynamic>));
    }
    for (final t in (j['foreign'] as List?) ?? const []) {
      final tm = Team.fromJson(t as Map<String, dynamic>);
      foreign[tm.id] = tm;
    }
    honours.addAll(((j['honours'] as List?) ?? const []).cast<String>());
    final st = j['staff'] as Map<String, dynamic>?;
    if (st != null) st.forEach((k, v) => staff[k] = v as int);
    fans = (j['fans'] as num?)?.toDouble() ?? (20.0 + user.reputation * 12);
    for (final h in (j['history'] as List?) ?? const []) {
      history.add(Map<String, dynamic>.from(h as Map));
    }
    bigWin = (j['bigWin'] as String?) ?? '';
    bigLoss = (j['bigLoss'] as String?) ?? '';
    bigWinD = (j['bigWinD'] as int?) ?? 0;
    bigLossD = (j['bigLossD'] as int?) ?? 0;
    pressWeek = (j['pressWeek'] as int?) ?? -1;
    final cj = j['cups'] as Map<String, dynamic>?;
    if (cj != null) {
      domestic = Cup.fromJson(cj['dom'] as Map<String, dynamic>);
      continental = Cup.fromJson(cj['con'] as Map<String, dynamic>);
    } else {
      _setupCups(null);
      _advanceCups();
    }
    var maxId = 0;
    for (final t in [...teams, ...foreign.values]) {
      for (final p in t.squad) {
        maxId = max(maxId, p.id);
      }
    }
    for (final p in market) {
      maxId = max(maxId, p.id);
    }
    pidCounter = max(pidCounter, maxId);
  }

  Team team(int id) => id >= 1000 ? foreign[id]! : teams[id];

  // ───────── الحفظ ─────────
  Map<String, dynamic> toJson() => {
        'v': 2,
        'user': user.id,
        'season': season,
        'week': week,
        'objective': objective,
        'league': leagueName,
        'fin': fin.toJson(),
        'offers': [for (final o in offers) o.toJson()],
        'foreign': [for (final t in foreign.values) t.toJson()],
        'honours': honours,
        'staff': staff,
        'fans': fans,
        'history': history,
        'bigWin': bigWin,
        'bigLoss': bigLoss,
        'bigWinD': bigWinD,
        'bigLossD': bigLossD,
        'pressWeek': pressWeek,
        'cups': {'dom': domestic!.toJson(), 'con': continental!.toJson()},
        'loanedOut': [for (final p in loanedOut) p.toJson()],
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
    final diff = myG - opG;
    final line = '${team(f.home).name} ${f.hg}-${f.ag} ${team(f.away).name} (موسم $season)';
    if (diff > bigWinD) {
      bigWinD = diff;
      bigWin = line;
    }
    if (-diff > bigLossD) {
      bigLossD = -diff;
      bigLoss = line;
    }
    fans = (fans + (diff > 0 ? 1.2 : (diff < 0 ? -1.0 : 0.0)) + (position <= 3 ? 0.3 : 0.0)).clamp(0, 100).toDouble();
    _pressHeadline(opp.name, myG, opG);
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
          rec += 1.5 * (staff['doctor'] ?? 0);
          if (p.injuredWeeks > 1 && rng.nextDouble() < 0.1 * (staff['doctor'] ?? 0)) p.injuredWeeks--;
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
    final gate = home ? (0.3 + 0.12 * user.reputation) * (0.7 + 0.15 * user.stadium) * (0.75 + 0.5 * fans / 100) : 0.0;
    final broadcast = 0.35 + 0.1 * user.reputation;
    final sponsor = (0.25 + 0.1 * user.reputation + (position <= 3 ? 0.2 : 0.0)) * (0.8 + 0.4 * fans / 100);
    final maintenance = 0.03 * (user.stadium + user.trainingLvl + user.academy);
    final interest = fin.debt * 0.004;
    fin.add('tickets', gate);
    fin.add('broadcast', broadcast);
    fin.add('sponsor', sponsor);
    fin.add('wages', weeklyWages);
    fin.add('staff', staffWages);
    fin.add('maintenance', maintenance);
    fin.add('interest', interest);
    user.budget += gate + broadcast + sponsor - weeklyWages - staffWages - maintenance - interest;
    fin.record(user.budget);

    if (week >= 4) {
      final expected = (teams.toList()..sort((a, b) => b.strength.compareTo(a.strength)))
              .indexOf(user) +
          1;
      confidence += (expected - position) * 0.5;
    }
    if (user.budget < -5) confidence -= 2;
    confidence = confidence.clamp(0, 100).toDouble();
    if (confidence <= 0) fired = true;

    _transferTick();
    week++;
    if (week % 4 == 0) market = _scoutedMarket();
    if (week >= rounds.length) seasonOver = true;
    _advanceCups();
    sim = null;
    unawaited(save());
    notifyListeners();
  }

  void _train(Player p) {
    if (training == 'rest' || training == 'fitness') return;
    if (p.overall >= p.potential) return;
    final base = p.age <= 24 ? 0.14 : (p.age <= 29 ? 0.06 : 0.02);
    final chance = base * (1 + 0.25 * (user.trainingLvl - 1)) * (1 + 0.1 * (staff['coach'] ?? 0));
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
  double signingBonus(Player p) => max(0.1, (p.wage * 15 * 10).round() / 10);
  double buyPrice(Player p) => p.free ? signingBonus(p) : (p.value * 1.15 * 10).round() / 10;
  double sellPrice(Player p) => (p.value * 0.85 * 10).round() / 10;
  double renewCost(Player p) => max(0.1, (p.value * 0.08 * 10).round() / 10);
  double agentFee(double price) => price <= 0 ? 0 : max(0.1, (price * 0.05 * 10).round() / 10);
  double loanFee(Player p) => max(0.1, (p.value * 0.12 * 10).round() / 10);
  double loanOutFee(Player p) => max(0.1, (p.value * 0.1 * 10).round() / 10);

  /// جولة تفاوض: يقبل البائع إذا بلغ عرضك حدّه الخفي، وإلا يعرض سعراً مضاداً (3 جولات)
  NegoResult evaluateOffer(Player p, double offer, int round) {
    final ask = buyPrice(p);
    final reserve = _reserve.putIfAbsent(p.id, () => ask * (0.84 + rng.nextDouble() * 0.12));
    if (offer >= ask - 0.0001) return const NegoResult('accept', null, 'وافق النادي البائع.');
    if (offer >= reserve) return const NegoResult('accept', null, 'وافق النادي على عرضك.');
    if (round >= 3) return const NegoResult('reject', null, 'انسحب البائع من المفاوضات. جرّب لاحقاً.');
    final c = max(reserve, offer + (ask - offer) * 0.5);
    final counter = min(ask, (c * 10).round() / 10);
    return NegoResult('counter', counter, 'عرض مضاد من البائع: ${money1(counter)}');
  }

  void endNegotiation(Player p) => _reserve.remove(p.id);

  String? buy(Player p) => completeSigning(p, buyPrice(p));

  /// إتمام الصفقة: عمولة الوكيل + الفحص الطبي (قد يُلغي الصفقة أو يكشف إصابة)
  String? completeSigning(Player p, double price) {
    if (user.squad.length >= 30) return 'التشكيلة ممتلئة (30 لاعباً كحد أقصى)';
    final fee = agentFee(price);
    if (price + fee > user.budget) {
      return 'الميزانية غير كافية (السعر + العمولة ${money1(price + fee)})';
    }
    if (rng.nextDouble() < 0.06) {
      market.remove(p);
      news.insert(0, '🩺 فشل ${p.name} في الفحص الطبي وانسحبت الصفقة');
      unawaited(save());
      notifyListeners();
      return 'فشل اللاعب في الفحص الطبي — أُلغيت الصفقة';
    }
    user.budget -= price + fee;
    fin.add('purchases', price);
    fin.add('agents', fee);
    var note = '';
    if (rng.nextDouble() < 0.1) {
      p.injuredWeeks = 1 + rng.nextInt(3);
      note = ' (إصابة طفيفة اكتُشفت في الفحص الطبي)';
    }
    p.contract = 3;
    p.free = false;
    p.listed = false;
    p.onLoan = false;
    p.morale = 75;
    user.squad.add(p);
    market.remove(p);
    news.insert(0, '💼 تعاقدت مع ${p.name} مقابل ${money1(price)} + عمولة وكيل ${money1(fee)}$note');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? loanIn(Player p) {
    if (user.squad.length >= 30) return 'التشكيلة ممتلئة (30 لاعباً كحد أقصى)';
    final fee = loanFee(p);
    if (fee > user.budget) return 'الميزانية غير كافية';
    user.budget -= fee;
    fin.add('loanin', fee);
    p
      ..onLoan = true
      ..free = false
      ..listed = false
      ..contract = 1
      ..morale = 75;
    user.squad.add(p);
    market.remove(p);
    news.insert(0, '🔄 استعرت ${p.name} حتى نهاية الموسم مقابل ${money1(fee)}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? _cannotLose(Player p) {
    if (user.squad.length <= 16) return 'يجب ألا يقل عدد اللاعبين عن 16';
    if (p.pos == Pos.gk && user.squad.where((x) => x.pos == Pos.gk).length <= 2) {
      return 'تحتاج إلى حارسين على الأقل';
    }
    return null;
  }

  String? loanOut(Player p) {
    final err = _cannotLose(p);
    if (err != null) return err;
    final fee = loanOutFee(p);
    user.squad.remove(p);
    loanedOut.add(p);
    p.listed = false;
    user.budget += fee;
    fin.add('loanout', fee);
    offers.removeWhere((o) => o.player == p);
    user.repairLineup();
    news.insert(0, '📤 أعرت ${p.name} حتى نهاية الموسم مقابل ${money1(fee)}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  void toggleListed(Player p) {
    p.listed = !p.listed;
    notifyListeners();
  }

  String? acceptOffer(Offer o) {
    final err = _cannotLose(o.player);
    if (err != null) return err;
    user.squad.remove(o.player);
    user.budget += o.amount;
    fin.add('sales', o.amount);
    offers.remove(o);
    user.repairLineup();
    news.insert(0, '💰 بعت ${o.player.name} إلى ${o.club} مقابل ${money1(o.amount)}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  void rejectOffer(Offer o) {
    offers.remove(o);
    notifyListeners();
  }

  /// كل جولة: تنتهي العروض القديمة وقد تصل عروض جديدة، وقد تخطف الأندية لاعبين من السوق
  void _transferTick() {
    for (final o in offers) {
      o.weeksLeft--;
    }
    offers.removeWhere((o) => o.weeksLeft <= 0 || !user.squad.contains(o.player));
    if (user.squad.length > 16 && offers.length < 3) {
      for (final p in user.squad.where((p) => p.overall >= 58 && !offers.any((o) => o.player == p))) {
        final chance = p.listed ? 0.22 : 0.025;
        if (rng.nextDouble() < chance) {
          final others = teams.where((t) => t != user).toList();
          final club = others[rng.nextInt(others.length)];
          final amount = ((p.value * (0.85 + rng.nextDouble() * 0.5)) * 10).round() / 10;
          offers.add(Offer(p, club.name, max(0.1, amount), 3));
          news.insert(0, '📨 عرض من ${club.name} لشراء ${p.name}: ${money1(amount)}');
          break;
        }
      }
    }
    if (market.length > 8 && rng.nextDouble() < 0.25) {
      final top = [...market]..sort((a, b) => b.overall.compareTo(a.overall));
      final pick = top[rng.nextInt(min(6, top.length))];
      final club = teams.where((t) => t != user).toList()[rng.nextInt(teams.length - 1)];
      market.remove(pick);
      news.insert(0, '🏃 سبقك ${club.name} إلى ${pick.free ? 'توقيع' : 'ضم'} ${pick.name}');
    }
  }

  String? sell(Player p) {
    if (p.onLoan) return 'لا يمكن بيع لاعب معار';
    if (user.squad.length <= 16) return 'يجب ألا يقل عدد اللاعبين عن 16';
    if (p.pos == Pos.gk && user.squad.where((x) => x.pos == Pos.gk).length <= 2) {
      return 'تحتاج إلى حارسين على الأقل';
    }
    final price = sellPrice(p);
    user.squad.remove(p);
    user.repairLineup();
    user.budget += price;
    fin.add('sales', price);
    news.insert(0, '💰 بعت ${p.name} مقابل ${price.toStringAsFixed(1)}M');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? renew(Player p) {
    final cost = renewCost(p);
    if (cost > user.budget) return 'الميزانية غير كافية';
    user.budget -= cost;
    fin.add('renewals', cost);
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
    fin.add('upgrades', cost);
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

  // ───────── الديون والعقود ─────────
  static const maxDebt = 30.0;

  double get squadValue => user.squad.fold(0.0, (a, p) => a + p.value);

  String? takeLoan(double amount) {
    if (fin.debt + amount > maxDebt) return 'سقف الديون ${maxDebt.toStringAsFixed(0)}M';
    user.budget += amount;
    fin.debt += amount;
    news.insert(0, '🏦 اقترضت ${money1(amount)} (فائدة أسبوعية 0.4%)');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? repay(double amount) {
    final a = min(amount, fin.debt);
    if (a <= 0) return 'لا توجد ديون';
    if (a > user.budget) return 'الميزانية غير كافية';
    user.budget -= a;
    fin.debt -= a;
    if (fin.debt < 0.05) fin.debt = 0;
    news.insert(0, '✅ سدّدت ${money1(a)} من الديون');
    unawaited(save());
    notifyListeners();
    return null;
  }

  double releaseCost(Player p) => max(0.1, (p.wage * 10 * p.contract * 10).round() / 10);

  String? release(Player p) {
    if (user.squad.length <= 16) return 'يجب ألا يقل عدد اللاعبين عن 16';
    if (p.pos == Pos.gk && user.squad.where((x) => x.pos == Pos.gk).length <= 2) {
      return 'تحتاج إلى حارسين على الأقل';
    }
    final cost = releaseCost(p);
    if (cost > user.budget) return 'الميزانية غير كافية للتعويض';
    user.budget -= cost;
    fin.add('severance', cost);
    user.squad.remove(p);
    user.repairLineup();
    news.insert(0, '📄 أنهيت عقد ${p.name} (تعويض ${money1(cost)})');
    unawaited(save());
    notifyListeners();
    return null;
  }

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
    final qual = [for (final t in table.take(3)) t.id];
    _recordSeason(pos);
    fin.season.clear();
    for (final p in user.squad.where((p) => p.onLoan).toList()) {
      user.squad.remove(p);
      news.insert(0, '↩️ عاد المعار ${p.name} إلى ناديه');
    }
    if (loanedOut.isNotEmpty) {
      for (final p in loanedOut) {
        user.squad.add(p);
        news.insert(0, '↩️ عاد ${p.name} من الإعارة');
      }
      loanedOut.clear();
    }
    offers.clear();
    if (pos <= objective) {
      confidence = min(100, confidence + 12);
      user.budget += 2;
      fin.add('prize', 2);
      news.insert(0, '🎯 حققت هدف الإدارة (المركز $pos)! مكافأة 2.0M');
    } else {
      confidence = max(0, confidence - (pos > objective + 2 ? 15 : 10));
      news.insert(0, '😕 لم تحقق هدف الإدارة (المركز $pos بدل $objective)');
    }
    final prize = max(0.0, (teams.length + 1 - pos) * 0.9 * 12 / teams.length);
    user.budget += prize;
    fin.add('prize', prize);
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
    _setupCups(qual);
    market = _scoutedMarket();
    _setObjective();
    if (confidence <= 0) fired = true;
    news.insert(0, '📋 هدف الإدارة للموسم $season: المركز $objective أو أفضل');
    unawaited(save());
    notifyListeners();
  }

  // ───────── البطولات (كأس محلي + بطولة قارية) ─────────
  static int _pow2(int n) {
    var p = 1;
    while (p < n) {
      p *= 2;
    }
    return p;
  }

  void _setupCups(List<int>? qual) {
    final w = rounds.length;
    List<int> sched(int r, int off) {
      final out = <int>[];
      for (var i = 0; i < r; i++) {
        var v = min(w - 2, ((i + 1) * w / (r + 1)).round() + off);
        if (out.isNotEmpty && v <= out.last) v = out.last + 1;
        out.add(v);
      }
      return out;
    }

    int log2c(int n) {
      var r = 0, p = 1;
      while (p < n) {
        p *= 2;
        r++;
      }
      return r;
    }

    domestic = Cup(
      key: 'dom',
      name: 'كأس الدوري',
      continental: false,
      schedule: sched(log2c(teams.length), 0),
      size: 2,
      alive: [for (final t in teams) t.id],
    );
    _draw(domestic!);

    foreign.clear();
    for (var i = 0; i < foreignClubNames.length; i++) {
      foreign[1000 + i] = createTeam(rng, 1000 + i, foreignClubNames[i], 3 + rng.nextInt(3));
    }
    final q = qual ?? [for (final t in ([...teams]..sort((a, b) => b.strength.compareTo(a.strength))).take(3)) t.id];
    continental = Cup(
      key: 'con',
      name: 'دوري الأبطال القاري',
      continental: true,
      schedule: sched(4, 3),
      size: 16,
      alive: [...q, ...foreign.keys],
    );
    _draw(continental!);
  }

  void _draw(Cup c) {
    final ids = [...c.alive];
    c.size = _pow2(ids.length);
    final nb = c.size - ids.length;
    ids.sort((a, b) => team(b).strength.compareTo(team(a).strength));
    c.byes = ids.take(nb).toList();
    final rest = ids.skip(nb).toList()..shuffle(rng);
    c.ties = [for (var i = 0; i + 1 < rest.length; i += 2) Tie(rest[i], rest[i + 1])];
  }

  void _setTie(Tie t, int hg, int ag) {
    t.hg = hg;
    t.ag = ag;
    if (hg == ag) {
      final pHome = (0.5 + (team(t.home).strength - team(t.away).strength) * 0.01).clamp(0.35, 0.65).toDouble();
      final homeWins = rng.nextDouble() < pHome;
      final w = 3 + rng.nextInt(3);
      final l = max(0, w - 1 - rng.nextInt(2));
      t.ph = homeWins ? w : l;
      t.pa = homeWins ? l : w;
    }
  }

  void _playAiTie(Tie t) {
    final m = MatchSim(team(t.home), team(t.away), random: rng)..simulateAll();
    _setTie(t, m.home.goals, m.away.goals);
  }

  void _closeRoundIfDone(Cup c) {
    if (c.ties.any((t) => !t.played)) return;
    final winners = [...c.byes, for (final t in c.ties) t.winner];
    for (final t in c.ties) {
      c.log.add('${c.roundName}|${t.text((i) => team(i).name)}');
    }
    final idx = c.round;
    final userWas = c.alive.contains(user.id);
    if (userWas) {
      if (winners.contains(user.id)) {
        final prize = (c.continental ? 1.5 : 0.5) * (idx + 1);
        user.budget += prize;
        fin.add('prize', prize);
        news.insert(0, '🏅 تأهلت في ${c.name} (${c.roundName}) — مكافأة ${money1(prize)}');
      } else {
        news.insert(0, '👋 ودّعت ${c.name} من ${c.roundName}');
      }
    }
    c.alive = winners;
    c.round++;
    if (winners.length == 1) {
      c.done = true;
      c.champion = winners.first;
      if (winners.first == user.id) {
        final bonus = c.continental ? 10.0 : 3.0;
        user.budget += bonus;
        fin.add('prize', bonus);
        confidence = min(100, confidence + 10);
        honours.add('🏆 ${c.name} — الموسم $season');
        news.insert(0, '🏆🏆 بطل ${c.name}! مكافأة ${money1(bonus)}');
      } else {
        news.insert(0, '🏆 ${team(winners.first).name} بطل ${c.name}');
      }
    } else {
      _draw(c);
    }
  }

  void _advanceCups() {
    for (final c in [domestic, continental]) {
      if (c == null) continue;
      while (!c.done && c.dueWeek != null && c.dueWeek! <= week) {
        if (c.userTie(user.id) != null) break;
        for (final t in c.ties.where((t) => !t.played)) {
          _playAiTie(t);
        }
        _closeRoundIfDone(c);
      }
    }
  }

  /// بطولة تنتظر مباراتك الآن (تُلعب قبل مباراة الدوري)
  Cup? get pendingCup {
    if (seasonOver || fired) return null;
    for (final c in [domestic, continental]) {
      if (c != null && !c.done && c.dueWeek != null && c.dueWeek! <= week && c.userTie(user.id) != null) {
        return c;
      }
    }
    return null;
  }

  void startCupMatch(Cup c) {
    final t = c.userTie(user.id);
    if (t == null) return;
    _suspBefore = {...user.squad.where((p) => p.suspendedMatches > 0)};
    _injBefore = {...user.squad.where((p) => p.injuredWeeks > 0)};
    final h = team(t.home), a = team(t.away);
    activeCup = c;
    sim = MatchSim(h, a, userHome: h == user, userAway: a == user, random: rng);
    notifyListeners();
  }

  /// زر «متابعة» بعد المباراة: دوري أو كأس
  void finishCurrent() {
    final c = activeCup;
    if (c == null) {
      finishMatchday();
      return;
    }
    final s = sim;
    final t = c.userTie(user.id);
    if (s == null || t == null) {
      activeCup = null;
      return;
    }
    s.simulateAll();
    _setTie(t, s.home.goals, s.away.goals);
    news.insert(0, '🏆 ${c.name} (${c.roundName}): ${t.text((i) => team(i).name)}');
    if (t.home == user.id) {
      final gate = (0.3 + 0.12 * user.reputation) * (0.7 + 0.15 * user.stadium) * (c.continental ? 1.5 : 1.0);
      user.budget += gate;
      fin.add('tickets', gate);
    }
    for (final p in user.squad) {
      if (_suspBefore.contains(p) && p.suspendedMatches > 0) p.suspendedMatches--;
      if (_injBefore.contains(p) && p.injuredWeeks > 0) p.injuredWeeks--;
      p.fitness = min(100, p.fitness + 8);
      if (p.injuredWeeks > 0 && !_injBefore.contains(p)) {
        news.insert(0, '🚑 أُصيب ${p.name} لمدة ${p.injuredWeeks} أسابيع');
      }
    }
    if (t.winner == user.id) {
      confidence = min(100, confidence + 2);
    } else {
      confidence = max(0, confidence - 2);
      if (confidence <= 0) fired = true;
    }
    _morale(user, t.winner == user.id ? 3 : -3);
    for (final o in c.ties.where((x) => !x.played)) {
      _playAiTie(o);
    }
    _closeRoundIfDone(c);
    _advanceCups();
    fin.record(user.budget);
    activeCup = null;
    sim = null;
    unawaited(save());
    notifyListeners();
  }

  // ───────── الطاقم والإعلام والتاريخ ─────────
  static const staffRoles = <String, (String, String)>{
    'coach': ('المدرب المساعد', 'يسرّع تطور اللاعبين (+10% لكل مستوى)'),
    'scout': ('الكشّاف', 'يضيف مواهب أفضل إلى سوق الانتقالات'),
    'doctor': ('الطبيب', 'يقلل مدة الإصابات ويسرّع التعافي'),
  };

  double get staffWages => staff.values.fold(0, (a, v) => a + v * 0.04);
  double staffCost(String role) => 4.0 * ((staff[role] ?? 0) + 1);

  String? upgradeStaff(String role) {
    final lvl = staff[role] ?? 0;
    if (lvl >= 5) return 'أقصى مستوى';
    final cost = staffCost(role);
    if (cost > user.budget) return 'الميزانية غير كافية';
    user.budget -= cost;
    fin.add('upgrades', cost);
    staff[role] = lvl + 1;
    news.insert(0, '🧑\u200d🏫 ${staffRoles[role]!.$1} أصبح بالمستوى ${lvl + 1}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  List<Player> _scoutedMarket() {
    final m = generateMarket(rng);
    final lvl = staff['scout'] ?? 0;
    for (var i = 0; i < lvl; i++) {
      final p = makePlayer(rng, Pos.values[rng.nextInt(4)], 66 + rng.nextInt(10) + lvl, 19 + rng.nextInt(8));
      p.potential = min(95, max(p.potential, p.overall + 4 + rng.nextInt(8)));
      m.add(p);
    }
    return m;
  }

  void _pressHeadline(String opp, int my, int op) {
    final d = my - op;
    final h = d >= 3
        ? '📰 الصحافة: اكتساح مدوٍّ لـ${user.name} أمام $opp'
        : d > 0
            ? '📰 الصحافة: ${user.name} يواصل الانتصارات'
            : d == 0
                ? '📰 الصحافة: تعادل بطعم باهت أمام $opp'
                : d <= -3
                    ? '📰 الصحافة: كارثة! والجماهير غاضبة على المدرب'
                    : '📰 الصحافة: خسارة موجعة أمام $opp';
    news.insert(0, h);
  }

  /// مؤتمر صحفي واحد في كل أسبوع
  String? pressConference(int choice) {
    if (pressWeek == week) return 'عقدت مؤتمراً صحفياً هذا الأسبوع بالفعل';
    pressWeek = week;
    switch (choice) {
      case 0:
        confidence = min(100, confidence + 1);
        _morale(user, 2);
        fans = min(100, fans + 0.5);
        news.insert(0, '🎤 صرّحت بثقتك الكبيرة في الفريق');
      case 1:
        fans = min(100, fans + 1.5);
        if (rng.nextDouble() < 0.4) {
          confidence = max(0, confidence - 2);
          news.insert(0, '🎤 انتقدت الحكام فغضبت الإدارة');
        } else {
          news.insert(0, '🎤 هجومك على الحكام أشعل حماس الجماهير');
        }
      case 2:
        _morale(user, 4);
        news.insert(0, '🎤 أشدت بلاعبيك فارتفعت معنوياتهم');
      default:
        confidence = min(100, confidence + 2);
        fans = min(100, fans + 0.2);
        news.insert(0, '🎤 تحدثت بتواضع واحترمت المنافسين');
    }
    unawaited(save());
    notifyListeners();
    return null;
  }

  String _cupResult(Cup c) {
    if (c.champion == user.id) return 'بطل 🏆';
    String? last;
    for (final l in c.log) {
      if (l.contains(user.name)) last = l.substring(0, l.indexOf('|'));
    }
    if (last != null) return 'خرج في $last';
    return c.continental ? 'لم يتأهل' : 'لم يلعب';
  }

  void _recordSeason(int pos) {
    final top = [...user.squad]..sort((a, b) => b.goals.compareTo(a.goals));
    history.add({
      's': season,
      'pos': pos,
      'pts': user.points,
      'w': user.won,
      'd': user.drawn,
      'l': user.lost,
      'gf': user.gf,
      'ga': user.ga,
      'cup': domestic == null ? '-' : _cupResult(domestic!),
      'con': continental == null ? '-' : _cupResult(continental!),
      'scorer': top.isEmpty || top.first.goals == 0 ? '-' : '${top.first.name} (${top.first.goals})',
    });
    if (pos == 1) {
      honours.add('🏆 الدوري — الموسم $season');
      news.insert(0, '🏆🏆 بطل الدوري!');
      fans = min(100, fans + 6);
    }
  }
}
