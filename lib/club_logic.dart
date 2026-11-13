part of 'game_state.dart';

/// حملة جماهيرية جارية
class Campaign {
  final String kind;
  int left;
  final int total;
  Campaign(this.kind, this.left, this.total);
  double get progress => total == 0 ? 1 : ((total - left) / total).clamp(0.0, 1.0).toDouble();
  Map<String, dynamic> toJson() => {'k': kind, 'l': left, 't': total};
  factory Campaign.fromJson(Map<String, dynamic> j) => Campaign(j['k'] as String, j['l'] as int, j['t'] as int);
}

/// أنواع الحملات: (الاسم، التكلفة M، الأسابيع، أثر الشعبية أسبوعياً، الوصف)
const kCampaigns = <String, (String, double, int, double, String)>{
  'membership': ('حملة العضوية الذهبية', 0.6, 6, 0.22, 'مشتركون جدد وولاء أعلى'),
  'kids': ('حملة الأطفال والمدارس', 0.4, 5, 0.18, 'جيل جديد من المشجعين'),
  'social': ('حملة وسائل التواصل', 0.3, 4, 0.2, 'انتشار سريع وشعبية'),
};

extension ClubLogic on GameState {
  /// راتب المدرب الأسبوعي بالملايين (تقدير): يتناسب مع سمعتك وسمعة النادي
  double get mgrWeekly => ((0.05 + 0.006 * mgrRep + 0.02 * user.reputation) * 1000).round() / 1000;

  double offerWeekly(String club) {
    double r = 3;
    try {
      r = clubNamed(club).reputation.toDouble();
    } catch (_) {}
    return ((0.05 + 0.006 * mgrRep + 0.02 * r) * 1000).round() / 1000;
  }

  /// قاعدة الجماهير بالملايين (تقدير): تتناسب مع سمعة النادي والشعبية
  double get fanBaseM => (0.25 + 0.95 * user.reputation) * (0.45 + fans / 100) * (1 + 0.004 * honours.length);

  /// الولاء: يرتفع مع الشعبية والنتائج
  int get loyalty {
    final pos = table.indexOf(user) + 1;
    final res = pos > 0 && pos <= 4 ? 8 : (pos > teams.length - 4 ? -6 : 0);
    return (45 + fans * 0.42 + res + 2.0 * (user.fanZone - 1)).round().clamp(5, 99);
  }

  /// نمو الشعبية بالنقاط في آخر موسم
  double get seasonGrowth => fanHist.length < 2 ? 0 : fans - fanHist[fanHist.length - 2];

  /// توزيع أعمار الجماهير (تقدير): دون 18 • 18-34 • 35-54 • 55+
  List<int> get fanAges {
    final young = (user.squad.where((p) => p.age <= 23).length * 100 / max(1, user.squad.length)).clamp(0, 100).toDouble();
    final a = (12 + young * 0.1 + 0.8 * user.academy).round();
    final b = (40 + young * 0.1 + fans * 0.05).round();
    final d = (10 + 0.06 * (100 - fans)).round();
    final c = max(5, 100 - a - b - d);
    return [a, b, c, d];
  }

  String? startCampaign(String kind) {
    final k = kCampaigns[kind];
    if (k == null) return 'حملة غير معروفة';
    if (campaigns.any((c) => c.kind == kind)) return 'هذه الحملة جارية بالفعل';
    if (campaigns.length >= 2) return 'لا تُنفَّذ أكثر من حملتين معاً';
    if (k.$2 > user.budget) return 'الميزانية لا تكفي (${money1(k.$2)})';
    user.budget -= k.$2;
    fin.add('staff', k.$2);
    campaigns.add(Campaign(kind, k.$3, k.$3));
    news.insert(0, '📣 انطلقت ${k.$1} لمدة ${k.$3} أسابيع بتكلفة ${money1(k.$2)}');
    unawaited(save());
    notifyListeners();
    return null;
  }

  void _campaignsTick() {
    for (final c in [...campaigns]) {
      final k = kCampaigns[c.kind];
      if (k != null) fans = min(100.0, fans + k.$4);
      c.left--;
      if (c.left <= 0) {
        campaigns.remove(c);
        news.insert(0, '✅ انتهت ${k?.$1 ?? 'الحملة'}: الشعبية ${fans.round()}%');
      }
    }
  }

  /// مفاوضة راعٍ على عرض: نجاح 55% يرفع المبلغ 8%، وإلا يسحب الراعي عرضه
  String? negotiateSponsor(SponsorOffer o) {
    final list = sponsorOffers[o.deal.type];
    if (list == null || !list.contains(o)) return 'العرض لم يعد متاحاً';
    final i = list.indexOf(o);
    if (rng.nextDouble() < 0.55) {
      final nd = SponsorDeal(o.deal.type, o.deal.brand, (o.deal.weekly * 1.08 * 1000).round() / 1000, o.deal.years);
      list[i] = SponsorOffer(nd, o.bonus);
      news.insert(0, '🤝 وافق ${o.deal.brand} على رفع عرضه 8%');
    } else {
      list.removeAt(i);
      news.insert(0, '❌ سحب ${o.deal.brand} عرضه بعد المفاوضة');
    }
    unawaited(save());
    notifyListeners();
    return null;
  }

  String? declineSponsor(SponsorOffer o) {
    final list = sponsorOffers[o.deal.type];
    if (list == null || !list.remove(o)) return 'العرض لم يعد متاحاً';
    unawaited(save());
    notifyListeners();
    return null;
  }
}
