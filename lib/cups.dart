/// مباراة إقصائية واحدة (مع ركلات ترجيح عند التعادل)
class Tie {
  final int home, away;
  int? hg, ag, ph, pa;
  Tie(this.home, this.away);

  bool get played => hg != null;
  int get winner => hg! > ag! ? home : (hg! < ag! ? away : (ph! > pa! ? home : away));

  List<dynamic> toJson() => [home, away, hg, ag, ph, pa];
  factory Tie.fromJson(List<dynamic> j) => Tie(j[0] as int, j[1] as int)
    ..hg = j[2] as int?
    ..ag = j[3] as int?
    ..ph = j[4] as int?
    ..pa = j[5] as int?;

  String text(String Function(int) name) =>
      '${name(home)} $hg-$ag ${name(away)}${ph != null ? ' (ر.ج $ph-$pa)' : ''}';
}

/// بطولة بنظام خروج المغلوب (كأس محلي أو قاري)
class Cup {
  final String key, name;
  final bool continental;
  final List<int> schedule; // الأسبوع الذي يسبق مباراة الدوري ويُلعب فيه كل دور
  int size;
  int round = 0;
  List<int> alive;
  List<int> byes = [];
  List<Tie> ties = [];
  bool done = false;
  int? champion;
  final List<String> log = [];

  Cup({
    required this.key,
    required this.name,
    required this.continental,
    required this.schedule,
    required this.size,
    required this.alive,
  });

  String get roundName => switch (size) {
        2 => 'النهائي',
        4 => 'نصف النهائي',
        8 => 'ربع النهائي',
        _ => 'دور الـ$size',
      };

  int? get dueWeek => round < schedule.length ? schedule[round] : null;

  Tie? userTie(int uid) {
    for (final t in ties) {
      if (!t.played && (t.home == uid || t.away == uid)) return t;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'con': continental,
        'sched': schedule,
        'size': size,
        'round': round,
        'alive': alive,
        'byes': byes,
        'ties': [for (final t in ties) t.toJson()],
        'done': done,
        'champ': champion,
        'log': log,
      };

  factory Cup.fromJson(Map<String, dynamic> j) {
    final c = Cup(
      key: j['key'] as String,
      name: j['name'] as String,
      continental: j['con'] as bool,
      schedule: (j['sched'] as List).cast<int>(),
      size: j['size'] as int,
      alive: (j['alive'] as List).cast<int>(),
    )
      ..round = j['round'] as int
      ..byes = (j['byes'] as List).cast<int>()
      ..ties = [for (final t in j['ties'] as List) Tie.fromJson(t as List)]
      ..done = j['done'] as bool
      ..champion = j['champ'] as int?;
    c.log.addAll((j['log'] as List).cast<String>());
    return c;
  }
}

const foreignClubNames = <String>[
  'نورث يونايتد',
  'لا ريال سيرا',
  'سان مارتينو',
  'بوروسيا الشمال',
  'أولمبيك الريفييرا',
  'سبورتينغ الدانوب',
  'أتلتيكو الجنوب',
  'إنتر البلطيق',
  'دينامو البحر الأسود',
  'سلتيك المرتفعات',
  'أطلنطيكا لشبونة',
  'أياكس القنوات',
  'كاراكوم إسطنبول',
];
