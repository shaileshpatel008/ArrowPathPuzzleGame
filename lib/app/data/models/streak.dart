import '../../core/utils/day.dart';

/// Daily-challenge streak state. Pure value object + rules (unit tested).
class StreakState {
  const StreakState({
    this.streak = 0,
    this.best = 0,
    this.freezes = 0,
    this.lastSolved,
  });

  final int streak;
  final int best;
  final int freezes;

  /// `yyyy-mm-dd` of the last solved daily puzzle.
  final String? lastSolved;

  StreakState copyWith({
    int? streak,
    int? best,
    int? freezes,
    String? lastSolved,
  }) => StreakState(
    streak: streak ?? this.streak,
    best: best ?? this.best,
    freezes: freezes ?? this.freezes,
    lastSolved: lastSolved ?? this.lastSolved,
  );
}

abstract final class StreakRules {
  /// Applies solving the daily puzzle of [day]. Missed days in between are
  /// bridged with streak freezes when enough are available.
  static StreakState onSolved(StreakState s, DateTime day) {
    final key = Day.key(day);
    if (s.lastSolved == key) return s;
    if (s.lastSolved == null) {
      return s.copyWith(
        streak: 1,
        best: s.best < 1 ? 1 : s.best,
        lastSolved: key,
      );
    }
    final gap = Day.between(Day.parse(s.lastSolved!), day);
    if (gap <= 0) return s; // solving an older (archive) day: no change
    var streak = 1;
    var freezes = s.freezes;
    if (gap == 1) {
      streak = s.streak + 1;
    } else if (gap - 1 <= s.freezes) {
      freezes -= gap - 1;
      streak = s.streak + 1;
    }
    return StreakState(
      streak: streak,
      best: streak > s.best ? streak : s.best,
      freezes: freezes,
      lastSolved: key,
    );
  }

  /// The streak to display today: still alive if today or yesterday was
  /// solved, or if the missed days can be covered by freezes.
  static int current(StreakState s, DateTime today) {
    if (s.lastSolved == null) return 0;
    final gap = Day.between(Day.parse(s.lastSolved!), today);
    if (gap <= 1) return s.streak;
    return gap - 1 <= s.freezes ? s.streak : 0;
  }
}
