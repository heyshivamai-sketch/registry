# Phase 2A — Local Pro foundation

**Date:** 27 September 2026
**Branch:** `feature/phase2-local-pro-foundation`
**HEAD:** `70fd5466287d945f76e1c7cd83b477ece224248a` (`feat: add encrypted registry backup and restore`)
**Remote:** not pushed. Nothing in this phase was committed.

Two device passes used `adb install -r`. Neither cleared, uninstalled, or replaced the emulator’s production registry.

The first pass only opened Home, Profile, Local Pro, and the in-app CSV choose step on the existing store. The second pass, recorded below, is the device acceptance. It used an isolated store id (`REGISTRY_STORE_ID=phase2aqa`) and synthetic fixtures.

## What this phase does

- Successful backup replace returns to Home only after the replacement is committed, repositories are refreshed, and reminders are reconciled. The success message is shown once. Cancel, wrong password, and failed restore stay on Import backup.
- Optional free app lock uses platform biometrics with device-credential fallback (`biometricOnly: false`). Turning it on or off requires a successful authentication before the preference is stored. The off value is written only after that success. Cancellation, a failed attempt, unavailable authentication, or a platform error leaves the previous setting in place. Relock timeout is 30 seconds (`AppLockPolicy.relockTimeout`). The privacy cover and Android `FLAG_SECURE` hide app-switcher previews. App lock is not database encryption.
- `EntitlementPolicy` and `RegistryWrites` are the only commercial record-count gate. Free: 10 documents and 5 subscriptions. Local Pro removes those two limits. Backup, reminder, CSV, and storage caps stay. Restore does not drop records to fit a plan. Existing records can still be viewed, edited, renewed, deleted, reminded, exported, and restored. A net-new record over the Free limit requires Local Pro. Edits call `update` and keep the id. A single create calls `save`. A CSV batch calls `saveAll` in one transaction.
- Local Pro is a one-time local purchase. Cloud sync, cloud backup, and accounts are listed as not included. Production purchase and entitlement sources do not grant Local Pro while `BillingConfiguration.storeVerificationConfigured` is false. There is no client boolean, backup flag, debug switch, or unverified callback that turns it on. Debug QA fakes throw in release and are not constructed by production startup.
- Generic CSV import is one documented format (`date,merchant,amount_minor,currency`). The person chooses the file, maps columns, reviews suggestions, and confirms before any write. Recurrence is a suggestion. Invalid input and cancellation leave repositories unchanged.

Design detail, the store-configuration checklist, and the branding file table are in `docs/roadmap/phase2_plan.md`. Display name, application id `com.registry.app`, and bundle id `com.example.theRegistry` are unchanged. **Regiday is a proposed name and is not approved.**

`BillingConfiguration.storeVerificationConfigured` is still `false` (`lib/features/entitlements/billing_configuration.dart`). This pass did not implement purchases and did not enable Buy.

## Isolated store

`openDefaultRegistryStore` reads `REGISTRY_STORE_ID`. The acceptance APK was built with `--dart-define=REGISTRY_STORE_ID=phase2aqa`, so it opened `app_flutter/registry_phase2aqa.db` and `registry_attachments_phase2aqa`. Production `registry.db` and `registry_attachments` were left in place. An older `registry_backupqa.db` was also left in place.

SharedPreferences are app-wide, so `flutter.app_lock_enabled` is not store-specific. Onboarding was already complete. After the pass, the original preferences file (onboarding only) was written back, the temporary PIN was cleared, and a debug APK **without** `REGISTRY_STORE_ID` was installed with `adb install -r`. That APK’s kernel does not contain `phase2aqa`. A normal launch then showed the production Home: 2 documents and 1 subscription (`PersistQAPassport`, `ReminderProbe`, `PersistQAStream`).

