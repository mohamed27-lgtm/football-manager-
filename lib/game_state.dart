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
import 'sponsors.dart';
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

enum TaskAction { offers, board, contracts, injuries, match }

class GameTask {
  final String id, title, body, reason, due;
  final bool urgent;
  final TaskAction action;
  const GameTask({required this.id, required this.title, required this.body, required this.reason, required this.due, required this.urgent, required this.action});
}

class SaveMeta {
  final int id, season, week, difficulty;
  final String club, league;
  final String? badge;
  final int at;
  SaveMeta(this.id, this.club, this.league, this.season, this.week, this.badge, this.at, this.difficulty);
  Map<String, dynamic> toJson() => {'id': id, 'club': club, 'league': league, 's': season, 'w': week, 'b': badge, 'at': at, 'd': difficulty};
  factory SaveMeta.fromJson(Map<String, dynamic> j) => SaveMeta(j['id'] as int, j['club'] as String, j['league'] as String,
      j['s'] as int, j['w'] as int, j['b'] as String?, (j['at'] as num).toInt(), (j['d'] as int?) ?? 1);
}

class GameState extends ChangeNotifier {
  /// يُضبط عند تسجيل الدخول ليكون لكل حساب حفظه الخاص
  static String slot = '';
  /// رقم خانة الحفظ الحالية (0 = الحفظ القديم)؛ كل مسيرة لها خانة مستقلة
  static int activeId = 0;
  int saveId = 0;
  static String _kOf(int id) => id == 0 ? 'fm_save_v2$slot' : 'fm_save_v2${slot}_g$id';
  static String get _key => _kOf(activeId);
  static String get _idxKey => 'fm_idx$slot';

  final Random rng = Random();
  late List<Team> teams;
  List<Team> upper = [], lower = []; // الدرجة الأعلى والأدنى
  String upperName = '', lowerName = '';
  int div = 1; // درجة نادي المستخدم الحالية

  /// معامل الدخل حسب الدرجة (البث والجوائز أقل في الدرجات الدنيا)
  double get divFactor => div <= 1 ? 1.0 : (div == 2 ? 0.6 : 0.4);
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
  final Set<int> watch = {};
  final List<String> oplog = [];
  void logOp(String m) {
    oplog.insert(0, 'الأسبوع ${week + 1} • $m');
    if (oplog.length > 120) oplog.removeLast();
  }

  /// مهام تحتاج قرار الرئيس — تُشتق من حالة المسيرة الفعلية فلا تتكرر ولا تضيع، وتختفي فور معالجتها
  List<GameTask> get tasks {
    final t = <GameTask>[];
    if (fired) return t;
    for (final o in offers) {
      t.add(GameTask(
        id: 'offer-${o.player.id}',
        title: 'عرض شراء ${o.player.name}',
        body: '${o.club} يعرض ${money1(o.amount)} (قيمته ${money1(o.player.value)})',
        reason: 'عرض وارد على لاعب في تشكيلتك',
        due: 'ينتهي بعد ${o.weeksLeft} جولات',
        urgent: o.weeksLeft <= 1,
        action: TaskAction.offers,
      ));
    }
    if (boardKind != null) {
      t.add(GameTask(
        id: 'board', title: 'طلب من مجلس الإدارة', body: 'ينتظر المجلس قرارك', reason: 'قرار إداري', due: 'الآن', urgent: true, action: TaskAction.board));
    }
    if (!seasonOver && rounds.length - week <= 8 && expiring.isNotEmpty) {
      t.add(GameTask(
        id: 'contracts',
        title: '${expiring.length} عقود تنتهي هذا الموسم',
        body: expiring.take(3).map((p) => p.name).join('، '),
        reason: 'سيغادرون مجاناً إن لم تجدّد',
        due: 'قبل نهاية الموسم',
        urgent: false,
        action: TaskAction.contracts,
      ));
    }
    final inj = user.squad.where((p) => p.injuredWeeks > 0).toList();
    if (inj.isNotEmpty) {
      t.add(GameTask(
        id: 'injuries',
        title: '${inj.length} إصابات في الفريق',
        body: inj.take(3).map((p) => '${p.name} (${p.injuredWeeks} أسابيع)').join('، '),
        reason: 'تؤثر على التشكيلة الأساسية',
        due: 'قبل المباراة',
        urgent: false,
        action: TaskAction.injuries,
      ));
    }
    if (seasonOver) {
      t.add(GameTask(id: 'season', title: 'انتهى الموسم', body: 'ابدأ موسماً جديداً', reason: 'نهاية الموسم', due: 'الآن', urgent: true, action: TaskAction.match));
    } else if (user.lineup.length < 11) {
      t.add(GameTask(id: 'lineup', title: 'التشكيلة غير مكتملة', body: 'اختر 11 لاعباً قبل المباراة', reason: 'لا يمكن لعب مباراة بأقل من 11', due: 'قبل المباراة', urgent: true, action: TaskAction.injuries));
    }
    return t;
  }

  String? celebration;
  void toggleWatch(Player p) {
    if (!watch.remove(p.id)) watch.add(p.id);
    notifyListeners();
    save();
  }

  /// آخر نتائج النادي (من جدول المباريات الفعلي)
  List<(Fixture, bool)> recentResults([int n = 3]) {
    final out = <(Fixture, bool)>[];
    for (final r in rounds) {
      for (final f in r) {
        if (f.played && (f.home == user.id || f.away == user.id)) out.add((f, f.home == user.id));
      }
    }
    return out.length <= n ? out : out.sublist(out.length - n);
  }

  final List<Player> loanedOut = [];
  final Map<int, double> _reserve = {};
  Cup? domestic, continental, superCup;
  Cup? activeCup;
  final Map<int, Team> foreign = {};
  final List<String> honours = [];
  final Map<String, int> staff = {'coach': 0, 'scout': 0, 'doctor': 0, 'analyst': 0, 'marketing': 0, 'director': 0};
  int? boardKind; // اجتماع إدارة معلّق
  bool boardPledge = false; // تعهّد للإدارة بإنهاء الدوري ضمن الثلاثة الأوائل
  List<int> lastXI = [];
  double fans = 50;
  int difficulty = 1; // 0 سهل، 1 عادي، 2 صعب
  bool introSeen = false;
  final List<Map<String, dynamic>> history = [];
  String bigWin = '', bigLoss = '';
  int bigWinD = 0, bigLossD = 0;
  int pressWeek = -1;
  final List<SponsorDeal> deals = [];
  Map<String, List<SponsorOffer>> sponsorOffers = {};
  int ffpBreaches = 0;
  bool transferBan = false;
  int pointsPenaltyNext = 0;
  final Map<int, double> _renewRes = {};

  Set<Player> _suspBefore = {};
  Set<Player> _injBefore = {};

  GameState.fromData(List<Team> t, int userId, this.leagueName, {Pyramid? pyramid}) {
    teams = t;
    if (pyramid != null) {
      div = pyramid.div;
      upper = pyramid.upper;
      upperName = pyramid.upperName;
      lower = pyramid.lower;
      lowerName = pyramid.lowerName;
    }
    user = teams.firstWhere((x) => x.id == userId);
    _buildFixtures();
    _setupCups(null);
    fans = 20.0 + user.reputation * 12;
    _genSponsorOffers();
    market = generateMarket(rng);
    _setObjective();
    news.add('مرحباً بك مدرباً لنادي ${user.name} في $leagueName. هدف الإدارة: المركز $objective أو أفضل.');
  }

