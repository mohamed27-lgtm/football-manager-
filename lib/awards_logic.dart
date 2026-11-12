part of 'game_state.dart';

/// بيانات الجوائز: العنوان، الرمز، المكافأة المالية (M)، المعنويات، زيادة القيمة السوقية (M)
class AwardInfo {
  final String title, icon, desc;
  final double money, value;
  final int morale;
  const AwardInfo(this.title, this.icon, this.desc, this.money, this.morale, this.value);
}

const kAwardInfo = <String, AwardInfo>{
  'bd': AwardInfo('الكرة الذهبية', '⚽', 'أفضل لاعب في العالم هذا الموسم', 0.5, 10, 4),
  'boot': AwardInfo('الحذاء الذهبي', '👟', 'هدّاف الموسم', 0.3, 8, 3),
  'glove': AwardInfo('القفاز الذهبي', '🧤', 'أفضل حارس مرمى', 0.25, 8, 2),
  'kopa': AwardInfo('أفضل لاعب شاب', '⭐', 'تحت 21 سنة', 0.2, 6, 5),
  'pm': AwardInfo('أفضل صانع ألعاب', '🎯', 'الأكثر تمريرات حاسمة', 0.2, 6, 2),
  'def': AwardInfo('أفضل مدافع', '🛡️', 'مدافع الموسم', 0.2, 6, 2),
  'mid': AwardInfo('أفضل لاعب وسط', '🧠', 'وسط الموسم', 0.2, 6, 2),
  'att': AwardInfo('أفضل مهاجم', '🔥', 'مهاجم الموسم', 0.2, 6, 2),
  'coach': AwardInfo('مدرب العام', '🎖️', 'أفضل مدرب في الموسم', 0, 0, 0),
  'club': AwardInfo('نادي العام', '🏟️', 'أفضل نادٍ في الموسم', 1.0, 0, 0),
  'nation': AwardInfo('أفضل منتخب', '🌍', 'أفضل منتخب في التصنيف العالمي', 0, 0, 0),
  'xi': AwardInfo('فريق الموسم', '👕', 'التشكيلة المثالية 4-3-3', 0.1, 4, 1),
};

extension SeasonCeremony on GameState {
  void estimateOtherStats() {
    // نجوم الأندية القارية والدرجات الأخرى: نقدّر إحصاءاتهم لأنهم لا يلعبون في دوريك
    for (final t in [...foreign.values.where((x) => x.id < 3000), ...upper, ...lower]) {
      for (final p in t.squad) {
        if (p.apps > 0 || p.overall < 66) continue;
        final q = (p.overall - 60).clamp(0, 30) / 30.0;
        p.apps = 22 + rng.nextInt(14);
        switch (p.pos) {
          case Pos.att:
            p.goals = (q * 26 * (0.55 + rng.nextDouble() * 0.6)).round();
            p.assists = (q * 11 * rng.nextDouble()).round();
          case Pos.mid:
            p.goals = (q * 11 * rng.nextDouble()).round();
            p.assists = (q * 14 * (0.4 + rng.nextDouble() * 0.6)).round();
          case Pos.def:
            p.goals = (q * 4 * rng.nextDouble()).round();
            p.assists = (q * 5 * rng.nextDouble()).round();
          case Pos.gk:
            break;
        }
      }
    }
  }

  void ensureCeremony() {
    if (ceremony != null && ceremony!['s'] == season) return;
    ceremony = _buildCeremony();
  }

  /// نسب التصويت: تتناسب مع قوة الملف، ومجموعها 100
  List<int> _shares(List<double> scores) {
    if (scores.isEmpty) return [];
    final mn = scores.reduce(min);
    final w = [for (final s in scores) pow(s - mn + 1.5, 2.2).toDouble()];
    final tot = w.fold<double>(0, (a, b) => a + b);
    final v = [for (final x in w) (x * 100 / tot).round()];
    v[0] += 100 - v.fold<int>(0, (a, b) => a + b);
    return v;
  }

  Map<String, dynamic> _nomP(Player p, Team t) => {
        'k': 'p',
        'id': p.id,
        'n': p.name,
        'c': t.name,
        't': t.id,
        'nat': p.nat,
        'pos': p.pos.index,
        'ov': p.overall,
        'g': p.goals,
        'a': p.assists,
        'r': double.parse((p.avgRating == 0 ? 6.0 + (p.overall - 60) / 20 : p.avgRating).toStringAsFixed(1)),
        'age': p.age,
        'm': t == user,
      };