| Item | After cleanup |
| --- | --- |
| `registry.db` sha256 | `f70b67c36644ab9fc679ed0712b4a4f4b1a139cd1d6440b78350a9ff68bc9b32` (45,056 bytes, mtime 2026-09-25 08:53) |
| Production attachment sha256 | `42ab578a8104e5728d80a28f6046c8d35a76a97d6530cb8b91e2de94d41b2a11` |
| Preferences | `flutter.onboarding_completed` true only |
| Lock screen | disabled again (`locksettings get-disabled` true). The QA PIN was cleared. |
| QA databases | still on the device. They were not deleted. |

Screenshot of the restored production Home: `screenshots/phase2a_local_pro/acceptance/71_production_restored.png`.

## Defect fixed during acceptance

`local_auth` 2.3.0 attaches the system prompt to a `FragmentActivity`. `MainActivity` extended `FlutterActivity`, so the plugin returned `errorNotFragmentActivity` immediately. `PlatformDeviceAuthenticator` reported that as a cancellation, and the switch stayed off with “Authentication was cancelled” before any sheet appeared.

`MainActivity` now extends `FlutterFragmentActivity`. The privacy channel and backup file bridge are unchanged. After reinstall, the system credential sheet appeared.

## Automated results

Re-run on 27 September 2026 after the activity change, from this working tree, one Flutter command at a time.

| Command | Result |
| --- | --- |
| `flutter test` on `app_lock_test`, `entitlement_policy_test`, `csv_import_test`, `local_pro_screen_test`, `import_backup_navigation_test` | **Passed.** 19 tests. |
| `flutter analyze` | No issues found (2.1s). |
| `flutter test` (one full suite) | **Passed.** `00:16 +276: All tests passed!` |
| `git diff --check` | Clean (exit 0). |
| `flutter build apk --debug` (no store id) | **Passed.** Installed with `adb install -r` so later launches use `registry.db`. |
| `flutter build ios --simulator --debug --dart-define=REGISTRY_STORE_ID=phase2aios` | **Passed.** Installed and launched on the iPhone 18 Pro simulator. See iOS. |

An earlier full suite the same day, before this acceptance pass, also passed 276 tests. The first suite that day had failed one save-path test; a single create now calls `subscriptions.save`, and CSV batches still use `saveAll`. That fix was already in the tree before this pass.

Android build warning, not a failure: `flutter_timezone` still applies the Kotlin Gradle Plugin. iOS build warning, not a failure: `google_mlkit_commons` and `google_mlkit_text_recognition` do not support Swift Package Manager. CocoaPods was used.

## Device

Pixel 8 emulator, `emulator-5554`, `sdk_gphone16k_arm64`, Android 17 (API 37), 1080×2400. Owner user 0. The emulator had no lock screen and no enrolled fingerprint at the start. A PIN was set only so the credential fallback could be exercised, then cleared. No fingerprint was enrolled, so a successful biometric match was not available. The sensor exists; the enrolled-print count stayed 0.

High-count registries came from synthetic backups written by `tool/phase2a_qa_fixtures.dart` (password `phase2a-qa-password`). Those files are fixtures, not records typed in one by one. The document-limit block, the edit, the renewal, the delete, and the CSV confirm used the real screens. No bank statement was used.

### 1. App lock

