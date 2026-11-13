part of 'game_state.dart';

/// مدرجات الملعب الأربعة: الاسم، حصتها من السعة، السعر المرجعي، حساسية السعر، فارق الطلب
const kStandNames = ['الشعبي', 'الغربي', 'الشرفة', 'VIP'];
const kStandShare = [0.47, 0.21, 0.24, 0.08];
const kStandBase = [35.0, 50.0, 80.0, 200.0];
const kStandElast = [1.3, 1.3, 1.5, 2.0];
const kStandOff = [0.12, 0.05, 0.0, -0.22];
/// بطاقات الموسم: (الاسم، المدرج المقابل، خصم نسبي، فارق الطلب)
const kSeasonTiers = <(String, int, double, double)>[('ذهبية', 3, 0.68, 0.32), ('فضية', 2, 0.58, 0.43), ('عادية', 0, 0.54, 0.0)];
const kHomeMatches = 19;
const kGateScale = 0.6;

class StandRow {
  final int cap, subs, att;
  final double price, fill;
  const StandRow(this.cap, this.subs, this.att, this.price, this.fill);
  int get singles => att - subs;
}

class TicketForecast {
  final List<StandRow> stands;
  final double seasonRev, singleRev, vipRev;
  const TicketForecast(this.stands, this.seasonRev, this.singleRev, this.vipRev);
  int get attendance => stands.fold(0, (a, s) => a + s.att);
  int get capacity => stands.fold(0, (a, s) => a + s.cap);
  int get subs => stands.fold(0, (a, s) => a + s.subs);
  double get revenue => seasonRev + singleRev + vipRev;
}

extension TicketsLogic on GameState {
  /// السعر المرجعي لمدرج (يتناسب مع سمعة النادي)
  double refPrice(int s) => ((kStandBase[s] * (0.6 + 0.1 * user.reputation)) / 5).round() * 5.0;

  double standPrice(int s) => (refPrice(s) * standMult[s]).roundToDouble();

  void setStandPrice(int s, double price) {
    standMult[s] = (price / refPrice(s)).clamp(0.4, 2.5).toDouble();
    notifyListeners();
    unawaited(save());
  }

  double get priceIndex {
    var w = 0.0, t = 0.0;
    for (var s = 0; s < 4; s++) {
      w += standMult[s] * kStandShare[s];
      t += kStandShare[s];
    }
    return w / t;
  }

  int get ticketLevel => priceIndex < 0.9 ? 0 : (priceIndex > 1.1 ? 2 : 1);

  void setTicketLevel(int v) {
    final m = const [0.8, 1.0, 1.25][v];
    for (var s = 0; s < 4; s++) {
      standMult[s] = m;
    }
    notifyListeners();
    unawaited(save());
  }

  /// الطلب الأساسي على المباراة (0..1): شعبية، قوة الخصم، شكل الفريق
  double demandBase({int oppRep = 3}) {
    final f = formOf(user, 5);
    final form = f.isEmpty ? 0.0 : (f.where((e) => e == 'W').length - f.where((e) => e == 'L').length) / f.length;
    return (0.40 + 0.55 * fans / 100 + 0.035 * (oppRep - 3) + 0.05 * form).clamp(0.1, 1.2).toDouble();
  }

  /// توقّع الحضور والإيراد لمباراة على الأرض بالأسعار الحالية (أو بمضاعف عام اختياري)
  TicketForecast ticketForecast({int oppRep = 3, double globalMult = 1.0}) {
    final cap = stadiumCapacity;
    final d = demandBase(oppRep: oppRep);
    final rows = <StandRow>[];
    var single = 0.0, vip = 0.0;
    for (var s = 0; s < 4; s++) {
      final c = (cap * kStandShare[s]).round();
      final dem = d + kStandOff[s];
      var m = standMult[s] * globalMult;
      if (dynPricing) m *= (1 + 0.25 * (dem - 0.65)).clamp(0.9, 1.12).toDouble();
      final price = refPrice(s) * m;
      final fill = (dem * pow(1 / m, kStandElast[s])).clamp(0.12, 1.0).toDouble();
      var subs = 0;
      for (final t in kSeasonTiers) {
        if (t.$2 == s) subs = seasonSold(t, c, d);
      }
      final att = max(subs, (c * fill).round());
      final rev = (att - subs) * price / 1e6 * kGateScale;
      if (s == 3) {
        vip += rev;
      } else {
        single += rev;
      }
      rows.add(StandRow(c, subs, att, price, fill));
    }
    var season = 0.0;
    for (final t in kSeasonTiers) {
      season += rows[t.$2].subs * seasonPrice(t) / kHomeMatches / 1e6 * kGateScale;
    }
    return TicketForecast(rows, season, single, vip);
  }

