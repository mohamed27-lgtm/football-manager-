import 'dart:math';
import 'models.dart';

class MatchEvent {
  final int minute;
  final String type; // goal, yellow, red, injury, sub, miss, save, penalty, info
  final String text;
  final bool home;
  final bool major;
  const MatchEvent(this.minute, this.type, this.text, this.home,
      {this.major = true});
}

class Slot {
  Pos pos;
  Player p;
  Slot(this.pos, this.p);

  double get rate {
    if (p.pos == pos) return p.effective;
    if (pos == Pos.gk) return p.effective * 0.2;
    if (p.pos == Pos.gk) return p.effective * 0.3;
    return p.effective * 0.85;
  }
}

/// إحصاءات أداء لاعب في المباراة (تُبنى منها التقييمات)
class PerfStat {
  int passes = 0, passOk = 0, keyPasses = 0, shots = 0, onTarget = 0, tackles = 0, saves = 0;
}

class Side {
  final Team team;
  final bool isHome;
  final bool isUser;
  late List<Slot> slots;
  final Set<Player> out = {};
  final Map<int, int> yellowCount = {};
  final Map<Player, double> ratings = {};
  final Map<Player, PerfStat> perf = {};
  PerfStat ps(Player p) => perf.putIfAbsent(p, PerfStat.new);
  int goals = 0, shots = 0, onTarget = 0, poss = 0, subsLeft = 3, fouls = 0, corners = 0;
  int passes = 0, passOk = 0, offsides = 0, bigChances = 0, bigMissed = 0;
  double xg = 0;

  /// مهارة التمرير: متوسط تمرير اللاعبين الميدانيين
  double get passSkill {
    final l = slots.where((s) => s.pos != Pos.gk).toList();
    return l.isEmpty ? 40 : l.fold(0.0, (a, s) => a + s.p.pas) / l.length;
  }
  int mentalityBoost = 0;

  Side(this.team, this.isHome, this.isUser) {
    if (isUser) {
      team.repairLineup();
    } else {
      team.applyAiStyle();
      team.autoPick();
    }
    final s = team.slots;
    slots = [for (var i = 0; i < 11; i++) Slot(s[i], team.lineup[i])];
    for (final sl in slots) {
      sl.p.apps++;
      ratings[sl.p] = 6.0;
    }
  }

  void bump(Player p, double v) =>
      ratings[p] = ((ratings[p] ?? 6.0) + v).clamp(3.0, 10.0).toDouble();

  List<Player> get bench => team.squad
      .where((p) =>
          p.available && !out.contains(p) && !slots.any((s) => s.p == p))
      .toList()
    ..sort((a, b) => b.effective.compareTo(a.effective));

  int get mentality => (team.mentality + mentalityBoost).clamp(0, 4).toInt();

  int count(Pos p) => slots.where((s) => s.pos == p).length;

  double lineAvg(Pos p) {
    final l = slots.where((s) => s.pos == p).toList();
    if (l.isEmpty) return 25;
    return l.fold(0.0, (a, s) => a + s.rate) / l.length;
  }

  double get _man => pow(slots.length / 11, 1.5).toDouble();

  /// الانسجام وتحليل الطاقم
  double get _form => (0.97 + 0.06 * team.cohesion / 100) * (1 + 0.008 * team.analystLvl) * (slots.any((s) => s.p.trait == 'قائد') ? 1.01 : 1.0);

  double get attackPower =>
      (0.55 * lineAvg(Pos.att) + 0.45 * lineAvg(Pos.mid)) *
      (1 + 0.03 * (mentality - 2)) *
      pow(max(1, count(Pos.att)) / 2, 0.25) *
      _form *
      _man;

  double get defensePower =>
      (0.6 * lineAvg(Pos.def) + 0.25 * lineAvg(Pos.mid) + 0.15 * lineAvg(Pos.gk)) *
      (1 - 0.025 * (mentality - 2)) *
      pow(max(1, count(Pos.def)) / 4, 0.3) *
      _form *
      _man;

  double get midPower =>
      lineAvg(Pos.mid) *
      (1 + 0.04 * (team.pressing - 1)) *
      (1 - 0.03 * (team.passing - 1)) *
      (1 + 0.025 * (team.defLine - 1)) *
      pow(max(1, count(Pos.mid)) / 4, 0.35) *
      _form *
      _man;
}

