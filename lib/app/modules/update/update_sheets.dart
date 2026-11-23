import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/feedback.dart';
import '../../routes/app_routes.dart';

/// UI for in-app updates. Prompts only appear on the main tabs.
abstract final class UpdateSheets {
  /// True when the player is on the main tabs with nothing on top.
  static bool get canShowNow =>
      Get.currentRoute == Routes.shell &&
      !(Get.isBottomSheetOpen ?? false) &&
      !(Get.isDialogOpen ?? false);

  /// "New update available". Completes with true for "Update now".
  static Future<bool?> updateAvailable() {
    if (!canShowNow) return Future.value(false);
    return AppSheet.show<bool>(
      _UpdateSheet(
        icon: Icons.system_update_rounded,
        title: 'update_title'.tr,
        body: 'update_body'.tr,
        primary: 'update_now'.tr,
      ),
    );
  }

  /// "Update ready". Completes with true for "Restart now".
  static Future<bool?> updateReady() => AppSheet.show<bool>(
    _UpdateSheet(
      icon: Icons.download_done_rounded,
      title: 'update_ready_title'.tr,
      body: 'update_ready_body'.tr,
      primary: 'restart_now'.tr,
    ),
  );

  static void downloadingToast() =>
      AppToast.show('update_downloading'.tr, icon: Icons.downloading_rounded);
}

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.primary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primary;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: IconBadge(
            icon: icon,
            color: p.primaryText,
            background: p.primarySoft,
            size: 72,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center, style: context.text.bodyLarge),
        const SizedBox(height: 20),
        AppButton(label: primary, onTap: () => Get.back<bool>(result: true)),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => Get.back<bool>(result: false),
          child: Text(
            'later'.tr,
            style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
