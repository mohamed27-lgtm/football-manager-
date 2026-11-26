import 'dart:math';
import 'coaches.dart';
import 'nations.dart';

enum Pos { gk, def, mid, att }

extension PosX on Pos {
  String get label => switch (this) {
        Pos.gk => 'حارس',
        Pos.def => 'مدافع',
        Pos.mid => 'وسط',
        Pos.att => 'مهاجم',
      };
  String get short => switch (this) {
        Pos.gk => 'GK',
        Pos.def => 'DF',
        Pos.mid => 'MF',
        Pos.att => 'FW',
      };
  String get plural => switch (this) {
        Pos.gk => 'الحراس',
        Pos.def => 'المدافعون',
        Pos.mid => 'لاعبو الوسط',
        Pos.att => 'المهاجمون',
      };
}

class Player {
  final int id;
  final String name;
  int age;
  final Pos pos;
  int atk, def, pas, gk, potential;
  int contract; // سنوات متبقية
  String? photo;
  String? nat, sub, foot; // الجنسية، المركز الدقيق، القدم
  String? nat2; // جنسية ثانية (للاعبين المُنشأين)
  String? swNat; // المنتخب الذي اختار تمثيله بعد الإقناع (بدل جنسيته الأساسية)
  int swTry = 0, swWeek = -99; // محاولات الإقناع وأسبوع آخر محاولة
  String? get natRep => swNat ?? nat; // المنتخب الذي يمثّله فعلياً
  List<int>? sk; // المهارات الست للاعب المُنشأ: سرعة، تسديد، تمرير، مراوغة، دفاع، قوة
  List<String> traits = [];
  String? club; // ناديه الحالي (لاعبو السوق الحقيقيون)
  int? height;
  double? mv0; // القيمة السوقية الحقيقية عند الاستيراد (M€)
  int? ov0, age0; // التقييم والعمر عند الاستيراد
  /// لقطة بداية الموسم/وقت الانضمام لعرض التطور (قوة وقيمة)
  int? sOv;
  double? sVal;
  int get ovDelta => overall - (sOv ?? overall);
  double get valDelta => value - (sVal ?? value);
  int get ovSinceStart => ov0 == null ? 0 : overall - ov0!;
  double get valSinceStart => mv0 == null ? 0 : value - mv0!;
  bool free = false, onLoan = false, listed = false, registered = true;
  String? focus; // تدريب فردي: 'atk' | 'pas' | 'def' | 'gk'
  int promise = 0, promBase = 0, promStarts = 0; // وعد المشاركة: 0 لا وعد، ثم أساس عدد مباريات الفريق وعدد مرات الأساسية منذ الوعد
  double awardBoost = 0; // هالة الجوائز: نسبة (0.16 = +16%) تتلاشى مع الوقت
  bool filler = false; // لاعب حشو مولَّد لملء التشكيلة (لا يظهر في السوق)
  double? salary;
  double fitness = 100;
  double morale = 70;
  int injuredWeeks = 0;
  String? injType; // نوع آخر إصابة (للعرض)
  String? loanClub; // ناديه المُعار إليه
  int loanRole = 1, loanApps = 0, loanMins = 0, loanGoals = 0; // 0 بديل، 1 مشارك، 2 أساسي
  int adapt = 0; // أسابيع التأقلم مع بلد/دوري جديد
  double load = 0; // إرهاق تراكمي 0..100 (دقائق اللعب المتواصلة)
  int suspendedMatches = 0;
  int goals = 0, assists = 0, apps = 0, yellows = 0;
  double ratingSum = 0;
  List<double> recent = []; // تقييمات آخر 5 مباريات (الفورمة)
  int rated = 0;
  int injuryCount = 0;
  List<String> injLog = []; // سجل الإصابات: 'الموسم|النوع|الأسابيع' (آخر 8)

  /// نقاط منحنى النمو: (تسمية الموسم، التقييم) من سجل المسيرة، ثم التقييم الحالي
  List<(String, int)> get growthPoints {
    final out = <(String, int)>[];
    for (final c in career) {
      final o = c['o'];
      if (o is num) out.add(('م${c['s']}', o.toInt()));
    }
    out.add(('الآن', overall));
    return out.length > 9 ? out.sublist(out.length - 9) : out;
  }