class MatchSim {
  final Side home, away;
  final Random rng;
  int minute = 0;
  final List<MatchEvent> events = [];

  /// يُستدعى عند كل هدف: المسجّل، صانع الهدف (إن وُجد)، وفريقه — لتسجيل إحصاءات كل بطولة
  void Function(Player shooter, Player? assister, Team team)? onGoal;

  /// موضع الكرة: x من 0 إلى 1 عرضاً، y من 0 (مرمى الضيف أعلى) إلى 1 (مرمى المضيف أسفل)
  double ballX = 0.5, ballY = 0.5;
  bool attackHome = true;

  /// الحكم: 0.75 متساهل … 1.3 صارم. والطقس: صافٍ/ممطر/حار/رياح
  late final double refStrict = 0.75 + rng.nextDouble() * 0.55;
  late final String weather = () {
    final r = rng.nextDouble();
    return r < 0.62 ? 'clear' : r < 0.78 ? 'rain' : r < 0.9 ? 'hot' : 'wind';
  }();
  String get weatherText => switch (weather) { 'rain' => '🌧 أجواء ممطرة', 'hot' => '☀️ حرارة مرتفعة', 'wind' => '💨 رياح قوية', _ => '⛅ طقس معتدل' };
  String get refText => refStrict > 1.12 ? 'حكم صارم' : refStrict < 0.9 ? 'حكم متساهل' : 'حكم متوازن';

  MatchSim(Team h, Team a,
      {bool userHome = false, bool userAway = false, Random? random})
      : home = Side(h, true, userHome),
        away = Side(a, false, userAway),
        rng = random ?? Random();

  bool get finished => minute >= 90;

  int get homePoss =>
      minute == 0 ? 50 : (home.poss * 100 / minute).round().clamp(0, 100).toInt();
  int get awayPoss => 100 - homePoss;

  String get lastText => events.isEmpty ? 'صافرة البداية' : events.last.text;

  (Player, Side, double)? get manOfMatch {
    (Player, Side, double)? best;
    for (final s in [home, away]) {
      s.ratings.forEach((p, r) {
        if (best == null || r > best!.$3) best = (p, s, r);
      });
    }
    return best;
  }

  void _log(String type, String text, bool isHome, {bool major = true}) =>
      events.add(MatchEvent(minute, type, text, isHome, major: major));

  T _weighted<T>(List<T> items, List<double> w) {
    final total = w.fold(0.0, (a, b) => a + b);
    var r = rng.nextDouble() * total;
    for (var i = 0; i < items.length; i++) {
      r -= w[i];
      if (r <= 0) return items[i];
    }
    return items.last;
  }

  void _setBall(Side a, double prog, double spread) {
    final y = 0.62 - 0.54 * prog;
    ballY = a.isHome ? y : 1 - y;
    ballX = (0.5 + (rng.nextDouble() - 0.5) * spread).clamp(0.12, 0.88).toDouble();
  }

  Player? _gk(Side s) {
    final l = s.slots.where((x) => x.pos == Pos.gk).toList();
    return l.isEmpty ? null : l.first.p;
  }

  void simulateAll() {
    while (!finished) {
      step();
    }
  }

