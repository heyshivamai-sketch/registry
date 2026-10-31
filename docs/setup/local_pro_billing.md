# Local Pro billing

Local Pro is one non-consumable in-app product, `local_pro`, sold through Google Play on Android and the App Store on iOS. It is a one-time purchase. It removes the Free limits of 10 documents and 5 subscriptions, and it keeps ads off in any build that has ads turned on. It does not add cloud sync, cloud backup, an account, or any other feature.

There is no Registry server, no app account, no email, no recovery code, and no server-issued grant. The app asks the platform store on the device whether this store account owns `local_pro`. Nothing else turns Local Pro on.

**Shipping state:** purchases are off. `PURCHASES_ENABLED` defaults to `false` (`lib/app/launch_config.dart`). In that build the app never connects to Play Billing or StoreKit, everyone is on Free, the Local Pro screen explains that purchases are not available in this version, the Buy button is disabled, and Restore purchases is hidden because there is nothing it could restore.

## What stays free

Reminders, text scanning (OCR), app lock, encrypted backup and restore (`.rgry`), and CSV import stay free. Records already on the device can always be viewed, edited, renewed, exported, and deleted on any plan.

## Free limits and over-limit data

- Free can create up to 10 documents and 5 subscriptions (`EntitlementPolicy`).
- Only a new record is checked. Editing an existing record keeps its id and is never blocked.
- A restored `.rgry` backup or a CSV import can leave the device above the Free limits. Nothing is deleted or hidden. The user cannot create another record of that type until Local Pro is active again or the count drops below the limit.
- When Local Pro is lost (refund, revocation, different store account) the same rule applies. Existing records stay readable, editable, and exportable.

## How ownership is decided

`LocalProEntitlement` (`lib/features/entitlements/local_pro_entitlement.dart`) owns the plan. `InAppPurchaseLocalProStore` (`lib/features/entitlements/in_app_purchase_store.dart`) is the only code that talks to `in_app_purchase`.

### Android (Play Billing)

- Buying uses `buyNonConsumable`. Nothing calls `buyConsumable` or `consumePurchase`; `local_pro` is never consumed.
- Only a purchase with Play `purchaseState` `PURCHASED` counts. `PENDING` never unlocks Local Pro and is never acknowledged. A cancelled or failed purchase stays Free.
- A `PURCHASED` purchase is acknowledged through `completePurchase`. If acknowledgement fails (for example the billing service disconnects), Local Pro stays on and the next query retries it. Play refunds a purchase that is not acknowledged within three days, so the retry runs on every launch, foreground, and Restore.
- On launch, on return to the foreground (at most every 30 seconds), and on Restore purchases, the app calls `queryPastPurchases` (Play `queryPurchasesAsync`). The answer for the signed-in Google account is the source of truth.

### iOS (StoreKit 2)

- Buying uses StoreKit 2 through `in_app_purchase_storekit`. A purchase update is not trusted by itself: the app reads ownership again from `Transaction.all`, which contains only transactions StoreKit verified on the device.
- A transaction with a `revocationDate` (refund or revocation) does not count. A payload that cannot be read does not count.
- Unfinished `local_pro` transactions are finished after ownership is confirmed.
- Restore purchases calls `AppStore.sync()` first (this can show the App Store sign-in), then reads `Transaction.all`.

### Unknown is not the same as not owned

| Store answer | Effect |
| --- | --- |
| Owned | Local Pro on. The time of this answer is saved on the device. |
| Not owned | Free. If Local Pro was on, it is turned off and the screen explains that the store no longer reports the purchase. The saved answer is cleared. |
| Pending only | Free. The screen says the store is waiting for payment. |
| Unavailable / error / timeout | Nothing changes. If the store confirmed Local Pro earlier on this device, Local Pro stays on ("active, not confirmed right now"). Otherwise Free, with "the store could not be reached". |

The saved answer is two values in `SharedPreferences` (`local_pro.store_confirmed_owned`, `local_pro.store_confirmed_at`). Only a store query writes it. It is not in the registry database and not in `.rgry` backups. It only lets a returning Local Pro user keep Pro while offline and keeps ads away while the store answers. It cannot turn Local Pro on for a device that the store never confirmed.

### Refunds

A refund or revocation is detected the next time the store answers "not owned": on launch, on return to the foreground, or on Restore purchases. A device that stays offline keeps Local Pro from its last store confirmation until it can reach the store. The app does not promise immediate refund detection.

## What this design does not do

- There is no backend. The app does not call the Google Play Developer API, the App Store Server API, Real-time Developer Notifications, or App Store Server Notifications. There is no server-side refund monitoring and no server-side receipt validation.
- All checks run on the device against the platform store client (Play Billing, StoreKit 2 verification). They are client checks. A modified app on a rooted or jailbroken device can bypass them. For a one-time unlock of local record limits, the product accepts that tradeoff instead of running a server.
- Android and iOS purchases are separate. A Google Play purchase does not unlock iOS, and an App Store purchase does not unlock Android.
- Restore works only with the same store account (Google account on Play, Apple Account on the App Store) and the same app identity (`com.residay.app` on Play; the App Store bundle id on iOS). A `.rgry` backup never carries Local Pro.
- There is no in-app switch, debug toggle, or hard-coded price. The price shown is the localized price returned by the store.

## Turning purchases on (future build)

Do this only after the products exist and the sandbox checklist in `docs/release/launch_checklist.md` passes.

```sh
flutter build appbundle --release --dart-define=PURCHASES_ENABLED=true
flutter build ipa --release --dart-define=PURCHASES_ENABLED=true \
  --dart-define=ADMOB_IOS_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

Every iOS release build needs a real iOS AdMob App ID while `google_mobile_ads` is linked, even with ads off (see "iOS release blocker" in `docs/setup/ads.md`).

The flag is a compile-time constant. It affects only builds made with it. It does not change an installed build.

### Google Play Console

1. App `com.residay.app` with a signed release uploaded to at least internal testing (Play Billing needs the app to be published to a track).
2. Monetize → Products → In-app products → create `local_pro`, set prices, activate it. It must be a one-time product, not a subscription.
3. Add license testers (Setup → License testing) for sandbox purchases.
4. `com.android.vending.BILLING` is already in `AndroidManifest.xml`.

### App Store Connect

1. App record for the iOS bundle id. The project currently uses `com.example.theRegistry`; set the real bundle id before creating the record. This task did not change it.
2. In-App Purchases → create a **Non-Consumable** with product id `local_pro`, pricing, localization, and review screenshot. Submit it with the first version that enables purchases.
3. Paid Apps agreement, tax, and banking must be active.
4. Create Sandbox Apple Accounts for testing. A StoreKit configuration file can be used for local Xcode testing but is not store acceptance.

## Tests

`test/local_pro_entitlement_test.dart`, `test/local_pro_screen_test.dart`, `test/entitlement_policy_test.dart`, and `test/ads_test.dart` use a scripted store boundary (`FakeLocalProStore` in `test/support/phase2_fakes.dart`) and the pure Play/StoreKit mapping functions. They are not Google Play or App Store sandbox acceptance. No real purchase, restore, or refund has been made against either store.
