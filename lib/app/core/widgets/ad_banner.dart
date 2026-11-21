import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import '../../data/services/ads_service.dart';

/// Anchored adaptive banner. Collapses to nothing for Plus members, during
/// the ad-free first levels, or when consent does not allow ads.
///
/// Loads one ad at a time, retries a failed load (up to 4 times with a
/// growing delay) and logs every step with the `[Ads]` prefix.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final AdsService _ads = Get.find();
  BannerAd? _banner;
  bool _loaded = false;
  bool _loading = false;
  int _attempts = 0;
  int? _width;
  Worker? _worker;
  Timer? _retry;

  static const _maxAttempts = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _width = MediaQuery.sizeOf(context).width.truncate();
    _worker ??= ever<bool>(_ads.sdkReady, (_) => _load());
    _load();
  }

  Future<void> _load() async {
    if (_loading || _banner != null || !mounted) return;
    if (!_ads.sdkReady.value || !_ads.eligible) return;
    final width = _width;
    if (width == null) return;
    _loading = true;
    _attempts++;
    try {
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null || !mounted) {
        _ads.log('banner: no adaptive size for width $width');
        _loading = false;
        return;
      }
      _ads.log('banner: loading (attempt $_attempts)');
      final ad = BannerAd(
        adUnitId: AdConfig.banner,
        size: size,
        request: _ads.request,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _ads.log('banner: loaded');
            _loading = false;
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _banner = ad as BannerAd;
              _loaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            _ads.log('banner: failed to load: ${error.message}');
            ad.dispose();
            _loading = false;
            if (mounted && _attempts < _maxAttempts) {
              _retry?.cancel();
              _retry = Timer(Duration(seconds: 10 * _attempts), _load);
            }
          },
        ),
      );
      await ad.load();
    } catch (e) {
      _ads.log('banner: error $e');
      _loading = false;
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    _worker?.dispose();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read the observables first so Obx always has something to track.
      final ready = _ads.sdkReady.value;
      final eligible = _ads.eligible;
      final banner = _banner;
      if (!ready || !eligible || !_loaded || banner == null) {
        return const SizedBox.shrink();
      }
      return SafeArea(
        top: false,
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      );
    });
  }
}
