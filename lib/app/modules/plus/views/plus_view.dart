import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/painters.dart';
import '../../../core/widgets/pressable.dart';
import '../controllers/plus_controller.dart';

/// The Plus paywall. Always dark, always closable, with the full
/// subscription disclosure Google Play requires (price, period, renewal,
/// how to cancel).
class PlusView extends GetView<PlusController> {
  const PlusView({super.key});

  static const _bg = Color(0xFF10131C);
  static const _card = Color(0xFF171B29);
  static const _selected = Color(0xFF1B2250);
  static const _accent = Color(0xFF8B9AFF);
  static const _muted = Color(0xFFB4BACB);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Obx(() {
            final member = c.wallet.isPlus.value;
            c.iap.products.length;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      if (c.fromOffer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF24307A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'offer_chip'.tr,
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const Spacer(),
                      CircleIconButton(
                        icon: Icons.close_rounded,
                        onTap: c.close,
                        semanticLabel: 'close'.tr,
                        background: const Color(0xFF1E2335),
                        foreground: Colors.white,
                        bordered: false,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                    children: [
                      Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: context.reduceMotion ? 1 : 0,
                              end: 1,
                            ),
                            duration: const Duration(milliseconds: 1000),
                            builder: (_, t, _) =>
                                LogoMark(size: 58, progress: t),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppConfig.plusName,
                                  style: displayStyle(
                                    30,
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member
                                      ? 'plus_member_sub'.tr
                                      : 'plus_tagline'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      for (final (i, perk) in [
                        'perk_hints',
                        'perk_themes',
                        'perk_archive',
                        'perk_freeze',
                        'perk_no_ads',
                      ].indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child:
                              Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF24307A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: _accent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          perk.trParams({
                                            'n': '${AppConfig.plusDailyHints}',
                                          }),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  .animate(delay: (100 + i * 70).ms)
                                  .fadeIn(duration: 300.ms)
                                  .slideX(begin: 0.06, end: 0),
                        ),
                      const SizedBox(height: 10),
                      if (member)
                        _MemberCard(controller: c)
                      else
                        Semantics(
                          label: 'choose_plan'.tr,
                          child: Column(
                            children: [
                              for (final (i, plan)
                                  in PlusController.plans.indexed) ...[
                                _PlanTile(
                                  plan: plan,
                                  price: c.priceOf(plan),
                                  selected: c.selected.value == i,
                                  onTap: () => c.select(i),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (!member)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                    child: Column(
                      children: [
                        AppButton(
                          label: c.plan.ctaKey.tr,
                          style: AppButtonStyle.light,
                          loading:
                              c.iap.busyProductId.value == c.plan.productId,
                          onTap: c.buy,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          c.fineText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.45,
                            color: Color(0xFF9AA1B4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FooterLink(label: 'restore'.tr, onTap: c.restore),
                            _FooterLink(
                              label: 'terms'.tr,
                              onTap: c.platform.openTerms,
                            ),
                            _FooterLink(
                              label: 'privacy_policy'.tr,
                              onTap: c.platform.openPrivacyPolicy,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final PlusPlan plan;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '${plan.nameKey.tr}, $price ${plan.periodKey.tr}',
      pressedScale: 0.98,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? PlusView._selected : PlusView._card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? PlusView._accent : const Color(0xFF2A3045),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? PlusView._accent
                          : const Color(0xFF5B6278),
                      width: 2,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: PlusView._accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.nameKey.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        plan.subKey.tr,
                        style: const TextStyle(
                          color: PlusView._muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$price ${plan.periodKey.tr}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (plan.tagKey != null)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5B700),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  plan.tagKey!.tr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10131C),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.controller});

  final PlusController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final sub = c.wallet.plusSubscription.value;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PlusView._selected,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified_rounded, color: PlusView._accent, size: 36),
          const SizedBox(height: 10),
          Text(
            'plus_active_title'.tr,
            textAlign: TextAlign.center,
            style: displayStyle(20, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            sub ? 'plus_active_sub'.tr : 'plus_lifetime_active'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PlusView._muted, fontSize: 13),
          ),
          if (sub) ...[
            const SizedBox(height: 14),
            AppButton(
              label: 'manage_subscription'.tr,
              style: AppButtonStyle.light,
              display: false,
              height: 50,
              onTap: c.manage,
            ),
          ],
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: label,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFB9C3FF),
          fontSize: 12,
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFFB9C3FF),
        ),
      ),
    ),
  );
}
