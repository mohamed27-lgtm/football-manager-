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

void _playSeason(GameState gs) {
  var guard = 0;
  while (!gs.seasonOver && guard++ < 600) {
    gs.confidence = 100;
    final c = gs.pendingCup;
    if (c != null) {
      gs.startCupMatch(c);
      gs.finishCurrent();
      continue;
    }
    gs.startMatch();
    gs.finishCurrent();
  }
  expect(gs.seasonOver, isTrue, reason: 'الموسم لم ينتهِ');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('محاكاة 5 مواسم كاملة: كؤوس، إنتركونتيننتال، كأس العالم للأندية، منتخبات، حفظ/تحميل', () {
    final gs = _newGame(7);
    expect(gs.realWorld, isTrue);
    expect(gs.ic, isNotNull, reason: 'إنتركونتيننتال الموسم 1');
    expect(gs.ic!.alive.length, 6);
    for (var s = 1; s <= 5; s++) {
      expect(gs.season, s);
      _playSeason(gs);
      gs.startNewSeason();
      expect(gs.season, s + 1);
      // حفظ وتحميل
      final j = jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>;
      final g2 = GameState.fromJson(j);
      expect(g2.season, gs.season);
      expect(g2.clubPts.length, gs.clubPts.length);
      expect(g2.nat.history.length, gs.nat.history.length);
      expect(g2.ic?.alive.length, gs.ic?.alive.length);
      expect(g2.cwc?.alive.length, gs.cwc?.alive.length);
      // ignore: avoid_print
      print('الموسم $s ✓ clubPts=${gs.clubPts.length} natHist=${gs.nat.history.map((t) => t.key).toList()} cwc=${gs.cwc != null}');
    }
    expect(gs.contChamps.length, greaterThanOrEqualTo(30));
    final wc = gs.nat.history.where((t) => t.key == 'wc').toList();
    expect(wc, isNotEmpty);
    expect(wc.first.teams.length, 48);
    expect(wc.first.champion, isNotNull);
    expect(gs.nat.history.any((t) => t.key == 'afcon'), isTrue);
    expect(gs.nat.rating(wc.first.champion!), greaterThan(0));
    expect(gs.cupHist.where((h) => h['k'] == 'ic'), isNotEmpty);
    expect(gs.worldClubTable().length, greaterThan(50));
    expect(gs.nat.ranking.length, greaterThan(150));
  });
}
