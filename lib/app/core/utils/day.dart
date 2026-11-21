/// Calendar-day helpers based on the device's local time.
abstract final class Day {
  /// `yyyy-mm-dd` for [date] (local).
  static String key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String todayKey([DateTime? now]) => key(now ?? DateTime.now());

  static DateTime parse(String key) {
    final p = key.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whole calendar days from [a] to [b] (DST safe).
  static int between(DateTime a, DateTime b) {
    final ua = DateTime.utc(a.year, a.month, a.day);
    final ub = DateTime.utc(b.year, b.month, b.day);
    return ub.difference(ua).inDays;
  }

  /// ISO-like week number used to grant one streak freeze per week.
  static int weekIndex(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      (Duration.millisecondsPerDay * 7);

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}
