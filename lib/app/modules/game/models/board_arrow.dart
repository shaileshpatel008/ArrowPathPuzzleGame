import 'package:get/get.dart';

import '../../../data/game/level_spec.dart';

enum ArrowFxKind { idle, enter, exit, bump, shake, undo }

/// A visual effect request for one tile. [token] makes repeated effects of
/// the same kind distinct so the tile replays them.
class ArrowFx {
  const ArrowFx(this.kind, {this.cells = 0, this.delayMs = 0, this.token = 0});

  final ArrowFxKind kind;

  /// Distance in cells (exit: to beyond the edge, bump: free cells ahead).
  final int cells;
  final int delayMs;
  final int token;
}

/// Runtime state of an arrow on the board.
class BoardArrow {
  BoardArrow(this.spec);

  final ArrowSpec spec;
  final fx = const ArrowFx(ArrowFxKind.idle).obs;

  /// True once the exit animation finished (tile no longer drawn).
  final gone = false.obs;

  int _token = 0;

  int get id => spec.id;

  void play(ArrowFxKind kind, {int cells = 0, int delayMs = 0}) {
    fx.value = ArrowFx(kind, cells: cells, delayMs: delayMs, token: ++_token);
  }
}

enum PathTone { none, aim, hint, blocked }

enum MsgTone { info, good, bad, warn }

class GameMessage {
  const GameMessage(this.text, this.tone);

  final String text;
  final MsgTone tone;
}

enum GameStatus { playing, won, lost }
