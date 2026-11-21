import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google User Messaging Platform (UMP) consent.
///
/// Required by Google Play / AdMob policy for users in the EEA, UK and
/// Switzerland (GDPR) and some US states. Configure the consent message in
/// AdMob > Privacy & messaging. Ads are only requested after
/// [canRequestAds] becomes true.
class ConsentService extends GetxService {
  final canRequestAds = false.obs;

  /// Whether Settings must show a "Privacy options" entry (GDPR requirement
  /// when a consent form was used).
  final privacyOptionsRequired = false.obs;

  Future<bool>? _gathering;

  /// Requests consent info and shows the form if needed. Safe to call many
  /// times; concurrent calls share the same future.
  Future<bool> gather() =>
      _gathering ??= _gather().whenComplete(() => _gathering = null);

  Future<bool> _gather() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) debugPrint('Consent form: ${error.message}');
          if (!done.isCompleted) done.complete();
        });
      },
      (FormError error) {
        debugPrint('Consent info: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
    await refresh();
    return canRequestAds.value;
  }

  Future<void> refresh() async {
    try {
      canRequestAds.value = await ConsentInformation.instance.canRequestAds();
      privacyOptionsRequired.value =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('Consent refresh: $e');
    }
  }

  /// Lets the player change their choice at any time (Settings screen).
  Future<void> showPrivacyOptions() async {
    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) debugPrint('Privacy options: ${error.message}');
      done.complete();
    });
    await done.future;
    await refresh();
  }
}
