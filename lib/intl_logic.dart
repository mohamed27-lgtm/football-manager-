part of 'game_state.dart';

/// تاريخ كل نافذة دولية: سبتمبر، أكتوبر، نوفمبر، مارس، يونيو
DateTime intlWindowDate(int season, int wid) {
  final y = 2025 + season;
  return [DateTime.utc(y, 9, 5), DateTime.utc(y, 10, 10), DateTime.utc(y, 11, 14), DateTime.utc(y + 1, 3, 27), DateTime.utc(y + 1, 6, 5)][wid];
}

extension IntlLogic on GameState {
  DateTime windowDate(int w) => intlWindowDate(season, w);

  /// النافذة القادمة (أو null إن انتهت نوافذ الموسم)
  int? get nextWindow {
    for (var w = 0; w < 5; w++) {
      if (!nat.winDone.contains(w)) return w;
    }
    return null;
  }

  /// توقف دولي: نافذة حلّ موعدها ولم تُلعب بعد؛ تتأجل الجولة حتى ينتهي التوقف
  bool get intlBreak {
    if (!realWorld || seasonOver || fired || rounds.isEmpty || week >= rounds.length) return false;
    ensureNat();
    final end = GameCalendar.weekStart(season, week.clamp(0, 60).toInt()).add(const Duration(days: 7));
    for (var w = 0; w < 4; w++) {
      if (!nat.winDone.contains(w) && intlWindowDate(season, w).isBefore(end)) return true;
    }
    return false;
  }

  /// يلعب النافذة الدولية: يستدعي نجوم فريقك (ولاعبي منتخبك) فيتعبون وقد يُصاب بعضهم، ثم تُستأنف الجولة
  String playIntlBreak() {
    ensureNat();
    final end = GameCalendar.weekStart(season, week.clamp(0, 60).toInt()).add(const Duration(days: 7));
    final before = nat.log.length;
    for (var w = 0; w < 4; w++) {
      if (!nat.winDone.contains(w) && intlWindowDate(season, w).isBefore(end)) this._playIntl(w);
    }
    final played = <String>{};
    for (final l in nat.log.skip(before)) {
      played
        ..add(l[2] as String)
        ..add(l[3] as String);
    }
    final away = <String>[], hurt = <String>[];
    for (final p in user.squad) {
      final n = p.natRep;
      if (n == null || !played.contains(n)) continue;
      if (!(p.overall >= 76 || (n == country && p.overall >= 70))) continue;
      away.add('${p.name} ($n)');
      p.fitness = (p.fitness - 6 - rng.nextInt(7)).clamp(30, 100).toDouble();
      if (p.injuredWeeks == 0 && rng.nextDouble() < 0.06) {
        p.injuredWeeks = 1 + rng.nextInt(3);
        hurt.add(p.name);
        news.insert(0, '🚑 عاد ${p.name} من الالتزام الدولي مصاباً (${p.injuredWeeks} أسابيع)');
      }
    }
    final msg = away.isEmpty
        ? 'توقفت الجولات بسبب نافذة المباريات الدولية. لم يُستدعَ أي من لاعبيك.'
        : 'توقفت الجولات بسبب نافذة المباريات الدولية.\nاستُدعي من لاعبيك: ${away.join('، ')}.${hurt.isEmpty ? '' : '\nأُصيب: ${hurt.join('، ')}.'}';
    news.insert(0, '🌍 التوقف الدولي: ${away.isEmpty ? 'بلا استدعاءات لفريقك' : 'استُدعي ${away.length} من لاعبيك'}');
    notifyListeners();
    unawaited(save());
    return msg;
  }

  int _playIntl(int wid) {
    ensureNat();
    _buildNatIdx();
    final n = nat.playWindow(wid, rng, _natAdj, season, custom: this._natJobMatch);
    final c = country;
    final mine = <String>[];
    if (c.isNotEmpty) {
      for (final l in nat.log.reversed.take(n)) {
        if (l[2] != c && l[3] != c) continue;
        final home = l[2] == c;
        final opp = (home ? l[3] : l[2]) as String;
        final gf = (home ? l[4] : l[5]) as int, ga = (home ? l[5] : l[4]) as int;
        mine.add('$gf-$ga أمام $opp (${(l[6] as int) == 0 ? 'تصفيات رسمية' : 'ودية'})');
      }
    }
    news.insert(0, '🌍 نافذة المباريات الدولية (${NatState.winNames[wid]}): لُعبت $n مباراة${mine.isEmpty ? '' : ' • منتخب $c: ${mine.join('، ')}'}');
    _adjCache.clear();
    return n;
  }

  void _publishRanking() {
    ensureNat();
    nat.publish(GameCalendar.fmt(today));
    final c = country;
    final rk = nat.pubRanking;
    final i = c.isEmpty ? -1 : rk.indexOf(c);
    final mv = i < 0 ? '' : ' • منتخب $c في المركز ${i + 1}';
    news.insert(0, '📊 صدر التصنيف الدولي الجديد: المتصدر ${rk.first}$mv');
  }

  /// كل أسبوع: تُلعب النافذة الدولية التي حلّ موعدها، ويُنشر التصنيف بعد النافذة بأسبوع
  void _intlTick() {
    if (!realWorld) return;
    ensureNat();
    if (nat.pub.isEmpty) nat.publish(GameCalendar.fmt(today));
    if (nat.pendRel) this._publishRanking();
    final end = GameCalendar.weekStart(season, week.clamp(0, 60).toInt()).add(const Duration(days: 7));
    for (var w = 0; w < 4; w++) {
      if (!nat.winDone.contains(w) && intlWindowDate(season, w).isBefore(end)) {
        this._playIntl(w);
      }
    }
  }

  /// نهاية الموسم: النوافذ المتبقية (يونيو) ثم إصدار التصنيف
  void _finishWindows() {
    ensureNat();
    for (var w = 0; w < 5; w++) {
      if (!nat.winDone.contains(w)) this._playIntl(w);
    }
  }
}
