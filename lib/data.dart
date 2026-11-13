import 'dart:math';
import 'models.dart';
import 'names.dart';
import 'stadiums.dart';


int _pid = 0;
int get pidCounter => _pid;
set pidCounter(int v) => _pid = v;

Player makePlayer(Random rng, Pos pos, int ov, int age,
    {String? name, String? photo, String? nat, String? preferNat}) {
  final genNat = name == null ? (nat ?? pickNat(rng, prefer: preferNat)) : nat;
  int n(int v, [int spread = 3]) =>
      (v + rng.nextInt(spread * 2 + 1) - spread).clamp(20, 95).toInt();
  var atk = 10, def = 10, pas = 10, gk = 10;
  switch (pos) {
    case Pos.gk:
      gk = n(ov, 2);
      atk = n(25);
      def = n(30);
      pas = n(45);
    case Pos.def:
      def = n(ov + 4);
      pas = n(ov - 8);
      atk = n(ov - 15);
    case Pos.mid:
      pas = n(ov + 3);
      atk = n(ov - 3);
      def = n(ov - 3);
    case Pos.att:
      atk = n(ov + 4);
      pas = n(ov - 5);
      def = n(ov - 20);
  }
  final p = Player(
    id: ++_pid,
    name: name ?? nameFor(rng, genNat!),
    photo: photo,
    age: age,
    pos: pos,
    atk: atk,
    def: def,
    pas: pas,
    gk: gk,
    potential: 0,
    contract: 1 + rng.nextInt(4),
  );
  if (genNat != null) p.nat = genNat;
  final hb = switch (pos) { Pos.gk => 188, Pos.def => 183, Pos.mid => 177, Pos.att => 180 };
  p.height ??= hb + rng.nextInt(13) - 6;
  final pot = age < 24
      ? min(95, p.overall + 2 + rng.nextInt(12))
      : p.overall + rng.nextInt(3);
  p.potential = max(pot, p.overall);
  return p;
}

Team createTeam(Random rng, int id, String name, int rep) {
  final base = 55 + rep * 3;
  const plan = {Pos.gk: 3, Pos.def: 8, Pos.mid: 8, Pos.att: 5};
  const starters = {Pos.gk: 1, Pos.def: 4, Pos.mid: 4, Pos.att: 2};
  final squad = <Player>[];
  plan.forEach((pos, count) {
    for (var i = 0; i < count; i++) {
      final ov = base + rng.nextInt(11) - 5 + (i < starters[pos]! ? 3 : -2);
      squad.add(makePlayer(rng, pos, ov, 18 + rng.nextInt(17)));
    }
  });
  final t = Team(
      id: id, name: name, reputation: rep, squad: squad, budget: 12.0 + rep * 8);
  t.venue = stadiumFor(name);
  t.autoPick();
  return t;
}


List<Player> generateMarket(Random rng) {
  const counts = {Pos.gk: 3, Pos.def: 6, Pos.mid: 6, Pos.att: 5};
  final list = <Player>[];
  counts.forEach((pos, c) {
    for (var i = 0; i < c; i++) {
      list.add(makePlayer(rng, pos, 52 + rng.nextInt(24), 18 + rng.nextInt(16)));
    }
  });
  for (final p in list) {
    if (rng.nextDouble() < 0.22) p.free = true;
  }
  list.sort((a, b) => b.overall.compareTo(a.overall));
  return list;
}

/// لاعب أكاديمية: مستواه يتبع مستوى ناديه (الأندية القوية تُخرّج مواهب أفضل) كي لا ينهار مستوى الدوري مع الزمن
Player makeYouth(Random rng, Pos pos, {int level = 0, String? preferNat}) =>
    makePlayer(rng, pos, level > 0 ? level - 3 + rng.nextInt(8) : 50 + rng.nextInt(8), 17 + rng.nextInt(3), preferNat: preferNat);

/// يضمن الحد الأدنى من اللاعبين في كل مركز (يملأ النقص بلاعبين شباب)
void topUpSquad(Team t, Random rng) {
  const minimum = {Pos.gk: 2, Pos.def: 6, Pos.mid: 6, Pos.att: 3};
  final lvl = (t.strength - 8).round().clamp(48, 76);
  final home = dominantNat(t.squad.map((p) => p.nat));
  minimum.forEach((pos, n) {
    while (t.squad.where((p) => p.pos == pos).length < n) {
      t.squad.add(makeYouth(rng, pos, level: lvl, preferNat: home)..filler = true);
    }
  });
  while (t.squad.length < 20) {
    t.squad.add(makeYouth(rng, Pos.values[1 + rng.nextInt(3)], level: lvl, preferNat: home)..filler = true);
  }
}



/// «ولادة جديدة» بعد الاعتزال: يبقى الاسم والصورة والجنسية والمركز، وتعود القدرات والعمر إلى البداية
void rebirth(Random rng, Player p) {
  final high = p.overall;
  final t = makePlayer(rng, p.pos, 44 + rng.nextInt(10), 16 + rng.nextInt(2));
  p
    ..age = t.age
    ..atk = t.atk
    ..def = t.def
    ..pas = t.pas
    ..gk = t.gk
    ..potential = (high + rng.nextInt(9) - 6).clamp(64, 92)
    ..contract = 3
    ..sk = null
    ..mv0 = null
    ..ov0 = null
    ..age0 = null
    ..free = false
    ..listed = false
    ..onLoan = false
    ..injuredWeeks = 0
    ..suspendedMatches = 0
    ..salary = null
    ..career = []
    ..awards = []
    ..traits = [];
}
