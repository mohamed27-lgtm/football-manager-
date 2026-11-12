/// دفتر مالي بسيط للنادي: إيرادات ومصاريف الموسم + منحنى الرصيد + الديون
class Finance {
  Finance();

  double debt = 0;
  final Map<String, double> season = {};
  final List<double> history = [];

  /// دفتر المعاملات: كل إدخال [موسم، أسبوع، يوم، بند، مبلغ موقّع (+دخل / −مصروف)، ملاحظة]
  final List<List<dynamic>> ledger = [];
  static const _ledgerMax = 400;
  int Function()? clockSeason, clockWeek, clockDay;

  static const incomeKeys = ['tickets', 'broadcast', 'sponsor', 'prize', 'sales', 'loanout'];
  static const expenseKeys = [
    'wages',
    'maintenance',
    'operations',
    'purchases',
    'renewals',
    'severance',
    'upgrades',
    'interest',
    'agents',
    'loanin',
    'staff',
    'scouting',
  ];

  static const labels = <String, String>{
    'tickets': 'التذاكر',
    'broadcast': 'البث',
    'sponsor': 'الرعاية',
    'prize': 'الجوائز',
    'sales': 'بيع اللاعبين',
    'wages': 'الرواتب',
    'maintenance': 'الصيانة',
    'operations': 'التشغيل والإدارة',
    'purchases': 'شراء اللاعبين',
    'renewals': 'تجديد العقود',
    'severance': 'إنهاء العقود',
    'upgrades': 'ترقية المنشآت',
    'interest': 'فوائد القروض',
    'agents': 'عمولات الوكلاء',
    'loanin': 'استعارة لاعبين',
    'staff': 'رواتب الطاقم',
    'loanout': 'إعارة لاعبين',
    'scouting': 'مهام الكشافة',
  };

  void add(String key, double v, {String note = ''}) {
    season[key] = (season[key] ?? 0) + v;
    if (v.abs() < 0.0005) return;
    final inc = incomeKeys.contains(key);
    ledger.add([clockSeason?.call() ?? 1, clockWeek?.call() ?? 0, clockDay?.call() ?? 0, key, inc ? v.abs() : -v.abs(), note]);
    if (ledger.length > _ledgerMax) ledger.removeRange(0, ledger.length - _ledgerMax);
  }

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
        'ledger': ledger,
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
    for (final e in (j['ledger'] as List?) ?? const []) {
      f.ledger.add(List<dynamic>.from(e as List));
    }
    return f;
  }
}
