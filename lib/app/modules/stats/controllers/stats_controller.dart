import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../data/services/progress_service.dart';

class Achievement {
  const Achievement(this.titleKey, this.progress, this.target);

  final String titleKey;
  final int progress;
  final int target;

  double get ratio => (progress / target).clamp(0, 1);
  bool get done => progress >= target;
}

class StatsController extends GetxController {
  final ProgressService progress = Get.find();

  List<int?> get week => progress.weekArrows();

  int get weekTotal => week.whereType<int>().fold(0, (a, b) => a + b);

  List<Achievement> get achievements {
    final now = DateTime.now();
    return [
      Achievement('ach_flawless', progress.perfectClears.value, 10),
      Achievement('ach_hint_free', progress.noHintClears.value, 25),
      Achievement(
        'ach_month',
        progress.solvedInMonth(now.year, now.month),
        AppConfig.monthlyBadgeTarget,
      ),
      Achievement(
        'ach_halfway',
        progress.highestCleared.value,
        AppConfig.totalLevels ~/ 2,
      ),
      Achievement('ach_streak', progress.streakState.value.best, 30),
    ];
  }
}
