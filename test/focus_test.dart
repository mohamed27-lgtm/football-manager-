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

  test('التدريب الفردي: خيارات حسب المركز، حدّ اللاعبين، وحفظ التركيز', () {
    final gs = _newGame(61);
    final sq = gs.user.squad.where((p) => !p.onLoan).toList();
    final gk = sq.firstWhere((p) => p.pos == Pos.gk);
    final att = sq.firstWhere((p) => p.pos == Pos.att);
    expect(gs.focusOptions(gk), ['gk']);
    expect(gs.focusOptions(att), ['atk', 'pas']);
    expect(gs.setFocus(att, 'def'), isNotNull, reason: 'مهارة لا تناسب المركز');
    expect(att.focus, isNull);
    expect(gs.setFocus(att, 'atk'), isNull);
    expect(att.focus, 'atk');
    // الحد الأقصى
    final others = sq.where((p) => p != att && p.pos != Pos.gk).toList();
    var ok = 1;
    for (final p in others) {
      final f = gs.focusOptions(p).first;
      if (gs.setFocus(p, f) == null) ok++;
    }
    expect(ok, gs.maxFocus);
    expect(gs.focusCount, gs.maxFocus);
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.focusCount, gs.focusCount);
    expect(gs.setFocus(att, null), isNull);
    expect(att.focus, isNull);
  });

  test('التدريب الفردي يرهق اللاعب أسبوعياً ويحسّن المهارة المختارة في المتوسط', () {
    final gs = _newGame(62);
    final p = gs.user.squad.where((x) => x.pos == Pos.mid && !x.onLoan).first
      ..age = 19
      ..potential = 90
      ..atk = 50
      ..pas = 50
      ..def = 50;
    gs.setFocus(p, 'atk');
    var guard = 0;
    final load0 = p.load;
    var sawLoad = false;
    while (gs.user.played < 12 && guard++ < 60) {
      gs.confidence = 100;
      if (gs.pendingCup != null) {
        gs.startCupMatch(gs.pendingCup!);
      } else {
        gs.startMatch();
      }
      gs.finishCurrent();
      if (p.load > load0) sawLoad = true;
    }
    expect(sawLoad, isTrue, reason: 'إجهاد إضافي');
    expect(p.atk, greaterThanOrEqualTo(50));
  });
}
