import 'dart:math';

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
  int kind = 0; // 0 إقصاء، 1 مجموعات، 2 مرحلة دوري (36 فريقاً)
  int lpRounds = 0; // عدد جولات المجموعات / مرحلة الدوري
  List<List<List<int>>> lpFx = []; // مرحلة الدوري: الجولة ← [مضيف، ضيف]
  bool seeded = false; // الملحق: الترتيب محفوظ (الثمانية الأوائل يتأهلون مباشرة)

  Cup({
    required this.key,
    required this.name,
    required this.continental,
    required this.schedule,
    required this.size,
    required this.alive,
  });

  bool get inGroups => groups.isNotEmpty && round < lpRounds;

  String get roundName => inGroups
      ? (kind == 2 ? 'مرحلة الدوري — المباراة ${round + 1}' : 'دور المجموعات — الجولة ${round + 1}')
      : switch (size) {
          2 => 'النهائي',
          4 => 'نصف النهائي',
          8 when key == 'ic' => 'الدور الأول',
          8 => 'ربع النهائي',
          32 when kind == 2 => 'الملحق',
          _ => 'دور الـ$size',
        };

  String roundNameAt(int r) {
    if (kind > 0 && r < lpRounds) return kind == 2 ? 'مرحلة الدوري — المباراة ${r + 1}' : 'دور المجموعات — الجولة ${r + 1}';
    final left = schedule.length - r;
    return switch (left) {
      1 => 'النهائي',
      2 => 'نصف النهائي',
      3 when key == 'ic' => 'الدور الأول',
      3 => 'ربع النهائي',
      4 => 'دور الـ16',
      5 when kind == 2 => 'الملحق',
      _ => 'الدور ${r + 1}',
    };
  }

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
        'kind': kind,
        'lpr': lpRounds,
        'lpfx': lpFx,
        'seed': seeded,
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
    c.kind = (j['kind'] as int?) ?? (c.groups.isNotEmpty ? 1 : 0);
    c.lpRounds = (j['lpr'] as int?) ?? (c.groups.isNotEmpty ? 3 : 0);
    c.lpFx = [
      for (final r in (j['lpfx'] as List?) ?? const [])
        [for (final p in r as List) (p as List).cast<int>()]
    ];
    c.seeded = (j['seed'] as bool?) ?? false;
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

/// ترتيب الدول حسب معامل الاتحاد الأوروبي (تقريبي) — يحدد مقاعد التأهل
const kContinentalOrder = <String>[
  'إنجلترا', 'إسبانيا', 'إيطاليا', 'ألمانيا', 'فرنسا', 'البرتغال', 'هولندا', 'بلجيكا', 'تركيا', 'إسكتلندا',
  'اليونان', 'النمسا', 'سويسرا', 'الدنمارك', 'النرويج', 'بولندا', 'التشيك', 'أوكرانيا', 'روسيا', 'صربيا', 'كرواتيا', 'السويد',
];

/// اتحاد قاري: أسماء بطولاته وترتيب دوله (لمقاعد التأهل)
class Confed {
  final String id, cl, second;
  final List<String> order;
  const Confed(this.id, this.cl, this.second, this.order);
  bool get swiss => id == 'uefa';
}

const kConfeds = <Confed>[
  Confed('caf', 'دوري أبطال أفريقيا', 'كأس الكونفدرالية الأفريقية',
      ['المغرب', 'مصر', 'الجزائر', 'تونس', 'جنوب أفريقيا', 'نيجيريا', 'السنغال', 'غانا', 'الكاميرون', 'ساحل العاج', 'ليبيا', 'السودان', 'مالي', 'الكونغو الديمقراطية', 'أنغولا', 'تنزانيا', 'زامبيا', 'كينيا', 'أوغندا']),
  Confed('afc', 'دوري أبطال آسيا للنخبة', 'دوري أبطال آسيا 2', ['السعودية', 'اليابان', 'كوريا الجنوبية', 'الإمارات', 'قطر', 'الصين']),
  Confed('conmebol', 'كوبا ليبرتادوريس', 'كوبا سودأمريكانا', ['البرازيل', 'الأرجنتين']),
  Confed('concacaf', 'دوري أبطال كونكاكاف', 'كأس كونكاكاف', ['المكسيك', 'أمريكا']),
];

const kUefa = Confed('uefa', 'دوري أبطال أوروبا', 'الدوري الأوروبي', kContinentalOrder);

Confed confedOf(String country) {
  for (final c in kConfeds) {
    if (c.order.contains(country)) return c;
  }
  return kUefa;
}

bool isCaf(String country) => confedOf(country).id == 'caf';

/// مقاعد الدولة (أبطال، أوروبي/ثاني، مؤتمر/ثالث) حسب مراكز الدوري — توزيع موسم 2025/26
/// بطل الكأس المحلي يأخذ مقعد الدوري الأوروبي إن لم يكن مؤهلاً للأبطال.
(int, int, int) slotsFor(String country) {
  final cf = confedOf(country);
  final i = cf.order.indexOf(country);
  if (cf.id == 'uefa') {
    if (i < 0) return (1, 0, 0);
    if (i < 4) return (4, 1, 1);
    if (i == 4) return (3, 1, 1);
    if (i < 7) return (2, 1, 1);
    return (1, 1, 1);
  }
  // غير أوروبا: أبطال + كأس ثانية (بلا ثلاثية)
  return i < 2 ? (2, 2, 0) : (1, 1, 0);
}

int continentalSlots(String country) => slotsFor(country).$1;
int europaSlots(String country) => confedOf(country).swiss ? slotsFor(country).$2 : 0;
int conferenceSlots(String country) {
  final s = slotsFor(country);
  return confedOf(country).swiss ? s.$3 : s.$2;
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// قرعة مرحلة الدوري: كل فريق يلعب [matches] مباراة (نصفها على أرضه) أمام فرق مختلفة،
/// وكل جولة يلعب فيها كل الفرق (مضيف/ضيف متوازن).
List<List<List<int>>> swissFixtures(List<int> ids, int matches, Random rng) {
  final n = ids.length;
  // حلقة بتوزيع الأوعية بالتناوب حتى يلاقي كل فريق مستويات مختلفة
  final pots = [for (var k = 0; k < 4; k++) <int>[]];
  for (var i = 0; i < n; i++) {
    pots[i * 4 ~/ n].add(ids[i]);
  }
  for (final p in pots) {
    p.shuffle(rng);
  }
  final ring = <int>[];
  for (var i = 0; ring.length < n; i++) {
    for (final p in pots) {
      if (i < p.length) ring.add(p[i]);
    }
  }
  final offsets = <int>[];
  for (var d = 1; d < n ~/ 2 && offsets.length < matches ~/ 2; d++) {
    if ((n ~/ _gcd(n, d)).isEven) offsets.add(d);
  }
  final out = <List<List<int>>>[];
  for (final d in offsets) {
    final g = _gcd(n, d);
    final a = <List<int>>[], b = <List<int>>[];
    for (var s = 0; s < g; s++) {
      final cyc = <int>[];
      var x = s;
      do {
        cyc.add(x);
        x = (x + d) % n;
      } while (x != s);
      for (var k = 0; k < cyc.length; k++) {
        final e = [ring[cyc[k]], ring[cyc[(k + 1) % cyc.length]]];
        (k.isEven ? a : b).add(e);
      }
    }
    out..add(a)..add(b);
  }
  out.shuffle(rng);
  return out;
}
