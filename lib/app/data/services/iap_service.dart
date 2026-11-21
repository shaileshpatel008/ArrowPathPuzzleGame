import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../config/iap_config.dart';
import 'progress_service.dart';
import 'purchase_verifier.dart';
import 'wallet_service.dart';

/// UI-facing purchase events.
sealed class PurchaseEvent {
  const PurchaseEvent(this.productId);
  final String productId;
}

class PurchasePending extends PurchaseEvent {
  const PurchasePending(super.productId);
}

class PurchaseSucceeded extends PurchaseEvent {
  const PurchaseSucceeded(super.productId);
}

class PurchaseFailed extends PurchaseEvent {
  const PurchaseFailed(super.productId, this.message);
  final String message;
}

class PurchaseCancelled extends PurchaseEvent {
  const PurchaseCancelled(super.productId);
}

/// Google Play Billing / StoreKit via the official `in_app_purchase` plugin.
///
/// Flow:
///  1. Listen to the purchase stream BEFORE anything else, so purchases that
///     finished while the app was closed are still delivered.
///  2. Load product details (localised prices come from the store).
///  3. On purchased/restored: verify, grant, then `completePurchase`
///     (acknowledges on Play; un-acknowledged purchases are refunded after
///     3 days).
///  4. On every launch re-read owned items so expired / refunded
///     subscriptions are removed.
class IapService extends GetxService {
  IapService(this._wallet, this._progress, {PurchaseVerifier? verifier})
    : _verifier = verifier ?? const LocalPurchaseVerifier();

  final WalletService _wallet;
  final ProgressService _progress;
  final PurchaseVerifier _verifier;
  // Lazy: the billing connection is only opened when first used.
  late final InAppPurchase _iap = InAppPurchase.instance;

  final available = false.obs;
  final loading = true.obs;
  final products = <String, ProductDetails>{}.obs;

  /// Product currently being bought (drives button spinners).
  final busyProductId = RxnString();

