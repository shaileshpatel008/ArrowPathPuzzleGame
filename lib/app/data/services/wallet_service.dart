import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../../config/iap_config.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/day.dart';
import 'storage_service.dart';

/// Hints and purchased entitlements.
///
/// Entitlements are cached locally so the game works offline, and refreshed
/// from Google Play by [IapService] on every launch.
class WalletService extends GetxService {
  WalletService(this._storage);

  final StorageService _storage;

  final hints = AppConfig.startingHints.obs;
  final themePack = false.obs;
  final plusLifetime = false.obs;
  final plusSubscription = false.obs;

  /// Product id of the active subscription (for "Manage subscription").
  final plusProductId = RxnString();

  /// True for lifetime or subscription members.
  final isPlus = false.obs;

  final _credited = <String>{};

  WalletService init() {
    hints.value = _storage.readInt(
      StorageKeys.hints,
      fallback: AppConfig.startingHints,
    );
    themePack.value = _storage.readBool(StorageKeys.themePack);
    plusLifetime.value = _storage.readBool(StorageKeys.plusLifetime);
    plusSubscription.value = _storage.readBool(StorageKeys.plusSubscription);
    plusProductId.value = _storage.readString(StorageKeys.plusProductId);
    _credited.addAll(_storage.readStringList(StorageKeys.creditedPurchases));
    _syncPlus();
    everAll([plusLifetime, plusSubscription], (_) => _syncPlus());
    ever<int>(hints, (v) => _storage.write(StorageKeys.hints, v));
    return this;
  }

  void _syncPlus() =>
      isPlus.value = plusLifetime.value || plusSubscription.value;

  bool get ownsAllThemes => themePack.value || isPlus.value;

  void addHints(int count) => hints.value += count;

  /// Spends one hint. Returns false when the balance is empty.
  bool spendHint() {
    if (hints.value <= 0) return false;
    hints.value--;
    return true;
  }

  /// Credits a consumable purchase exactly once, even if Google Play
  /// delivers the same purchase twice (app restart mid-purchase etc.).
  Future<bool> creditHintPack(String productId, String purchaseId) async {
    final amount = IapConfig.hintPacks[productId];
    if (amount == null || _credited.contains(purchaseId)) return false;
    _credited.add(purchaseId);
    addHints(amount);
    await _storage.write(StorageKeys.creditedPurchases, _credited.toList());
    return true;
  }

  Future<void> setThemePack(bool owned) async {
    themePack.value = owned;
    await _storage.write(StorageKeys.themePack, owned);
  }

  Future<void> setPlusLifetime(bool owned) async {
    plusLifetime.value = owned;
    await _storage.write(StorageKeys.plusLifetime, owned);
  }

  Future<void> setPlusSubscription(bool active, {String? productId}) async {
    plusSubscription.value = active;
    plusProductId.value = active ? productId : null;
    await _storage.write(StorageKeys.plusSubscription, active);
    await _storage.write(StorageKeys.plusProductId, active ? productId : null);
  }

  /// Plus perk: daily hints, granted at most once per calendar day.
  /// Returns how many hints were granted.
  Future<int> grantDailyPlusHints() async {
    if (!isPlus.value) return 0;
    final today = Day.todayKey();
    if (_storage.readString(StorageKeys.lastPlusHintGrant) == today) return 0;
    addHints(AppConfig.plusDailyHints);
    await _storage.write(StorageKeys.lastPlusHintGrant, today);
    return AppConfig.plusDailyHints;
  }
}