  /// قابلية الإصابة (ثابتة من هوية اللاعب): -1 هشّ بدنياً، 0 عادي، 1 متين
  int get fragility {
    final h = ((id * 40503) >> 4) % 100;
    return h < 14 ? -1 : (h >= 86 ? 1 : 0);
  }

  String get fragilityLabel => fragility < 0 ? 'هشّ بدنياً' : (fragility > 0 ? 'متين بدنياً' : 'عادي');

  /// معامل خطر الإصابة الناتج عن البنية
  double get fragilityFactor => fragility < 0 ? 1.5 : (fragility > 0 ? 0.7 : 1.0);

  void logInjury(int season) {
    final e = '$season|${injType ?? 'إصابة'}|$injuredWeeks';
    if (injLog.isNotEmpty && injLog.last == e) return;
    injLog.add(e);
    if (injLog.length > 8) injLog.removeAt(0);
  }
  double? optionFee; // إعارة بخيار/إلزامية شراء
  bool obligation = false;
  List<Map<String, dynamic>> career = [];
  /// الجوائز: {s: الموسم, c: اسم البطولة/الجائزة, k: league|cup|indiv}
  List<Map<String, dynamic>> awards = [];
  double get avgRating => rated == 0 ? 0 : ratingSum / rated;

  Player({
    required this.id,
    required this.name,
    required this.age,
    required this.pos,
    required this.atk,
    required this.def,
    required this.pas,
    required this.gk,
    required this.potential,
    this.contract = 2,
    this.photo,
  });

  int get overall => switch (pos) {
        Pos.gk => gk,
        Pos.def => (def * 0.65 + pas * 0.2 + atk * 0.15).round(),
        Pos.mid => (pas * 0.45 + atk * 0.25 + def * 0.3).round(),
        Pos.att => (atk * 0.7 + pas * 0.2 + def * 0.1).round(),
      };

  /// الفورمة: متوسط آخر التقييمات (يلزم 3 على الأقل)، 0 إن لم تكفِ
  double get formAvg => recent.length < 3 ? 0 : recent.fold(0.0, (a, b) => a + b) / recent.length;

  /// اتجاه الفورمة: 1 جيدة، -1 سيئة، 0 عادية
  int get formTrend => recent.length < 3 ? 0 : (formAvg >= 7.2 ? 1 : (formAvg <= 6.3 ? -1 : 0));

  /// معامل الفورمة على الأداء: من نحو 0.977 إلى 1.03
  double get formFactor => recent.length < 3 ? 1.0 : 1 + (formAvg - 6.7).clamp(-1.0, 1.2).toDouble() * 0.025;

  void addRating(double r) {
    recent.add(r);
    if (recent.length > 5) recent.removeAt(0);
  }

  double get effective =>
      formFactor *
      overall * (0.55 + 0.45 * fitness / 100) * (0.92 + 0.16 * morale / 100) * (adapt > 0 ? 1 - 0.05 * min(adapt, 6) / 6 : 1.0);

  /// شخصية اللاعب (ثابتة من هويته): تؤثر في تطوره وانضباطه وطموحه
  String? traitOverride; // يُضبط عند تغيّر طبع اللاعب (كتأثر بمرشد)
  String get trait {
    if (traitOverride != null) return traitOverride!;
    final h = ((id * 2654435761) >> 9) % 100;
    if (h < 26) return 'محترف';
    if (h < 44) return 'متقلب';
    if (h < 56 && age >= 26) return 'قائد';
    if (h < 76) return 'طموح';
    return 'عادي';
  }

  bool get available => injuredWeeks == 0 && suspendedMatches == 0 && registered;

  /// منحنى العمر: الشباب أغلى (إعادة بيع)، ثم تهبط القيمة تدريجياً بعد الذروة
  static double _ageF(int a) {
    const t = {19: 1.35, 20: 1.3, 21: 1.25, 22: 1.18, 23: 1.12, 24: 1.08, 25: 1.02, 26: 1.0, 27: 1.0, 28: 0.93, 29: 0.85, 30: 0.76, 31: 0.66, 32: 0.55, 33: 0.45, 34: 0.36};
    return a <= 19 ? 1.35 : (a >= 35 ? 0.26 : t[a]!);
  }