  Map<String, dynamic> _buildCeremony() {
    estimateOtherStats();
    final tb = table;
    int rankOf(Team t) => tb.indexOf(t) + 1;
    final all = <(Player, Team)>[
      for (final t in [...teams, ...foreign.values.where((x) => x.id < 3000)])
        for (final p in t.squad)
          if (p.apps > 0) (p, t)
    ];
    double sc((Player, Team) e) {
      final r = rankOf(e.$2);
      final eloBonus = (eloOf(e.$2) - 1500) / 40.0;
      return e.$1.goals * 2.0 + e.$1.assists * 1.5 + e.$1.overall * 0.25 + (r == 0 ? eloBonus : (teams.length - r) * 0.2);
    }

    final awards = <Map<String, dynamic>>[];
    void player(String id, Iterable<(Player, Team)> src, double Function((Player, Team)) f) {
      final l = src.toList()..sort((a, b) => f(b).compareTo(f(a)));
      if (l.isEmpty) return;
      final top = l.take(3).toList();
      final v = _shares([for (final e in top) f(e)]);
      awards.add({
        'id': id,
        'rev': false,
        'nom': [
          for (var i = 0; i < top.length; i++) {..._nomP(top[i].$1, top[i].$2), 'v': v[i]}
        ],
      });
    }

    player('bd', all, sc);
    player('boot', all, (e) => e.$1.goals * 100.0 + e.$1.assists + e.$1.overall * 0.01);
    player('glove', all.where((e) => e.$1.pos == Pos.gk), (e) => e.$1.gk - e.$2.ga * 0.5);
    player('kopa', all.where((e) => e.$1.age <= 21), sc);
    player('pm', all, (e) => e.$1.assists * 100.0 + e.$1.goals + e.$1.overall * 0.01);
    player('def', all.where((e) => e.$1.pos == Pos.def), (e) => sc(e) + e.$1.overall * 0.4 - e.$2.ga * 0.05);
    player('mid', all.where((e) => e.$1.pos == Pos.mid), sc);
    player('att', all.where((e) => e.$1.pos == Pos.att), (e) => e.$1.goals * 2.0 + e.$1.assists + e.$1.overall * 0.2);

    // مدرب العام: أكبر تفوق على ترتيب القوة
    final byStrength = [...teams]..sort((a, b) => b.strength.compareTo(a.strength));
    final gain = <Team, double>{
      for (final t in teams) t: ((byStrength.indexOf(t) + 1) - rankOf(t)).toDouble() + (rankOf(t) == 1 ? 3 : 0) + t.points / max(1, t.played) * 0.5,
    };
    final coaches = [...teams]..sort((a, b) => gain[b]!.compareTo(gain[a]!));
    final cv = _shares([for (final t in coaches.take(3)) gain[t]!]);
    awards.add({
      'id': 'coach',
      'rev': false,
      'nom': [
        for (var i = 0; i < min(3, coaches.length); i++)
          {
            'k': 'c',
            'n': coaches[i].coachName,
            'c': coaches[i].name,
            't': coaches[i].id,
            'm': coaches[i] == user,
            'v': cv[i],
            'st': [
              ['فوز', '${coaches[i].won}'],
              ['نقطة', '${coaches[i].points}'],
              ['المركز', '${rankOf(coaches[i])}'],
            ],
          }
      ],
    });

    // نادي العام: الدوري + الكؤوس + البطولات القارية
    final cands = <Team, double>{};
    for (final t in teams) {
      var s = t.points / max(1, t.played) * 10;
      if (domestic?.champion == t.id) s += 4;
      cands[t] = s;
    }
    for (final e in [(continental, 32.0), (europa, 28.0), (conference, 26.0), (cwc, 36.0), (ic, 30.0)]) {
      final c = e.$1?.champion;
      if (c == null) continue;
      final t = team(c);
      cands[t] = max(cands[t] ?? 0, e.$2) + (teams.contains(t) ? 6 : 0);
    }
    final clubs = cands.keys.toList()..sort((a, b) => cands[b]!.compareTo(cands[a]!));
    final bv = _shares([for (final t in clubs.take(3)) cands[t]!]);
    if (clubs.isNotEmpty) {
      awards.add({
        'id': 'club',
        'rev': false,
        'nom': [
          for (var i = 0; i < min(3, clubs.length); i++)
            {
              'k': 'b',
              'n': clubs[i].name,
              'c': 'قوة ${clubs[i].strength.round()}',
              't': clubs[i].id,
              'm': clubs[i] == user,
              'v': bv[i],
              'st': [
                ['هدف', '${clubs[i].gf}'],
                ['نقطة', '${clubs[i].points}'],
                ['القوة', '${clubs[i].strength.round()}'],
              ],
            }
        ],
      });
    }

    // أفضل منتخب: أعلى التصنيف العالمي
    ensureNat();
    final rk = nat.ranking;
    if (rk.isNotEmpty && nat.rating(rk.first) > 0) {
      final top = rk.take(3).toList();
      final nv = _shares([for (final n in top) nat.rating(n) / 100]);
      awards.add({
        'id': 'nation',
        'rev': false,
        'nom': [
          for (var i = 0; i < top.length; i++)
            {
              'k': 'n',
              'n': top[i],
              'c': 'منتخب',
              't': -1,
              'nat': top[i],
              'm': false,
              'v': nv[i],
              'st': [
                ['الاتحاد', (nat.conf[top[i]] ?? '').toUpperCase()],
                ['المركز', '${i + 1}'],
                ['النقاط', nat.rating(top[i]).round().toString()],
              ],
            }
        ],
      });
    }

    // فريق الموسم 4-3-3
    final xi = <Map<String, dynamic>>[];
    for (final e in const [(Pos.gk, 1), (Pos.def, 4), (Pos.mid, 3), (Pos.att, 3)]) {
      final l = all.where((x) => x.$1.pos == e.$1).toList()..sort((a, b) => sc(b).compareTo(sc(a)));
      xi.addAll(l.take(e.$2).map((x) => _nomP(x.$1, x.$2)));
    }
    if (xi.length == 11) awards.add({'id': 'xi', 'rev': false, 'nom': xi});
    return {'s': season, 'paid': false, 'a': awards};
  }

