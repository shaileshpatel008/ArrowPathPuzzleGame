import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pressable.dart';
import '../controllers/result_controller.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = controller;
    final r = c.result;
    final on = p.onPrimary;
    final soft = on.withValues(alpha: 0.78);
    final reduce = context.reduceMotion;

    Widget star(int i, double size, {double lift = 0}) {
      final earned = i < r.stars;
      final icon = Padding(
        padding: EdgeInsets.only(bottom: lift),
        child: Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: earned ? p.star : on.withValues(alpha: 0.35),
        ),
      );
      if (reduce) return icon;
      return icon
          .animate(delay: (450 + i * 220).ms)
          .scaleXY(begin: 0, end: 1, duration: 520.ms, curve: Curves.elasticOut)
          .rotate(
            begin: -0.15,
            end: 0,
            duration: 520.ms,
            curve: Curves.easeOutBack,
          );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.skin.isDark
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) c.allLevels();
        },
        child: Scaffold(
          backgroundColor: p.primary,
          body: Stack(
            children: [
              const Positioned.fill(child: ConfettiBurst()),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: CircleIconButton(
                          icon: Icons.close_rounded,
                          onTap: c.allLevels,
                          semanticLabel: 'close'.tr,
                          background: on.withValues(alpha: 0.16),
                          foreground: on,
                          bordered: false,
                        ),
                      ),
                      const Spacer(),
                      Semantics(
                        label: 'stars_a11y'.trParams({'n': '${r.stars}'}),
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              star(0, 64),
                              const SizedBox(width: 8),
                              star(1, 88, lift: 16),
                              const SizedBox(width: 8),
                              star(2, 64),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        (c.isDaily
                                ? 'daily_challenge'.tr
                                : 'level_cleared_n'.trParams({
                                    'n': '${r.args.level}',
                                  }))
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: soft,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 6),
                      Text(
                            c.headline,
                            textAlign: TextAlign.center,
                            style: displayStyle(
                              40,
                              color: on,
                              letterSpacing: -1.2,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 400.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: 6),
                      Text(
                        c.subline,
                        style: TextStyle(fontSize: 15, color: soft),
                      ),
                      const SizedBox(height: 26),
                      Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                _Stat(
                                  value: AnimatedCount(
                                    r.taps,
                                    style: displayStyle(26, color: p.ink),
                                  ),
                                  label: 'taps'.tr,
                                ),
                                _Divider(color: p.line),
                                _Stat(
                                  value: Text(
                                    c.time,
                                    style: displayStyle(26, color: p.ink),
                                  ),
                                  label: 'time'.tr,
                                ),
                                _Divider(color: p.line),
                                _Stat(
                                  value: Text(
                                    c.isDaily
                                        ? '${r.streak}'
                                        : '${r.heartsLeft}/3',
                                    style: displayStyle(26, color: p.ink),
                                  ),
                                  label: c.isDaily
                                      ? 'day_streak'.tr
                                      : 'hearts_left_label'.tr,
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 900.ms, duration: 400.ms)
                          .slideY(begin: 0.15, end: 0),
                      if (r.earnedHint) ...[
                        const SizedBox(height: 12),
                        Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: on.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const IconBadge(
                                    icon: Icons.lightbulb_rounded,
                                    color: Color(0xFF7A5000),
                                    background: Color(0xFFFFF6DB),
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'hint_earned'.tr,
                                          style: TextStyle(
                                            color: on,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'hint_earned_sub'.tr,
                                          style: TextStyle(
                                            color: soft,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 1200.ms)
                            .scaleXY(
                              begin: 0.9,
                              end: 1,
                              curve: Curves.easeOutBack,
                            ),
                      ],
                      const Spacer(),
                      AppButton(
                        label: c.hasNext ? 'next_level'.tr : 'done'.tr,
                        trailingIcon: Icons.arrow_forward_rounded,
                        style: AppButtonStyle.light,
                        onTap: c.next,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _GhostButton(
                              label: 'replay'.tr,
                              onTap: c.replay,
                              color: on,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _GhostButton(
                              label: c.isDaily
                                  ? 'calendar'.tr
                                  : 'all_levels'.tr,
                              onTap: c.allLevels,
                              color: on,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final Widget value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        value,
        const SizedBox(height: 4),
        Text(label, style: context.text.bodySmall),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: color);
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: label,
    child: Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
  );
}
