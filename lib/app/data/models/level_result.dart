/// Which kind of puzzle is being played.
enum GameMode { campaign, daily }

/// Arguments for the game screen.
class GameArgs {
  const GameArgs.campaign(this.level) : mode = GameMode.campaign, date = null;
  const GameArgs.daily(DateTime this.date) : mode = GameMode.daily, level = 0;

  final GameMode mode;
  final int level;
  final DateTime? date;
}

/// Summary of a finished puzzle, shown on the result screen.
class LevelResult {
  const LevelResult({
    required this.args,
    required this.stars,
    required this.taps,
    required this.crashes,
    required this.heartsLeft,
    required this.hintsUsed,
    required this.duration,
    required this.earnedHint,
    required this.firstClear,
    required this.streak,
  });

  final GameArgs args;
  final int stars;
  final int taps;
  final int crashes;
  final int heartsLeft;
  final int hintsUsed;
  final Duration duration;
  final bool earnedHint;
  final bool firstClear;

  /// Daily streak after solving (daily mode only).
  final int streak;

  bool get perfect => crashes == 0 && hintsUsed == 0;

  static int starsFor(int crashes) => switch (crashes) {
    0 => 3,
    1 => 2,
    _ => 1,
  };
}
