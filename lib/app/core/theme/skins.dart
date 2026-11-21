import 'package:flutter/painting.dart';

import '../../data/game/direction.dart';

/// How a skin gets unlocked.
enum SkinUnlock { free, level50, streak14 }

/// A complete colour scheme for the app and the board.
class Skin {
  const Skin({
    required this.id,
    required this.nameKey,
    required this.noteKey,
    required this.isDark,
    required this.background,
    required this.surface,
    required this.cell,
    required this.ink,
    required this.muted,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.tileUp,
    required this.tileRight,
    required this.tileDown,
    required this.tileLeft,
    required this.glyph,
    this.unlock = SkinUnlock.free,
  });

  final String id;
  final String nameKey;
  final String noteKey;
  final bool isDark;

  final Color background;
  final Color surface;
  final Color cell;
  final Color ink;
  final Color muted;
  final Color line;
  final Color primary;
  final Color onPrimary;

  /// Primary colour safe for text on [surface] (4.5:1).
  final Color primaryText;

  final Color tileUp;
  final Color tileRight;
  final Color tileDown;
  final Color tileLeft;
  final Color glyph;
  final SkinUnlock unlock;

  Color tileFor(Direction d) => switch (d) {
    Direction.up => tileUp,
    Direction.right => tileRight,
    Direction.down => tileDown,
    Direction.left => tileLeft,
  };

  List<Color> get swatches => [tileUp, tileRight, tileDown, tileLeft];
}

abstract final class Skins {
  static const daylight = Skin(
    id: 'daylight',
    nameKey: 'skin_daylight',
    noteKey: 'skin_daylight_note',
    isDark: false,
    background: Color(0xFFF2F4F8),
    surface: Color(0xFFFFFFFF),
    cell: Color(0xFFF0F2F7),
    ink: Color(0xFF10131C),
    muted: Color(0xFF586072),
    line: Color(0xFFE3E7EF),
    primary: Color(0xFF2E4BFF),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF1F33C7),
    tileUp: Color(0xFF2E4BFF),
    tileRight: Color(0xFFE8590C),
    tileDown: Color(0xFF0E9F8E),
    tileLeft: Color(0xFF10131C),
    glyph: Color(0xFFFFFFFF),
  );

  static const midnight = Skin(
    id: 'midnight',
    nameKey: 'skin_midnight',
    noteKey: 'skin_midnight_note',
    isDark: true,
    background: Color(0xFF0E1220),
    surface: Color(0xFF171C2E),
    cell: Color(0xFF1F2538),
    ink: Color(0xFFE9ECF5),
    muted: Color(0xFFA3AABD),
    line: Color(0xFF2A3147),
    primary: Color(0xFF8B9AFF),
    onPrimary: Color(0xFF0E1220),
    primaryText: Color(0xFFA9B4FF),
    tileUp: Color(0xFF8B9AFF),
    tileRight: Color(0xFFFF9D4D),
    tileDown: Color(0xFF3DD6C3),
    tileLeft: Color(0xFFE6E8F0),
    glyph: Color(0xFF0E1220),
  );

  static const sorbet = Skin(
    id: 'sorbet',
    nameKey: 'skin_sorbet',
    noteKey: 'skin_sorbet_note',
    isDark: false,
    background: Color(0xFFFFEFEA),
    surface: Color(0xFFFFFFFF),
    cell: Color(0xFFFBEDE8),
    ink: Color(0xFF2A1A22),
    muted: Color(0xFF6E5560),
    line: Color(0xFFF2DCD5),
    primary: Color(0xFFD6336C),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFFB0244F),
    tileUp: Color(0xFFD6336C),
    tileRight: Color(0xFFD97706),
    tileDown: Color(0xFF7C3AED),
    tileLeft: Color(0xFF0F766E),
    glyph: Color(0xFFFFFFFF),
  );

  static const ink = Skin(
    id: 'ink',
    nameKey: 'skin_ink',
    noteKey: 'skin_ink_note',
    isDark: false,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    cell: Color(0xFFEDEDED),
    ink: Color(0xFF111111),
    muted: Color(0xFF555555),
    line: Color(0xFFD9D9D9),
    primary: Color(0xFF111111),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF111111),
    tileUp: Color(0xFF111111),
    tileRight: Color(0xFF111111),
    tileDown: Color(0xFF111111),
    tileLeft: Color(0xFF111111),
    glyph: Color(0xFFFFFFFF),
  );

  static const forest = Skin(
    id: 'forest',
    nameKey: 'skin_forest',
    noteKey: 'skin_forest_note',
    isDark: false,
    background: Color(0xFFEAF1E8),
    surface: Color(0xFFFFFFFF),
    cell: Color(0xFFE3ECE0),
    ink: Color(0xFF1E2B20),
    muted: Color(0xFF52645A),
    line: Color(0xFFD5E0D2),
    primary: Color(0xFF2F6B3A),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF2F6B3A),
    tileUp: Color(0xFF2F6B3A),
    tileRight: Color(0xFFB45309),
    tileDown: Color(0xFF3B6E8F),
    tileLeft: Color(0xFF22301F),
    glyph: Color(0xFFFFFFFF),
    unlock: SkinUnlock.level50,
  );

  static const neon = Skin(
    id: 'neon',
    nameKey: 'skin_neon',
    noteKey: 'skin_neon_note',
    isDark: true,
    background: Color(0xFF07070B),
    surface: Color(0xFF12121A),
    cell: Color(0xFF1C1C28),
    ink: Color(0xFFF1F1F7),
    muted: Color(0xFFA6A6B8),
    line: Color(0xFF26263A),
    primary: Color(0xFF00D8F5),
    onPrimary: Color(0xFF07070B),
    primaryText: Color(0xFF00D8F5),
    tileUp: Color(0xFF00D8F5),
    tileRight: Color(0xFFFF4FD8),
    tileDown: Color(0xFFB6FF3D),
    tileLeft: Color(0xFFFFFFFF),
    glyph: Color(0xFF07070B),
    unlock: SkinUnlock.streak14,
  );

  static const all = [daylight, midnight, sorbet, ink, forest, neon];

  static Skin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => daylight);
}
