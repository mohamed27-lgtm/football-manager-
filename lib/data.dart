import 'dart:math';
import 'models.dart';


const _first = [
  'كريم', 'يوسف', 'أمين', 'سمير', 'هشام', 'طارق', 'ياسين', 'عمر', 'زياد',
  'وليد', 'مهدي', 'رضا', 'بلال', 'أيوب', 'نبيل', 'فاروق', 'حمزة', 'إلياس',
  'سعيد', 'جلال', 'مراد', 'نزار', 'رياض', 'عادل', 'فيصل', 'هيثم', 'ماجد',
  'لؤي', 'شادي', 'أنس',
];
const _last = [
  'الحداد', 'المنصوري', 'الفاسي', 'بنعلي', 'الشرقاوي', 'العلوي', 'التازي',
  'القاسمي', 'الزعيم', 'البدوي', 'الصغير', 'الكبير', 'العمراني', 'السعدي',
  'الجزائري', 'التونسي', 'المصري', 'الحربي', 'الشامي', 'النجار', 'الخطيب',
  'الرفاعي', 'الهاشمي', 'الأنصاري', 'الحمداني', 'المرابط', 'الصالحي', 'الدرعي',
  'الغالي', 'السبتي',
];

int _pid = 0;
int get pidCounter => _pid;
set pidCounter(int v) => _pid = v;

String randomName(Random rng) =>
    '${_first[rng.nextInt(_first.length)]} ${_last[rng.nextInt(_last.length)]}';

Player makePlayer(Random rng, Pos pos, int ov, int age,
    {String? name, String? photo}) {
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
    name: name ?? randomName(rng),
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

Player makeYouth(Random rng, Pos pos) =>
    makePlayer(rng, pos, 50 + rng.nextInt(8), 17 + rng.nextInt(3));

/// يضمن الحد الأدنى من اللاعبين في كل مركز (يملأ النقص بلاعبين شباب)
void topUpSquad(Team t, Random rng) {
  const minimum = {Pos.gk: 2, Pos.def: 6, Pos.mid: 6, Pos.att: 3};
  minimum.forEach((pos, n) {
    while (t.squad.where((p) => p.pos == pos).length < n) {
      t.squad.add(makeYouth(rng, pos));
    }
  });
  while (t.squad.length < 20) {
    t.squad.add(makeYouth(rng, Pos.values[1 + rng.nextInt(3)]));
  }
}

