import 'dart:io' show Platform;

import '../env/env_config.dart';
import '../env/environment.dart';

/// Per-platform AdMob unit identifiers plus the global app IDs.
///
/// Google's official **test** unit IDs are baked in and used automatically in
/// any non-prod [Environment] (or whenever [forceTestAds] is set), so you never
/// risk serving live ads — or getting your account flagged for clicking your
/// own — during development.
///
/// Wire your real IDs in `main()` before [AdsService.init]:
/// ```dart
/// AdConfig.configure(
///   android: AdUnitIds(
///     banner: 'ca-app-pub-XXX/aaa',
///     interstitial: 'ca-app-pub-XXX/bbb',
///     rewarded: 'ca-app-pub-XXX/ccc',
///   ),
///   ios: AdUnitIds(/* … */),
/// );
/// ```
class AdConfig {
  AdConfig._();

  /// Google's reserved test unit IDs — always safe to display.
  static const _testAndroid = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/6300978111',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const _testIos = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/2934735716',
    interstitial: 'ca-app-pub-3940256099942544/4411468910',
    rewarded: 'ca-app-pub-3940256099942544/1712485313',
  );

  static AdUnitIds? _android;
  static AdUnitIds? _ios;

  /// When true, test units are returned regardless of environment. Handy for a
  /// manual QA toggle. Defaults to false (environment decides).
  static bool forceTestAds = false;

  /// Register your production unit IDs. Call once before [AdsService.init].
  static void configure({AdUnitIds? android, AdUnitIds? ios}) {
    _android = android;
    _ios = ios;
  }

  /// True when test units should be served (non-prod env or forced).
  static bool get useTestAds =>
      forceTestAds || EnvConfig.current != Environment.prod;

  /// The unit IDs for the current platform, resolving to test units when
  /// [useTestAds] is set or no production IDs were configured.
  static AdUnitIds get current {
    final isIos = !Platform.isAndroid && Platform.isIOS;
    if (useTestAds) return isIos ? _testIos : _testAndroid;
    final prod = isIos ? _ios : _android;
    // Fail safe: never crash on a missing config — fall back to test units.
    return prod ?? (isIos ? _testIos : _testAndroid);
  }
}

/// The three ad-format unit IDs for a single platform.
class AdUnitIds {
  final String banner;
  final String interstitial;
  final String rewarded;

  const AdUnitIds({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });
}
