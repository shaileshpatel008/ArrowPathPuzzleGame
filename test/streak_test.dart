import 'package:arrowpathpuzzle/app/data/models/streak.dart';
import 'package:arrowpathpuzzle/app/data/models/level_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final d = DateTime(2026, 11, 20);

  test('first solve starts a streak of 1', () {
    final s = StreakRules.onSolved(const StreakState(), d);
    expect(s.streak, 1);
    expect(s.best, 1);
  });

  test('consecutive days grow the streak', () {
    var s = StreakRules.onSolved(const StreakState(), d);
    s = StreakRules.onSolved(s, d.add(const Duration(days: 1)));
    s = StreakRules.onSolved(s, d.add(const Duration(days: 2)));
    expect(s.streak, 3);
    expect(s.best, 3);
  });

  test('solving twice on the same day changes nothing', () {
    final s = StreakRules.onSolved(const StreakState(), d);
    expect(StreakRules.onSolved(s, d).streak, 1);
  });

  test('a missed day resets the streak without freezes', () {
    var s = StreakRules.onSolved(
      const StreakState(streak: 5, best: 5, lastSolved: '2026-11-18'),
      d,
    );
    expect(s.streak, 1);
    expect(s.best, 5);
    s = StreakRules.onSolved(s, d.add(const Duration(days: 1)));
    expect(s.streak, 2);
  });

  test('a freeze bridges one missed day', () {
    final s = StreakRules.onSolved(
      const StreakState(
        streak: 5,
        best: 5,
        freezes: 1,
        lastSolved: '2026-11-18',
      ),
      d,
    );
    expect(s.streak, 6);
    expect(s.freezes, 0);
  });

  test('current streak shows 0 once it is broken', () {
    const s = StreakState(streak: 4, best: 4, lastSolved: '2026-11-17');
    expect(StreakRules.current(s, d), 0);
    expect(StreakRules.current(s, DateTime(2026, 11, 18)), 4);
  });

  test('stars depend on crashes', () {
    expect(LevelResult.starsFor(0), 3);
    expect(LevelResult.starsFor(1), 2);
    expect(LevelResult.starsFor(2), 1);
  });
}
