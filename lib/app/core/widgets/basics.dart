import 'package:flutter/material.dart';

import '../theme/context_ext.dart';
import 'pressable.dart';

/// White (surface) rounded card with a hairline border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = 22,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? p.line,
          width: borderColor == null ? 1 : 2,
        ),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      pressedScale: 0.98,
      child: card,
    );
  }
}

/// 44x44 round icon button used in headers.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.background,
    this.foreground,
    this.bordered = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color? background;
  final Color? foreground;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      pressedScale: 0.9,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background ?? p.surface,
          shape: BoxShape.circle,
          border: bordered ? Border.all(color: p.line) : null,
        ),
        child: Icon(icon, size: 22, color: foreground ?? p.ink),
      ),
    );
  }
}

/// Small rounded pill with an icon and a value (streak, hints...).
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    this.onTap,
    this.semanticLabel,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final pill = Container(
      height: 38,
      padding: EdgeInsets.only(left: 12, right: trailing == null ? 12 : 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: p.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: iconColor),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: p.ink,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
    if (onTap == null) return Semantics(label: semanticLabel, child: pill);
    return Pressable(onTap: onTap, semanticLabel: semanticLabel, child: pill);
  }
}

/// Uppercase section heading.
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(4, 20, 4, 10),
  });

  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Semantics(
      header: true,
      child: Text(text.toUpperCase(), style: context.text.labelSmall),
    ),
  );
}

/// Rounded progress bar that animates to its value.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.track,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: track ?? p.line)),
              TweenAnimationBuilder<double>(
                tween: Tween(end: value.clamp(0, 1)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => FractionallySizedBox(
                  widthFactor: v,
                  heightFactor: 1,
                  alignment: AlignmentDirectional.centerStart,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color ?? p.primary,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
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

/// Integer that counts up when it changes.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount(
    this.value, {
    super.key,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: context.reduceMotion ? Duration.zero : duration,
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => Text('${v.round()}', style: style),
  );
}

/// Round icon badge on a tinted square (used in list rows and cards).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Icon(icon, color: color, size: size * 0.52),
  );
}
