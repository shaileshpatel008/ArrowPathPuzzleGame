import 'dart:async';

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
import '../data/services/wallet_service.dart';
import '../modules/store/purchase_feedback.dart';

/// Creates the app-wide services (permanent singletons) in dependency order.
abstract final class InitialBinding {
  static Future<void> initServices() async {
    final storage = await Get.putAsync(
      () => StorageService().init(),
      permanent: true,
    );
    final settings = Get.put(SettingsService(storage).init(), permanent: true);
    final progress = Get.put(ProgressService(storage).init(), permanent: true);
    final wallet = Get.put(WalletService(storage).init(), permanent: true);
    await Get.putAsync(() => PlatformService().init(), permanent: true);
    await Get.putAsync(() => AudioService(settings).init(), permanent: true);
    final consent = Get.put(ConsentService(), permanent: true);
    Get.put(
      AdsService(consent, progress, wallet, storage).init(),
      permanent: true,
    );

    // Billing talks to Google Play; never block the first frame on it.
    final iap = Get.put(IapService(wallet, progress), permanent: true);
    unawaited(iap.init());

    Get.put(PurchaseFeedback(iap), permanent: true);
    Get.put(LifecycleService(wallet, progress), permanent: true);
  }
}
