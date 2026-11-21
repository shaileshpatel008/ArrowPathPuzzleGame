import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';

/// External links, store review and app version.
class PlatformService extends GetxService {
  final version = ''.obs;

  Future<PlatformService> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version.value = '${info.version} (${info.buildNumber})';
    } catch (_) {}
    return this;
  }

  Future<bool> openUrl(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('openUrl: $e');
      return false;
    }
  }

  Future<void> openPrivacyPolicy() => openUrl(AppConfig.privacyPolicyUrl);
  Future<void> openTerms() => openUrl(AppConfig.termsUrl);

  Future<void> emailSupport() => openUrl(
    'mailto:${AppConfig.supportEmail}?subject=${Uri.encodeComponent('${AppConfig.appName} support')}',
  );

  /// Google Play in-app review sheet. Play decides whether it is shown; we
  /// never reward or gate anything behind a review (policy).
  Future<void> requestReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } catch (e) {
      debugPrint('review: $e');
    }
  }

  Future<void> openStoreListing() async {
    try {
      await InAppReview.instance.openStoreListing();
    } catch (_) {
      await openUrl(AppConfig.playStoreUrl);
    }
  }
}
