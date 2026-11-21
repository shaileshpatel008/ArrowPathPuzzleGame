// ignore_for_file: unawaited_futures
// Renders every screen to PNG, for design review and Play Store screenshots.
//
//   flutter test tool/screenshots/screens_test.dart --update-goldens
//
// Output: tool/screenshots/out/<size>/<screen>.png
// Any layout overflow makes the run fail, so this doubles as a UI smoke test.

import 'package:arrowpathpuzzle/app/core/constants/storage_keys.dart';
import 'package:arrowpathpuzzle/app/data/models/level_result.dart';
import 'package:arrowpathpuzzle/app/modules/game/controllers/game_controller.dart';
import 'package:arrowpathpuzzle/app/modules/shell/controllers/shell_controller.dart';
import 'package:arrowpathpuzzle/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../test/helpers/test_app.dart';

// ----- Shots ------------------------------------------------------------------

typedef Shot = ({
  String name,
  String route,
  String skin,
  void Function(MemoryStorage)? tweak,
  Future<void> Function(WidgetTester t)? act,
});

Future<void> settle(WidgetTester t, [int ms = 1600]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

final shots = <Shot>[
  (
    name: '01_splash',
    route: Routes.splash,
    skin: 'daylight',
    tweak: null,
    act: null,
  ),
  (
    name: '02_onboarding',
    route: Routes.onboarding,
    skin: 'daylight',
    tweak: null,
    act: null,
  ),
  (
    name: '03_home',
    route: Routes.shell,
    skin: 'daylight',
    tweak: null,
    act: null,
  ),
  (
    name: '04_levels',
    route: Routes.shell,
    skin: 'daylight',
    tweak: null,
    act: (t) async => Get.find<ShellController>().select(ShellTab.levels),
  ),
  (
    name: '05_game_hint',
    route: Routes.shell,
    skin: 'daylight',
    tweak: null,
    act: (t) async {
      Get.toNamed<void>(Routes.game, arguments: const GameArgs.campaign(24));
      await settle(t, 1500);
      final c = Get.find<GameController>();
      final free = c.arrows.where((a) => c.remaining.contains(a.id)).toList();
      c.tapArrow(free.last.id);
      await settle(t, 900);
      c.useHint();
    },
  ),
  (
    name: '06_game_crash',
    route: Routes.shell,
    skin: 'daylight',
    tweak: null,
    act: (t) async {
      Get.toNamed<void>(Routes.game, arguments: const GameArgs.campaign(24));
      await settle(t, 1500);
      final c = Get.find<GameController>();
      for (final a in c.arrows) {
        final before = c.hearts.value;
        c.tapArrow(a.id);
        if (c.hearts.value < before) break;
        await settle(t, 600);
      }
    },
  ),
  (
    name: '07_level_cleared',
    route: Routes.shell,
    skin: 'daylight',
    tweak: null,
    act: (t) async {
      Get.toNamed<void>(
        Routes.result,
        arguments: const LevelResult(
          args: GameArgs.campaign(24),
          stars: 3,
          taps: 18,
          crashes: 0,
          heartsLeft: 3,
          hintsUsed: 0,
          duration: Duration(seconds: 52),
          earnedHint: true,
          firstClear: true,
          streak: 0,
        ),
      );
    },
  ),
  (
    name: '08_out_of_hearts',
    route: Routes.shell,
    skin: 'daylight',
    tweak: null,
    act: (t) async {
      Get.toNamed<void>(Routes.game, arguments: const GameArgs.campaign(24));
      await settle(t, 1500);
      final c = Get.find<GameController>();
      var guard = 0;
      while (c.hearts.value > 0 && guard++ < 200) {
        final ids = c.arrows
            .where((a) => c.remaining.contains(a.id))
            .map((a) => a.id)
            .toList();
        // Tap the first blocked arrow we can find.
        for (final id in ids) {
          final before = c.hearts.value;
          c.tapArrow(id);
          if (c.hearts.value < before) break;
        }
        await settle(t, 300);
      }
    },
  ),
  (
    name: '09_out_of_hints',
    route: Routes.shell,
    skin: 'daylight',
    tweak: (s) => s.m[StorageKeys.hints] = 0,
    act: (t) async {
      Get.toNamed<void>(Routes.game, arguments: const GameArgs.campaign(24));
      await settle(t, 1200);
      Get.find<GameController>().useHint();
    },
  ),
  (
    name: '10_daily',
    route: Routes.shell,
    skin: 'daylight',
    tweak: null,
    act: (t) async => Get.find<ShellController>().select(ShellTab.daily),
  ),
  (
    name: '11_themes',
    route: Routes.themes,
    skin: 'daylight',
    tweak: null,
    act: null,
  ),
  (
    name: '12_stats',
    route: Routes.stats,
    skin: 'daylight',
    tweak: null,
    act: null,
  ),
  (
    name: '13_settings',
    route: Routes.shell,
    skin: 'daylight',
    tweak: null,
    act: (t) async => Get.find<ShellController>().select(ShellTab.settings),
  ),
  (
    name: '14_shop',
    route: Routes.store,
    skin: 'daylight',
    tweak: null,
    act: null,
  ),
  (
    name: '15_plus',
    route: Routes.plus,
    skin: 'daylight',
    tweak: null,
    act: null,
  ),
  (
    name: '16_home_midnight',
    route: Routes.shell,
    skin: 'midnight',
    tweak: null,
    act: null,
  ),
  (
    name: '17_game_neon',
    route: Routes.shell,
    skin: 'neon',
    tweak: null,
    act: (t) async {
      Get.toNamed<void>(Routes.game, arguments: const GameArgs.campaign(60));
    },
  ),
];

void main() {
  const sizes = {
    // Matches the design mockups.
    'review_390x844': (Size(390, 844), 2.0),
    // Small phone + Play-compliant 1:2 ratio (1080x2160).
    'store_1080x2160': (Size(360, 720), 3.0),
  };

  setUpAll(loadFonts);

  for (final entry in sizes.entries) {
    for (final shot in shots) {
      testWidgets('${entry.key}/${shot.name}', (t) async {
        final (size, dpr) = entry.value;
        t.view.physicalSize = size * dpr;
        t.view.devicePixelRatio = dpr;
        addTearDown(t.view.reset);

        await setupServices(skin: shot.skin, tweak: shot.tweak);
        await t.pumpWidget(app(shot.route));
        await settle(t, shot.route == Routes.splash ? 1200 : 900);
        if (shot.act != null) {
          await shot.act!(t);
          await settle(t);
        }
        await expectLater(
          find.byType(GetMaterialApp),
          matchesGoldenFile('out/${entry.key}/${shot.name}.png'),
        );
        // Let pending timers (splash redirect, toasts) finish, then clean up.
        await settle(t, 2500);
        await t.pumpWidget(const SizedBox());
        await settle(t, 3000);
        Get.reset();
      });
    }
  }
}
