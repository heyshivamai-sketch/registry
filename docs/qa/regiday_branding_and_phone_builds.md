# Regiday branding and phone builds — 29 September 2026

Private QA only. Public name/mark clearance and final production identities remain pending.

## Handoff inspection and preserved work

Branch: `feature/local-store-pro-and-ads`, HEAD `b2083fd`. Nothing staged. The substantial existing billing-server removals, store-only Pro/ads changes, branding, icons, signing scripts and screenshot evidence were present on arrival and preserved. No applicable `AGENTS.md` was found. The brief was read from `~/Downloads/Regiday_Cursor_Branding_and_Phone_Testing.md`.

Already implemented: Android/iOS display name Regiday, Regiday Pro and notification/backup/privacy copy in EN/FR/AR, one-time upgrade wording, Android legacy/adaptive/themed icons and iOS appearance assets. Generic “Your Registry” remains intentional. Package IDs remain `com.residay.app` and `com.example.theRegistry`; `local_pro`, database/attachment paths, backup versions, channels and preference identifiers remain unchanged. Ads and purchases default off, with normal `registry.db` storage and free limits of 10 documents / 5 subscriptions.

This continuation adds this report and a screenshot-output override in `test/support/save_screenshot.dart`, formats changed Dart files (including the pre-existing fixture tool), prepares the iOS ads-off Debug configuration, and verifies/rebuilds the Android artifact with the existing key. No app was uninstalled, no data cleared, and no commit, push or publication performed.

## Icon status — reference still required

The actual attached concept image is not accessible in this conversation or the checked repository/design references/downloads. The previous agent's [icon README](../../design/branding/regiday/README.md) explicitly identifies the current artwork as an approximation of the written brief. It is not an approved match to the missing attachment. Supply the reference before final visual acceptance; do not invent a replacement reference.

Existing outputs were inspected without regenerating or overwriting them:

