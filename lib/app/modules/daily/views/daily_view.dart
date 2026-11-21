import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/game/level_catalog.dart';
import '../controllers/daily_controller.dart';

class DailyView extends GetView<DailyController> {
  const DailyView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final c = controller;
        final streak = c.progress.currentStreak;
        final s = c.progress.streakState.value;
        final solvedToday = c.progress.solvedToday;
        final today = DateTime.now();
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
                    'daily_challenge'.tr,
                    style: context.text.headlineSmall,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EnterAnimation(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child:
                          Icon(
                                Icons.local_fire_department_rounded,
                                size: 32,
                                color: p.accent,
                              )
                              .animate(
                                onPlay: (a) => context.reduceMotion
                                    ? null
                                    : a.repeat(reverse: true),
                              )
                              .scaleXY(
                                begin: 1,
                                end: 1.12,
                                duration: 900.ms,
                                curve: Curves.easeInOut,
                              ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'streak_days'.trParams({'n': '$streak'}),
                            style: displayStyle(22, color: p.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'best_streak'.trParams({'n': '${s.best}'}),
                            style: TextStyle(fontSize: 13, color: p.accentText),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: 'freezes_a11y'.trParams({'n': '${s.freezes}'}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.ac_unit_rounded,
                              size: 20,
                              color: p.primaryText,
                            ),
                            Text(
                              'freezes_n'.trParams({'n': '${s.freezes}'}),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            EnterAnimation(
              delay: const Duration(milliseconds: 80),
              child: AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        _MonthArrow(
                          icon: Icons.chevron_left_rounded,
                          enabled: c.canGoBack,
                          onTap: c.prevMonth,
                          label: 'prev_month'.tr,
                        ),
                        Expanded(
                          child: Text(
                            '${'month_${c.month.value.month}'.tr} ${c.month.value.year}',
                            textAlign: TextAlign.center,
                            style: context.text.titleMedium,
                          ),
                        ),
                        _MonthArrow(
                          icon: Icons.chevron_right_rounded,
                          enabled: c.canGoForward,
                          onTap: c.nextMonth,
                          label: 'next_month'.tr,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final d in [
                          'wd_s',
                          'wd_m',
                          'wd_t',
                          'wd_w',
                          'wd_th',
                          'wd_f',
                          'wd_sa',
                        ])
                          Expanded(
                            child: Text(
                              d.tr,
                              textAlign: TextAlign.center,
                              style: context.text.labelMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 4,
                      children: [
                        for (final day in c.grid)
                          day == null
                              ? const SizedBox()
                              : _DayCell(day: day, onTap: () => c.tapDay(day)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Legend(color: p.successText, label: 'solved'.tr),
                        const SizedBox(width: 14),
                        _Legend(color: p.primary, label: 'today'.tr),
                        const SizedBox(width: 14),
                        _Legend(
                          color: p.muted,
                          label: 'missed'.tr,
                          dashed: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            EnterAnimation(
              delay: const Duration(milliseconds: 140),
              child: Pressable(
                onTap: solvedToday ? null : c.playToday,
                semanticLabel: 'daily_challenge'.tr,
                pressedScale: 0.98,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.contrastSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${'today'.tr} · ${'wd_full_${today.weekday}'.tr}, ${'month_${today.month}'.tr} ${today.day}'
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: p.onContrastMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'daily_card_title'.trParams({
                                'size': '${LevelCatalog.dailySize}',
                                'n':
                                    '${LevelCatalog.daily(today).arrows.length}',
                              }),
                              style: displayStyle(19, color: p.onContrast),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              solvedToday
                                  ? 'daily_done_today'.tr
                                  : 'resets_in'.trParams({
                                      't': c.resetsIn.value,
                                    }),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFFFB37A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              solvedToday
                                  ? Icons.check_rounded
                                  : Icons.play_arrow_rounded,
                              size: 20,
                              color: const Color(0xFF10131C),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              solvedToday ? 'done'.tr : 'play'.tr,
                              style: displayStyle(
                                16,
                                color: const Color(0xFF10131C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            EnterAnimation(
              delay: const Duration(milliseconds: 200),
              child: AppCard(
                child: Row(
                  children: [
                    IconBadge(
                      icon: Icons.emoji_events_rounded,
                      color: p.warnText,
                      background: p.warnSoft,
                      size: 44,
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
                                  'month_badge'.trParams({
                                    'month': 'month_${c.month.value.month}'.tr,
                                  }),
                                  style: context.text.titleSmall,
                                ),
                              ),
                              Text(
                                '${c.solvedThisMonth} / ${AppConfig.monthlyBadgeTarget}',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AppProgressBar(
                            value:
                                c.solvedThisMonth /
                                AppConfig.monthlyBadgeTarget,
                            color: p.warn,
                            height: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!c.wallet.isPlus.value) ...[
              const SizedBox(height: 10),
              Text(
                'archive_hint'.trParams({'plus': AppConfig.plusName}),
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.onTap});

  final CalendarDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final (Color bg, Color fg, BoxBorder? border) = switch (day.state) {
      DayState.solved => (p.successText, Colors.white, null),
      DayState.today => (p.primary, p.onPrimary, null),
      DayState.missed => (
        Colors.transparent,
        p.muted,
        Border.all(color: p.line, width: 1.5),
      ),
      _ => (Colors.transparent, p.ink, null),
    };
    final label = '${day.date.day}, ${'day_${day.state.name}'.tr}';
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.9,
      feedback: day.state != DayState.future,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          child: Text(
            '${day.date.day}',
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: day.state == DayState.today
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: enabled ? onTap : null,
    semanticLabel: label,
    child: SizedBox(
      width: 44,
      height: 44,
      child: Icon(icon, color: context.pal.ink),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: dashed ? null : color,
          borderRadius: BorderRadius.circular(3),
          border: dashed ? Border.all(color: color, width: 1.5) : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: context.text.bodySmall),
    ],
  );
}
