/// Keys used in local storage. Never rename a key after release, or players
/// lose their progress.
abstract final class StorageKeys {
  static const box = 'arrow_path';

  // settings
  static const skinId = 'settings.skin';
  static const aimByDefault = 'settings.aim';
  static const sound = 'settings.sound';
  static const music = 'settings.music';
  static const haptics = 'settings.haptics';
  static const colorBlind = 'settings.colorBlind';
  static const reduceMotion = 'settings.reduceMotion';

  // progress
  static const onboardingDone = 'progress.onboardingDone';
  static const highestCleared = 'progress.highestCleared';
  static const stars = 'progress.stars';
  static const perfectClears = 'progress.perfectClears';
  static const noHintClears = 'progress.noHintClears';
  static const arrowsCleared = 'progress.arrowsCleared';
  static const hintsUsed = 'progress.hintsUsed';
  static const arrowsByDay = 'progress.arrowsByDay';
  static const plusOfferShown = 'progress.plusOfferShown';
  static const reviewAsked = 'progress.reviewAsked';
  static const levelsSinceInterstitial = 'ads.levelsSinceInterstitial';

  // daily
  static const dailySolved = 'daily.solved';
  static const dailyStreak = 'daily.streak';
  static const dailyBestStreak = 'daily.bestStreak';
  static const dailyLastSolved = 'daily.lastSolved';
  static const dailyFreezes = 'daily.freezes';
  static const dailyFreezeWeek = 'daily.freezeWeek';

  // wallet & entitlements
  static const hints = 'wallet.hints';
  static const themePack = 'wallet.themePack';
  static const plusLifetime = 'wallet.plusLifetime';
  static const plusSubscription = 'wallet.plusSubscription';
  static const plusProductId = 'wallet.plusProductId';
  static const creditedPurchases = 'wallet.creditedPurchases';
  static const lastPlusHintGrant = 'wallet.lastPlusHintGrant';
}
