# Arrow Path Puzzle

Tap the arrows, find the right order and clear the board.
Flutter + GetX, AdMob (with UMP consent) and Google Play Billing.

- **Package:** `com.shaileshpatel008.arrowpathpuzzle`
- **Flutter:** 3.47 or newer (built and tested on 3.50.1) · **Dart:** 3.13+ · **minSdk:** 24 · **targetSdk:** Flutter default (latest)

---

## 1. Run it

```bash
flutter pub get
flutter run            # debug: always uses Google TEST ads
flutter test           # 13 unit tests (levels, streaks, stars)
```

The game works fully offline. The shop shows prices only when the app was
installed from Google Play (internal testing track) and the products exist
in Play Console (see section 4).

## 2. Folder structure (GetX pattern)

```
lib/
├─ main.dart                      # boot: orientation, edge-to-edge, services
└─ app/
   ├─ app.dart                    # GetMaterialApp, theme, translations
   ├─ bindings/initial_binding.dart   # all permanent services, in order
   ├─ config/                     # ⚙️ everything you edit before release
   │  ├─ app_config.dart          # name, URLs, gameplay tuning
   │  ├─ ad_config.dart           # AdMob unit IDs + frequency rules
   │  └─ iap_config.dart          # Play product IDs
   ├─ core/
   │  ├─ constants/storage_keys.dart
   │  ├─ theme/                   # 6 skins, AppPalette (ThemeExtension), AppTheme
   │  ├─ translations/            # GetX .tr strings (en_US)
   │  ├─ utils/day.dart           # calendar-day maths
   │  └─ widgets/                 # Pressable, AppButton, sheets, confetti, painters…
   ├─ data/
   │  ├─ game/                    # pure Dart engine (no Flutter): rules, generator, levels
   │  ├─ models/                  # GameArgs, LevelResult, StreakState
   │  └─ services/                # GetxServices: storage, settings, progress,
   │                              # wallet, audio, consent, ads, iap, platform, lifecycle
   ├─ modules/                    # one folder per screen: bindings/ controllers/ views/
   │  ├─ splash  onboarding  shell  home  levels  game  result
   │  └─ daily  themes  stats  settings  store  plus
   └─ routes/                     # app_routes.dart + app_pages.dart
assets/  audio (generated SFX + music loop) · branding (icon, splash) · fonts (OFL)
docs/    Play policy checklist + GitHub Pages site (privacy.html, terms.html)
store_listing/  512px icon, 1024x500 feature graphic, listing texts
```

## 3. AdMob setup

1. Create the app in AdMob, then 3 ad units: **Banner**, **Interstitial**, **Rewarded**.
2. Paste the unit IDs in `lib/app/config/ad_config.dart`.
3. Replace the **App ID** (currently Google's test ID) in
   `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`.
4. AdMob › **Privacy & messaging**: create a **GDPR** message (and a US
   states message). The app shows it automatically through UMP and adds a
   *Privacy & ad choices* row in Settings when required.
5. Add your phone as a test device (`AdConfig.testDeviceIds`) while testing
   release builds.

Debug builds always use Google's test units, and so do release builds until
you replace the `XXXX` placeholders, so you can't get an invalid-traffic strike by accident.

**Where ads appear (option B flow)**

| Player | Ads |
|---|---|
| Levels 1-5 | none at all |
| Level 6+ (free player) | interstitial after every 3rd **won** level (≥ 90 s apart, never after a loss, never mid-level) · optional rewarded ads (+1 hint / +1 heart) · banner on the Levels list only |
| Plus member | no ads |

With the defaults, the first interstitial appears when you leave the win
screen of **level 7** (levels 5, 6, 7 = 3 wins counted once ads switch on at
level 5). The banner shows on the Levels tab as soon as level 5 is cleared.
Level 15's win shows the one-time Plus offer instead of an ad.
Change `AppConfig.freeLevelsWithoutAds` to move the start. Run
`flutter run` and look for `[Ads]` lines in the
console to see consent, loading and the interstitial counter.

If the consent check fails (always the case with Google's *test* App ID,
or before you publish a consent message in AdMob), ads are still served
but as **non-personalised** ads.

## 4. Google Play Billing setup

Play Console › your app › **Monetize › Products**

| Type | Product ID | Gives |
|---|---|---|
| In-app (consumable) | `hints_5`, `hints_15`, `hints_40` | 5 / 15 / 40 hints |
| In-app (one-time) | `theme_pack` | Forest + Neon + future themes |
| In-app (one-time) | `plus_lifetime` | Plus forever |
| Subscription | `plus_monthly` (1 base plan, monthly, auto-renewing) | Plus |
| Subscription | `plus_yearly` (1 base plan, yearly, auto-renewing) | Plus |

Then:
1. Upload a signed **App Bundle** to the **Internal testing** track (billing
   only works for builds installed from Play).
2. Settings › **License testing**: add tester Gmail accounts (test purchases
   are free, and subscriptions renew every few minutes).
3. Install from the internal-testing link and try the Shop.

How purchases flow is documented in `lib/app/data/services/iap_service.dart`.
Purchases are acknowledged with `completePurchase` (Play refunds anything
that isn't acknowledged within 3 days), consumables are credited exactly once,
and owned items and subscriptions are re-read from Play on every launch.

**Before you scale:** replace `LocalPurchaseVerifier` with server-side
verification (Google Play Developer API). See `purchase_verifier.dart`.

## 5. Release build

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

Copy `android/key.properties.example` to `android/key.properties` (git-ignored) and fill it in:
```
storePassword=***
keyPassword=***
keyAlias=upload
storeFile=/Users/you/upload-keystore.jks
```

```bash
flutter build appbundle --release      # -> build/app/outputs/bundle/release/app-release.aab
```

Bump `version:` in `pubspec.yaml` (`1.0.1+2`) for every upload.

## 6. Before you publish
Work through **`docs/PLAY_POLICY_CHECKLIST.md`**. It covers the privacy policy URL,
Data safety answers, content rating, target audience, ads declaration and
subscription disclosure.

## 7. Customising
- **Name / links / tuning:** `config/app_config.dart`
- **Colours:** `core/theme/skins.dart` (each skin recolours the whole app)
- **Levels:** `data/game/level_catalog.dart` (chapters, board sizes and
  density). Levels are generated deterministically and are solvable by
  construction, and `test/level_generator_test.dart` checks all 200 of them.
- **Text / new languages:** `core/translations/` (add `xx_YY.dart` + register)
- **Icon / splash:** replace `assets/branding/*.png`, then run
  `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`

## 8. Note on Flutter 3.47+ Material deprecation
Flutter now ships Material as the separate `material_ui` package and marks
`package:flutter/material.dart` deprecated. GetX is still built on the SDK
Material library, so this app keeps using it (mixing both would break Theme
lookups). The deprecation info is silenced in `analysis_options.yaml`.
Switch the imports once GetX migrates.