| Scenario | Result | Evidence |
| --- | --- | --- |
| Enable with no biometrics and no passcode | Switch stayed off. Snackbar: the device has no biometrics or passcode Registry can use. Preference unchanged. | `acceptance/02_lock_unavailable.png` |
| Enable after the activity fix, then Cancel on the PIN sheet | Sheet title `the_registry`, “Confirm it is you before turning on app lock.” Cancel left “App lock is off” and showed the cancelled snackbar. | Prompt captures are black because the credential UI is secure. UI text came from `uiautomator`. `acceptance/05_after_cancel.png` |
| Wrong PIN `0000` | Sheet stayed up and showed “Wrong PIN”. It did not turn the lock on. | `acceptance/06_wrong_pin.png`, `acceptance/07_off_after_wrong_pin.png` |
| Correct PIN | “App lock is on.” `flutter.app_lock_enabled` became true. | `acceptance/08_lock_enabled.png` |
| Force-stop and relaunch | “Registry is locked” / Unlock. The restored marker name was absent from the accessibility tree. Taps did not reveal it. Unlock showed Home again. | `acceptance/09_cold_locked.png` is black (`FLAG_SECURE`). Tree text was the lock screen. |
| Return after about 8 seconds, and a short Recents visit | Stayed unlocked. | UI dump while the marker was visible. |
| Background Home for about 32 seconds | Lock screen on return. | Same lock copy as cold start. |
| `FLAG_SECURE` | `dumpsys window` showed `SECURE` on the app window while the lock was on, and the flag was gone after disable. Recents thumbnail was a black card labeled `the_registry`. | `acceptance/10_recents_flag_secure.png` |
| Privacy cover | The Flutter cover is the word “Registry” while the app is inactive and still unlocked. With `FLAG_SECURE` set, `screencap` of that window is black, including during the 30-second grace window, so the cover word was not captured as pixels. Cover behaviour is also in `test/app_lock_test.dart`. | Black recents card plus the widget test. |
| Disable | In this pass, turning the switch off did not ask for authentication. Preference returned to false and `SECURE` cleared. The later hardening pass below requires authentication before the off value is stored. | `acceptance/26_lock_disabled.png` |
| Notification / deep link | The manifest has only `MAIN` / `LAUNCHER`. There is no custom URI. `flutter_local_notifications` has no Dart `onDidReceiveNotificationResponse` handler. A `SELECT_NOTIFICATION` intent delivered while locked left the lock screen up and did not show the marker. A real shade tap of a Registry reminder was not available: the fixtures scheduled no reminders. | `acceptance/25_locked_notification_intent.png` |

Credential fallback is the Android device PIN (`BIOMETRIC_WEAK`, `BIOMETRIC_STRONG`, and `DEVICE_CREDENTIAL`). User cancel completes as a failure. A wrong PIN stays on the sheet until Cancel or a correct PIN.

One copy observation, with records still hidden: cancelling Unlock left the default locked sentence. Cancelling Enable did show “Authentication was cancelled.”

### 2. Free limits

The exact-limit registry is the fixture backup `qa_exact_free_limit.rgry` (10 documents `qa-exact-doc-01` … `10`, 5 subscriptions `qa-exact-sub-01` … `05`). The screen work after that restore is the real UI.

| Scenario | Result | Evidence |
| --- | --- | --- |
| Restore of the exact fixture | Home once, one snackbar: “This device's registry was replaced from the backup.” Counts 10 documents and 5 subscriptions (50.15 USD). | `acceptance/46_exact_home_message.png` |
| Net-new document at 10, real add-document wizard, name `QA Net NeX` | Save stayed on the review step. “The free plan includes 10 documents. Local Pro removes that limit for new documents. Records you already have can still be viewed, edited, renewed, and deleted.” Count stayed 10. Same ids. | `acceptance/54_limit_blocked.png` |
| Edit `qa-exact-doc-01` | Id stayed `qa-exact-doc-01`. Snackbar “Document updated on this device.” Count stayed 10. | `acceptance/58_edited.png` |
| Renewal | An expiry on 27 Sep 2026 was rejected because it was not after the previous expiry (1 Jun 2027). 15 Sep 2028 saved. “Renewal recorded on this device.” History for that id became 2. | `acceptance/56_detail_lower.png`, `acceptance/63_renewed.png` |
| Delete `qa-exact-doc-10` | 9 documents. Its history and attachment went with it. “Document deleted from this device.” | `acceptance/66_after_delete.png` |
| New document after that delete | `QARoom` saved as `doc_1790527648140025`. Count returned to 10. “Document saved on this device.” | `acceptance/67_room_saved.png` |
| Subscription batch over the Free cap | One existing CSV subscription plus six new suggestions. Create refused the whole batch. See CSV. | `acceptance/43c_csv_limit_top.png` |

