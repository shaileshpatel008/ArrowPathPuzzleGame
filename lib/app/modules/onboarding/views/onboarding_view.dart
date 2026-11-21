import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/basics.dart';
import '../../../core/widgets/painters.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/game/direction.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  static const _pages = [
    ('onb1_title', 'onb1_body'),
    ('onb2_title', 'onb2_body'),
    ('onb3_title', 'onb3_body'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Obx(
                      () => Text(
                        'onb_step'.trParams({
                          'n': '${controller.page.value + 1}',
                          'total': '${OnboardingController.pageCount}',
                        }),
                        style: context.text.labelMedium,
                      ),
                    ),
                    const Spacer(),
                    Pressable(
                      onTap: controller.skip,
                      semanticLabel: 'skip'.tr,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'skip'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: p.muted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _OnboardPage(
                    index: i,
                    title: _pages[i].$1.tr,
                    body: _pages[i].$2.tr,
                  ),
                ),
              ),
              Obx(() {
                final current = controller.page.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < OnboardingController.pageCount; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == current ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == current ? p.primary : p.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 20),
              Obx(
                () => AppButton(
                  label: controller.isLast ? 'onb_play'.tr : 'next'.tr,
                  onTap: controller.next,
                  trailingIcon: controller.isLast
                      ? Icons.play_arrow_rounded
                      : Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.index,
    required this.title,
    required this.body,
  });

  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final (String chip, Color chipBg, Color chipFg, IconData chipIcon)? badge =
        switch (index) {
          1 => (
            'onb_minus_heart'.tr,
            p.dangerSoft,
            p.dangerText,
            Icons.favorite_rounded,
          ),
          2 => (
            'onb_hint_safe'.tr,
            p.warnSoft,
            p.warnText,
            Icons.lightbulb_rounded,
          ),
          _ => null,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: AppCard(
            radius: 32,
            padding: EdgeInsets.zero,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(child: SizedBox()),
                ExcludeSemantics(child: _Illustration(step: index)),
                if (badge != null)
                  Positioned(
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: badge.$2,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badge.$4, size: 16, color: badge.$3),
                          const SizedBox(width: 6),
                          Text(
                            badge.$1,
                            style: TextStyle(
                              color: badge.$3,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
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
        const SizedBox(height: 28),
        Text(title, style: context.text.headlineMedium),
        const SizedBox(height: 10),
        SizedBox(height: 72, child: Text(body, style: context.text.bodyLarge)),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Looping animated demo of a mechanic.
class _Illustration extends StatefulWidget {
  const _Illustration({required this.step});

  final int step;

  @override
  State<_Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<_Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.value = 0.3;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 236,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        painter: _DemoPainter(widget.step, _c.value, context.pal),
      ),
    ),
  );
}

class _DemoPainter extends CustomPainter {
  _DemoPainter(this.step, this.t, this.p);

  final int step;
  final double t;
  final AppPalette p;

  static const cell = 68.0;
  static const stepPx = 84.0;

  Rect _rect(double row, double col) =>
      Rect.fromLTWH(col * stepPx, row * stepPx, cell, cell);

  double _seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  void _ring(Canvas canvas, Rect r, Color color, double strength) {
    if (strength <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: strength)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(24)),
      paint,
    );
  }

  void _tile(
    Canvas canvas,
    Rect r,
    Direction d,
    Color color, {
    double opacity = 1,
  }) {
    if (opacity <= 0) return;
    canvas.saveLayer(
      r.inflate(4),
      Paint()..color = Colors.black.withValues(alpha: opacity),
    );
    paintTile(canvas, r, color, radiusFactor: 0.26);
    paintArrowGlyph(canvas, r.translate(0, -2), d, p.skin.glyph);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            _rect(r.toDouble(), c.toDouble()),
            const Radius.circular(18),
          ),
          Paint()..color = p.cell,
        );
      }
    }
    final s = p.skin;
    switch (step) {
      case 0:
        _tile(canvas, _rect(0, 1), Direction.down, s.tileDown);
        _tile(canvas, _rect(2, 2), Direction.up, s.tileLeft);
        final tap = _seg(0.0, 0.22);
        final fly = Curves.easeIn.transform(_seg(0.22, 0.55));
        final back = _seg(0.82, 1.0);
        final x = fly * 3.2;
        final path = Paint()..color = p.primarySoft;
        if (fly < 1) {
          for (var c = 1; c < 3; c++) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                _rect(1, c.toDouble()),
                const Radius.circular(18),
              ),
              path,
            );
          }
        }
        final opacity = fly >= 1 ? back : (1 - _seg(0.45, 0.55));
        final r = _rect(1, x);
        _tile(canvas, r, Direction.right, s.tileRight, opacity: opacity);
        if (fly == 0) _ring(canvas, r, p.primary, math.sin(tap * math.pi));
      case 1:
        _tile(canvas, _rect(2, 1), Direction.left, s.tileLeft);
        final forward = Curves.easeIn.transform(_seg(0.15, 0.32));
        final backT = Curves.elasticOut.transform(_seg(0.32, 0.75));
        final x = forward * 0.42 * (1 - backT);
        final shake = t > 0.3 && t < 0.5
            ? math.sin(t * 160) * 4 * (1 - _seg(0.3, 0.5))
            : 0.0;
        final hit = t > 0.3 && t < 0.8;
        canvas.drawRRect(
          RRect.fromRectAndRadius(_rect(1, 1), const Radius.circular(18)),
          Paint()..color = hit ? p.dangerSoft : p.cell,
        );
        final blocker = _rect(1, 2).translate(shake, 0);
        _tile(canvas, blocker, Direction.up, s.tileUp);
        final mover = _rect(1, x);
        _tile(canvas, mover, Direction.right, s.tileRight);
        if (hit) {
          _ring(canvas, mover, p.danger, 1);
          _ring(canvas, blocker, p.danger, 1);
        }
      default:
        final pulse = 0.55 + 0.45 * math.sin(t * math.pi * 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(_rect(0, 1), const Radius.circular(18)),
          Paint()..color = p.warnSoft,
        );
        canvas.drawCircle(
          _rect(0, 1).center,
          6,
          Paint()..color = p.warn.withValues(alpha: pulse),
        );
        _tile(canvas, _rect(0, 0), Direction.down, s.tileDown, opacity: 0.4);
        _tile(canvas, _rect(2, 2), Direction.left, s.tileLeft, opacity: 0.4);
        final r = _rect(1, 1);
        _tile(canvas, r, Direction.up, s.tileUp);
        _ring(canvas, r, p.warn, pulse);
    }
  }

  @override
  bool shouldRepaint(_DemoPainter old) =>
      old.t != t || old.step != step || old.p != p;
}
