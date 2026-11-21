import 'board_logic.dart';
import 'direction.dart';
import 'level_spec.dart';
import 'seeded_random.dart';

/// Builds puzzles that are solvable *by construction*.
///
/// Arrows are placed in reverse solving order: every new arrow must have a
/// clear path past the arrows already on the board. Undoing the placement
/// (newest first) is therefore always a valid solution.
///
/// To make puzzles interesting, new arrows prefer cells that sit on the
/// path of arrows already placed, which creates chains of dependencies.
abstract final class LevelGenerator {
  static LevelSpec generate({
    required int size,
    required int count,
    required int seed,
  }) {
    final rng = SeededRandom(seed);
    final grid = List<int?>.filled(size * size, null);
    final placed = <ArrowSpec>[];
    int? lookup(int r, int c) => grid[r * size + c];

    while (placed.length < count) {
      // How many placed arrows would be blocked by an arrow on each cell.
      final cover = List<int>.filled(size * size, 0);
      for (final a in placed) {
        for (final cell in BoardLogic.castRay(a, size, lookup).cells) {
          cover[cell.row * size + cell.col]++;
        }
      }

      final candidates = <_Candidate>[];
      for (var idx = 0; idx < size * size; idx++) {
        if (grid[idx] != null) continue;
        final row = idx ~/ size;
        final col = idx % size;
        for (final dir in Direction.values) {
          final probe = ArrowSpec(-1, row, col, dir);
          final ray = BoardLogic.castRay(probe, size, lookup);
          if (!ray.isClear) continue;
          var score = cover[idx] * 3.0 + ray.cells.length * 0.12;
          if (ray.cells.isEmpty) score -= 1.6; // pointing straight off an edge
          score += rng.nextDouble() * 1.4;
          candidates.add(_Candidate(row, col, dir, score, candidates.length));
        }
      }
      if (candidates.isEmpty) break;

      candidates.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.order.compareTo(b.order);
      });
      final top = (candidates.length * 0.12).ceil().clamp(1, candidates.length);
      final pick = candidates[rng.nextInt(top)];

      final arrow = ArrowSpec(placed.length, pick.row, pick.col, pick.dir);
      placed.add(arrow);
      grid[pick.row * size + pick.col] = arrow.id;
    }

    return LevelSpec(
      size: size,
      arrows: placed,
      seed: seed,
      depth: BoardLogic.solveDepth(size, placed),
    );
  }
}

class _Candidate {
  _Candidate(this.row, this.col, this.dir, this.score, this.order);

  final int row;
  final int col;
  final Direction dir;
  final double score;
  final int order;
}
