import 'package:get/get.dart';

import '../../../config/ad_config.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/game/level_catalog.dart';
import '../../../data/models/level_result.dart';
import '../../../data/services/progress_service.dart';
import '../../../routes/app_routes.dart';

enum LevelState { done, current, locked }

class LevelsController extends GetxController {
  final ProgressService progress = Get.find();

  late final selected =
      (LevelCatalog.chapterOf(progress.nextLevel).number - 1).obs;

  bool get showBanner => AdConfig.showBannerOnLevels;

  List<Chapter> get chapters => LevelCatalog.chapters;
  Chapter get chapter => chapters[selected.value];

  bool chapterUnlocked(Chapter c) => progress.isUnlocked(c.firstLevel);

  int chapterStars(Chapter c) {
    var sum = 0;
    for (var l = c.firstLevel; l <= c.lastLevel; l++) {
      sum += progress.starsFor(l);
    }
    return sum;
  }

  LevelState stateOf(int level) {
    if (progress.starsFor(level) > 0 ||
        level <= progress.highestCleared.value) {
      return LevelState.done;
    }
    return progress.isUnlocked(level) ? LevelState.current : LevelState.locked;
  }

  void selectChapter(int index) => selected.value = index;

  void open(int level) {
    if (stateOf(level) == LevelState.locked) {
      AppToast.show(
        'level_locked_toast'.trParams({'n': '${progress.nextLevel}'}),
      );
      return;
    }
    Get.toNamed<void>(Routes.game, arguments: GameArgs.campaign(level));
  }
}
