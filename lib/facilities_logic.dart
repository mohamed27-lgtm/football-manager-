part of 'game_state.dart';

/// مشروع إنشاء/ترقية منشأة: يستغرق أسابيع، قد يتأخر، ويمكن تسريعه بمقابل
class Project {
  final String kind;
  final int toLevel, total;
  int left, delays;
  final double cost;
  bool rushed;
  Project(this.kind, this.toLevel, this.total, this.left, this.cost, {this.delays = 0, this.rushed = false});
  double get progress => total == 0 ? 1 : ((total - left) / total).clamp(0.0, 1.0).toDouble();
  Map<String, dynamic> toJson() => {'k': kind, 'l': toLevel, 't': total, 'w': left, 'c': cost, 'd': delays, 'r': rushed};
  factory Project.fromJson(Map<String, dynamic> j) =>
      Project(j['k'] as String, j['l'] as int, j['t'] as int, j['w'] as int, (j['c'] as num).toDouble(), delays: (j['d'] as int?) ?? 0, rushed: (j['r'] as bool?) ?? false);
}

const kFacilityKinds = ['stadium', 'training', 'academy', 'medical', 'fans'];

extension FacilitiesLogic on GameState {
  int facLevel(String kind) => switch (kind) {
        'stadium' => user.stadium,
        'training' => user.trainingLvl,
        'academy' => user.academy,
        'medical' => user.medical,
        'fans' => user.fanZone,
        _ => 1,
      };

  void _setFac(String kind, int v) {
    switch (kind) {
      case 'stadium':
        user.stadium = v;
      case 'training':
        user.trainingLvl = v;
      case 'academy':
        user.academy = v;
      case 'medical':
        user.medical = v;
      case 'fans':
        user.fanZone = v;
    }
  }

  Project? projectOf(String kind) {
    for (final p in projects) {
      if (p.kind == kind) return p;
    }
    return null;
  }

  /// تكلفة المستوى التالي: تتدرج مع المستوى ونوع المنشأة وحجم النادي
  double facCost(String kind, int lvl) {
    const mult = {'stadium': 2.2, 'training': 1.2, 'academy': 1.0, 'medical': 0.9, 'fans': 0.9};
    return ((6.0 + 6.0 * lvl) * (mult[kind] ?? 1.0) * (0.85 + 0.05 * user.reputation) * 10).round() / 10;
  }

  /// مدة التنفيذ بالأسابيع: الملاعب أطول بكثير من المرافق الصغيرة
  int facWeeks(String kind, int lvl) {
    const stadium = [10, 14, 20, 28];
    const other = [6, 8, 11, 14];
    final i = (lvl - 1).clamp(0, 3);
    return kind == 'stadium' ? stadium[i] : (other[i] * (kind == 'training' ? 1.15 : 1.0)).round();
  }

  static const facNames = {'stadium': 'توسعة الملعب', 'training': 'مركز التدريب', 'academy': 'الأكاديمية', 'medical': 'المركز الطبي', 'fans': 'مرافق الجماهير'};

  String? startProject(String kind) {
    final lvl = facLevel(kind);
    if (lvl >= 5) return 'وصلت إلى أقصى مستوى';
    if (projectOf(kind) != null) return 'هناك مشروع جارٍ لهذه المنشأة';
    if (projects.length >= 2) return 'لا يمكن تنفيذ أكثر من مشروعين في الوقت نفسه';
    final cost = facCost(kind, lvl);
    if (cost > user.budget) return 'الميزانية غير كافية (${money1(cost)})';
    user.budget -= cost;
    fin.add('upgrades', cost);
    final w = facWeeks(kind, lvl);
    projects.add(Project(kind, lvl + 1, w, w, cost));
    news.insert(0, '🏗️ بدأ مشروع ${facNames[kind]} (المستوى ${lvl + 1}) — يستغرق $w أسبوعاً بتكلفة ${money1(cost)}');
    logOp('مشروع ${facNames[kind]} (-${money1(cost)})');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// تكلفة التسريع: 35% من تكلفة المشروع، يختصر ٪45 من المدة المتبقية (مرة واحدة)
  double rushCost(Project p) => (p.cost * 0.35 * 10).round() / 10;

  String? rushProject(String kind) {
    final p = projectOf(kind);
    if (p == null) return 'لا يوجد مشروع';
    if (p.rushed) return 'سبق تسريع هذا المشروع';
    if (p.left <= 1) return 'المشروع على وشك الانتهاء';
    final c = rushCost(p);
    if (c > user.budget) return 'الميزانية غير كافية (${money1(c)})';
    user.budget -= c;
    fin.add('upgrades', c);
    p.left = max(1, (p.left * 0.55).ceil());
    p.rushed = true;
    news.insert(0, '⚡ سرّعت مشروع ${facNames[kind]}: يتبقى ${p.left} أسبوعاً');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// ترقية قديمة (للتوافق): تبدأ مشروعاً
  String? upgrade(String kind) => startProject(kind);

  /// كل أسبوع: تقدّم المشاريع، تأخيرات محتملة، وتجاوز تكلفة
  void _projectsTick() {
    for (final p in [...projects]) {
      p.left--;
      if (p.left > 0 && rng.nextDouble() < 0.05) {
        final d = 1 + rng.nextInt(2);
        p.left += d;
        p.delays++;
        final why = ['أمطار غزيرة', 'تأخر تراخيص البلدية', 'نقص في المواد', 'خلاف مع المقاول'][rng.nextInt(4)];
        news.insert(0, '🚧 تأخر مشروع ${facNames[p.kind]} $d أسبوعاً بسبب $why');
      }
      if (p.left > 0 && p.kind == 'stadium' && rng.nextDouble() < 0.03) {
        final extra = (p.cost * 0.08 * 10).round() / 10;
        user.budget -= extra;
        fin.add('upgrades', extra);
        news.insert(0, '💸 تجاوزت تكلفة توسعة الملعب الميزانية بمقدار ${money1(extra)}');
      }
      if (p.left <= 0) {
        _setFac(p.kind, p.toLevel);
        projects.remove(p);
        news.insert(0, '✅ اكتمل مشروع ${facNames[p.kind]}: المستوى ${p.toLevel}${p.kind == 'stadium' ? ' — السعة $stadiumCapacity' : ''}');
        if (p.kind == 'stadium') fans = min(100, fans + 1.5);
      }
    }
  }

  /// تأثير التوسعة: الملعب أثناء البناء يعمل بسعة أقل (15%)
  bool get stadiumBuilding => projectOf('stadium') != null;

  /// تقدير إيراد مباراة على أرضك مقسّماً: اشتراكات موسمية (ثابتة)، تذاكر منفردة (تتأثر بالسعر)، وضيافة VIP
  ({double season, double single, double vip}) gateParts({int oppRep = 3}) {
    final mk = staff['marketing'] ?? 0;
    final base = (0.3 + 0.12 * user.reputation) * (0.7 + 0.15 * user.stadium) * (0.75 + 0.5 * fans / 100) * (1 + 0.04 * mk) * (1 + 0.04 * (user.fanZone - 1));
    final baseFill = 0.42 + 0.5 * fans / 100;
    final opp = 0.92 + 0.04 * oppRep;
    final pos = table.indexOf(user) + 1;
    final vipF = (0.8 + 0.1 * user.stadium) * (pos > 0 && pos <= 4 ? 1.1 : 0.95);
    return (
      season: base * 0.35,
      single: base * 0.45 * ticketMult[ticketLevel] * (fillRate / baseFill) * opp,
      vip: base * 0.20 * vipF * opp,
    );
  }
}
