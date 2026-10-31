/// دفتر مالي بسيط للنادي: إيرادات ومصاريف الموسم + منحنى الرصيد + الديون
class Finance {
  double debt = 0;
  final Map<String, double> season = {};
  final List<double> history = [];

  static const incomeKeys = ['tickets', 'broadcast', 'sponsor', 'prize', 'sales'];
  static const expenseKeys = [
    'wages',
    'maintenance',
    'purchases',
    'renewals',
    'severance',
    'upgrades',
    'interest',
  ];

  static const labels = <String, String>{
    'tickets': 'التذاكر',
    'broadcast': 'البث',
    'sponsor': 'الرعاية',
    'prize': 'الجوائز',
    'sales': 'بيع اللاعبين',
    'wages': 'الرواتب',
    'maintenance': 'الصيانة',
    'purchases': 'شراء اللاعبين',
    'renewals': 'تجديد العقود',
    'severance': 'إنهاء العقود',
    'upgrades': 'ترقية المنشآت',
    'interest': 'فوائد القروض',
  };

  void add(String key, double v) => season[key] = (season[key] ?? 0) + v;

  double get totalIncome =>
      incomeKeys.fold(0.0, (a, k) => a + (season[k] ?? 0));

  double get totalExpense =>
      expenseKeys.fold(0.0, (a, k) => a + (season[k] ?? 0));

  void record(double budget) {
    history.add(budget);
    if (history.length > 60) history.removeAt(0);
  }

  Map<String, dynamic> toJson() => {
        'debt': debt,
        'season': season,
        'history': history,
      };

  factory Finance.fromJson(Map<String, dynamic> j) {
    final f = Finance();
    f.debt = ((j['debt'] as num?) ?? 0).toDouble();
    ((j['season'] as Map?) ?? {}).forEach((k, v) {
      f.season[k as String] = (v as num).toDouble();
    });
    for (final v in (j['history'] as List?) ?? const []) {
      f.history.add((v as num).toDouble());
    }
    return f;
  }
}