  void step() {
    if (finished) return;
    minute++;
    if (minute == 1) {
      _log('info', '🟢 صافرة البداية', true, major: false);
      _log('info', '$weatherText • $refText', true, major: false);
    }

    for (final s in [home, away]) {
      final f = 0.2 *
          (1 +
              0.3 * (s.team.pressing - 1) +
              0.2 * (s.team.tempo - 1) +
              0.1 * (s.team.defLine - 1));
      final wf = weather == 'hot' ? 1.25 : weather == 'rain' ? 1.08 : 1.0;
      for (final sl in s.slots) {
        sl.p.fitness = max(0, sl.p.fitness - f * wf);
        sl.p.load = min(100, sl.p.load + 0.14 * wf);
      }
    }

    for (final s in [home, away]) {
      if (s.isUser) continue;
      final o = identical(s, home) ? away : home;
      s.mentalityBoost = 0;
      if (minute > 70 && s.goals < o.goals) s.mentalityBoost = 2;
      if (minute > 75 && s.goals > o.goals) s.mentalityBoost = -2;
      if (minute == 56 || minute == 66 || minute == 76) _aiSub(s);
    }

    final hm = home.midPower * 1.07;
    final am = away.midPower;
    final ph = pow(hm, 3) / (pow(hm, 3) + pow(am, 3));
    final homeAtt = rng.nextDouble() < ph;
    final a = homeAtt ? home : away;
    final d = homeAtt ? away : home;
    a.poss++;
    // تمريرات الاستحواذ: العدد يتبع أسلوب التمرير، والدقة تتبع مهارة اللاعبين
    final k = 5 + rng.nextInt(6) + (a.team.passing - 1);
    final okRate = (0.58 + 0.0042 * a.passSkill - 0.02 * (a.team.passing - 1) - 0.012 * (d.team.pressing - 1) - (weather == 'rain' ? 0.03 : weather == 'wind' ? 0.015 : 0)).clamp(0.55, 0.93);
    var ok = 0;
    for (var i = 0; i < k; i++) {
      if (rng.nextDouble() < okRate) ok++;
    }
    a.passes += k;
    a.passOk += ok;
    // نسب التمريرات للاعبين (الوسط والخلف أكثر تمريراً)
    final pc = a.slots.where((x) => x.pos != Pos.gk || rng.nextDouble() < 0.3).toList();
    if (pc.isNotEmpty) {
      final c1 = _weighted(pc, pc.map((x) => x.p.pas * (x.pos == Pos.mid ? 1.6 : x.pos == Pos.def ? 1.2 : 0.8)).toList()).p;
      final st = a.ps(c1);
      st.passes += k;
      st.passOk += ok;
    }
    // تدخل دفاعي للخصم
    if (rng.nextDouble() < 0.33) {
      final dc = d.slots.where((x) => x.pos != Pos.gk).toList();
      if (dc.isNotEmpty) {
        final tp = _weighted(dc, dc.map((x) => x.p.def * (x.pos == Pos.def ? 2.0 : x.pos == Pos.mid ? 1.3 : 0.5)).toList()).p;
        d.ps(tp).tackles++;
      }
    }
    if (rng.nextDouble() < 0.05 * (1 + 0.2 * (d.team.defLine - 1))) a.offsides++;
    attackHome = a.isHome;
    _setBall(a, rng.nextDouble() * 0.75, 0.85);

    final ratio = a.attackPower / max(1, d.defensePower);
    // عرض اللعب والتمرير المباشر يزيدان عدد الفرص، وخط دفاع الخصم المرتفع يترك مساحات خلفه
    final pShot = (0.27 *
            pow(ratio, 1.3) *
            (1 + 0.08 * (a.team.tempo - 1)) *
            (1 + 0.05 * (a.team.width - 1)) *
            (1 + 0.06 * (a.team.passing - 1)) *
            (1 + 0.07 * (d.team.defLine - 1)) *
            _matchup(a, d))
        .clamp(0.05, 0.6)
        .toDouble();
    if (rng.nextDouble() < pShot) {
      _shot(a, d);
    } else if (rng.nextDouble() < 0.0045 * refStrict) {
      _penalty(a, d);
    }

    _discipline(d);
    // خطر الإصابة يرتفع مع إرهاق التشكيلة (متوسط اللياقة)
    double tire(Side x) => x.slots.isEmpty ? 0.0 : 1 - x.slots.fold<double>(0, (a, e) => a + e.p.fitness) / (100.0 * x.slots.length);
    double ld(Side x) => x.slots.isEmpty ? 0.0 : x.slots.fold<double>(0, (a, e) => a + e.p.load) / (100.0 * x.slots.length);
    final hs = 1 + 1.6 * tire(home) + 1.2 * ld(home), as = 1 + 1.6 * tire(away) + 1.2 * ld(away);
    if (rng.nextDouble() < 0.0012 * (hs + as) / 2) _injury(rng.nextDouble() * (hs + as) < hs ? home : away);

    if (minute == 60) _insights();
    if (minute == 45) _log('info', '⏸ نهاية الشوط الأول', true);
    if (minute == 90) {
      _finalRatings();
      _log('info', '🏁 نهاية المباراة', true);
    }
  }