A single add-subscription wizard at exactly 5 was not repeated. The CSV batch is the same `saveAll` gate, and it refused 1 existing + 6 new with the Local Pro sentence. Editing, renewing, and deleting were done on the exact-limit store before the later above-limit restore replaced it.

### 3. CSV import

Files in `screenshots/phase2a_local_pro/fixtures/` are synthetic. They were opened through the system Documents picker (`file_picker`, `FileType.custom`, csv, `withData: true`). The filename row was tapped. The preview control opens “Open with” and was not used as the confirm path.

| Scenario | Result | Evidence |
| --- | --- | --- |
| `small_recurring.csv` | Map step preselected `date`, `merchant`, `amount_minor`, `currency`. Review showed the suggestion. Confirm wrote one subscription. Snackbar “1 subscription added.” | `acceptance/31_csv_review.png`, `acceptance/33_csv_created.png` |
| Restart | The subscription was still in `registry_phase2aqa.db` and on screen. | `acceptance/34_csv_after_restart.png` |
| Import the same file again | “Possible duplicate…” The row was unselected. Create with nothing selected: “Select at least one suggestion. Nothing was added.” Count stayed 1. | `acceptance/35_csv_duplicate.png`, `acceptance/36_csv_duplicate_not_created.png` |
| `malformed_mixed.csv` | “5 rows were skipped…” Only the already-imported stream was suggested, and it was unselected. The mixed-currency merchant (alternating USD/EUR) did not become a suggestion. Nothing new was saved. | `acceptance/37_csv_malformed.png` |
| Cancel | Left the flow without a new row. | `acceptance/41_csv_cancel.png` |
| `over_limit.csv` | Six suggestions, QA Over Alpha–Zeta. Create refused the batch: “The free plan includes 5 subscription records. Local Pro removes that limit for new subscriptions. Records you already have can still be viewed, edited, and deleted.” The database stayed at the one earlier subscription. | `acceptance/42_csv_over_limit_review.png`, `acceptance/43c_csv_limit_top.png` |
| `invalid.csv` (one non-CSV line) | Opened the map step, then “Choose a different column for each field.” Nothing was saved. | `acceptance/39_csv_invalid.png`, `acceptance/40_csv_invalid_review.png` |

### 4. Restore

Backups are synthetic `.rgry` files from the same fixture tool. The picker is `ACTION_OPEN_DOCUMENT`. Password minimum is 8 characters.

| Scenario | Result | Evidence |
| --- | --- | --- |
| Replace dialog, Cancel | Stayed on Import backup. “Import cancelled.” QA database still empty at that point. | `acceptance/17_replace_dialog.png`, `acceptance/18_replace_cancelled.png` |
| Wrong password | “That password does not open this backup. Nothing on this device was changed.” Repeated later while the marker and the CSV subscription existed. Both times the screen stayed on Import and the row set was unchanged. | `acceptance/19_wrong_password.png`, `acceptance/44_wrong_password_with_data.png` |
| Picker back | “Import cancelled.” | `acceptance/20_picker_cancel.png` |
| Marker backup | Committed `qa-lock-marker`, one renewal “Synthetic renewal qa-lock-marker”, and a 24-byte attachment matching the fixture. A long `uiautomator` dump during that restore also crossed the 30-second relock, so the success snackbar was covered. The later exact and above restores showed the snackbar once on Home. | Database pull. `acceptance/23_marker_documents.png` after unlock. |
| Exact Free backup | 10 documents, 5 subscriptions, Home once, one success snackbar. | `acceptance/46_exact_home_message.png` |
| Above-Free backup `qa_above_free_limit.rgry` | Home: 12 documents, 7 subscriptions, 70.28 USD, one snackbar. SQLite after the pass: ids `qa-above-doc-01` … `12`, `qa-above-sub-01` … `07`, 12 renewal-history rows, minor-unit sum 7028. Twelve attachment files were on disk under `registry_attachments_phase2aqa`. | `acceptance/69_above_home.png` |

