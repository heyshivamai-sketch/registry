# Local Pro billing

Local Pro is a one-time, non-consumable purchase of higher local record limits. It does not include cloud sync, cloud backup, or a transfer of a purchase from Android to iOS. The app can be used with no account. An optional verified email can be used only to recover a Local Pro purchase on a new installation of the same store.

`BillingConfiguration.storeVerificationConfigured` stays `false` in the default build. Until that flag is changed after a real store verification, the app does not show a price and does not grant Local Pro. This document is the setup and the ownership model. It is not evidence that a purchase was verified.

## Entitlement ownership

The app can be used locally with no sign-in. An optional email is not a Google account or an Apple ID, and it does not sync records. Google Play and the App Store decide which signed-in device can see a purchase. They do not tell this server the Google account or the Apple ID. Nothing in the Play Developer API response or the Apple signed transaction is that account.

### What the server actually checks

A grant is issued only after the store API accepts the purchase for this app.

- Google: `purchases.products.get` for package `com.registry.app` and product `local_pro`, using the purchase token from Play Billing on the device. `purchaseState` 0 is purchased. `purchaseState` 2 is pending and does not grant. `purchaseState` 1 (canceled) revokes. `refundableQuantity` 0 revokes. `consumptionState` 1 is rejected. `purchaseType` 0 is sandbox. A missing `purchaseType` is a normal production purchase. `purchaseType` 1 (promo) is treated as production. `purchaseType` 2 (rewarded) is rejected. The server never calls `purchases.products.consume`.
- Apple: `SignedDataVerifier` on the StoreKit 2 transaction JWS. The transaction must have bundle id `IOS_BUNDLE_ID`, product `local_pro`, type Non-Consumable, `inAppOwnershipType` exactly `PURCHASED`, environment Sandbox or Production matching the request, and no `revocationDate`. A missing ownership type does not grant. Family Sharing (`FAMILY_SHARED`) does not grant.
- The installation id inside the store record is not a store account. At purchase the app sends its own UUID v4 as `PurchaseParam.applicationUserName`. Play stores that as `obfuscatedExternalAccountId`. StoreKit 2 stores it as `appAccountToken`. The server compares that field with the installation id on the request. A caller-supplied installation id is ignored when it does not match.

### What is not a credential

A purchase token, order id, or transaction id is not by itself a way to turn on Local Pro for an arbitrary installation.

- There is no field in the app for pasting a receipt, order id, or token.
- `POST /v1/purchases/verify` rejects a bare transaction id. Apple verification requires the signed transaction (JWS). Google verification requires the purchase token returned by Play Billing on that device. An order id alone is not accepted.
- A caller who presents a valid token or JWS with a different installation id receives `binding_mismatch` and no grant. The response does not include the installation id that holds the binding.
- Tokens, signed transactions, service-account keys, and restore codes are redacted from logs.
- Registry backup files (`.rgry`) contain documents and subscriptions only. They do not contain the plan, the installation id, the grant, the purchase token, the transaction id, or the restore code. Restoring a backup does not grant Local Pro and does not remove records to fit the Free limits.
- A signed grant copied onto another installation fails the installation-id check. A client premium flag, a debug switch, and an unauthenticated webhook do not grant or extend Local Pro.

### Installation binding

On first launch the app creates an installation id (UUID v4) outside the registry database. That id is the value stored by the store, as described above. It is not the Google account and it is not the Apple ID.

The first verified purchase for a store purchase key is bound to that installation id. The same installation can verify again (idempotent). Another installation cannot reuse the token or JWS alone.

The server returns a grant signed with the server Ed25519 key. The grant names the installation id, product id `local_pro`, platform, environment (`sandbox` or `production`), and status. The app applies it only when the signature checks out, the installation id matches this install, the product id matches, the environment matches the build that is allowed to accept it, and store verification is configured. A client-written premium flag is ignored.

Sandbox and production rows are separate. A sandbox grant does not satisfy a production check, and the reverse is also refused.

### Why a restore code exists