  /// خطة ضد خطة: اللعب العريض يستغل ثلاثي الدفاع ويتعثر أمام الخماسي، والكتلة المنخفضة تُصعّب التمرير القصير
  double _matchup(Side a, Side d) {
    var m = 1.0;
    final back = d.count(Pos.def);
    if (a.team.width >= 2) m *= back >= 5 ? 0.92 : (back <= 3 ? 1.08 : 1.0);
    if (a.team.width == 0) m *= back <= 3 ? 0.95 : 1.02;
    if (d.team.defLine == 0 && a.team.passing == 0) m *= 0.9;
    if (d.team.defLine == 0 && a.team.passing == 2 && a.team.tempo >= 2) m *= 0.97;
    if (d.team.pressing >= 2 && a.team.passing == 0 && a.passSkill < 62) m *= 0.94;
    final mid = a.count(Pos.mid) - d.count(Pos.mid);
    m *= 1 + 0.015 * mid.clamp(-2, 2);
    return m;
  }

  /// ملاحظات تكتيكية للمدرب عند الدقيقة 60
  void _insights() {
    for (final s in [home, away]) {
      if (!s.isUser || s.slots.isEmpty) continue;
      final o = identical(s, home) ? away : home;
      final fit = s.slots.fold<double>(0, (a, e) => a + e.p.fitness) / s.slots.length;
      if (fit < 68 && (s.team.pressing >= 2 || s.team.tempo >= 2)) {
        _log('info', '💡 الضغط والإيقاع العاليان أنهكا لاعبيك (لياقة ${fit.round()}%). فكّر بالتبديل أو خفض الضغط', s.isHome, major: false);
      }
      if (o.team.defLine == 2 && s.team.passing == 2) {
        _log('info', '💡 خط دفاع الخصم مرتفع: الكرات المباشرة خلفه فعّالة', s.isHome, major: false);
      }
      if (o.team.defLine == 0 && s.team.passing == 0) {
        _log('info', '💡 الخصم متراجع بكتلة منخفضة: جرّب الكرات المباشرة أو اللعب العريض', s.isHome, major: false);
      }
      if (s.team.width >= 2 && o.count(Pos.def) >= 5) {
        _log('info', '💡 دفاع الخصم بخمسة مدافعين يخنق الأطراف: ضيّق اللعب أو ادفع بمهاجم إضافي', s.isHome, major: false);
      }
    }
  }

  void _finalRatings() {
    for (final s in [home, away]) {
      final o = identical(s, home) ? away : home;
      final res = s.goals > o.goals ? 0.4 : (s.goals < o.goals ? -0.3 : 0.0);
      for (final e in s.perf.entries) {
        final st = e.value;
        var v = 0.0;
        if (st.passes >= 12) v += ((st.passOk / st.passes) - 0.78) * 1.6;
        v += 0.22 * min(st.keyPasses, 4) + 0.1 * st.onTarget - 0.03 * (st.shots - st.onTarget);
        v += 0.1 * min(st.tackles, 8) + 0.22 * min(st.saves, 7);
        s.bump(e.key, v);
      }
      for (final sl in s.slots) {
        s.bump(sl.p, res);
        final back = sl.pos == Pos.gk || sl.pos == Pos.def;
        if (o.goals == 0 && back) s.bump(sl.p, 0.5);
        if (o.goals >= 3 && back) s.bump(sl.p, -0.4);
      }
      s.ratings.forEach((p, r) {
        p.ratingSum += r;
        p.rated++;
      });
    }
  }

