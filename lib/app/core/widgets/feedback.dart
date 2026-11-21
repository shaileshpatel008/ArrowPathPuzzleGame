import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/context_ext.dart';

/// Bottom sheet chrome: drag handle, rounded top, safe-area padding.
abstract final class AppSheet {
  static Future<T?> show<T>(Widget child, {bool dismissible = true}) {
    return Get.bottomSheet<T>(
      _SheetFrame(child: child),
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      barrierColor: const Color(0x8C10131C),
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 320),
      exitBottomSheetDuration: const Duration(milliseconds: 220),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(22, 12, 22, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: p.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

enum ToastTone { info, good, bad }

/// Lightweight floating message.
abstract final class AppToast {
  static void show(
    String message, {
    ToastTone tone = ToastTone.info,
    IconData? icon,
  }) {
    final ctx = Get.context;
    if (ctx == null) return;
    final p = ctx.pal;
    final (Color bg, Color fg) = switch (tone) {
      ToastTone.info => (p.contrastSurface, p.onContrast),
      ToastTone.good => (p.successText, Colors.white),
      ToastTone.bad => (p.dangerText, Colors.white),
    };
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.showSnackbar(
      GetSnackBar(
        messageText: Text(
          message,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        icon: icon == null ? null : Icon(icon, color: fg),
        backgroundColor: bg,
        borderRadius: 18,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(milliseconds: 2400),
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

/// One-shot burst of geometric confetti (squares, triangles, pills).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.particles = 70,
    this.origin = const Alignment(0, -0.35),
  });

  final int particles;
  final Alignment origin;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final List<_Particle> _parts;

  static const _colors = [
    Color(0xFF2E4BFF),
    Color(0xFFE8590C),
    Color(0xFF0E9F8E),
    Color(0xFFF5B700),
    Color(0xFFFFFFFF),
    Color(0xFFFF4FD8),
  ];

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _parts = List.generate(widget.particles, (i) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.25;
      final speed = 380 + rnd.nextDouble() * 560;
      return _Particle(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: 6 + rnd.nextDouble() * 9,
        spin: (rnd.nextDouble() - 0.5) * 14,
        shape: i % 3,
        color: _colors[i % _colors.length],
        delay: rnd.nextDouble() * 0.12,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.reduceMotion) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_parts, _c.value, widget.origin),
      ),
    ),
  );
}

class _Particle {
  _Particle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.spin,
    required this.shape,
    required this.color,
    required this.delay,
  });

  final double vx, vy, size, spin, delay;
  final int shape;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.parts, this.t, this.origin);

  final List<_Particle> parts;
  final double t;
  final Alignment origin;

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0) return;
    final o = origin.alongSize(size);
    for (final p in parts) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final time = lt * 2.6;
      final x = o.dx + p.vx * time * 0.55;
      final y = o.dy + p.vy * time * 0.55 + 520 * time * time * 0.5;
      final alpha = (1 - lt).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * time);
      switch (p.shape) {
        case 0:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size,
                height: p.size,
              ),
              Radius.circular(p.size * 0.25),
            ),
            paint,
          );
        case 1:
          canvas.drawPath(
            Path()
              ..moveTo(0, -p.size * 0.6)
              ..lineTo(p.size * 0.55, p.size * 0.45)
              ..lineTo(-p.size * 0.55, p.size * 0.45)
              ..close(),
            paint,
          );
        default:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size * 1.6,
                height: p.size * 0.5,
              ),
              Radius.circular(p.size),
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Custom animated on/off switch (accessible as a toggle).
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      toggled: value,
      label: label,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? p.primary : p.line,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
