import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// كوينز اللعبة: عملة نادرة مشتركة بين كل الألعاب المحفوظة (تُحفظ على الجهاز)
class Wallet extends ChangeNotifier {
  static final Wallet i = Wallet._();
  Wallet._();

  static const startCoins = 300;
  static const dailyReward = 25;
  int coins = startCoins;
  int lastDaily = 0; // وقت آخر مكافأة يومية (ميلي ثانية)

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      coins = p.getInt('w_coins') ?? startCoins;
      lastDaily = p.getInt('w_daily') ?? 0;
    } catch (_) {}
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('w_coins', coins);
      await p.setInt('w_daily', lastDaily);
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

  bool canClaimDaily([DateTime? now]) => (now ?? DateTime.now()).millisecondsSinceEpoch - lastDaily >= const Duration(hours: 20).inMilliseconds;

  /// المكافأة اليومية: مرة كل 20 ساعة. يعيد المبلغ، أو 0 إن لم يحن وقتها
  int claimDaily([DateTime? now]) {
    final t = now ?? DateTime.now();
    if (!canClaimDaily(t)) return 0;
    lastDaily = t.millisecondsSinceEpoch;
    coins += dailyReward;
    _save();
    return dailyReward;
  }
}