Fixture attachment bytes are a PNG signature plus id bytes. They are not decodable images. Detail and edit showed “Exception: Invalid image data” for those blobs. The bytes were still stored. Real photo attachments were not part of this fixture. `Image.memory` has no `errorBuilder`. That was left as a fixture limit.

A second net-new add after the 12/7 restore was not walked through the wizard again. The same save path already blocked a net-new document at 10, and the above-limit rows stayed usable on Home.

### 5. iOS

Three different results:

| Kind | What happened |
| --- | --- |
| Build only | Earlier `flutter build ios --debug --no-codesign` produced `build/ios/iphoneos/Runner.app`. It was not installed. |
| Simulator launch | `flutter build ios --simulator --debug --dart-define=REGISTRY_STORE_ID=phase2aios` installed on iPhone 18 Pro (`4287A018-F5DF-43E7-BF55-45999C3BC9D6`, iOS 27.0). The process stayed up. Home was the empty isolated store: “Your Registry”, “Add your first document”. |
| Physical device | No iPhone was attached. There is no device result. |

`screenshots/phase2a_local_pro/ios/02_display.png` is the simulator Home. `ios/01_launch.png` is a blank framebuffer from the first capture and is not the UI.

`NSFaceIDUsageDescription` is in `ios/Runner/Info.plist`. `simctl` has no biometric command, and Simulator.app was not available to open Features > Face ID. Face ID was not enrolled, and app lock, the file picker, and restore were not tapped on iOS. `simctl openurl` of `registry://document/qa-lock-marker` failed with `LSApplicationWorkspaceErrorDomain` 115. The app has no custom URL scheme, which matches the Android manifest.

Simulated biometrics and a physical Face ID match are both still open.

## Screenshots

Widget fixtures from `test/phase2a_screenshots_test.dart` (`save_screenshot.dart`, 390×844) are labeled fixture. Device files are under `screenshots/phase2a_local_pro/acceptance/`. Synthetic inputs are under `screenshots/phase2a_local_pro/fixtures/` (`FIXTURES.txt` lists them).

| File | Kind |
| --- | --- |
| `fixture_app_lock.png`, `fixture_local_pro_price_unavailable.png`, `fixture_local_pro_store_price.png`, `fixture_csv_review.png` | Widget fixtures from the first pass |
| `device_home.png`, `device_profile_top.png`, `device_profile_lower.png`, `device_local_pro.png`, `device_local_pro_lower.png`, `device_csv_choose.png`, `device_after_csv_cancel.png` | First pass, production store, no writes |
| `acceptance/00_launch.png` | Isolated QA Home, empty |
| `acceptance/02_lock_unavailable.png`, `05_after_cancel.png`, `08_lock_enabled.png`, `26_lock_disabled.png` | App lock setting |
| `acceptance/09_cold_locked.png`, `10_recents_flag_secure.png` | Secure lock and black Recents card |
| `acceptance/31_csv_review.png`, `33_csv_created.png`, `34_csv_after_restart.png`, `35_csv_duplicate.png`, `37_csv_malformed.png`, `43c_csv_limit_top.png` | Real picker CSV flow |
| `acceptance/46_exact_home_message.png`, `54_limit_blocked.png`, `58_edited.png`, `63_renewed.png`, `66_after_delete.png`, `67_room_saved.png` | Exact Free limit, then real edits |
| `acceptance/69_above_home.png` | Fixture restore above the Free limits |
| `acceptance/71_production_restored.png` | Production Home after the default APK was reinstalled |
| `ios/02_display.png` | Simulator launch, isolated empty store |

