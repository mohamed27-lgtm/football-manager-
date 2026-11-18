import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/api_football.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/importer.dart';
import 'package:football_manager/models.dart';

void main() {
  test('كل لاعب بلا بيانات Transfermarkt يحصل على جنسية وقدم ومركز دقيق ثابتة', () {
    const ap = ApiPlayer(id: 4242, name: 'Juan Perez', age: 26, position: 'Defender');
    final a = playerFromApi(ap, 70, country: 'إسبانيا');
    final b = playerFromApi(ap, 70, country: 'إسبانيا');
    expect(a.nat, 'إسبانيا');
    expect(a.foot, isNotNull);
    expect(a.sub, isNotNull);
    expect(a.foot, b.foot);
    expect(a.sub, b.sub);
    expect(subAr(a.sub), isNotEmpty);
  });

  test('اللاعبون المولَّدون يملكون قدماً ومركزاً دقيقاً', () {
    final r = Random(1);
    for (final pos in Pos.values) {
      final p = makePlayer(r, pos, 60, 24);
      expect(p.foot, isNotNull);
      expect(p.sub, isNotNull);
      expect(p.nat, isNotNull);
    }
  });
}
