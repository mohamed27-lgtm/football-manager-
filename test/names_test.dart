import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/names.dart';
import 'package:football_manager/models.dart';

void main() {
  test('generated players get a nationality and a matching Latin name', () {
    final rng = Random(7);
    for (final e in kNames.entries) {
      expect(e.value.$1.length, greaterThanOrEqualTo(15), reason: e.key);
      expect(e.value.$2.length, greaterThanOrEqualTo(15), reason: e.key);
    }
    final nats = <String>{};
    for (var i = 0; i < 600; i++) {
      final p = makePlayer(rng, Pos.mid, 60, 20, preferNat: 'المغرب');
      expect(p.nat, isNotNull);
      expect(kNames.containsKey(p.nat), isTrue);
      expect(RegExp(r'[؀-ۿ]').hasMatch(p.name), isFalse, reason: p.name);
      nats.add(p.nat!);
    }
    expect(nats.length, greaterThan(10));
    var home = 0;
    for (var i = 0; i < 600; i++) {
      if (makePlayer(rng, Pos.def, 60, 20, preferNat: 'اليابان').nat == 'اليابان') home++;
    }
    expect(home, greaterThan(360));
  });
}
