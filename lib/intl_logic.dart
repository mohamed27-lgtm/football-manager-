part of 'game_state.dart';

/// تاريخ كل نافذة دولية: سبتمبر، أكتوبر، نوفمبر، مارس، يونيو
DateTime intlWindowDate(int season, int wid) {
  final y = 2025 + season;
  return [DateTime.utc(y, 9, 5), DateTime.utc(y, 10, 10), DateTime.utc(y, 11, 14), DateTime.utc(y + 1, 3, 27), DateTime.utc(y + 1, 6, 5)][wid];
}

extension IntlLogic on GameState {
  /// النافذة القادمة (أو null إن انتهت نوافذ الموسم)
  int? get nextWindow {
    for (var w = 0; w < 5; w++) {
      if (!nat.winDone.contains(w)) return w;
    }
    return null;
  }

  void _playIntl(int wid) {
    ensureNat();
    _buildNatIdx();
    final n = nat.playWindow(wid, rng, _natAdj, season);
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
