import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../../config/iap_config.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/feedback.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/iap_service.dart';
import '../../data/services/settings_service.dart';
import '../../data/services/wallet_service.dart';

/// Shows purchase results wherever the purchase was started from
/// (shop, Plus screen, in-game "out of hints" sheet).
class PurchaseFeedback extends GetxService {
  PurchaseFeedback(this._iap);

  final IapService _iap;
  StreamSubscription<PurchaseEvent>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _iap.events.listen(_onEvent);
  }

  void _onEvent(PurchaseEvent e) {
    switch (e) {
      case PurchaseSucceeded(:final productId):
        Get.find<AudioService>().play(Sfx.reward);
        Get.find<SettingsService>().success();
        unawaited(AppSheet.show<void>(_SuccessSheet(productId: productId)));
      case PurchaseFailed(:final productId, :final message):
        if (message == 'store_unavailable') {
          AppToast.show('store_unavailable'.tr, tone: ToastTone.bad);
        } else {
          unawaited(AppSheet.show<void>(_FailedSheet(productId: productId)));
        }
      case PurchasePending():
        AppToast.show('purchase_pending'.tr);
      case PurchaseCancelled():
        break;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final wallet = Get.find<WalletService>();
    final String body;
    if (IapConfig.isConsumable(productId)) {
      body = 'purchase_hints_body'.trParams({
        'n': '${IapConfig.hintPacks[productId]}',
        'total': '${wallet.hints.value}',
      });
    } else if (productId == IapConfig.themePack) {
      body = 'purchase_theme_body'.tr;
    } else {
      body = 'purchase_plus_body'.trParams({'plus': AppConfig.plusName});
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: context.reduceMotion ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 650),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: p.successSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 44,
                    color: p.successText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'purchase_done'.tr,
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'purchase_linked'.tr,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 20),
            AppButton(label: 'awesome'.tr, onTap: Get.back<void>),
          ],
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: -40,
          height: 360,
          child: ConfettiBurst(particles: 50, origin: Alignment(0, -0.6)),
        ),
      ],
    );
  }
}

class _FailedSheet extends StatelessWidget {
  const _FailedSheet({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: p.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.priority_high_rounded,
              size: 36,
              color: p.dangerText,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'purchase_failed'.tr,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'purchase_failed_body'.tr,
          textAlign: TextAlign.center,
          style: context.text.bodyLarge,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'try_again'.tr,
                display: false,
                height: 52,
                onTap: () {
                  Get.back<void>();
                  Get.find<IapService>().buy(productId);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'not_now'.tr,
                style: AppButtonStyle.secondary,
                display: false,
                height: 52,
                onTap: Get.back<void>,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
