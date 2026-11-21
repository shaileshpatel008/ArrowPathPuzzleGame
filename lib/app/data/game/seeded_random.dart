/// Small deterministic PRNG (mulberry32).
///
/// `dart:math`'s [Random] is not guaranteed to produce the same sequence
/// across SDK versions. Levels and the daily puzzle must be identical for
/// every player on every app version, so we ship our own generator.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  /// Next 32-bit unsigned integer.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= (t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }

  /// Uniform double in [0, 1).
  double nextDouble() => nextUint32() / 4294967296.0;

  /// Uniform int in [0, max).
  int nextInt(int max) => (nextDouble() * max).floor();

  static int _imul(int a, int b) {
    final ah = (a >> 16) & 0xFFFF;
    final al = a & 0xFFFF;
    final bh = (b >> 16) & 0xFFFF;
    final bl = b & 0xFFFF;
    return ((al * bl) + (((ah * bl + al * bh) << 16) & 0xFFFFFFFF)) &
        0xFFFFFFFF;
  }

  /// Mixes an arbitrary integer into a well-distributed 32-bit seed.
  static int hash(int value) {
    var h = value & 0xFFFFFFFF;
    h = _imul(h ^ (h >> 16), 0x45D9F3B);
    h = _imul(h ^ (h >> 16), 0x45D9F3B);
    return (h ^ (h >> 16)) & 0xFFFFFFFF;
  }
}
