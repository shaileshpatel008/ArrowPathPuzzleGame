/// App-wide constants: identity, links and gameplay tuning.
///
/// Everything you are expected to change before publishing lives in the
/// `config/` folder: this file, [AdConfig] and [IapConfig].
abstract final class AppConfig {
  static const appName = 'Arrow Path Puzzle';
  static const shortName = 'Arrow Path';
  static const plusName = 'Arrow Path Plus';
  static const packageName = 'com.shaileshpatel008.arrowpathpuzzle';

  // TODO(before release): host the documents in /docs and put the URLs here.
  // Google Play requires a working privacy policy link inside the app and on
  // the store listing because the app uses ads and in-app purchases.
  static const privacyPolicyUrl = 'https://example.com/arrow-path/privacy';
  static const termsUrl = 'https://example.com/arrow-path/terms';
  static const supportEmail = 'support@example.com';

  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';

  /// Opens Google Play's subscription centre for this app.
  static String manageSubscriptionUrl(String? productId) => productId == null
      ? 'https://play.google.com/store/account/subscriptions'
      : 'https://play.google.com/store/account/subscriptions?sku=$productId&package=$packageName';

  // ----- Gameplay tuning -----------------------------------------------------

  /// Hints a brand-new player starts with.
  static const startingHints = 3;

  /// Hearts per level. Each crash costs one.
  static const heartsPerLevel = 3;

  /// Extra hints Plus members receive every day.
  static const plusDailyHints = 3;

  /// Total number of levels across all chapters.
  static const totalLevels = 200;

  /// Levels 1..[freeLevelsWithoutAds] never show ads or sales prompts.
  static const freeLevelsWithoutAds = 5;

  /// The one-time Plus offer appears after this level is cleared.
  static const plusOfferAfterLevel = 15;

  /// Ask for a Play review after these levels are cleared (once each).
  static const reviewPromptLevels = [10, 40];

  /// Daily challenge days needed in one month for the monthly badge.
  static const monthlyBadgeTarget = 20;
}
