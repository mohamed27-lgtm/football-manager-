import 'dart:math';

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
  List<int>? sk; // المهارات الست للاعب المُنشأ: سرعة، تسديد، تمرير، مراوغة، دفاع، قوة
  List<String> traits = [];
  String? club; // ناديه الحالي (لاعبو السوق الحقيقيون)
  int? height;
  double? mv0; // القيمة السوقية الحقيقية عند الاستيراد (M€)
  int? ov0, age0; // التقييم والعمر عند الاستيراد
  bool free = false, onLoan = false, listed = false, registered = true;
  double? salary;
  double fitness = 100;
  double morale = 70;
  int injuredWeeks = 0;
  int suspendedMatches = 0;
  int goals = 0, assists = 0, apps = 0, yellows = 0;
  double ratingSum = 0;
  int rated = 0;
  int injuryCount = 0;
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

  double get effective =>
      overall * (0.55 + 0.45 * fitness / 100) * (0.92 + 0.16 * morale / 100);

  bool get available => injuredWeeks == 0 && suspendedMatches == 0 && registered;

  static double _ageF(int a) => a <= 21 ? 1.25 : a <= 24 ? 1.1 : a <= 28 ? 1.0 : a <= 31 ? 0.8 : a <= 34 ? 0.5 : 0.3;

  /// القيمة السوقية: تعتمد على قيمة Transfermarkt الحقيقية وتتحرك مع تطور تقييم اللاعب وعمره
  double get value {
    if (mv0 != null && ov0 != null) {
      final v = mv0! * pow(10, (overall - ov0!) / 9.3) * _ageF(age) / _ageF(age0 ?? age);
      return max(0.1, (v * 10).round() / 10);
    }
    var m = 1.0;
    if (age <= 23) m += max(0, potential - overall) / 25;
    if (age >= 31) m *= 0.6;
    final v = pow(overall / 50, 6).toDouble() * m;
    return max(0.1, (v * 10).round() / 10);
  }

  double get baseWage => (overall - 40).clamp(1, 60) * 0.0015;
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
        'sus': suspendedMatches,
        'goals': goals,
        'ast': assists,
        'apps': apps,
        'yel': yellows,
        'photo': photo,
        'free': free,
        'loan': onLoan,
        'listed': listed,
        'reg': registered,
        'sal': salary,
        'rs': ratingSum,
        'rn': rated,
        'ic': injuryCount,
        'opt': optionFee,
        'obl': obligation,
        'career': career,
        'aw': awards,
        'nat2': nat2, 'sk': sk, 'tr': traits,
        'club': club, 'nat': nat, 'sub': sub, 'ft': foot, 'ht': height, 'mv0': mv0, 'ov0': ov0, 'age0': age0,
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
        ..suspendedMatches = j['sus'] as int
        ..goals = j['goals'] as int
        ..assists = j['ast'] as int
        ..apps = j['apps'] as int
        ..yellows = j['yel'] as int
        ..photo = j['photo'] as String?
        ..free = (j['free'] as bool?) ?? false
        ..onLoan = (j['loan'] as bool?) ?? false
        ..listed = (j['listed'] as bool?) ?? false
        ..registered = (j['reg'] as bool?) ?? true
        ..salary = (j['sal'] as num?)?.toDouble()
        ..ratingSum = (j['rs'] as num?)?.toDouble() ?? 0
        ..rated = (j['rn'] as int?) ?? 0
        ..injuryCount = (j['ic'] as int?) ?? 0
        ..optionFee = (j['opt'] as num?)?.toDouble()
        ..obligation = (j['obl'] as bool?) ?? false
        ..club = j['club'] as String?
        ..nat = j['nat'] as String?
        ..nat2 = j['nat2'] as String?
        ..sk = (j['sk'] as List?)?.cast<int>()
        ..traits = [for (final t in (j['tr'] as List?) ?? const []) t as String]
        ..sub = j['sub'] as String?
        ..foot = j['ft'] as String?
        ..height = (j['ht'] as num?)?.toInt()
        ..mv0 = (j['mv0'] as num?)?.toDouble()
        ..ov0 = (j['ov0'] as num?)?.toInt()
        ..age0 = (j['age0'] as num?)?.toInt()
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
];

class Team {
  int id;
  final String name;
  final int reputation;
  List<Player> squad;
  Formation formation = formations[0];
  int mentality = 1;
  int pressing = 1;
  int tempo = 1;
  int width = 1; // 0 ضيق، 1 متوازن، 2 عريض
  int defLine = 1; // 0 منخفض، 1 متوسط، 2 مرتفع
  int passing = 1; // 0 قصير، 1 مختلط، 2 مباشر
  int analystLvl = 0; // يُضبط قبل كل مباراة من الطاقم
  double cohesion = 65; // الانسجام 30-100
  List<Player> lineup = [];
  double budget;
  int played = 0, won = 0, drawn = 0, lost = 0, gf = 0, ga = 0;
  int stadium = 1, trainingLvl = 1, academy = 1;
  String? badge, venue;

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

  Player _choose(Pos slot, Set<Player> used) {
    List<Player> pool(bool strict) => squad
        .where((p) =>
            !used.contains(p) &&
            p.available &&
            (strict
                ? p.pos == slot
                : (slot == Pos.gk ? true : p.pos != Pos.gk)))
        .toList()
      ..sort((a, b) => b.effective.compareTo(a.effective));
    var c = pool(true);
    if (c.isEmpty) c = pool(false);
    if (c.isEmpty) {
      c = squad.where((p) => !used.contains(p)).toList()
        ..sort((a, b) => b.effective.compareTo(a.effective));
    }
    return c.first;
  }

  void autoPick() {
    final used = <Player>{};
    final res = <Player>[];
    for (final s in slots) {
      final p = _choose(s, used);
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
        'press': pressing,
        'tempo': tempo,
        'wid': width,
        'dl': defLine,
        'pass': passing,
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
        'badge': badge,
        'venue': venue,
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
    t.mentality = j['ment'] as int;
    t.pressing = j['press'] as int;
    t.tempo = j['tempo'] as int;
    t.width = (j['wid'] as int?) ?? 1;
    t.defLine = (j['dl'] as int?) ?? 1;
    t.passing = (j['pass'] as int?) ?? 1;
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
    t.badge = j['badge'] as String?;
    t.venue = j['venue'] as String?;
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
