import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/data.dart';

void main() {
  test('نقاط منحنى النمو: من سجل المواسم التي فيها تقييم ثم الحالي، حدّ 9 نقاط', () {
    final p = createTeam(Random(8), 1, 'نادي', 4).squad.first;
    p.career.clear();
    expect(p.growthPoints, [('الآن', p.overall)]);
    p.career.add({'s': 1, 't': 'x', 'a': 20, 'g': 1, 'as': 0, 'r': 6.5}); // قديم بلا 'o'
    expect(p.growthPoints.length, 1, reason: 'تجاهل السجلات القديمة');
    for (var s = 2; s <= 13; s++) {
      p.career.add({'s': s, 'o': 60 + s, 't': 'x', 'a': 20, 'g': 1, 'as': 0, 'r': 6.5});
    }
    final gp = p.growthPoints;
    expect(gp.length, 9);
    expect(gp.last, ('الآن', p.overall));
    expect(gp[gp.length - 2], ('م13', 73));
    expect(gp.first, ('م6', 66));
  });
}
