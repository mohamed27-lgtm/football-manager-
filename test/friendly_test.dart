import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/game_state.dart';
import 'package:football_manager/engine.dart';
import 'package:football_manager/models.dart';
import 'package:football_manager/wallet.dart';
import 'package:football_manager/transfers.dart';
import 'package:football_manager/stadiums.dart';
import 'package:football_manager/countries.dart';
import 'package:football_manager/flags.dart';

List<Team> _pool(Random r, int base, int n, String tag) => [for (var i = 0; i < n; i++) createTeam(r, base + i, '$tag ${i + 1}', 3 + i % 5)];

GameState _newGame(int seed) {
  final r = Random(seed);
  final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 4)];
  final py = Pyramid(
    world: _pool(r, 1000, 36, 'أوروبي'),
    worldEl: _pool(r, 1100, 36, 'يوروبا'),
    worldCo: _pool(r, 1200, 36, 'مؤتمر'),
    userSlots: 4,
    userSlotsEl: 1,
    userSlotsCo: 1,
    country: 'إسبانيا',
    leagueId: 1,
  );
  return GameState.fromData(teams, 0, 'الدوري التجريبي', pyramid: py);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('الودية: 3 فقط قبل أول مباراة، لا تدخل الترتيب، وترفع التأقلم', () {
    final gs = _newGame(95);
    expect(gs.friendlyOpen, isTrue);
    expect(gs.friendlyOpponents().length, 3);
    gs.user.familiarity = 60;
    final played = gs.user.played;
    final opp = gs.friendlyOpponents().first;
    final r = gs.playFriendly(opp);
    expect(r, isNotNull);
    expect(gs.friendliesLeft, 2);
    expect(gs.user.played, played);
    expect(gs.user.familiarity, greaterThanOrEqualTo(60));
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.friendliesLeft, 2);
    gs.playFriendly(opp);
    gs.playFriendly(opp);
    expect(gs.friendlyOpen, isFalse);
    expect(gs.playFriendly(opp), isNull);
  });

  test('التوقف الدولي: كل 8 مباريات مرة واحدة، يمس النجوم فقط', () {
    final gs = _newGame(96);
    for (final p in gs.user.squad.take(3)) {
      p..atk = 99..pas = 99..def = 99..gk = 99;
    }
    gs.user.played = 5;
    gs.intlBreakTick();
    expect(gs.intlDone, 0);
    gs.user.played = 8;
    final n0 = gs.news.length;
    gs.intlBreakTick();
    expect(gs.intlDone, 8);
    expect(gs.news.length, greaterThan(n0));
    final n1 = gs.news.length;
    gs.intlBreakTick();
    expect(gs.news.length, n1);
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.intlDone, 8);
  });

  test('الاستحواذ: القبول يضخ مالاً ويرفع صعوبة الهدف، والرفض يخفض الثقة', () {
    final gs = _newGame(97);
    expect(gs.decideTakeover(true), isNotNull);
    gs.takeoverPending = 'مجموعة الصقر';
    gs.objective = 8;
    final b = gs.user.budget;
    expect(gs.decideTakeover(true), isNull);
    expect(gs.user.budget, greaterThan(b));
    expect(gs.objective, 6);
    expect(gs.investor, 'مجموعة الصقر');
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.investor, 'مجموعة الصقر');
    gs.takeoverPending = 'صندوق الأفق';
    final c = gs.confidence;
    gs.decideTakeover(false);
    expect(gs.confidence, lessThan(c));
    expect(gs.takeoverPending, isNull);
  });

  test('الأكاديمية: فئات حسب المستوى وفرصة الجوهرة تزداد', () {
    expect(GameState.academyTier(1), 'برونزية');
    expect(GameState.academyTier(5), 'نخبة');
    expect(GameState.wonderChance(5), greaterThan(GameState.wonderChance(1)));
    final gs = _newGame(98);
    gs.user.academy = 5;
    var gems = 0;
    for (var i = 0; i < 60; i++) {
      gs.news.clear();
      gs.user.squad.removeWhere((p) => p.age <= 18);
      gs.academyIntakeForTest();
      gems += gs.news.where((n) => n.startsWith('💎')).length;
    }
    expect(gems, greaterThan(0));
  });

  test('عدم التكرار: لاعب فريقي لا يظهر في السوق ولا في نادٍ آخر', () {
    final gs = _newGame(99);
    final mine = gs.user.squad.firstWhere((p) => !p.filler);
    final other = gs.teams.firstWhere((t) => t != gs.user);
    other.squad.add(Player.fromJson(mine.toJson())..club = other.name);
    gs.freeAgents.add(Player.fromJson(mine.toJson())..free = true);
    gs.dedupePlayers();
    expect(other.squad.where((p) => p.id == mine.id), isEmpty);
    expect(gs.freeAgents.where((p) => p.id == mine.id), isEmpty);
    gs.market = [Player.fromJson(mine.toJson())];
    gs.purgeElsewhere(mine);
    expect(gs.market, isEmpty);
    expect(gs.user.squad.where((p) => p.id == mine.id).length, 1);
  });

  test('التفاوض على العروض الواردة: سعر معقول يُقبل، مبالغ فيه ينسحب النادي', () {
    final gs = _newGame(100);
    final p = gs.user.squad.firstWhere((x) => !x.filler);
    final club = gs.teams.firstWhere((t) => t != gs.user);
    club.budget = 500;
    final o = Offer(p, club.name, p.value, 3);
    gs.offers.add(o);
    expect(gs.windowOpen, isTrue);
    final ceil = gs.offerCeiling(o);
    expect(ceil, greaterThanOrEqualTo(o.amount));
    final r1 = gs.counterIncoming(o, o.amount);
    expect(r1.status, 'accept');
    final r2 = gs.counterIncoming(o, ceil * 0.9 + 0.2);
    expect(['accept', 'counter'], contains(r2.status));
    final o2 = Offer(p, club.name, p.value, 3);
    gs.offers.add(o2);
    final r3 = gs.counterIncoming(o2, ceil * 3 + 10);
    expect(r3.status, 'reject');
    expect(gs.offers.contains(o2), isFalse);
  });

  test('سعة الملاعب: حقيقية للأندية المعروفة وتزداد 14% لكل مستوى', () {
    expect(stadiumBaseCapacity('Barcelona', 5), 99354);
    expect(stadiumBaseCapacity('Real Madrid', 5), 83186);
    expect(stadiumBaseCapacity('نادي مجهول', 3), 6000 + 5500 * 3);
    final gs = _newGame(101);
    final c1 = gs.capacityAt(1);
    expect(gs.capacityAt(3), greaterThan(c1));
    expect(gs.capacityAt(3), closeTo(c1 * 1.28, 300));
  });

  test('واقعية السعر: العقد القصير يخفض والأساسي يرفع', () {
    final gs = _newGame(102);
    final owner = gs.teams.firstWhere((t) => t != gs.user);
    final star = ([...owner.squad]..sort((a, b) => b.overall.compareTo(a.overall))).first;
    star..contract = 3..listed = false..injuredWeeks = 0..age = 27;
    final base = gs.buyPrice(star);
    expect(gs.priceFactors(star).any((e) => e.$2 > 1), isTrue);
    star.contract = 1;
    expect(gs.buyPrice(star), lessThan(base));
    expect(gs.priceFactors(star).any((e) => e.$1.contains('ينتهي')), isTrue);
  });

  test('هوية اللاعب: «I. Saibari» و«Ismael Saibari» لاعب واحد، تبقى النسخة الكاملة', () {
    final gs = _newGame(103);
    final others = gs.teams.where((t) => t != gs.user).toList();
    final base = others[0].squad.firstWhere((p) => !p.filler).toJson();
    Player mk(int id, String name) => Player.fromJson({...base, 'id': id, 'name': name, 'nat': 'Morocco', 'age': 24});
    final a = mk(990001, 'I. Saibari'), b = mk(990002, 'Ismael Saibari');
    others[0].squad.add(a);
    others[1].squad.add(b);
    gs.dedupeByIdentity();
    final all = [for (final t in gs.teams) ...t.squad].where((p) => p.name.contains('Saibari')).toList();
    expect(all.length, 1);
    expect(all.single.name, 'Ismael Saibari');
  });

  test('الأحدث جلباً يفوز حتى لو الاسم مختصر', () {
    final gs = _newGame(104);
    final others = gs.teams.where((t) => t != gs.user).toList();
    final base = others[0].squad.firstWhere((p) => !p.filler).toJson();
    Player mk(int id, String name) => Player.fromJson({...base, 'id': id, 'name': name, 'nat': 'Morocco', 'age': 24});
    others[0].dataAt = 1000;
    others[1].dataAt = 5000;
    others[0].squad.add(mk(990011, 'Ismael Saibari'));
    others[1].squad.add(mk(990012, 'I. Saibari'));
    gs.dedupeByIdentity();
    final all = [for (final t in gs.teams) ...t.squad].where((p) => p.name.contains('Saibari')).toList();
    expect(all.length, 1);
    expect(all.single.name, 'I. Saibari');
  });

  test('القيمة السوقية: سقف حسب المركز، والإصابة الطويلة تخفض، والعمر يتدرج', () {
    final gs = _newGame(105);
    final p = gs.user.squad.firstWhere((x) => !x.filler);
    p.mv0 = 900;
    p.ov0 = p.overall;
    p.age0 = p.age;
    p.pub = null;
    expect(p.value, lessThanOrEqualTo(p.valueCap));
    p.pub = null;
    final base = (p..mv0 = 60..ov0 = p.overall).value;
    p.injuredWeeks = 10;
    expect(p.liveValue, lessThan(base));
    p.injuredWeeks = 0;
    p.age0 = 22;
    p.age = 22;
    final young = p.liveValue;
    p.age = 31;
    expect(p.liveValue, lessThan(young));
    final big = gs.clubStature;
    expect(big, inInclusiveRange(0.85, 2.0));
  });

  test('تطور اللاعب: اللقطة تُحفظ والفروق تُحسب', () {
    final gs = _newGame(106);
    final p = gs.user.squad.firstWhere((x) => !x.filler);
    p.sOv = p.overall - 3;
    p.sVal = p.value - 2;
    expect(p.ovDelta, 3);
    expect(p.valDelta, closeTo(2, 0.01));
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    final q = g2.user.squad.firstWhere((x) => x.id == p.id);
    expect(q.ovDelta, 3);
    gs.snapProgress(force: true);
    expect(p.ovDelta, 0);
  });

  test('هوية اللاعب: يُدمج رغم اختلاف المركز، ولا يُدمج المختصران المختلفان', () {
    final gs = _newGame(107);
    final others = gs.teams.where((t) => t != gs.user).toList();
    final base = others[0].squad.firstWhere((p) => !p.filler).toJson();
    Player mk(int id, String name, int pos) => Player.fromJson({...base, 'id': id, 'name': name, 'nat': 'Morocco', 'age': 24, 'pos': pos});
    others[0].dataAt = 1000;
    others[1].dataAt = 9000;
    others[0].squad.add(mk(990021, 'I. Saibari', 1));
    others[1].squad.add(mk(990022, 'Ismael Saibari', 2));
    others[2].squad.add(mk(990023, 'M. Hansen', 3));
    others[3].squad.add(mk(990024, 'M. Hansen', 3));
    gs.dedupeByIdentity();
    final all = [for (final t in gs.teams) ...t.squad];
    expect(all.where((p) => p.name.contains('Saibari')).length, 1);
    expect(all.where((p) => p.name.contains('Saibari')).single.name, 'Ismael Saibari');
    expect(all.where((p) => p.name == 'M. Hansen').length, 2);
  });

  test('الرقم نفسه في ناديين: تبقى نسخة الدوري الأحدث', () {
    final gs = _newGame(108);
    final others = gs.teams.where((t) => t != gs.user).toList();
    final p0 = others[0].squad.firstWhere((p) => !p.filler);
    final copy = Player.fromJson(p0.toJson());
    others[0].dataAt = 100;
    others[1].dataAt = 900;
    others[1].squad.add(copy);
    gs.dedupePlayers();
    expect(others[0].squad.where((p) => p.id == p0.id), isEmpty);
    expect(others[1].squad.where((p) => p.id == p0.id).length, 1);
  });

  test('الأعلام: كل دولة في القائمة لها ملف علم مضمّن', () {
    final missing = <String>[];
    for (final c in kAllCountries) {
      if (!File('assets/flags/${c.iso.toLowerCase()}.png').existsSync()) missing.add('${c.name}:${c.iso}');
    }
    expect(missing, isEmpty);
    for (final iso in kCountryIso.values) {
      expect(File('assets/flags/$iso.png').existsSync(), isTrue, reason: iso);
    }
  });

  test('القيمة المعلنة لا تتحرك إلا عند النشر، ونوافذ التحديث محددة', () {
    final gs = _newGame(109);
    final p = gs.user.squad.firstWhere((x) => !x.filler);
    p.mv0 = 20;
    p.ov0 = p.overall;
    p.age0 = p.age;
    p.publishValue();
    final shown = p.value;
    p.mv0 = 40;
    expect(p.value, shown);
    expect(p.pendingValue, greaterThan(shown));
    gs.publishAllValues('اختبار');
    expect(p.value, p.pendingValue);
    expect(gs.valueWindows.length, 2);
    expect(gs.valueWindows[0].$1, lessThan(gs.valueWindows[1].$1));
    expect(gs.matchesToValueUpdate, isNotNull);
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.user.squad.firstWhere((x) => x.id == p.id).pub, p.pub);
  });

  test('جوائز الدوري: البطل أكثر بكثير من الأخير ومرتبطة بمستوى الدوري', () {
    final gs = _newGame(110);
    expect(gs.leagueMoneyF, inInclusiveRange(0.2, 1.0));
    final cup = gs.continental!;
    expect(gs.koPrize(cup, 4), greaterThan(gs.koPrize(cup, 16)));
    expect(gs.koPrize(cup, 2), lessThan(gs.koPrize(cup, 4)));
  });

  test('قواعد التبديل: 5 كحد أقصى و3 فرص والاستراحة مجانية ومن خرج لا يعود', () {
    final gs = _newGame(120);
    final a = gs.teams[0], b = gs.teams[1];
    final sim = MatchSim(a, b, userHome: true, random: Random(1));
    final s = sim.home;
    Player outOf(int i) => s.slots.where((x) => x.pos != Pos.gk).toList()[i].p;
    for (var k = 0; k < 3; k++) {
      sim.minute = 10 + k * 5;
      final bn = s.bench.where((x) => x.pos != Pos.gk).first;
      expect(sim.substitute(s, outOf(k), bn), isNull);
    }
    expect(s.subWindows, 3);
    sim.minute = 40;
    var bn = s.bench.where((x) => x.pos != Pos.gk).first;
    expect(sim.substitute(s, outOf(5), bn), isNotNull); // الفرصة الرابعة مرفوضة
    expect(sim.substitute(s, outOf(5), bn, half: true), isNull); // الاستراحة مجانية
    expect(s.subsLeft, 1);
    final gone = s.subLog.first.out;
    expect(s.bench.contains(gone), isFalse);
    sim.minute = 10; // نفس الدقيقة التي حدث فيها تبديل سابق
    bn = s.bench.where((x) => x.pos != Pos.gk).first;
    expect(sim.substitute(s, outOf(6), bn, half: true), isNull);
    bn = s.bench.isEmpty ? bn : s.bench.first;
    expect(sim.substitute(s, outOf(7), bn, half: true), isNotNull); // استُنفدت الخمسة
  });

  test('تعليمات اللاعبين: تُحفظ، وتبقى المحاكاة سليمة', () {
    final gs = _newGame(130);
    final t = gs.teams[0];
    final fw = t.squad.firstWhere((p) => p.pos == Pos.att);
    t.instr[fw.id] = 'long';
    final back = Team.fromJson(t.toJson());
    expect(back.instr[fw.id], 'long');
    var g1 = 0, g2 = 0;
    for (var i = 0; i < 40; i++) {
      final s = MatchSim(gs.teams[0], gs.teams[1], userHome: true, random: Random(i))..simulateAll();
      g1 += s.home.goals;
      g2 += s.away.goals;
    }
    expect(g1 + g2, greaterThan(0));
  });

  test('أهداف المجلس الثانوية: لقطة الشباب والتقييم والحفظ', () {
    final gs = _newGame(140);
    gs.snapBoardGoals();
    expect(gs.youthDone, 0);
    for (final p in gs.user.squad.where((p) => p.age <= 21)) {
      p.apps += gs.youthMinApps;
    }
    final c0 = gs.confidence;
    gs.evaluateBoardGoals();
    expect((gs.confidence - c0).abs(), lessThanOrEqualTo(8));
    final j = gs.toJson();
    expect(j['ya0'], isA<Map>());
  });

  test('كوينز اللعبة: رصيد مشترك، مكافأة يومية مرة كل 20 ساعة، وخصم لا يتجاوز الرصيد', () {
    final w = Wallet.i;
    w.coins = 100;
    w.lastDaily = 0;
    final t0 = DateTime(2026, 11, 26, 10);
    expect(w.claimDaily(t0), Wallet.dailyReward);
    expect(w.coins, 125);
    expect(w.claimDaily(t0.add(const Duration(hours: 5))), 0);
    expect(w.claimDaily(t0.add(const Duration(hours: 21))), Wallet.dailyReward);
    expect(w.spend(10000), isFalse);
    expect(w.spend(50), isTrue);
    final gs = _newGame(150);
    expect(gs.coins, w.coins);
    gs.coins = gs.coins - 10;
    expect(w.coins, gs.coins);
  });

  test('مزايا الكوينز: الدفع، التمديد، العلاج، الأسطورة، التسريع، والأولوية', () {
    final gs = _newGame(160);
    Wallet.i.coins = 2000;
    // الكشّاف: إما يضيف مواهب أو يعتذر دون خصم
    final c0 = Wallet.i.coins;
    final m0 = gs.market.length;
    final r = gs.premiumScout();
    if (r == null) {
      expect(gs.market.length, greaterThan(m0));
      expect(Wallet.i.coins, c0 - CoinPerks.costScout);
    } else {
      expect(Wallet.i.coins, c0);
    }
    // تمديد النافذة: مرة واحدة في الموسم
    expect(gs.windowOpen, isTrue);
    expect(gs.extendWindow(), isNull);
    expect(gs.windowExtended, isTrue);
    expect(gs.extendWindow(), isNotNull);
    gs.week = 5; // كانت ستُغلق (الأسبوع 4) لكنها ممددة
    expect(gs.windowOpen, isTrue);
    gs.week = 7;
    expect(gs.windowOpen, isFalse);
    gs.week = 0;
    // العلاج
    final p = gs.user.squad.first..injuredWeeks = 8;
    expect(gs.healInjury(p), isNull);
    expect(p.injuredWeeks, 4);
    expect(gs.healInjury(p), isNotNull);
    // الأولوية
    expect(gs.buyPriority(), isNull);
    expect(gs.priorityActive, isTrue);
    // الأسطورة: واحد في الموسم
    final n0 = gs.user.squad.length;
    expect(gs.signLegend(0), isNull);
    expect(gs.user.squad.length, n0 + 1);
    expect(gs.signLegend(1), isNotNull);
    // رصيد غير كافٍ
    Wallet.i.coins = 5;
    expect(gs.buyPriority(), isNotNull);
    expect(gs.retryNegotiation(gs.user.squad.first), isNotNull);
    // سلامة الحفظ
    final back = GameState.fromJson(gs.toJson());
    expect(back.legendSeason, gs.season);
    expect(back.windowExtSeason, gs.season);
  });
}