  void _shot(Side a, Side d) {
    final cands = a.slots.where((s) => s.pos != Pos.gk).toList();
    if (cands.isEmpty) return;
    final w = cands
        .map((s) =>
            (s.pos == Pos.att ? 5.0 : s.pos == Pos.mid ? 2.0 : 0.6) *
            s.p.atk *
            (0.5 + 0.5 * s.p.fitness / 100))
        .toList();
    final shooter = _weighted(cands, w).p;
    a.shots++;
    a.ps(shooter).shots++;
    final creators = cands.where((x) => x.p != shooter).toList();
    if (creators.isNotEmpty && rng.nextDouble() < 0.65) {
      a.ps(_weighted(creators, creators.map((x) => x.p.pas.toDouble()).toList()).p).keyPasses++;
    }
    _setBall(a, 0.95, 0.45);
    final gkP = _gk(d);
    final gks = d.slots.where((s) => s.pos == Pos.gk).toList();
    final gkR = gks.isEmpty ? 30.0 : gks.first.rate;
    final q = shooter.atk * (0.7 + 0.3 * shooter.fitness / 100);

    final onT = (0.36 +
            0.004 * (q - 65) -
            0.025 * (a.team.width - 1) -
            0.02 * (a.team.passing - 1))
        .clamp(0.2, 0.6);
    // جودة الفرصة: فرصة محققة (12%) ، قريبة (25%) ، بعيدة/ضغط (63%)
    final cr = rng.nextDouble();
    final big = cr < 0.12;
    final qf = big ? 2.3 : (cr < 0.37 ? 1.25 : 0.68);
    final xgShot = (0.255 * pow(q / max(20, gkR), 1.4) * qf).clamp(0.03, 0.85).toDouble();
    final onTf = big ? (onT + 0.12).clamp(0.2, 0.8).toDouble() : onT.toDouble();
    a.xg += onTf * xgShot;
    if (big) a.bigChances++;
    if (rng.nextDouble() > onTf) {
      if (big) {
        a.bigMissed++;
        a.bump(shooter, -0.25);
        _log('miss', '😱 ${shooter.name} يهدر فرصة محققة!', a.isHome);
      }
      if (!big && rng.nextDouble() < 0.35) {
        _log('miss', '${shooter.name} يسدد بعيداً عن المرمى', a.isHome,
            major: false);
      }
      if (rng.nextDouble() < 0.38) _corner(a);
      return;
    }
    a.onTarget++;
    a.ps(shooter).onTarget++;
    final pg = xgShot;
    if (rng.nextDouble() < pg) {
      // مراجعة الفيديو: أحياناً يُلغى الهدف (تسلل أو خطأ قبله)
      if (rng.nextDouble() < 0.035) {
        _log('info', '📺 VAR: مراجعة هدف ${shooter.name}...', a.isHome);
        if (rng.nextDouble() < 0.6) {
          a.onTarget--;
          a.offsides++;
          _log('miss', '🚫 أُلغي الهدف بعد مراجعة الفيديو (تسلل)', a.isHome);
          return;
        }
        _log('info', '✅ VAR يؤكد الهدف', a.isHome, major: false);
      }
      a.goals++;
      shooter.goals++;
      a.bump(shooter, 1.2);
      if (gkP != null) d.bump(gkP, -0.3);
      Player? assister;
      if (rng.nextDouble() < 0.7) {
        final c = a.slots.where((s) => s.p != shooter && s.pos != Pos.gk).toList();
        if (c.isNotEmpty) {
          assister = _weighted(c, c.map((s) => s.p.pas.toDouble()).toList()).p;
          assister.assists++;
          a.bump(assister, 0.6);
        }
      }
      onGoal?.call(shooter, assister, a.team);
      ballX = 0.5;
      ballY = a.isHome ? 0.01 : 0.99;
      _log(
          'goal',
          '⚽ هدف! ${shooter.name}${assister != null ? ' (تمريرة ${assister.name})' : ''}',
          a.isHome);
    } else {
      if (big) a.bigMissed++;
      if (gkP != null) {
        d.bump(gkP, big ? 0.7 : 0.4);
        d.ps(gkP).saves++;
      }
      if (rng.nextDouble() < 0.55) _corner(a);
      if (rng.nextDouble() < 0.6) {
        _log('save', '🧤 تصدٍّ رائع لتسديدة ${shooter.name}', a.isHome,
            major: false);
      }
    }
  }

  void _corner(Side a) {
    a.corners++;
    _log('info', '🚩 ركنية لصالح ${a.team.name}', a.isHome, major: false);
  }

