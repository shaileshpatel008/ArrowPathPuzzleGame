import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob configuration.
///
/// Debug builds ALWAYS use Google's official test units, so you can never
/// get an invalid-traffic strike while developing. Release builds use the
/// real IDs below once you replace the placeholders.
///
/// Also replace the AdMob *App ID* in:
///   * android/app/src/main/AndroidManifest.xml
///       (com.google.android.gms.ads.APPLICATION_ID)
///   * ios/Runner/Info.plist (GADApplicationIdentifier)
abstract final class AdConfig {
  // AdMob ad unit IDs (AdMob › Apps › Arrow Path Puzzle › Ad units).
  static const _androidBanner = 'ca-app-pub-7616025727863605/2128825410';
  static const _androidInterstitial = 'ca-app-pub-7616025727863605/5096614586';
  static const _androidRewarded = 'ca-app-pub-7616025727863605/1620404007';

  static const _iosBanner = 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB';
  static const _iosInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII';
  static const _iosRewarded = 'ca-app-pub-XXXXXXXXXXXXXXXX/RRRRRRRRRR';

  // Google's public test units (safe to ship in debug builds).
  static const _testAndroidBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const _testAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testIosBanner = 'ca-app-pub-3940256099942544/2435281174';
  static const _testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  /// Device IDs that should always receive test ads (from logcat:
  /// "Use RequestConfiguration.Builder().setTestDeviceIds(...)").
  static const testDeviceIds = <String>[];

  /// Debug builds always get test ads. Release builds get real ads, except
  /// on a platform whose IDs are still placeholders (iOS for now), which
  /// falls back to test ads instead of requesting an invalid unit.
  static bool _isPlaceholder(String id) => id.contains('XXXXXXXX');

  static String get banner => _pick(
    android: _androidBanner,
    ios: _iosBanner,
    testAndroid: _testAndroidBanner,
    testIos: _testIosBanner,
  );

  static String get interstitial => _pick(
    android: _androidInterstitial,
    ios: _iosInterstitial,
    testAndroid: _testAndroidInterstitial,
    testIos: _testIosInterstitial,
  );

  static String get rewarded => _pick(
    android: _androidRewarded,
    ios: _iosRewarded,
    testAndroid: _testAndroidRewarded,
    testIos: _testIosRewarded,
  );

  // ----- Frequency rules (player-friendly and policy-safe) ------------------

  /// Show an interstitial after every N cleared levels (never after a loss,
  /// never mid-level).
  static const interstitialEveryLevels = 3;

  /// Minimum gap between two interstitials.
  static const interstitialMinGap = Duration(seconds: 90);

  /// Banner only on the level list, never on the game board.
  static const showBannerOnLevels = true;

  static String _pick({
    required String android,
    required String ios,
    required String testAndroid,
    required String testIos,
  }) {
    final isIos = !kIsWeb && Platform.isIOS;
    final real = isIos ? ios : android;
    if (kDebugMode || _isPlaceholder(real)) {
      return isIos ? testIos : testAndroid;
    }
    return real;
  }
}
