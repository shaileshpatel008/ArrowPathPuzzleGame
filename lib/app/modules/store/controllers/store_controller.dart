import 'package:get/get.dart';

import '../../../config/iap_config.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/services/iap_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../../routes/app_routes.dart';

class HintPack {
  const HintPack(this.id, this.amount, this.tagKey);

  final String id;
  final int amount;
  final String? tagKey;
}

class StoreController extends GetxController {
  final IapService iap = Get.find();
  final WalletService wallet = Get.find();
  final restoring = false.obs;

  static const packs = [
    HintPack(IapConfig.hints5, 5, null),
    HintPack(IapConfig.hints15, 15, 'popular'),
    HintPack(IapConfig.hints40, 40, 'best_value'),
  ];

  @override
  void onReady() {
    super.onReady();
    // Retry loading products if the first attempt happened offline.
    if (iap.available.value && iap.products.isEmpty) iap.loadProducts();
  }

  String priceOf(String id) => iap.priceOf(id) ?? '—';

  bool canBuy(String id) => iap.available.value && iap.products.containsKey(id);

  void buy(String id) => iap.buy(id);

  void openPlus() => Get.toNamed<void>(Routes.plus);

  Future<void> restore() async {
    if (restoring.value) return;
    restoring.value = true;
    try {
      final found = await iap.restore();
      AppToast.show(
        found ? 'restore_found'.tr : 'restore_none'.tr,
        tone: found ? ToastTone.good : ToastTone.info,
      );
    } finally {
      restoring.value = false;
    }
  }
}
