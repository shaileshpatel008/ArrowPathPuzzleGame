// Shared test setup: fake services (no platform plugins) + seeded player.
import 'dart:io';

import 'package:arrowpathpuzzle/app/core/constants/storage_keys.dart';
import 'package:arrowpathpuzzle/app/core/theme/app_theme.dart';
import 'package:arrowpathpuzzle/app/core/translations/app_translations.dart';
import 'package:arrowpathpuzzle/app/core/utils/day.dart';
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
import 'package:arrowpathpuzzle/app/modules/store/purchase_feedback.dart';
import 'package:arrowpathpuzzle/app/routes/app_pages.dart';
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