`screenshots/phase2a_local_pro/_acceptance.py` drives the emulator. It does not clear app data.

## App lock disable hardening

Same day, after the acceptance pass above. Nothing was committed.

Turning app lock off now asks for a fresh system authentication. `AppLockController.disable` writes `flutter.app_lock_enabled` false only after that succeeds, and it clears `FLAG_SECURE` only then. Cancel, a failed attempt, unavailable authentication, and a platform error leave the preference true.

`local_auth` 2.3.0 does not use one result for every platform:

- Android completes a dismissed prompt as `false` (`AuthResult.failure`), including the cancel button. That is cancellation.
- Darwin reports a user cancel as `PlatformException` code `UserCancelled`. `UserFallback` is the person leaving biometrics without authenticating, so it is cancellation too.
- `false` on iOS, macOS, and Windows is an attempt that finished without authenticating.
- Other `PlatformException` codes are configuration or plugin failures: `NotAvailable`, `NotEnrolled`, `PasscodeNotSet`, `LockedOut`, `PermanentlyLockedOut`, `no_fragment_activity`, `no_activity`, `auth_in_progress`, `BiometricNotAvailable`, and `channel-error`. Darwin also reports `LAError.authenticationFailed` as `NotAvailable`, so that path uses the platform-error sentence.
- Only the exception code is read. The message and details are not logged and are not shown. The snackbar is a localized sentence.

English, French, and Arabic:

- Cancel while turning off: “Authentication was cancelled. App lock stays on.”
- Failed attempt while turning off: “Authentication failed. App lock stays on.”
- Platform or configuration error: “Registry could not use this device's authentication. App lock was not changed.”

### Automated results for this pass

| Command | Result |
| --- | --- |
| `flutter test test/app_lock_test.dart` | **Passed.** 9 tests, including successful disable, cancelled disable, failed authentication, and platform errors. |
| `flutter analyze` | No issues found. |
| `git diff --check` | Clean (exit 0). |

This pass did not re-run the full suite. The 276-test run above is from before this hardening change.

### Device

Pixel 8 emulator, `emulator-5554`, same image as the acceptance pass. `adb install -r` of a debug APK built with `--dart-define=REGISTRY_STORE_ID=phase2aqa`. The app was not cleared or uninstalled. Home on that APK was the isolated store (12 documents, 7 subscriptions, 70.28 USD), not the production registry.

A temporary PIN was set only so the credential sheet could be used, then cleared with `locksettings clear`. `locksettings set-disabled true` was run again. After cleanup, `get-disabled` is true and `is-user-secure` is false.

| Step | Result |
| --- | --- |
| Enable | Sheet title `the_registry`, “Confirm it is you before turning on app lock.” After the PIN, the switch read “App lock is on” and `flutter.app_lock_enabled` was true. |
| Disable sheet, before it completed | Preference was still true. The off value was not written first. |
| Cancel | Snackbar: “Authentication was cancelled. App lock stays on.” The switch stayed on and the preference stayed true. |
| Disable with the PIN | Sheet text: “Confirm it is you before turning off app lock.” The switch read “App lock is off”. Preference became false. `dumpsys window` had no `SECURE` flag. Screenshot: `acceptance/73_lock_disabled_after_auth.png`. |

The prompt captures are not pixels. The credential UI is secure, and `FLAG_SECURE` makes `screencap` black while the lock is on. The sentences above are from `uiautomator`.

Production was put back with `adb install -r` of a debug APK built without `REGISTRY_STORE_ID`. `assets/flutter_assets/kernel_blob.bin` in that APK does not contain `phase2aqa`. A normal launch showed the production Home: 2 documents, 1 subscription, `ReminderProbe`, `PersistQAStream`. Screenshot: `acceptance/74_production_restored_after_lock.png`.

