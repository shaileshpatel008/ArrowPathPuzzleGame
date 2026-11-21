import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import '../../data/services/ads_service.dart';

/// Anchored adaptive banner. Collapses to nothing for Plus members, during
/// the ad-free first levels, or when consent does not allow ads.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final AdsService _ads = Get.find();
  BannerAd? _banner;
  bool _loaded = false;
  Worker? _worker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _worker ??= ever<bool>(_ads.sdkReady, (_) => _load());
    _load();
  }

  Future<void> _load() async {
    if (_banner != null || !_ads.sdkReady.value || !_ads.eligible) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size == null || !mounted) return;
    _banner = BannerAd(
      adUnitId: AdConfig.banner,
      size: size,
      request: _ads.request,
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
        },
      ),
    );
    await _banner!.load();
  }

  @override
  void dispose() {
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
      final show = ready && eligible && _loaded && _banner != null;
      if (!show) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: SizedBox(
          width: _banner!.size.width.toDouble(),
          height: _banner!.size.height.toDouble(),
          child: AdWidget(ad: _banner!),
        ),
      );
    });
  }
}