The stores do not disclose the Google account or Apple ID, so the server cannot tell a reinstall of the same store customer from someone who copied a purchase token or a signed transaction. Those values are bearer secrets. Binding the purchase to the installation UUID that was sent at purchase time stops a copied token from granting a different installation.

For a purchase that is not linked to a verified email, the one-time restore code is still the credential that moves that binding. It is not a store account, and it is not a receipt. The code is 16 characters from a 32-character alphabet (about 80 bits), stored only as a peppered SHA-256 hash, and compared in constant time. A successful move rotates the hash inside the database transaction, so the same code cannot be replayed or used a second time. A canceled, refunded, or revoked purchase does not move: the existing row is marked revoked and the caller gets `binding_mismatch` with no grant. Wrong codes share the restore rate limit (10 requests per minute per IP) and do not grant. Guessing the code is not practical.

Losing the code for a purchase that was never linked to a verified email means this service cannot move Local Pro onto a new installation id. That is the limit of having no store identity. It is not evidence that the server can see the Google account or Apple ID.

### Optional verified email

A person can verify an email before buying. The purchase UI says that verification has to happen first, and that the email does not turn on Local Pro. Confirming the code returns a session. It does not write a purchase and it does not return a grant.

- A new purchase is linked to that account only when the request carries a valid session and the store API accepts the purchase for this installation. A client `accountId`, `premium` flag, or `sessionToken` in the JSON body is ignored. The session is taken only from the `Authorization` header.
- After sign-in on a new installation, Restore purchases reads the current store entitlement (Play `queryPurchases` or StoreKit `Transaction.currentEntitlements`) and posts it to `POST /v1/purchases/restore`. The server calls the store again. A purchase already bound to a verified account moves only when that request carries a session for the same account and the store still says the purchase is purchased. Repeating that restore on the new installation is idempotent and does not rotate the restore code again.
- A recovery code alone does not move an account-bound purchase. A session for a different account does not move it either, including when that caller also sends the current restore code. The server returns `409` with `{ "result": "account_sign_in_required" }` and does not change the row. That body has no email and no account id. The purchase screen tells the person to sign in with the email that owns the purchase and restore again.
- Email verification alone, a copied `.rgry` backup, a client flag, and a submitted transaction id do not grant.

### How an installation-only purchase becomes account-bound

A purchase is installation-only while `purchases.account_id` is null. That is a purchase verified with no session, including one made before accounts existed, and a purchase whose account was later deleted. Deletion sets `account_id` to null. It does not revoke the store entitlement and it does not rotate the restore code.

That purchase becomes account-bound only on `POST /v1/purchases/restore` when all of the following are true:

1. The `Authorization: Bearer` session is valid for the account that should own it.
2. The request includes the current restore code, and that code matches the stored hash.
3. The server checks the purchase token or signed transaction with the store, and the store reports the purchase as purchased.
4. The row is still active and is not already bound to an account.

On the same installation, the server sets `account_id`, leaves the installation id and the restore-code hash in place, and returns `accountLink: linked`. On a different installation, it also moves the installation id and rotates the restore code. Signing in and restoring without the code does not set `account_id`. Another installation gets `recovery_code_required`. The same installation gets `accountLink: unchanged`. There is no silent rebind.

After that link, the restore code is no longer enough to move the purchase. The next move requires the owning account's session and another current store check, as described above. Deleting the account returns the purchase to the installation-only rule, so the current restore code plus a verified store entitlement can move it again. Verifying the same email afterward creates a new account id. That account does not inherit the purchase. Linking it uses the same four steps, and the new account id is not the deleted one.

- Android and iOS stay separate rows. Restoring a Play purchase does not move an App Store purchase, and the reverse is also refused.
- A refund or revocation still removes Local Pro. A signed-in restore of a revoked purchase returns an inactive grant for that account and does not grant again.
- If the grant response is lost after the server commits, the next restore with the same session sees the installation already recorded and returns the grant without another code. If a verification response is lost, the code is already consumed and the person requests a new code. The server does not keep a plaintext copy it can show again.
- Offline use of an already cached signed grant is unchanged. A failed account request does not clear that cache and does not claim that a code was sent.
- Deleting the account revokes its sessions and clears `account_id` on its purchases. It does not refund the store, does not revoke the current installation, and does not grant. The purchase falls back to the restore code. Signing in again with the same email creates a new account that does not inherit the old purchase.
- Verification codes and session tokens are stored only as hashes on the server. The app keeps the session token in `account_session.json` next to the installation id, outside the registry database. `.rgry` backups do not contain the session, the code, or purchase credentials. Logs redact those values and the server does not write the code or the token into log lines.