  /// سقف القيمة السوقية حسب المركز (M): الهجوم الأعلى سوقياً، والحراس والمدافعون أقل
  double get valueCap => switch (pos) { Pos.att => 250.0, Pos.mid => 200.0, Pos.def => 150.0, Pos.gk => 90.0 };

  /// حساسية القيمة لتقييم اللاعب: تقييم المهاجم يرفع قيمته أسرع من المدافع/الحارس
  double get _ovSlope => switch (pos) { Pos.att => 8.6, Pos.mid => 9.3, Pos.def => 10.2, Pos.gk => 11.5 };

  /// عوامل حالية: الأداء الأخير والإصابة الطويلة
  double get _situationF {
    var f = 1.0;
    if (recent.length >= 3) f *= (1 + ((formAvg - 6.5) * 0.04)).clamp(0.94, 1.07).toDouble();
    if (injuredWeeks >= 8) f *= 0.9;
    return f;
  }

  /// القيمة المعلنة (مثل Transfermarkt): لا تتحرك أسبوعياً، بل تُحدَّث في نوافذ محددة من الموسم
  double? pub;

  double get _core {
    double v;
    if (mv0 != null && ov0 != null) {
      v = mv0! * pow(10, (overall - ov0!) / _ovSlope) * _ageF(age) / _ageF(age0 ?? age);
    } else {
      var m = 1.0;
      if (age <= 23) m += max(0, potential - overall) / 25;
      if (age >= 31) m *= 0.6;
      v = pow(overall / 50, 6).toDouble() * m;
    }
    return v * (1 + awardBoost) * _situationF;
  }

  double _fin(double v) => max(0.1, (min(v, valueCap) * 10).round() / 10);

  /// القيمة الحقيقية الآن (تتأثر بالعقد وبكل العوامل فوراً)
  double get liveValue => _fin(_core * _contractF);

  /// ما سيُعلن عند التحديث القادم (دون أثر العقد لأنه يدخل في سعر الصفقة)
  double get pendingValue => _fin(_core);

  /// القيمة السوقية المعلنة: المنشورة آخر مرة، أو الحية إن لم تُنشر بعد
  double get value => pub ?? liveValue;

  void publishValue() => pub = pendingValue;

  /// عقد قصير يخفّض القيمة (قرب الرحيل المجاني)، وعقد طويل يرفعها قليلاً
  double get _contractF => contract <= 0 ? 0.5 : contract == 1 ? 0.82 : contract == 2 ? 0.95 : contract >= 4 ? 1.05 : 1.0;

