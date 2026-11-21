import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../config/iap_config.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/services/iap_service.dart';
import '../../../routes/app_routes.dart';
import '../controllers/game_controller.dart';

/// Bottom sheets shown from the game screen.
abstract final class GameSheets {
  static Future<void> outOfHearts(GameController c) =>
      AppSheet.show<void>(_OutOfHeartsSheet(c: c), dismissible: false);

  static Future<void> outOfHints(GameController c) =>
      AppSheet.show<void>(_OutOfHintsSheet(c: c));

  static Future<void> pause(GameController c) =>
      AppSheet.show<void>(_PauseSheet(c: c));
}

class _OutOfHeartsSheet extends StatelessWidget {
  const _OutOfHeartsSheet({required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Obx(() {
      final canAd = c.ads.eligible && c.ads.rewardedReady.value;
      final hints = c.wallet.hints.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Icon(Icons.favorite_border_rounded, size: 32, color: p.line),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'out_of_hearts'.tr,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'cleared_x_of_y'.trParams({
              'n': '${c.cleared}',
              'total': '${c.total}',
            }),
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 14),
          AppProgressBar(value: c.cleared / c.total, height: 10),
          if (!c.aim.value) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.gps_fixed_rounded, size: 20, color: p.primaryText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('tip_aim'.tr, style: context.text.bodyMedium),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: 'try_again'.tr,
            icon: Icons.restart_alt_rounded,
            onTap: () {
              Get.back<void>();
              c.restart();
            },
          ),
          if (canAd) ...[
            const SizedBox(height: 10),
            _OptionRow(
              icon: Icons.ondemand_video_rounded,
              iconColor: p.primaryText,
              title: 'revive_ad'.tr,
              trailing: _Tag(
                text: 'free'.tr,
                bg: p.successSoft,
                fg: p.successText,
              ),
              onTap: () async {
                Get.back<void>();
                await c.reviveWithAd();
              },
            ),
          ],
          if (hints > 0) ...[
            const SizedBox(height: 10),
            _OptionRow(
              icon: Icons.favorite_rounded,
              iconColor: p.danger,
              title: 'revive_hint'.tr,
              trailing: _Tag(
                text: 'one_hint'.tr,
                bg: p.warnSoft,
                fg: p.warnText,
                icon: Icons.lightbulb_rounded,
              ),
              onTap: () {
                Get.back<void>();
                c.reviveWithHint();
              },
            ),
          ],
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              Get.back<void>();
              c.exitToLevels();
            },
            child: Text(
              'back_to_levels'.tr,
              style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    });
  }
}

class _OutOfHintsSheet extends StatelessWidget {
  const _OutOfHintsSheet({required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final iap = Get.find<IapService>();
    return Obx(() {
      final canAd = c.ads.eligible && c.ads.rewardedReady.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(
                icon: Icons.lightbulb_rounded,
                color: p.warnText,
                background: p.warnSoft,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('out_of_hints'.tr, style: context.text.headlineSmall),
                    const SizedBox(height: 2),
                    Text('out_of_hints_sub'.tr, style: context.text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (canAd) ...[
            _OptionRow(
              icon: Icons.ondemand_video_rounded,
              iconColor: p.primaryText,
              title: 'hint_ad'.tr,
              trailing: _Tag(
                text: 'free'.tr,
                bg: p.successSoft,
                fg: p.successText,
              ),
              onTap: () async {
                Get.back<void>();
                await c.earnHintWithAd();
              },
            ),
            const SizedBox(height: 10),
          ],
          for (final id in [IapConfig.hints15, IapConfig.hints5]) ...[
            _OptionRow(
              icon: Icons.lightbulb_outline_rounded,
              iconColor: p.primaryText,
              title: 'n_hints'.trParams({'n': '${IapConfig.hintPacks[id]}'}),
              subtitle: id == IapConfig.hints15 ? 'most_popular'.tr : null,
              highlighted: id == IapConfig.hints15,
              trailing: _Tag(
                text: iap.priceOf(id) ?? '—',
                bg: p.primary,
                fg: p.onPrimary,
              ),
              onTap: () {
                Get.back<void>();
                iap.buy(id);
              },
            ),
            const SizedBox(height: 10),
          ],
          if (!c.wallet.isPlus.value)
            _OptionRow(
              icon: Icons.workspace_premium_rounded,
              iconColor: p.onContrast,
              title: 'get_plus'.tr,
              subtitle: 'plus_hints_daily'.trParams({
                'n': '${AppConfig.plusDailyHints}',
              }),
              dark: true,
              trailing: Icon(Icons.chevron_right_rounded, color: p.onContrast),
              onTap: () {
                Get.back<void>();
                Get.toNamed<void>(Routes.plus);
              },
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 18, color: p.star),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'free_hint_tip'.tr,
                    style: context.text.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Get.back<void>();
                  Get.toNamed<void>(Routes.store);
                },
                child: Text(
                  'see_all_packs'.tr,
                  style: TextStyle(
                    color: p.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: Get.back<void>,
                child: Text(
                  'not_now'.tr,
                  style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _PauseSheet extends StatelessWidget {
  const _PauseSheet({required this.c});

  final GameController c;

  @override
  Widget build(BuildContext context) {
    final s = c.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'paused'.tr,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          c.title,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(
            () => Column(
              children: [
                _QuickToggle(
                  label: 'sound_effects'.tr,
                  value: s.sound.value,
                  onChanged: (v) => s.sound.value = v,
                ),
                _QuickToggle(
                  label: 'music'.tr,
                  value: s.music.value,
                  onChanged: (v) => s.music.value = v,
                ),
                _QuickToggle(
                  label: 'vibration'.tr,
                  value: s.haptics.value,
                  onChanged: (v) => s.haptics.value = v,
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'resume'.tr,
          icon: Icons.play_arrow_rounded,
          onTap: Get.back<void>,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'restart'.tr,
                style: AppButtonStyle.secondary,
                display: false,
                height: 52,
                onTap: () {
                  Get.back<void>();
                  c.restart();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'tab_levels'.tr,
                style: AppButtonStyle.secondary,
                display: false,
                height: 52,
                onTap: () {
                  Get.back<void>();
                  c.exitToLevels();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickToggle extends StatelessWidget {
  const _QuickToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      border: last ? null : Border(bottom: BorderSide(color: context.pal.line)),
    ),
    child: Row(
      children: [
        Expanded(child: Text(label, style: context.text.titleSmall)),
        AppSwitch(value: value, onChanged: onChanged, label: label),
      ],
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.subtitle,
    this.dark = false,
    this.highlighted = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final bool dark;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Pressable(
      onTap: onTap,
      semanticLabel: subtitle == null ? title : '$title. $subtitle',
      pressedScale: 0.98,
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: dark ? p.contrastSurface : p.surface,
          borderRadius: BorderRadius.circular(18),
          border: dark
              ? null
              : Border.all(
                  color: highlighted ? p.primary : p.line,
                  width: highlighted ? 2 : 1,
                ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: dark ? p.onContrast : p.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: dark ? p.onContrastMuted : p.muted,
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
