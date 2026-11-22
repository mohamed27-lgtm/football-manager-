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

  test('يوم إغلاق الميركاتو: ينبّه قبله ويُطلق الحدث مرة واحدة في آخر جولة للنافذة', () {
    final gs = _newGame(21);
    expect(gs.windowOpen, isTrue);
    var guard = 0;
    var sawEve = false, sawDay = 0;
    while (gs.week < 5 && guard++ < 80) {
      gs.confidence = 100;
      if (gs.pendingCup != null) {
        gs.startCupMatch(gs.pendingCup!);
      } else {
        gs.startMatch();
      }
      gs.finishCurrent();
      sawEve = sawEve || gs.news.any((n) => n.startsWith('⏳'));
      sawDay = gs.news.where((n) => n.startsWith('⏰')).length;
    }
    expect(sawEve, isTrue, reason: 'تنبيه الجولة الأخيرة');
    expect(sawDay, 1, reason: 'حدث الإغلاق مرة واحدة فقط');
    expect(gs.deadlineDay, isFalse);
  });
}
