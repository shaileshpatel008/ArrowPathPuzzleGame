import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/settings_service.dart';
import 'app_palette.dart';
import 'app_theme.dart';

extension ThemeContextX on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;

  /// True when animations should be skipped (system setting or in-app
  /// "Reduce motion").
  bool get reduceMotion {
    final system = MediaQuery.maybeDisableAnimationsOf(this) ?? false;
    final app =
        Get.isRegistered<SettingsService>() &&
        Get.find<SettingsService>().reduceMotion.value;
    return system || app;
  }
}

/// Big numbers and screen titles use the display face.
TextStyle displayStyle(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w700,
  double letterSpacing = -0.4,
}) => TextStyle(
  fontFamily: AppFonts.display,
  fontSize: size,
  fontWeight: weight,
  letterSpacing: letterSpacing,
  color: color,
  height: 1.1,
);
