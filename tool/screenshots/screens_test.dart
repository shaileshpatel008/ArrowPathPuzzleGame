// ignore_for_file: unawaited_futures
// Renders every screen to PNG, for design review and Play Store screenshots.
//
//   flutter test tool/screenshots/screens_test.dart --update-goldens
//
// Output: tool/screenshots/out/<size>/<screen>.png
// Any layout overflow makes the run fail, so this doubles as a UI smoke test.
import 'dart:io';

import 'package:arrowpathpuzzle/app/core/constants/storage_keys.dart';
import 'package:arrowpathpuzzle/app/core/theme/app_theme.dart';
import 'package:arrowpathpuzzle/app/core/translations/app_translations.dart';
import 'package:arrowpathpuzzle/app/core/utils/day.dart';
import 'package:arrowpathpuzzle/app/data/models/level_result.dart';
import 'package:arrowpathpuzzle/app/data/services/ads_service.dart';
import 'package:arrowpathpuzzle/app/data/services/audio_service.dart';
import 'package:arrowpathpuzzle/app/data/services/consent_service.dart';
import 'package:arrowpathpuzzle/app/data/services/iap_service.dart';
import 'package:arrowpathpuzzle/app/data/services/lifecycle_service.dart';
import 'package:arrowpathpuzzle/app/data/services/platform_service.dart';
import 'package:arrowpathpuzzle/app/data/services/progress_service.dart';
import 'package:arrowpathpuzzle/app/data/services/settings_service.dart';
import 'package:arrowpathpuzzle/app/data/services/storage_service.dart';
import 'package:arrowpathpuzzle/app/data/services/wallet_service.dart';
import 'package:arrowpathpuzzle/app/modules/game/controllers/game_controller.dart';
import 'package:arrowpathpuzzle/app/modules/shell/controllers/shell_controller.dart';
import 'package:arrowpathpuzzle/app/modules/store/purchase_feedback.dart';
import 'package:arrowpathpuzzle/app/routes/app_pages.dart';
import 'package:arrowpathpuzzle/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// ----- Fakes (no platform plugins in tests) ----------------------------------

class MemoryStorage extends StorageService {
  final m = <String, dynamic>{};

  @override
  Future<StorageService> init() async => this;
  @override
  bool readBool(String key, {bool fallback = false}) =>
      m[key] as bool? ?? fallback;
  @override
  int readInt(String key, {int fallback = 0}) =>
      (m[key] as num?)?.toInt() ?? fallback;
  @override
  String? readString(String key) => m[key] as String?;
  @override
  List<String> readStringList(String key) =>
      (m[key] as List?)?.map((e) => '$e').toList() ?? [];
  @override
  Map<String, int> readIntMap(String key) =>
      (m[key] as Map?)?.map((k, v) => MapEntry('$k', (v as num).toInt())) ?? {};
  @override
  Future<void> write(String key, Object? value) async => m[key] = value;
  @override
  Future<void> remove(String key) async => m.remove(key);
}

class SilentAudio extends AudioService {
  SilentAudio(super.settings);
  @override
  Future<AudioService> init() async => this;
  @override
  void play(Sfx sfx) {}
}

class NoAds extends AdsService {
  NoAds(super.c, super.p, super.w, super.s);
  @override
  AdsService init() => this;
}

// ----- Setup ---------------------------------------------------------------

Future<void> loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(rootBundle.load(f));
    }
    await loader.load();
  }

  await family('Inter', [
    for (final w in [400, 500, 600, 700]) 'assets/fonts/Inter-$w.ttf',
  ]);
  await family('SpaceGrotesk', [
    for (final w in [500, 600, 700]) 'assets/fonts/SpaceGrotesk-$w.ttf',
  ]);
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
  await loader.load();
}

