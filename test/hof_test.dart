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

  test('قاعة الشهرة: تتجمّع أرقام لاعبي النادي من سجلهم وتُحفظ وتُرتَّب', () {
    final gs = _newGame(31);
    final ps = gs.user.squad.where((p) => !p.onLoan).take(3).toList();
    ps[0].career.addAll([
      {'s': 1, 't': gs.user.name, 'a': 30, 'g': 20, 'as': 5, 'r': 7.4},
      {'s': 2, 't': gs.user.name, 'a': 28, 'g': 15, 'as': 4, 'r': 7.2},
      {'s': 3, 't': 'نادٍ آخر', 'a': 99, 'g': 99, 'as': 99, 'r': 7.0},
    ]);
    ps[1].career.add({'s': 1, 't': gs.user.name, 'a': 45, 'g': 0, 'as': 1, 'r': 6.8});
    ps[2].career.add({'s': 1, 't': gs.user.name, 'a': 3, 'g': 0, 'as': 0, 'r': 6.0});
    for (final p in ps) {
      p.apps = 0;
      p.goals = 0;
      p.assists = 0;
    }
    // تنشيط التحديث عبر مباراة واحدة
    var guard = 0;
    while (gs.legends.isEmpty && guard++ < 10) {
      gs.confidence = 100;
      if (gs.pendingCup != null) {
        gs.startCupMatch(gs.pendingCup!);
      } else {
        gs.startMatch();
      }
      gs.finishCurrent();
    }
    final hf = gs.hallOfFame;
    expect(hf.isNotEmpty, isTrue);
    expect(hf.first['id'], ps[0].id, reason: 'الأعلى نقاطاً: 58 مباراة و35 هدفاً');
    expect(hf.first['g'], greaterThanOrEqualTo(35), reason: 'لا تُحتسب أهداف النادي الآخر');
    expect(hf.first['g'], lessThan(99));
    expect(hf.any((e) => e['id'] == ps[2].id), isFalse, reason: '3 مباريات لا تكفي');
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.legends.length, gs.legends.length);
    expect(g2.hallOfFame.first['id'], ps[0].id);
  });
}
