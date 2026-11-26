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

  static const costShield = 100;
  static const costUndo = 80;
  static const costFullHeal = 90;
  static const costTalent = 120;
  static const costStadiumName = 60;

  /// يُستدعى عند نزول الثقة إلى الصفر: درع الإقالة يمنعها مرة ويعيد الثقة إلى 40
  void _checkSack() {
    if (confidence > 0) return;
    if (sackShield > 0) {
      sackShield--;
      confidence = 40;
      news.insert(0, '🛡️ درع الإقالة أنقذ منصبك! عادت ثقة الإدارة إلى 40%');
    } else {
      fired = true;
    }
  }

  /// للاختبار فقط
  void checkSackForTest() => _checkSack();

  String? buyShield() {
    if (sackShield >= 2) return 'لديك درعان بالفعل (الحد الأقصى)';
    final c = _needCoins(costShield);
    if (c != null) return c;
    Wallet.i.spend(costShield);
    sackShield++;
    news.insert(0, '🛡️ اشتريت درع إقالة ($sackShield)');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// آخر صفقة شراء يمكن التراجع عنها (في الأسبوع نفسه أو الذي يليه)
  Player? get undoableDeal {
    final d = lastDeal;
    if (d == null || d['s'] != season || week - (d['w'] as int) > 1) return null;
    return user.squad.where((p) => p.id == d['id']).firstOrNull;
  }

  String? undoLastDeal() {
    final p = undoableDeal;
    final d = lastDeal;
    if (p == null || d == null) return 'لا توجد صفقة يمكن التراجع عنها (خلال أسبوع من التعاقد)';
    final c = _needCoins(costUndo);
    if (c != null) return c;
    Wallet.i.spend(costUndo);
    final price = (d['price'] as num).toDouble();
    final fee = (d['fee'] as num).toDouble();
    final extra = (d['extra'] as num).toDouble();
    user.squad.remove(p);
    user.budget += price + fee + extra;
    fin.season['purchases'] = (fin.season['purchases'] ?? 0) - price;
    fin.season['agents'] = (fin.season['agents'] ?? 0) - fee;
    final from = d['from'] as String?;
    final owner = from == null ? null : _clubNamed(from);
    if (owner != null) {
      p.club = from;
      owner.squad.add(p);
      owner.budget -= price;
    } else {
      p.free = true;
      p.club = null;
      freeAgents.add(p);
    }
    user.repairLineup();
    lastDeal = null;
    news.insert(0, '↩️ تراجعت عن صفقة ${p.name} واستُردّت ${money1(price + fee + extra)}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// علاج كامل: ينهي الإصابة فوراً (مرة في الموسم)
  String? healInjuryFull(Player p) {
    if (p.injuredWeeks <= 0) return 'اللاعب غير مصاب';
    if (fullHealSeason == season) return 'استخدمت الشفاء الكامل في هذا الموسم';
    final c = _needCoins(costFullHeal);
    if (c != null) return c;
    Wallet.i.spend(costFullHeal);
    fullHealSeason = season;
    p.injuredWeeks = 0;
    news.insert(0, '💉 شفاء فوري لـ ${p.name}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// 3 مواهب شابة للاختيار منها (لا تكلفة قبل الاختيار)
  List<Player> drawTalents() {
    final out = <Player>[];
    final pos = [Pos.att, Pos.mid, Pos.def, Pos.gk]..shuffle(rng);
    for (final ps in pos.take(3)) {
      final p = makePlayer(rng, ps, 60 + rng.nextInt(6), 17 + rng.nextInt(2), preferNat: dominantNat(user.squad.map((q) => q.nat)));
      p.potential = max(p.overall + 14, 84 + rng.nextInt(9));
      p.contract = 4;
      out.add(p);
    }
    return out;
  }

  String? signTalent(Player p) {
    if (talentSeason == season) return 'اخترت موهبة في هذا الموسم';
    if (user.squad.length >= 30) return 'التشكيلة ممتلئة (30 لاعباً كحد أقصى)';
    final c = _needCoins(costTalent);
    if (c != null) return c;
    Wallet.i.spend(costTalent);
    talentSeason = season;
    p.club = user.name;
    user.squad.add(p);
    _registerNew(p);
    news.insert(0, '🌟 موهبة مضمونة: ${p.name} (${p.overall} ← ${p.potential}) انضم إلى ${user.name}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  /// اسم الملعب: تغييره بكوينز (يظهر في صفحة الملعب)
  String? renameStadium(String name) {
    final n = name.trim();
    if (n.length < 3 || n.length > 30) return 'الاسم من 3 إلى 30 حرفاً';
    final c = _needCoins(costStadiumName);
    if (c != null) return c;
    Wallet.i.spend(costStadiumName);
    user.venue = n;
    news.insert(0, '🏟️ أصبح اسم ملعبك: $n');
    unawaited(save());
    notifyListeners();
    return null;
  }
}