  /// الراتب الأسبوعي (M): مشتق من القيمة السوقية الحقيقية حين تتوفر (لا توجد رواتب حقيقية في المصادر المجانية)
  double get baseWage {
    if (mv0 != null) {
      final w = 0.012 + 0.0042 * pow(max(value, 0.1), 0.85);
      return ((w * 1000).round() / 1000).clamp(0.01, 0.6).toDouble();
    }
    return (overall - 40).clamp(1, 60) * 0.0015;
  }
  double get wage => salary ?? baseWage;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'pos': pos.index,
        'atk': atk,
        'def': def,
        'pas': pas,
        'gk': gk,
        'pot': potential,
        'con': contract,
        'fit': fitness,
        'mor': morale,
        'inj': injuredWeeks,
        'it': injType,
        'ad': adapt,
        'lc': loanClub,
        'lr': loanRole,
        'la': loanApps,
        'lm': loanMins,
        'lg': loanGoals,
        'ld': double.parse(load.toStringAsFixed(1)),
        'sus': suspendedMatches,
        'goals': goals,
        'ast': assists,
        'apps': apps,
        'yel': yellows,
        'photo': photo,
        'free': free,
        'fil': filler,
        'ap': awardBoost,
        'loan': onLoan,
        'listed': listed,
        if (promise != 0) 'pm': [promise, promBase, promStarts],
        if (focus != null) 'fc': focus,
        if (traitOverride != null) 'tro': traitOverride,
        'reg': registered,
        'sal': salary,
        'rs': ratingSum,
        if (recent.isNotEmpty) 'fm': recent,
        'rn': rated,
        'ic': injuryCount,
        if (injLog.isNotEmpty) 'il': injLog,
        'opt': optionFee,
        'obl': obligation,
        'career': career,
        'aw': awards,
        'nat2': nat2, 'sw': swNat, 'swt': swTry, 'sww': swWeek, 'sk': sk, 'tr': traits,
        'club': club, 'nat': nat, 'sub': sub, 'ft': foot, 'ht': height, 'mv0': mv0, 'ov0': ov0, 'age0': age0, if (pub != null) 'pub': pub, if (sOv != null) 'sov': sOv, if (sVal != null) 'sval': sVal,
      };

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        id: j['id'] as int,
        name: j['name'] as String,
        age: j['age'] as int,
        pos: Pos.values[j['pos'] as int],
        atk: j['atk'] as int,
        def: j['def'] as int,
        pas: j['pas'] as int,
        gk: j['gk'] as int,
        potential: j['pot'] as int,
        contract: j['con'] as int,
      )
        ..fitness = (j['fit'] as num).toDouble()
        ..morale = (j['mor'] as num).toDouble()
        ..injuredWeeks = j['inj'] as int
        ..injType = j['it'] as String?
        ..adapt = (j['ad'] as int?) ?? 0
        ..loanClub = j['lc'] as String?
        ..loanRole = (j['lr'] as int?) ?? 1
        ..loanApps = (j['la'] as int?) ?? 0
        ..loanMins = (j['lm'] as int?) ?? 0
        ..loanGoals = (j['lg'] as int?) ?? 0
        ..load = ((j['ld'] as num?) ?? 0).toDouble()
        ..suspendedMatches = j['sus'] as int
        ..goals = j['goals'] as int
        ..assists = j['ast'] as int
        ..apps = j['apps'] as int
        ..yellows = j['yel'] as int
        ..photo = j['photo'] as String?
        ..free = (j['free'] as bool?) ?? false
        ..filler = (j['fil'] as bool?) ?? false
        ..awardBoost = (j['ap'] as num?)?.toDouble() ?? 0
        ..onLoan = (j['loan'] as bool?) ?? false
        ..listed = (j['listed'] as bool?) ?? false
        ..traitOverride = ['محترف', 'متقلب', 'قائد', 'طموح', 'عادي'].contains(j['tro']) ? j['tro'] as String : null
        ..focus = ['atk', 'pas', 'def', 'gk'].contains(j['fc']) ? j['fc'] as String : null
        ..promise = ((j['pm'] as List?)?[0] as int?) ?? 0
        ..promBase = ((j['pm'] as List?)?[1] as int?) ?? 0
        ..promStarts = ((j['pm'] as List?)?[2] as int?) ?? 0
        ..registered = (j['reg'] as bool?) ?? true
        ..salary = (j['sal'] as num?)?.toDouble()
        ..ratingSum = (j['rs'] as num?)?.toDouble() ?? 0
        ..recent = [for (final v in (j['fm'] as List?) ?? const []) (v as num).toDouble()]
        ..rated = (j['rn'] as int?) ?? 0
        ..injuryCount = (j['ic'] as int?) ?? 0
        ..injLog = [for (final v in (j['il'] as List?) ?? const []) '$v']
        ..optionFee = (j['opt'] as num?)?.toDouble()
        ..obligation = (j['obl'] as bool?) ?? false
        ..club = j['club'] as String?
        ..nat = natArabic(j['nat'] as String?)
        ..nat2 = natArabic(j['nat2'] as String?)
        ..swNat = natArabic(j['sw'] as String?)
        ..swTry = (j['swt'] as int?) ?? 0
        ..swWeek = (j['sww'] as int?) ?? -99
        ..sk = (j['sk'] as List?)?.cast<int>()
        ..traits = [for (final t in (j['tr'] as List?) ?? const []) t as String]
        ..sub = j['sub'] as String?
        ..foot = j['ft'] as String?
        ..height = (j['ht'] as num?)?.toInt()
        ..mv0 = (j['mv0'] as num?)?.toDouble()
        ..ov0 = (j['ov0'] as num?)?.toInt()
        ..age0 = (j['age0'] as num?)?.toInt()
        ..pub = (j['pub'] as num?)?.toDouble()
        ..sOv = (j['sov'] as num?)?.toInt()
        ..sVal = (j['sval'] as num?)?.toDouble()
        ..career = [
          for (final c in (j['career'] as List?) ?? const [])
            Map<String, dynamic>.from(c as Map)
        ]
        ..awards = [
          for (final c in (j['aw'] as List?) ?? const [])
            Map<String, dynamic>.from(c as Map)
        ];
}

