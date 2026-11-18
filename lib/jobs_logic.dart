part of 'game_state.dart';

/// عرض تدريب من نادٍ آخر
class JobOffer {
  final String club, reason;
  final int years, objective, div;
  final double budget;
  int ttl;
  final int lid; // معرّف دوري النادي إن كان في دولة أخرى (0 = داخل هرمك الحالي)
  final String lname;
  JobOffer(this.club, this.reason, this.years, this.objective, this.div, this.budget, this.ttl, {this.lid = 0, this.lname = ''});
  bool get abroad => lid != 0;
  Map<String, dynamic> toJson() => {'c': club, 'r': reason, 'y': years, 'o': objective, 'd': div, 'b': budget, 't': ttl, if (lid != 0) 'l': lid, if (lname.isNotEmpty) 'ln': lname};
  factory JobOffer.fromJson(Map<String, dynamic> j) => JobOffer(
      j['c'] as String, j['r'] as String, j['y'] as int, j['o'] as int, j['d'] as int, (j['b'] as num).toDouble(), j['t'] as int,
      lid: (j['l'] as int?) ?? 0, lname: (j['ln'] as String?) ?? '');
}

extension JobsLogic on GameState {
  /// فريق بالاسم من كل الدرجات والأندية العالمية (أو بديل بشعار من الفهرس)
  Team clubNamed(String n) {
    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
      if (t.name == n) return t;
    }
    for (final m in wTeams.values) {
      final t = m[n];
      if (t != null) return t;
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
        final hired = takeCoachFromPool(rng, {for (final x in [...teams, ...upper, ...lower]) x.coachName});
        if (hired == null) continue;
        final old = t.coachName;
        t.coach = hired;
        t.cohesion = min(100, t.cohesion + 6); // ارتداد المدرب الجديد
        if (t.reputation >= 3) news.insert(0, '🪓 ${t.name} يقيل ${t.hasCoachName && old != 'غير متوفر' ? old : 'مدربه'} ويعيّن $hired مدرباً جديداً');
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
    if (k > 0) {
      _genJobs(force: k);
      if (rng.nextDouble() < 0.35 + max(0.0, mgrRep - 50) / 120) this._genForeignJob();
    }
  }