  void _penalty(Side a, Side d) {
    final att = a.slots.where((s) => s.pos != Pos.gk).toList();
    if (att.isEmpty) return;
    att.sort((x, y) => y.p.atk.compareTo(x.p.atk));
    final shooter = att.first.p;
    a.shots++;
    ballX = 0.5;
    ballY = a.isHome ? 0.12 : 0.88;
    _log('penalty', '⚠️ ركلة جزاء لصالح ${a.team.name}!', a.isHome);
    final gkP = _gk(d);
    final p = (0.72 + 0.003 * (shooter.atk - 70)).clamp(0.55, 0.9);
    a.xg += p;
    if (rng.nextDouble() < p) {
      a.onTarget++;
      a.goals++;
      shooter.goals++;
      onGoal?.call(shooter, null, a.team);
      a.bump(shooter, 1.0);
      if (gkP != null) d.bump(gkP, -0.3);
      ballY = a.isHome ? 0.01 : 0.99;
      _log('goal', '⚽ هدف من ركلة جزاء! ${shooter.name}', a.isHome);
    } else {
      a.bump(shooter, -0.8);
      if (gkP != null) d.bump(gkP, 0.6);
      _log('miss', '❌ ${shooter.name} يهدر ركلة الجزاء!', a.isHome);
    }
  }

  void _discipline(Side d) {
    if (d.slots.isEmpty) return;
    if (rng.nextDouble() < 0.24 * refStrict * (1 + 0.25 * (d.team.pressing - 1))) d.fouls++;
    if (rng.nextDouble() < 0.04 * refStrict * (1 + 0.4 * (d.team.pressing - 1))) {
      final c = d.slots.where((s) => s.pos != Pos.gk).toList();
      if (c.isEmpty) return;
      final sl = _weighted(
          c,
          c
              .map((s) => (s.pos == Pos.def ? 3.0 : s.pos == Pos.mid ? 2.5 : 1.0) * (s.p.trait == 'متقلب' ? 1.8 : 1.0) * ((d.yellowCount[s.p.id] ?? 0) > 0 ? 0.2 : 1.0))
              .toList());
      final p = sl.p;
      final n = (d.yellowCount[p.id] ?? 0) + 1;
      d.yellowCount[p.id] = n;
      p.yellows++;
      d.bump(p, -0.3);
      if (n >= 2) {
        _log('yellow', '🟨 إنذار ثانٍ للاعب ${p.name}', d.isHome);
        _sendOff(d, sl, 'إنذار ثانٍ وطرد', 1);
      } else {
        _log('yellow', '🟨 إنذار للاعب ${p.name}', d.isHome);
        if (p.yellows % 5 == 0) {
          p.suspendedMatches = max(p.suspendedMatches, p.yellows >= 10 ? 2 : 1);
          _log('info', '⛔ ${p.name} بلغ ${p.yellows} إنذارات ويغيب عن المباراة القادمة', d.isHome, major: false);
        }
      }
    }
    if (rng.nextDouble() < 0.00018) {
      final c = d.slots.where((s) => s.pos != Pos.gk).toList();
      if (c.isNotEmpty) {
        _sendOff(d, c[rng.nextInt(c.length)], 'بطاقة حمراء مباشرة', 2);
      }
    }
  }

  void _sendOff(Side d, Slot sl, String why, int games) {
    d.bump(sl.p, -1.5);
    d.slots.remove(sl);
    d.out.add(sl.p);
    sl.p.suspendedMatches = max(sl.p.suspendedMatches, games);
    _log('red', '🟥 $why: ${sl.p.name}! الفريق يكمل بعشرة لاعبين', d.isHome);
  }