class Formation {
  final String name;
  final int d, m, a;
  const Formation(this.name, this.d, this.m, this.a);
}

const formations = <Formation>[
  Formation('4-4-2', 4, 4, 2),
  Formation('4-3-3', 4, 3, 3),
  Formation('3-5-2', 3, 5, 2),
  Formation('5-3-2', 5, 3, 2),
  Formation('4-5-1', 4, 5, 1),
  Formation('4-2-3-1', 4, 5, 1),
];

/// أدوار اللاعبين: (الاسم، المركز، تأثير الهجوم، الوسط، الدفاع) — نسب صغيرة تُجمع على مستوى الفريق
/// تعليمات اللاعب الفردية (تؤثر في توزيع التسديد وفي مراقبة نجم الخصم)
const kInstr = <String, (String, String)>{
  'push': ('يتقدم للأمام', 'يشارك أكثر في إنهاء الهجمات'),
  'stay': ('يبقى في الخلف', 'يشارك أقل في التسديد ويحمي الدفاع'),
  'long': ('تسديد من بعيد', 'يكثر من التسديد، لكن أغلبها أقل دقة'),
  'mark': ('رقابة لصيقة', 'يلاحق نجم الخصم الهجومي ويقلل خطورته'),
};

const kRoles = <String, (String, Pos, double, double, double)>{
  'playmaker': ('صانع ألعاب متأخر', Pos.mid, 0.006, 0.02, -0.006),
  'box2box': ('وسط شامل', Pos.mid, 0.004, 0.01, 0.004),
  'ballwinner': ('قاطع كرات', Pos.mid, -0.008, 0.0, 0.016),
  'attfb': ('ظهير/مدافع مهاجم', Pos.def, 0.012, 0.004, -0.014),
  'stopper': ('مدافع مقاتل', Pos.def, -0.006, 0.0, 0.01),
  'falsenine': ('مهاجم وهمي', Pos.att, -0.004, 0.018, -0.002),
  'poacher': ('هدّاف منطقة', Pos.att, 0.014, -0.012, 0.0),
  'targetman': ('رأس حربة ثابت', Pos.att, 0.008, 0.004, -0.002),
};

class Team {
  int id;
  final String name;
  final int reputation;
  List<Player> squad;
  Formation formation = formations[0];
  int mentality = 2; // 0 دفاعية، 1 حذرة، 2 متوازنة، 3 هجومية، 4 شاملة
  int pressing = 1;
  int tempo = 1;
  int width = 1; // 0 ضيق، 1 متوازن، 2 عريض
  int defLine = 1; // 0 منخفض، 1 متوسط، 2 مرتفع
  int passing = 1; // 0 قصير، 1 مختلط، 2 مباشر
  final Map<int, String> roles = {}; // معرّف اللاعب → دور (فارغ = الدور العادي)
  /// تعليمات فردية داخل المباراة: معرّف اللاعب → رمز (انظر kInstr)
  final Map<int, String> instr = {};

  /// مجموع تأثير أدوار اللاعبين الموجودين فعلاً على الملعب: (هجوم، وسط، دفاع)
  (double, double, double) roleEffect(Iterable<Player> onPitch) {
    var a = 0.0, m = 0.0, d = 0.0;
    for (final p in onPitch) {
      final r = kRoles[roles[p.id]];
      if (r == null || r.$2 != p.pos) continue;
      a += r.$3;
      m += r.$4;
      d += r.$5;
    }
    return (a, m, d);
  }

  /// الألفة التكتيكية (0-100): تتراكم باستقرار الخطة والتشكيلة وتنخفض عند التغيير. الافتراضي 70 = محايدة
  double pitch = 90; // حالة عشب الملعب (للمستخدم): 100 ممتاز، تتدهور بالمباريات والمطر
  final Map<String, int> perks = {}; // مزايا رخصة المدرب (للمستخدم): المعرّف → الرتبة 1-3
  int perk(String k) => perks[k] ?? 0;
  final Map<int, int> mentors = {}; // معرّف الشاب → معرّف مرشده
  double familiarity = 70;
  Set<int> lastXI = {}; // تشكيلة آخر مباراة للمقارنة