The session lasts 30 days. A verification code lasts 15 minutes and accepts 5 attempts. Start is limited to 5 requests a minute per IP and 3 per email hash. Confirm and delete are limited to 10 a minute per IP.

### Reinstall and restore

Restore purchases obtains the transaction from the platform store on this device and the server verifies it again. The app does not accept a typed token. The product is never consumed.

- Android: `restorePurchases` calls Play Billing `queryPurchases` for in-app products and sends the purchase token to `POST /v1/purchases/restore`. Passing a new installation id on restore does not change the `obfuscatedExternalAccountId` already stored on the purchase.
- iOS: before reading transactions, the app calls StoreKit 2 `AppStore.sync()`, then the plugin reads `Transaction.currentEntitlements` and sends each transaction JWS to the same restore endpoint. Restore does not change the original `appAccountToken`. A dismissed App Store sign-in prompt does not grant and does not clear a cached grant. Entitlements already on the device are still submitted for verification.
- Same installation (app data still present): the store record's installation id matches, so restore or the next launch re-verifies and refreshes the signed grant. No restore code is required.
- Purchase still pending in the store: Local Pro stays off. The unfinished purchase is kept locally and retried. A temporary verification failure, including HTTP 429 or 503, does not change the cached grant and does not change documents or subscriptions.
- Server timeout or app restart: the purchase token or JWS is kept outside the registry database. The next launch sends it to the server again even if Play does not redeliver an already acknowledged purchase. If the grant was saved and `completePurchase` failed, the next store delivery finishes the transaction and does not verify it a second time. Duplicate callbacks are idempotent.
- Reinstall or cleared app data: a new installation id is created. The store can still return the non-consumable, and the server verifies that purchase again. The UUID on the store record is still the old installation id. If the purchase is bound to a verified account, Restore purchases moves it only after sign-in with that same account; the restore code alone returns `account_sign_in_required` and leaves the row unchanged. If it is not bound, the server does not grant until the same restore request includes the current restore code, and signing in does not attach the purchase by itself. After a successful move, a new code is returned for the new installation and the previous installation loses Local Pro on its next successful revalidation. Records on either device are not deleted.
- Android and iOS are not transferable. A Play purchase is not an App Store purchase. Restore on iOS will not honor a Play token, and Restore on Android will not honor an App Store transaction.

### Offline cache and revalidation

The cache stores the signed grant, not a boolean. While verification is not configured, the cache is not applied.

When verification is configured:

- A valid active grant is used so the plan can stay Local Pro while the device is offline.
- The app tries to revalidate about 24 hours after the last verification, and again on launch when that time has passed.
- If the network fails, or the server returns HTTP 429 or 503, the cached grant is left as it is. Registry records are not deleted or rewritten because verification failed.
- A store response that does not prove revocation (for example a product id the server does not sell) does not mint a new active grant and does not extend `revalidateAfter`.
- A verified refund, revocation, or binding move replaces the cache with a signed inactive grant and the plan returns to Free. A consumed purchase, a non-purchased ownership type, or a purchase state the server does not accept also replaces the cache with an inactive grant on the next successful revalidation.
- Losing Local Pro does not block viewing, editing, renewing, deleting, reminders, export, or restore of records that already exist. Only a net-new document or subscription past the Free limits is refused. No record is deleted because the plan changed.

### Refunds and notifications

Google Play Real-time developer notifications and App Store Server Notifications V2 are authenticated, then applied in event-time order. A duplicate notification id is stored once. An older event does not overwrite a newer status. A notification that cannot be authenticated does not change a row. Google push authentication checks the OIDC audience, the service-account email, and `email_verified`. Apple notifications are accepted only after `SignedDataVerifier` accepts the signed payload. If the store API cannot be reached, or a Play lookup fails while handling a notification, the row is left unchanged and the handler returns HTTP 503 so the notification is retried. An Apple signature failure returns HTTP 401.

