# Ads

**Shipping state: ads are off.** `ADS_ENABLED` defaults to `false`. The launch build shows no ad.

With ads off:

- Dart never calls the Mobile Ads SDK or the User Messaging Platform (UMP): no `MobileAds.initialize`, no consent request, no consent form, no ad request (`AdsController`, `test/ads_test.dart`).
- The Home banner slot takes no space. There is no blank reserved area.
- Profile shows no ad privacy options.
- Android: the build merges `android/app/src/adsOff/AndroidManifest.xml`, which removes the SDK's `MobileAdsInitProvider` and the `AD_ID` / `ACCESS_ADSERVICES_AD_ID` permissions. No AdMob App ID is written. The ads SDK is still linked, because the plugin is a dependency, but it does not start. The SDK's other manifest entries (`AdActivity`, `AdService`, the `ACCESS_ADSERVICES_ATTRIBUTION` / `ACCESS_ADSERVICES_TOPICS` permissions) stay in the merged manifest.
- iOS: see the release blocker below.

The `google_mobile_ads` plugin is linked into every build. Store privacy forms must still reflect what the shipped build does (see `docs/setup/privacy_and_data.md`).

### iOS release blocker: a real iOS AdMob App ID is required, even with ads off

Google documents `GADApplicationIdentifier` in `Info.plist` as required whenever the Google Mobile Ads SDK is in the app, and that leaving it out crashes the app at launch with `GADInvalidInitializationException`:

- AdMob iOS quick start, "Update your Info.plist": https://developers.google.com/admob/ios/quick-start
- Flutter plugin quick start, iOS platform setup: https://developers.google.com/admob/flutter/quick-start
- Ad Manager iOS guide (quotes the exact crash message): https://developers.google.com/ad-manager/mobile-ads-sdk/ios/adx-direct
- iOS SDK release notes, 7.42.0 (App ID must be in the plist): https://developers.google.com/admob/ios/rel-notes

This was reproduced on the isolated iOS 27 simulator with `google_mobile_ads` 9.1.0 (GMA SDK 13.x): an ads-off app whose plist has no App ID aborts at launch, although Dart never starts the SDK. `GADDelayInitialization`, an earlier workaround, appears in none of Google's docs or release notes, so it is no longer used. `GADIsAdManagerApp` does not help either.

The "Configure AdMob" build phase (`ios/scripts/configure_admob.sh`) therefore does this when `ADS_ENABLED` is not `true`:

