import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/game_state.dart';
import 'package:football_manager/models.dart';
import 'package:football_manager/transfers.dart';
import 'package:football_manager/stadiums.dart';

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
}