  /// عروض للمُقال/المستقيل: أندية تحتاج مدرباً (تُولَّد مرة واحدة)
  List<JobOffer> get availableJobs {
    if (fired && !jobsGen) {
      jobsGen = true;
      if (!resigned) mgrRep = max(30.0, mgrRep - 8);
      jobOffers.clear();
      this._genForeignJob();
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
    if (o.abroad) {
      if (!seasonOver) return 'الانتقال إلى دولة أخرى ممكن فقط عند نهاية الموسم';
      if (wTeams[o.lid]?[o.club] == null) return 'لم يعد هذا النادي متاحاً';
      pendingJob = o.club;
      pendingAbroad = o.lid;
      jobOffers.clear();
      news.insert(0, '🌍 وافقت على تدريب ${o.club} في الخارج اعتباراً من الموسم القادم');
      unawaited(save());
      notifyListeners();
      return null;
    }
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
    final ab = pendingAbroad;
    if (ab != null) {
      pendingJob = null;
      pendingAbroad = null;
      if (name != null) this._applyAbroad(name, ab);
      return;
    }
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

extension AbroadJobs on GameState {
  /// عرض من نادٍ في دولة أخرى: لا يُعرض إلا عند نهاية الموسم وينفَّذ مع بداية الموسم القادم
  void _genForeignJob() {
    if (!realWorld || !seasonOver || jobOffers.length >= 3 || wLeagues.isEmpty) return;
    final target = user.reputation + (mgrRep - 50) / 25;
    Team? best;
    WorldLeague? bestL;
    var bestS = -1.0;
    for (final l in wLeagues) {
      final dv = worldDivOf(l);
      if (dv > 2 || l.country == country) continue;
      final ts = wTeams[l.id];
      if (ts == null) continue;
      for (final t in ts.values) {
        if (jobOffers.any((o) => o.club == t.name)) continue;
        final rep = t.reputation - (dv - 1) * 1.5; // أندية الدرجة الثانية أقل مكانة
        final fit = (1 - (rep - target).abs() / 3).clamp(0.0, 1.0).toDouble();
        final s = 0.65 * fit + 0.35 * rng.nextDouble();
        if (s > bestS) {
          bestS = s;
          best = t;
          bestL = l;
        }
      }
    }
    final t = best, l = bestL;
    if (t == null || l == null || bestS < 0.45) return;
    final rank = 1 + wTeams[l.id]!.values.where((x) => x.strength > t.strength).length;
    final sv = t.squad.fold<double>(0, (a, x) => a + x.value);
    final reason = t.reputation > user.reputation ? 'أعجبهم أداؤك ويرون فيك مدرب مشروعهم القادم' : 'يريد النادي مدرباً بسمعتك لقيادة مرحلة جديدة';
    jobOffers.add(JobOffer(t.name, reason, 2 + rng.nextInt(3), max(1, rank - 1), worldDivOf(l), (0.12 * sv).clamp(5.0, 220.0).toDouble(), 99, lid: l.id, lname: '${l.country} • ${l.name}'));
  }

  /// الانتقال الفعلي لدوري دولة أخرى: يتحول دوريك القديم إلى دوري عالمي محاكى، ودوري الوجهة يصبح دوريك الكامل.
  /// أي فشل في منتصف العملية يُعيد الحال كما كانت (تبقى في ناديك).
  void _applyAbroad(String clubName, int lid) {
    final src = Bundled.cached;
    final dest = src?.where((x) => x.id == lid).firstOrNull;
    if (src == null || dest == null) {
      news.insert(0, '⚠️ تعذّر الانتقال إلى الخارج فبقيت في ناديك');
      return;
    }
    final sTeams = teams, sUpper = upper, sLower = lower;
    final sUpN = upperName, sLoN = lowerName, sLeague = leagueName, sDiv = div, sCountry = country, sLid = leagueId;
    final sSlots = [userSlots, userSlotsEl, userSlotsCo];
    final sForeign = Map<int, Team>.of(foreign);
    final sWl = [...wLeagues];
    final sWt = Map<int, Map<String, Team>>.of(wTeams);
    final sCups = Map<int, WorldCup>.of(wCups);
    try {
      // ── تجهيز (بلا تعديل لأي كائن مشترك) ──
      final sameC = [for (final l in wLeagues) if (l.country == dest.country) l];
      final mainW = sameC.where((l) => l.id == lid).firstOrNull;
      if (mainW == null) throw StateError('league');
      WorldLeague? near(int dv) => sameC.where((l) => src.where((x) => x.id == l.id).firstOrNull?.div == dv).firstOrNull;
      final upW = near(dest.div - 1), loW = near(dest.div + 1);
      List<Team> asTeams(WorldLeague l) {
        final m = this._teamsOfWorld(l);
        if (m == null) throw StateError('teams');
        final ts = [for (final n in l.names) m[n]].whereType<Team>().toList();
        if (ts.length.isOdd) {
          ts.sort((a, b) => a.strength.compareTo(b.strength));
          ts.removeAt(0);
        }
        return ts;
      }

      final nMain = asTeams(mainW);
      final nUp = upW == null ? <Team>[] : asTeams(upW);
      final nLo = loW == null ? <Team>[] : asTeams(loW);
      final nt = nMain.where((t) => t.name == clubName).firstOrNull;
      if (nt == null || nMain.length < 6) throw StateError('club');
      final (p0, p1, p2) = buildContinentalPools(dest.country, src, rng);
      final topId = src.where((x) => x.country == dest.country && x.div == 1).firstOrNull?.id ?? lid;
      // دوريك القديم يصبح دوري عالم محاكى
      final oldSame = [for (final x in src) if (x.country == sCountry && x.teams.length >= 6) x];
      LeagueData? oldNear(int dv) => oldSame.where((x) => x.div == dv).firstOrNull;
      final oldWorld = <(WorldLeague, List<Team>)>[];
      void toWorld(LeagueData? d, List<Team> ts) {
        if (d == null || ts.length < 4) return;
        final s = [...ts]..sort((a, b) => b.strength.compareTo(a.strength));
        oldWorld.add((WorldLeague(d.id, d.name, d.country, d.tier, [for (final t in s) t.name], [for (final t in s) t.strength]), s));
      }

      toWorld(oldNear(sDiv), sTeams);
      toWorld(oldNear(sDiv - 1), sUpper);
      toWorld(oldNear(sDiv + 1), sLower);

      // ── التنفيذ ──
      final goneIds = {for (final l in [mainW, upW, loW]) if (l != null) l.id};
      wLeagues.removeWhere((l) => goneIds.contains(l.id));
      for (final id in goneIds) {
        wTeams.remove(id);
        wCups.remove(id);
      }
      for (final (wl, ts) in oldWorld) {
        for (var i = 0; i < ts.length; i++) {
          ts[i].id = 100000 + wl.id * 100 + i;
        }
        wLeagues.removeWhere((l) => l.id == wl.id);
        wLeagues.add(wl);
        wTeams[wl.id] = {for (final t in ts) t.name: t};
        wCups.remove(wl.id);
      }
      wLeagues.sort((a, b) => a.tier != b.tier ? a.tier.compareTo(b.tier) : a.name.compareTo(b.name));
      void prep(List<Team> ts) {
        for (var i = 0; i < ts.length; i++) {
          final t = ts[i];
          t
            ..id = i
            ..played = 0
            ..won = 0
            ..drawn = 0
            ..lost = 0
            ..gf = 0
            ..ga = 0
            ..penalty = 0
            ..form = [];
          t.venue ??= stadiumFor(t.name);
          final sv = t.squad.fold<double>(0, (a, x) => a + x.value);
          t.budget = (0.12 * sv).clamp(5.0, 220.0).toDouble();
        }
      }

      prep(nMain);
      prep(nUp);
      prep(nLo);
      teams = nMain;
      upper = nUp;
      lower = nLo;
      leagueName = mainW.name;
      upperName = upW?.name ?? '';
      lowerName = loW?.name ?? '';
      div = dest.div;
      country = dest.country;
      leagueId = topId;
      userSlots = dest.div == 1 ? max(1, continentalSlots(dest.country)) : 3;
      userSlotsEl = dest.div == 1 ? europaSlots(dest.country) : 0;
      userSlotsCo = dest.div == 1 ? conferenceSlots(dest.country) : 0;
      foreign.removeWhere((id, _) => id >= 1000 && id < 3000);
      void reg(List<Team> l, int base) {
        for (var i = 0; i < l.length; i++) {
          l[i].id = base + i;
          foreign[base + i] = l[i];
        }
      }

      reg(p0, 1000);
      reg(p1, 1100);
      reg(p2, 1200);
      for (final t in nMain) {
        if (t != nt) t.autoPick();
      }
      fans = 20.0 + nt.reputation * 12;
      this._takeClub(nt, 3, null);
      news.insert(0, '🌍 انتقلت للعمل في ${dest.country}: دوريك الجديد $leagueName');
    } catch (_) {
      teams = sTeams;
      upper = sUpper;
      lower = sLower;
      upperName = sUpN;
      lowerName = sLoN;
      leagueName = sLeague;
      div = sDiv;
      country = sCountry;
      leagueId = sLid;
      userSlots = sSlots[0];
      userSlotsEl = sSlots[1];
      userSlotsCo = sSlots[2];
      foreign
        ..clear()
        ..addAll(sForeign);
      wLeagues
        ..clear()
        ..addAll(sWl);
      wTeams
        ..clear()
        ..addAll(sWt);
      wCups
        ..clear()
        ..addAll(sCups);
      for (final l in [teams, upper, lower]) {
        for (var i = 0; i < l.length; i++) {
          l[i].id = i;
        }
      }
      news.insert(0, '⚠️ تعذّر الانتقال إلى الخارج فبقيت في ناديك');
    }
  }
}
