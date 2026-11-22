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

  test('وعد المشاركة: حدّ 3 وعود، يُحفظ، ويُحاسَب عليه بعد 8 مباريات', () {
    final gs = _newGame(11);
    final ps = gs.user.squad.where((p) => !p.onLoan).take(4).toList();
    for (var i = 0; i < 3; i++) {
      expect(gs.promisePlaying(ps[i]), isNull);
    }
    expect(gs.promisePlaying(ps[3]), isNotNull, reason: 'الحد الأقصى 3');
    expect(gs.promisePlaying(ps[0]), isNotNull, reason: 'وعد مكرر');
    final j = jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>;
    final g2 = GameState.fromJson(j);
    expect(g2.user.squad.where((p) => p.promise != 0).length, 3);
    // لعب 10 مباريات؛ يُحاسَب كل وعد مرة واحدة ثم يُصفَّر
    var guard = 0;
    while (gs.user.played < 10 && guard++ < 60) {
      gs.confidence = 100;
      if (gs.pendingCup != null) {
        gs.startCupMatch(gs.pendingCup!);
      } else {
        gs.startMatch();
      }
      gs.finishCurrent();
    }
    expect(gs.user.played, greaterThanOrEqualTo(8));
    expect(gs.activePromises, 0, reason: 'تم تقييم كل الوعود');
  });
}
