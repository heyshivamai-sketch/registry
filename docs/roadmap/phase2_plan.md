# Phase 2 plan

> **Superseded (28 September 2026, `feature/local-store-pro-and-ads`).** The billing server, email account, recovery code, installation binding, and signed grants described here were removed. Local Pro is now checked on the device against Google Play Billing or StoreKit only. Current setup: `docs/setup/local_pro_billing.md`, `docs/setup/ads.md`, `docs/setup/privacy_and_data.md`, `docs/release/launch_checklist.md`. This file is kept as a historical record.

Phase 2A is the local premium foundation on `feature/phase2-local-pro-foundation`, branched from `70fd546` (`feature/secure-backup-restore`). It does not add cloud sync, bank access, email import, or a live store purchase.

The proposed product name **Regiday** is not approved or cleared. This phase keeps the current display name, application id, and bundle ids.

## 2A — Local Pro foundation (this branch)

### Backup restore navigation

A successful replace returns to Home only after `restoreBackup` has committed, the repositories have refreshed, and reminder reconciliation has finished. The success message is shown once, on the shell. Cancelling the file picker, cancelling the replace confirmation, a wrong password, and a failed restore stay on Import backup and do not change live records. Database ids, attachment bytes, and reminder reconciliation are unchanged from the encrypted backup work.

### App lock

App lock is free. It asks for platform biometrics and can fall back to the device passcode where the OS supports that (`biometricOnly: false`). Turning the setting on or off requires a successful authentication first. The off value is stored only after that success. Cancellation, a failed attempt, unavailable authentication, or a platform error leaves the previous setting in place.

When the setting is on:

- Cold start shows a lock screen before records. Records stay offstage until authentication succeeds.
- The privacy cover appears as soon as the app becomes inactive, including during the grace window. Android also sets `FLAG_SECURE` while the lock is on, through `com.residay.app/privacy`.
- Relock timeout is **30 seconds** (`AppLockPolicy.relockTimeout`). A resume before that keeps the unlocked session. A resume at or after 30 seconds requires authentication again. The system authentication sheet does not start the timer.
- Cancellation or unavailable authentication while locked keeps records hidden.

App lock hides records. It does not encrypt the SQLite database. Backup files remain separately password-encrypted.

### Entitlements

All commercial record-count decisions go through `EntitlementPolicy` and `RegistryWrites`.

| Plan | Documents | Subscription records |
| --- | --- | --- |
| Free | 10 | 5 |
| Local Pro | No commercial count limit | No commercial count limit |

Technical limits stay for every plan: backup caps in `BackupLimits`, the 64 pending local reminders, CSV import caps, and device storage.

Viewing, editing, renewing, deleting, reminders, app lock, export, and restore stay available for records that already exist. Editing calls `update` and keeps the id. Restore does not consult the plan and must not drop records to fit Free. If a restored registry is over the Free limits, existing-record actions still work and only a net-new record requires Local Pro. A batch that would pass the limit is refused before the write, so the repository is unchanged.

### Purchase boundary

Production uses `ProductionStoreProductSource`, `ProductionPurchaseService`, and `ProductionVerifiedEntitlementSource`.

- `BillingConfiguration.storeVerificationConfigured` is `false`.
- There is no hard-coded price and the Buy button does nothing until a store listing is supplied by a configured catalog.
- A client boolean, backup field, debug switch, or unverified purchase callback cannot turn on Local Pro. `planAfterProof` grants Local Pro only when verification is configured, the proof is accepted, the product id is `local_pro`, and the proof is not client-supplied.
- `DebugQaVerifiedEntitlementSource` throws in release builds and is not constructed by production startup.

Local Pro is described as a one-time purchase of the local limits above. Cloud sync, cloud backup, and accounts are listed as not included.

#### Configuration required before any real purchase

Do not set `storeVerificationConfigured` until all of the following exist.

Google Play Console, application id `com.residay.app`:

- One-time product id `local_pro` (not a subscription).
- An active price created in Play Console. The app must display that localized price from a Play Billing product query.
- Play Developer API access that can call `purchases.products.get` for package `com.residay.app` and product `local_pro`.
- The backend treats `purchaseState` purchased, for that product, as success and acknowledges the purchase.

App Store Connect, bundle id `com.example.theRegistry`:

- Non-consumable product id `local_pro`.
- Paid Applications agreement and an App Store Connect price.
- App Store Server API verification (`Get Transaction Info` or the signed transaction). Require product id `local_pro`, this bundle id, and no revocation.

Backend, which the app does not ship:

- Receive the store token or signed transaction.
- Call the store API. Do not trust the client callback.
- Return a verified result. A later cache must store that result, not a client-written premium flag.

### Generic charge CSV

This is one documented format, not universal bank-statement support and not a bank or email connection.

- UTF-8, comma-separated, header row required.
- At most 1 MB, 2,000 data rows, and 32 columns.
- The person chooses the file and maps date, merchant, amount, and currency.
- Example header: `date,merchant,amount_minor,currency`.
- Dates are `YYYY-MM-DD`. Amounts are non-negative integer minor units with no decimal point. Currency must be one of the app's supported codes.
- Rows that fail validation are skipped and listed. They are not saved.
- Recurring groups (same merchant, amount, and currency, with a regular weekly, monthly, quarterly, or yearly gap) are **suggestions**. One-off and irregular rows are not created.
- The person can correct a suggestion, see source rows, review possible duplicates, and choose which ones to create.
- Nothing is written until Create is pressed. The free or Local Pro limit is checked first. Refusal, cancellation, and invalid files leave the repositories unchanged. A successful batch is one `saveAll` transaction.

### Branding files to update later

Do not change these until Regiday is approved and store listings are created for the new ids.

| Surface | File | Current value |
| --- | --- | --- |
| Android label | `android/app/src/main/AndroidManifest.xml` | `the_registry` |
| Android application id | `android/app/build.gradle.kts` | `com.residay.app` |
| Android package | `android/app/src/main/kotlin/com/registry/app/` | `com.residay.app` |
| iOS display name | `ios/Runner/Info.plist` `CFBundleDisplayName` | `The Registry` |
| iOS bundle name | `ios/Runner/Info.plist` `CFBundleName` | `the_registry` |
| iOS bundle id | `ios/Runner.xcodeproj/project.pbxproj` `PRODUCT_BUNDLE_IDENTIFIER` | `com.example.theRegistry` |
| macOS bundle id | `macos/Runner/Configs/AppInfo.xcconfig` | `com.example.theRegistry` |
| Window title | `lib/app/app.dart` `onGenerateTitle` | `Registry` |
| Copy | `lib/l10n/app_en.arb`, `app_fr.arb`, `app_ar.arb` | Strings that say Registry |
| Package name | `pubspec.yaml` `name` | `the_registry` |

## Later phases (not in 2A)

1. **Smallest next implementation:** Play Billing and StoreKit behind the purchase interfaces, plus the backend verifier above. Keep `storeVerificationConfigured` false until a real purchase can be verified. Then show the store-localized price and enable Buy.
2. A verified-entitlement cache that stores the backend result, not a boolean.
3. Cloud backup, sync, and accounts as separate products, only after they exist. They are not part of the Local Pro offer.
4. Additional CSV or statement formats only after the generic format is in users' hands. Do not claim bank connectivity.
5. Approved Regiday branding, including store ids if they must change.