Play notifications store the purchase token. Apple notifications store the inner transaction JWS (`signedTransactionInfo`), not the outer notification payload, so a later revalidation can still read `revocationDate`. A voided or canceled Play notification, and an Apple `REFUND` or `REVOKE`, mark the bound row revoked even when the caller is not that installation. They do not grant the presenter.

Acknowledgement means the entitlement was delivered. The server calls Play `purchases.products.acknowledge` only after the active row is committed, and retries when that call fails. The app calls `completePurchase` only after the signed grant is stored on the device. Play is not acknowledged for a binding mismatch, a rate limit, or a server error. User cancellation is finished so the store sheet can close. On Apple, a binding mismatch or an invalid transaction is finished so `Transaction.updates` does not repeat it; `Transaction.currentEntitlements` still returns the non-consumable, and Restore can submit it again with the restore code. A pending purchase and a temporary verification failure are not finished. The server never calls `purchases.products.consume`. StoreKit transactions are finished locally after the grant is stored; the signed transaction is verified with Apple's server library.

## Identity decisions required before store setup

Do not change these in the app until the store records exist for the new values. This phase leaves them as they are.

| Item | Current value | Decision |
| --- | --- | --- |
| Android application id | `com.registry.app` | Keep. The Play Console app must be created with this id. It cannot be changed after the app is published. |
| Android label | `the_registry` | Keep until a brand is approved. |
| iOS bundle id | `com.example.theRegistry` | **Decide before creating the App Store Connect app.** Apple bundle ids cannot be changed after the first upload. `com.example` is a sample prefix and may be rejected. This phase does not change it. |
| iOS display name | `The Registry` | Keep until a brand is approved. |
| macOS bundle id | `com.example.theRegistry` | Not used for this purchase. Same decision as iOS if macOS is ever sold. |
| Product id | `local_pro` | Proposed for both stores. Confirm before creating the products. Apple product ids are permanent. The id must match `LOCAL_PRO_PRODUCT_ID` on the server. It is a one-time product on Play and a non-consumable on the App Store, not a subscription. |
| Regiday | not approved | Do not rename the application id, bundle id, or store listing for that name in this phase. |

## Google Play

Company Play Console access is required. None of these steps were done in this phase.

1. Create the Play Console app with application id `com.registry.app`.
2. Complete the app's Play App Signing setup. Billing tests need a build uploaded to an internal testing track. Use the same application id. Do not change it in `android/app/build.gradle.kts`.
3. In Monetize > Products, create a one-time product (not a subscription) with product id `local_pro`. Activate it and set a price in Play Console. The app reads the localized price from Play Billing. Do not hard-code a price.
4. Add license testers for sandbox purchases.
5. In Google Cloud, select or create a project, enable the Google Play Android Developer API, and create a service account. Do not put the JSON key in the app or in git.
6. In Play Console > API access, link that Cloud project and grant the service account permission to view financial data and manage orders (enough for `purchases.products.get` and `purchases.products.acknowledge` on package `com.registry.app` and product `local_pro`).
7. Create a Pub/Sub topic for Real-time developer notifications and a push subscription whose audience and service account match `GOOGLE_PUBSUB_AUDIENCE` and `GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL`. Point the push endpoint at `https://<billing-host>/v1/notifications/google`.
8. Deploy `server/billing` with the placeholders in `server/billing/.env.example` replaced by the real values on the server only.

The server treats Play `purchaseState` 0 (purchased), product `local_pro`, package `com.registry.app`, and a matching installation id in `obfuscatedExternalAccountId` as the success case. That field is the UUID the app sent. It is not the Google account. `purchaseType` 0 is sandbox. A missing `purchaseType` is production. `purchaseType` 1 is a promo purchase and is treated as production. `purchaseType` 2 is rejected. `purchaseState` 2 is pending and does not grant. `purchaseState` 1, `refundableQuantity` 0, or an authenticated voided-purchase notification revokes. The server never consumes the product.

