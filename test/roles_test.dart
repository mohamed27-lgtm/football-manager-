import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/engine.dart';
import 'package:football_manager/models.dart';

void main() {
  test('أدوار اللاعبين: تأثير على قوى الفريق، تتجاهل المركز الخاطئ، وتُحفظ', () {
    final t = createTeam(Random(5), 1, 'نادي', 4)..autoPick();
    final mid = t.lineup.firstWhere((p) => p.pos == Pos.mid);
    final att = t.lineup.firstWhere((p) => p.pos == Pos.att);
    expect(t.roleEffect(t.lineup), (0.0, 0.0, 0.0));
    t.roles[mid.id] = 'playmaker';
    final fx = t.roleEffect(t.lineup);
    expect(fx.$2, greaterThan(0));
    expect(fx.$3, lessThan(0));
    t.roles[att.id] = 'playmaker'; // مركز خاطئ: يُتجاهل
    expect(t.roleEffect([att]), (0.0, 0.0, 0.0));
    final back = Team.fromJson(t.toJson());
    expect(back.roles[mid.id], 'playmaker');
    final a = Side(createTeam(Random(5), 1, 'نادي', 4), true, false);
    final base = a.midPower;
    a.team.roles[a.slots.firstWhere((s) => s.pos == Pos.mid).p.id] = 'playmaker';
    expect(a.midPower, greaterThan(base));
  });
}
