import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/painters.dart';
import '../controllers/splash_controller.dart';

/// Always dark, matching the native launch screen for a seamless hand-off.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  static const _bg = Color(0xFF10131C);

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            ..._floatingTiles(reduce),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: reduce ? 1 : 0, end: 1),
                    duration: const Duration(milliseconds: 1100),
                    builder: (_, t, _) => LogoMark(size: 116, progress: t),
                  ),
                  const SizedBox(height: 28),
                  Text(
                        AppConfig.shortName,
                        style: displayStyle(
                          44,
                          color: Colors.white,
                          letterSpacing: -1.4,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 500.ms)
                      .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 8),
                  Text(
                    'splash_tagline'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFB4BACB),
                    ),
                  ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 72 + MediaQuery.paddingOf(context).bottom,
              child: Center(
                child: SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1600),
                      curve: Curves.easeInOutCubic,
                      builder: (_, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF262C42),
                        color: const Color(0xFF2E4BFF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _floatingTiles(bool reduce) {
    const specs = [
      (0.08, 0.14, 44.0, 0.0),
      (0.78, 0.2, 56.0, 0.3),
      (0.14, 0.76, 56.0, 0.6),
      (0.76, 0.82, 40.0, 0.9),
    ];
    return [
      for (final (x, y, s, d) in specs)
        Positioned.fill(
          child: Align(
            alignment: Alignment(x * 2 - 1, y * 2 - 1),
            child:
                Container(
                      width: s,
                      height: s,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2033),
                        borderRadius: BorderRadius.circular(s * 0.29),
                      ),
                    )
                    .animate(
                      onPlay: (c) => reduce ? null : c.repeat(reverse: true),
                    )
                    .moveY(
                      begin: -6,
                      end: 6,
                      duration: 2400.ms,
                      delay: (d * 1000).ms,
                      curve: Curves.easeInOut,
                    ),
          ),
        ),
    ];
  }
}
