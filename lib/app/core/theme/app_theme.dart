import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';
import 'skins.dart';

abstract final class AppFonts {
  static const body = 'Inter';
  static const display = 'SpaceGrotesk';
}

abstract final class AppTheme {
  static ThemeData build(Skin skin) {
    final p = AppPalette.fromSkin(skin);
    final brightness = skin.isDark ? Brightness.dark : Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: skin.primary,
          brightness: brightness,
        ).copyWith(
          primary: skin.primary,
          onPrimary: skin.onPrimary,
          surface: skin.surface,
          onSurface: skin.ink,
          error: p.danger,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: skin.background,
      fontFamily: AppFonts.body,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      textTheme: _text(p),
      dividerColor: p.line,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: overlay(skin),
      ),
    );
  }

  static SystemUiOverlayStyle overlay(Skin skin) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: skin.isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: skin.isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: skin.isDark
        ? Brightness.light
        : Brightness.dark,
  );

  static TextTheme _text(AppPalette p) => TextTheme(
    displaySmall: TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      height: 1.05,
      color: p.ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.15,
      color: p.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.15,
      color: p.ink,
    ),
    titleLarge: TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: p.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: p.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: p.muted),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: p.muted),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: p.muted),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: p.ink,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: p.muted,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.7,
      color: p.muted,
    ),
  );
}