  /// أثر الألفة على قوى الفريق: من نحو 0.965 (ألفة 20) إلى 1.021 (ألفة 100)
  double get familiarityFactor => 1 + (familiarity - 70) * 0.0007;

  /// يُستدعى عند بدء كل مباراة للفريق: يقارن التشكيلة بالسابقة ثم يرفع الألفة
  void onMatchStart(Iterable<Player> xi) {
    final ids = {for (final p in xi) p.id};
    if (lastXI.isNotEmpty) {
      final changed = ids.difference(lastXI).length;
      familiarity = (familiarity - 2.0 * changed + (changed == 0 ? 3 : 1) + (changed == 0 ? perk('tact') : 0)).clamp(20.0, 100.0).toDouble();
    }
    lastXI = ids;
  }

  /// تغيير التشكيل الأساسي يضرب الألفة بقوة
  void shakeFamiliarity(double d) => familiarity = (familiarity - d).clamp(20.0, 100.0).toDouble();

  int penTaker = 0, fkTaker = 0, cornerTaker = 0; // معرّف المنفّذ المحدّد (0 = تلقائي)

  /// المنفّذ المحدّد إن كان على أرض الملعب وإلا null
  Player? takerAmong(int id, Iterable<Player> onPitch) {
    if (id == 0) return null;
    for (final p in onPitch) {
      if (p.id == id) return p;
    }
    return null;
  }
  int analystLvl = 0; // يُضبط قبل كل مباراة من الطاقم
  double cohesion = 65; // الانسجام 30-100
  List<Player> lineup = [];
  double budget;
  int played = 0, won = 0, drawn = 0, lost = 0, gf = 0, ga = 0;
  int stadium = 1, trainingLvl = 1, academy = 1, medical = 1, fanZone = 1;
  String? badge, venue;
  /// وقت جلب بيانات الدوري الذي جاء منه الفريق (لتفضيل الأحدث عند تكرار اللاعب)
  int dataAt = 0;
  String? coach; // اسم المدرب إن عُيّن؛ وإلا coachFor(name)
  String get coachName {
    final c = coach ?? coachFor(name);
    return c.isEmpty ? 'غير متوفر' : c;
  }

  bool get hasCoachName => coach != null || coachFor(name).isNotEmpty;

  Team({
    required this.id,
    required this.name,
    required this.reputation,
    required this.squad,
    required this.budget,
  });

  int penalty = 0;
  List<String> form = []; // آخر النتائج: W/D/L
  void addForm(String r) {
    form.add(r);
    if (form.length > 6) form.removeAt(0);
  }

  int get points => won * 3 + drawn - penalty;
  int get gd => gf - ga;

  List<Pos> get slots => [
        Pos.gk,
        ...List.filled(formation.d, Pos.def),
        ...List.filled(formation.m, Pos.mid),
        ...List.filled(formation.a, Pos.att),
      ];

  double get strength {
    final l = squad.map((p) => p.overall).toList()
      ..sort((a, b) => b.compareTo(a));
    final top = l.take(11);
    return top.fold(0, (a, b) => a + b) / max(1, top.length);
  }

  List<Player> get bench => squad
      .where((p) => p.available && !lineup.contains(p))
      .toList()
    ..sort((a, b) => b.effective.compareTo(a.effective));

  /// درجة الاختيار: مع التدوير يُخصم الإرهاق التراكمي فيُريح المدرب النجم المنهك
  double _score(Player p, bool rotate) => !rotate || p.load <= 40 ? p.effective : p.effective * (1 - (p.load - 40) / 300);