  GameState.fromJson(Map<String, dynamic> j) {
    teams = [
      for (final t in j['teams'] as List) Team.fromJson(t as Map<String, dynamic>)
    ];
    user = teams.firstWhere((t) => t.id == j['user']);
    div = (j['div'] as int?) ?? 1;
    upperName = (j['upN'] as String?) ?? '';
    lowerName = (j['loN'] as String?) ?? '';
    upper = [for (final t in (j['upper'] as List?) ?? const []) Team.fromJson(t as Map<String, dynamic>)];
    lower = [for (final t in (j['lower'] as List?) ?? const []) Team.fromJson(t as Map<String, dynamic>)];
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
    oplog.addAll(((j['oplog'] as List?) ?? const []).cast<String>());
    watch.addAll(((j['watch'] as List?) ?? const []).cast<int>());
    final st = j['staff'] as Map<String, dynamic>?;
    if (st != null) st.forEach((k, v) => staff[k] = v as int);
    boardKind = j['bk'] as int?;
    boardPledge = (j['bp'] as bool?) ?? false;
    lastXI = [for (final x in (j['lxi'] as List?) ?? const []) x as int];
    fans = (j['fans'] as num?)?.toDouble() ?? (20.0 + user.reputation * 12);
    difficulty = (j['diff'] as int?) ?? 1;
    introSeen = (j['intro'] as bool?) ?? true;
    for (final h in (j['history'] as List?) ?? const []) {
      history.add(Map<String, dynamic>.from(h as Map));
    }
    bigWin = (j['bigWin'] as String?) ?? '';
    bigLoss = (j['bigLoss'] as String?) ?? '';
    bigWinD = (j['bigWinD'] as int?) ?? 0;
    bigLossD = (j['bigLossD'] as int?) ?? 0;
    pressWeek = (j['pressWeek'] as int?) ?? -1;
    for (final d in (j['deals'] as List?) ?? const []) {
      deals.add(SponsorDeal.fromJson(Map<String, dynamic>.from(d as Map)));
    }
    final so = j['sOffers'] as Map?;
    if (so != null) {
      sponsorOffers = {
        for (final e in so.entries)
          e.key as String: [
            for (final o in e.value as List) SponsorOffer.fromJson(Map<String, dynamic>.from(o as Map))
          ]
      };
    } else {
      _genSponsorOffers();
    }
    ffpBreaches = (j['ffpB'] as int?) ?? 0;
    transferBan = (j['ban'] as bool?) ?? false;
    pointsPenaltyNext = (j['ppn'] as int?) ?? 0;
    final cj = j['cups'] as Map<String, dynamic>?;
    if (cj != null) {
      domestic = Cup.fromJson(cj['dom'] as Map<String, dynamic>);
      continental = Cup.fromJson(cj['con'] as Map<String, dynamic>);
      if (cj['sup'] != null) superCup = Cup.fromJson(cj['sup'] as Map<String, dynamic>);
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
        'oplog': oplog,
        'watch': watch.toList(),
        'staff': staff,
        'bk': boardKind,
        'div': div,
        'upN': upperName,
        'loN': lowerName,
        'upper': [for (final t in upper) t.toJson()],
        'lower': [for (final t in lower) t.toJson()],
        'bp': boardPledge,
        'lxi': lastXI,
        'fans': fans,
        'diff': difficulty,
        'intro': introSeen,
        'history': history,
        'bigWin': bigWin,
        'bigLoss': bigLoss,
        'bigWinD': bigWinD,
        'bigLossD': bigLossD,
        'pressWeek': pressWeek,
        'deals': [for (final d in deals) d.toJson()],
        'sOffers': {
          for (final e in sponsorOffers.entries) e.key: [for (final o in e.value) o.toJson()]
        },
        'ffpB': ffpBreaches,
        'ban': transferBan,
        'ppn': pointsPenaltyNext,
        'cups': {'dom': domestic!.toJson(), 'con': continental!.toJson(), 'sup': superCup?.toJson()},
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
      final key = _kOf(saveId);
      final old = p.getString(key);
      // نسخة احتياطية: تُحفظ نسخة سابقة كل 6 حفظات حتى لا تضيع المسيرة عند خلل
      _saves++;
      if (old != null && _saves % 6 == 1) await p.setString('${key}_bak', old);
      await p.setString(key, jsonEncode(toJson()));
      await _writeMeta(p);
    } catch (_) {}
  }

  Future<void> _writeMeta(SharedPreferences p) async {
    final list = await _readIdx(p);
    list.removeWhere((m) => m.id == saveId);
    list.add(SaveMeta(saveId, user.name, leagueName, season, week, user.badge, DateTime.now().millisecondsSinceEpoch, difficulty));
    await p.setString(_idxKey, jsonEncode([for (final m in list) m.toJson()]));
  }

  static Future<List<SaveMeta>> _readIdx(SharedPreferences p) async {
    final raw = p.getString(_idxKey);
    final out = <SaveMeta>[];
    if (raw != null) {
      try {
        for (final e in jsonDecode(raw) as List) {
          final m = SaveMeta.fromJson(Map<String, dynamic>.from(e as Map));
          if (p.containsKey(_kOf(m.id))) out.add(m);
        }
      } catch (_) {}
    }
    // ترحيل الحفظ القديم (قبل الخانات المتعددة)
    if (!out.any((m) => m.id == 0) && p.containsKey(_kOf(0))) {
      try {
        final g = GameState.fromJson(jsonDecode(p.getString(_kOf(0))!) as Map<String, dynamic>);
        out.add(SaveMeta(0, g.user.name, g.leagueName, g.season, g.week, g.user.badge, 0, g.difficulty));
      } catch (_) {}
    }
    return out;
  }

  static Future<List<SaveMeta>> listSaves() async {
    try {
      final p = await SharedPreferences.getInstance();
      final l = await _readIdx(p);
      l.sort((a, b) => b.at.compareTo(a.at));
      return l;
    } catch (_) {
      return [];
    }
  }

  /// معرّف جديد لمسيرة جديدة
  static Future<int> newSaveId() async {
    final l = await listSaves();
    return l.fold<int>(0, (a, m) => m.id > a ? m.id : a) + 1;
  }

