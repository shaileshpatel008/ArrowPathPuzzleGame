import 'dart:async';

import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../data/game/level_catalog.dart';
import '../../../data/models/level_result.dart';
import '../../../data/services/ads_service.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/platform_service.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../../routes/app_routes.dart';
import '../../shell/controllers/shell_controller.dart';

class ResultController extends GetxController {
  final AdsService _ads = Get.find();
  final AudioService _audio = Get.find();
  final ProgressService _progress = Get.find();
  final WalletService _wallet = Get.find();
  final PlatformService _platform = Get.find();

  late final LevelResult result;
  bool _leaving = false;

  @override
  void onInit() {
    super.onInit();
    result = Get.arguments as LevelResult;
  }

  @override
  void onReady() {
    super.onReady();
    // Star "pings" timed with the star animations in the view.
    for (var i = 0; i < result.stars; i++) {
      Future<void>.delayed(
        Duration(milliseconds: 520 + i * 220),
        () => _audio.play(Sfx.star),
      );
    }
    if (result.args.mode == GameMode.campaign &&
        _progress.shouldAskForReview(result.args.level)) {
      Future<void>.delayed(
        const Duration(milliseconds: 1800),
        _platform.requestReview,
      );
    }
  }

  bool get isDaily => result.args.mode == GameMode.daily;
  bool get hasNext => !isDaily && result.args.level < LevelCatalog.totalLevels;

  String get headline {
    if (isDaily) return 'daily_solved'.tr;
    if (result.perfect) return 'perfect_clear'.tr;
    return result.stars >= 2 ? 'great_job'.tr : 'level_cleared'.tr;
  }

  String get subline {
    if (result.perfect) return 'no_crash_no_hint'.tr;
    return 'crashes_n'.trParams({'n': '${result.crashes}'});
  }

  String get time {
    final s = result.duration.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Future<void> next() async {
    if (_leaving) return;
    _leaving = true;
    await _beforeLeavingWin();
    if (hasNext) {
      await Get.offNamed<void>(
        Routes.game,
        arguments: GameArgs.campaign(result.args.level + 1),
      );
    } else {
      await _toShell(isDaily ? ShellTab.daily : ShellTab.levels);
    }
  }

  Future<void> replay() async {
    if (_leaving) return;
    _leaving = true;
    await _beforeLeavingWin();
    await Get.offNamed<void>(Routes.game, arguments: result.args);
  }

  Future<void> allLevels() async {
    if (_leaving) return;
    _leaving = true;
    await _beforeLeavingWin();
    await _toShell(isDaily ? ShellTab.daily : ShellTab.levels);
  }

  /// Natural break after a win: maybe the one-time Plus offer, otherwise
  /// maybe an interstitial (frequency-capped inside AdsService).
  Future<void> _beforeLeavingWin() async {
    final level = result.args.level;
    if (!isDaily &&
        level >= AppConfig.plusOfferAfterLevel &&
        !_progress.plusOfferShown.value &&
        !_wallet.isPlus.value) {
      await _progress.markPlusOfferShown();
      await Get.toNamed<void>(Routes.plus, arguments: 'offer');
      return;
    }
    await _ads.onLevelWon();
  }

  Future<void> _toShell(ShellTab tab) async {
    if (Get.isRegistered<ShellController>()) {
      Get.find<ShellController>().select(tab);
    }
    Get.until((route) => route.settings.name == Routes.shell || route.isFirst);
  }
}
