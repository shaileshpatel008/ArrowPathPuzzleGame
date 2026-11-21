import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../config/iap_config.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/theme/skins.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/painters.dart';
import '../../../core/widgets/pressable.dart';
import '../controllers/store_controller.dart';

class StoreView extends GetView<StoreController> {
  const StoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final isPlus = c.wallet.isPlus.value;
          final themeOwned = c.wallet.ownsAllThemes;
          final busy = c.iap.busyProductId.value;
          final unavailable = !c.iap.loading.value && !c.iap.available.value;
          // Touch the product map so prices refresh once loaded.
          c.iap.products.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: Get.back<void>,
                    semanticLabel: 'back'.tr,
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    header: true,
                    child: Text('shop'.tr, style: context.text.headlineSmall),
                  ),
                  const Spacer(),
                  StatPill(
                    icon: Icons.lightbulb_rounded,
                    iconColor: p.primary,
                    value: '${c.wallet.hints.value}',
                    semanticLabel: 'hints_n'.trParams({
                      'n': '${c.wallet.hints.value}',
                    }),
                  ),
                ],
              ),
              if (unavailable) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.warnSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: p.warnText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'store_unavailable_long'.tr,
                          style: TextStyle(color: p.warnText, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              EnterAnimation(
                child: AppCard(
                  onTap: c.openPlus,
                  semanticLabel: AppConfig.plusName,
                  color: p.contrastSurface,
                  borderColor: p.contrastSurface,
                  radius: 26,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const LogoMark(size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppConfig.plusName,
                              style: displayStyle(21, color: p.onContrast),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPlus ? p.success : p.warn,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text(
                              isPlus ? 'active'.tr : 'best_deal'.tr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10131C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final perk in [
                        'perk_hints',
                        'perk_themes',
                        'perk_archive',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            perk.trParams({'n': '${AppConfig.plusDailyHints}'}),
                            style: TextStyle(
                              color: p.onContrastMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          isPlus ? 'view_membership'.tr : 'see_plans'.tr,
                          style: const TextStyle(
                            color: Color(0xFF10131C),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SectionLabel('hint_packs'.tr),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, pack) in StoreController.packs.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: EnterAnimation.staggered(
                        index: i,
                        base: const Duration(milliseconds: 80),
                        child: _PackCard(
                          pack: pack,
                          price: c.priceOf(pack.id),
                          enabled: c.canBuy(pack.id),
                          busy: busy == pack.id,
                          onBuy: () => c.buy(pack.id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SectionLabel('themes'.tr),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ColoredBox(
                                      color: Skins.forest.tileUp,
                                    ),
                                  ),
                                  Expanded(
                                    child: ColoredBox(color: Skins.neon.tileUp),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ColoredBox(
                                      color: Skins.neon.tileRight,
                                    ),
                                  ),
                                  Expanded(
                                    child: ColoredBox(
                                      color: Skins.forest.tileRight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'theme_pack'.tr,
                            style: context.text.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            themeOwned
                                ? 'theme_pack_owned'.tr
                                : 'theme_pack_sub'.tr,
                            style: context.text.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (themeOwned)
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.successSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'owned'.tr,
                          style: TextStyle(
                            color: p.successText,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      _PriceButton(
                        price: c.priceOf(IapConfig.themePack),
                        enabled: c.canBuy(IapConfig.themePack),
                        busy: busy == IapConfig.themePack,
                        dark: true,
                        label: 'buy_theme_pack'.tr,
                        onTap: () => c.buy(IapConfig.themePack),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Pressable(
                  onTap: c.restore,
                  semanticLabel: 'restore_purchases'.tr,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: c.restoring.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: p.primary,
                            ),
                          )
                        : Text(
                            'restore_purchases'.tr,
                            style: TextStyle(
                              color: p.primaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
              Text(
                'prices_local'.tr,
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.price,
    required this.enabled,
    required this.busy,
    required this.onBuy,
  });

  final HintPack pack;
  final String price;
  final bool enabled;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final popular = pack.tagKey == 'popular';
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: popular ? p.primary : p.line,
              width: popular ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              IconBadge(
                icon: Icons.lightbulb_rounded,
                color: p.primaryText,
                background: p.primarySoft,
                size: 44,
              ),
              const SizedBox(height: 8),
              Text('${pack.amount}', style: displayStyle(24, color: p.ink)),
              Text('hints_word'.tr, style: context.text.bodySmall),
              const SizedBox(height: 10),
              _PriceButton(
                price: price,
                enabled: enabled,
                busy: busy,
                expand: true,
                label: 'buy_n_hints'.trParams({
                  'n': '${pack.amount}',
                  'price': price,
                }),
                onTap: onBuy,
              ),
            ],
          ),
        ),
        if (pack.tagKey != null)
          Positioned(
            top: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: popular ? p.primary : p.warn,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pack.tagKey!.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: popular ? p.onPrimary : const Color(0xFF10131C),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceButton extends StatelessWidget {
  const _PriceButton({
    required this.price,
    required this.enabled,
    required this.busy,
    required this.onTap,
    required this.label,
    this.dark = false,
    this.expand = false,
  });

  final String price;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;
  final String label;
  final bool dark;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final bg = dark ? p.contrastSurface : p.primary;
    final fg = dark ? p.onContrast : p.onPrimary;
    return Pressable(
      onTap: enabled && !busy ? onTap : null,
      semanticLabel: label,
      child: Container(
        height: 40,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Text(
                price,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}
