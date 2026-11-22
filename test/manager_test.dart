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

  test('رخصة المدرب: مستويات الخبرة، النقاط، الإنفاق، الحد الأقصى، والحفظ', () {
    final gs = _newGame(71);
    expect(gs.mgrLevel, 1);
    expect(gs.perkPoints, 0);
    expect(gs.spendPerk('sp'), isNotNull, reason: 'لا نقاط');
    gs.mgrXp = 100;
    expect(gs.mgrLevel, 2);
    expect(gs.perkPoints, 1);
    expect(gs.mgrNext, (0, 180));
    expect(gs.spendPerk('nope'), isNotNull);
    expect(gs.spendPerk('negot'), isNull);
    expect(gs.perkPoints, 0);
    expect(gs.user.perk('negot'), 1);
    gs.mgrXp = 99999;
    expect(gs.mgrLevel, GameState.xpLevels.length);
    expect(gs.mgrNext, isNull);
    for (var i = 0; i < 5; i++) {
      gs.spendPerk('sp');
    }
    expect(gs.user.perk('sp'), GameState.maxPerkRank);
    expect(gs.spendPerk('sp'), isNotNull, reason: 'أقصى رتبة');
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.mgrXp, 99999);
    expect(g2.user.perks, gs.user.perks);
  });

  test('ميزة المفاوض تخفض سعر الشراء، والخبرة تتراكم من المباريات', () {
    final gs = _newGame(72);
    final p = gs.user.squad.firstWhere((x) => !x.free);
    final base = gs.buyPrice(p);
    gs.user.perks['negot'] = 3;
    expect(gs.buyPrice(p), lessThan(base));
    var guard = 0;
    while (gs.user.played < 3 && guard++ < 30) {
      if (gs.pendingCup != null) {
        gs.startCupMatch(gs.pendingCup!);
      } else {
        gs.startMatch();
      }
      gs.finishCurrent();
    }
    expect(gs.mgrXp, greaterThanOrEqualTo(3), reason: 'كل مباراة تمنح خبرة 1 على الأقل');
  });
}
