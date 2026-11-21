# Google Play policy checklist: Arrow Path Puzzle

✅ = already handled in the code · ☐ = you do it in a console / on the web

## Already in the app
- ✅ **Target API**: uses Flutter's current `targetSdk` (latest required level).
- ✅ **Ads consent (GDPR / US states)**: Google UMP via `ConsentService`; no ad
  request before consent allows it; "Privacy & ad choices" in Settings when required.
- ✅ **Ad content rating** capped at **PG** (`MaxAdContentRating.pg`).
- ✅ **Ad placement**: no ads in levels 1-5, no interstitials mid-game, after a
  loss or on app open/exit, frequency capped; rewarded ads are optional and
  state the reward up front; banner never overlaps game controls.
- ✅ **Test ads** in every debug build (no invalid-traffic risk).
- ✅ **Billing**: Google Play Billing only (no other payment methods for digital
  goods); localized prices from Play; purchases acknowledged; pending
  purchases handled; Restore purchases in Shop, Plus and Settings.
- ✅ **Subscription disclosure** on the Plus screen: price, billing period,
  auto-renewal, how to cancel; link to Play's subscription centre ("Manage
  subscription"); terms and privacy links; the paywall can always be closed.
- ✅ **No incentivised reviews**: Play In-App Review API at milestones, no reward.
- ✅ **Privacy policy + terms links** inside the app (Settings, Plus).
- ✅ **Reset progress** (local data deletion) in Settings. There are no user
  accounts, so the *account deletion* requirement does not apply.
- ✅ **Accessibility**: semantic labels on every control, colour-blind mode,
  reduce-motion, high-contrast "Ink" theme, scalable text.
- ✅ **Auto Backup** rules so progress survives a phone change.
- ✅ **No sensitive permissions**: only INTERNET (+ AD_ID / BILLING merged by SDKs).

## You do in consoles
- ☐ Host `docs/PRIVACY_POLICY.md` and `docs/TERMS.md` (GitHub Pages, Google
  Sites…), fill in the placeholders, and put the URLs in `config/app_config.dart`
  **and** in Play Console › App content › Privacy policy.
- ☐ Replace the AdMob test App ID and unit IDs (README §3).
- ☐ AdMob › Privacy & messaging: publish the GDPR + US states messages.
- ☐ Create the 7 products (README §4).
- ☐ **App content › Ads**: "Yes, my app contains ads".
- ☐ **App content › Target audience**: **13+** (or 18+). Do NOT pick under-13
  ages unless you switch to Families-certified ad settings.
- ☐ **Content rating** questionnaire: puzzle game, no violence, contains ads,
  in-app purchases → usually *Everyone / PEGI 3*.
- ☐ **Data safety** form (answers below).
- ☐ **Store listing**: use `store_listing/` assets and texts, plus 2-8 phone
  screenshots (run the app and capture Home, Game, Levels, Daily, Themes).
- ☐ **App access**: "All functionality is available without special access".
- ☐ Financial features: none. Government app: no. Health: no. News: no.

## Data safety answers (with AdMob + Play Billing, no own backend)
| Question | Answer |
|---|---|
| Does your app collect or share user data? | **Yes** (by the AdMob SDK) |
| Device or other IDs | Collected & shared: **Advertising** + **Analytics** (AdMob), ephemeral: no, required: no (user can reset/limit) |
| App activity: app interactions | Collected by AdMob for ads/analytics |
| Diagnostics: crash logs, performance | Collected by AdMob |
| Approximate location | Collected by AdMob (derived from IP) for ads |
| Purchase history | Handled by Google Play (you can declare "Purchase history: collected, for app functionality") |
| Is data encrypted in transit? | **Yes** |
| Can users request deletion? | Progress is local only (Reset progress); ad data via Google's controls |
| Game progress | Stored **on device only** (not collected) |

Re-check Google's current AdMob data-disclosure guidance before you submit.
