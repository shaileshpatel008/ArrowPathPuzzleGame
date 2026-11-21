import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/game/direction.dart';
import '../../data/game/level_spec.dart';

/// Draws an arrow glyph pointing [direction] inside [rect].
void paintArrowGlyph(
  Canvas canvas,
  Rect rect,
  Direction direction,
  Color color, {
  double strokeFactor = 0.11,
}) {
  final s = rect.shortestSide;
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.4, s * strokeFactor)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.save();
  canvas.translate(rect.center.dx, rect.center.dy);
  canvas.rotate(direction.quarterTurns * math.pi / 2);
  final h = s * 0.27;
  final w = s * 0.2;
  final path = Path()
    ..moveTo(0, h)
    ..lineTo(0, -h)
    ..moveTo(-w, -h + w)
    ..lineTo(0, -h)
    ..lineTo(w, -h + w);
  canvas.drawPath(path, paint);
  canvas.restore();
}

/// Small shape that tells directions apart without colour (colour-blind mode).
void paintDirectionMarker(Canvas canvas, Rect tile, Direction d, Color color) {
  final r = tile.shortestSide * 0.075;
  final c = Offset(tile.left + tile.width * 0.2, tile.top + tile.height * 0.2);
  final paint = Paint()..color = color.withValues(alpha: 0.9);
  switch (d) {
    case Direction.up:
      canvas.drawCircle(c, r, paint);
    case Direction.right:
      canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 1.8, height: r * 1.8),
        paint,
      );
    case Direction.down:
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy + r * 0.8)
          ..lineTo(c.dx - r, c.dy + r * 0.8)
          ..close(),
        paint,
      );
    case Direction.left:
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r * 1.1)
          ..lineTo(c.dx + r * 1.1, c.dy)
          ..lineTo(c.dx, c.dy + r * 1.1)
          ..lineTo(c.dx - r * 1.1, c.dy)
          ..close(),
        paint,
      );
  }
}

/// Paints a tactile tile: a darker base with the coloured face on top.
void paintTile(
  Canvas canvas,
  Rect rect,
  Color color, {
  double radiusFactor = 0.28,
}) {
  final radius = Radius.circular(rect.shortestSide * radiusFactor);
  final base = Color.lerp(color, Colors.black, 0.24)!;
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, radius),
    Paint()..color = base,
  );
  final face = Rect.fromLTRB(
    rect.left,
    rect.top,
    rect.right,
    rect.bottom - rect.height * 0.085,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(face, radius),
    Paint()..color = color,
  );
}

/// The brand mark: four tiles whose arrows point outwards.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 28,
    this.progress = 1,
    this.lightTile,
  });

  final double size;

  /// 0..1 reveal progress used by the splash animation.
  final double progress;
  final Color? lightTile;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _LogoPainter(progress, lightTile ?? const Color(0xFFF2F4F8)),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.t, this.light);

  final double t;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 28;
    final tiles = <(double, double, Color, Color, Direction)>[
      (0, 0, const Color(0xFF2E4BFF), Colors.white, Direction.up),
      (15, 0, const Color(0xFFE8590C), Colors.white, Direction.right),
      (0, 15, light, const Color(0xFF10131C), Direction.left),
      (15, 15, const Color(0xFF0E9F8E), Colors.white, Direction.down),
    ];
    for (var i = 0; i < tiles.length; i++) {
      final local = ((t - i * 0.12) / 0.64).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final e = Curves.easeOutBack.transform(local);
      final (x, y, color, glyph, dir) = tiles[i];
      final rect = Rect.fromLTWH(x * u, y * u, 13 * u, 13 * u);
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.scale(e);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(3.5 * u)),
        Paint()..color = color,
      );
      final shift =
          Offset(dir.dCol.toDouble(), dir.dRow.toDouble()) *
          (1 - local) *
          -2 *
          u;
      paintArrowGlyph(
        canvas,
        rect.shift(shift),
        dir,
        glyph,
        strokeFactor: 0.14,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.t != t || old.light != light;
}

/// Static preview of a puzzle (home hero card, theme previews).
class MiniBoard extends StatelessWidget {
  const MiniBoard({
    super.key,
    required this.spec,
    required this.cellColor,
    required this.tileColor,
    required this.glyphColor,
    this.size = 96,
  });

  final LevelSpec spec;
  final Color cellColor;
  final Color Function(Direction) tileColor;
  final Color glyphColor;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _MiniBoardPainter(spec, cellColor, tileColor, glyphColor),
    ),
  );
}

class _MiniBoardPainter extends CustomPainter {
  _MiniBoardPainter(this.spec, this.cell, this.tile, this.glyph);

  final LevelSpec spec;
  final Color cell;
  final Color Function(Direction) tile;
  final Color glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final n = spec.size;
    final gap = size.width * 0.045;
    final c = (size.width - gap * (n - 1)) / n;
    final occupied = {for (final a in spec.arrows) a.row * n + a.col: a};
    for (var r = 0; r < n; r++) {
      for (var col = 0; col < n; col++) {
        final rect = Rect.fromLTWH(col * (c + gap), r * (c + gap), c, c);
        final a = occupied[r * n + col];
        if (a == null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(c * 0.28)),
            Paint()..color = cell,
          );
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(c * 0.28)),
            Paint()..color = tile(a.direction),
          );
          paintArrowGlyph(canvas, rect, a.direction, glyph, strokeFactor: 0.13);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MiniBoardPainter old) =>
      old.spec != spec || old.cell != cell || old.glyph != glyph;
}