  Player _choose(Pos slot, Set<Player> used, {bool rotate = false}) {
    List<Player> pool(bool strict) => squad
        .where((p) =>
            !used.contains(p) &&
            p.available &&
            (strict
                ? p.pos == slot
                : (slot == Pos.gk ? true : p.pos != Pos.gk)))
        .toList()
      ..sort((a, b) => _score(b, rotate).compareTo(_score(a, rotate)));
    var c = pool(true);
    if (c.isEmpty) c = pool(false);
    if (c.isEmpty) {
      c = squad.where((p) => !used.contains(p)).toList()
        ..sort((a, b) => _score(b, rotate).compareTo(_score(a, rotate)));
    }
    return c.first;
  }

  /// هوية تكتيكية ثابتة لأندية الذكاء الاصطناعي (تتحدد من اسم النادي وقوته)
  void applyAiStyle() {
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    var k = h % 6;
    if (reputation <= 2 && k == 1) k = 2; // الأضعف لا يلعب هجومياً مفتوحاً
    switch (k) {
      case 1: // هجومي
        formation = formations[1];
        mentality = 3; tempo = 2; width = 2; defLine = 2; pressing = 2; passing = 1;
      case 2: // دفاع ومرتدات
        formation = formations[3];
        mentality = 1; tempo = 2; width = 1; defLine = 0; pressing = 0; passing = 2;
      case 3: // استحواذ
        formation = formations[1];
        mentality = 2; tempo = 0; width = 1; defLine = 1; pressing = 2; passing = 0;
      case 4: // ضغط عالٍ
        formation = formations[5];
        mentality = 3; tempo = 2; width = 1; defLine = 2; pressing = 2; passing = 1;
      case 5: // لعب على الأطراف
        formation = formations[0];
        mentality = 2; tempo = 1; width = 2; defLine = 1; pressing = 1; passing = 1;
      default: // متوازن
        formation = formations[h % 2 == 0 ? 0 : 5];
        mentality = 2; tempo = 1; width = 1; defLine = 1; pressing = 1; passing = 1;
    }
  }

  void autoPick({bool rotate = false}) {
    final used = <Player>{};
    final res = <Player>[];
    for (final s in slots) {
      final p = _choose(s, used, rotate: rotate);
      used.add(p);
      res.add(p);
    }
    lineup = res;
  }

  void repairLineup() {
    final s = slots;
    if (lineup.length != 11) {
      autoPick();
      return;
    }
    final used = <Player>{};
    final bad = <int>[];
    for (var i = 0; i < 11; i++) {
      final p = lineup[i];
      if (squad.contains(p) && p.available && !used.contains(p)) {
        used.add(p);
      } else {
        bad.add(i);
      }
    }
    for (final i in bad) {
      final p = _choose(s[i], used);
      used.add(p);
      lineup[i] = p;
    }
  }

  void setFormation(Formation f) {
    formation = f;
    autoPick();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rep': reputation,
        'squad': [for (final p in squad) p.toJson()],
        'formation': formations.indexOf(formation),
        'ment': mentality,
        'm5': true,
        'press': pressing,
        'tempo': tempo,
        'wid': width,
        'dl': defLine,
        'pass': passing,
        'tk': [penTaker, fkTaker, cornerTaker],
        if (familiarity != 70) 'fam': familiarity,
        if (perks.isNotEmpty) 'pk': perks,
        if (pitch != 90) 'pit': pitch,
        if (mentors.isNotEmpty) 'mn': {for (final e in mentors.entries) '${e.key}': e.value},
        if (lastXI.isNotEmpty) 'lxi': lastXI.toList(),
        if (instr.isNotEmpty) 'ins': {for (final e in instr.entries) '${e.key}': e.value},
        if (roles.isNotEmpty) 'roles': {for (final e in roles.entries) '${e.key}': e.value},
        'coh': cohesion,
        'lineup': [for (final p in lineup) p.id],
        'budget': budget,
        'played': played,
        'won': won,
        'drawn': drawn,
        'lost': lost,
        'gf': gf,
        'ga': ga,
        'stadium': stadium,
        'trainingLvl': trainingLvl,
        'academy': academy,
        'med': medical,
        'fz': fanZone,
        'badge': badge,
        if (dataAt != 0) 'dat': dataAt,
        'venue': venue,
        'coach': coach,
        'pen': penalty,
        'form': form,
      };

