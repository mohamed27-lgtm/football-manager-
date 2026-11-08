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
  List<List<int>> groups = [];
  List<Tie> gdone = [];

  Cup({
    required this.key,
    required this.name,
    required this.continental,
    required this.schedule,
    required this.size,
    required this.alive,
  });

  bool get inGroups => groups.isNotEmpty && round < 3;

  String get roundName => inGroups ? 'دور المجموعات — الجولة ${round + 1}' : switch (size) {
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
        'groups': groups,
        'gdone': [for (final t in gdone) t.toJson()],
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
    c.groups = [for (final g in (j['groups'] as List?) ?? const []) (g as List).cast<int>()];
    c.gdone = [for (final t in (j['gdone'] as List?) ?? const []) Tie.fromJson(t as List)];
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

class GroupRow {
  final int id;
  int p = 0, w = 0, d = 0, l = 0, gf = 0, ga = 0;
  GroupRow(this.id);
  int get pts => w * 3 + d;
  int get gd => gf - ga;
}

/// ترتيب مجموعة من نتائج المباريات المنتهية
List<GroupRow> groupTable(Cup c, List<int> g) {
  final rows = {for (final id in g) id: GroupRow(id)};
  for (final t in c.gdone) {
    final h = rows[t.home], a = rows[t.away];
    if (h == null || a == null) continue;
    h.p++;
    a.p++;
    h.gf += t.hg!;
    h.ga += t.ag!;
    a.gf += t.ag!;
    a.ga += t.hg!;
    if (t.hg! > t.ag!) {
      h.w++;
      a.l++;
    } else if (t.hg! < t.ag!) {
      a.w++;
      h.l++;
    } else {
      h.d++;
      a.d++;
    }
  }
  return rows.values.toList()
    ..sort((x, y) {
      final k = y.pts.compareTo(x.pts);
      if (k != 0) return k;
      final k2 = y.gd.compareTo(x.gd);
      if (k2 != 0) return k2;
      return y.gf.compareTo(x.gf);
    });
}

/// ترتيب الدول حسب معامل الاتحاد الأوروبي (تقريبي) — يحدد مقاعد دوري الأبطال
const kContinentalOrder = <String>[
  'إنجلترا', 'إسبانيا', 'إيطاليا', 'ألمانيا', 'فرنسا', 'البرتغال', 'هولندا', 'بلجيكا', 'تركيا', 'إسكتلندا',
  'اليونان', 'النمسا', 'سويسرا', 'الدنمارك', 'النرويج', 'بولندا', 'التشيك', 'أوكرانيا', 'روسيا', 'صربيا', 'كرواتيا', 'السويد',
];

/// عدد مقاعد الدولة في دوري الأبطال (16 فريقاً): الأربع الكبرى 2، ثم الباقي 1
int continentalSlots(String country) {
  final i = kContinentalOrder.indexOf(country);
  if (i < 0) return 1; // دول خارج أوروبا/غير مصنّفة: البطل فقط
  return i < 4 ? 2 : 1;
}

/// مقاعد الدولة في الدوري الأوروبي (الأربع الكبرى 2، الباقي 1) ودوري المؤتمر (1)
int europaSlots(String country) {
  final i = kContinentalOrder.indexOf(country);
  if (i < 0) return 0;
  return i < 4 ? 2 : 1;
}

int conferenceSlots(String country) => kContinentalOrder.contains(country) ? 1 : 0;
