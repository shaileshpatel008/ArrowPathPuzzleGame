import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/stats_controller.dart';

class StatsView extends GetView<StatsController> {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final pr = c.progress;
          final tiles = [
            (pr.highestCleared.value, 'stat_levels'.tr),
            (pr.perfectClears.value, 'stat_perfect'.tr),
            (pr.streakState.value.best, 'stat_best_streak'.tr),
            (pr.arrowsCleared.value, 'stat_arrows'.tr),
          ];
          final week = c.week;
          final maxVal = math.max(1, week.whereType<int>().fold(0, math.max));
          final todayIdx = DateTime.now().weekday - 1;
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
                    child: Text(
                      'your_stats'.tr,
                      style: context.text.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 104,
                ),
                children: [
                  for (final (i, (value, label)) in tiles.indexed)
                    EnterAnimation.staggered(
                      index: i,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedCount(
                              value,
                              style: displayStyle(30, color: p.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: context.text.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              EnterAnimation(
                delay: const Duration(milliseconds: 160),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'this_week'.tr,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'n_arrows'.trParams({'n': '${c.weekTotal}'}),
                            style: context.text.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 150,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                child: _Bar(
                                  value: week[i],
                                  max: maxVal,
                                  label: 'wd_short_${i + 1}'.tr,
                                  today: i == todayIdx,
                                  index: i,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SectionLabel(
                'achievements'.tr,
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (final (i, a) in c.achievements.indexed)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: i == c.achievements.length - 1
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: p.line.withValues(alpha: 0.6),
                                  ),
                                ),
                        ),
                        child: Row(
                          children: [
                            IconBadge(
                              icon: a.done
                                  ? Icons.emoji_events_rounded
                                  : Icons.star_rounded,
                              color: a.done ? p.warnText : p.primaryText,
                              background: a.done ? p.warnSoft : p.primarySoft,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          a.titleKey.tr,
                                          style: context.text.titleSmall,
                                        ),
                                      ),
                                      Text(
                                        '${math.min(a.progress, a.target)} / ${a.target}',
                                        style: context.text.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  AppProgressBar(
                                    value: a.ratio,
                                    height: 6,
                                    color: a.done ? p.warn : p.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.max,
    required this.label,
    required this.today,
    required this.index,
  });

  final int? value;
  final int max;
  final String label;
  final bool today;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final future = value == null;
    final h = future ? 10.0 : math.max(8.0, (value! / max) * 100);
    return Semantics(
      label: future ? label : '$label: $value',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            future ? '' : '$value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: p.muted,
            ),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: h),
            duration: Duration(
              milliseconds: context.reduceMotion ? 0 : 600 + index * 60,
            ),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Container(
              width: 28,
              height: v,
              decoration: BoxDecoration(
                color: future
                    ? Colors.transparent
                    : (today ? p.primary : p.primarySoft),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                  bottom: Radius.circular(4),
                ),
                border: future ? Border.all(color: p.line, width: 1.5) : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: today ? FontWeight.w700 : FontWeight.w500,
              color: today ? p.ink : p.muted,
            ),
          ),
        ],
      ),
    );
  }
}
