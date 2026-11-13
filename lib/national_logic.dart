part of 'game_state.dart';

/// إدارة المنتخبات: إحصاءات حقيقية من سجل المباريات والبطولات، وتدريب منتخب بالمحرك الكامل نفسه
extension NationalLogic on GameState {
  /// لاعبو الأمة في عالم اللعبة (من كل الأندية الحقيقية)، الأفضل أولاً
  List<(Player, Team)> natPlayers(String nation) {
    if (_natIdx == null) _buildNatIdx();
    final l = [...?_natIdx?[nation]]..sort((a, b) => b.$1.overall.compareTo(a.$1.overall));
    return l;
  }

  /// أفضل تشكيلة 4-3-3 + مقاعد: حارسان و8 مدافعين... حتى 23 لاعباً
  List<Player> natBestCall(String nation, {int size = 23}) {
    final all = natPlayers(nation).where((e) => e.$1.available).map((e) => e.$1).toList();
    final out = <Player>[];
    void take(Pos p, int n) => out.addAll(all.where((x) => x.pos == p && !out.contains(x)).take(n));
    take(Pos.gk, 3);
    take(Pos.def, 8);
    take(Pos.mid, 8);
    take(Pos.att, 5);
    for (final p in all) {
      if (out.length >= size) break;
      if (!out.contains(p)) out.add(p);
    }
    return out.take(size).toList();
  }

  /// سجل المنتخب: انتصارات/تعادلات/هزائم/أهداف من المباريات الدولية والبطولات المسجّلة
  ({int w, int d, int l, int gf, int ga, int titles}) natRecord(String n) {
    var w = 0, d = 0, l = 0, gf = 0, ga = 0, t = 0;
    void add(int f, int a) {
      gf += f;
      ga += a;
      if (f > a) {
        w++;
      } else if (f == a) {
        d++;
      } else {
        l++;
      }
    }

    for (final x in nat.log) {
      if (x[2] == n) add(x[4] as int, x[5] as int);
      if (x[3] == n) add(x[5] as int, x[4] as int);
    }
    for (final h in nat.history) {
      for (final m in h.matches) {
        if (m.a == n) add(m.ag, m.bg);
        if (m.b == n) add(m.bg, m.ag);
      }
      if (h.champion == n) t++;
    }
    return (w: w, d: d, l: l, gf: gf, ga: ga, titles: t);
  }

