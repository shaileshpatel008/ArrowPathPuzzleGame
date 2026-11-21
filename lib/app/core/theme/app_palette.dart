import 'package:flutter/material.dart';

import 'skins.dart';

/// Semantic colours derived from the active [Skin]. Read it with
/// `context.pal` anywhere in the widget tree.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.skin,
    required this.background,
    required this.surface,
    required this.cell,
    required this.ink,
    required this.muted,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.primarySoft,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.success,
    required this.successText,
    required this.successSoft,
    required this.danger,
    required this.dangerText,
    required this.dangerSoft,
    required this.warn,
    required this.warnText,
    required this.warnSoft,
    required this.star,
    required this.contrastSurface,
    required this.onContrast,
    required this.onContrastMuted,
  });

  factory AppPalette.fromSkin(Skin s) {
    Color soft(Color c, [double t = 0.14]) => Color.lerp(s.surface, c, t)!;
    final dark = s.isDark;
    const accent = Color(0xFFE8590C);
    const success = Color(0xFF0E9F8E);
    const danger = Color(0xFFE5484D);
    const warn = Color(0xFFF5B700);
    return AppPalette(
      skin: s,
      background: s.background,
      surface: s.surface,
      cell: s.cell,
      ink: s.ink,
      muted: s.muted,
      line: s.line,
      primary: s.primary,
      onPrimary: s.onPrimary,
      primaryText: s.primaryText,
      primarySoft: soft(s.primary, dark ? 0.22 : 0.12),
      accent: accent,
      accentText: dark ? const Color(0xFFFFB37A) : const Color(0xFFC2410C),
      accentSoft: soft(accent, dark ? 0.22 : 0.13),
      success: success,
      successText: dark ? const Color(0xFF5EE0C8) : const Color(0xFF0B6B5F),
      successSoft: soft(success, dark ? 0.22 : 0.13),
      danger: danger,
      dangerText: dark ? const Color(0xFFFF8A8E) : const Color(0xFFB42318),
      dangerSoft: soft(danger, dark ? 0.22 : 0.11),
      warn: warn,
      warnText: dark ? const Color(0xFFFFD45C) : const Color(0xFF7A5000),
      warnSoft: soft(warn, dark ? 0.2 : 0.16),
      star: warn,
      contrastSurface: dark ? const Color(0xFF262C44) : const Color(0xFF10131C),
      onContrast: Colors.white,
      onContrastMuted: const Color(0xFFB4BACB),
    );
  }

  final Skin skin;
  final Color background;
  final Color surface;
  final Color cell;
  final Color ink;
  final Color muted;
  final Color line;
  final Color primary;
  final Color onPrimary;
  final Color primaryText;
  final Color primarySoft;
  final Color accent;
  final Color accentText;
  final Color accentSoft;
  final Color success;
  final Color successText;
  final Color successSoft;
  final Color danger;
  final Color dangerText;
  final Color dangerSoft;
  final Color warn;
  final Color warnText;
  final Color warnSoft;
  final Color star;

  /// A dark card used for premium / highlight surfaces in every skin.
  final Color contrastSurface;
  final Color onContrast;
  final Color onContrastMuted;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      skin: t < 0.5 ? skin : other.skin,
      background: l(background, other.background),
      surface: l(surface, other.surface),
      cell: l(cell, other.cell),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryText: l(primaryText, other.primaryText),
      primarySoft: l(primarySoft, other.primarySoft),
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      accentSoft: l(accentSoft, other.accentSoft),
      success: l(success, other.success),
      successText: l(successText, other.successText),
      successSoft: l(successSoft, other.successSoft),
      danger: l(danger, other.danger),
      dangerText: l(dangerText, other.dangerText),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      warn: l(warn, other.warn),
      warnText: l(warnText, other.warnText),
      warnSoft: l(warnSoft, other.warnSoft),
      star: l(star, other.star),
      contrastSurface: l(contrastSurface, other.contrastSurface),
      onContrast: l(onContrast, other.onContrast),
      onContrastMuted: l(onContrastMuted, other.onContrastMuted),
    );
  }
}
