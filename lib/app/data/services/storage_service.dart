import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/constants/storage_keys.dart';

/// Thin typed wrapper around [GetStorage] so the rest of the app never deals
/// with raw dynamic values.
class StorageService extends GetxService {
  late final GetStorage _box;

  Future<StorageService> init() async {
    await GetStorage.init(StorageKeys.box);
    _box = GetStorage(StorageKeys.box);
    return this;
  }

  bool readBool(String key, {bool fallback = false}) =>
      _box.read<bool>(key) ?? fallback;

  int readInt(String key, {int fallback = 0}) {
    final v = _box.read<dynamic>(key);
    return v is int ? v : (v is num ? v.toInt() : fallback);
  }

  String? readString(String key) => _box.read<String>(key);

  List<String> readStringList(String key) {
    final v = _box.read<dynamic>(key);
    return v is List ? v.map((e) => e.toString()).toList() : <String>[];
  }

  Map<String, int> readIntMap(String key) {
    final v = _box.read<dynamic>(key);
    if (v is! Map) return <String, int>{};
    return v.map((k, val) => MapEntry(k.toString(), (val as num).toInt()));
  }

  Future<void> write(String key, Object? value) => _box.write(key, value);

  Future<void> remove(String key) => _box.remove(key);

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
    final keys = _box.getKeys<Iterable<dynamic>>().map((k) => k.toString());
    for (final k in keys.toList()) {
      if (!keep.contains(k)) await _box.remove(k);
    }
  }
}