  /// هدّافو المنتخب في البطولات المسجّلة (لاعب ← أهداف)
  List<(String, int)> natScorers(String n) {
    final m = <String, int>{};
    for (final h in nat.history) {
      h.scorers.forEach((k, v) {
        final p = k.split('|');
        if (p.length >= 2 && p[1] == n) m[p[0]] = (m[p[0]] ?? 0) + v;
      });
    }
    final l = m.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));
    return l;
  }

  /// فريق منتخب قابل للعب بالمحرك: من استدعاءات المدرب أو أفضل لاعبي الأمة
  Team _natTeam(String nation, {List<Player>? call}) {
    final squad = [...(call != null && call.length >= 14 ? call : natBestCall(nation))];
    final t = Team(id: 200000 + (nation.hashCode & 0xffff), name: nation, reputation: 4, squad: squad, budget: 0);
    if (squad.length < 14) {
      topUpSquad(t, rng);
    } else {
      // لا مراكز ناقصة: أكمل بلاعبين مساعدين إن غاب حارس أو فئة كاملة
      final hasGk = squad.any((p) => p.pos == Pos.gk);
      if (!hasGk) topUpSquad(t, rng);
    }
    t.autoPick();
    return t;
  }

  List<Player> get natCalled {
    final job = natJob;
    if (job == null) return const [];
    final ids = natCall.toSet();
    final pool = [for (final e in natPlayers(job)) e.$1];
    final l = [for (final p in pool) if (ids.contains(p.id)) p];
    return l.length >= 14 ? l : natBestCall(job);
  }

  /// عروض المنتخبات تأتي حسب حاجة المنتخب: نتائج متعثرة أو تصنيف يتراجع، وبما يناسب سمعتك
  void _natOffersTick() {
    natOffers.removeWhere((o) => --o.ttl <= 0);
    if (natJob != null || seasonOver || natOffers.length >= 2 || mgrRep < 55) return;
    if (rng.nextDouble() > 0.035 + (mgrRep - 55) / 900) return;
    ensureNat();
    final rank = nat.pubRanking;
    // مستوى المنتخبات المناسب لسمعتك: كلما زادت سمعتك طُرحت عليك منتخبات أقوى
    final top = (60 - (mgrRep - 55) * 1.1).clamp(5, 70).toInt();
    final cand = <(String, double)>[];
    for (var i = 0; i < min(rank.length, top + 40); i++) {
      final n = rank[i];
      if (natOffers.any((o) => o.club == n) || natPlayers(n).length < 14) continue;
      final r = natRecord(n);
      final games = r.w + r.d + r.l;
      final need = games == 0 ? 0.35 : (r.l + 0.5 * r.d) / games;
      final fit = 1 - ((i - top).abs() / 50).clamp(0.0, 1.0).toDouble();
      cand.add((n, 0.55 * need + 0.35 * fit + 0.1 * rng.nextDouble()));
    }
    if (cand.isEmpty) return;
    cand.sort((a, b) => b.$2.compareTo(a.$2));
    final n = cand.first.$1;
    final pos = rank.indexOf(n) + 1;
    final r = natRecord(n);
    final why = r.l > r.w
        ? 'يمرّ المنتخب بنتائج متعثرة ويبحث اتحاده عن مدرب يعيد إليه التوازن'
        : 'يريد اتحاد اللعبة مدرباً بسمعتك لقيادة مرحلة جديدة للمنتخب';
    natOffers.add(JobOffer(n, why, 2, max(1, pos - 6), 0, 0, 14));
    news.insert(0, '💼 اتحاد $n يعرض عليك تدريب المنتخب');
  }

  /// قبول منتخب = ترك النادي (لا تدريب نادٍ ومنتخب معاً). يواصل ناديك اللعب آلياً دون تدخلك.
  String? acceptNatOffer(JobOffer o) {
    if (natJob != null) return 'تدرّب منتخباً بالفعل';
    final n = natPlayers(o.club).length;
    if (n < 11) return 'لا يملك منتخب ${o.club} لاعبين كافيين في عالم اللعبة';
    final old = user.name;
    natJob = o.club;
    natObjective = o.objective;
    natCall = [for (final p in natBestCall(o.club)) p.id];
    natOffers.clear();
    jobOffers.clear();
    renewal = null;
    fired = true;
    resigned = true;
    jobsGen = true;
    news.insert(0, '🤝 تركت تدريب $old وأصبحت مدرباً لمنتخب ${o.club}');
    notifyListeners();
    unawaited(save());
    return null;
  }

  /// ترك المنتخب: تعود بلا نادٍ وتصلك عروض الأندية
  void leaveNatJob() {
    if (natJob == null) return;
    news.insert(0, '👋 غادرت تدريب منتخب $natJob');
    natJob = null;
    natCall = [];
    jobsGen = false; // تُولَّد عروض الأندية عند فتح صفحة العروض
    notifyListeners();
    unawaited(save());
  }

  void toggleCall(Player p) {
    if (natJob == null) return;
    if (!natCall.remove(p.id)) {
      if (natCall.length >= 26) return;
      natCall.add(p.id);
    }
    notifyListeners();
    unawaited(save());
  }

  void autoCall() {
    final j = natJob;
    if (j == null) return;
    natCall = [for (final p in natBestCall(j)) p.id];
    notifyListeners();
    unawaited(save());
  }

  /// مباراة ودية يطلبها المدرب أمام منتخب آخر (بالمحرك الكامل، وتؤثر في التصنيف بوزن الودية)
  String? natFriendly(String opp) {
    final job = natJob;
    if (job == null) return 'لا تدرّب منتخباً';
    if (opp == job) return 'اختر منتخباً آخر';
    if (natFriendlyDone) return 'لُعبت مباراة ودية هذا الأسبوع — انتظر الأسبوع القادم';
    ensureNat();
    final r = _natJobMatch(job, opp, false);
    if (r == null) return 'تعذّر إجراء المباراة';
    nat.apply(job, opp, r.$1, r.$2, 10, fifa: 1.0);
    nat.log.add([season, 9, job, opp, r.$1, r.$2, 1]);
    natFriendlyWeek = week;
    notifyListeners();
    unawaited(save());
    return null;
  }

  bool get natFriendlyDone => natFriendlyWeek == week;

  /// مباراة منتخبي بالمحرك الكامل: تُستدعى من نافذة دولية فتُعيد النتيجة (لطرف أ، لطرف ب)
  (int, int)? _natJobMatch(String a, String b, bool qual) {
    final job = natJob;
    if (job == null || (a != job && b != job)) return null;
    final mine = _natTeam(job, call: natCalled);
    final opp = _natTeam(a == job ? b : a);
    final backup = <Player, List<num>>{
      for (final p in [...mine.squad, ...opp.squad]) p: [p.apps, p.goals, p.assists, p.rated, p.ratingSum, p.yellows, p.suspendedMatches],
    };
    final home = a == job ? mine : opp, away = a == job ? opp : mine;
    try {
      final sim = MatchSim(home, away, random: rng);
      sim.simulateAll();
      final hg = sim.home.goals, ag = sim.away.goals;
      final gf = a == job ? hg : ag, ga = a == job ? ag : hg;
      natJobLog.insert(0, [season, a == job ? b : a, gf, ga, qual ? 0 : 1, a == job ? 1 : 0]);
      if (natJobLog.length > 60) natJobLog.removeLast();
      news.insert(0, '🏅 منتخب $job: $gf-$ga أمام ${a == job ? b : a} (${qual ? 'تصفيات رسمية' : 'ودية'})');
      return (hg, ag);
    } catch (_) {
      return null;
    } finally {
      backup.forEach((p, v) {
        p.apps = v[0].toInt();
        p.goals = v[1].toInt();
        p.assists = v[2].toInt();
        p.rated = v[3].toInt();
        p.ratingSum = v[4].toDouble();
        p.yellows = v[5].toInt();
        p.suspendedMatches = v[6].toInt();
      });
    }
  }
}