| Item | After this cleanup |
| --- | --- |
| `registry.db` sha256 | `f70b67c36644ab9fc679ed0712b4a4f4b1a139cd1d6440b78350a9ff68bc9b32` (45,056 bytes, mtime 2026-09-25 08:53) |
| Production attachment sha256 | `42ab578a8104e5728d80a28f6046c8d35a76a97d6530cb8b91e2de94d41b2a11` |
| `registry_phase2aqa.db` sha256 | `3619da5ebc87ee123d6347499d2e24c13c156970c77e3adbc35130c6245a9824` (left on the device, not deleted) |
| Preferences | `flutter.onboarding_completed` true only. The temporary `flutter.app_lock_enabled` value was removed. |
| Lock screen | disabled (`locksettings get-disabled` true, `is-user-secure` false) |

iOS interactive acceptance is still pending. No Face ID enrollment, and app lock was not tapped on the simulator or on a physical iPhone.

`BillingConfiguration.storeVerificationConfigured` is still `false`.

## Remaining blockers

- Play Billing, StoreKit, and a verifier for product `local_pro`. `storeVerificationConfigured` stays false. Buy stays unavailable. No store listing was created.
- iOS interactive acceptance is still pending. App lock, including turning it off, CSV import, and restore were not tapped on a simulator with Face ID enrolled or on a physical iPhone. The simulator launch earlier in this note did not enroll Face ID. The disable hardening above was checked on Android only.
- A successful fingerprint match. The emulator had no enrolled print.
- A shade tap of a real Registry reminder while locked. The locked `SELECT_NOTIFICATION` intent did not reveal records. Fixtures scheduled no reminders.
- Pixel capture of the Flutter privacy-cover word while `FLAG_SECURE` is set. The Recents card is black, which is the flag working. The cover widget is covered by the unit test.
- `invalid.csv` stays on column mapping instead of an invalid-file message. Nothing is written.
- Unlock-cancel uses the default locked sentence. Records stay hidden.
- Fixture attachments that are not images surface `Exception: Invalid image data` because `Image.memory` has no `errorBuilder`.

## Files changed in this acceptance pass

Product:

- `android/app/src/main/kotlin/com/registry/app/MainActivity.kt` — `FlutterFragmentActivity` so the system credential sheet can attach.

Acceptance evidence and harness, not shipped behaviour:

- `tool/phase2a_qa_fixtures.dart`
- `screenshots/phase2a_local_pro/_acceptance.py`
- `screenshots/phase2a_local_pro/fixtures/`
- `screenshots/phase2a_local_pro/acceptance/`
- `screenshots/phase2a_local_pro/ios/`
- `docs/qa/phase2a_local_pro_foundation.md`

The rest of the uncommitted Phase 2A work (app lock, entitlements, CSV import, restore navigation, l10n, and the earlier iOS Face ID usage string) was already in the tree and was left as it was.

Disable hardening, still uncommitted:

- `lib/features/app_lock/app_lock_controller.dart`
- `lib/features/app_lock/device_authenticator.dart`
- `lib/features/app_lock/platform_device_authenticator.dart`
- `lib/features/app_lock/presentation/app_lock_gate.dart`
- `lib/features/backup/presentation/profile_screen.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_ar.arb`, and the generated localization Dart files
- `test/app_lock_test.dart`, `test/support/phase2_fakes.dart`
- `docs/roadmap/phase2_plan.md`
- `docs/qa/phase2a_local_pro_foundation.md`
- `screenshots/phase2a_local_pro/acceptance/73_lock_disabled_after_auth.png`
- `screenshots/phase2a_local_pro/acceptance/74_production_restored_after_lock.png`

## Next implementation

The smallest next task is Play Billing and StoreKit behind `StoreProductSource` and `PurchaseService`, plus a backend that verifies product `local_pro` with the store. Keep `storeVerificationConfigured` false until a real purchase can be verified. Then the Local Pro screen can show the store-localized price and enable Buy.
