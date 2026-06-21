import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../env/env_config.dart';
import '../ad_config.dart';

/// A self-contained, reusable AdMob banner.
///
/// Loads its own [BannerAd] on mount, sizes itself to the requested [AdSize],
/// and disposes the ad on unmount — so you can drop it anywhere:
/// ```dart
/// const BannerAdWidget()                       // adaptive anchored banner
/// BannerAdWidget(size: AdSize.mediumRectangle) // 300×250 inline
/// ```
///
/// While the ad is loading (or if it fails) the widget collapses to
/// [placeholder] (a zero-height box by default) so it never leaves a gap.
class BannerAdWidget extends StatefulWidget {
  /// Fixed size. When null an adaptive anchored banner sized to the screen
  /// width is requested in [State.didChangeDependencies].
  final AdSize? size;

  /// Shown while loading or after a load failure. Defaults to `SizedBox.shrink`.
  final Widget placeholder;

  const BannerAdWidget({
    super.key,
    this.size,
    this.placeholder = const SizedBox.shrink(),
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _load();
  }

  Future<void> _load() async {
    final size = widget.size ??
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
          Orientation.portrait,
          MediaQuery.of(context).size.width.truncate(),
        ) ??
        AdSize.banner;

    final ad = BannerAd(
      adUnitId: AdConfig.current.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          if (EnvConfig.verboseLogging) {
            debugPrint('[BannerAdWidget] failed: ${err.code} ${err.message}');
          }
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return widget.placeholder;
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
