import 'package:in_app_purchase/in_app_purchase.dart';

/// Decides whether a purchase reported by the store is genuine.
///
/// Swap [LocalPurchaseVerifier] for a server implementation before you
/// scale: send `purchase.verificationData.serverVerificationData` (the Play
/// purchase token) plus `purchase.productID` to your backend, verify it with
/// the Google Play Developer API (purchases.products / purchases.subscriptionsv2)
/// and return the result. That blocks forged purchases on rooted devices.
abstract interface class PurchaseVerifier {
  Future<bool> verify(PurchaseDetails purchase);
}

/// Trusts Google Play's on-device result. Fine to launch with.
class LocalPurchaseVerifier implements PurchaseVerifier {
  const LocalPurchaseVerifier();

  @override
  Future<bool> verify(PurchaseDetails purchase) async =>
      purchase.verificationData.serverVerificationData.isNotEmpty;
}