  final _events = StreamController<PurchaseEvent>.broadcast();
  Stream<PurchaseEvent> get events => _events.stream;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<IapService> init() async {
    try {
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => debugPrint('[IAP] purchase stream error: $e'),
      );
      available.value = await _iap.isAvailable();
      debugPrint('[IAP] Google Play Billing available: ${available.value}');
      if (available.value) {
        await loadProducts();
        await refreshEntitlements();
      }
    } catch (e) {
      debugPrint('[IAP] init failed: $e');
      available.value = false;
    } finally {
      loading.value = false;
    }
    return this;
  }

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(IapConfig.all);
    if (response.error != null) {
      debugPrint('[IAP] product query error: ${response.error!.message}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        '[IAP] NOT FOUND in Play Console (check IDs / activation): '
        '${response.notFoundIDs}',
      );
    }
    final map = <String, ProductDetails>{};
    for (final p in response.productDetails) {
      // Android returns one entry per subscription offer. Prefer the plain
      // base plan (no offer id) and fall back to the first entry.
      final existing = map[p.id];
      if (existing == null || (_isBasePlan(p) && !_isBasePlan(existing))) {
        map[p.id] = p;
      }
    }
    products.assignAll(map);
    debugPrint(
      '[IAP] products loaded: '
      '${map.values.map((p) => '${p.id}=${p.price}').join(', ')}',
    );
  }

  bool _isBasePlan(ProductDetails p) {
    if (p is! GooglePlayProductDetails) return true;
    final idx = p.subscriptionIndex;
    final offers = p.productDetails.subscriptionOfferDetails;
    if (idx == null || offers == null) return true;
    return offers[idx].offerId == null;
  }

  /// Localised price, e.g. "₹99.00" or "$1.99". Null until loaded.
  String? priceOf(String productId) => products[productId]?.price;

  bool isOwned(String productId) => switch (productId) {
    IapConfig.themePack => _wallet.themePack.value,
    IapConfig.plusLifetime => _wallet.plusLifetime.value,
    IapConfig.plusMonthly || IapConfig.plusYearly =>
      _wallet.plusSubscription.value &&
          _wallet.plusProductId.value == productId,
    _ => false,
  };

  /// Starts the store purchase sheet. Results arrive on [events].
  Future<void> buy(String productId) async {
    if (busyProductId.value != null) return;
    final product = products[productId];
    if (!available.value || product == null) {
      _events.add(PurchaseFailed(productId, 'store_unavailable'));
      return;
    }
    if (isOwned(productId)) {
      _events.add(PurchaseSucceeded(productId));
      return;
    }
    busyProductId.value = productId;
    try {
      final param = PurchaseParam(productDetails: product);
      final started = IapConfig.isConsumable(productId)
          ? await _iap.buyConsumable(purchaseParam: param)
          : await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        busyProductId.value = null;
        _events.add(PurchaseCancelled(productId));
      }
    } catch (e) {
      busyProductId.value = null;
      _events.add(PurchaseFailed(productId, e.toString()));
    }
  }

  /// "Restore purchases": re-reads everything the Google account owns.
  Future<bool> restore() async {
    if (!available.value) return false;
    await refreshEntitlements();
    if (!kIsWeb && Platform.isIOS) await _iap.restorePurchases();
    return _wallet.isPlus.value || _wallet.themePack.value;
  }

  /// Rebuilds entitlements from what the store says is currently owned.
  Future<void> refreshEntitlements() async {
    if (kIsWeb || !Platform.isAndroid) {
      await _iap.restorePurchases();
      return;
    }
    final addition = _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      debugPrint('[IAP] owned items query error: ${response.error!.message}');
      return; // keep cached entitlements when offline
    }
    var theme = false;
    var lifetime = false;
    String? subscription;
    for (final p in response.pastPurchases) {
      if (p.status != PurchaseStatus.purchased &&
          p.status != PurchaseStatus.restored) {
        continue;
      }
      if (p.productID == IapConfig.themePack) theme = true;
      if (p.productID == IapConfig.plusLifetime) lifetime = true;
      if (IapConfig.subscriptions.contains(p.productID)) {
        subscription = p.productID;
      }
      if (IapConfig.isConsumable(p.productID)) {
        // A consumable left unconsumed (app died mid-purchase): deliver now.
        await _deliver(p, announce: false);
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    await _wallet.setThemePack(theme);
    await _wallet.setPlusLifetime(lifetime);
    await _wallet.setPlusSubscription(
      subscription != null,
      productId: subscription,
    );
    await _onEntitlementsChanged();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      debugPrint('[IAP] ${p.productID}: ${p.status.name}');
      switch (p.status) {
        case PurchaseStatus.pending:
          _events.add(PurchasePending(p.productID));
        case PurchaseStatus.canceled:
          busyProductId.value = null;
          _events.add(PurchaseCancelled(p.productID));
        case PurchaseStatus.error:
          busyProductId.value = null;
          final code = p.error?.code ?? '';
          _events.add(
            code.contains('canceled')
                ? PurchaseCancelled(p.productID)
                : PurchaseFailed(p.productID, p.error?.message ?? 'error'),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliver(p, announce: p.status == PurchaseStatus.purchased);
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (e) {
          debugPrint('[IAP] acknowledge failed: $e');
        }
      }
    }
  }

  Future<void> _deliver(PurchaseDetails p, {required bool announce}) async {
    final valid = await _verifier.verify(p);
    if (!valid) {
      busyProductId.value = null;
      _events.add(PurchaseFailed(p.productID, 'verification_failed'));
      return;
    }
    final id = p.productID;
    if (IapConfig.isConsumable(id)) {
      final key = p.purchaseID ?? p.verificationData.serverVerificationData;
      await _wallet.creditHintPack(id, key);
    } else if (id == IapConfig.themePack) {
      await _wallet.setThemePack(true);
    } else if (id == IapConfig.plusLifetime) {
      await _wallet.setPlusLifetime(true);
    } else if (IapConfig.subscriptions.contains(id)) {
      await _wallet.setPlusSubscription(true, productId: id);
    }
    await _onEntitlementsChanged();
    if (busyProductId.value == id) busyProductId.value = null;
    if (announce) _events.add(PurchaseSucceeded(id));
  }

  Future<void> _onEntitlementsChanged() async {
    await _wallet.grantDailyPlusHints();
    await _progress.grantWeeklyFreeze(isPlus: _wallet.isPlus.value);
  }

  @override
  void onClose() {
    _sub?.cancel();
    _events.close();
    super.onClose();
  }
}
