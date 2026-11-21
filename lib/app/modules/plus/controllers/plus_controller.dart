import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../config/iap_config.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/services/iap_service.dart';
import '../../../data/services/platform_service.dart';
import '../../../data/services/wallet_service.dart';

class PlusPlan {
  const PlusPlan(
    this.productId,
    this.nameKey,
    this.subKey,
    this.periodKey,
    this.ctaKey,
    this.fineKey, {
    this.tagKey,
  });

  final String productId;
  final String nameKey;
  final String subKey;
  final String periodKey;
  final String ctaKey;
  final String fineKey;
  final String? tagKey;
}

class PlusController extends GetxController {
  final IapService iap = Get.find();
  final WalletService wallet = Get.find();
  final PlatformService platform = Get.find();

  /// True when opened as the one-time offer after level 15.
  late final bool fromOffer = Get.arguments == 'offer';

  static const plans = [
    PlusPlan(
      IapConfig.plusYearly,
      'plan_yearly',
      'plan_yearly_sub',
      'per_year',
      'cta_yearly',
      'fine_yearly',
      tagKey: 'best_value',
    ),
    PlusPlan(
      IapConfig.plusMonthly,
      'plan_monthly',
      'plan_monthly_sub',
      'per_month',
      'cta_monthly',
      'fine_monthly',
    ),
    PlusPlan(
      IapConfig.plusLifetime,
      'plan_lifetime',
      'plan_lifetime_sub',
      'once',
      'cta_lifetime',
      'fine_lifetime',
    ),
  ];

  final selected = 0.obs;

  PlusPlan get plan => plans[selected.value];

  String priceOf(PlusPlan p) => iap.priceOf(p.productId) ?? '—';

  String get fineText => plan.fineKey.trParams({'price': priceOf(plan)});

  void select(int i) => selected.value = i;

  void buy() => iap.buy(plan.productId);

  Future<void> restore() async {
    final found = await iap.restore();
    AppToast.show(
      found ? 'restore_found'.tr : 'restore_none'.tr,
      tone: found ? ToastTone.good : ToastTone.info,
    );
  }

  void manage() => platform.openUrl(
    AppConfig.manageSubscriptionUrl(wallet.plusProductId.value),
  );

  void close() => Get.back<void>();
}
