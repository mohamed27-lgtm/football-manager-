import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'wallet.dart';

/// إعلانات الفيديو المكافِئة (AdMob). بلا إعداد يعمل بمعرّفات Google التجريبية؛
/// ضع معرّفاتك الحقيقية في متغيرات المستودع ADMOB_APP_ID و ADMOB_REWARDED_ID
class Ads {
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _cfg = String.fromEnvironment('ADMOB_REWARDED_ID');
  static String get rewardedId => _cfg.isEmpty ? _testRewarded : _cfg;
  static const reward = 20;

  static bool _ready = false;
  static final busy = ValueNotifier<bool>(false);

  static Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _ready = true;
    } catch (_) {}
  }

  /// يحمّل ويعرض إعلاناً مكافِئاً. يعيد null عند النجاح (تُضاف الكوينز عند إكمال المشاهدة)، أو سبب الإخفاق
  static Future<String?> watch() async {
    if (busy.value) return 'جارٍ تحميل إعلان';
    if (!_ready) await init();
    if (!_ready) return 'خدمة الإعلانات غير متاحة الآن';
    busy.value = true;
    final done = _Done();
    await RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              done.finish(done.earned ? null : 'أغلقت الإعلان قبل نهايته فلم تُضَف الكوينز');
            },
            onAdFailedToShowFullScreenContent: (a, e) {
              a.dispose();
              done.finish('تعذّر عرض الإعلان');
            },
          );
          ad.show(onUserEarnedReward: (_, __) {
            done.earned = true;
            Wallet.i.add(reward);
          });
        },
        onAdFailedToLoad: (e) => done.finish('لا يوجد إعلان متاح الآن، حاول لاحقاً'),
      ),
    );
    final r = await done.future;
    busy.value = false;
    return r;
  }
}

class _Done {
  bool earned = false;
  final _c = Completer<String?>();
  void finish(String? r) {
    if (!_c.isCompleted) _c.complete(r);
  }

  Future<String?> get future => _c.future;
}
