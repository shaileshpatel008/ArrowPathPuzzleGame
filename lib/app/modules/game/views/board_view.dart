import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide Direction;
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/painters.dart';
import '../../../data/game/direction.dart';
import '../controllers/game_controller.dart';
import '../models/board_arrow.dart';

/// Geometry of the board for a given pixel size.
class BoardMetrics {
  BoardMetrics(double side, this.n)
    : pad = side * 0.04,
      gap = math.max(3, side * 0.016) {
    cell = (side - pad * 2 - gap * (n - 1)) / n;
    inner = side - pad * 2;
  }

  final int n;
  final double pad;
  final double gap;
  late final double cell;
  late final double inner;

  double get step => cell + gap;
  Offset origin(int row, int col) => Offset(col * step, row * step);
}

class BoardView extends StatelessWidget {
  const BoardView({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.min(math.min(box.maxWidth, box.maxHeight), 460.0);
        final m = BoardMetrics(side, controller.spec.size);
        return Center(
          child: Container(
            width: side,
            height: side,
            padding: EdgeInsets.all(m.pad),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(side * 0.085),
              border: Border.all(color: p.line),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _GridPainter(m, p.cell)),
                ),
                Positioned.fill(
                  child: _PathOverlay(controller: controller, m: m),
                ),
                for (final a in controller.arrows)
                  ArrowTileView(
                    key: ValueKey(a.id),
                    arrow: a,
                    m: m,
                    controller: controller,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.m, this.color);

  final BoardMetrics m;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = Radius.circular(m.cell * 0.28);
    for (var row = 0; row < m.n; row++) {
      for (var col = 0; col < m.n; col++) {
        final o = m.origin(row, col);
        canvas.drawRRect(
          RRect.fromRectAndRadius(o & Size.square(m.cell), r),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color || old.m.cell != m.cell;
}

class _PathOverlay extends StatelessWidget {
  const _PathOverlay({required this.controller, required this.m});

  final GameController controller;
  final BoardMetrics m;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Obx(() {
      final tone = controller.pathTone.value;
      final version = controller.pathVersion.value;
      if (tone == PathTone.none || controller.path.isEmpty) {
        return const SizedBox.shrink();
      }
      final (Color bg, Color dot) = switch (tone) {
        PathTone.blocked => (p.dangerSoft, p.danger),
        PathTone.hint => (p.warnSoft, p.warn),
        _ => (p.primarySoft, p.primary),
      };
      final reduce = context.reduceMotion;
      return Stack(
        children: [
          for (final (i, c) in controller.path.indexed)
            Positioned(
              left: c.col * m.step,
              top: c.row * m.step,
              width: m.cell,
              height: m.cell,
              child: _cell(bg, dot, reduce, i, version),
            ),
        ],
      );
    });
  }

  Widget _cell(Color bg, Color dot, bool reduce, int i, int version) {
    final w = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(m.cell * 0.28),
      ),
      child: Center(
        child: Container(
          width: m.cell * 0.2,
          height: m.cell * 0.2,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
      ),
    );
    if (reduce) return w;
    return w
        .animate(key: ValueKey('p$version-$i'))
        .fadeIn(delay: (i * 35).ms, duration: 160.ms)
        .scaleXY(
          begin: 0.6,
          end: 1,
          delay: (i * 35).ms,
          duration: 220.ms,
          curve: Curves.easeOutBack,
        );
  }
}

/// One arrow tile. Owns its animations and reacts to [BoardArrow.fx].
class ArrowTileView extends StatefulWidget {
  const ArrowTileView({
    super.key,
    required this.arrow,
    required this.m,
    required this.controller,
  });

  final BoardArrow arrow;
  final BoardMetrics m;
  final GameController controller;

  @override
  State<ArrowTileView> createState() => _ArrowTileViewState();
}

class _ArrowTileViewState extends State<ArrowTileView>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final AnimationController _exit = AnimationController(vsync: this);
  late final AnimationController _bump = AnimationController(vsync: this);
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Worker? _fxWorker;
  int _exitCells = 0;
  int _bumpCells = 0;
  bool _pressed = false;

  BoardArrow get a => widget.arrow;

  @override
  void initState() {
    super.initState();
    _fxWorker = ever<ArrowFx>(a.fx, _onFx);
    _exit.addStatusListener((s) {
      if (s == AnimationStatus.completed) a.gone.value = true;
    });
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inherited widgets (MediaQuery for "reduce motion") are only safe to
    // read from here on, so the first effect is played now.
    if (!_started) {
      _started = true;
      _onFx(a.fx.value);
    }
  }

  bool get _reduce => context.reduceMotion;

  Future<void> _onFx(ArrowFx fx) async {
    if (fx.delayMs > 0 && !_reduce) {
      await Future<void>.delayed(Duration(milliseconds: fx.delayMs));
    }
    if (!mounted || a.fx.value.token != fx.token) return;
    switch (fx.kind) {
      case ArrowFxKind.idle:
        _enter.value = 1;
      case ArrowFxKind.enter:
      case ArrowFxKind.undo:
        _exit.value = 0;
        _bump.value = 0;
        _enter.value = 0;
        if (_reduce) {
          _enter.value = 1;
        } else {
          await _enter.forward();
        }
      case ArrowFxKind.exit:
        _exitCells = fx.cells;
        _exit.duration = Duration(
          milliseconds: (150 + 42 * fx.cells).clamp(180, 560),
        );
        if (_reduce) {
          _exit.value = 1;
          a.gone.value = true;
        } else {
          await _exit.forward(from: 0);
        }
      case ArrowFxKind.bump:
        _bumpCells = fx.cells;
        _bump.duration = Duration(milliseconds: 520 + 40 * fx.cells);
        if (!_reduce) await _bump.forward(from: 0);
      case ArrowFxKind.shake:
        if (!_reduce) await _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fxWorker?.dispose();
    _enter.dispose();
    _exit.dispose();
    _bump.dispose();
    _shake.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Forward travel during the bump: out quickly, back with a spring.
  double _bumpOffset(double t) {
    final reach = _bumpCells * widget.m.step + widget.m.cell * 0.16;
    if (t < 0.28) return reach * Curves.easeIn.transform(t / 0.28);
    return reach * (1 - Curves.elasticOut.transform((t - 0.28) / 0.72));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final c = widget.controller;
    final s = a.spec;
    final o = m.origin(s.row, s.col);
    final dir = s.direction;
    final unit = Offset(dir.dCol.toDouble(), dir.dRow.toDouble());
    final p = context.pal;

    final visual = Obx(() {
      if (a.gone.value) return const SizedBox.shrink();
      final isHint = c.hintId.value == a.id;
      final isAim = c.aimedId.value == a.id;
      final isFlash = c.flashIds.contains(a.id);
      final Color? ring = isFlash
          ? p.danger
          : (isHint ? p.warn : (isAim ? p.primary : null));
      final pulsing = (isHint || isAim) && !context.reduceMotion;
      if (pulsing && !_pulse.isAnimating) {
        _pulse.repeat(reverse: true);
      } else if (!pulsing && _pulse.isAnimating) {
        _pulse.stop();
        _pulse.value = 0;
      }
      final colorBlind = c.settings.colorBlind.value;
      final skin = p.skin;

      return Positioned(
        left: o.dx,
        top: o.dy,
        width: m.cell,
        height: m.cell,
        child: AnimatedBuilder(
          animation: Listenable.merge([_enter, _exit, _bump, _shake, _pulse]),
          builder: (context, _) {
            final exitT = Curves.easeInCubic.transform(_exit.value);
            final travel = exitT * _exitCells * m.step;
            final bump = _bump.isAnimating || _bump.value > 0
                ? _bumpOffset(_bump.value)
                : 0.0;
            final shake = _shake.isAnimating
                ? math.sin(_shake.value * math.pi * 7) *
                      (1 - _shake.value) *
                      m.cell *
                      0.09
                : 0.0;
            final offset =
                unit * (travel + bump) +
                Offset(dir.dRow != 0 ? shake : 0, dir.dCol != 0 ? shake : 0);
            final enterT = Curves.easeOutBack.transform(
              _enter.value.clamp(0.0, 1.0),
            );
            final scale =
                (_pressed ? 0.9 : 1.0) *
                (0.2 + 0.8 * enterT) *
                (1 - 0.15 * exitT);
            final opacity =
                (_enter.value.clamp(0.0, 1.0)) *
                (1 - ((_exit.value - 0.55) / 0.45).clamp(0.0, 1.0));
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (_exit.value > 0)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrailPainter(
                        unit: unit,
                        length: travel,
                        color: skin.tileFor(dir),
                        fade: 1 - _exit.value,
                        cell: m.cell,
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: offset,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: CustomPaint(
                        size: Size.square(m.cell),
                        painter: _TilePainter(
                          color: skin.tileFor(dir),
                          glyph: skin.glyph,
                          direction: dir,
                          ring: ring,
                          ringPulse: _pulse.value,
                          colorBlind: colorBlind,
                          surface: p.surface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });

    final hitArea = Obx(() {
      if (!c.remaining.contains(a.id)) return const SizedBox.shrink();
      return Positioned(
        left: o.dx,
        top: o.dy,
        width: m.cell,
        height: m.cell,
        child: Semantics(
          button: true,
          label: _label(dir, s.row, s.col),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            onTap: () => c.tapArrow(a.id),
          ),
        ),
      );
    });

    // The hit area stays on the grid cell; the visual may fly away.
    return Positioned.fill(
      child: Stack(clipBehavior: Clip.none, children: [visual, hitArea]),
    );
  }

  String _label(Direction d, int row, int col) => 'arrow_a11y'.trParams({
    'dir': 'dir_${d.name}'.tr,
    'row': '${row + 1}',
    'col': '${col + 1}',
  });

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }
}

class _TilePainter extends CustomPainter {
  _TilePainter({
    required this.color,
    required this.glyph,
    required this.direction,
    required this.ring,
    required this.ringPulse,
    required this.colorBlind,
    required this.surface,
  });

  final Color color;
  final Color glyph;
  final Direction direction;
  final Color? ring;
  final double ringPulse;
  final bool colorBlind;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (ring != null) {
      final grow = size.width * (0.1 + 0.05 * ringPulse);
      final rr = RRect.fromRectAndRadius(
        rect.inflate(grow),
        Radius.circular(size.width * 0.36),
      );
      canvas.drawRRect(
        rr,
        Paint()..color = ring!.withValues(alpha: 0.9 - 0.3 * ringPulse),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(size.width * 0.05),
          Radius.circular(size.width * 0.32),
        ),
        Paint()..color = surface,
      );
    }
    paintTile(canvas, rect, color);
    final face = Rect.fromLTWH(0, 0, size.width, size.height * 0.915);
    paintArrowGlyph(canvas, face, direction, glyph);
    if (colorBlind) paintDirectionMarker(canvas, face, direction, glyph);
  }

  @override
  bool shouldRepaint(_TilePainter old) =>
      old.color != color ||
      old.ring != ring ||
      old.ringPulse != ringPulse ||
      old.colorBlind != colorBlind ||
      old.glyph != glyph;
}

/// Motion streak left behind by an arrow leaving the board.
class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.unit,
    required this.length,
    required this.color,
    required this.fade,
    required this.cell,
  });

  final Offset unit;
  final double length;
  final Color color;
  final double fade;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    if (length <= 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final end = c + unit * length;
    final thickness = cell * 0.34;
    final rect = Rect.fromPoints(
      c - Offset(unit.dy.abs(), unit.dx.abs()) * thickness / 2,
      end + Offset(unit.dy.abs(), unit.dx.abs()) * thickness / 2,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-unit.dx, -unit.dy),
        end: Alignment(unit.dx, unit.dy),
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.38 * fade),
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(thickness / 2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.length != length || old.fade != fade;
}

/// Palette helper used by tests and previews.
Color tileColorFor(AppPalette p, Direction d) => p.skin.tileFor(d);
