import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/translations/app_translations.dart';
import 'data/services/settings_service.dart';
import 'data/services/update_service.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class ArrowPathApp extends StatelessWidget {
  const ArrowPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    return Obx(() {
      final skin = settings.skin;
      SystemChrome.setSystemUIOverlayStyle(AppTheme.overlay(skin));
      return GetMaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(skin),
        translations: AppTranslations(),
        locale: Get.deviceLocale,
        fallbackLocale: AppTranslations.fallback,
        initialRoute: AppPages.initial,
        getPages: AppPages.pages,
        defaultTransition: Transition.fadeIn,
        routingCallback: (routing) {
          // Check for Play updates whenever the player lands on the tabs.
          if (routing?.current == Routes.shell &&
              Get.isRegistered<UpdateService>()) {
            Future<void>.delayed(
              const Duration(milliseconds: 900),
              Get.find<UpdateService>().onHomeVisible,
            );
          }
        },
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          // Respect the system font size, but keep boards and grids usable.
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        ),
      );
    });
  }
}
