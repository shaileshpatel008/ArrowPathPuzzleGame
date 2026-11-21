/// The four directions an arrow can point to.
enum Direction {
  up(-1, 0, 0),
  right(0, 1, 1),
  down(1, 0, 2),
  left(0, -1, 3);

  const Direction(this.dRow, this.dCol, this.quarterTurns);

  final int dRow;
  final int dCol;

  /// Clockwise quarter turns from "up" (used to rotate the arrow glyph).
  final int quarterTurns;

  String get code => switch (this) {
    Direction.up => 'U',
    Direction.right => 'R',
    Direction.down => 'D',
    Direction.left => 'L',
  };

  static Direction fromCode(String code) =>
      Direction.values.firstWhere((d) => d.code == code);
}
