import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../env/env_config.dart';
import 'ad_config.dart';

/// Centralised Google AdMob (Google Ads) lifecycle for both apps.
///
/// Responsibilities:
/// - Initialise the Mobile Ads SDK once at boot ([init]).
/// - Pre-load and cache **interstitial** and **rewarded** ads so they show
///   instantly at the moment you want them.
/// - Hand out fresh [AdUnitIds.banner] for inline [BannerAdWidget]s.
///
/// Register permanently:
/// ```dart
/// final ads = AdsService();
/// await ads.init();           // also call AdConfig.configure(...) first
/// Get.put<AdsService>(ads, permanent: true);
/// ```
class AdsService extends GetxService {
  bool _initialised = false;
  bool get isInitialised => _initialised;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  /// True once a cached interstitial/rewarded is ready to show.
  final RxBool isInterstitialReady = false.obs;
  final RxBool isRewardedReady = false.obs;

  /// Initialise the SDK and warm the cache. Idempotent.
  ///
  /// Pass [testDeviceIds] (printed to logcat/console on first ad request) so
  /// real devices still receive test ads in production builds during QA.
  Future<void> init({List<String> testDeviceIds = const []}) async {
    if (_initialised) return;
    await MobileAds.instance.initialize();
    if (testDeviceIds.isNotEmpty || AdConfig.useTestAds) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
    }
    _initialised = true;
    // Warm the cache so the first show() is instant.
    preloadInterstitial();
    preloadRewarded();
  }

  AdRequest get _request => const AdRequest();

  void _log(String msg) {
    if (EnvConfig.verboseLogging) debugPrint('[AdsService] $msg');
  }

  // ── Interstitial ────────────────────────────────────────────
  /// Load (and cache) a full-screen interstitial ahead of time.
  void preloadInterstitial() {
    if (!_initialised || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdConfig.current.interstitial,
      request: _request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          isInterstitialReady.value = true;
          _log('interstitial loaded');
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          isInterstitialReady.value = false;
          _log('interstitial failed: ${err.code} ${err.message}');
        },
      ),
    );
  }

  /// Show the cached interstitial, if any. Returns true when one was shown.
  /// A fresh ad is pre-loaded immediately after dismissal.
  Future<bool> showInterstitial({VoidCallback? onDismissed}) async {
    final ad = _interstitial;
    if (ad == null) {
      preloadInterstitial();
      return false;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        isInterstitialReady.value = false;
        preloadInterstitial();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _interstitial = null;
        isInterstitialReady.value = false;
        preloadInterstitial();
        onDismissed?.call();
      },
    );
    await ad.show();
    return true;
  }

  // ── Rewarded ────────────────────────────────────────────────
  /// Load (and cache) a rewarded ad ahead of time.
  void preloadRewarded() {
    if (!_initialised || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: AdConfig.current.rewarded,
      request: _request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          isRewardedReady.value = true;
          _log('rewarded loaded');
        },
        onAdFailedToLoad: (err) {
          _rewarded = null;
          isRewardedReady.value = false;
          _log('rewarded failed: ${err.code} ${err.message}');
        },
      ),
    );
  }

  /// Show the cached rewarded ad. [onReward] fires with the reward amount/type
  /// only if the user watches long enough to earn it. Returns true when the ad
  /// was shown.
  Future<bool> showRewarded({
    required void Function(int amount, String type) onReward,
    VoidCallback? onDismissed,
  }) async {
    final ad = _rewarded;
    if (ad == null) {
      preloadRewarded();
      return false;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        isRewardedReady.value = false;
        preloadRewarded();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewarded = null;
        isRewardedReady.value = false;
        preloadRewarded();
        onDismissed?.call();
      },
    );
    await ad.show(
      onUserEarnedReward: (_, reward) =>
          onReward(reward.amount.toInt(), reward.type),
    );
    return true;
  }

  @override
  void onClose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
    super.onClose();
  }
}
