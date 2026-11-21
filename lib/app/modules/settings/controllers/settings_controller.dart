import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/services/consent_service.dart';
import '../../../data/services/iap_service.dart';
import '../../../data/services/platform_service.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../../routes/app_routes.dart';

class SettingsController extends GetxController {
  final SettingsService settings = Get.find();
  final WalletService wallet = Get.find();
  final ConsentService consent = Get.find();
  final PlatformService platform = Get.find();
  final IapService _iap = Get.find();
  final ProgressService _progress = Get.find();

  final restoring = false.obs;

  @override
  void onReady() {
    super.onReady();
    consent.refresh();
  }

  void openThemes() => Get.toNamed<void>(Routes.themes);
  void openPlus() => Get.toNamed<void>(Routes.plus);
  void openStore() => Get.toNamed<void>(Routes.store);

  Future<void> restore() async {
    if (restoring.value) return;
    restoring.value = true;
    try {
      final found = await _iap.restore();
      AppToast.show(
        found ? 'restore_found'.tr : 'restore_none'.tr,
        tone: found ? ToastTone.good : ToastTone.info,
      );
    } catch (_) {
      AppToast.show('store_unavailable'.tr, tone: ToastTone.bad);
    } finally {
      restoring.value = false;
    }
  }

  Future<void> manageSubscription() => platform.openUrl(
    AppConfig.manageSubscriptionUrl(wallet.plusProductId.value),
  );

  Future<void> privacyOptions() => consent.showPrivacyOptions();

  Future<void> confirmReset() async {
    final ok = await Get.defaultDialog<bool>(
      title: 'reset_title'.tr,
      middleText: 'reset_body'.tr,
      textConfirm: 'reset_confirm'.tr,
      textCancel: 'cancel'.tr,
      radius: 24,
      onConfirm: () => Get.back(result: true),
    );
    if (ok == true) {
      await _progress.resetAll();
      AppToast.show('reset_done'.tr);
    }
  }
}
