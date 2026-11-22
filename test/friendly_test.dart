import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/game_state.dart';
import 'package:football_manager/models.dart';

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
}