/// A believable mid-game player: level 23 cleared, 7-day streak.
void seed(MemoryStorage s, {String skin = 'daylight'}) {
  final now = DateTime.now();
  final today = Day.dateOnly(now);
  s.m[StorageKeys.onboardingDone] = true;
  s.m[StorageKeys.skinId] = skin;
  s.m[StorageKeys.highestCleared] = 23;
  s.m[StorageKeys.stars] = {
    for (var l = 1; l <= 23; l++) '$l': l % 5 == 0 ? 2 : (l % 7 == 0 ? 1 : 3),
  };
  s.m[StorageKeys.perfectClears] = 15;
  s.m[StorageKeys.noHintClears] = 18;
  s.m[StorageKeys.arrowsCleared] = 412;
  s.m[StorageKeys.hints] = 3;
  final monday = today.subtract(Duration(days: today.weekday - 1));
  const perDay = [34, 52, 18, 61, 27, 40, 22];
  s.m[StorageKeys.arrowsByDay] = {
    for (var i = 0; i < 7; i++)
      if (!monday.add(Duration(days: i)).isAfter(today))
        Day.key(monday.add(Duration(days: i))): perDay[i],
  };
  final solved = <String>[];
  for (var d = 1; d < today.day; d++) {
    if (d == 4 || d == 9) continue;
    solved.add(Day.key(DateTime(today.year, today.month, d)));
  }
  for (var i = 1; i <= 7; i++) {
    final k = Day.key(today.subtract(Duration(days: i)));
    if (!solved.contains(k)) solved.add(k);
  }
  s.m[StorageKeys.dailySolved] = solved;
  s.m[StorageKeys.dailyStreak] = 7;
  s.m[StorageKeys.dailyBestStreak] = 12;
  s.m[StorageKeys.dailyFreezes] = 1;
  s.m[StorageKeys.dailyLastSolved] = Day.key(
    today.subtract(const Duration(days: 1)),
  );
  s.m[StorageKeys.plusOfferShown] = true;
}

Future<void> setupServices({
  String skin = 'daylight',
  void Function(MemoryStorage)? tweak,
}) async {
  Get.testMode = true;
  final storage = MemoryStorage();
  seed(storage, skin: skin);
  tweak?.call(storage);
  Get.put<StorageService>(storage, permanent: true);
  final settings = Get.put(SettingsService(storage).init(), permanent: true);
  final progress = Get.put(ProgressService(storage).init(), permanent: true);
  final wallet = Get.put(WalletService(storage).init(), permanent: true);
  Get.put(PlatformService()..version.value = '1.0.0 (1)', permanent: true);
  Get.put<AudioService>(SilentAudio(settings), permanent: true);
  final consent = Get.put(ConsentService(), permanent: true);
  Get.put<AdsService>(
    NoAds(consent, progress, wallet, storage).init(),
    permanent: true,
  );
  final iap = Get.put(IapService(wallet, progress), permanent: true);
  iap.loading.value = false;
  iap.available.value = true;
  ProductDetails pd(String id, String price) => ProductDetails(
    id: id,
    title: id,
    description: id,
    price: price,
    rawPrice: 0,
    currencyCode: 'INR',
  );
  iap.products.assignAll({
    'hints_5': pd('hints_5', '₹49'),
    'hints_15': pd('hints_15', '₹129'),
    'hints_40': pd('hints_40', '₹299'),
    'theme_pack': pd('theme_pack', '₹199'),
    'plus_monthly': pd('plus_monthly', '₹149'),
    'plus_yearly': pd('plus_yearly', '₹999'),
    'plus_lifetime': pd('plus_lifetime', '₹1,999'),
  });
  Get.put(PurchaseFeedback(iap), permanent: true);
  Get.put(LifecycleService(wallet, progress), permanent: true);
}

Widget app(String initialRoute) {
  final settings = Get.find<SettingsService>();
  return Obx(
    () => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(settings.skin),
      translations: AppTranslations(),
      locale: AppTranslations.fallback,
      initialRoute: initialRoute,
      getPages: AppPages.pages,
    ),
  );
}

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
