import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/engine.dart';
import 'package:football_manager/rivalries.dart';

void main() {
  test('الديربيات: مطابقة الأسماء بصرف النظر عن الترتيب والرموز', () {
    expect(derbyOf('Real Madrid', 'FC Barcelona').$2, 'الكلاسيكو');
    expect(derbyOf('FC Barcelona', 'Real Madrid').$1, 2);
    expect(derbyOf('AC Milan', 'Inter').$2, 'ديربي ميلانو');
    expect(derbyOf('Arsenal FC', 'Tottenham Hotspur').$1, 2);
    expect(derbyOf('Real Madrid', 'Sevilla').$1, 0);
    expect(derbyOf('Inter Miami', 'LA Galaxy').$1, 0, reason: 'inter miami ليس إنتر ميلان');
    expect(derbyOf('نادي 1', 'نادي 2').$1, 0);
    expect(derbyOf('X', 'X').$1, 0);
  });

  test('المحرك: الديربي يُفعَّل على المباراة ويسجّل خبر البداية', () {
    final r = Random(2);
    final a = createTeam(r, 1, 'Real Madrid', 4), b = createTeam(r, 2, 'Barcelona', 4);
    final s = MatchSim(a, b, random: Random(1))..simulateAll();
    expect(s.derby.$1, 2);
    expect(s.events.any((e) => e.text.contains('الكلاسيكو')), isTrue);
    final c = createTeam(r, 3, 'نادي ثالث', 4);
    expect(MatchSim(a, c, random: Random(1)).derby.$1, 0);
  });
}
