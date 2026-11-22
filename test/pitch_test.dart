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

  test('أرضية الملعب: تتدهور بالمباريات على الأرض، تتعافى أسبوعياً، والصيانة بتكلفة ومهلة', () {
    final gs = _newGame(81);
    expect(gs.user.pitch, 90);
    expect(gs.pitchLabel, 'ممتازة');
    gs.user.pitch = 40;
    expect(gs.pitchLabel, 'سيئة جداً');
    final b = gs.user.budget;
    expect(gs.maintainPitch(), isNull);
    expect(gs.user.pitch, 65);
    expect(gs.user.budget, lessThan(b));
    expect(gs.maintainPitch(), isNotNull, reason: 'مهلة 4 أسابيع');
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.user.pitch, 65);
    // لعب مباريات: تغيّر الحالة (تدهور بالمباريات على الأرض وتعافٍ أسبوعي)
    var guard = 0;
    final p0 = gs.user.pitch;
    var changed = false;
    while (gs.user.played < 4 && guard++ < 30) {
      if (gs.pendingCup != null) {
        gs.startCupMatch(gs.pendingCup!);
      } else {
        gs.startMatch();
      }
      gs.finishCurrent();
      if (gs.user.pitch != p0) changed = true;
    }
    expect(changed, isTrue);
    expect(gs.user.pitch, inInclusiveRange(20, 100));
  });

  test('المحرك: الأرضية السيئة تخفض الدقة وتزيد خسارة الجودة للفريقين', () {
    final r = Random(3);
    final a = createTeam(r, 1, 'مضيف', 4), b = createTeam(r, 2, 'ضيف', 4);
    final ok = MatchSim(a, b, random: Random(1));
    expect(ok.pitchLoss, 0, reason: 'أرضية 90 = لا خسارة');
    a.pitch = 40;
    final bad = MatchSim(a, b, random: Random(1));
    expect(bad.pitchLoss, 45);
    a.pitch = 5;
    expect(MatchSim(a, b, random: Random(1)).pitchLoss, 65, reason: 'سقف الخسارة');
  });
}