- Editable masters: `design/branding/regiday/regiday_icon_master.svg`, `regiday_adaptive_foreground.svg`, `regiday_monochrome.svg`.
- Reproducible exporter: `tool/branding/regiday_icons.py` (setup in the icon README).
- Listing/iOS exports: `design/branding/regiday/exports/`, 512 and 1024 square masters.
- Review sheet: `design/branding/regiday/previews/regiday_icon_contact_sheet.png`; circle/rounded-square crops, themed light/dark, safe zone and actual 24/32/48 px previews. R is legible and uncropped; the mint fold is weak at 24 px.
- Android resources: `android/app/src/main/res/mipmap-*`, `mipmap-anydpi-v26`, and `drawable/ic_launcher_*.xml`. Single-colour `ic_notification.xml` is retained.
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset`, Any/Dark/Tinted 1024 assets. No Icon Composer layered asset is claimed.

Existing `screenshots/regiday_branding/` evidence is retained. The app-drawer image shows Regiday with the R icon. **The prior `android_release_relaunch_after_edit.png` contains a “System UI isn't responding” dialog**, although a QA document is visible beneath it. It is not clean restart acceptance. These images are prior emulator evidence, not physical-phone evidence or proof of the newly rebuilt APK's runtime behavior.

## Android deliverable

The current artifact and exact certificate/hash/size/ABI metadata are in:

- `artifacts/qa/Regiday-android-release-qa.apk`
- `artifacts/qa/BUILD_INFO.md`

The prior artifact and its metadata are preserved in `artifacts/qa/prior-20260929/`. App source timestamps were newer than that artifact, so a rebuild was used to establish correspondence with the current workspace. The successful serial rebuild produced the **same SHA-256** as the prior APK.

| Verified current artifact | Value |
| --- | --- |
| SHA-256 | `ac0d6da89867ae5db2a93457a71c36a8d6ecd3d6bb1ab2a3f57a67ee8c6a6932` |
| Size | 93,940,952 bytes |
| Rebuilt | 2026-09-29 10:13 UTC |
| Application / label / version | `com.residay.app` / Regiday / 1.0.0 (1) |
| minSdk / targetSdk | 24 / 36 |
| ABIs | arm64-v8a, armeabi-v7a, x86_64 |
| Signature | `apksigner verify --verbose --print-certs` passed, v2, RSA 4096, Regiday QA certificate |
| Debuggable | No |
| Ads-off manifest | No MobileAdsInitProvider, AdMob App ID, AD_ID, or AdServices advertising permissions |

Reproduce from the repository root:

```sh
bash tool/android/build_release_qa_apk.sh
```

The script runs `flutter build apk --release` with no Dart defines: ads off, purchases off, normal storage, all supported phone ABIs. It reads the existing key password from macOS Keychain without printing it, verifies the APK with `apksigner`, rejects debug signing/debuggable APKs and advertising permissions/providers, and writes build metadata. Flutter 3.44.8 / Dart 3.12.2 and Android build-tools 36.0.0 were used for validation.

Run all Flutter commands serially, including analysis and builds. The first rebuild overlapped the final analyzer invocation and failed because the generated Android plugin registrant referred to the excluded `integration_test` release plugin. A serial retry regenerated the release registrant without that entry; no application-source workaround or dependency suppression was added.

Existing QA key: `~/.regiday/signing/regiday-qa-release.p12`, alias `regiday-qa`; directory mode 700, key mode 600. Keychain service `regiday-android-qa-keystore`, account `regiday-qa` exists. Certificate SHA-256: `43a9766ed56d7cdafb9f6f18052fb706f348d93ce0133208a48f8bc38a5daa91`. This is a **QA-only certificate**, not a selected production upload key. Keep an encrypted offline backup of the keystore and separately retain its password in a trusted password manager/Keychain backup. Do not regenerate the key for updates, copy secrets into this repo, or paste them into chat.

WorkManager remains pinned to 2.11.2. Flutter's installed Gradle plugin automatically includes `android/app/proguard-rules.pro`; its narrow optional non-Latin ML Kit rules are present in the generated R8 configuration. No broad R8 suppression was added. The ads-off manifest removes the SDK initialization provider and advertising permissions; the ads-on manifest remains separate.

### Install without losing existing Android data

No Android device was connected in this continuation (`adb devices -l` returned no devices). Physical QA is pending. Connect the phone, enable USB debugging and accept its authorization prompt. Before updating any existing installation, compare its signing certificate:

```sh
SDK="$HOME/Library/Android/sdk"
ADB="$SDK/platform-tools/adb"
APKSIGNER="$SDK/build-tools/36.0.0/apksigner"
"$ADB" devices -l
# Substitute the authorized serial; always select a device explicitly.
"$ADB" -s SERIAL shell pm path com.residay.app
```

If installed, copy the returned **base.apk** path (without `package:`), pull it to a new local QA evidence file, and inspect both certificates:

```sh
"$ADB" -s SERIAL pull /data/app/RETURNED_PATH/base.apk /tmp/regiday-installed-base.apk
"$APKSIGNER" verify --verbose --print-certs /tmp/regiday-installed-base.apk
"$APKSIGNER" verify --verbose --print-certs artifacts/qa/Regiday-android-release-qa.apk
```

Only if the certificates match (or no app is installed), use:

```sh
"$ADB" -s SERIAL install -r artifacts/qa/Regiday-android-release-qa.apk
```

If the existing app uses a debug/other certificate, stop and preserve it. An isolated QA application ID can be prepared only after the owner's confirmation; no such variant has been created. Do not uninstall, clear data, force a downgrade or restore a fixture into a real store. If certificate inspection fails, do not guess. A manual APK install through the phone's file manager is also possible after this comparison; authorize that source locally when prompted.

Acceptance still needed on a real phone: launcher/splash, cold start and Home, existing-record visibility, lock/unlock, create/edit/restart using a clearly named safe QA record, backup-screen navigation without restoring/replacing data, EN/FR/AR including RTL and large text, and no banner/privacy-ad menu. Capture new evidence under a new directory. Unit tests verify zero app calls to the injected ad/consent interface; no universal network/privacy guarantee or physical network observation is claimed.

## iPhone: prepared Debug route, no installable artifact yet

Xcode 27.0 (27A266a) is installed. `xcrun xctrace list devices` found the Mac and simulators, **no physical iPhone**. `security find-identity -v -p codesigning` found **0 valid signing identities**, and the project has no `DEVELOPMENT_TEAM`. A paid team/provisioning profile is not established; account membership cannot be inferred from that alone. No IPA or phone-installable Runner.app is delivered.

Stale generated settings had `ADS_ENABLED=true` / `ADS_MODE=test`. They were replaced successfully using:

```sh
flutter build ios --config-only --debug --no-codesign \
  --dart-define=ADS_ENABLED=false \
  --dart-define=PURCHASES_ENABLED=false
