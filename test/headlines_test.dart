import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/game_state.dart';
import 'package:football_manager/headlines.dart';
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

  test('العناوين الصحفية: تُولَّد من حالة الدوري والمصابين والثقة', () {
    final gs = _newGame(41);
    expect(headlinesOf(gs).where((h) => h.$1 == '🔝'), isEmpty, reason: 'لا ترتيب قبل أي مباراة');
    var guard = 0;
    while (gs.user.played < 4 && guard++ < 30) {
      if (gs.pendingCup != null) {
        gs.startCupMatch(gs.pendingCup!);
      } else {
        gs.startMatch();
      }
      gs.finishCurrent();
    }
    var hs = headlinesOf(gs);
    expect(hs.any((h) => h.$1 == '🔝' && h.$2.contains('يتصدر الدوري')), isTrue);
    expect(hs.length, lessThanOrEqualTo(9));
    for (final p in gs.user.squad.take(4)) {
      p.injuredWeeks = 3;
    }
    gs.confidence = 10;
    hs = headlinesOf(gs);
    expect(hs.any((h) => h.$1 == '🚑'), isTrue);
    expect(hs.any((h) => h.$2.contains('تفقد صبرها')), isTrue);
    gs.fired = true;
    expect(headlinesOf(gs), isEmpty);
  });
}
