import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/day.dart';
import '../game/level_catalog.dart';
import '../models/streak.dart';
import 'storage_service.dart';

/// What happened when a campaign level was cleared.
class ClearOutcome {
  const ClearOutcome({required this.firstClear, required this.earnedHint});

  final bool firstClear;
  final bool earnedHint;
}

/// Campaign progress, statistics and the daily-challenge streak.
class ProgressService extends GetxService {
  ProgressService(this._storage);

  final StorageService _storage;

  final onboardingDone = false.obs;
  final highestCleared = 0.obs;
  final stars = <int, int>{}.obs;
  final perfectClears = 0.obs;
  final noHintClears = 0.obs;
  final arrowsCleared = 0.obs;
  final hintsUsed = 0.obs;
  final arrowsByDay = <String, int>{}.obs;
  final dailySolved = <String>{}.obs;
  final streakState = const StreakState().obs;
  final plusOfferShown = false.obs;

  ProgressService init() {
    onboardingDone.value = _storage.readBool(StorageKeys.onboardingDone);
    highestCleared.value = _storage.readInt(StorageKeys.highestCleared);
    stars.assignAll(
      _storage
          .readIntMap(StorageKeys.stars)
          .map((k, v) => MapEntry(int.parse(k), v)),
    );
    perfectClears.value = _storage.readInt(StorageKeys.perfectClears);
    noHintClears.value = _storage.readInt(StorageKeys.noHintClears);
    arrowsCleared.value = _storage.readInt(StorageKeys.arrowsCleared);
    hintsUsed.value = _storage.readInt(StorageKeys.hintsUsed);
    arrowsByDay.assignAll(_storage.readIntMap(StorageKeys.arrowsByDay));
    dailySolved
      ..clear()
      ..addAll(_storage.readStringList(StorageKeys.dailySolved));
    plusOfferShown.value = _storage.readBool(StorageKeys.plusOfferShown);
    streakState.value = StreakState(
      streak: _storage.readInt(StorageKeys.dailyStreak),
      best: _storage.readInt(StorageKeys.dailyBestStreak),
      freezes: _storage.readInt(StorageKeys.dailyFreezes),
      lastSolved: _storage.readString(StorageKeys.dailyLastSolved),
    );
    return this;
  }

  // ----- Derived values -------------------------------------------------------

  /// The next level to play (capped at the last level).
  int get nextLevel =>
      (highestCleared.value + 1).clamp(1, LevelCatalog.totalLevels);

  bool get finishedCampaign => highestCleared.value >= LevelCatalog.totalLevels;

  bool isUnlocked(int level) => level <= highestCleared.value + 1;

  int starsFor(int level) => stars[level] ?? 0;

  int get currentStreak =>
      StreakRules.current(streakState.value, DateTime.now());

  bool get solvedToday => dailySolved.contains(Day.todayKey());

  int solvedInMonth(int year, int month) {
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-';
    return dailySolved.where((d) => d.startsWith(prefix)).length;
  }

  /// Arrows cleared per day for the current week, Monday first.
  List<int?> weekArrows([DateTime? now]) {
    final today = Day.dateOnly(now ?? DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      if (d.isAfter(today)) return null;
      return arrowsByDay[Day.key(d)] ?? 0;
    });
  }

  // ----- Mutations ------------------------------------------------------------

  Future<void> completeOnboarding() async {
    onboardingDone.value = true;
    await _storage.write(StorageKeys.onboardingDone, true);
  }

  Future<void> markPlusOfferShown() async {
    plusOfferShown.value = true;
    await _storage.write(StorageKeys.plusOfferShown, true);
  }

  Future<ClearOutcome> recordLevelClear({
    required int level,
    required int starCount,
    required bool usedHint,
  }) async {
    final previous = starsFor(level);
    final firstClear = previous == 0;
    if (starCount > previous) {
      stars[level] = starCount;
      await _storage.write(
        StorageKeys.stars,
        stars.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    if (level > highestCleared.value) {
      highestCleared.value = level;
      await _storage.write(StorageKeys.highestCleared, level);
    }
    // A free hint for the first 3-star clear of a level (no farming).
    final earnedHint = starCount == 3 && previous < 3 && !usedHint;
    if (starCount == 3 && previous < 3) {
      perfectClears.value++;
      await _storage.write(StorageKeys.perfectClears, perfectClears.value);
    }
    if (!usedHint && firstClear) {
      noHintClears.value++;
      await _storage.write(StorageKeys.noHintClears, noHintClears.value);
    }
    return ClearOutcome(firstClear: firstClear, earnedHint: earnedHint);
  }

  /// Marks a daily puzzle solved and returns the new streak.
  Future<int> recordDailySolve(DateTime date) async {
    final key = Day.key(date);
    if (dailySolved.add(key)) {
      await _storage.write(StorageKeys.dailySolved, dailySolved.toList());
    }
    if (Day.key(DateTime.now()) == key) {
      final s = StreakRules.onSolved(streakState.value, date);
      streakState.value = s;
      await _saveStreak(s);
    }
    return currentStreak;
  }

  /// Plus members receive one streak freeze per week (max 2 banked).
  Future<void> grantWeeklyFreeze({required bool isPlus}) async {
    if (!isPlus) return;
    final week = Day.weekIndex(DateTime.now());
    if (_storage.readInt(StorageKeys.dailyFreezeWeek, fallback: -1) == week) {
      return;
    }
    final s = streakState.value;
    streakState.value = s.copyWith(freezes: (s.freezes + 1).clamp(0, 2));
    await _storage.write(StorageKeys.dailyFreezeWeek, week);
    await _saveStreak(streakState.value);
  }

  Future<void> addArrows(int count) async {
    if (count <= 0) return;
    arrowsCleared.value += count;
    final key = Day.todayKey();
    arrowsByDay[key] = (arrowsByDay[key] ?? 0) + count;
    // Keep two weeks of history.
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    arrowsByDay.removeWhere((k, _) => Day.parse(k).isBefore(cutoff));
    await _storage.write(StorageKeys.arrowsCleared, arrowsCleared.value);
    await _storage.write(
      StorageKeys.arrowsByDay,
      Map<String, int>.of(arrowsByDay),
    );
  }

  Future<void> addHintUsed() async {
    hintsUsed.value++;
    await _storage.write(StorageKeys.hintsUsed, hintsUsed.value);
  }

  /// Returns true once per configured milestone (used for the review prompt).
  bool shouldAskForReview(int clearedLevel) {
    if (!AppConfig.reviewPromptLevels.contains(clearedLevel)) return false;
    final asked = _storage.readStringList(StorageKeys.reviewAsked);
    if (asked.contains('$clearedLevel')) return false;
    _storage.write(StorageKeys.reviewAsked, [...asked, '$clearedLevel']);
    return true;
  }

  Future<void> resetAll() async {
    await _storage.resetProgress();
    init();
    stars.refresh();
  }

  Future<void> _saveStreak(StreakState s) async {
    await _storage.write(StorageKeys.dailyStreak, s.streak);
    await _storage.write(StorageKeys.dailyBestStreak, s.best);
    await _storage.write(StorageKeys.dailyFreezes, s.freezes);
    if (s.lastSolved != null) {
      await _storage.write(StorageKeys.dailyLastSolved, s.lastSolved);
    }
  }
}
