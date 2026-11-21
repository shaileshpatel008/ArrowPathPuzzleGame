import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pressable.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = controller;
    final s = c.settings;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final isPlus = c.wallet.isPlus.value;
        final hasSub = c.wallet.plusSubscription.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Text(
                    'tab_settings'.tr,
                    style: context.text.headlineSmall,
                  ),
                ),
              ),
            ),
            SectionLabel(
              'gameplay'.tr,
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
            ),
            _Group(
              children: [
                _ToggleRow(
                  label: 'aim_default'.tr,
                  sub: 'aim_default_sub'.tr,
                  value: s.aimByDefault.value,
                  onChanged: (v) => s.aimByDefault.value = v,
                ),
                _ToggleRow(
                  label: 'sound_effects'.tr,
                  value: s.sound.value,
                  onChanged: (v) => s.sound.value = v,
                ),
                _ToggleRow(
                  label: 'music'.tr,
                  value: s.music.value,
                  onChanged: (v) => s.music.value = v,
                ),
                _ToggleRow(
                  label: 'vibration'.tr,
                  value: s.haptics.value,
                  onChanged: (v) => s.haptics.value = v,
                ),
              ],
            ),
            SectionLabel('accessibility'.tr),
            _Group(
              children: [
                _ToggleRow(
                  label: 'colorblind'.tr,
                  sub: 'colorblind_sub'.tr,
                  value: s.colorBlind.value,
                  onChanged: (v) => s.colorBlind.value = v,
                ),
                _ToggleRow(
                  label: 'reduce_motion'.tr,
                  value: s.reduceMotion.value,
                  onChanged: (v) => s.reduceMotion.value = v,
                ),
              ],
            ),
            SectionLabel('purchases'.tr),
            _Group(
              children: [
                _LinkRow(
                  label: AppConfig.plusName,
                  onTap: c.openPlus,
                  trailing: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPlus ? p.successSoft : p.contrastSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isPlus ? 'active'.tr : 'get_plus'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isPlus ? p.successText : p.onContrast,
                      ),
                    ),
                  ),
                ),
                _LinkRow(
                  label: 'shop'.tr,
                  onTap: c.openStore,
                  value: 'hints_n'.trParams({'n': '${c.wallet.hints.value}'}),
                ),
                _LinkRow(
                  label: 'restore_purchases'.tr,
                  onTap: c.restore,
                  trailing: c.restoring.value
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: p.primary,
                          ),
                        )
                      : null,
                ),
                if (hasSub)
                  _LinkRow(
                    label: 'manage_subscription'.tr,
                    onTap: c.manageSubscription,
                    external: true,
                  ),
              ],
            ),
            SectionLabel('more'.tr),
            _Group(
              children: [
                _LinkRow(
                  label: 'theme'.tr,
                  value: p.skin.nameKey.tr,
                  onTap: c.openThemes,
                ),
                _LinkRow(
                  label: 'rate_us'.tr,
                  onTap: c.platform.openStoreListing,
                  external: true,
                ),
                _LinkRow(
                  label: 'contact_support'.tr,
                  onTap: c.platform.emailSupport,
                  external: true,
                ),
                if (c.consent.privacyOptionsRequired.value)
                  _LinkRow(
                    label: 'privacy_options'.tr,
                    onTap: c.privacyOptions,
                  ),
                _LinkRow(
                  label: 'privacy_policy'.tr,
                  onTap: c.platform.openPrivacyPolicy,
                  external: true,
                ),
                _LinkRow(
                  label: 'terms'.tr,
                  onTap: c.platform.openTerms,
                  external: true,
                ),
                _LinkRow(
                  label: 'reset_progress'.tr,
                  onTap: c.confirmReset,
                  danger: true,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                '${AppConfig.appName} · ${'version'.tr} ${c.platform.version.value}',
                style: context.text.bodySmall,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      radius: 20,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == children.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: p.line.withValues(alpha: 0.6),
                        ),
                      ),
              ),
              child: children[i],
            ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
  });

  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: context.text.titleSmall),
                if (sub != null) Text(sub!, style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSwitch(value: value, onChanged: onChanged, label: label),
        ],
      ),
    ),
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.onTap,
    this.value,
    this.trailing,
    this.external = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? value;
  final Widget? trailing;
  final bool external;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Pressable(
      onTap: onTap,
      semanticLabel: value == null ? label : '$label, $value',
      pressedScale: 0.99,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.text.titleSmall?.copyWith(
                  color: danger ? p.dangerText : p.ink,
                ),
              ),
            ),
            if (value != null) ...[
              Text(value!, style: context.text.bodyMedium),
              const SizedBox(width: 4),
            ],
            trailing ??
                Icon(
                  external
                      ? Icons.open_in_new_rounded
                      : Icons.chevron_right_rounded,
                  size: external ? 18 : 22,
                  color: p.muted,
                ),
          ],
        ),
      ),
    );
  }
}
