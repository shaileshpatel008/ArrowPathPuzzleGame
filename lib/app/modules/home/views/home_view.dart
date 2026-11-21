import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/painters.dart';
import '../../../data/game/level_catalog.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final c = controller;
        final finished = c.progress.finishedCampaign;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            // Header
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  const LogoMark(size: 28),
                  const SizedBox(width: 10),
                  Text(
                    AppConfig.shortName,
                    style: displayStyle(22, color: p.ink),
                  ),
                  const Spacer(),
                  StatPill(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: p.accent,
                    value: '${c.progress.currentStreak}',
                    onTap: c.openDaily,
                    semanticLabel: 'streak_days'.trParams({
                      'n': '${c.progress.currentStreak}',
                    }),
                  ),
                  const SizedBox(width: 8),
                  StatPill(
                    icon: Icons.lightbulb_rounded,
                    iconColor: p.primary,
                    value: '${c.wallet.hints.value}',
                    onTap: c.openStore,
                    semanticLabel: 'hints_open_shop'.trParams({
                      'n': '${c.wallet.hints.value}',
                    }),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: p.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: p.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            EnterAnimation(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.greetingKey.tr,
                    style: context.text.bodyMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    finished
                        ? 'home_all_done'.tr
                        : 'home_ready'.trParams({'n': '${c.nextLevel}'}),
                    style: context.text.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            EnterAnimation(
              delay: 80.ms,
              child: _HeroCard(controller: c),
            ),
            const SizedBox(height: 16),
            EnterAnimation(
              delay: 140.ms,
              child: _DailyCard(controller: c),
            ),
            const SizedBox(height: 16),
            EnterAnimation(
              delay: 200.ms,
              child: Row(
                children: [
                  Expanded(
                    child: AppCard(
                      onTap: c.openThemes,
                      semanticLabel: 'themes'.tr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (final color in p.skin.swatches)
                                Container(
                                  width: 18,
                                  height: 18,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'themes'.tr,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            p.skin.nameKey.tr,
                            style: context.text.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      onTap: c.openStats,
                      semanticLabel: 'stats'.tr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 18,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final (i, h) in [
                                  8.0,
                                  14.0,
                                  11.0,
                                  18.0,
                                ].indexed)
                                  Container(
                                    width: 8,
                                    height: h,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: i == 3 ? p.primary : p.primarySoft,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'stats'.tr,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'levels_cleared_n'.trParams({
                              'n': '${c.progress.highestCleared.value}',
                            }),
                            style: context.text.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (c.showPlusBanner) ...[
              const SizedBox(height: 16),
              EnterAnimation(
                delay: 260.ms,
                child: _PlusBanner(onTap: c.openPlus),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = controller;
    final ch = c.chapter;
    final spec = c.nextSpec;
    final onHero = p.onPrimary;
    final soft = onHero.withValues(alpha: 0.78);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'chapter_label'.trParams({
                        'num': '${ch.number}',
                        'title': ch.titleKey.tr,
                      }).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: soft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'level_n'.trParams({'n': '${c.nextLevel}'}),
                      style: displayStyle(
                        42,
                        color: onHero,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'arrows_board'.trParams({
                        'arrows': '${spec.arrows.length}',
                        'size': '${spec.size}',
                      }),
                      style: TextStyle(fontSize: 14, color: soft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(
                child: MiniBoard(
                  spec: spec,
                  size: 96,
                  cellColor: onHero.withValues(alpha: 0.16),
                  tileColor: (_) => onHero,
                  glyphColor: p.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'chapter_progress'.tr,
                style: TextStyle(fontSize: 13, color: soft),
              ),
              const Spacer(),
              Text(
                '${c.chapterCleared} / ${ch.levelCount}',
                style: TextStyle(fontSize: 13, color: soft),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(
            value: c.chapterCleared / ch.levelCount,
            color: onHero,
            track: onHero.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 18),
          _PlayButton(
            label: c.progress.finishedCampaign ? 'replay_last'.tr : 'play'.tr,
            onTap: c.play,
            background: onHero,
            foreground: p.primary,
          ),
        ],
      ),
    );
  }
}

/// Primary play button with a gentle breathing glow.
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final button = AppButton(
      label: label,
      onTap: onTap,
      icon: Icons.play_arrow_rounded,
      style: AppButtonStyle.light,
    );
    if (context.reduceMotion) return button;
    return button
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1,
          end: 1.025,
          duration: 1100.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final solved = controller.progress.solvedToday;
    return AppCard(
      onTap: controller.playDaily,
      semanticLabel: 'daily_challenge'.tr,
      child: Row(
        children: [
          IconBadge(
            icon: solved ? Icons.check_rounded : Icons.calendar_month_rounded,
            color: solved ? p.successText : p.accentText,
            background: solved ? p.successSoft : p.accentSoft,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('daily_challenge'.tr, style: context.text.titleMedium),
                const SizedBox(height: 3),
                Text(
                  'daily_meta'.trParams({'size': '${LevelCatalog.dailySize}'}),
                  style: context.text.bodyMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 3),
                Obx(
                  () => Text(
                    solved
                        ? 'daily_done_today'.tr
                        : 'resets_in'.trParams({
                            't': controller.resetsIn.value,
                          }),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: solved ? p.successText : p.accentText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.contrastSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              solved ? 'view'.tr : 'play'.tr,
              style: TextStyle(
                color: p.onContrast,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusBanner extends StatelessWidget {
  const _PlusBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      onTap: onTap,
      semanticLabel: AppConfig.plusName,
      color: p.contrastSurface,
      borderColor: p.contrastSurface,
      child: Row(
        children: [
          const LogoMark(size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.plusName,
                  style: TextStyle(
                    color: p.onContrast,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'plus_banner_sub'.tr,
                  style: TextStyle(color: p.onContrastMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.onContrast),
        ],
      ),
    );
  }
}
