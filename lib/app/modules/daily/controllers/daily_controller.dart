import 'dart:async';

import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../core/utils/day.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/models/level_result.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../../routes/app_routes.dart';

enum DayState { solved, today, missed, future, beforeStart }

class CalendarDay {
  const CalendarDay(this.date, this.state);
  final DateTime date;
  final DayState state;
}

class DailyController extends GetxController {
  final ProgressService progress = Get.find();
  final WalletService wallet = Get.find();

  late final month = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final resetsIn = ''.obs;
  Timer? _timer;

  /// How far back the archive goes.
  static const archiveMonths = 6;

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

  DateTime get _thisMonth =>
      DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get _firstMonth =>
      DateTime(_thisMonth.year, _thisMonth.month - archiveMonths + 1);

  bool get canGoBack => month.value.isAfter(_firstMonth);
  bool get canGoForward => month.value.isBefore(_thisMonth);

  void prevMonth() {
    if (canGoBack) {
      month.value = DateTime(month.value.year, month.value.month - 1);
    }
  }

  void nextMonth() {
    if (canGoForward) {
      month.value = DateTime(month.value.year, month.value.month + 1);
    }
  }

  /// Leading blanks (Sunday-first grid) followed by the month's days.
  List<CalendarDay?> get grid {
    final m = month.value;
    final today = Day.dateOnly(DateTime.now());
    final lead = DateTime(m.year, m.month).weekday % 7;
    final days = Day.daysInMonth(m.year, m.month);
    // Touch reactive state.
    final solved = progress.dailySolved;
    return [
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= days; d++)
        () {
          final date = DateTime(m.year, m.month, d);
          final key = Day.key(date);
          final DayState state;
          if (solved.contains(key)) {
            state = DayState.solved;
          } else if (date == today) {
            state = DayState.today;
          } else if (date.isAfter(today)) {
            state = DayState.future;
          } else {
            state = DayState.missed;
          }
          return CalendarDay(date, state);
        }(),
    ];
  }

  int get solvedThisMonth =>
      progress.solvedInMonth(month.value.year, month.value.month);

  void tapDay(CalendarDay day) {
    switch (day.state) {
      case DayState.today:
        playToday();
      case DayState.future:
      case DayState.beforeStart:
        AppToast.show('daily_future'.tr);
      case DayState.solved:
      case DayState.missed:
        if (Day.key(day.date) == Day.todayKey()) {
          playToday();
        } else if (wallet.isPlus.value) {
          Get.toNamed<void>(Routes.game, arguments: GameArgs.daily(day.date));
        } else {
          AppToast.show('archive_plus'.trParams({'plus': AppConfig.plusName}));
          Get.toNamed<void>(Routes.plus);
        }
    }
  }

  void playToday() =>
      Get.toNamed<void>(Routes.game, arguments: GameArgs.daily(DateTime.now()));

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
