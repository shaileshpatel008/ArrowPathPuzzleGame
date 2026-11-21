import 'direction.dart';

/// A single arrow on the board (immutable puzzle data).
class ArrowSpec {
  const ArrowSpec(this.id, this.row, this.col, this.direction);

  final int id;
  final int row;
  final int col;
  final Direction direction;

  @override
  String toString() => '$row,$col,${direction.code}';
}

/// A cell position on the board.
class Cell {
  const Cell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => row * 31 + col;
}

/// Result of casting an arrow forward across the board.
class RayResult {
  const RayResult(this.cells, this.blockerId);

  /// Empty cells the arrow passes through before leaving or hitting.
  final List<Cell> cells;

  /// Id of the first arrow in the way, or null when the path is clear.
  final int? blockerId;

  bool get isClear => blockerId == null;
}

/// A full puzzle.
class LevelSpec {
  const LevelSpec({
    required this.size,
    required this.arrows,
    required this.seed,
    required this.depth,
  });

  final int size;
  final List<ArrowSpec> arrows;
  final int seed;

  /// Minimum number of "rounds" needed to clear the board when every free
  /// arrow is fired each round. A rough difficulty signal.
  final int depth;
}
