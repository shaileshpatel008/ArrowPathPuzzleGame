import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/services/ads_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/consent_service.dart';
import '../data/services/iap_service.dart';
import '../data/services/lifecycle_service.dart';
import '../data/services/platform_service.dart';
import '../data/services/progress_service.dart';
import '../data/services/settings_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/update_service.dart';
import '../data/services/wallet_service.dart';
import '../modules/store/purchase_feedback.dart';

/// Creates the app-wide services (permanent singletons) in dependency order.
///
/// Only local, fast services are awaited before the first frame. Everything
/// that talks to a platform plugin (audio, package info, ads, billing) starts
/// in the background and is guarded, so a plugin failure on one device can
/// never stop the game from opening.
abstract final class InitialBinding {
  static Future<void> initServices() async {
    final storage = await Get.putAsync(
      () => StorageService().init(),
      permanent: true,
    );
    final settings = Get.put(SettingsService(storage).init(), permanent: true);
    final progress = Get.put(ProgressService(storage).init(), permanent: true);
    final wallet = Get.put(WalletService(storage).init(), permanent: true);

    final platform = Get.put(PlatformService(), permanent: true);
    _background('platform', platform.init);

    final audio = Get.put(AudioService(settings), permanent: true);
    _background('audio', audio.init);

    final consent = Get.put(ConsentService(), permanent: true);
    final ads = Get.put(
      AdsService(consent, progress, wallet, storage),
      permanent: true,
    );
    _guard('ads', ads.init);

    final iap = Get.put(IapService(wallet, progress), permanent: true);
    _background('billing', iap.init);

    Get.put(PurchaseFeedback(iap), permanent: true);
    Get.put(LifecycleService(wallet, progress), permanent: true);
    _guard('updates', () {
      Get.put(UpdateService(storage), permanent: true);
    });
  }

  static void _background(String name, Future<Object?> Function() task) {
    unawaited(
      Future<void>(() async {
        try {
          await task();
        } catch (e, s) {
          debugPrint('Service "$name" failed to start: $e\n$s');
        }
      }),
    );
  }

  static void _guard(String name, void Function() task) {
    try {
      task();
    } catch (e, s) {
      debugPrint('Service "$name" failed to start: $e\n$s');
    }
  }
}
