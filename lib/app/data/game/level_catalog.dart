import 'level_generator.dart';
import 'level_spec.dart';
import 'seeded_random.dart';

/// A group of levels sharing one board size.
class Chapter {
  const Chapter({
    required this.number,
    required this.titleKey,
    required this.subtitleKey,
    required this.size,
    required this.firstLevel,
    required this.lastLevel,
    required this.densityFrom,
    required this.densityTo,
  });

  final int number;
  final String titleKey;
  final String subtitleKey;
  final int size;
  final int firstLevel;
  final int lastLevel;
  final double densityFrom;
  final double densityTo;

  int get levelCount => lastLevel - firstLevel + 1;
  bool contains(int level) => level >= firstLevel && level <= lastLevel;
}

/// Every level of the game, generated on demand and cached.
abstract final class LevelCatalog {
  static const chapters = <Chapter>[
    Chapter(
      number: 1,
      titleKey: 'ch1_title',
      subtitleKey: 'ch1_sub',
      size: 4,
      firstLevel: 1,
      lastLevel: 10,
      densityFrom: .40,
      densityTo: .62,
    ),
    Chapter(
      number: 2,
      titleKey: 'ch2_title',
      subtitleKey: 'ch2_sub',
      size: 5,
      firstLevel: 11,
      lastLevel: 20,
      densityFrom: .48,
      densityTo: .64,
    ),
    Chapter(
      number: 3,
      titleKey: 'ch3_title',
      subtitleKey: 'ch3_sub',
      size: 6,
      firstLevel: 21,
      lastLevel: 35,
      densityFrom: .50,
      densityTo: .66,
    ),
    Chapter(
      number: 4,
      titleKey: 'ch4_title',
      subtitleKey: 'ch4_sub',
      size: 7,
      firstLevel: 36,
      lastLevel: 55,
      densityFrom: .52,
      densityTo: .68,
    ),
    Chapter(
      number: 5,
      titleKey: 'ch5_title',
      subtitleKey: 'ch5_sub',
      size: 8,
      firstLevel: 56,
      lastLevel: 80,
      densityFrom: .55,
      densityTo: .70,
    ),
    Chapter(
      number: 6,
      titleKey: 'ch6_title',
      subtitleKey: 'ch6_sub',
      size: 9,
      firstLevel: 81,
      lastLevel: 110,
      densityFrom: .55,
      densityTo: .72,
    ),
    Chapter(
      number: 7,
      titleKey: 'ch7_title',
      subtitleKey: 'ch7_sub',
      size: 9,
      firstLevel: 111,
      lastLevel: 150,
      densityFrom: .62,
      densityTo: .78,
    ),
    Chapter(
      number: 8,
      titleKey: 'ch8_title',
      subtitleKey: 'ch8_sub',
      size: 9,
      firstLevel: 151,
      lastLevel: 200,
      densityFrom: .68,
      densityTo: .82,
    ),
  ];

  static int get totalLevels => chapters.last.lastLevel;

  static final _cache = <int, LevelSpec>{};
  static final _dailyCache = <int, LevelSpec>{};

  static Chapter chapterOf(int level) => chapters.firstWhere(
    (c) => c.contains(level),
    orElse: () => chapters.last,
  );

  /// Puzzle for a campaign level (1-based).
  static LevelSpec level(int level) {
    return _cache.putIfAbsent(level, () {
      final ch = chapterOf(level);
      final cells = ch.size * ch.size;
      final t = ch.levelCount <= 1
          ? 0.0
          : (level - ch.firstLevel) / (ch.levelCount - 1);
      final density = ch.densityFrom + (ch.densityTo - ch.densityFrom) * t;
      // The first three levels are a gentle introduction.
      final count = switch (level) {
        1 => 3,
        2 => 4,
        3 => 5,
        _ => (cells * density).round(),
      };
      return LevelGenerator.generate(
        size: ch.size,
        count: count,
        seed: SeededRandom.hash(level * 7919 + 104729),
      );
    });
  }

  /// The daily puzzle for a date, identical for every player.
  static LevelSpec daily(DateTime date) {
    final key = date.year * 10000 + date.month * 100 + date.day;
    return _dailyCache.putIfAbsent(
      key,
      () => LevelGenerator.generate(
        size: dailySize,
        count: (dailySize * dailySize * 0.68).round(),
        seed: SeededRandom.hash(key * 31 + 0xA11CE),
      ),
    );
  }

  static const dailySize = 8;
}