  static Future<void> deleteSave(int id) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kOf(id));
      await p.remove('${_kOf(id)}_bak');
      final l = await _readIdx(p);
      l.removeWhere((m) => m.id == id);
      await p.setString(_idxKey, jsonEncode([for (final m in l) m.toJson()]));
    } catch (_) {}
  }

  static int _saves = 0;

  static Future<bool> hasBackup() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.containsKey('${_key}_bak');
    } catch (_) {
      return false;
    }
  }

  /// يستعيد النسخة الاحتياطية مكان الحفظ الحالي
  static Future<bool> restoreBackup() async {
    try {
      final p = await SharedPreferences.getInstance();
      final b = p.getString('${_key}_bak');
      if (b == null) return false;
      await p.setString(_key, b);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasSave() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.containsKey(_key);
    } catch (_) {
      return false;
    }
  }

  static Future<GameState?> load([int? id]) async {
    try {
      if (id != null) activeId = id;
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s == null) return null;
      return GameState.fromJson(jsonDecode(s) as Map<String, dynamic>)..saveId = activeId;
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

  static const diffNames = ['سهل', 'عادي', 'صعب'];

  /// يُطبَّق مرة واحدة عند بدء المسيرة: يغيّر الميزانية الابتدائية وثقة الإدارة
  void startCareer(int d) {
    difficulty = d;
    final m = [1.3, 1.0, 0.7][d];
    user.budget = user.budget * m;
    confidence = [75.0, 60.0, 45.0][d];
    introSeen = true;
    logOp('بدء المسيرة بمستوى ${diffNames[d]}');
    unawaited(save());
    notifyListeners();
  }

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

  void setWidth(int v) {
    user.width = v;
    notifyListeners();
  }

  void setDefLine(int v) {
    user.defLine = v;
    notifyListeners();
  }

  void setPassing(int v) {
    user.passing = v;
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
    _prepMatch();
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
    h.addForm(hg > ag ? 'W' : (hg < ag ? 'L' : 'D'));
    a.addForm(hg < ag ? 'W' : (hg > ag ? 'L' : 'D'));
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
    final mk = staff['marketing'] ?? 0;
    final gate = home ? (0.3 + 0.12 * user.reputation) * (0.7 + 0.15 * user.stadium) * (0.75 + 0.5 * fans / 100) * (1 + 0.04 * mk) : 0.0;
    final broadcast = (0.35 + 0.1 * user.reputation) * divFactor;
    final sponsor = (0.25 + 0.1 * user.reputation + (position <= 3 ? 0.2 : 0.0)) * 0.5 * (0.8 + 0.4 * fans / 100) +
        dealsIncome * (0.9 + 0.2 * fans / 100);
    final sponsorX = sponsor * (1 + 0.05 * mk);
    final maintenance = 0.03 * (user.stadium + user.trainingLvl + user.academy);
    final interest = fin.debt * 0.004;
    fin.add('tickets', gate);
    fin.add('broadcast', broadcast);
    fin.add('sponsor', sponsorX);
    fin.add('wages', weeklyWages);
    fin.add('staff', staffWages);
    fin.add('maintenance', maintenance);
    fin.add('interest', interest);
    user.budget += gate + broadcast + sponsorX - weeklyWages - staffWages - maintenance - interest;
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

    if (week == rounds.length ~/ 2 && ffpRatio > 0.85) {
      news.insert(0, '⚠️ تحذير اللعب المالي النظيف: الرواتب ${(ffpRatio * 100).round()}% من الإيرادات (الحد 85%)');
    }
    _transferTick();
    _boardTick();
    week++;
    if (week >= 4) transferBan = false;
    _enforceRegistration();
    if (week % 4 == 0) market = _scoutedMarket();
    if (week >= rounds.length) seasonOver = true;
    _advanceCups();
    sim = null;
    unawaited(save());
    notifyListeners();
  }

  // ───────── مجلس الإدارة ─────────
  static const boardTitles = <int, (String, String, String, String)>{
    0: ('عرض من مجلس الإدارة', 'تُخصَّص 6M لتعزيز الفريق مقابل تعهّدك بإنهاء الدوري ضمن الثلاثة الأوائل.', 'أقبل التعهد', 'أرفض'),
    1: ('غضب الجماهير من الأسعار', 'الجماهير تطالب بخفض أسعار التذاكر. الخفض يرضيهم لكنه يكلّف النادي.', 'أخفّض الأسعار', 'أُبقيها'),
    2: ('ضغط مالي', 'الرئيس يطلب بيع أحد النجوم لتخفيف الأعباء المالية.', 'أسمح بعروض', 'أرفض'),
  };

  void _boardTick() {
    if (boardKind != null || seasonOver || week < 5 || week % 9 != 0) return;
    boardKind = rng.nextInt(3);
    news.insert(0, '🏛️ دعاك مجلس الإدارة إلى اجتماع: ${boardTitles[boardKind]!.$1}');
  }

  void answerBoard(bool yes) {
    final k = boardKind;
    if (k == null) return;
    switch (k) {
      case 0:
        if (yes) {
          user.budget += 6;
          fin.add('prize', 6);
          boardPledge = true;
          news.insert(0, '🏛️ قبلت التعهد وحصلت على 6.0M');
        } else {
          confidence = max(0, confidence - 2);
          news.insert(0, '🏛️ رفضت عرض الإدارة');
        }
      case 1:
        if (yes) {
          fans = min(100, fans + 4);
          user.budget -= 1.5;
          fin.add('upgrades', 1.5);
          news.insert(0, '🏛️ خفّضت الأسعار: الجماهير سعيدة (تكلفة 1.5M)');
        } else {
          fans = max(0, fans - 3);
          user.budget += 1.5;
          fin.add('tickets', 1.5);
          news.insert(0, '🏛️ أبقيت الأسعار: +1.5M لكن الجماهير غاضبة');
        }
      default:
        if (yes) {
          final cand = user.squad.where((p) => !p.onLoan).toList()..sort((a, b) => b.value.compareTo(a.value));
          if (cand.isNotEmpty && windowOpen && !offers.any((o) => o.player == cand.first)) {
            final others = teams.where((t) => t != user).toList();
            offers.add(Offer(cand.first, others[rng.nextInt(others.length)].name, max(0.1, (cand.first.value * 1.2 * 10).round() / 10), 3));
            news.insert(0, '🏛️ وصل عرض مغرٍ لـ${cand.first.name}');
          } else {
            news.insert(0, '🏛️ لا يمكن بيع لاعب الآن (نافذة الانتقالات مغلقة)');
          }
        } else {
          confidence = max(0, confidence - 4);
          news.insert(0, '🏛️ رفضت طلب الرئيس، وثقته بك تراجعت');
        }
    }
    boardKind = null;
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
  double agentFee(double price) =>
      price <= 0 ? 0 : max(0.1, (price * 0.05 * (1 - 0.1 * (staff['director'] ?? 0)) * 10).round() / 10);
  double loanFee(Player p) => max(0.1, (p.value * 0.12 * 10).round() / 10);
  double loanOutFee(Player p) => max(0.1, (p.value * 0.1 * 10).round() / 10);

  /// جولة تفاوض: يقبل البائع إذا بلغ عرضك حدّه الخفي، وإلا يعرض سعراً مضاداً (3 جولات)
  NegoResult evaluateOffer(Player p, double offer, int round) {
    final ask = buyPrice(p);
    final reserve = _reserve.putIfAbsent(p.id, () => ask * (0.84 + rng.nextDouble() * 0.12) * (1 - 0.02 * (staff['director'] ?? 0)));
    if (offer >= ask - 0.0001) return const NegoResult('accept', null, 'وافق النادي البائع.');
    if (offer >= reserve) return const NegoResult('accept', null, 'وافق النادي على عرضك.');
    if (round >= 2 && rng.nextDouble() < 0.1 + (p.overall >= 75 ? 0.08 : 0.0)) {
      market.remove(p);
      _reserve.remove(p.id);
      news.insert(0, '🏃 خطف نادٍ منافس ${p.name} أثناء تفاوضك');
      return const NegoResult('reject', null, 'تدخّل نادٍ منافس بعرض أعلى وخطف اللاعب!');
    }
    if (round >= 3) return const NegoResult('reject', null, 'انسحب البائع من المفاوضات. جرّب لاحقاً.');
    final c = max(reserve, offer + (ask - offer) * 0.5);
    final counter = min(ask, (c * 10).round() / 10);
    return NegoResult('counter', counter, 'عرض مضاد من البائع: ${money1(counter)}');
  }

  void endNegotiation(Player p) => _reserve.remove(p.id);

  /// استعداد اللاعب للانضمام: 0 يرحّب، 1 متردد، 2 يرفض
  int joinOutlook(Player p) {
    final a = user.strength + user.reputation * 2 + (position <= 4 ? 2 : 0) + (p.age >= 30 ? 4 : 0) + (p.free ? 3 : 0);
    final gap = p.overall - a;
    if (gap <= 2) return 0;
    if (gap <= 6) return 1;
    return 2;
  }

  String? _refusal(Player p) {
    final o = joinOutlook(p);
    if (o == 2 || (o == 1 && (p.id + week) % 2 == 0)) {
      news.insert(0, '🙅 رفض ${p.name} الانضمام إلى ${user.name}');
      return 'رفض ${p.name} الانتقال: يرى ناديك أقل من طموحه الآن';
    }
    return null;
  }

  String? buy(Player p) => completeSigning(p, buyPrice(p));

  /// إتمام الصفقة: عمولة الوكيل + الفحص الطبي (قد يُلغي الصفقة أو يكشف إصابة)
  String? completeSigning(Player p, double price) {
    final werr = _incomingErr(p.free);
    if (werr != null) return werr;
    if (user.squad.length >= 30) return 'التشكيلة ممتلئة (30 لاعباً كحد أقصى)';
    final refused = _refusal(p);
    if (refused != null) return refused;
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
    p.salary = null;
    user.squad.add(p);
    _registerNew(p);
    market.remove(p);
    news.insert(0, '💼 تعاقدت مع ${p.name} مقابل ${money1(price)} + عمولة وكيل ${money1(fee)}$note');
    logOp('تعاقد مع ${p.name} (-${money1(price + fee)})');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// إعارة بخيار شراء (إلزامية إن كان obligation) بقيمة محددة سلفاً
  String? loanInOption(Player p, {bool obligation = false}) {
    final werr = _incomingErr(false);
    if (werr != null) return werr;
    if (user.squad.length >= 30) return 'التشكيلة ممتلئة (30 لاعباً كحد أقصى)';
    final refused = _refusal(p);
    if (refused != null) return refused;
    final fee = max(0.1, (loanFee(p) * (obligation ? 0.6 : 0.85) * 10).round() / 10);
    if (fee > user.budget) return 'الميزانية غير كافية';
    user.budget -= fee;
    fin.add('loanin', fee);
    p
      ..onLoan = true
      ..free = false
      ..listed = false
      ..contract = 1
      ..morale = 75
      ..optionFee = max(0.1, (buyPrice(p) * (obligation ? 1.0 : 1.05) * 10).round() / 10)
      ..obligation = obligation;
    user.squad.add(p);
    _registerNew(p);
    market.remove(p);
    news.insert(0, '🔄 استعرت ${p.name} ${obligation ? 'بإلزامية شراء' : 'بخيار شراء'} (${money1(p.optionFee!)}) مقابل ${money1(fee)}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? exerciseOption(Player p) {
    final fee = p.optionFee;
    if (!p.onLoan || fee == null) return 'لا يوجد خيار شراء';
    if (fee > user.budget) return 'الميزانية غير كافية لتفعيل الخيار (${money1(fee)})';
    user.budget -= fee;
    fin.add('purchases', fee);
    p
      ..onLoan = false
      ..optionFee = null
      ..obligation = false
      ..contract = 3;
    news.insert(0, '✅ فعّلت خيار شراء ${p.name} مقابل ${money1(fee)}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? loanIn(Player p) {
    final werr = _incomingErr(false);
    if (werr != null) return werr;
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
    _registerNew(p);
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
    if (!windowOpen) return _closedMsg;
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
    if (!windowOpen) return _closedMsg;
    final err = _cannotLose(o.player);
    if (err != null) return err;
    user.squad.remove(o.player);
    user.budget += o.amount;
    fin.add('sales', o.amount);
    offers.remove(o);
    user.repairLineup();
    news.insert(0, '💰 بعت ${o.player.name} إلى ${o.club} مقابل ${money1(o.amount)}');
    logOp('بيع ${o.player.name} إلى ${o.club} (+${money1(o.amount)})');
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
    if (windowOpen && user.squad.length > 16 && offers.length < 3) {
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
    if (windowOpen) _aiTransfers();
    if (windowOpen && market.length > 8 && rng.nextDouble() < 0.25) {
      final top = [...market]..sort((a, b) => b.overall.compareTo(a.overall));
      final pick = top[rng.nextInt(min(6, top.length))];
      final club = teams.where((t) => t != user).toList()[rng.nextInt(teams.length - 1)];
      market.remove(pick);
      news.insert(0, '🏃 سبقك ${club.name} إلى ${pick.free ? 'توقيع' : 'ضم'} ${pick.name}');
    }
  }

  /// صفقات بين الأندية الأخرى: تتحرك النجوم فتتغير قوة الفرق خلال الموسم
  void _aiTransfers() {
    final pool = teams.where((t) => t != user).toList();
    if (pool.length < 4) return;
    final n = rng.nextDouble() < 0.4 ? 2 : 1;
    for (var i = 0; i < n; i++) {
      final from = pool[rng.nextInt(pool.length)];
      final cands = from.squad.where((p) => p.overall >= 62 && !p.onLoan).toList();
      if (cands.isEmpty || from.squad.length <= 18) continue;
      final p = cands[rng.nextInt(cands.length)];
      final buyers = pool.where((t) => t != from && t.squad.length < 28 && t.budget >= p.value && t.strength + 4 >= p.overall).toList();
      if (buyers.isEmpty) continue;
      final to = buyers[rng.nextInt(buyers.length)];
      final fee = (p.value * (0.9 + rng.nextDouble() * 0.4) * 10).round() / 10;
      from.squad.remove(p);
      to.squad.add(p);
      from.budget += fee;
      to.budget -= fee;
      from.repairLineup();
      news.insert(0, '🔁 ${p.name} ينتقل من ${from.name} إلى ${to.name} (${money1(fee)})');
    }
    if (news.length > 150) news.removeRange(150, news.length);
  }

  String? sell(Player p) {
    if (p.onLoan) return 'لا يمكن بيع لاعب معار';
    if (!windowOpen) return _closedMsg;
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
    logOp('بيع ${p.name} (+${money1(price)})');
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
    logOp('تجديد عقد ${p.name} 3 سنوات (-${money1(cost)})');
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
    logOp('إنهاء عقد ${p.name} (-${money1(cost)})');
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
    final finalTable = table;
    final qualT = finalTable.take(3).toList();
    final champT = finalTable.first;
    final runnerT = finalTable.length > 1 ? finalTable[1] : finalTable.first;
    final cupWinner = domestic?.champion;
    final cupT = cupWinner == null ? null : team(cupWinner);
    final aw = _seasonAwards(pos);
    _recordSeason(pos, aw);
    _ffpReview();
    fin.season.clear();
    for (final p in user.squad.where((p) => p.onLoan).toList()) {
      if (p.obligation && p.optionFee != null) {
        user.budget -= p.optionFee!;
        fin.add('purchases', p.optionFee!);
        news.insert(0, '📝 فُعّلت إلزامية شراء ${p.name} (${money1(p.optionFee!)})');
        p
          ..onLoan = false
          ..optionFee = null
          ..obligation = false
          ..contract = 3;
        continue;
      }
      p.optionFee = null;
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
    if (boardPledge) {
      if (pos <= 3) {
        confidence = min(100, confidence + 10);
        news.insert(0, '🤝 وفيت بتعهدك للإدارة بإنهاء الدوري ضمن الثلاثة الأوائل');
      } else {
        confidence = max(0, confidence - 10);
        news.insert(0, '😠 أخلفت تعهدك للإدارة، وثقتهم بك تراجعت');
      }
      boardPledge = false;
    }
    if (pos <= objective) {
      confidence = min(100, confidence + 12);
      user.budget += 2;
      fin.add('prize', 2);
      news.insert(0, '🎯 حققت هدف الإدارة (المركز $pos)! مكافأة 2.0M');
    } else {
      confidence = max(0, confidence - (pos > objective + 2 ? 15 : 10));
      news.insert(0, '😕 لم تحقق هدف الإدارة (المركز $pos بدل $objective)');
    }
    final prize = max(0.0, (teams.length + 1 - pos) * 0.9 * 12 / teams.length) * divFactor;
    user.budget += prize;
    fin.add('prize', prize);
    news.insert(0, '🏆 أنهيت الموسم $season في المركز $pos — جائزة ${prize.toStringAsFixed(1)}M');

    for (final t in [...teams, ...upper, ...lower]) {
      for (final p in [...t.squad]) {
        p.age++;
        p.contract--;
        // تطور اللاعب: العمر + الأداء الموسمي (التقييم والمشاركات) + مستوى التدريب
        final played = p.apps >= 15;
        final form = p.rated == 0 ? 0 : (p.avgRating >= 7.3 ? 1 : (p.avgRating <= 6.2 && played ? -1 : 0));
        final train = t == user ? (user.trainingLvl >= 3 ? 1 : 0) : 0;
        if (p.age <= 24) {
          if (p.overall < p.potential) {
            var g = 1 + rng.nextInt(3) + (p.apps >= 18 ? 1 : (p.apps < 5 ? -1 : 0)) + (form > 0 ? 1 : 0) + train;
            _grow(p, max(0, min(g, p.potential - p.overall)));
          }
        } else if (p.age <= 30) {
          // قمة العطاء: يتغير قليلاً حسب الأداء فقط
          if (form > 0 && p.overall < p.potential + 2 && rng.nextDouble() < 0.5) _grow(p, 1);
          if (form < 0 && rng.nextDouble() < 0.5) _grow(p, -1);
        } else {
          _grow(p, -(rng.nextInt(3) + (p.age >= 34 ? 1 : 0)) + (form > 0 ? 1 : 0));
        }
        if (p.apps > 0) {
          p.career.add({
            's': season,
            't': t.name,
            'a': p.apps,
            'g': p.goals,
            'as': p.assists,
            'r': double.parse(p.avgRating.toStringAsFixed(2)),
          });
          if (p.career.length > 12) p.career.removeAt(0);
        }
        p.ratingSum = 0;
        p.rated = 0;
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
      t.form = [];
      t.won = 0;
      t.drawn = 0;
      t.lost = 0;
      t.gf = 0;
      t.ga = 0;
      t.penalty = 0;
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

    for (final d in deals) {
      d.years--;
    }
    for (final d in deals.where((d) => d.years <= 0)) {
      news.insert(0, '📄 انتهى عقد الرعاية مع ${d.brand}');
    }
    deals.removeWhere((d) => d.years <= 0);
    _movePyramid(finalTable, pos);
    season++;
    week = 0;
    if (pointsPenaltyNext > 0) {
      user.penalty = pointsPenaltyNext;
      news.insert(0, '⛔ خصم $pointsPenaltyNext نقاط من رصيدك بسبب مخالفة اللعب المالي النظيف');
      pointsPenaltyNext = 0;
    }
    _genSponsorOffers();
    _enforceRegistration();
    seasonOver = false;
    roundResults.clear();
    _buildFixtures();
    final qualIds = qualT.every(teams.contains) ? [for (final t in qualT) t.id] : null;
    _setupCups(qualIds);
    if (div == 1 && teams.contains(champT) && teams.contains(runnerT) && (cupT == null || teams.contains(cupT))) {
      _setupSuper(champT.id, cupT?.id, runnerT.id);
    } else {
      superCup = null;
    }
    market = _scoutedMarket();
    _setObjective();
    if (confidence <= 0) fired = true;
    _advanceCups();
    news.insert(0, '📋 هدف الإدارة للموسم $season: المركز $objective أو أفضل');
    unawaited(save());
    notifyListeners();
  }

  // ───────── الصعود والهبوط بين الدرجات ─────────
  int _pois(double l) {
    final lim = exp(-l);
    var k = 0;
    var p = 1.0;
    do {
      k++;
      p *= rng.nextDouble();
    } while (p > lim);
    return k - 1;
  }

  /// محاكاة سريعة لموسم دوري لا يلعبه المستخدم، وإرجاع ترتيبه النهائي
  List<Team> _quickRank(List<Team> ts) {
    final pts = <Team, int>{for (final t in ts) t: 0};
    final gd = <Team, int>{for (final t in ts) t: 0};
    for (final h in ts) {
      for (final a in ts) {
        if (identical(h, a)) continue;
        final r = (h.strength / a.strength).clamp(0.6, 1.6).toDouble();
        final hg = _pois((1.45 * pow(r, 2.2) * 1.08).clamp(0.3, 4.0).toDouble());
        final ag = _pois((1.2 * pow(1 / r, 2.2) / 1.08).clamp(0.3, 4.0).toDouble());
        gd[h] = gd[h]! + hg - ag;
        gd[a] = gd[a]! + ag - hg;
        if (hg > ag) {
          pts[h] = pts[h]! + 3;
        } else if (hg < ag) {
          pts[a] = pts[a]! + 3;
        } else {
          pts[h] = pts[h]! + 1;
          pts[a] = pts[a]! + 1;
        }
      }
    }
    return [...ts]..sort((x, y) {
        final c = pts[y]!.compareTo(pts[x]!);
        if (c != 0) return c;
        final g = gd[y]!.compareTo(gd[x]!);
        return g != 0 ? g : y.strength.compareTo(x.strength);
      });
  }

  /// نهاية الموسم: يصعد أول الفرق من الدرجة الأدنى ويهبط آخر الفرق من الأعلى (وفي الاتجاه المعاكس)
  void _movePyramid(List<Team> finalTable, int pos) {
    final k = max(1, min(3, teams.length ~/ 6));
    final hasLow = lower.length >= k * 2;
    final hasUp = upper.length >= k * 2;
    if (!hasLow && !hasUp) return;
    final down = hasLow ? finalTable.sublist(finalTable.length - k) : <Team>[];
    final up = hasLow ? _quickRank(lower).take(k).toList() : <Team>[];
    final goUp = hasUp ? finalTable.take(k).toList() : <Team>[];
    final fall = hasUp ? _quickRank(upper).reversed.take(k).toList() : <Team>[];
    final mid = [...teams.where((t) => !down.contains(t) && !goUp.contains(t)), ...up, ...fall];
    final newUpper = [...upper.where((t) => !fall.contains(t)), ...goUp];
    final newLower = [...lower.where((t) => !up.contains(t)), ...down];
    final oldName = leagueName;
    if (goUp.contains(user)) {
      news.insert(0, '🔼 صعدت إلى $upperName! أنهيت الموسم في المركز $pos');
      confidence = min(100, confidence + 20);
      user.budget += 4;
      fin.add('prize', 4);
      teams = newUpper;
      leagueName = upperName;
      lower = mid;
      lowerName = oldName;
      upper = [];
      upperName = '';
      div = max(1, div - 1);
    } else if (down.contains(user)) {
      news.insert(0, '🔽 هبطت إلى $lowerName بعد إنهاء الموسم في المركز $pos');
      confidence = max(0, confidence - 25);
      teams = newLower;
      leagueName = lowerName;
      upper = mid;
      upperName = oldName;
      lower = [];
      lowerName = '';
      div++;
    } else {
      teams = mid;
      upper = newUpper;
      lower = newLower;
      if (up.isNotEmpty || fall.isNotEmpty) {
        news.insert(0, '🔁 صعد ${up.map((t) => t.name).join('، ')} وهبط ${down.map((t) => t.name).join('، ')} في ${hasLow ? lowerName : upperName}');
      }
    }
    for (final l in [teams, upper, lower]) {
      for (var i = 0; i < l.length; i++) {
        l[i].id = i;
        l[i]
          ..played = 0
          ..won = 0
          ..drawn = 0
          ..lost = 0
          ..gf = 0
          ..ga = 0
          ..penalty = 0
          ..form = [];
      }
    }
    for (final t in teams) {
      if (t != user) t.autoPick();
    }
    _setObjective();
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
    const extraNames = ['سبارتا الشمال', 'فيورينتينا الهضاب', 'أنتويرب الميناء'];
    final extra = div > 1 ? extraNames.length : 0;
    for (var i = 0; i < foreignClubNames.length + extra; i++) {
      final nm = i < foreignClubNames.length ? foreignClubNames[i] : extraNames[i - foreignClubNames.length];
      foreign[1000 + i] = createTeam(rng, 1000 + i, nm, 3 + rng.nextInt(3));
    }
    final q = div > 1 ? <int>[] : qual ?? [for (final t in ([...teams]..sort((a, b) => b.strength.compareTo(a.strength))).take(3)) t.id];
    continental = Cup(
      key: 'con',
      name: 'دوري الأبطال القاري',
      continental: true,
      schedule: sched(6, 3),
      size: 16,
      alive: [...q, ...foreign.keys],
    );
    final sorted = [...continental!.alive]..sort((a, b) => team(b).strength.compareTo(team(a).strength));
    final pots = [
      for (var k = 0; k < 4; k++) (sorted.sublist(k * 4, k * 4 + 4)..shuffle(rng))
    ];
    continental!.groups = [
      for (var gI = 0; gI < 4; gI++) [for (final pot in pots) pot[gI]]
    ];
    _draw(continental!);
  }

  void _draw(Cup c) {
    if (c.inGroups) {
      const pat = [
        [(0, 1), (2, 3)],
        [(0, 2), (3, 1)],
        [(3, 0), (1, 2)],
      ];
      c.byes = [];
      c.ties = [
        for (final g in c.groups)
          for (final pr in pat[c.round]) Tie(g[pr.$1], g[pr.$2])
      ];
      return;
    }
    final ids = [...c.alive];
    c.size = _pow2(ids.length);
    final nb = c.size - ids.length;
    ids.sort((a, b) => team(b).strength.compareTo(team(a).strength));
    c.byes = ids.take(nb).toList();
    final rest = ids.skip(nb).toList()..shuffle(rng);
    c.ties = [for (var i = 0; i + 1 < rest.length; i += 2) Tie(rest[i], rest[i + 1])];
  }

  void _setTie(Tie t, int hg, int ag, {bool pens = true}) {
    t.hg = hg;
    t.ag = ag;
    if (hg == ag && pens) {
      final pHome = (0.5 + (team(t.home).strength - team(t.away).strength) * 0.01).clamp(0.35, 0.65).toDouble();
      final homeWins = rng.nextDouble() < pHome;
      final w = 3 + rng.nextInt(3);
      final l = max(0, w - 1 - rng.nextInt(2));
      t.ph = homeWins ? w : l;
      t.pa = homeWins ? l : w;
    }
  }

  void _playAiTie(Tie t, {bool pens = true}) {
    final m = MatchSim(team(t.home), team(t.away), random: rng)..simulateAll();
    _setTie(t, m.home.goals, m.away.goals, pens: pens);
  }

  void _closeRoundIfDone(Cup c) {
    if (c.ties.any((t) => !t.played)) return;
    if (c.inGroups) {
      c.gdone.addAll(c.ties);
      for (final t in c.ties) {
        c.log.add('${c.roundName}|${t.text((i) => team(i).name)}');
      }
      c.round++;
      if (c.round < 3) {
        _draw(c);
        return;
      }
      final q = <int>[];
      for (final grp in c.groups) {
        final tb = groupTable(c, grp);
        q..add(tb[0].id)..add(tb[1].id);
      }
      final userWas = c.alive.contains(user.id);
      c.alive = q;
      if (userWas) {
        if (q.contains(user.id)) {
          user.budget += 3.0;
          fin.add('prize', 3.0);
          news.insert(0, '🏅 تأهلت من دور المجموعات في ${c.name} — مكافأة ${money1(3.0)}');
        } else {
          news.insert(0, '👋 ودّعت ${c.name} من دور المجموعات');
        }
      }
      _draw(c);
      return;
    }
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
        final bonus = c.continental ? 10.0 : (c.key == 'sup' ? 2.0 : 3.0);
        user.budget += bonus;
        fin.add('prize', bonus);
        confidence = min(100, confidence + 10);
        honours.add('🏆 ${c.name} — الموسم $season');
        celebration = c.name;
        news.insert(0, '🏆🏆 بطل ${c.name}! مكافأة ${money1(bonus)}');
      } else {
        news.insert(0, '🏆 ${team(winners.first).name} بطل ${c.name}');
      }
    } else {
      _draw(c);
    }
  }

  void _advanceCups() {
    for (final c in [domestic, continental, superCup]) {
      if (c == null) continue;
      while (!c.done && c.dueWeek != null && c.dueWeek! <= week) {
        if (c.userTie(user.id) != null) break;
        for (final t in c.ties.where((t) => !t.played)) {
          _playAiTie(t, pens: !c.inGroups);
        }
        _closeRoundIfDone(c);
      }
    }
  }

  /// بطولة تنتظر مباراتك الآن (تُلعب قبل مباراة الدوري)
  Cup? get pendingCup {
    if (seasonOver || fired) return null;
    for (final c in [domestic, continental, superCup]) {
      if (c != null && !c.done && c.dueWeek != null && c.dueWeek! <= week && c.userTie(user.id) != null) {
        return c;
      }
    }
    return null;
  }

  /// قبل كل مباراة: مستوى المحلل + تحديث الانسجام حسب استقرار التشكيلة
  void _prepMatch() {
    user.analystLvl = staff['analyst'] ?? 0;
    final ids = [for (final p in user.lineup) p.id];
    if (lastXI.isNotEmpty && ids.length == 11) {
      final changes = 11 - ids.where(lastXI.contains).length;
      user.cohesion = (user.cohesion + (changes <= 2 ? 1.5 : -1.2 * (changes - 2))).clamp(30, 100).toDouble();
    }
    if (ids.length == 11) lastXI = ids;
  }

  void startCupMatch(Cup c) {
    final t = c.userTie(user.id);
    if (t == null) return;
    _suspBefore = {...user.squad.where((p) => p.suspendedMatches > 0)};
    _injBefore = {...user.squad.where((p) => p.injuredWeeks > 0)};
    final h = team(t.home), a = team(t.away);
    activeCup = c;
    _prepMatch();
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
    final grp = c.inGroups;
    _setTie(t, s.home.goals, s.away.goals, pens: !grp);
    final mine = t.home == user.id ? s.home.goals - s.away.goals : s.away.goals - s.home.goals;
    final won = grp ? mine > 0 : t.winner == user.id;
    final lost = grp ? mine < 0 : t.winner != user.id;
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
    if (won) {
      confidence = min(100, confidence + 2);
    } else if (lost) {
      confidence = max(0, confidence - 2);
      if (confidence <= 0) fired = true;
    }
    _morale(user, won ? 3 : (lost ? -3 : 0));
    for (final o in c.ties.where((x) => !x.played)) {
      _playAiTie(o, pens: !grp);
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
    'analyst': ('المحلل', 'يرفع كفاءة الفريق في المباريات (+0.8% لكل مستوى)'),
    'marketing': ('مدير التسويق', 'يزيد دخل الرعاة (+5%) والتذاكر (+4%) لكل مستوى'),
    'director': ('المدير الرياضي', 'يخفض عمولات الوكلاء ويسهّل التفاوض على الأسعار'),
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

  void _recordSeason(int pos, List<String> awards) {
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
      'awards': awards,
    });
    if (pos == 1) {
      honours.add('🏆 الدوري — الموسم $season');
      celebration = 'الدوري';
      news.insert(0, '🏆🏆 بطل الدوري!');
      fans = min(100, fans + 6);
    }
  }

  // ───────── نوافذ الانتقالات والتسجيل ─────────
  bool get windowOpen {
    final h = rounds.length ~/ 2;
    return week < 4 || (week >= h - 1 && week < h + 3);
  }

  String get windowLabel {
    final h = rounds.length ~/ 2;
    if (week < 4) return 'نافذة الصيف مفتوحة — تُغلق بعد ${4 - week} جولات';
    if (week >= h - 1 && week < h + 3) return 'نافذة الشتاء مفتوحة — تُغلق بعد ${h + 3 - week} جولات';
    if (week < h - 1) return 'النافذة مغلقة — تفتح الشتوية بعد ${h - 1 - week} جولات';
    return 'النافذة مغلقة — تفتح الصيفية مع الموسم القادم';
  }

  static const _closedMsg = 'نافذة الانتقالات مغلقة حالياً';

  String? _incomingErr(bool free) {
    if (transferBan) return 'عليك حظر انتقالات بسبب مخالفة اللعب المالي النظيف';
    if (!free && !windowOpen) return _closedMsg;
    return null;
  }

  static const regLimit = 25;
  int get registeredCount => user.squad.where((p) => p.registered && p.age > 21).length;

  void _registerNew(Player p) {
    p.registered = true;
    if (p.age > 21 && registeredCount > regLimit) {
      p.registered = false;
      news.insert(0, '📝 ${p.name} غير مسجّل: قائمة الـ$regLimit ممتلئة (يمكنك تبديل التسجيل)');
    }
  }

  void _enforceRegistration() {
    var changed = false;
    while (registeredCount > regLimit) {
      final cands = user.squad.where((p) => p.registered && p.age > 21).toList()
        ..sort((a, b) => a.overall.compareTo(b.overall));
      cands.first.registered = false;
      changed = true;
    }
    if (changed) user.repairLineup();
  }

  String? toggleRegistration(Player p) {
    if (!windowOpen) return 'تغيير التسجيل ممكن فقط خلال نافذة الانتقالات';
    if (p.registered) {
      p.registered = false;
      user.repairLineup();
    } else {
      if (p.age > 21 && registeredCount >= regLimit) return 'قائمة التسجيل ممتلئة ($regLimit لاعباً فوق 21 سنة)';
      p.registered = true;
    }
    unawaited(save());
    notifyListeners();
    return null;
  }

  // ───────── اللعب المالي النظيف ─────────
  double get ffpRevenue =>
      (fin.season['tickets'] ?? 0) + (fin.season['broadcast'] ?? 0) + (fin.season['sponsor'] ?? 0) + (fin.season['prize'] ?? 0);
  double get ffpWages => (fin.season['wages'] ?? 0) + (fin.season['staff'] ?? 0);
  double get ffpRatio => ffpRevenue <= 0 ? 0 : ffpWages / ffpRevenue;

  void _ffpReview() {
    final r = ffpRatio;
    if (ffpRevenue <= 0) return;
    if (r > 0.85) {
      ffpBreaches++;
      final fine = 2.0 * ffpBreaches;
      user.budget -= fine;
      fin.add('upgrades', fine);
      news.insert(0, '⚖️ مخالفة اللعب المالي النظيف (الرواتب ${(r * 100).round()}% من الإيرادات): غرامة ${money1(fine)}');
      if (ffpBreaches >= 2) {
        transferBan = true;
        news.insert(0, '⛔ حظر انتقالات في الصيف القادم');
      }
      if (r > 1.0 || ffpBreaches >= 3) pointsPenaltyNext = 6;
    } else {
      ffpBreaches = max(0, ffpBreaches - 1);
    }
  }

  // ───────── الرعاة ─────────
  double get dealsIncome => deals.fold(0.0, (a, d) => a + d.weekly);

  void _genSponsorOffers() {
    sponsorOffers = {};
    for (final type in sponsorTypes.keys) {
      if (deals.any((d) => d.type == type)) continue;
      final pool = sponsorBrands[type]!.where((b) => tierFans[b.$2]! <= fans).toList()..shuffle(rng);
      final offers = <SponsorOffer>[];
      for (final b in pool.take(3)) {
        final years = 1 + rng.nextInt(4);
        final base = (0.2 + 0.09 * user.reputation) * typeMult[type]! * tierMult[b.$2]! * (1 + 0.05 * (4 - years));
        final weekly = (base * 100).round() / 100;
        final bonus = years >= 3 ? (weekly * 4 * 10).round() / 10 : 0.0;
        offers.add(SponsorOffer(SponsorDeal(type, b.$1, weekly, years), bonus));
      }
      sponsorOffers[type] = offers;
    }
  }

  String? signSponsor(SponsorOffer o) {
    if (deals.any((d) => d.type == o.deal.type)) return 'لديك صفقة سارية من هذا النوع';
    deals.add(SponsorDeal(o.deal.type, o.deal.brand, o.deal.weekly, o.deal.years));
    sponsorOffers.remove(o.deal.type);
    if (o.bonus > 0) {
      user.budget += o.bonus;
      fin.add('sponsor', o.bonus);
    }
    news.insert(0, '🤝 وقّعت مع ${o.deal.brand} (${sponsorTypes[o.deal.type]}) لمدة ${o.deal.years} سنوات');
    unawaited(save());
    notifyListeners();
    return null;
  }

  double cancelCost(SponsorDeal d) => (d.weekly * 8 * 10).round() / 10 + 0.1;

  String? cancelSponsor(SponsorDeal d) {
    final c = cancelCost(d);
    if (c > user.budget) return 'الميزانية لا تكفي للغرامة';
    user.budget -= c;
    fin.add('upgrades', c);
    deals.remove(d);
    fans = max(0, fans - 1);
    news.insert(0, '✂️ أنهيت عقد ${d.brand} بغرامة ${money1(c)}');
    _genSponsorOffers();
    unawaited(save());
    notifyListeners();
    return null;
  }

  // ───────── تجديد العقود بالتفاوض ─────────
  double renewDemand(Player p) {
    var m = 1.1;
    if (p.age <= 27) m += 0.2;
    if (p.morale < 50) m += 0.2;
    if (p.overall >= 72) m += 0.15;
    return max(p.wage, p.baseWage) * m;
  }

  double renewBonus(double wage) => (wage * 10 * 100).round() / 100;

  NegoResult renewOffer(Player p, double wage, int years) {
    final dem = renewDemand(p);
    final res = _renewRes.putIfAbsent(p.id, () => dem * (0.92 + rng.nextDouble() * 0.08));
    final bonus = renewBonus(wage);
    final fee = agentFee(bonus);
    if (bonus + fee > user.budget) {
      return NegoResult('reject', null, 'الميزانية لا تكفي لمكافأة التوقيع (${(bonus + fee).toStringAsFixed(2)}M)');
    }
    if (wage >= res) {
      user.budget -= bonus + fee;
      fin.add('renewals', bonus);
      fin.add('agents', fee);
      p.salary = wage;
      p.contract = years;
      p.morale = min(100, p.morale + 6);
      _renewRes.remove(p.id);
      news.insert(0, '✍️ جدّدت عقد ${p.name} لـ$years سنوات براتب ${(wage * 1000).round()}K أسبوعياً');
      unawaited(save());
      notifyListeners();
      return const NegoResult('accept', null, 'وافق اللاعب على التجديد');
    }
    final counter = (dem * 1000).ceil() / 1000;
    return NegoResult('counter', counter, 'اللاعب يطلب راتباً لا يقل عن ${(counter * 1000).round()}K أسبوعياً');
  }

  // ───────── كأس السوبر والجوائز الفردية ─────────
  void _setupSuper(int champ, int? cupWinner, int runner) {
    final other = (cupWinner == null || cupWinner == champ) ? runner : cupWinner;
    if (other == champ) {
      superCup = null;
      return;
    }
    superCup = Cup(
      key: 'sup',
      name: 'كأس السوبر',
      continental: false,
      schedule: [0],
      size: 2,
      alive: [champ, other],
    );
    _draw(superCup!);
    news.insert(0, '🏟️ كأس السوبر: ${team(champ).name} × ${team(other).name}');
  }

  List<String> _seasonAwards(int pos) {
    final out = <String>[];
    final tb = table;
    int rankOf(Team t) => tb.indexOf(t) + 1;
    final all = <(Player, Team)>[
      for (final t in teams)
        for (final p in t.squad)
          if (p.apps > 0) (p, t)
    ];
    if (all.isEmpty) return out;
    double sc((Player, Team) e) =>
        e.$1.goals * 2.0 + e.$1.assists * 1.5 + e.$1.overall * 0.25 + (teams.length - rankOf(e.$2)) * 0.2;
    (Player, Team) best(Iterable<(Player, Team)> l, double Function((Player, Team)) f) =>
        l.reduce((a, b) => f(b) > f(a) ? b : a);

    void give(String title, (Player, Team) e, String extra) {
      out.add('$title: ${e.$1.name} (${e.$2.name}) $extra');
      if (e.$2 == user) {
        honours.add('$title — ${e.$1.name} (الموسم $season)');
        fans = min(100, fans + 3);
        news.insert(0, '🥇 $title لاعبك ${e.$1.name}!');
      }
    }

    final bd = best(all, sc);
    give('🥇 الكرة الذهبية', bd, '— ${bd.$1.goals} هدف');
    final gb = best(all, (e) => e.$1.goals * 100.0 + e.$1.assists);
    give('👟 الحذاء الذهبي', gb, '— ${gb.$1.goals} هدف');
    final pm = best(all, (e) => e.$1.assists * 100.0 + e.$1.goals);
    give('🎯 أفضل صانع ألعاب', pm, '— ${pm.$1.assists} تمريرة حاسمة');
    final gks = all.where((e) => e.$1.pos == Pos.gk);
    if (gks.isNotEmpty) {
      final gk = best(gks, (e) => e.$1.gk - e.$2.ga * 0.5);
      give('🧤 أفضل حارس', gk, '— ${gk.$2.ga} هدفاً دخل مرماه');
    }
    final young = all.where((e) => e.$1.age <= 21);
    if (young.isNotEmpty) give('🌟 أفضل لاعب شاب', best(young, sc), '');
    // مدرب العام: أكبر تفوق على ترتيب القوة
    final byStrength = [...teams]..sort((a, b) => b.strength.compareTo(a.strength));
    Team coach = tb.first;
    var bestGain = -99;
    for (final t in teams) {
      final gain = (byStrength.indexOf(t) + 1) - rankOf(t);
      if (gain > bestGain || (gain == bestGain && rankOf(t) < rankOf(coach))) {
        bestGain = gain;
        coach = t;
      }
    }
    out.add('🎖️ مدرب العام: مدرب ${coach.name}');
    if (coach == user) {
      honours.add('🎖️ مدرب العام — الموسم $season');
      confidence = min(100, confidence + 6);
      news.insert(0, '🎖️ اخترت مدرب العام!');
    }
    // التشكيلة المثالية
    final xi = <String>[];
    for (final e in const [(Pos.gk, 1), (Pos.def, 4), (Pos.mid, 3), (Pos.att, 3)]) {
      final l = all.where((x) => x.$1.pos == e.$1).toList()..sort((a, b) => sc(b).compareTo(sc(a)));
      xi.addAll(l.take(e.$2).map((x) => x.$1.name));
    }
    out.add('⭐ التشكيلة المثالية: ${xi.join('، ')}');
    return out;
  }
}
