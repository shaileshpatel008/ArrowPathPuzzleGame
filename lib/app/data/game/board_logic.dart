import 'level_spec.dart';

/// Pure rules of the game. No Flutter, fully unit tested.
abstract final class BoardLogic {
  /// Walks from [arrow] in its direction across a [size]x[size] board.
  /// [occupant] returns the id of the arrow at a cell, or null when empty.
  static RayResult castRay(
    ArrowSpec arrow,
    int size,
    int? Function(int row, int col) occupant,
  ) {
    final cells = <Cell>[];
    var r = arrow.row + arrow.direction.dRow;
    var c = arrow.col + arrow.direction.dCol;
    while (r >= 0 && r < size && c >= 0 && c < size) {
      final hit = occupant(r, c);
      if (hit != null) return RayResult(cells, hit);
      cells.add(Cell(r, c));
      r += arrow.direction.dRow;
      c += arrow.direction.dCol;
    }
    return RayResult(cells, null);
  }

  /// Ray cast against a list of remaining arrows.
  static RayResult castAgainst(
    ArrowSpec arrow,
    int size,
    Iterable<ArrowSpec> remaining,
  ) {
    final grid = _grid(size, remaining);
    return castRay(arrow, size, (r, c) => grid[r * size + c]);
  }

  /// Arrows that can leave the board right now.
  static List<ArrowSpec> freeArrows(int size, Iterable<ArrowSpec> remaining) {
    final grid = _grid(size, remaining);
    return remaining
        .where((a) => castRay(a, size, (r, c) => grid[r * size + c]).isClear)
        .toList();
  }

  /// Number of rounds to clear the board firing every free arrow per round,
  /// or -1 when the board is stuck (unsolvable).
  ///
  /// Removing an arrow can never block another one, so this greedy check is
  /// a complete solvability test.
  static int solveDepth(int size, List<ArrowSpec> arrows) {
    var remaining = List<ArrowSpec>.of(arrows);
    var depth = 0;
    while (remaining.isNotEmpty) {
      final free = freeArrows(size, remaining).map((a) => a.id).toSet();
      if (free.isEmpty) return -1;
      remaining = remaining.where((a) => !free.contains(a.id)).toList();
      depth++;
    }
    return depth;
  }

  static List<int?> _grid(int size, Iterable<ArrowSpec> arrows) {
    final grid = List<int?>.filled(size * size, null);
    for (final a in arrows) {
      grid[a.row * size + a.col] = a.id;
    }
    return grid;
  }
}
