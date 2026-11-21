import 'package:get/get.dart';

import '../modules/game/bindings/game_binding.dart';
import '../modules/game/views/game_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/plus/bindings/plus_binding.dart';
import '../modules/plus/views/plus_view.dart';
import '../modules/result/bindings/result_binding.dart';
import '../modules/result/views/result_view.dart';
import '../modules/shell/bindings/shell_binding.dart';
import '../modules/shell/views/shell_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/stats/bindings/stats_binding.dart';
import '../modules/stats/views/stats_view.dart';
import '../modules/store/bindings/store_binding.dart';
import '../modules/store/views/store_view.dart';
import '../modules/themes/bindings/themes_binding.dart';
import '../modules/themes/views/themes_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static const initial = Routes.splash;

  static const _fast = Duration(milliseconds: 320);

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _fast,
    ),
    GetPage(
      name: Routes.shell,
      page: () => const ShellView(),
      binding: ShellBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _fast,
    ),
    GetPage(
      name: Routes.game,
      page: () => const GameView(),
      binding: GameBinding(),
      transition: Transition.zoom,
      transitionDuration: _fast,
    ),
    GetPage(
      name: Routes.result,
      page: () => const ResultView(),
      binding: ResultBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _fast,
    ),
    GetPage(
      name: Routes.themes,
      page: () => const ThemesView(),
      binding: ThemesBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _fast,
    ),
    GetPage(
      name: Routes.stats,
      page: () => const StatsView(),
      binding: StatsBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _fast,
    ),
    GetPage(
      name: Routes.store,
      page: () => const StoreView(),
      binding: StoreBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _fast,
    ),
    GetPage(
      name: Routes.plus,
      page: () => const PlusView(),
      binding: PlusBinding(),
      transition: Transition.downToUp,
      transitionDuration: _fast,
      fullscreenDialog: true,
    ),
  ];
}
