import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/constants/storage_keys.dart';

/// Thin typed wrapper around [GetStorage] so the rest of the app never deals
/// with raw dynamic values.
///
/// If the device storage cannot be opened (very rare: full disk, broken
/// file system), the app falls back to memory so it still starts instead of
/// closing. Progress is then kept for the session only.
class StorageService extends GetxService {
  GetStorage? _box;
  final _memory = <String, dynamic>{};

  /// False when running on the in-memory fallback.
  bool get persistent => _box != null;

  Future<StorageService> init() async {
    try {
      await GetStorage.init(StorageKeys.box)
          .timeout(const Duration(seconds: 6));
      _box = GetStorage(StorageKeys.box);
    } catch (e, s) {
      debugPrint('StorageService: falling back to memory. $e\n$s');
      _box = null;
    }
    return this;
  }

  T? _read<T>(String key) {
    try {
      final box = _box;
      final v = box == null ? _memory[key] : box.read<dynamic>(key);
      return v is T ? v : null;
    } catch (e) {
      debugPrint('StorageService.read($key): $e');
      return null;
    }
  }

  bool readBool(String key, {bool fallback = false}) =>
      _read<bool>(key) ?? fallback;

  int readInt(String key, {int fallback = 0}) {
    final v = _read<num>(key);
    return v?.toInt() ?? fallback;
  }

  String? readString(String key) => _read<String>(key);

  List<String> readStringList(String key) {
    final v = _read<List<dynamic>>(key);
    return v == null ? <String>[] : v.map((e) => e.toString()).toList();
  }

  Map<String, int> readIntMap(String key) {
    final v = _read<Map<dynamic, dynamic>>(key);
    if (v == null) return <String, int>{};
    return v.map((k, val) => MapEntry(k.toString(), (val as num).toInt()));
  }

  Future<void> write(String key, Object? value) async {
    final box = _box;
    if (box == null) {
      _memory[key] = value;
      return;
    }
    try {
      await box.write(key, value);
    } catch (e) {
      debugPrint('StorageService.write($key): $e');
    }
  }

  Future<void> remove(String key) async {
    final box = _box;
    if (box == null) {
      _memory.remove(key);
      return;
    }
    await box.remove(key);
  }

  /// Wipes everything except purchase records (those belong to the player's
  /// Google account and must survive a progress reset).
  Future<void> resetProgress() async {
    const keep = {
      StorageKeys.themePack,
      StorageKeys.plusLifetime,
      StorageKeys.plusSubscription,
      StorageKeys.plusProductId,
      StorageKeys.creditedPurchases,
      StorageKeys.hints,
      StorageKeys.onboardingDone,
    };
    final box = _box;
    final keys = box == null
        ? _memory.keys.toList()
        : box.getKeys<Iterable<dynamic>>().map((k) => k.toString()).toList();
    for (final k in keys) {
      if (!keep.contains(k)) await remove(k);
    }
  }
}
