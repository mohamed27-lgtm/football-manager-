import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/engine.dart';
import 'package:football_manager/models.dart';

void main() {
  test('الألفة التكتيكية: ترتفع بالاستقرار، تنخفض بالتغيير، تؤثر على القوة وتُحفظ', () {
    final t = createTeam(Random(6), 1, 'نادي', 4)..autoPick();
    final xi = t.lineup.take(11).toList();
    t.onMatchStart(xi);
    expect(t.familiarity, 70, reason: 'أول مباراة: لا مقارنة');
    t.onMatchStart(xi);
    expect(t.familiarity, 73);
    for (var i = 0; i < 20; i++) {
      t.onMatchStart(xi);
    }
    expect(t.familiarity, 100, reason: 'سقف 100');
    final other = t.squad.where((p) => !xi.contains(p)).take(3).toList();
    t.onMatchStart([...xi.take(8), ...other]);
    expect(t.familiarity, 95, reason: '3 تغييرات: -6 +1');
    t.shakeFamiliarity(1000);
    expect(t.familiarity, 20, reason: 'أرضية 20');
    expect(t.familiarityFactor, closeTo(1 - 50 * 0.0007, 1e-9));
    final back = Team.fromJson(t.toJson());
    expect(back.familiarity, 20);
    expect(back.lastXI.length, 11);
  });

  test('الألفة تؤثر على قوة الوسط في المحرك للمستخدم فقط', () {
    final a = createTeam(Random(7), 1, 'أ', 4);
    final b = createTeam(Random(7), 1, 'أ', 4);
    final sa = Side(a, true, false), sb = Side(b, true, false);
    sa.team.familiarity = 100;
    expect(sa.midPower, greaterThan(sb.midPower));
    sb.team.familiarity = 20;
    expect(sb.midPower, lessThan(Side(createTeam(Random(7), 1, 'أ', 4), true, false).midPower));
  });
}
