# Launch checklist: local store Local Pro and ads

**Branch:** `feature/local-store-pro-and-ads`, from `b2083fd` (`feat: add verified account recovery for Local Pro`). Not committed, not pushed, not deployed.

Related: `docs/setup/local_pro_billing.md`, `docs/setup/ads.md`, `docs/setup/privacy_and_data.md`.

## What ships in the launch build

| Area | Launch build |
| --- | --- |
| Records, photos, OCR, reminders, settings | On the device only |
| Moving data | Encrypted `.rgry` export/import |
| Free limits | 10 documents, 5 subscriptions; over-limit data stays usable |
| Purchases | **Off** (`PURCHASES_ENABLED=false`). Buy disabled with an explanation; Restore hidden |
| Ads | **Off** (`ADS_ENABLED=false`). No SDK start, no consent, no request, no reserved space |
| Server, account, email, recovery code, grants | Removed |

Launch build commands:

```sh
flutter build appbundle --release
flutter build ipa --release --dart-define=ADMOB_IOS_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

**iOS release blocker:** the iOS launch build needs a real iOS AdMob App ID, even with ads off, because the linked Google Mobile Ads SDK crashes at launch without `GADApplicationIdentifier` (Google-documented; see `docs/setup/ads.md`). Without `ADMOB_IOS_APP_ID`, `flutter build ipa --release` / `flutter build ios --release` fails on purpose with `RELEASE BLOCKER`. No such App ID exists yet. The ads-off iOS release build has not been launched anywhere.

## Before enabling purchases

1. Play Console: `local_pro` one-time in-app product, active, priced; app on a testing track; license testers added.
2. App Store Connect: real bundle id chosen (the project still uses `com.example.theRegistry`), Non-Consumable `local_pro`, Paid Apps agreement active, Sandbox Apple Accounts.
3. Build with `--dart-define=PURCHASES_ENABLED=true` and run the sandbox checklist below on real devices for each platform.

### Sandbox checklist (run separately on Android and iOS)

- [ ] Local Pro screen shows the store's localized price (never a hard-coded one).
- [ ] Buy → cancel → stays Free, no error loop.
- [ ] Buy with a slow or pending payment method → "waiting for payment", stays Free; complete payment → Local Pro turns on.
- [ ] Buy → Local Pro on; limits lifted; ads (if an ads build) disappear without restart.
- [ ] Android: Play Console order shows the purchase **acknowledged** within minutes (not refunded after 3 days). Never consumed.
- [ ] Force-quit and relaunch → still Local Pro.
- [ ] Airplane mode, relaunch → Local Pro kept ("not confirmed right now").
- [ ] Uninstall, reinstall, same store account → launch restores Local Pro (Android on launch; iOS at latest after Restore purchases).
- [ ] Restore purchases twice in a row → no duplicate prompts or errors.
- [ ] Different store account → Restore says no purchase found; stays Free.
- [ ] Restore a `.rgry` backup on a fresh install → records restored, Local Pro **not** granted.
- [ ] Refund (Play Console refund with entitlement removal / App Store sandbox refund or StoreKit test revocation) → on next launch or foreground with network, Local Pro turns off with the refund message; records above Free limits remain viewable/editable/exportable; creating a new record is blocked until below the limit.
- [ ] Android purchase does not unlock iOS and the reverse.

## Before enabling ads

1. AdMob Android and iOS apps and adaptive banner units created; `app-ads.txt` published.
2. UMP messages configured (GDPR; US states if applicable).
3. Store privacy forms and Play Advertising ID declaration updated for the ads build.
4. Build per `docs/setup/ads.md` (live mode with the four real IDs); release builds refuse test/sample/invalid IDs.
5. On real devices: EEA consent flow (use UMP debug geography in a debug build), privacy options entry in Profile, banner only for Free, never for Local Pro, no banner while a returning Pro user is being checked.

## Evidence from this task

Everything below ran on this branch on 28 September 2026. Devices were an **isolated** Android emulator (`Registry_Launch_QA`, created for this task, `emulator-5556`) and an **isolated** iOS simulator ("Registry Launch QA", iPhone 17, iOS 27.0, created for this task). The existing Pixel 8 emulator with production test data (`emulator-5554`) and the booted iPhone 18 Pro simulator were not installed to, cleared, or uninstalled.

| Check | Result |
| --- | --- |
| `dart format`, `flutter analyze` | Clean |
| Unit/widget tests for Local Pro, limits, ads, consent (scripted store and ads boundaries) | Pass |
| Full `flutter test --concurrency=1` | 339 passed, 0 failed |
| Android debug APK, ads off | Built; merged manifest has no `MobileAdsInitProvider`, no AdMob App ID, no `AD_ID` permission; launches on isolated emulator |
| Android debug APK, ads test mode | Built; merged manifest has Google's sample Android App ID |
| Android release with `ADS_MODE=test` / banner unit ID as App ID / sample App ID in live | Build refused, each with its own message |
| `configure_admob.sh` off/test/live, Debug/Profile/Release, missing/sample/unit-ID/well-formed App ID | Verified against a scratch plist; ads-off Release without an App ID fails with `RELEASE BLOCKER` |
| Device QA `integration_test/launch_ads_qa_test.dart` (test ads), Android and iOS | Pass, rerun 29 September after the changes below. Screens in `screenshots/launch_local_pro_ads/` |

### Release audit of the ads-off launch build (29 September 2026)

`GADDelayInitialization`, used earlier to stop the iOS ads-off launch crash, is not in any Google doc or release note, so it was removed. `android/app/proguard-rules.pro` and the `work-runtime` dependency were added (see `docs/setup/ads.md`).

| Check | Result |
| --- | --- |
| `flutter clean`, then `flutter build ios --release --no-codesign` (ads off, no App ID) | **Fails on purpose:** `RELEASE BLOCKER` from the Configure AdMob phase. Blocker, not a pass. |
| `flutter build ios --simulator --release` | Not possible: "Release mode is not supported for simulators" |
| iOS Debug ads-off simulator app with its App ID removed (the state a Release build would ship in) | Crashes at launch: `GADInvalidInitializationException`. Confirms the blocker. |
| iOS Debug ads-off simulator app (sample App ID, Debug only) | Cold launch, force-quit (`simctl terminate`), relaunch: runs; the only socket is the loopback debug VM service |
| `flutter build apk --release` (ads off), before the fixes | Failed in R8 (ML Kit non-Latin recognizers); after the keep rules it built, then **crashed at startup** (`WorkDatabase`, via `play-services-ads`) |
| `flutter build apk --release` (ads off), after the fixes | Built; merged manifest has no `MobileAdsInitProvider`, no App ID, no `AD_ID` / `ACCESS_ADSERVICES_AD_ID` |
| Android ads-off release APK on the isolated emulator | Cold launch, `am force-stop`, relaunch (twice, including after an emulator reboot): runs, no crash, no ads/UMP log lines, no sockets owned by the app |
| Device QA `integration_test/launch_ads_off_qa_test.dart`, Android and iOS | Pass: real `GoogleMobileAdsPlatform` handed in, 0 ad/consent calls, Home slot height 0, no Profile ad privacy section |

Screenshots (`screenshots/launch_local_pro_ads/`):

- `*_qa_free_local_pro_purchases_off.png` — launch-default Local Pro screen.
- `*_qa_pro_local_pro_active_fake_store.png`, `*_qa_pro_home_no_banner.png` — Local Pro from a **scripted store**, ads build in test mode, zero ad SDK calls.
- `*_qa_free_home_test_banner.png` — Free, real Google **test** banner (sample unit ID) at the end of Home, above the dock.
- `android_qa_ads_off_launch.png` — Android ads-off debug build launching.
- `ios_sim_ads_off_launch.png` — iOS ads-off debug build with the since-removed `GADDelayInitialization` workaround. Superseded; not release evidence.
- `android_release_ads_off_cold.png`, `android_release_ads_off_relaunch.png` — Android ads-off **release** APK, cold launch and relaunch.
- `ios_sim_ads_off_debug_cold.png`, `ios_sim_ads_off_debug_relaunch.png` — iOS ads-off **Debug** simulator app (Debug-only sample App ID), cold launch and relaunch.

## Not done (blocked)

| Item | Why |
| --- | --- |
| Real Google Play purchase, acknowledgement, reinstall restore, refund | No `local_pro` product or testing track exists |
| Real App Store / StoreKit sandbox purchase, restore, refund | No App Store Connect product; bundle id still a placeholder |
| Live ads | No AdMob account, App IDs, or ad unit IDs |
| UMP consent form in the EEA | Needs AdMob privacy messages and a real device with debug geography |
| **iOS ads-off release build** | **Release blocker:** needs a real iOS AdMob App ID while `google_mobile_ads` is linked. Then launch/force-quit/relaunch on a real iPhone |
| iOS physical device QA | No device used in this task |
| Android release on a physical device and in Play pre-launch report | Only the isolated emulator was used |

None of these are marked as passed.
