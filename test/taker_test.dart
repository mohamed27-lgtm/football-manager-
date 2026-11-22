import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/models.dart';

void main() {
  test('المنفّذ المحدد: يُختار إن كان على الملعب وإلا تلقائي، ويُحفظ مع الفريق', () {
    final t = createTeam(Random(3), 1, 'نادي', 4);
    t.autoPick();
    final out = t.lineup.where((p) => p.pos != Pos.gk).toList();
    expect(t.takerAmong(0, out), isNull);
    final pick = out.last;
    expect(t.takerAmong(pick.id, out), same(pick));
    expect(t.takerAmong(pick.id, out.where((p) => p != pick)), isNull);
    t
      ..penTaker = pick.id
      ..fkTaker = out.first.id
      ..cornerTaker = out[1].id;
    final back = Team.fromJson(t.toJson());
    expect([back.penTaker, back.fkTaker, back.cornerTaker], [pick.id, out.first.id, out[1].id]);
  });
}
