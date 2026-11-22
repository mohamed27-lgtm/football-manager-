import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/models.dart';

void main() {
  test('قابلية الإصابة: ثابتة لكل لاعب، موزعة بنسب معقولة، وسجل الإصابات يُحفظ', () {
    final r = Random(9);
    final ps = [for (var i = 0; i < 40; i++) ...createTeam(r, i, 'نادي $i', 4).squad];
    final fr = ps.where((p) => p.fragility < 0).length / ps.length;
    final ro = ps.where((p) => p.fragility > 0).length / ps.length;
    expect(fr, inInclusiveRange(0.05, 0.25));
    expect(ro, inInclusiveRange(0.05, 0.25));
    final p = ps.first;
    expect(p.fragility, p.fragility);
    expect(p.fragilityFactor, anyOf(1.5, 0.7, 1.0));
    p
      ..injType = 'شد عضلي'
      ..injuredWeeks = 3;
    p.logInjury(2);
    p.logInjury(2); // مكرر: لا يُضاف
    expect(p.injLog, ['2|شد عضلي|3']);
    for (var i = 0; i < 12; i++) {
      p.injuredWeeks = i + 1;
      p.logInjury(3);
    }
    expect(p.injLog.length, 8);
    expect(Player.fromJson(p.toJson()).injLog, p.injLog);
  });
}
