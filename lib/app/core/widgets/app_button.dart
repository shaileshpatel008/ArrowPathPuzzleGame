import 'package:flutter/material.dart';

import '../theme/context_ext.dart';
import 'pressable.dart';

enum AppButtonStyle { primary, secondary, dark, light, ghost }

/// The app's standard button. 56px tall, fully rounded corners.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.height = 56,
    this.expand = true,
    this.display = true,
  });

  final String label;
  final VoidCallback? onTap;
  final AppButtonStyle style;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final double height;
  final bool expand;

  /// Use the display font (Space Grotesk) for primary calls to action.
  final bool display;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final (Color bg, Color fg, Color? border) = switch (style) {
      AppButtonStyle.primary => (p.primary, p.onPrimary, null),
      AppButtonStyle.secondary => (p.surface, p.ink, p.line),
      AppButtonStyle.dark => (p.contrastSurface, p.onContrast, null),
      AppButtonStyle.light => (Colors.white, const Color(0xFF10131C), null),
      AppButtonStyle.ghost => (Colors.transparent, p.primaryText, null),
    };
    final textStyle = display
        ? displayStyle(height >= 54 ? 18 : 16, color: fg, letterSpacing: -0.2)
        : TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg);

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: loading
          ? SizedBox(
              key: const ValueKey('l'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: fg),
            )
          : Row(
              key: const ValueKey('c'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 10),
                  Icon(trailingIcon, size: 20, color: fg),
                ],
              ],
            ),
    );

    return Pressable(
      onTap: loading ? null : onTap,
      semanticLabel: label,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height * 0.32),
          border: border == null ? null : Border.all(color: border),
        ),
        child: content,
      ),
    );
  }
}