  void _injury(Side s) {
    if (s.slots.isEmpty) return;
    // الأكثر إرهاقاً والأكبر سناً ومن تكررت إصاباته أكثر عرضة
    double risk(Player x) => (110 - x.fitness) * (x.age >= 31 ? 1.5 : x.age >= 28 ? 1.2 : 1.0) * (1 + 0.12 * min(x.injuryCount, 5)) * (1 + x.load / 70);
    final sl = _weighted(s.slots, s.slots.map((x) => risk(x.p)).toList());
    final p = sl.p;
    final old = p.age >= 31 ? 2 : p.age >= 28 ? 1 : 0;
    // نوع الإصابة: الإرهاق يزيد الشدّ العضلي والأوتار؛ الاحتكاك يسبّب الكاحل والركبة والكدمات
    final lf = p.load / 100;
    final kinds = <(String, double, int, int)>[
      ('شد عضلي', 26 + 30 * lf, 1, 4),
      ('إصابة الأوتار الخلفية', 12 + 16 * lf, 2, 6),
      ('التواء الكاحل', 18, 1, 5),
      ('كدمة قوية', 14, 1, 2),
      ('ارتجاج', 3, 1, 2),
      ('إصابة الركبة', 7, 4, 12),
      ('كسر', 2.5, 6, 12),
      ('تمزق الرباط الصليبي', 1.1 + 0.6 * lf, 24, 40),
    ];
    var r = rng.nextDouble() * kinds.fold<double>(0, (a, e) => a + e.$2);
    var kind = kinds.first;
    for (final k in kinds) {
      r -= k.$2;
      if (r < 0) {
        kind = k;
        break;
      }
    }
    p.injType = kind.$1;
    p.injuredWeeks = kind.$3 + rng.nextInt(kind.$4 - kind.$3 + 1) + (kind.$4 <= 6 ? old : old * 2) + (rng.nextDouble() < 0.03 * min(p.injuryCount, 4) ? 2 : 0);
    if (kind.$4 >= 40) {
      // الرباط الصليبي يترك أثراً دائماً خفيفاً على القدرات
      int d(int v) => max(20, v - 1 - rng.nextInt(3));
      p
        ..atk = d(p.atk)
        ..def = d(p.def)
        ..pas = d(p.pas);
    }
    p.injuryCount++;
    _log('injury', '🚑 إصابة ${p.name} — ${kind.$1} (${p.injuredWeeks} أسابيع)', s.isHome);
    Player? rep;
    if (s.subsLeft > 0) {
      final same = s.bench.where((b) => b.pos == sl.pos).toList();
      final other =
          s.bench.where((b) => b.pos != Pos.gk && sl.pos != Pos.gk).toList();
      rep = same.isNotEmpty ? same.first : (other.isNotEmpty ? other.first : null);
    }
    s.out.add(p);
    if (rep == null) {
      s.slots.remove(sl);
    } else {
      _doSub(s, sl, rep);
    }
  }

  void _doSub(Side s, Slot sl, Player inP) {
    s.subsLeft--;
    s.out.add(sl.p);
    _log('sub', '🔄 يدخل ${inP.name} بدلاً من ${sl.p.name}', s.isHome);
    sl.p = inP;
    inP.apps++;
    s.ratings.putIfAbsent(inP, () => 6.0);
  }

  void _aiSub(Side s) {
    if (s.subsLeft <= 0) return;
    final tired = s.slots.where((x) => x.pos != Pos.gk).toList()
      ..sort((a, b) => a.p.fitness.compareTo(b.p.fitness));
    if (tired.isEmpty || tired.first.p.fitness > 78) return;
    final sl = tired.first;
    final bs = s.bench.where((b) => b.pos == sl.pos).toList();
    if (bs.isEmpty) return;
    _doSub(s, sl, bs.first);
  }

  bool substitute(Side s, Player outP, Player inP) {
    if (s.subsLeft <= 0 || finished) return false;
    final l = s.slots.where((x) => x.p == outP).toList();
    if (l.isEmpty || !s.bench.contains(inP)) return false;
    _doSub(s, l.first, inP);
    return true;
  }

  /// حديث الاستراحة: 0 تشجيع، 1 تحدٍّ (مخاطرة)، 2 تهدئة
  String teamTalk(Side s, int kind) {
    final o = identical(s, home) ? away : home;
    final trailing = s.goals < o.goals;
    var msg = '';
    for (final sl in s.slots) {
      final p = sl.p;
      switch (kind) {
        case 0:
          p.morale = (p.morale + (trailing ? 7 : 4)).clamp(20, 100).toDouble();
        case 1:
          p.morale = (p.morale + (rng.nextDouble() < 0.6 ? 8 : -6)).clamp(20, 100).toDouble();
        default:
          p.morale = (p.morale + 2).clamp(20, 100).toDouble();
          p.fitness = (p.fitness + 3).clamp(0, 100).toDouble();
      }
    }
    msg = switch (kind) {
      0 => 'شجّعت اللاعبين وبثثت فيهم الثقة 👏',
      1 => 'تحدّيت اللاعبين… لنرَ كيف سيستجيبون 🔥',
      _ => 'هدّأت الأجواء وطلبت التركيز 🧘',
    };
    return msg;
  }
}
