part of 'game_state.dart';

/// عرض تدريب من نادٍ آخر
class JobOffer {
  final String club, reason;
  final int years, objective, div;
  final double budget;
  int ttl;
  JobOffer(this.club, this.reason, this.years, this.objective, this.div, this.budget, this.ttl);
  Map<String, dynamic> toJson() => {'c': club, 'r': reason, 'y': years, 'o': objective, 'd': div, 'b': budget, 't': ttl};
  factory JobOffer.fromJson(Map<String, dynamic> j) =>
      JobOffer(j['c'] as String, j['r'] as String, j['y'] as int, j['o'] as int, j['d'] as int, (j['b'] as num).toDouble(), j['t'] as int);
}

extension JobsLogic on GameState {
  /// فريق بالاسم من كل الدرجات والأندية العالمية (أو بديل بشعار من الفهرس)
  Team clubNamed(String n) {
    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
      if (t.name == n) return t;
    }
    return Team(id: -1, name: n, reputation: 3, squad: [], budget: 0);
  }

  /// المواسم المتبقية في عقد المدرب مع النادي الحالي
  int get contractLeft => max(0, (mgrEnd == 0 ? season + 2 : mgrEnd) - season + 1);

  /// سمعة المدرب كنص
  String get mgrTier => mgrRep >= 85 ? 'مدرب نخبة' : mgrRep >= 70 ? 'مدرب مرموق' : mgrRep >= 55 ? 'مدرب واعد' : 'مدرب صاعد';

  List<Team> _jobPool() => (seasonOver && !fired) ? [...teams, ...upper, ...lower] : [...teams];

  /// ولادة العروض: الجودة (سمعتك مقابل مكانة النادي) والحاجة (نادٍ متعثر يبحث عن مدرب) والطلب (أدائك)
  void _genJobs({int force = 0}) {
    if (jobOffers.length >= 3) return;
    final pool = this._jobPool().where((t) => t != user && !jobOffers.any((o) => o.club == t.name)).toList();
    if (pool.isEmpty) return;
    final tbl = table;
    final target = user.reputation + (mgrRep - 50) / 25;
    final scored = <(Team, double)>[];
    for (final t in pool) {
      final inLeague = teams.contains(t);
      final pos = inLeague ? tbl.indexOf(t) + 1 : (teams.length / 2).round();
      final need = inLeague ? ((pos - teams.length * 0.55) / (teams.length * 0.45)).clamp(0.0, 1.0).toDouble() : 0.3;
      final fit = (1 - (t.reputation - target).abs() / 3).clamp(0.0, 1.0).toDouble();
      scored.add((t, 0.45 * fit + 0.4 * need + 0.15 * rng.nextDouble()));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final n = force > 0 ? min(force, 3 - jobOffers.length) : 1;
    for (final e in scored.take(n)) {
      final t = e.$1;
      final list = teams.contains(t) ? teams : (upper.contains(t) ? upper : lower);
      final rank = ([...list]..sort((a, b) => b.strength.compareTo(a.strength))).indexOf(t) + 1;
      final inLeague = teams.contains(t);
      final pos = inLeague ? tbl.indexOf(t) + 1 : 0;
      final reason = inLeague && pos > teams.length * 0.65
          ? 'يمرّ النادي بفترة صعبة ويبحث عن مدرب يعيد إليه توازنه'
          : t.reputation > user.reputation
              ? 'أعجبهم أداؤك ويرون فيك مدرب مشروعهم القادم'
              : 'يريد النادي مدرباً بسمعتك لقيادة مرحلة جديدة';
      jobOffers.add(JobOffer(t.name, reason, 2 + rng.nextInt(3), max(1, rank - 1), teams.contains(t) ? div : (upper.contains(t) ? div - 1 : div + 1), t.budget, seasonOver ? 99 : 6));
    }
  }

  /// عالم الأندية: إقالات وتعيينات مدربين، واستحواذات تغيّر ميزانيات الأندية الأخرى
  void _clubsTick() {
    if (fired || seasonOver || week < 6) return;
    for (final t in teams) {
      if (t == user) continue;
      final f = formOf(t, 6);
      // إقالة بعد سلسلة نتائج سيئة (تتكرر بحسب صبر الإدارة)
      if (f.length >= 5 && f.where((r) => r == 'L').length >= 4 && rng.nextDouble() < 0.18) {
        final old = t.coachName;
        t.coach = randomName(rng);
        t.cohesion = min(100, t.cohesion + 6); // ارتداد المدرب الجديد
        if (t.reputation >= 3) news.insert(0, '🪓 ${t.name} يقيل $old ويعيّن ${t.coach} مدرباً جديداً');
      }
    }
    // استحواذ: مُلّاك جدد ينقذون نادياً متعثراً أو يضخّون أموالاً في نادٍ طموح
    if (rng.nextDouble() < 0.012) {
      final pool = teams.where((t) => t != user && (t.budget < 4 || (t.reputation >= 3 && rng.nextDouble() < 0.2))).toList();
      if (pool.isNotEmpty) {
        final t = pool[rng.nextInt(pool.length)];
        final cash = 25.0 + rng.nextInt(90);
        t.budget += cash;
        news.insert(0, '🏦 استحواذ جديد على ${t.name}: ضخ ${money1(cash)} ويعلن طموحاً كبيراً');
      }
    }
  }

  /// كل أسبوع: تقادم العروض القديمة واحتمال وصول عرض جديد
  void _weeklyJobs() {
    this._clubsTick();
    jobOffers.removeWhere((o) => --o.ttl <= 0);
    this._natOffersTick();
    if (fired || seasonOver) return;
    final p = 0.04 + max(0.0, mgrRep - 50) / 500 + (confidence < 35 ? 0.04 : 0.0);
    if (rng.nextDouble() < p) {
      final before = jobOffers.length;
      _genJobs();
      if (jobOffers.length > before) news.insert(0, '💼 وصلك عرض تدريب من ${jobOffers.last.club}');
    }
  }

  /// تجديد العقد: في موسمك الأخير تقرر الإدارة حسب نتائجك وثقتها ورغبتها (مرة واحدة في الموسم)
  void _renewalTick(int pos) {
    if (fired || resigned || pendingJob != null || renewal != null || renewDecidedSeason == season) return;
    if (contractLeft > 1 || week < rounds.length * 0.5) return;
    renewDecidedSeason = season;
    final good = pos <= objective || pos <= 3;
    final want = confidence >= 62 && good ? 2 : (confidence >= 45 || good ? 1 : 0);
    if (want == 0) {
      news.insert(0, '📄 الإدارة غير راضية ولا تنوي تجديد عقدك حالياً');
      return;
    }
    final years = want == 2 ? 3 + (confidence >= 80 ? 1 : 0) : 1;
    final obj = want == 2 ? max(1, min(objective, pos)) : objective;
    renewal = JobOffer(user.name, want == 2 ? 'الإدارة راضية عن نتائجك وتريد الاستمرار معك لمشروع طويل' : 'تعرض الإدارة تمديداً قصيراً وتنتظر نتائج أفضل قبل الالتزام أكثر', years, obj, div, user.budget, 99);
    news.insert(0, '📄 الإدارة تعرض عليك تجديد العقد لـ $years ${years == 1 ? 'موسم' : 'مواسم'}');
    notifyListeners();
  }

  String? acceptRenewal() {
    final r = renewal;
    if (r == null) return 'لا يوجد عرض تجديد';
    mgrEnd = season + r.years - 1;
    objective = r.objective;
    confidence = min(100, confidence + 5);
    renewal = null;
    news.insert(0, '📄 جدّدت عقدك مع ${user.name} حتى الموسم ${mgrEnd + 1}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  void rejectRenewal() {
    renewal = null;
    renewDecidedSeason = season;
    news.insert(0, '📄 رفضت عرض تجديد العقد وستنهي الموسم بالعقد الحالي');
    unawaited(save());
    notifyListeners();
  }

  /// آخر الموسم: إن انتهى العقد دون تجديد يُمدَّد سنة أو تنفصل الإدارة عنك
  void _contractExpiry() {
    if (fired || resigned || pendingJob != null || contractLeft > 1) {
      renewal = null;
      return;
    }
    if (renewal != null) {
      mgrEnd = season;
      news.insert(0, '📄 انتهت مهلة عرض التجديد، فمدّدت الإدارة عقدك موسماً واحداً');
      mgrEnd = season + 1;
    } else if (confidence < 35) {
      fired = true;
      news.insert(0, '📄 انتهى عقدك ولم تجدد الإدارة معك');
    } else {
      mgrEnd = season + 1;
      news.insert(0, '📄 مددت الإدارة عقدك موسماً واحداً بنفس الشروط');
    }
    renewal = null;
  }

  /// نهاية الموسم: عروض أوفر للمدرب الناجح
  void _seasonJobs(int pos) {
    mgrRep = (mgrRep + (pos <= objective ? 3 : -2) + (pos == 1 ? 3 : 0)).clamp(30.0, 100.0).toDouble();
    if (fired) return;
    final k = confidence >= 65 || pos <= 3 ? 2 : (confidence >= 40 ? 1 : 0);
    if (k > 0) _genJobs(force: k);
  }

  /// عروض للمُقال/المستقيل: أندية تحتاج مدرباً (تُولَّد مرة واحدة)
  List<JobOffer> get availableJobs {
    if (fired && !jobsGen) {
      jobsGen = true;
      if (!resigned) mgrRep = max(30.0, mgrRep - 8);
      jobOffers.clear();
      _genJobs(force: 3);
    }
    return jobOffers;
  }

  /// الاستقالة / فسخ العقد: لا يتوقف شيء ولا يُمسح شيء؛ تستمر اللعبة كالمعتاد مع ناديك
  /// حتى تقبل عرضاً من نادٍ آخر، وتصلك عروض الأندية فوراً.
  void resign() {
    if (resigned) return;
    resigned = true;
    mgrRep = max(30.0, mgrRep - 4 * (contractLeft - 1).clamp(0, 3).toInt());
    news.insert(0, '✍️ قدّمت استقالتك من تدريب ${user.name}، وستواصل العمل حتى تقبل عرضاً جديداً');
    jobsGen = true;
    jobOffers.clear();
    _genJobs(force: 3);
    unawaited(save());
    notifyListeners();
  }

  /// متابعة الموسم بلا نادٍ (بعد الإقالة): تُلعب جولتك وكؤوسك آلياً ويستمر العالم، حتى تقبل عرضاً
  void spectateRound() {
    if (!fired || seasonOver) return;
    fired = false;
    try {
      user.autoPick();
      var guard = 0;
      Cup? c;
      while ((c = pendingCup) != null && guard++ < 8) {
        startCupMatch(c!);
        finishCurrent();
      }
      if (!seasonOver) {
        startMatch();
        finishMatchday();
      }
    } finally {
      fired = true;
    }
    notifyListeners();
  }

  /// قبول عرض: فوري داخل الدوري، أو مؤجل لبداية الموسم عند الانتقال لدرجة أخرى
  String? acceptJob(JobOffer o) {
    final nt = [...teams, ...upper, ...lower].where((t) => t.name == o.club).firstOrNull;
    if (nt == null) return 'لم يعد هذا النادي متاحاً';
    if (seasonOver && !fired) {
      pendingJob = o.club;
      jobOffers.clear();
      news.insert(0, '💼 وافقت على تدريب ${o.club} اعتباراً من الموسم القادم');
      unawaited(save());
      notifyListeners();
      return null;
    }
    if (!teams.contains(nt)) return 'الانتقال لدرجة أخرى ممكن فقط عند نهاية الموسم';
    this._takeClub(nt, o.years, o.objective);
    return null;
  }

  void rejectJob(JobOffer o) {
    jobOffers.remove(o);
    notifyListeners();
    save();
  }

  void _takeClub(Team nt, int years, int? obj) {
    final old = user;
    for (final p in loanedOut) {
      old.squad.add(p);
    }
    loanedOut.clear();
    jobOffers.clear();
    offers.clear();
    boardKind = null;
    deals.clear();
    if (!identical(nt, old)) mgrRep = (mgrRep + (resigned || fired ? 0 : -2)).clamp(30.0, 100.0).toDouble();
    user = nt;
    fired = false;
    resigned = false;
    jobsGen = false;
    pendingJob = null;
    mgrEnd = season + years - 1;
    confidence = 60;
    nt.repairLineup();
    _genSponsorOffers();
    _setObjective();
    if (obj != null) objective = obj;
    _adjCache.clear();
    news.insert(0, '🤝 أصبحت مدرباً لنادي ${nt.name} — هدف الإدارة: المركز $objective أو أفضل');
    unawaited(save());
    notifyListeners();
  }

  /// بعد الصعود/الهبوط في بداية الموسم: ينتقل المستخدم للنادي المتفق عليه ولو في درجة أخرى
  void _applyPendingJob() {
    final name = pendingJob;
    if (name == null) return;
    pendingJob = null;
    final all = [...teams, ...upper, ...lower];
    final nt = all.where((t) => t.name == name).firstOrNull;
    if (nt == null) return;
    final oldName = leagueName;
    if (upper.contains(nt)) {
      final old = teams;
      teams = upper;
      leagueName = upperName;
      lower = old;
      lowerName = oldName;
      upper = [];
      upperName = '';
      div = max(1, div - 1);
    } else if (lower.contains(nt)) {
      final old = teams;
      teams = lower;
      leagueName = lowerName;
      upper = old;
      upperName = oldName;
      lower = [];
      lowerName = '';
      div++;
    }
    for (final l in [teams, upper, lower]) {
      for (var i = 0; i < l.length; i++) {
        l[i].id = i;
      }
    }
    for (final t in teams) {
      if (t != nt) t.autoPick();
    }
    this._takeClub(nt, 3, null);
  }
}
