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

  test('الإرشاد: شروط المرشد والشاب، معامل النمو، الحد الأقصى، والحفظ', () {
    final gs = _newGame(51);
    final sq = gs.user.squad.where((p) => !p.onLoan).toList();
    final mid = sq.where((p) => p.pos == Pos.mid).take(5).toList();
    expect(mid.length, greaterThanOrEqualTo(2));
    final kid = mid[0]..age = 19;
    final old = mid[1]
      ..age = 32
      ..overall = 70
      ..trait = 'قائد';
    expect(gs.canMentor(old, kid), isTrue);
    expect(gs.assignMentor(kid, old), isNull);
    expect(gs.mentorOf(kid), same(old));
    expect(gs.menteeOf(old), same(kid));
    expect(gs.mentorFactor(kid), 1.2);
    old.trait = 'عادي';
    expect(gs.mentorFactor(kid), 1.12);
    expect(gs.canMentor(old, mid[2]..age = 18), isFalse, reason: 'المرشد مشغول');
    final grown = mid[3]..age = 25;
    expect(gs.assignMentor(grown, old), isNotNull, reason: 'الشاب أكبر من 21');
    final j = jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>;
    final g2 = GameState.fromJson(j);
    expect(g2.user.mentors, {kid.id: old.id});
    gs.removeMentor(kid);
    expect(gs.mentorOf(kid), isNull);
    expect(gs.mentorFactor(kid), 1.0);
    final weak = sq.firstWhere((p) => p.pos == Pos.def)
      ..age = 33
      ..overall = 50;
    final kid2 = sq.firstWhere((p) => p.pos == Pos.def && p != weak)..age = 18;
    expect(gs.canMentor(weak, kid2), isFalse, reason: 'تقييم ضعيف');
  });
}
