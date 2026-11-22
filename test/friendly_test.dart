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
}
