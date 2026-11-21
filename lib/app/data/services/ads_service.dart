import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import '../../config/app_config.dart';
import '../../core/constants/storage_keys.dart';
import 'consent_service.dart';
import 'progress_service.dart';
import 'storage_service.dart';
import 'wallet_service.dart';

/// AdMob: interstitials between levels and opt-in rewarded ads.
///
/// Player-first rules (also keeps the app inside AdMob/Play policy):
///  * no ads at all for levels 1..[AppConfig.freeLevelsWithoutAds];
///  * no ads for Plus members;
///  * interstitials only on a natural break (after a WIN, before the next
///    level), never after a loss, never mid-level, rate limited;
///  * rewarded ads are always optional and the reward is stated up front;
///  * nothing is requested before UMP consent allows it.
class AdsService extends GetxService {
  AdsService(this._consent, this._progress, this._wallet, this._storage);

  final ConsentService _consent;
  final ProgressService _progress;
  final WalletService _wallet;
  final StorageService _storage;

  final sdkReady = false.obs;
  final rewardedReady = false.obs;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  DateTime? _lastInterstitial;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  int _retry = 0;
  bool _starting = false;

  /// True when consent status could not be determined (e.g. Google's test
  /// App ID, no consent message configured yet, or offline). Ads are then
  /// requested as non-personalised, which is the safe default.
  bool _nonPersonalized = false;

  /// The request used for every ad format (banner included).
  AdRequest get request => _nonPersonalized
      ? const AdRequest(nonPersonalizedAds: true)
      : const AdRequest();

  /// Ads may be shown to this player right now.
  bool get eligible =>
      !_wallet.isPlus.value &&
      _progress.highestCleared.value >= AppConfig.freeLevelsWithoutAds;

  AdsService init() {
    everAll([_progress.highestCleared, _wallet.isPlus], (_) => _maybeStart());
    _maybeStart();
    return this;
  }

  Future<void> _maybeStart() async {
    if (!eligible) {
      if (sdkReady.value) log('not eligible any more (Plus or reset)');
      _disposeAds();
      return;
    }
    if (sdkReady.value || _starting) return;
    _starting = true;
    try {
      log(
        'eligible (level ${_progress.highestCleared.value}), checking consent',
      );
      final allowed = await _consent.gather();
      if (!allowed && !_consent.updateFailed.value) {
        // The player has not given (or is still being asked for) consent.
        log('consent does not allow ads yet');
        return;
      }
      _nonPersonalized = !allowed;
      if (_nonPersonalized) {
        log('consent status unknown, using non-personalised ads');
      }
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          // The game is rated for everyone; keep ad content family friendly.
          maxAdContentRating: MaxAdContentRating.pg,
          testDeviceIds: AdConfig.testDeviceIds,
        ),
      );
      sdkReady.value = true;
      log('SDK ready, loading interstitial + rewarded');
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      log('start failed: $e');
    } finally {
      _starting = false;
    }
  }

  bool get _canLoad => sdkReady.value && eligible;

  void log(String message) => debugPrint('[Ads] $message');

  // ----- Interstitial ---------------------------------------------------------

  void _loadInterstitial() {
    if (!_canLoad || _interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitial,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          log('interstitial loaded');
          _loadingInterstitial = false;
          _retry = 0;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          log('interstitial failed to load: ${error.message}');
          _scheduleRetry(_loadInterstitial);
        },
      ),
    );
  }

  /// Call when the player leaves a WON level. Shows an interstitial only if
  /// the frequency rules allow it; always completes (never blocks the flow).
  Future<void> onLevelWon() async {
    if (!eligible) return;
    final count = _storage.readInt(StorageKeys.levelsSinceInterstitial) + 1;
    await _storage.write(StorageKeys.levelsSinceInterstitial, count);
    final gapOk =
        _lastInterstitial == null ||
        DateTime.now().difference(_lastInterstitial!) >=
            AdConfig.interstitialMinGap;
    final ad = _interstitial;
    log(
      'level won: $count/${AdConfig.interstitialEveryLevels} towards next '
      'interstitial (gap ok: $gapOk, loaded: ${ad != null})',
    );
    if (count < AdConfig.interstitialEveryLevels || !gapOk || ad == null) {
      _loadInterstitial();
      return;
    }
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
    );
    _interstitial = null;
    _lastInterstitial = DateTime.now();
    await _storage.write(StorageKeys.levelsSinceInterstitial, 0);
    await ad.show();
    await closed.future.timeout(const Duration(minutes: 2), onTimeout: () {});
    _loadInterstitial();
  }

  // ----- Rewarded -------------------------------------------------------------

  void _loadRewarded() {
    if (!_canLoad || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewarded,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          log('rewarded loaded');
          _loadingRewarded = false;
          _rewarded = ad;
          rewardedReady.value = true;
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          rewardedReady.value = false;
          log('rewarded failed to load: ${error.message}');
          _scheduleRetry(_loadRewarded);
        },
      ),
    );
  }

  /// Shows a rewarded ad. Completes with true only if the reward was earned.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!result.isCompleted) result.complete(false);
      },
    );
    _rewarded = null;
    rewardedReady.value = false;
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    final ok = await result.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => earned,
    );
    _loadRewarded();
    return ok;
  }

  void _scheduleRetry(void Function() load) {
    _retry = (_retry + 1).clamp(1, 6);
    Future<void>.delayed(Duration(seconds: 5 * _retry * _retry), load);
  }

  void _disposeAds() {
    _interstitial?.dispose();
    _interstitial = null;
    _rewarded?.dispose();
    _rewarded = null;
    rewardedReady.value = false;
  }

  @override
  void onClose() {
    _disposeAds();
    super.onClose();
  }
}