  factory Team.fromJson(Map<String, dynamic> j) {
    final squad = [
      for (final p in j['squad'] as List)
        Player.fromJson(p as Map<String, dynamic>)
    ];
    final byId = {for (final p in squad) p.id: p};
    final t = Team(
      id: j['id'] as int,
      name: j['name'] as String,
      reputation: j['rep'] as int,
      squad: squad,
      budget: (j['budget'] as num).toDouble(),
    );
    t.formation = formations[(j['formation'] as int).clamp(0, formations.length - 1).toInt()];
    t.mentality = (j['m5'] as bool?) == true ? j['ment'] as int : (j['ment'] as int) * 2;
    t.pressing = j['press'] as int;
    t.tempo = j['tempo'] as int;
    t.width = (j['wid'] as int?) ?? 1;
    t.defLine = (j['dl'] as int?) ?? 1;
    t.passing = (j['pass'] as int?) ?? 1;
    final il = j['ins'] as Map<String, dynamic>?;
    if (il != null) {
      for (final e in il.entries) {
        final id = int.tryParse(e.key);
        if (id != null && kInstr.containsKey(e.value)) t.instr[id] = e.value as String;
      }
    }
    final rl = j['roles'] as Map<String, dynamic>?;
    if (rl != null) {
      for (final e in rl.entries) {
        final id = int.tryParse(e.key);
        if (id != null && kRoles.containsKey(e.value)) t.roles[id] = e.value as String;
      }
    }
    t.familiarity = (j['fam'] as num?)?.toDouble() ?? 70;
    t.pitch = ((j['pit'] as num?)?.toDouble() ?? 90).clamp(20.0, 100.0).toDouble();
    for (final e in ((j['pk'] as Map?) ?? const {}).entries) {
      if (e.value is int) t.perks['${e.key}'] = (e.value as int).clamp(0, 3);
    }
    for (final e in ((j['mn'] as Map?) ?? const {}).entries) {
      final k = int.tryParse('${e.key}');
      if (k != null) t.mentors[k] = e.value as int;
    }
    t.lastXI = {for (final v in (j['lxi'] as List?) ?? const []) v as int};
    final tk = (j['tk'] as List?)?.cast<int>();
    if (tk != null && tk.length == 3) {
      t.penTaker = tk[0];
      t.fkTaker = tk[1];
      t.cornerTaker = tk[2];
    }
    t.cohesion = (j['coh'] as num?)?.toDouble() ?? 65;
    t.lineup = [
      for (final id in j['lineup'] as List)
        if (byId[id] != null) byId[id]!
    ];
    t.played = j['played'] as int;
    t.won = j['won'] as int;
    t.drawn = j['drawn'] as int;
    t.lost = j['lost'] as int;
    t.gf = j['gf'] as int;
    t.ga = j['ga'] as int;
    t.stadium = j['stadium'] as int;
    t.trainingLvl = j['trainingLvl'] as int;
    t.academy = j['academy'] as int;
    t.medical = (j['med'] as int?) ?? 1;
    t.fanZone = (j['fz'] as int?) ?? 1;
    t.badge = j['badge'] as String?;
    t.dataAt = (j['dat'] as int?) ?? 0;
    t.venue = j['venue'] as String?;
    t.coach = j['coach'] as String?;
    t.penalty = (j['pen'] as int?) ?? 0;
    t.form = [for (final x in (j['form'] as List?) ?? const []) x as String];
    return t;
  }
}

/// الهرم الكروي للدولة: الدرجة الأعلى والأدنى من درجة المستخدم (إن توفرت بياناتهما)
class Pyramid {
  final int div;
  final List<Team> upper;
  final String upperName;
  final List<Team> lower;
  final String lowerName;
  final List<Team> world; // أندية قارية حقيقية بلاعبيها
  final String country;
  final int leagueId;
  final List<Team> worldEl, worldCo; // الدوري الأوروبي ودوري المؤتمر
  final int userSlotsEl, userSlotsCo;
  final int userSlots; // عدد مقاعد دوري الأبطال لدوري المستخدم
  const Pyramid({this.div = 1, this.upper = const [], this.upperName = '', this.lower = const [], this.lowerName = '', this.world = const [], this.worldEl = const [], this.worldCo = const [], this.userSlotsEl = 0, this.userSlotsCo = 0, this.userSlots = 3, this.country = '', this.leagueId = 0});
}
