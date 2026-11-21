import 'package:arrowpathpuzzle/app/core/constants/storage_keys.dart';
import 'package:flutter/widgets.dart';
import 'package:arrowpathpuzzle/app/modules/home/views/home_view.dart';
import 'package:arrowpathpuzzle/app/modules/onboarding/views/onboarding_view.dart';
import 'package:arrowpathpuzzle/app/modules/splash/views/splash_view.dart';
import 'package:arrowpathpuzzle/app/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/test_app.dart';

/// Regression: the app must leave the splash screen on its own.
void main() {
  tearDown(Get.reset);

  Future<void> pumpFor(WidgetTester t, Duration d) async {
    for (var i = 0; i < d.inMilliseconds ~/ 100; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('returning player: splash -> home', (t) async {
    await setupServices();
    await t.pumpWidget(app(Routes.splash));
    await t.pump();
    expect(find.byType(SplashView), findsOneWidget);
    await pumpFor(t, const Duration(milliseconds: 2500));
    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(HomeView), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await pumpFor(t, const Duration(seconds: 3));
  });

  testWidgets('new player: splash -> onboarding', (t) async {
    await setupServices(tweak: (s) => s.m.remove(StorageKeys.onboardingDone));
    await t.pumpWidget(app(Routes.splash));
    await pumpFor(t, const Duration(milliseconds: 2500));
    expect(find.byType(OnboardingView), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await pumpFor(t, const Duration(seconds: 3));
  });
}