```

This prepares configuration only. Verified target: `lib/main.dart`; no fixture store define. Repeat this command immediately before opening Xcode if other Flutter builds have changed the generated settings. The existing build phase writes Google's sample iOS App ID `ca-app-pub-3940256099942544~1458002511` for ads-off Debug startup, while app ad/consent requests remain disabled. It does not turn on test ads.

Local owner steps:

1. Connect and unlock the iPhone; accept Trust on phone/Mac. Pair it in Xcode → Window → Devices and Simulators. Enable Settings → Privacy & Security → Developer Mode on the phone, restart and confirm when requested.
2. Sign in locally through Xcode → Settings → Accounts with your Apple Account. Never share the password or verification code in chat.
3. Open `ios/Runner.xcworkspace`. Select Runner target → Signing & Capabilities → Automatically manage signing; select your Personal Team (or already available paid team). Keep bundle ID **`com.example.theRegistry`**.
4. Select the connected iPhone and Runner scheme. Edit Scheme → Run → Build Configuration **Debug**. Press Run. Accept any local developer-trust prompt required by iOS. Keep Xcode attached for the Debug session.
5. Verify launch, Regiday name/icon, Home/Profile/backup navigation and existing data; use only safe QA records. Record the team type, device/iOS version and actual installed Debug flags with screenshots.

If the bundle ID cannot be provisioned, retain the exact Xcode error. No conflict has yet been observed because there is no signed-device attempt. Do not silently change the ID; a separate isolated QA target requires confirmation. Likewise, report any unsupported capability before changing it; app lock, reminders and OCR must not be removed to pass signing.

Apple's free Personal Team provisioning expires after **7 days** and requires rebuilding/reinstalling with the same identity. It is for local testing, not a lasting distributable IPA. See [Apple's Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account) and [running on a device](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices).

**iOS Release remains blocked without a real AdMob iOS App ID**, even with app ads off, because the SDK is linked. The validator was exercised with temporary plists: ads-off Debug succeeds with the sample ID; Release without an ID fails; Release test mode fails. `GADDelayInitialization` was not restored. [Google's iOS setup guidance](https://developers.google.com/admob/ios/quick-start) documents the required App ID. A paid signing team alone does not resolve this Release blocker. No archive, TestFlight upload or publication was attempted.

## Validation

- `dart format` on changed/new Dart files: 37 files checked, 2 formatted (screenshot helper and existing fixture tool).
- `flutter analyze`: no issues, including the final run after the test-helper change.
- Focused `regiday_branding_test.dart`, `ads_test.dart`, `local_pro_screen_test.dart`: **35 passed**. Covers EN/FR/AR branding, one-time copy, original backup format/channel/product identifiers, pre-branding `.rgry` decryption (10 documents / 5 subscriptions / 10 attachments), ads-off zero calls/zero banner height/hidden ad menu, and Arabic large-text Pro layout.
- Full `flutter test --reporter expanded`: **348 passed**, one sequential run after final Dart formatting. Includes persistence, backup/restore, app lock, reminders and entitlement regressions. Fake store/fixture Pro tests are not real purchases.
- New suite screenshots were saved with `REGISTRY_SCREENSHOT_ROOT` to `artifacts/qa/validation-20260929/screenshots`; existing screenshot evidence was not overwritten. They use Flutter's block-shaped test font, so they are layout fixtures, not readable typography/device acceptance images.
- Logs: `artifacts/qa/validation-20260929/`. `git diff --check` passed. Existing tracked modifications/deletions and untracked work remain; nothing staged or committed.

Outstanding: original icon reference and visual match; real Android install/runtime acceptance; iPhone connection, local account signing and Debug run. These are not store-release acceptance.
