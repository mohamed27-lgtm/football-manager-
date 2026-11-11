import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/game_state.dart';
import 'package:football_manager/models.dart';

List<Team> _pool(Random r, int base, int n, String tag) => [for (var i = 0; i < n; i++) createTeam(r, base + i, '$tag ${i + 1}', 3 + i % 5)];

GameState _game(int seed, bool real) {
  final r = Random(seed);
  final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
  if (!real) return GameState.fromData(teams, 2, 'تجريبي');
  final py = Pyramid(
    div: 2,
    upper: [for (var i = 0; i < 20; i++) createTeam(r, 100 + i, 'درجة أولى ${i + 1}', 2 + i % 3)],
    upperName: 'الدرجة الأولى',
    lower: [for (var i = 0; i < 20; i++) createTeam(r, 200 + i, 'درجة ثالثة ${i + 1}', 1 + i % 3)],
    lowerName: 'الدرجة الثالثة',
    world: _pool(r, 1000, 36, 'أوروبي'),
    worldEl: _pool(r, 1100, 36, 'يوروبا'),
    worldCo: _pool(r, 1200, 36, 'مؤتمر'),
    userSlots: 2,
    userSlotsEl: 1,
    userSlotsCo: 1,
    country: 'المغرب',
    leagueId: 2,
  );
  return GameState.fromData(teams, 2, 'الدوري المغربي', pyramid: py);
}

void _act(GameState gs, Random r) {
  switch (r.nextInt(16)) {
    case 0:
      if (gs.market.isNotEmpty) gs.buy(gs.market[r.nextInt(gs.market.length)]);
    case 1:
      if (gs.user.squad.length > 20) gs.sell(gs.user.squad[r.nextInt(gs.user.squad.length)]);
    case 2:
      if (gs.market.isNotEmpty) gs.loanIn(gs.market[r.nextInt(gs.market.length)]);
    case 3:
      if (gs.user.squad.length > 20) gs.loanOut(gs.user.squad[r.nextInt(gs.user.squad.length)]);
    case 4:
      gs.toggleListed(gs.user.squad[r.nextInt(gs.user.squad.length)]);
    case 5:
      if (gs.offers.isNotEmpty) gs.acceptOffer(gs.offers[r.nextInt(gs.offers.length)]);
    case 6:
      gs.upgrade(r.nextBool() ? 'stadium' : 'training');
    case 7:
      r.nextBool() ? gs.takeLoan(5) : gs.repay(5);
    case 8:
      if (gs.user.squad.length > 22) gs.release(gs.user.squad[r.nextInt(gs.user.squad.length)]);
    case 9:
      for (final role in gs.staff.keys) {
        gs.upgradeStaff(role);
      }
    case 10:
      for (final o in gs.sponsorOffers.values.expand((e) => e).toList()) {
        gs.signSponsor(o);
      }
    case 11:
      final p = gs.user.squad[r.nextInt(gs.user.squad.length)];
      gs.renewOffer(p, gs.renewDemand(p) * 1.05, 1 + r.nextInt(4));
    case 12:
      gs.runCampaign();
    case 13:
      gs.setFormation(Formation.values[r.nextInt(Formation.values.length)]);
      gs.setMentality(r.nextInt(5));
      gs.autoPickUser();
    case 14:
      gs.setTraining(const ['technical', 'physical', 'mental', 'tactical'][r.nextInt(4)]);
      gs.setIntensity(r.nextInt(3));
    case 15:
      if (gs.boardKind != null) gs.answerBoard(r.nextBool());
  }
}

void _season(GameState gs, Random r) {
  var guard = 0;
  while (!gs.seasonOver && guard++ < 600) {
    gs.confidence = 100;
    if (gs.user.budget < 5) gs.user.budget += 20;
    for (var k = 0; k < 3; k++) {
      _act(gs, r);
    }
    final c = gs.pendingCup;
    if (c != null) {
      gs.startCupMatch(c);
      gs.finishCurrent();
      continue;
    }
    gs.startMatch();
    gs.finishCurrent();
  }
  expect(gs.seasonOver, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  for (final real in [false, true]) {
    test('أفعال عشوائية للمستخدم عبر 4 مواسم (${real ? 'عالم حقيقي بالدرجات' : 'عالم خيالي'})', () {
      for (final seed in [1, 2]) {
        final gs = _game(seed, real);
        final r = Random(seed * 31);
        for (var s = 1; s <= 4; s++) {
          _season(gs, r);
          expect(gs.user.squad.length, greaterThanOrEqualTo(11));
          gs.startNewSeason();
          final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
          expect(g2.season, gs.season);
          expect(g2.user.squad.length, gs.user.squad.length);
        }
      }
    });
  }
}
