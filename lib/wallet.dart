import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// كوينز اللعبة: عملة نادرة مشتركة بين كل الألعاب المحفوظة (تُحفظ على الجهاز)
class Wallet extends ChangeNotifier {
  static final Wallet i = Wallet._();
  Wallet._();

  static const startCoins = 300;

  /// مكافآت أيام السلسلة (تتكرر كل 7 أيام): اليوم السابع هو الأكبر
  static const rewards = [25, 30, 40, 50, 60, 80, 150];
  int coins = startCoins;
  int streak = 0;
  String lastDay = ''; // آخر يوم استُلمت فيه المكافأة (سنة-شهر-يوم)

  static String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      coins = p.getInt('w_coins') ?? startCoins;
      streak = p.getInt('w_streak') ?? 0;
      lastDay = p.getString('w_day') ?? '';
    } catch (_) {}
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('w_coins', coins);
      await p.setInt('w_streak', streak);
      await p.setString('w_day', lastDay);
    } catch (_) {}
  }

  void add(int n) {
    coins += n;
    _save();
  }

  /// يخصم المبلغ إن كان الرصيد كافياً
  bool spend(int n) {
    if (n < 0 || coins < n) return false;
    coins -= n;
    _save();
    return true;
  }

  bool canClaimDaily([DateTime? now]) => lastDay != _day(now ?? DateTime.now());

  /// طول السلسلة لو استلمت الآن: تستمر إن استلمت أمس، وإلا تبدأ من 1
  int streakIfClaimed([DateTime? now]) {
    final t = now ?? DateTime.now();
    return lastDay == _day(t.subtract(const Duration(days: 1))) ? streak + 1 : 1;
  }

  int nextReward([DateTime? now]) => rewards[(streakIfClaimed(now) - 1) % rewards.length];

  /// المكافأة اليومية: مرة كل يوم تقويمي، وتكبر مع تتابع الأيام. تعيد المبلغ أو 0
  int claimDaily([DateTime? now]) {
    final t = now ?? DateTime.now();
    if (!canClaimDaily(t)) return 0;
    final r = nextReward(t);
    streak = streakIfClaimed(t);
    lastDay = _day(t);
    coins += r;
    _save();
    return r;
  }
}