  /// سعر بطاقة الموسم الكاملة (خصم على سعر المدرج × عدد المباريات)
  double seasonPrice((String, int, double, double) t) => (refPrice(t.$2) * kHomeMatches * (1 - t.$3) * seasonMult / 5).round() * 5.0;

  /// عدد المشتركين في فئة بحسب الشعبية والسعر
  int seasonSold((String, int, double, double) t, int cap, double demand) {
    final pct = ((0.30 + 0.5 * fans / 100 + t.$4) * pow(1 / seasonMult, 1.5)).clamp(0.05, 0.98).toDouble();
    return (cap * pct).round();
  }

  /// معدل تجديد الاشتراكات
  double get renewalRate => ((0.62 + 0.35 * fans / 100) * pow(1 / seasonMult, 1.2)).clamp(0.3, 0.99).toDouble();

  /// المباراة القادمة على أرضك (إن وُجدت) وخصمها
  Fixture? get nextHomeFixture {
    for (var w = week; w < rounds.length; w++) {
      for (final f in rounds[w]) {
        if (f.home == user.id && !f.played) return f;
      }
    }
    return null;
  }

  int get nextHomeWeek {
    for (var w = week; w < rounds.length; w++) {
      for (final f in rounds[w]) {
        if (f.home == user.id && !f.played) return w;
      }
    }
    return week;
  }

  int get nextOppRep {
    final f = nextHomeFixture;
    if (f == null) return 3;
    try {
      return team(f.away).reputation;
    } catch (_) {
      return 3;
    }
  }

  double get fillRate {
    final t = ticketForecast(oppRep: 3);
    return t.capacity == 0 ? 0 : t.attendance / t.capacity;
  }

  int get attendance => ticketForecast(oppRep: nextOppRep).attendance;

  /// أفضل سعر لكل مدرج (يعظّم إيراد المدرج) بحدّ أقصى مقبول جماهيرياً
  List<double> suggestedMults({int oppRep = 3}) {
    final d = demandBase(oppRep: oppRep);
    final out = <double>[];
    for (var s = 0; s < 4; s++) {
      var best = 1.0, bestRev = -1.0;
      for (var m = 0.6; m <= 1.5001; m += 0.05) {
        final dem = d + kStandOff[s];
        final fill = (dem * pow(1 / m, kStandElast[s])).clamp(0.12, 1.0).toDouble();
        final rev = fill * m;
        if (rev > bestRev) {
          bestRev = rev;
          best = m;
        }
      }
      out.add(double.parse(best.toStringAsFixed(2)));
    }
    return out;
  }

  void applySuggested() {
    final m = suggestedMults(oppRep: nextOppRep);
    for (var s = 0; s < 4; s++) {
      standMult[s] = m[s];
    }
    notifyListeners();
    unawaited(save());
  }

  /// منحنى الإيراد مقابل مضاعف السعر العام (نقاط 0.5..1.8)
  List<(double, double)> priceCurve({int oppRep = 3}) => [
        for (var m = 0.5; m <= 1.801; m += 0.05) (m, ticketForecast(oppRep: oppRep, globalMult: m).revenue),
      ];

  void setSeasonMult(double v) {
    seasonMult = v.clamp(0.8, 1.4).toDouble();
    notifyListeners();
    unawaited(save());
  }
}
