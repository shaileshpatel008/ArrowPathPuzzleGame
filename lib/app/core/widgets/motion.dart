import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/context_ext.dart';

/// Fade + slight upward slide on first build. Respects "Reduce motion".
class EnterAnimation extends StatelessWidget {
  const EnterAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 0.06,
    this.scale = false,
  });

  /// Convenience for staggered lists.
  // ignore: prefer_const_constructors_in_immutables
  EnterAnimation.staggered({
    super.key,
    required this.child,
    required int index,
    Duration step = const Duration(milliseconds: 45),
    Duration base = Duration.zero,
    this.offset = 0.06,
    this.scale = false,
  }) : delay = base + step * index;

  final Widget child;
  final Duration delay;
  final double offset;
  final bool scale;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    var a = child
        .animate(delay: delay)
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideY(
          begin: offset,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
    if (scale) {
      a = a.scaleXY(
        begin: 0.92,
        end: 1,
        duration: 420.ms,
        curve: Curves.easeOutBack,
      );
    }
    return a;
  }
}
