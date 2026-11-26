part of 'game_state.dart';

/// أساطير متقاعدون يمكن استقدام أحدهم بالكوينز: (الاسم، المركز، التقييم، العمر، الجنسية)
const kLegends = <(String, Pos, int, int, String)>[
  ('Ronaldinho', Pos.att, 88, 33, 'البرازيل'),
  ('Zinedine Zidane', Pos.mid, 89, 34, 'فرنسا'),
  ('Paolo Maldini', Pos.def, 88, 35, 'إيطاليا'),
  ('Iker Casillas', Pos.gk, 88, 34, 'إسبانيا'),
  ('Thierry Henry', Pos.att, 88, 33, 'فرنسا'),
  ('Xavi Hernandez', Pos.mid, 88, 34, 'إسبانيا'),
  ('Carles Puyol', Pos.def, 87, 34, 'إسبانيا'),
  ('Ronaldo Nazario', Pos.att, 89, 32, 'البرازيل'),
];

/// مزايا نادرة تُشترى بكوينز اللعبة فقط
extension CoinPerks on GameState {
  static const costScout = 60;
  static const costWindow = 80;
  static const costHeal = 40;
  static const costRetry = 30;
  static const costPriority = 50;
  static const costLegend = 400;
  static const rushPerWeek = 15;

  String? _needCoins(int c) => Wallet.i.coins < c ? 'الكوينز غير كافية ($c مطلوبة)' : null;

  bool get windowExtended => windowExtSeason == season && week < windowExtUntil;
  bool get priorityActive => prioritySeason == season && week < priorityUntil;

  /// 1) كشّاف مميز: 5 مواهب شابة عالية الإمكانية من أنحاء العالم تدخل سوقك فوراً
  String? premiumScout() {
    final c = _needCoins(costScout);
    if (c != null) return c;
    final have = {for (final p in market) p.id};
    final mine = {for (final p in user.squad) p.id};
    final pool = <Player>[];
    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
      if (t == user) continue;
      for (final p in t.squad) {
        if (p.age <= 21 && p.potential >= 78 && !p.onLoan && !p.filler && !have.contains(p.id) && !mine.contains(p.id)) {
          p.club = t.name;
          pool.add(p);
        }
      }
    }
    if (pool.isEmpty) return 'لم يجد الكشّاف مواهب جديدة الآن';
    pool.sort((a, b) => b.potential.compareTo(a.potential));
    final top = pool.take(25).toList()..shuffle(rng);
    final pick = top.take(5).toList();
    Wallet.i.spend(costScout);
    for (final p in pick) {
      market.add(Player.fromJson(p.toJson())..club = p.club);
      scoutFound.add(p.id);
    }
    news.insert(0, '🔭 كشّاف مميز: أضاف إلى سوقك ${pick.map((p) => p.name).join('، ')}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// 2) تمديد النافذة جولتين بعد إغلاقها (مرة في الموسم، ويُشترى والنافذة مفتوحة)
  String? extendWindow() {
    if (!windowOpen) return 'النافذة مغلقة الآن؛ اشترِ التمديد وهي مفتوحة';
    if (windowExtSeason == season) return 'استخدمت التمديد في هذا الموسم';
    final c = _needCoins(costWindow);
    if (c != null) return c;
    final h = rounds.length ~/ 2;
    final end = week < 4 ? 4 : h + 3;
    Wallet.i.spend(costWindow);
    windowExtSeason = season;
    windowExtUntil = end + 2;
    news.insert(0, '⏱ مُدّدت نافذة الانتقالات جولتين إضافيتين');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// 5) علاج متقدم: يختصر نصف مدة إصابة طويلة (3 أسابيع فأكثر) مرة في الموسم
  String? healInjury(Player p) {
    if (p.injuredWeeks < 3) return 'الإصابة قصيرة، لا تحتاج علاجاً متقدماً';
    if (healSeason == season) return 'استخدمت العلاج المتقدم في هذا الموسم';
    final c = _needCoins(costHeal);
    if (c != null) return c;
    Wallet.i.spend(costHeal);
    healSeason = season;
    final before = p.injuredWeeks;
    p.injuredWeeks = (p.injuredWeeks / 2).ceil();
    news.insert(0, '🩺 علاج متقدم لـ ${p.name}: من $before إلى ${p.injuredWeeks} أسابيع');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// 4) إعادة التفاوض بعد انسحاب البائع أو اللاعب (يعيد فتح الجولات الثلاث)
  String? retryNegotiation(Player p) {
    final c = _needCoins(costRetry);
    if (c != null) return c;
    Wallet.i.spend(costRetry);
    _reserve.remove(p.id);
    _rivalHeat.remove(p.id);
    notifyListeners();
    return null;
  }

  /// 3) أولوية التفاوض: لا يتدخل أي نادٍ منافس في صفقاتك لأربع جولات
  String? buyPriority() {
    if (priorityActive) return 'الأولوية مفعّلة بالفعل';
    final c = _needCoins(costPriority);
    if (c != null) return c;
    Wallet.i.spend(costPriority);
    prioritySeason = season;
    priorityUntil = week + 4;
    news.insert(0, '🥇 أولوية التفاوض مفعّلة لأربع جولات: لن يخطف منافس صفقاتك');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// لاعب أسطوري: واحد في الموسم، يضاف فوراً إلى التشكيلة
  String? signLegend(int i) {
    if (legendSeason == season) return 'استقدمت أسطورة في هذا الموسم';
    if (user.squad.length >= 30) return 'التشكيلة ممتلئة (30 لاعباً كحد أقصى)';
    final c = _needCoins(costLegend);
    if (c != null) return c;
    final l = kLegends[i];
    if (user.squad.any((p) => p.name == l.$1)) return '${l.$1} في فريقك بالفعل';
    Wallet.i.spend(costLegend);
    legendSeason = season;
    final p = makePlayer(rng, l.$2, l.$3, l.$4, name: l.$1, nat: l.$5)
      ..contract = 2
      ..club = user.name;
    p.potential = p.overall;
    user.squad.add(p);
    user.repairLineup();
    news.insert(0, '👑 انضم الأسطورة ${l.$1} إلى ${user.name}!');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// تسريع البناء فوراً: يكتمل المشروع الآن مقابل 15 كوينز عن كل أسبوع متبقٍّ (10 على الأقل)
  int instantBuildCost(Project p) => max(10, p.left * rushPerWeek);

  String? instantBuild(String kind) {
    final p = projectOf(kind);
    if (p == null) return 'لا يوجد مشروع';
    final cost = instantBuildCost(p);
    final c = _needCoins(cost);
    if (c != null) return c;
    Wallet.i.spend(cost);
    _setFac(p.kind, p.toLevel);
    projects.remove(p);
    news.insert(0, '⚡ اكتمل مشروع ${FacilitiesLogic.facNames[p.kind]} فوراً: المستوى ${p.toLevel}${p.kind == 'stadium' ? ' — السعة $stadiumCapacity' : ''}');
    if (p.kind == 'stadium') fans = min(100, fans + 1.5);
    unawaited(save());
    notifyListeners();
    return null;
  }
}
