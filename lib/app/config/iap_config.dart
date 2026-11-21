/// In-app product catalogue.
///
/// Create products with EXACTLY these IDs in Play Console:
///   Monetize > Products > In-app products: hints_5, hints_15, hints_40,
///                                          theme_pack, plus_lifetime
///   Monetize > Products > Subscriptions:   plus_monthly, plus_yearly
///                                          (one base plan each)
abstract final class IapConfig {
  static const hints5 = 'hints_5';
  static const hints15 = 'hints_15';
  static const hints40 = 'hints_40';
  static const themePack = 'theme_pack';
  static const plusLifetime = 'plus_lifetime';
  static const plusMonthly = 'plus_monthly';
  static const plusYearly = 'plus_yearly';

  /// Consumables and how many hints each one grants.
  static const hintPacks = <String, int>{hints5: 5, hints15: 15, hints40: 40};

  static const nonConsumables = <String>{themePack, plusLifetime};
  static const subscriptions = <String>{plusMonthly, plusYearly};

  static Set<String> get all => {
    ...hintPacks.keys,
    ...nonConsumables,
    ...subscriptions,
  };

  static bool isConsumable(String id) => hintPacks.containsKey(id);
  static bool grantsPlus(String id) =>
      id == plusLifetime || subscriptions.contains(id);
}
