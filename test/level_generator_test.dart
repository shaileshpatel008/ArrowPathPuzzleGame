import 'package:arrowpathpuzzle/app/data/game/board_logic.dart';
import 'package:arrowpathpuzzle/app/data/game/direction.dart';
import 'package:arrowpathpuzzle/app/data/game/level_catalog.dart';
import 'package:arrowpathpuzzle/app/data/game/level_generator.dart';
import 'package:arrowpathpuzzle/app/data/game/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardLogic', () {
    test('ray stops at the first arrow in the way', () {
      const a = ArrowSpec(0, 1, 0, Direction.right);
      const b = ArrowSpec(1, 1, 3, Direction.up);
      final ray = BoardLogic.castAgainst(a, 5, [a, b]);
      expect(ray.blockerId, 1);
      expect(ray.cells.length, 2);
    });

    test('arrows facing each other are unsolvable', () {
      const a = ArrowSpec(0, 0, 0, Direction.right);
      const b = ArrowSpec(1, 0, 2, Direction.left);
      expect(BoardLogic.solveDepth(4, [a, b]), -1);
    });
  });

  group('LevelCatalog', () {
    test('every campaign level is solvable and has the planned size', () {
      for (var n = 1; n <= LevelCatalog.totalLevels; n++) {
        final level = LevelCatalog.level(n);
        final chapter = LevelCatalog.chapterOf(n);
        expect(level.size, chapter.size, reason: 'level $n');
        expect(level.arrows, isNotEmpty, reason: 'level $n');
        expect(level.depth, greaterThan(0), reason: 'level $n unsolvable');
        final cells = level.arrows.map((a) => a.row * 100 + a.col).toSet();
        expect(cells.length, level.arrows.length, reason: 'overlap in $n');
      }
    });

    test('levels are deterministic', () {
      final a = LevelGenerator.generate(size: 7, count: 31, seed: 42);
      final b = LevelGenerator.generate(size: 7, count: 31, seed: 42);
      expect(a.arrows.toString(), b.arrows.toString());
    });

    test('daily puzzles are solvable for a whole year', () {
      var day = DateTime(2026);
      for (var i = 0; i < 366; i++) {
        final spec = LevelCatalog.daily(day);
        expect(spec.depth, greaterThan(0), reason: '$day');
        day = day.add(const Duration(days: 1));
      }
    });

    test('difficulty grows across chapters', () {
      double avgDepth(int from, int to) {
        var sum = 0;
        for (var n = from; n <= to; n++) {
          sum += LevelCatalog.level(n).depth;
        }
        return sum / (to - from + 1);
      }

      expect(avgDepth(1, 10), lessThan(avgDepth(56, 80)));
      expect(avgDepth(56, 80), lessThan(avgDepth(151, 200)));
    });
  });
}