## App Store

Company App Store Connect access is required. None of these steps were done in this phase.

1. Resolve the bundle id decision above. The app currently uses `com.example.theRegistry` (`ios/Runner.xcodeproj/project.pbxproj`).
2. Create the app record with that bundle id. Accept the Paid Applications agreement and enter tax and banking.
3. Create a non-consumable in-app purchase with product id `local_pro` and a price. Do not create it as a consumable or a subscription. Leave Family Sharing off. This service grants only `inAppOwnershipType` `PURCHASED`.
4. Create a Sandbox Apple ID under Users and Access > Sandbox.
5. Create an App Store Server API key. Record the issuer id, key id, and the `.p8` contents in the server environment only.
6. Download the Apple root certificates from [Apple PKI](https://www.apple.com/certificateauthority/) and set `APPLE_ROOT_CA_DIR` to that directory on the server. The server verifies signed transactions and notification payloads with `@apple/app-store-server-library` (`SignedDataVerifier`). Production verification also needs the numeric App Apple ID (`APPLE_APP_APPLE_ID`).
7. Set the App Store Server Notifications V2 production and sandbox URLs to `https://<billing-host>/v1/notifications/apple`.
8. The iOS app uses StoreKit 2 through Flutter `in_app_purchase` (default for the generic API). No extra usage-description string is required for purchases. Enable the In-App Purchase capability on the App ID when the developer account exists.

The server requires product id `local_pro`, bundle id equal to `IOS_BUNDLE_ID`, type Non-Consumable, `inAppOwnershipType` `PURCHASED`, no `revocationDate`, and an `appAccountToken` equal to the installation id. `appAccountToken` is the UUID the app sent. It is not the Apple ID. Sandbox and Production are verified separately. A revoked or refunded transaction removes Local Pro.

## Server

There was no existing backend in this repository. The service is `server/billing` (Node.js 24, TypeScript).

```sh
cd server/billing
npm install
npm test
npm run check
```

Copy `server/billing/.env.example` to a server-side env file. Replace placeholders there. Do not commit real values.

| Variable | Purpose |
| --- | --- |
| `PORT` | Listen port. |
| `DATABASE_PATH` | SQLite file for purchases, notification ids, and rate buckets. |
| `ANDROID_PACKAGE_NAME` | Must stay `com.registry.app` until the identity decision changes the app. |
| `IOS_BUNDLE_ID` | Must match the iOS bundle id in the app. |
| `LOCAL_PRO_PRODUCT_ID` | `local_pro` unless the product id decision changes both stores and the app. |
| `BILLING_GRANT_PRIVATE_JWK` | Ed25519 private JWK used only to sign grants. Generate on the server. |
| `BILLING_GRANT_PUBLIC_KEY_B64` | Raw 32-byte public key, standard base64. The app build must contain this before grants can be applied. Not a secret. Still do not flip the app flag until a real purchase verifies. |
| `BILLING_TOKEN_KEY_B64` | 32-byte AES-256-GCM key for purchase tokens stored for acknowledgement retry. |
| `RECOVERY_CODE_PEPPER` | Server pepper for restore-code hashes and email-code hashes. |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Full service-account JSON. Placeholder in the example. Server only. |
| `APPLE_ISSUER_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` | App Store Server API key. |
| `APPLE_ROOT_CA_DIR` | Directory of Apple root CA certificates. |
| `APPLE_APP_APPLE_ID` | Required for the production Apple verifier. |
| `GOOGLE_PUBSUB_AUDIENCE` | OIDC audience for the Pub/Sub push subscription. |
| `GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL` | Expected email on that OIDC token. |
| `REVALIDATE_AFTER_HOURS` | Grant lifetime hint before the app should revalidate. Default 24. |

Generate a grant key on the server (do not commit the output):

```sh
node --experimental-strip-types -e "import { generateGrantKeyPair } from './src/grantKeys.ts'; console.log(JSON.stringify(generateGrantKeyPair(), null, 2))"
```

Run from `server/billing`. Put the private JWK in `BILLING_GRANT_PRIVATE_JWK`. Put `publicKeyB64` in the app only when a deployment build is allowed to verify grants, and keep `storeVerificationConfigured` false until the sandbox checklist below has passed.

Migrations run on startup (`schema_migrations`). The first migration creates `purchases`, `notification_events`, and `rate_buckets`.

Endpoints:

| Method and path | Role |
| --- | --- |
| `GET /health` | Process is up. No store call. |
| `POST /v1/accounts/verification/start` | Ask the email provider to send a code. Does not grant. |
| `POST /v1/accounts/verification/confirm` | Check the code and return a session. Does not grant. |
| `POST /v1/accounts/delete` | Revoke sessions and unlink purchases. Does not grant or revoke the store purchase. |
| `POST /v1/purchases/verify` | Verify a new or retried purchase. A verified session may link a new purchase. |
| `POST /v1/purchases/restore` | Verify a store restore. May include a restore code when the installation id changed. |
| `POST /v1/entitlements/revalidate` | Re-check a bound purchase. Does not accept a client premium flag. |
| `POST /v1/notifications/google` | Authenticated Play RTDN. |
| `POST /v1/notifications/apple` | Apple notification V2 signed payload. |

Verify and restore bodies are limited to 16 KiB. Notification bodies are limited to 256 KiB. Verify is limited to 30 requests per minute per IP. Restore-code attempts are limited to 10 per minute per IP. Over-limit requests are refused and do not change rows.

Store credentials stay in this process. The app receives a signed grant only.

## App configuration

The Flutter integration is `in_app_purchase` 3.3.x (Flutter team plugin). Android uses `in_app_purchase_android` (Play Billing). iOS uses `in_app_purchase_storekit` with StoreKit 2 by default. Local Pro calls `buyNonConsumable` only. It does not call `buyConsumable`.

Prices come from `queryProductDetails`. If the store returns no product, or verification is not configured, the screen shows that the price is unavailable and the buy button does nothing.

`lib/features/entitlements/billing_configuration.dart` keeps `storeVerificationConfigured` false. A future deployment build may set it true only after all of the following are true:

- Play product and App Store product exist and a sandbox purchase has been verified by this server (see the QA checklist).
- `BillingRuntime` has the verification base URL, the grant public key, and the environment (`sandbox` or `production`) for that build.
- The server environment variables above are set on the server, not in the app.

Missing any of those must not show a stand-in price and must not grant Local Pro. Debug purchase simulations stay in tests and `DebugQa*` types. Production startup does not construct those types.

## Sandbox test after credentials exist

Do this before changing `storeVerificationConfigured`. Do not treat mocked tests as this checklist.

1. Install a build that points at the deployed server and the sandbox environment, still with the flag false, and confirm the price is hidden and Buy does not grant.
2. Set the flag true only in that sandbox build, with the sandbox public key and server URL.
3. On a license tester (Play) or Sandbox Apple ID, buy `local_pro`. Confirm the store-localized price, then a signed grant, then Local Pro on that installation only.
4. Force-stop the app during the purchase sheet and on the next launch confirm the transaction is verified once and finished or acknowledged. Confirm Play does not show the purchase as consumed.
5. Tap Restore purchases on the same installation. Confirm the store returns the purchase, the server verifies it again, and Local Pro stays active without the restore code.
6. Confirm a second device, or a reinstall, stays Free until Restore purchases returns the store transaction and the server accepts it. If the purchase is bound to a verified account, sign in with that same account first. A restore code alone, or a different account, returns `account_sign_in_required` and does not move it. If the purchase is installation-only, the current restore code is required; signing in does not move it, and the purchase becomes account-bound only when that code is sent with the session. The old installation loses Local Pro on its next successful revalidation. Records are not deleted. A copied purchase token, a verified email alone, or a transaction id does not grant.
7. Refund or cancel the sandbox purchase. Confirm the notification or the next revalidation turns Local Pro off and that existing records can still be edited, exported, and restored.
8. Confirm a Play purchase does not unlock the iOS app.

Only after that evidence should a production build set `storeVerificationConfigured` to true.
