import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/game_state.dart';
import 'package:football_manager/engine.dart';
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

  test('الشائعات: تُنفى، وتُحفظ في JSON، وتتولد مع الأسابيع ولا تتجاوز 3', () {
    final gs = _newGame(91);
    final p = gs.user.squad.first;
    expect(gs.rumorOf(p), isNull);
    expect(gs.denyRumor(p), isNotNull);
    gs.rumors.add((pid: p.id, club: 'نادي تجريبي', weeks: 4));
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.rumors.length, 1);
    expect(g2.rumors.first.club, 'نادي تجريبي');
    final m = p.morale;
    expect(gs.denyRumor(p), isNull);
    expect(gs.rumors, isEmpty);
    expect(p.morale, greaterThanOrEqualTo(m));
    var guard = 0, maxSeen = 0;
    while (gs.user.played < 30 && guard++ < 80) {
      if (gs.pendingCup != null) {
        gs.startCupMatch(gs.pendingCup!);
      } else {
        gs.startMatch();
      }
      gs.finishCurrent();
      maxSeen = max(maxSeen, gs.rumors.length);
    }
    expect(maxSeen, lessThanOrEqualTo(3));
  });
}
