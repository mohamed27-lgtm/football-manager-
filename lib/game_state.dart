import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'countries.dart' show kAllCountries;
import 'cups.dart';
import 'data.dart';
import 'engine.dart';
import 'finance.dart';
import 'models.dart';
import 'last_match.dart';
import 'calendar.dart';
import 'sponsors.dart';
import 'transfers.dart';
import 'world.dart';

class NextMatch {
  final String comp, round, time;
  final Team home, away;
  final DateTime date;
  final int daysUntil;
  final Cup? cup;
  const NextMatch({required this.comp, required this.round, required this.home, required this.away, required this.date, required this.time, required this.daysUntil, this.cup});
}

class ScheduledMatch {
  final String comp, key, round, time;
  final DateTime date;
  final Team? home, away;
  const ScheduledMatch({required this.comp, required this.key, required this.round, required this.date, required this.time, this.home, this.away});
}

class Fixture {
  final int home, away;
  int? hg, ag;
  Fixture(this.home, this.away);
  bool get played => hg != null;
}

const trainingModes = <String, String>{
  'technical': 'فني',
  'physical': 'بدني',
  'mental': 'ذهني',
  'tactical': 'تكتيكي',
};

/// تحويل أنماط التدريب القديمة في الحفظات
String migrateTraining(String k) => switch (k) {
      'attack' || 'balanced' => 'technical',
      'fitness' => 'physical',
      'rest' => 'mental',
      'defense' || 'passing' => 'tactical',
      _ => trainingModes.containsKey(k) ? k : 'technical',
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
  int bytes = 0; // حجم الحفظ على الجهاز (تقريبي)
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
  String country = '';
  int leagueId = 0;
  double confidence = 60;
  String training = 'technical';
  int trainIntensity = 1; // 0 خفيف، 1 متوسط، 2 مكثف
  static const intensityGain = [0.7, 1.0, 1.35];
  static const intensityRec = [4.0, 0.0, -5.0];
  bool fired = false;
  bool seasonOver = false;
  final List<String> news = [];
  final List<String> roundResults = [];
  List<Player> market = [];
  MatchSim? sim;
  Finance fin = Finance();
  final List<Offer> offers = [];
  final Set<int> watch = {};
  LastMatch? lastMatch;
  final Map<int, List<String>> h2h = {}; // خصم → آخر نتائجك أمامه (W/D/L)

  // ───────── التقويم: تاريخ ويوم ووقت كل مباراة ─────────
  /// اليوم الحالي ضمن الأسبوع (0 = الاثنين). يتقدم بعد كل مباراة كأس، ويعود للاثنين بعد جولة الدوري
  int dayCursor = 0;

  /// المباراة القادمة للمستخدم عبر كل البطولات، مرتبة بالتاريخ
  NextMatch? get nextMatch {
    if (seasonOver || fired) return null;
    final pc = pendingCup;
    if (pc != null) {
      final t = pc.userTie(user.id)!;
      final slot = GameCalendar.cup(pc.key, pc.round, t.home, t.away);
      return NextMatch(
        comp: pc.name,
        round: pc.roundName,
        home: team(t.home),
        away: team(t.away),
        date: GameCalendar.dateOf(season, week, slot.day),
        time: slot.time,
        daysUntil: slot.day - dayCursor,
        cup: pc,
      );
    }
    final f = userFixture;
    if (f == null) return null;
    final slot = GameCalendar.league(f.home, f.away, week, season);
    return NextMatch(
      comp: leagueName,
      round: 'الجولة ${week + 1}',
      home: team(f.home),
      away: team(f.away),
      date: GameCalendar.dateOf(season, week, slot.day),
      time: slot.time,
      daysUntil: slot.day - dayCursor,
    );
  }

  String matchDay() => nextMatch == null ? '—' : GameCalendar.dayNames[nextMatch!.date.weekday - 1];
  String matchTime() => nextMatch?.time ?? '—';
  String matchDate() => nextMatch == null ? '—' : GameCalendar.fmt(nextMatch!.date);
  int daysUntilMatch() => nextMatch == null ? 0 : nextMatch!.daysUntil.clamp(0, 9).toInt();

  /// تاريخ اليوم داخل اللعبة
  DateTime get today => GameCalendar.dateOf(season, week.clamp(0, 60).toInt(), dayCursor);

  /// جدول مباريات المستخدم القادمة في كل البطولات (للعرض فقط)
  List<ScheduledMatch> upcomingSchedule() {
    final out = <ScheduledMatch>[];
    for (var w = week; w < rounds.length; w++) {
      for (final f in rounds[w]) {
        if (f.played || (f.home != user.id && f.away != user.id)) continue;
        final slot = GameCalendar.league(f.home, f.away, w, season);
        out.add(ScheduledMatch(
          comp: leagueName,
          key: 'league',
          round: 'الجولة ${w + 1}',
          date: GameCalendar.dateOf(season, w, slot.day),
          time: slot.time,
          home: team(f.home),
          away: team(f.away),
        ));
      }
    }
    for (final c in allCups) {
      if (c.done || c.alive.isEmpty) continue;
      final inIt = c.alive.contains(user.id) || c.byes.contains(user.id);
      if (!inIt) continue;
      for (var r = c.round; r < c.schedule.length; r++) {
        final w = c.schedule[r];
        if (w < week) continue;
        final t = r == c.round ? c.userTie(user.id) : null;
        int? hId = t?.home, aId = t?.away;
        if (t == null && c.kind == 2 && r < c.lpRounds && r < c.lpFx.length) {
          for (final p in c.lpFx[r]) {
            if (p[0] == user.id || p[1] == user.id) {
              hId = p[0];
              aId = p[1];
            }
          }
        }
        final slot = GameCalendar.cup(c.key, r, hId ?? user.id, aId ?? r);
        out.add(ScheduledMatch(
          comp: c.name,
          key: c.key,
          round: _roundLabel(c, r),
          date: GameCalendar.dateOf(season, w, slot.day),
          time: slot.time,
          home: hId == null ? null : team(hId),
          away: aId == null ? null : team(aId),
        ));
      }
    }
    out.sort((a, b) {
      final k = a.date.compareTo(b.date);
      return k != 0 ? k : a.time.compareTo(b.time);
    });
    return out;
  }

  String _roundLabel(Cup c, int r) {
    return c.roundNameAt(r);
  }

  /// آخر نتائج فريق في الدوري: W فوز، D تعادل، L خسارة
  List<String> formOf(Team t, [int n = 5]) {
    final out = <String>[];
    for (final r in rounds) {
      for (final f in r) {
        if (!f.played || (f.home != t.id && f.away != t.id)) continue;
        final mine = f.home == t.id ? f.hg! : f.ag!;
        final opp = f.home == t.id ? f.ag! : f.hg!;
        out.add(mine > opp ? 'W' : (mine < opp ? 'L' : 'D'));
      }
    }
    return out.length <= n ? out : out.sublist(out.length - n);
  }

  void _record(MatchSim s, String comp, int round, int oppId, [String label = '']) {
    final lm = LastMatch.fromSim(s, comp: comp, round: round, label: label, userHome: s.home.team == user);
    lastMatch = lm;
    final l = h2h.putIfAbsent(oppId, () => []);
    l.add(lm.result);
    if (l.length > 10) l.removeAt(0);
  }
  int coins = 300; // كوينز: تُكسب من المتجر ومشاهدة الإعلانات (لاحقاً)
  static const createPlayerCost = 100;
  // ───────── مهام الكشافة ─────────
  final List<Map<String, dynamic>> missions = []; // {c: البلد, e: أسبوع الانتهاء, w: المدة}
  final List<int> scoutFound = []; // ids اللاعبين المكتشفين (تبقى في السوق)
  final List<String> scoutLog = [];
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
  Cup? domestic, continental, europa, conference, superCup, cwc, ic;
  int userSlotsEl = 0, userSlotsCo = 0;
  List<Cup> get allCups => [for (final c in [domestic, continental, europa, conference, superCup, ic, cwc]) if (c != null) c];
  Cup? activeCup;
  final Map<int, Team> foreign = {};
  /// تصنيف Elo للأندية (الترتيب العالمي) بالاسم؛ يبدأ من قوة الفريق ويتغير بالنتائج
  final Map<String, double> elo = {};
  double eloOf(Team t) => elo[t.name] ?? 1500 + (t.strength - 65) * 18;

  void _eloUpdate(Team h, Team a, int hg, int ag) {
    final eh = eloOf(h), ea = eloOf(a);
    final exp = 1 / (1 + pow(10, (ea - (eh + 50)) / 400));
    final res = hg > ag ? 1.0 : (hg == ag ? 0.5 : 0.0);
    final k = 22.0 * (1 + (hg - ag).abs().clamp(0, 4) * 0.25);
    elo[h.name] = eh + k * (res - exp);
    elo[a.name] = ea - k * (res - exp);
  }

  /// كل الأندية المعروفة مرتبة عالمياً
  List<Team> get worldRanking {
    final all = {for (final t in [...teams, ...upper, ...lower, ...foreign.values]) t.name: t}.values.toList();
    all.sort((a, b) => eloOf(b).compareTo(eloOf(a)));
    return all;
  }

  bool realWorld = false; // أندية قارية حقيقية
  int userSlots = 3;
  final List<String> honours = [];
  final Map<String, int> staff = {'coach': 0, 'scout': 0, 'doctor': 0, 'analyst': 0, 'marketing': 0, 'director': 0};
  int? boardKind; // اجتماع إدارة معلّق
  bool boardPledge = false; // تعهّد للإدارة بإنهاء الدوري ضمن الثلاثة الأوائل
  List<int> lastXI = [];
  double fans = 50;
  int ticketLevel = 1; // 0 رخيصة، 1 عادية، 2 مرتفعة
  static const ticketMult = [0.8, 1.0, 1.25];
  int get stadiumCapacity => 12000 + 8000 * user.stadium;
  double get fillRate => (0.42 + 0.5 * fans / 100 - 0.12 * (ticketLevel - 1)).clamp(0.2, 1.0).toDouble();
  int get attendance => (stadiumCapacity * fillRate).round();
  void setTicketLevel(int v) { ticketLevel = v; notifyListeners(); unawaited(save()); }
  int difficulty = 1; // 0 سهل، 1 عادي، 2 صعب
  bool introSeen = false;
  /// ختم زمني لكل خبر (تاريخ اللعبة|الساعة) ليُجمَّع في صندوق الرسائل
  final Map<String, String> newsStamp = {};
  final Set<String> readMsgs = {};
  final List<int> attHist = []; // حضور آخر المباريات على أرضك
  int campaignWeek = -99;
  String? runCampaign() {
    if (week - campaignWeek < 4) return 'الحملة التالية بعد ${4 - (week - campaignWeek)} جولات';
    if (user.budget < 1.0) return 'الميزانية لا تكفي (1.0M)';
    user.budget -= 1.0;
    fin.add('staff', 1.0);
    fans = min(100, fans + 3);
    campaignWeek = week;
    news.insert(0, '📣 أطلقت حملة تسويقية: شعبية النادي +3');
    unawaited(save());
    notifyListeners();
    return null;
  }
  @override
  void notifyListeners() {
    if (news.isNotEmpty && rounds.isNotEmpty) {
      final d = today;
      final n = DateTime.now();
      final stamp = '${d.year}-${d.month}-${d.day}|${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
      for (final x in news.take(12)) {
        newsStamp.putIfAbsent(x, () => stamp);
      }
      if (newsStamp.length > 150) {
        final keep = news.take(60).toSet();
        newsStamp.removeWhere((k, _) => !keep.contains(k));
      }
    }
    super.notifyListeners();
  }
  bool indTrain = false; // تدريب فردي للمواهب الشابة
  void setIndTrain(bool v) { indTrain = v; notifyListeners(); unawaited(save()); }
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
      country = pyramid.country;
      leagueId = pyramid.leagueId;
      if (pyramid.world.isNotEmpty) {
        realWorld = true;
        userSlots = pyramid.userSlots;
        userSlotsEl = pyramid.userSlotsEl;
        userSlotsCo = pyramid.userSlotsCo;
        void reg(List<Team> l, int base) {
          for (var i = 0; i < l.length; i++) {
            l[i].id = base + i;
            foreign[base + i] = l[i];
          }
        }

        reg(pyramid.world, 1000);
        reg(pyramid.worldEl, 1100);
        reg(pyramid.worldCo, 1200);
      }
    }
    user = teams.firstWhere((x) => x.id == userId);
    _buildFixtures();
    _setupCups(null);
    _setupWorldCups();
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
    training = migrateTraining(j['training'] as String);
    trainIntensity = (j['tint'] as int?) ?? 1;
    indTrain = (j['itr'] as bool?) ?? false;
    attHist.addAll(((j['ah'] as List?) ?? const []).cast<int>());
    campaignWeek = (j['cw'] as int?) ?? -99;
    fired = j['fired'] as bool;
    seasonOver = j['over'] as bool;
    news.addAll((j['news'] as List).cast<String>());
    newsStamp.addAll(((j['nst'] as Map?) ?? const {}).cast<String, String>());
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
    realWorld = (j['rw'] as bool?) ?? false;
    for (final e in ((j['elo'] as Map?) ?? const {}).entries) {
      elo[e.key as String] = (e.value as num).toDouble();
    }
    country = (j['ctry'] as String?) ?? '';
    leagueId = (j['lid'] as int?) ?? 0;
    userSlots = (j['uslots'] as int?) ?? 3;
    userSlotsEl = (j['uel'] as int?) ?? 0;
    userSlotsCo = (j['uco'] as int?) ?? 0;
    for (final t in (j['foreign'] as List?) ?? const []) {
      final tm = Team.fromJson(t as Map<String, dynamic>);
      foreign[tm.id] = tm;
    }
    honours.addAll(((j['honours'] as List?) ?? const []).cast<String>());
    oplog.addAll(((j['oplog'] as List?) ?? const []).cast<String>());
    watch.addAll(((j['watch'] as List?) ?? const []).cast<int>());
    coins = (j['coins'] as int?) ?? 300;
    dayCursor = (j['dc'] as int?) ?? 0;
    if (j['lm'] != null) {
      try {
        lastMatch = LastMatch.fromJson(Map<String, dynamic>.from(j['lm'] as Map));
      } catch (_) {}
    }
    for (final e in ((j['h2h'] as Map?) ?? const {}).entries) {
      h2h[int.parse(e.key as String)] = (e.value as List).cast<String>();
    }
    for (final m in (j['missions'] as List?) ?? const []) {
      missions.add(Map<String, dynamic>.from(m as Map));
    }
    scoutFound.addAll(((j['sfound'] as List?) ?? const []).cast<int>());
    scoutLog.addAll(((j['slog'] as List?) ?? const []).cast<String>());
    final st = j['staff'] as Map<String, dynamic>?;
    if (st != null) st.forEach((k, v) => staff[k] = v as int);
    boardKind = j['bk'] as int?;
    boardPledge = (j['bp'] as bool?) ?? false;
    lastXI = [for (final x in (j['lxi'] as List?) ?? const []) x as int];
    fans = (j['fans'] as num?)?.toDouble() ?? (20.0 + user.reputation * 12);
    ticketLevel = (j['tl'] as int?) ?? 1;
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
    final nj = j['nat'] as Map<String, dynamic>?;
    if (nj != null) {
      for (final e in (nj['pts'] as Map).entries) {
        nat.pts[e.key as String] = (e.value as num).toDouble();
      }
      for (final e in ((nj['start'] as Map?) ?? const {}).entries) {
        nat.start[e.key as String] = (e.value as num).toDouble();
      }
      for (final h in (nj['hist'] as List?) ?? const []) {
        nat.history.add(NatTour.fromJson(h as Map<String, dynamic>));
      }
    }
    for (final e in ((j['cc'] as Map?) ?? const {}).entries) {
      contChamps[e.key as String] = e.value as String;
    }
    for (final h in (j['ch'] as List?) ?? const []) {
      cupHist.add(Map<String, dynamic>.from(h as Map));
    }
    ffpBreaches = (j['ffpB'] as int?) ?? 0;
    transferBan = (j['ban'] as bool?) ?? false;
    pointsPenaltyNext = (j['ppn'] as int?) ?? 0;
    final cj = j['cups'] as Map<String, dynamic>?;
    if (cj != null) {
      domestic = Cup.fromJson(cj['dom'] as Map<String, dynamic>);
      continental = Cup.fromJson(cj['con'] as Map<String, dynamic>);
      if (cj['eur'] != null) europa = Cup.fromJson(cj['eur'] as Map<String, dynamic>);
      if (cj['uecl'] != null) conference = Cup.fromJson(cj['uecl'] as Map<String, dynamic>);
      if (cj['sup'] != null) superCup = Cup.fromJson(cj['sup'] as Map<String, dynamic>);
      if (cj['cwc'] != null) cwc = Cup.fromJson(cj['cwc'] as Map<String, dynamic>);
      if (cj['ic'] != null) ic = Cup.fromJson(cj['ic'] as Map<String, dynamic>);
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
        'rw': realWorld,
        'elo': elo,
        'ctry': country,
        'lid': leagueId,
        'uslots': userSlots,
        'uel': userSlotsEl,
        'uco': userSlotsCo,
        'honours': honours,
        'oplog': oplog,
        'watch': watch.toList(),
        'coins': coins,
        'dc': dayCursor,
        'lm': lastMatch?.toJson(),
        'h2h': {for (final e in h2h.entries) '${e.key}': e.value},
        'missions': missions,
        'sfound': scoutFound,
        'slog': scoutLog,
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
        'tl': ticketLevel,
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
        'cups': {'dom': domestic!.toJson(), 'con': continental!.toJson(), 'eur': europa?.toJson(), 'uecl': conference?.toJson(), 'sup': superCup?.toJson(), 'cwc': cwc?.toJson(), 'ic': ic?.toJson()},
        'nat': {'pts': nat.pts, 'start': nat.start, 'hist': [for (final t in nat.history) t.toJson()]},
        'cc': contChamps,
        'ch': cupHist,
        'loanedOut': [for (final p in loanedOut) p.toJson()],
        'conf': confidence,
        'training': training,
        'tint': trainIntensity,
        'itr': indTrain,
        'ah': attHist,
        'cw': campaignWeek,
        'fired': fired,
        'over': seasonOver,
        'news': news,
        'nst': newsStamp,
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
      for (final m in l) {
        m.bytes = (p.getString(_kOf(m.id)) ?? '').length;
      }
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

  void setIntensity(int v) {
    trainIntensity = v;
    notifyListeners();
    unawaited(save());
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
    _eloUpdate(h, a, hg, ag);
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
    _record(s, leagueName, week + 1, f.home == user.id ? f.away : f.home, 'الجولة ${week + 1}');
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
          if (training == 'mental') rec += 8;
          if (training == 'physical') rec += 4;
          if (training != 'mental') rec += intensityRec[trainIntensity];
          if (training == 'mental') p.morale = min(100, p.morale + 1.2);
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
    final gate = home ? (0.3 + 0.12 * user.reputation) * (0.7 + 0.15 * user.stadium) * (0.75 + 0.5 * fans / 100) * (1 + 0.04 * mk) * ticketMult[ticketLevel] : 0.0;
    if (home) {
      attHist.add(attendance);
      if (attHist.length > 12) attHist.removeAt(0);
    }
    if (home) fans = (fans + (ticketLevel == 0 ? 0.3 : ticketLevel == 2 ? -0.4 : 0.0)).clamp(0, 100).toDouble();
    final broadcast = (0.35 + 0.1 * user.reputation) * divFactor;
    final sponsor = (0.25 + 0.1 * user.reputation + (position <= 3 ? 0.2 : 0.0)) * 0.5 * (0.8 + 0.4 * fans / 100) +
        dealsIncome * (0.9 + 0.2 * fans / 100);
    final sponsorX = sponsor * (1 + 0.05 * mk);
    final maintenance = 0.03 * (user.stadium + user.trainingLvl);
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
    dayCursor = 0;
    _scoutTick();
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
    if (training == 'mental' || training == 'physical') return;
    if (p.overall >= p.potential) return;
    final base = p.age <= 24 ? 0.14 : (p.age <= 29 ? 0.06 : 0.02);
    final chance = base * (1 + 0.25 * (user.trainingLvl - 1)) * (1 + 0.1 * (staff['coach'] ?? 0)) * intensityGain[trainIntensity] * (indTrain && p.age <= 22 ? 1.25 : 1.0);
    if (rng.nextDouble() > chance) return;
    if (p.pos == Pos.gk) {
      p.gk = min(95, p.gk + 1);
      return;
    }
    switch (training) {
      case 'technical':
        if (p.pos == Pos.def) {
          p.pas = min(95, p.pas + 1);
        } else {
          p.atk = min(95, p.atk + 1);
        }
      case 'tactical':
        if (p.pos == Pos.att) {
          p.pas = min(95, p.pas + 1);
        } else {
          p.def = min(95, p.def + 1);
        }
        user.cohesion = min(100, user.cohesion + 0.05);
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
  String? completeSigning(Player p, double price, {double? wage, int? years, double bonus = 0}) {
    final werr = _incomingErr(p.free);
    if (werr != null) return werr;
    if (user.squad.length >= 30) return 'التشكيلة ممتلئة (30 لاعباً كحد أقصى)';
    final refused = _refusal(p);
    if (refused != null) return refused;
    final fee = agentFee(price);
    final extra = bonus + agentFee(bonus);
    if (price + fee + extra > user.budget) {
      return 'الميزانية غير كافية (السعر + العمولات ${money1(price + fee + extra)})';
    }
    if (rng.nextDouble() < 0.06) {
      market.remove(p);
      news.insert(0, '🩺 فشل ${p.name} في الفحص الطبي وانسحبت الصفقة');
      unawaited(save());
      notifyListeners();
      return 'فشل اللاعب في الفحص الطبي — أُلغيت الصفقة';
    }
    if (!p.free && p.club != null) {
      final owner = _ownerOf(p);
      if (owner == null) {
        market.remove(p);
        notifyListeners();
        return 'اللاعب لم يعد متاحاً — انتقل إلى نادٍ آخر';
      }
      owner.squad.removeWhere((x) => x.id == p.id);
      owner.budget += price;
      owner.repairLineup();
    }
    user.budget -= price + fee + extra;
    if (bonus > 0) fin.add('renewals', bonus);
    fin.add('purchases', price);
    fin.add('agents', fee);
    var note = '';
    if (rng.nextDouble() < 0.1) {
      p.injuredWeeks = 1 + rng.nextInt(3);
      note = ' (إصابة طفيفة اكتُشفت في الفحص الطبي)';
    }
    p.club = null;
    p.contract = years ?? 3;
    p.free = false;
    p.listed = false;
    p.onLoan = false;
    p.morale = 75;
    p.salary = wage;
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
      _ => 1,
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
        break;
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
    final champT = finalTable.first;
    final runnerT = finalTable.length > 1 ? finalTable[1] : finalTable.first;
    final cupWinner = domestic?.champion;
    final cupT = cupWinner == null ? null : team(cupWinner);
    final qualT = realWorld ? _qualifiers(finalTable, cupT) : finalTable.take(3).toList();
    final aw = _seasonAwards(pos);
    _recordSeason(pos, aw);
    _worldSeasonEnd();
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

    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
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
    dayCursor = 0;
    missions.clear();
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
    _setupWorldCups();
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
  /// المتأهلون قارياً من ترتيب الدوري: مراكز الأبطال ثم مقاعد الأوروبي/الثانية، وبطل الكأس المحلي يأخذ مقعده
  List<Team> _qualifiers(List<Team> tbl, Team? cupT, {int? eOver, int? cOver}) {
    final u = userSlots, e = eOver ?? userSlotsEl, c = cOver ?? userSlotsCo;
    final ucl = tbl.take(u).toList();
    final pool = tbl.skip(u).toList();
    final uel = <Team>[], uecl = <Team>[];
    final swiss = confedOf(country).swiss;
    if (swiss && e > 0 && cupT != null && pool.contains(cupT)) {
      uel.add(cupT);
      pool.remove(cupT);
    }
    while (uel.length < e && pool.isNotEmpty) {
      uel.add(pool.removeAt(0));
    }
    if (!swiss && c > 0 && cupT != null && pool.contains(cupT)) {
      uecl.add(cupT);
      pool.remove(cupT);
    }
    while (uecl.length < c && pool.isNotEmpty) {
      uecl.add(pool.removeAt(0));
    }
    return [...ucl, ...uel, ...uecl];
  }

  /// منطقة التأهل القاري لكل نادٍ في جدول الدوري: 0 أبطال، 1 أوروبي/ثانية، 2 مؤتمر (قبل حسم الكأس يبقى مقعده محجوزاً)
  Map<int, int> qualZones() {
    if (div != 1) return {};
    final tbl = table;
    final out = <int, int>{};
    if (!realWorld) {
      for (var i = 0; i < min(3, tbl.length); i++) {
        out[tbl[i].id] = 0;
      }
      return out;
    }
    final swiss = confedOf(country).swiss;
    final cw = domestic?.champion;
    final cupT = cw != null && cw < 1000 ? team(cw) : null;
    final pending = domestic != null && !domestic!.done;
    final q = _qualifiers(tbl, cupT, eOver: pending && swiss && userSlotsEl > 0 ? userSlotsEl - 1 : null, cOver: pending && !swiss && userSlotsCo > 0 ? userSlotsCo - 1 : null);
    for (var i = 0; i < q.length; i++) {
      out[q[i].id] = i < userSlots ? 0 : (i < userSlots + userSlotsEl - (pending && swiss && userSlotsEl > 0 ? 1 : 0) ? 1 : 2);
    }
    return out;
  }

  static int _pow2(int n) {
    var p = 1;
    while (p < n) {
      p *= 2;
    }
    return p;
  }

  void _setupCups(List<int>? qual) {
    final w = rounds.length;
    // أسابيع الأدوار: موزعة كالواقع على الموسم؛ كل بطولة قارية تلعب في الأسابيع نفسها (بأيام مختلفة)
    List<int> schedFrac(List<double> fr) {
      final out = <int>[];
      for (final f in fr) {
        var v = min(w - 2, (f * w).round());
        if (out.isNotEmpty && v <= out.last) v = out.last + 1;
        out.add(v);
      }
      return out;
    }

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

    if (!realWorld) {
      foreign.clear();
      const extraNames = ['سبارتا الشمال', 'فيورينتينا الهضاب', 'أنتويرب الميناء'];
      final extra = div > 1 ? extraNames.length : 0;
      for (var i = 0; i < foreignClubNames.length + extra; i++) {
        final nm = i < foreignClubNames.length ? foreignClubNames[i] : extraNames[i - foreignClubNames.length];
        foreign[1000 + i] = createTeam(rng, 1000 + i, nm, 3 + rng.nextInt(3));
      }
    }
    final take = realWorld ? userSlots + userSlotsEl + userSlotsCo : 3;
    final order = div > 1
        ? <int>[]
        : qual ?? [for (final t in ([...teams]..sort((a, b) => b.strength.compareTo(a.strength))).take(take)) t.id];
    final nU = realWorld ? userSlots : 3;
    final qU = order.take(nU).toList();
    final qE = realWorld ? order.skip(nU).take(userSlotsEl).toList() : <int>[];
    final qC = realWorld ? order.skip(nU + userSlotsEl).take(userSlotsCo).toList() : <int>[];

    var extraId = 1500;
    List<int> fill(List<int> uq, int lo, int n) {
      final alive = [...uq, ...foreign.keys.where((k) => k >= lo && k < lo + 100)];
      // ضمان العدد المطلوب بالضبط (قد ينقص الحقيقي أو يزيد)
      while (alive.length < n) {
        foreign[extraId] = createTeam(rng, extraId, 'نادٍ ضيف ${extraId - 1499}', 3);
        alive.add(extraId++);
      }
      if (alive.length > n) {
        final keep = alive.where(uq.contains).toList();
        final rest = alive.where((x) => !uq.contains(x)).toList()..sort((a, b) => team(b).strength.compareTo(team(a).strength));
        return [...keep, ...rest].take(n).toList();
      }
      return alive;
    }

    // مرحلة دوري (36 فريقاً، 8 أو 6 مباريات) ← ملحق ← دور الـ16 ← النهائي
    Cup swissCup(String key, String name, List<int> uq, int lo, int matches, List<double> fr) {
      final ids = fill(uq, lo, 36);
      final sorted = [...ids]..sort((a, b) => team(b).strength.compareTo(team(a).strength));
      final c = Cup(key: key, name: name, continental: true, schedule: schedFrac(fr), size: 36, alive: ids)
        ..kind = 2
        ..lpRounds = matches
        ..groups = [sorted];
      c.lpFx = swissFixtures(sorted, matches, rng);
      _draw(c);
      return c;
    }

    // 16 فريقاً في 4 مجموعات ثم الإقصاء (أفريقيا/آسيا/أمريكا أو اللعبة الخيالية)
    Cup groupCup(String key, String name, List<int> uq, int lo, int rounds, List<double> fr) {
      final ids = fill(uq, lo, 16);
      final sorted = [...ids]..sort((a, b) => team(b).strength.compareTo(team(a).strength));
      final pots = [for (var k = 0; k < 4; k++) (sorted.sublist(k * 4, k * 4 + 4)..shuffle(rng))];
      final c = Cup(key: key, name: name, continental: true, schedule: schedFrac(fr), size: 16, alive: ids)
        ..kind = 1
        ..lpRounds = rounds
        ..groups = [
          for (var gI = 0; gI < 4; gI++) [for (final pot in pots) pot[gI]]
        ];
      _draw(c);
      return c;
    }

    const swiss8 = [0.10, 0.17, 0.24, 0.31, 0.38, 0.45, 0.52, 0.58, 0.66, 0.74, 0.82, 0.90, 0.96];
    const swiss6 = [0.12, 0.20, 0.28, 0.36, 0.44, 0.52, 0.66, 0.74, 0.82, 0.90, 0.96];
    const grp6 = [0.12, 0.22, 0.32, 0.42, 0.52, 0.62, 0.76, 0.88, 0.96];
    const grp3 = [0.14, 0.27, 0.40, 0.60, 0.76, 0.94];

    if (realWorld && confedOf(country).swiss) {
      continental = swissCup('con', 'دوري أبطال أوروبا', qU, 1000, 8, swiss8);
      europa = swissCup('uel', 'الدوري الأوروبي', qE, 1100, 8, swiss8);
      conference = swissCup('uecl', 'دوري المؤتمر الأوروبي', qC, 1200, 6, swiss6);
    } else if (realWorld) {
      final cf = confedOf(country);
      continental = groupCup('con', cf.cl, qU, 1000, 6, grp6);
      europa = null;
      conference = groupCup('uecl', cf.second, qC, 1200, 6, grp6);
    } else {
      continental = groupCup('con', 'دوري أبطال أوروبا', qU, 1000, 3, grp3);
      europa = null;
      conference = null;
    }
  }

  void _draw(Cup c) {
    if (c.inGroups) {
      c.byes = [];
      if (c.kind == 2) {
        c.ties = [for (final p in c.lpFx[c.round]) Tie(p[0], p[1])];
        return;
      }
      const pat = [
        [(0, 1), (2, 3)],
        [(0, 2), (3, 1)],
        [(3, 0), (1, 2)],
        [(1, 0), (3, 2)],
        [(2, 0), (1, 3)],
        [(0, 3), (2, 1)],
      ];
      c.ties = [
        for (final g in c.groups)
          for (final pr in pat[c.round]) Tie(g[pr.$1], g[pr.$2])
      ];
      return;
    }
    final ids = [...c.alive];
    c.size = _pow2(ids.length);
    final nb = c.size - ids.length;
    if (c.seeded) {
      // الملحق: الترتيب محفوظ؛ الأفضل يستضيف الأضعف
      c.byes = ids.take(nb).toList();
      final rest = ids.skip(nb).toList();
      c.ties = [for (var i = 0; i < rest.length ~/ 2; i++) Tie(rest[i], rest[rest.length - 1 - i])];
      return;
    }
    ids.sort((a, b) => team(b).strength.compareTo(team(a).strength));
    c.byes = ids.take(nb).toList();
    final rest = ids.skip(nb).toList()..shuffle(rng);
    c.ties = [for (var i = 0; i + 1 < rest.length; i += 2) Tie(rest[i], rest[i + 1])];
  }

  void _setTie(Tie t, int hg, int ag, {bool pens = true}) {
    t.hg = hg;
    t.ag = ag;
    _eloUpdate(team(t.home), team(t.away), hg, ag);
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
      if (c.round < c.lpRounds) {
        _draw(c);
        return;
      }
      if (c.kind == 2) {
        _finishLeaguePhase(c);
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
    final userWas = c.alive.contains(user.id) && !c.byes.contains(user.id);
    if (userWas) {
      if (winners.contains(user.id)) {
        final prize = (c.continental ? 1.5 : 0.5) * (c.kind == 2 ? idx - c.lpRounds + 1 : idx + 1);
        user.budget += prize;
        fin.add('prize', prize);
        news.insert(0, '🏅 تأهلت في ${c.name} (${c.roundName}) — مكافأة ${money1(prize)}');
      } else {
        news.insert(0, '👋 ودّعت ${c.name} من ${c.roundName}');
      }
    }
    c.alive = winners;
    c.round++;
    c.seeded = false;
    if (winners.length == 1) {
      c.done = true;
      c.champion = winners.first;
      final fin0 = c.ties.isEmpty ? null : c.ties.first;
      cupHist.add({
        's': season,
        'k': c.key,
        'n': team(winners.first).name,
        'r': fin0 == null ? '' : team(fin0.home == winners.first ? fin0.away : fin0.home).name,
      });
      for (final pl in team(winners.first).squad) {
        pl.awards.add({'s': season, 'c': c.name, 'k': 'cup'});
      }
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

  /// نهاية مرحلة الدوري (36 فريقاً): 1-8 إلى دور الـ16، 9-24 إلى الملحق، والباقي يودّع
  void _finishLeaguePhase(Cup c) {
    final tb = groupTable(c, c.groups[0]);
    final ids = [for (final r in tb) r.id];
    final rank = ids.indexOf(user.id);
    c.alive = ids.take(24).toList();
    c.seeded = true;
    if (rank >= 0) {
      if (rank < 8) {
        user.budget += 4.0;
        fin.add('prize', 4.0);
        news.insert(0, '🏅 ${c.name}: المركز ${rank + 1} في مرحلة الدوري — تأهل مباشر إلى دور الـ16 (+${money1(4.0)})');
      } else if (rank < 24) {
        user.budget += 1.5;
        fin.add('prize', 1.5);
        news.insert(0, '🏅 ${c.name}: المركز ${rank + 1} — ستلعب الملحق على التأهل لدور الـ16 (+${money1(1.5)})');
      } else {
        news.insert(0, '👋 ودّعت ${c.name} من مرحلة الدوري (المركز ${rank + 1})');
      }
    }
    _draw(c);
  }

  void _advanceCups() {
    for (final c in allCups) {
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
    Cup? best;
    var bestDay = 99;
    for (final c in allCups) {
      if (!c.done && c.dueWeek != null && c.dueWeek! <= week) {
        final t = c.userTie(user.id);
        if (t == null) continue;
        final d = GameCalendar.cup(c.key, c.round, t.home, t.away).day;
        if (d < bestDay) {
          bestDay = d;
          best = c;
        }
      }
    }
    return best;
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
    _record(s, c.name, week + 1, t.home == user.id ? t.away : t.home, c.roundName);
    dayCursor = GameCalendar.cup(c.key, c.round, t.home, t.away).day;
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
  /// إنشاء لاعب جديد مقابل كوينز
  String? createPlayer(Player p) {
    if (user.squad.length >= 30) return 'التشكيلة ممتلئة (30 لاعباً كحد أقصى)';
    if (coins < createPlayerCost) return 'الكوينز غير كافية ($createPlayerCost مطلوبة)';
    coins -= createPlayerCost;
    p.club = user.name;
    user.squad.add(p);
    news.insert(0, '🌟 أنشأت لاعباً جديداً: ${p.name} (${p.overall})');
    unawaited(save());
    notifyListeners();
    return null;
  }

  // ───────── نظام الكشافة: إرسال كشّاف إلى بلد ─────────
  int get scoutSlots => 1 + (staff['scout'] ?? 0) ~/ 2;
  static const scoutDurations = [2, 4, 6];
  double missionCost(int weeks) => 0.3 * weeks;

  List<MapEntry<String, int>> get scoutCountries {
    final by = <String, int>{};
    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
      if (t == user) continue;
      for (final p in t.squad) {
        final n = p.nat;
        if (n != null && n.isNotEmpty && p.age <= 23) by[n] = (by[n] ?? 0) + 1;
      }
    }
    final l = by.entries.where((e) => e.value >= 3).toList()..sort((a, b) => b.value.compareTo(a.value));
    return l;
  }

  String? startMission(String country, int weeks) {
    if (missions.length >= scoutSlots) return 'لا يوجد كشّاف متاح (الحد $scoutSlots)';
    if (missions.any((m) => m['c'] == country)) return 'يوجد كشّاف في هذا البلد بالفعل';
    final cost = missionCost(weeks);
    if (cost > user.budget) return 'الميزانية غير كافية (${money1(cost)})';
    user.budget -= cost;
    fin.add('scouting', cost);
    missions.add({'c': country, 'e': week + weeks, 'w': weeks});
    news.insert(0, '🔭 أرسلت كشّافاً إلى $country لمدة $weeks أسابيع');
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? cancelMission(Map<String, dynamic> m) {
    missions.remove(m);
    unawaited(save());
    notifyListeners();
    return null;
  }

  void _scoutTick() {
    final done = missions.where((m) => (m['e'] as int) <= week).toList();
    for (final m in done) {
      missions.remove(m);
      final country = m['c'] as String;
      final lvl = staff['scout'] ?? 0;
      final pool = <Player>[];
      for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
        if (t == user) continue;
        for (final p in t.squad) {
          if (p.nat == country && p.age <= 23 && !p.onLoan && !scoutFound.contains(p.id)) {
            p.club = t.name;
            pool.add(p);
          }
        }
      }
      pool.sort((a, b) => (b.potential + rng.nextInt(10)).compareTo(a.potential + rng.nextInt(10)));
      final n = 2 + (m['w'] as int) ~/ 2 + lvl ~/ 2;
      final found = pool.take(n).toList();
      for (final p in found) {
        scoutFound.add(p.id);
        if (!market.any((x) => x.id == p.id)) market.add(Player.fromJson(p.toJson())..club = p.club);
      }
      while (scoutFound.length > 24) {
        scoutFound.removeAt(0);
      }
      if (found.isEmpty) {
        scoutLog.insert(0, '$country: لم يجد الكشّاف أحداً');
        news.insert(0, '🔭 عاد الكشّاف من $country دون اكتشافات');
      } else {
        scoutLog.insert(0, '$country: ${found.map((p) => '${p.name} (${p.overall}/${p.potential})').join('، ')}');
        news.insert(0, '🔭 عاد الكشّاف من $country: اكتشف ${found.length} لاعبين جدداً في السوق');
      }
      if (scoutLog.length > 20) scoutLog.removeLast();
    }
  }

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

  /// سوق حقيقي: لاعبون من أندية الدوريات الأخرى (بالنادي والقيمة الحقيقية) + أحرار
  List<Player> _scoutedMarket() {
    final m = generateMarket(rng).where((p) => p.free).toList();
    final pool = <Player>[];
    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
      if (t == user) continue;
      for (final p in t.squad) {
        if (p.overall >= 58 && !p.onLoan && p.injuredWeeks == 0) {
          p.club = t.name;
          pool.add(p);
        }
      }
    }
    pool.shuffle(rng);
    // الأفضلية للأقوى لكن بتنوع: نأخذ 45 عشوائياً ونرتّبهم
    for (final p in pool.take(45)) {
      m.add(Player.fromJson(p.toJson())..club = p.club);
    }
    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
      if (t == user) continue;
      for (final p in t.squad) {
        if (scoutFound.contains(p.id) && !m.any((x) => x.id == p.id)) m.add(Player.fromJson(p.toJson())..club = t.name);
      }
    }
    final lvl = staff['scout'] ?? 0;
    if (lvl > 0) {
      final top = pool.where((p) => p.age <= 23 && p.potential >= 78).take(lvl * 3);
      for (final p in top) {
        if (!m.any((x) => x.id == p.id)) m.add(Player.fromJson(p.toJson())..club = p.club);
      }
    }
    return m;
  }

  Team? _ownerOf(Player p) {
    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
      if (t != user && t.squad.any((x) => x.id == p.id)) return t;
    }
    return null;
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
    if (last != null) return 'خرج في ${last.contains('مرحلة الدوري') ? 'مرحلة الدوري' : (last.contains('مجموعات') ? 'دور المجموعات' : last)}';
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
      'eur': europa == null ? '-' : _cupResult(europa!),
      'uecl': conference == null ? '-' : _cupResult(conference!),
      'scorer': top.isEmpty || top.first.goals == 0 ? '-' : '${top.first.name} (${top.first.goals})',
      'awards': awards,
    });
    for (final pl in table.first.squad) {
      pl.awards.add({'s': season, 'c': leagueName, 'k': 'league'});
    }
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

  /// المرحلة الثانية من الصفقة: شروط اللاعب الشخصية (راتب ومدة)
  double signDemand(Player p) {
    var m = 1.15;
    if (user.reputation < 3) m += 0.15;
    if (p.age <= 25) m += 0.1;
    if (p.overall >= 78) m += 0.15;
    final avg = user.squad.isEmpty ? 60.0 : user.squad.fold<double>(0, (a, x) => a + x.overall) / user.squad.length;
    if (p.overall < avg - 4) m -= 0.1; // يرضى بأقل لأنه سيحصل على دقائق لعب أقل
    return max(p.wage, p.baseWage) * m;
  }

  NegoResult playerSignOffer(Player p, double wage, int years, int tries) {
    final dem = signDemand(p);
    var score = wage / dem;
    if (p.age <= 24 && years >= 4) score += 0.04; // الشاب يحب الأمان
    if (p.age >= 31 && years >= 4) score -= 0.04;
    if (score >= 1.0) return const NegoResult('accept', null, 'وافق اللاعب على الشروط الشخصية');
    if (score >= 0.8 && tries < 2) {
      return NegoResult('counter', (dem * 0.98 * 1000).round() / 1000, 'اللاعب يطلب راتباً أعلى: ${(dem * 980).round()}K أسبوعياً.');
    }
    return const NegoResult('reject', null, 'رفض اللاعب الشروط الشخصية وانسحب من الصفقة.');
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

  // ───────── العالم: أبطال الاتحادات، إنتركونتيننتال، كأس العالم للأندية، المنتخبات ─────────
  final NatState nat = NatState();
  final Map<String, String> contChamps = {}; // موسم|اتحاد ← اسم البطل
  final List<Map<String, dynamic>> cupHist = []; // {s, k, n, r}
  Map<String, List<(Player, Team)>>? _natIdx;
  final Map<String, double> _adjCache = {};

  void ensureNat() {
    if (nat.conf.isNotEmpty && nat.pts.isNotEmpty) return;
    nat.init([for (final c in kAllCountries) (c.name, c.region)], rng);
  }

  void _buildNatIdx() {
    final m = <String, List<(Player, Team)>>{};
    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
      for (final p in t.squad) {
        final n = p.nat;
        if (n == null || n.isEmpty) continue;
        m.putIfAbsent(n, () => []).add((p, t));
      }
    }
    _natIdx = m;
    _adjCache.clear();
  }

  /// فرق مستوى لاعبي المنتخب في اللعبة عن المتوسط (يُضاف إلى نقاط فيفا عند المحاكاة)
  double _natAdj(String n) => _adjCache.putIfAbsent(n, () {
        final l = _natIdx?[n];
        if (l == null || l.length < 11) return 0.0;
        final top = [for (final e in l) e.$1.overall]..sort((a, b) => b.compareTo(a));
        final avg = top.take(11).fold<int>(0, (a, b) => a + b) / 11;
        return ((avg - 72) * 7).clamp(-100, 100).toDouble();
      });

  List<(String, String, double)> _natPool(String n) {
    final l = _natIdx?[n] ?? const <(Player, Team)>[];
    final c = <(String, String, double)>[];
    for (final e in l) {
      final k = switch (e.$1.pos) { Pos.att => 1.0, Pos.mid => 0.35, Pos.def => 0.08, Pos.gk => 0.0 };
      final x = max(1, e.$1.overall - 40).toDouble();
      if (k > 0) c.add((e.$1.name, e.$2.name, k * x * x));
    }
    c.sort((a, b) => b.$3.compareTo(a.$3));
    return c.take(14).toList();
  }

  List<(String, double)> _confClubs(String conf) {
    if (conf == confedOf(country).id) {
      return [for (final t in [...teams, ...foreign.values.where((x) => x.id < 3000)]) (t.name, eloOf(t))];
    }
    return [for (final c in kWorldClubs) if (c.conf == conf) (c.name, elo[c.name] ?? c.elo.toDouble())];
  }

  String _ghostChampion(String conf) {
    final l = _confClubs(conf)..sort((a, b) => b.$2.compareTo(a.$2));
    final e = {for (final x in l) x.$1: x.$2};
    var cur = [for (final x in l.take(conf == 'ofc' ? 4 : 16)) x.$1]..shuffle(rng);
    while (cur.length > 1) {
      final nx = <String>[];
      for (var i = 0; i + 1 < cur.length; i += 2) {
        final a = cur[i], b = cur[i + 1];
        final p = 1 / (1 + pow(10, (e[b]! - e[a]!) / 400));
        nx.add(rng.nextDouble() < p ? a : b);
      }
      if (cur.length.isOdd) nx.add(cur.last);
      cur = nx;
    }
    final w = cur.first;
    elo[w] = e[w]! + 12;
    return w;
  }

  /// نهاية الموسم: أبطال الاتحادات القارية + نافذة المنتخبات + البطولات الكبرى
  void _worldSeasonEnd() {
    if (!realWorld) return;
    final cf = confedOf(country);
    final cc = continental?.champion;
    if (cc != null) {
      contChamps[champKey(season, cf.id)] = team(cc).name;
    } else {
      final l = _confClubs(cf.id)..sort((a, b) => b.$2.compareTo(a.$2));
      if (l.isNotEmpty) contChamps[champKey(season, cf.id)] = l.first.$1;
    }
    for (final c in kConfNames.keys) {
      if (c != cf.id) contChamps[champKey(season, c)] = _ghostChampion(c);
    }
    ensureNat();
    _buildNatIdx();
    nat.seasonWindow(rng, _natAdj);
    for (final d in kNatTours) {
      if (season % d.cycle == d.offset) _playNatTour(d);
    }
    _natIdx = null;
    _adjCache.clear();
  }

  List<String> _natQualify(NatTourDef d, List<String> hosts) {
    final res = <String>[...hosts];
    void add(Iterable<String> l) {
      for (final x in l) {
        if (!res.contains(x)) res.add(x);
      }
    }

    int inConf(String c) => res.where((x) => nat.conf[x] == c).length;
    switch (d.key) {
      case 'wc':
        const slots = {'uefa': 16, 'caf': 9, 'afc': 8, 'conmebol': 6, 'concacaf': 6, 'ofc': 1};
        slots.forEach((c, n) => add(nat.qualifiers([c], n + 4, exclude: {...res}).take(max(0, n - inConf(c)))));
        // ملحقان قاريان: الأفضل تصنيفاً بين أول المتخلفين عن التأهل في كل اتحاد
        final next = <String>[
          for (final c in ['caf', 'afc', 'conmebol', 'concacaf', 'ofc'])
            ...nat.qualifiers([c], 1, exclude: {...res})
        ]..sort((a, b) => nat.pts[b]!.compareTo(nat.pts[a]!));
        add(next.take(2));
      case 'euro':
        add(nat.qualifiers(['uefa'], d.teams, exclude: {...res}).take(d.teams - res.length));
      case 'afcon':
        add(nat.qualifiers(['caf'], d.teams, exclude: {...res}).take(d.teams - res.length));
      case 'asia':
        add(nat.qualifiers(['afc'], d.teams, exclude: {...res}).take(d.teams - res.length));
      case 'copa':
        add(nat.qualifiers(['conmebol'], 10, exclude: {...res}));
        add(nat.qualifiers(['concacaf'], d.teams, exclude: {...res}).take(max(0, d.teams - res.length)));
      case 'gold':
        final guests = nat.ranking.where((x) => nat.conf[x] == 'afc' || nat.conf[x] == 'conmebol').take(2).toList();
        add(nat.qualifiers(['concacaf'], d.teams, exclude: {...res}).take(max(0, d.teams - 2 - res.length)));
        add(guests);
    }
    if (res.length < d.teams) add(nat.ranking.where((x) => !res.contains(x)).take(d.teams - res.length));
    while (res.length > d.teams) {
      final i = res.lastIndexWhere((x) => !hosts.contains(x));
      if (i < 0) break;
      res.removeAt(i);
    }
    return res;
  }

  void _playNatTour(NatTourDef d) {
    final hl = kNatHosts[d.key]!;
    final hosts = [for (final h in hl[(season ~/ d.cycle) % hl.length]) if (nat.pts.containsKey(h)) h];
    final teams = _natQualify(d, hosts);
    final t = nat.play(d, season, teams, hosts, rng, _natAdj, _natPool);
    nat.history.add(t);
    final same = nat.history.where((x) => x.key == d.key).toList();
    while (same.length > 3) {
      nat.history.remove(same.removeAt(0));
    }
    news.insert(0, '🌍 ${d.name}: ${t.champion} بطلاً على ${t.runnerUp}');
    final mine = [for (final p in user.squad) if (p.nat != null && teams.contains(p.nat)) p];
    if (mine.isNotEmpty) {
      news.insert(0, '🌍 شارك ${mine.length} من لاعبيك مع منتخباتهم في ${d.name}');
      for (final p in mine) {
        p.morale = min(100, p.morale + (p.nat == t.champion ? 8 : 2));
        if (p.nat == t.champion) p.awards.add({'s': season, 'c': d.name, 'k': 'cup'});
      }
    }
    for (final e in t.scorers.entries) {
      final f = e.key.split('|');
      if (f.length == 3 && f[2] == user.name && e.value >= 3) {
        news.insert(0, '⚽ لاعبك ${f[0]} سجّل ${e.value} أهداف في ${d.name}');
        fans = min(100, fans + 1);
      }
    }
  }

  int _clubIdByName(String name) {
    for (final e in foreign.entries) {
      if (e.value.name == name) return e.key;
    }
    for (final t in teams) {
      if (t.name == name) return t.id;
    }
    final i = kWorldClubs.indexWhere((c) => c.name == name);
    final reg = kWorldClubs[i];
    final id = 3000 + i;
    final e0 = elo[name] ?? reg.elo.toDouble();
    final s = 65 + (e0 - 1500) / 18;
    foreign[id] = createTeam(rng, id, name, ((s - 55) / 3).round().clamp(1, 10));
    elo[name] = e0;
    return id;
  }

  List<int> _weeksAt(List<double> fr) {
    final w = rounds.length;
    final out = <int>[];
    for (final f in fr) {
      var v = min(w - 2, (f * w).round());
      if (out.isNotEmpty && v <= out.last) v = out.last + 1;
      out.add(v);
    }
    return out;
  }

  /// كأس إنتركونتيننتال كل موسم + كأس العالم للأندية كل 4 مواسم (الموسم 3، 7 ...)
  void _setupWorldCups() {
    ic = null;
    cwc = null;
    if (!realWorld) return;
    final userConf = confedOf(country).id;
    // إنتركونتيننتال: أبطال الاتحادات الستة، الأفضل تصنيفاً يتجاوز الدور الأول
    final names = <String>[];
    for (final conf in kConfNames.keys) {
      var n = contChamps[champKey(season - 1, conf)];
      if (n == null) {
        final l = _confClubs(conf)..sort((a, b) => b.$2.compareTo(a.$2));
        n = conf == userConf ? l.first.$1 : _ghostChampion(conf);
        contChamps[champKey(season - 1, conf)] = n;
      }
      names.add(n);
    }
    final ids = [for (final n in names) _clubIdByName(n)]..sort((a, b) => eloOf(team(b)).compareTo(eloOf(team(a))));
    ic = Cup(key: 'ic', name: 'كأس إنتركونتيننتال', continental: true, schedule: _weeksAt(const [0.36, 0.42, 0.48]), size: 8, alive: ids)..seeded = true;
    _draw(ic!);
    news.insert(0, '🌍 كأس إنتركونتيننتال: ${names.map((n) => n).join(' • ')}');
    if (season % 4 != 3) return;
    const slots = {'uefa': 12, 'conmebol': 6, 'caf': 4, 'afc': 4, 'concacaf': 5, 'ofc': 1};
    final all = <String>[];
    slots.forEach((conf, n) {
      final got = <String>[];
      for (var s = season - 1; s >= season - 4 && got.length < n; s--) {
        final c = contChamps[champKey(s, conf)];
        if (c != null && !got.contains(c)) got.add(c);
      }
      final cand = _confClubs(conf)..sort((a, b) => b.$2.compareTo(a.$2));
      for (final c in cand) {
        if (got.length >= n) break;
        if (!got.contains(c.$1)) got.add(c.$1);
      }
      all.addAll(got);
    });
    if (all.length != 32) return;
    final cid = [for (final n in all) _clubIdByName(n)]..sort((a, b) => eloOf(team(b)).compareTo(eloOf(team(a))));
    final pots = [for (var k = 0; k < 4; k++) (cid.sublist(k * 8, k * 8 + 8)..shuffle(rng))];
    final c = Cup(key: 'cwc', name: 'كأس العالم للأندية', continental: true, schedule: _weeksAt(const [0.50, 0.56, 0.62, 0.70, 0.78, 0.86, 0.94]), size: 32, alive: cid)
      ..kind = 1
      ..lpRounds = 3
      ..groups = [
        for (var g = 0; g < 8; g++) [for (final pot in pots) pot[g]]
      ];
    _draw(c);
    cwc = c;
    news.insert(0, '🏆 انطلقت نسخة كأس العالم للأندية هذا الموسم بمشاركة 32 نادياً');
  }

  /// ترتيب شامل للأندية (بما فيها أندية العالم غير الممثَّلة في اللعبة)
  List<(String, String, double, Team?)> worldClubTable() {
    final uc = confedOf(country).id;
    String confOf(Team t) {
      if (t.id >= 3000) {
        final i = kWorldClubs.indexWhere((c) => c.name == t.name);
        return i < 0 ? uc : kWorldClubs[i].conf;
      }
      return uc;
    }

    final out = <(String, String, double, Team?)>[for (final t in worldRanking) (t.name, confOf(t), eloOf(t), t)];
    final have = {for (final e in out) e.$1};
    if (realWorld) {
      for (final c in kWorldClubs) {
        if (c.conf == uc || have.contains(c.name)) continue;
        out.add((c.name, c.conf, elo[c.name] ?? c.elo.toDouble(), null));
      }
    }
    out.sort((a, b) => b.$3.compareTo(a.$3));
    return out;
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
    // نجوم الأندية القارية والدرجات الأخرى: نقدّر إحصاءاتهم لأنهم لا يلعبون في دوريك
    for (final t in [...foreign.values.where((x) => x.id < 3000), ...upper, ...lower]) {
      for (final p in t.squad) {
        if (p.apps > 0 || p.overall < 66) continue;
        final q = (p.overall - 60).clamp(0, 30) / 30.0;
        p.apps = 22 + rng.nextInt(14);
        switch (p.pos) {
          case Pos.att:
            p.goals = (q * 26 * (0.55 + rng.nextDouble() * 0.6)).round();
            p.assists = (q * 11 * rng.nextDouble()).round();
          case Pos.mid:
            p.goals = (q * 11 * rng.nextDouble()).round();
            p.assists = (q * 14 * (0.4 + rng.nextDouble() * 0.6)).round();
          case Pos.def:
            p.goals = (q * 4 * rng.nextDouble()).round();
            p.assists = (q * 5 * rng.nextDouble()).round();
          case Pos.gk:
            break;
        }
      }
    }
    final all = <(Player, Team)>[
      for (final t in [...teams, ...foreign.values.where((x) => x.id < 3000)])
        for (final p in t.squad)
          if (p.apps > 0) (p, t)
    ];
    if (all.isEmpty) return out;
    double sc((Player, Team) e) {
      final r = rankOf(e.$2);
      final eloBonus = (eloOf(e.$2) - 1500) / 40.0;
      return e.$1.goals * 2.0 + e.$1.assists * 1.5 + e.$1.overall * 0.25 + (r == 0 ? eloBonus : (teams.length - r) * 0.2);
    }
    (Player, Team) best(Iterable<(Player, Team)> l, double Function((Player, Team)) f) =>
        l.reduce((a, b) => f(b) > f(a) ? b : a);

    void give(String title, (Player, Team) e, String extra) {
      out.add('$title: ${e.$1.name} (${e.$2.name}) $extra');
      e.$1.awards.add({'s': season, 'c': title, 'k': 'indiv'});
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
