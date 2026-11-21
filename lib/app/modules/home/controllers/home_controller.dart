import 'dart:async';

import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../data/game/level_catalog.dart';
import '../../../data/game/level_spec.dart';
import '../../../data/models/level_result.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../../routes/app_routes.dart';
import '../../shell/controllers/shell_controller.dart';

class HomeController extends GetxController {
  final ProgressService progress = Get.find();
  final WalletService wallet = Get.find();
  final SettingsService settings = Get.find();

  /// "6h 42m" until the daily puzzle resets (local midnight).
  final resetsIn = ''.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final left = DateTime(now.year, now.month, now.day + 1).difference(now);
    resetsIn.value = '${left.inHours}h ${left.inMinutes.remainder(60)}m';
  }

  int get nextLevel => progress.nextLevel;
  Chapter get chapter => LevelCatalog.chapterOf(nextLevel);
  LevelSpec get nextSpec => LevelCatalog.level(nextLevel);

  int get chapterCleared =>
      (progress.highestCleared.value - chapter.firstLevel + 1).clamp(
        0,
        chapter.levelCount,
      );

  String get greetingKey {
    final h = DateTime.now().hour;
    if (h < 12) return 'greet_morning';
    if (h < 18) return 'greet_afternoon';
    return 'greet_evening';
  }

  bool get showPlusBanner =>
      !wallet.isPlus.value &&
      progress.highestCleared.value >= AppConfig.freeLevelsWithoutAds;

  void play() =>
      Get.toNamed<void>(Routes.game, arguments: GameArgs.campaign(nextLevel));

  void playDaily() {
    if (progress.solvedToday) {
      Get.find<ShellController>().select(ShellTab.daily);
    } else {
      Get.toNamed<void>(Routes.game, arguments: GameArgs.daily(DateTime.now()));
    }
  }

  void openStore() => Get.toNamed<void>(Routes.store);
  void openThemes() => Get.toNamed<void>(Routes.themes);
  void openStats() => Get.toNamed<void>(Routes.stats);
  void openPlus() => Get.toNamed<void>(Routes.plus);
  void openDaily() => Get.find<ShellController>().select(ShellTab.daily);

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
