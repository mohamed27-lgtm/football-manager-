import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/models.dart';

void main() {
  test('الفورمة: تتطلب 3 تقييمات، تحتفظ بآخر 5، وتؤثر على الأداء وتُحفظ', () {
    final p = createTeam(Random(4), 1, 'نادي', 4).squad.first;
    final base = p.effective;
    expect(p.formTrend, 0);
    p.addRating(8.5);
    p.addRating(8.0);
    expect(p.effective, base, reason: 'أقل من 3 تقييمات');
    p.addRating(8.2);
    expect(p.formTrend, 1);
    expect(p.effective, greaterThan(base));
    for (var i = 0; i < 6; i++) {
      p.addRating(5.4);
    }
    expect(p.recent.length, 5);
    expect(p.formTrend, -1);
    expect(p.effective, lessThan(base));
    final back = Player.fromJson(p.toJson());
    expect(back.recent, p.recent);
  });
}