  Player? playerById(int id) {
    for (final t in [...teams, ...upper, ...lower, ...foreign.values]) {
      for (final p in t.squad) {
        if (p.id == id) return p;
      }
    }
    return null;
  }

  /// يُنفَّذ عند بدء الموسم الجديد: يسجّل الجوائز على اللاعبين والألقاب والأخبار
  List<String> _applyCeremony() {
    final out = <String>[];
    final c = ceremony;
    if (c == null) return out;
    for (final a in (c['a'] as List)) {
      final id = a['id'] as String;
      final info = kAwardInfo[id]!;
      final noms = (a['nom'] as List).cast<Map>();
      final w = noms.first;
      if (id == 'xi') {
        var mine = 0;
        for (final n in noms) {
          final p = playerById(n['id'] as int);
          p?.awards.add({'s': season, 'c': info.title, 'k': 'indiv'});
          if (n['m'] == true) mine++;
        }
        out.add('⭐ التشكيلة المثالية: ${noms.map((n) => n['n']).join('، ')}');
        if (mine > 0) {
          honours.add('${info.title} — $mine من لاعبيك (الموسم $season)');
          news.insert(0, '⭐ $mine من لاعبيك في فريق الموسم!');
        }
        continue;
      }
      final isMine = w['m'] == true;
      switch (w['k']) {
        case 'p':
          final p = playerById(w['id'] as int);
          p?.awards.add({'s': season, 'c': info.title, 'k': 'indiv'});
          final extra = switch (id) {
            'boot' => ' — ${w['g']} هدف',
            'pm' => ' — ${w['a']} تمريرة حاسمة',
            'bd' => ' — ${w['g']} هدف',
            _ => '',
          };
          out.add('${info.icon} ${info.title}: ${w['n']} (${w['c']})$extra');
          if (isMine) {
            honours.add('${info.title} — ${w['n']} (الموسم $season)');
            fans = min(100, fans + 3);
            news.insert(0, '🥇 ${info.title} لاعبك ${w['n']}!');
          }
        case 'c':
          out.add('🎖️ مدرب العام: ${w['n']}');
          if (isMine) {
            honours.add('🎖️ مدرب العام — الموسم $season');
            confidence = min(100, confidence + 6);
            news.insert(0, '🎖️ اخترت مدرب العام!');
          }
        case 'b':
          out.add('🏟️ نادي العام: ${w['n']}');
          if (isMine) {
            honours.add('🏟️ نادي العام — الموسم $season');
            fans = min(100, fans + 5);
            news.insert(0, '🏟️ ناديك هو نادي العام!');
          }
        case 'n':
          out.add('🌍 أفضل منتخب: ${w['n']}');
      }
    }
    return out;
  }

  /// ما يربحه المستخدم من الجوائز: [(الجائزة، اللاعب أو null، المال، المعنويات، القيمة)]
  List<({String id, int? pid, String name, double money, int morale, double value})> myAwardWins() {
    final c = ceremony;
    if (c == null) return [];
    final out = <({String id, int? pid, String name, double money, int morale, double value})>[];
    for (final a in (c['a'] as List)) {
      final id = a['id'] as String;
      final info = kAwardInfo[id]!;
      final noms = (a['nom'] as List).cast<Map>();
      if (id == 'xi') {
        for (final n in noms) {
          if (n['m'] == true) out.add((id: id, pid: n['id'] as int, name: n['n'] as String, money: info.money, morale: info.morale, value: info.value));
        }
      } else if (noms.first['m'] == true) {
        out.add((id: id, pid: noms.first['k'] == 'p' ? noms.first['id'] as int : null, name: noms.first['n'] as String, money: info.money, morale: info.morale, value: info.value));
      }
    }
    return out;
  }

  /// استلام المكافآت: مال + معنويات + ارتفاع القيمة السوقية
  void claimAwardRewards() {
    final c = ceremony;
    if (c == null || c['paid'] == true) return;
    var total = 0.0;
    for (final w in myAwardWins()) {
      total += w.money;
      final p = w.pid == null ? null : user.squad.where((x) => x.id == w.pid).firstOrNull;
      if (p != null) {
        p.morale = min(100, p.morale + w.morale);
        p.awardBoost += w.value;
      }
    }
    if (total > 0) {
      user.budget += total;
      fin.add('prize', total);
      news.insert(0, '💰 استلمت مكافآت الجوائز: ${money1(total)}');
    }
    c['paid'] = true;
    touch();
  }

  void revealAward(String id) {
    final c = ceremony;
    if (c == null) return;
    for (final a in (c['a'] as List)) {
      if (a['id'] == id) a['rev'] = true;
    }
    touch();
  }
}
