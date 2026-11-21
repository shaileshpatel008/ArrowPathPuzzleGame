import 'dart:ui';

import 'package:get/get.dart';

import 'en_us.dart';

/// Add a language: create `xx_yy.dart` with the same keys and register it.
class AppTranslations extends Translations {
  static const fallback = Locale('en', 'US');

  @override
  Map<String, Map<String, String>> get keys => {'en_US': enUS};
}