| Build | `Info.plist` |
| --- | --- |
| Any configuration with `ADMOB_IOS_APP_ID` | That App ID (format checked; Google's sample refused in Release). The SDK is still never started. |
| Debug / Profile without it | Google's sample iOS App ID, so the app can run locally. Never shipped. |
| Release without it | **Build fails** with `RELEASE BLOCKER`. No crashing binary is produced. |

**To unblock the iOS launch build:** create the iOS app in AdMob (it can stay without ad units while ads are off), then build with

```sh
flutter build ipa --release --dart-define=ADMOB_IOS_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

and run the launch, force-quit, relaunch check on a real iPhone (Flutter release builds do not run on the simulator).

The other supported route is to not link the SDK into the launch build: remove `google_mobile_ads` from `pubspec.yaml` and add it back only for ads builds. That changes how test and live ads builds are made, so it has not been done.

### Android release: WorkManager dependency

`play-services-ads` 25.4.0 (through `google_mobile_ads` 9.1.0) pulls in `androidx.work:work-runtime` 2.7.0. With AGP 9 and R8, a release build of that version crashes at startup (`Failed to create an instance of androidx.work.impl.WorkDatabase`), with ads on or off. `android/app/build.gradle.kts` therefore depends on `androidx.work:work-runtime:2.11.2`, the resolution given by the plugin maintainers in https://github.com/googleads/googleads-mobile-flutter/issues/1444. Remove it once the GMA SDK ships a fixed WorkManager, and recheck an Android release launch after every `google_mobile_ads` upgrade.

## What ads-on means (future build)

- Free users only. Local Pro users never get a consent request, an SDK initialization, or an ad request. While the store is still answering for a returning Local Pro user, no ad is requested.
- One inline adaptive banner at the end of the Home list (`RegistryBannerSlot`). It scrolls with the list and sits above the dock clearance, so it never covers the dock, the add button, forms, the keyboard, attachments, OCR review, or detail text. It is not shown on any form or detail screen.
- No interstitial, app-open, rewarded, or native ads.
- A banner that fails to load leaves no space and is retried at most once a minute. Banners are disposed when they leave the screen or the user gets Local Pro.
- Consent: on first eligible launch the app calls UMP `requestConsentInfoUpdate`, then `loadAndShowConsentFormIfRequired`. The Mobile Ads SDK is initialized and ads are requested only when `canRequestAds()` is true. When UMP reports privacy options as required, Profile shows "Ad privacy" with a button that opens `showPrivacyOptionsForm`.
- Layout follows the current locale and RTL (Arabic), since the banner lives inside the same list.

## Build configuration

All values are `--dart-define`s. They are compile-time constants, so a change affects only builds made with it.

| Define | Used by | Value |
| --- | --- | --- |
| `ADS_ENABLED` | Dart, Gradle, Xcode script | `true` to turn ads on. Anything else is off. |
| `ADS_MODE` | Dart, Gradle, Xcode script | `test` or `live`. |
| `ADMOB_ANDROID_APP_ID` | Gradle → `AndroidManifest` `com.google.android.gms.ads.APPLICATION_ID` | Android **App ID**, `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY` |
| `ADMOB_IOS_APP_ID` | Xcode script → `Info.plist` `GADApplicationIdentifier` | iOS **App ID**, `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY` |
| `ADMOB_ANDROID_BANNER_UNIT_ID` | Dart | Android banner **ad unit ID**, `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ` |
| `ADMOB_IOS_BANNER_UNIT_ID` | Dart | iOS banner **ad unit ID**, `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ` |

An App ID contains `~` and identifies the app in AdMob. An ad unit ID contains `/` and identifies one placement. Android and iOS each have their own App ID and their own banner unit ID. They are not interchangeable.

### Test mode (debug/profile only)

```sh
flutter run --dart-define=ADS_ENABLED=true --dart-define=ADS_MODE=test
```

Test mode uses Google's published sample IDs only:

- Android App ID `ca-app-pub-3940256099942544~3347511713`, adaptive banner `ca-app-pub-3940256099942544/9214589741`
- iOS App ID `ca-app-pub-3940256099942544~1458002511`, adaptive banner `ca-app-pub-3940256099942544/2435281174`

A release build refuses test mode: Gradle fails in `validateAdmobReleaseConfig`, the Xcode script fails for any `Release*` configuration, and Dart turns ads off if it ever sees test mode in release mode.

### Live mode

```sh
flutter build appbundle --release \
  --dart-define=ADS_ENABLED=true --dart-define=ADS_MODE=live \
  --dart-define=ADMOB_ANDROID_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY \
  --dart-define=ADMOB_ANDROID_BANNER_UNIT_ID=ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ

flutter build ipa --release \
  --dart-define=ADS_ENABLED=true --dart-define=ADS_MODE=live \
  --dart-define=ADMOB_IOS_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY \
  --dart-define=ADMOB_IOS_BANNER_UNIT_ID=ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
```

The build fails when the App ID is missing, is not in App ID form (for example a banner unit ID was passed), or is Google's sample ID. In Dart, a missing, malformed, or sample banner unit ID turns ads off for that build (`AdsConfig.resolve`), and the reason is printed in debug logs.

No real AdMob App ID or ad unit ID exists in this repository. They must be created in AdMob.

## Needed before a live ads build

1. AdMob account with two apps (Android `com.residay.app`, iOS bundle id), each with an adaptive banner ad unit.
2. `app-ads.txt` on the developer website listed in both stores.
3. UMP in AdMob → Privacy & messaging: a GDPR message (EEA, UK, Switzerland) and, if needed, a US state regulations message. If an IDFA explainer message is used, add `NSUserTrackingUsageDescription` to `ios/Runner/Info.plist` for that build.
4. Android: Play Console → App content → Advertising ID declaration, "Contains ads", and the Data safety form updated for the ads build. The ads-on build keeps the SDK's `AD_ID` permission.
5. iOS: App Store privacy "nutrition label" updated for the ads build. The script adds Google's `SKAdNetworkItems` entry (`cstr6suwn9.skadnetwork`); add third-party buyer IDs if the AdMob account uses them.
6. Verify on real devices in test mode first, then with the live IDs using AdMob test devices. Never click live ads.

## Verification in this task

Automated tests use a scripted ads boundary (`FakeAdsPlatform`). They do not contact Google. See `docs/release/launch_checklist.md` for what was run on an emulator or simulator and what is still open.
