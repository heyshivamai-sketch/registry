# Phase 2B — Local Pro billing

**Date:** 28 September 2026
**Branch:** `feature/local-pro-billing`
**HEAD:** `f335091ac19cc04b891c315123bbc59f7f354582` (`docs: remove trailing whitespace from phase2a QA report`)
**Remote:** not pushed. Nothing in this phase was committed.

This correction pass compared the Flutter and server code with the current Play Billing and StoreKit rules. It did not commit, push, deploy, or set `storeVerificationConfigured`.

This pass did not clear emulator data, uninstall the app, deploy the billing server, create a store product, or change a developer-console setting. The debug APK and the iOS simulator app were built and not installed.

`BillingConfiguration.storeVerificationConfigured` is still `false`. No real Google Play or App Store purchase was made. The automated tests below mock the store and the server. They are not store verification.

Setup and the ownership model are in `docs/setup/local_pro_billing.md`. Placeholders only: `server/billing/.env.example`.

## What this phase does

- Local Pro stays a one-time non-consumable. The Flutter integration is `in_app_purchase` 3.3.1 with `in_app_purchase_android` 0.5.3. The app calls `buyNonConsumable` and `completePurchase`. It does not call `buyConsumable` or Play consume. Product id `local_pro` is configurable through `BillingConfiguration.localProProductId`. A price is shown only when the store query returns one and billing is ready.
- Billing is ready only when `storeVerificationConfigured` is true and the build also has a verification URL, a grant public key, and an environment of `sandbox` or `production`. The default constants leave this false. `openProductionBilling` returns null and does not construct the store plugin. Missing configuration does not invent a price or grant Local Pro.
- The app keeps an installation id outside the registry database and outside `.rgry` backups. At purchase that UUID is sent as `applicationUserName`. Play stores it as `obfuscatedExternalAccountId` and StoreKit 2 stores it as `appAccountToken`. Those fields are not the Google account or the Apple ID. Neither store sends that account to this server. The server grants only when the store record's UUID matches this installation. A valid purchase token or signed transaction from another installation is `binding_mismatch` and does not grant. A bare transaction id or order id is rejected.
- The restore code exists because there is no Registry account and the stores do not disclose who paid. A copied token would otherwise be enough to bind Local Pro to a new installation. The code is 16 characters from a 32-character alphabet, stored only as a peppered hash, rotated inside the database transaction when it is used, and refused after a cancel, refund, or revocation. The same installation does not need it.
- Restore purchases reads the current platform store and the server verifies that purchase again. Android uses Play `queryPurchases`. iOS calls `AppStore.sync()` and then the plugin reads `Transaction.currentEntitlements`. Restore does not change the UUID already stored on the purchase. After a reinstall, Local Pro stays off until that store transaction is verified again and the restore code moves the binding. A Play purchase does not unlock iOS, and an App Store purchase does not unlock Android.
- `server/billing` verifies Play purchases with the Google Play Developer API (`purchases.products.get` and `purchases.products.acknowledge`) and Apple transactions with `@apple/app-store-server-library` `SignedDataVerifier`. Those live clients are not what the tests call. Tests use `FakeGoogle` and `FakeApple`. Sandbox and production rows are separate. Processing is idempotent. Notification events are authenticated, ordered by event time, and a duplicate event id does not change the row. A Play lookup failure during a notification returns 503 and does not change the row. Google push auth in the server process also requires `email_verified`. Apple notifications keep the inner transaction JWS so a later revalidation can still see `revocationDate`. Play is acknowledged only after the active row is committed. The app does not acknowledge Play on a mismatch, a rate limit, or a server error. A lost response is retried from the on-device pending file on the next launch.
- The app caches the signed grant, not a boolean. A transport failure or HTTP 503 leaves that cache and does not rewrite documents or subscriptions. A verified revocation replaces the cache with an inactive grant and the plan returns to Free. Existing records can still be updated. A net-new document past the Free limit is still refused.
- Opening Local Pro from a document draft pushes a route on top of the form. Dismissing it leaves the draft text in place. The Local Pro screen does not offer cloud sync, cloud backup, or an account.

Application id `com.registry.app` and bundle id `com.example.theRegistry` are unchanged. The bundle id still has to be decided before an App Store Connect app is created. `com.example` may be rejected, and an Apple bundle id cannot be changed after the first upload.

## Automated results

Run on 28 September 2026 from this working tree, one Flutter command at a time, after the correction pass.

| Command | Result |
| --- | --- |
| `node --test --test-timeout 15000 --experimental-strip-types test/billing.test.ts` in `server/billing` | **Passed.** 15 tests, 0 failed. Node printed the expected experimental `node:sqlite` warning. |
| `npx tsc --noEmit` in `server/billing` | **Passed.** Exit 0. |
| `flutter analyze` | No issues found (3.1s). |
| `flutter test test/local_pro_billing_test.dart` | **Passed.** 15 tests. |
| `flutter test` (one full suite) | **Passed.** `00:15 +298: All tests passed!` |
| `git diff --check` | Clean (exit 0). |

This correction pass did not rebuild or install the debug APK or the iOS simulator app. The 27 September builds were not repeated and were not installed then either. Their Gradle and CocoaPods warnings were not rechecked.

The full Flutter suite includes `test/local_pro_billing_test.dart`, `test/local_pro_screen_test.dart`, and `test/entitlement_policy_test.dart`. The billing file states at the top that its store and server boundaries are fakes.

### What the fakes cover

These are not Play Console, App Store Connect, or a live `SignedDataVerifier` call.

| Case | Where it was checked |
| --- | --- |
| Invalid signature | Dart `proofFromSignedGrant` rejects a 64-byte signature that does not match the canonical grant. |
| Wrong product, application, environment | Server tests reject them and do not write a row. The app ignores a signed grant whose environment is not the build environment, and it ignores a store update for another product id. |
| Pending purchase | App outcome is pending. `completePurchase` is not called. Server pending does not grant. |
| Cancellation | Store canceled status and an error code containing "cancel" finish the transaction and do not verify. Server cancellation does not grant. |
| Duplicate callbacks | A second in-flight update for the same purchase does not call verify again. Server verify is idempotent and keeps the same restore code. Duplicate notification ids do not change the row. |
| Restart and retry | If `completePurchase` throws after a verified grant, the next launch finishes that purchase and does not verify it again. A failed Play acknowledgement stays unacknowledged and the next verify retries it. |
| Restore | Restore posts `/v1/purchases/restore` with the token or JWS from the store update. A different installation is `binding_mismatch` until the restore code matches. The server test moves the binding only with that code, then rejects the same code on replay and on a second use. iOS `AppStore.sync()` is called from `InAppPurchaseBillingPlugin.restorePurchases` before the plugin reads current entitlements. That call was not executed against the App Store. |
| Refund / revocation | An inactive signed grant sets the plan back to Free. `documents.update` still edits an existing record. `RegistryWrites.createDocument` throws `EntitlementDenied` at the Free document limit. Server tests apply a newer refund, ignore a stale one, refuse the restore code after `purchaseState` 1, and revoke when `refundableQuantity` is 0. A wrong product on revalidation does not mint a new active grant. |
| Copied token | A valid Play token submitted with another installation id returns 409 and does not grant, including after the purchase is revoked. |
| Acknowledgement | HTTP 429 does not call `completePurchase` and leaves the cached grant and the pending token in place. The next `warmUp` verifies that stored token without a new store delivery. Apple binding mismatch finishes the queue. Play binding mismatch does not acknowledge. |
| Temporary backend failure | HTTP 503 and an unreachable client leave the cached grant unchanged and do not finish the transaction. Server revalidation of a down store leaves the purchase row unchanged. |
| Client premium flag | The verify body sent by the app coordinator has no `premium` field. The server test ignores a client premium claim. |
| Play token, no consume | `GooglePlayPurchaseDetails` uses `purchaseToken`, not the other verification string. The adapter records only `buyNonConsumable`. The server test asserts the Google client source has no `:consume` URL. |
| Backup | Encoded `.rgry` payload version stays 1 and the bytes do not contain `installationId`, `purchaseToken`, `recoveryCode`, or `signedTransaction`. |
| Unconfigured app | `ProductionStoreProductSource` returns null. `ProductionPurchaseService` returns an unavailable attempt. `openProductionBilling` returns null. A client-supplied accepted proof does not change the plan. The Local Pro screen test still finds no price and a disabled buy button. |
| Draft | Typing a document name, pushing Local Pro, and popping it leaves "Passport draft" on the add-document form. |

## What was not verified

- No purchase, restore, refund, or notification was sent to Google Play or the App Store.
- `createGooglePlayClient` and `createAppleVerifier` were not called with real credentials. Company developer accounts and store products are not available.
- The billing server was not deployed. No sandbox or production URL was configured in the app.
- The debug APK and the simulator build were not rebuilt or installed in this correction pass, so there is no device screenshot of a store price, a purchase sheet, or a restore code.
- A license-tester purchase, a Sandbox Apple ID purchase, a force-stop during the purchase sheet, a reinstall restore-code move, `AppStore.sync()` against Apple, and a real refund notification were not run.
- `email_verified` is checked in `server/billing/src/index.ts`. The automated tests use a fake authorizer, so they do not exercise Google's OIDC library.

## Account-bound transfer rule

Checked on 28 September 2026 on `feature/pro-account-recovery`. This is the server and Flutter behavior in the working tree. `BillingConfiguration.storeVerificationConfigured` is still `false`. No store purchase was made.

An account-bound purchase (`purchases.account_id` set) moves to another installation only when Restore purchases carries a session for that same account and the server accepts a current store entitlement. A recovery code with no session returns `409` `{ "result": "account_sign_in_required" }` and does not change the row. A session for a different account does the same, including when it also sends the current recovery code. The response body has no email and no account id. The Local Pro screen shows that the person must sign in with the owning email and restore again, and that the restore code alone does not move the purchase. Local Pro stays off.

An installation-only purchase (`account_id` null) still moves with its current recovery code plus a store entitlement the server accepts. It becomes account-bound only on restore when that request also has a valid session, the current recovery code, and a purchased store result. The same installation keeps its installation id and restore-code hash and returns `accountLink: linked`. A different installation moves and rotates the code. Signing in without the code does not set `account_id`.

The owning session can move the purchase. A second restore on that new installation returns the grant and does not rotate the code again. Replaying either the old or the new recovery code without that session does not move it. A refund marks the row revoked; the recovery code does not grant it again. Deleting the account revokes its sessions, sets `account_id` to null, and leaves the store entitlement on the current installation. The same email can be verified again as a new account id. That account does not inherit the purchase. The current recovery code plus a verified store entitlement can move it, and the same restore with the new session links that new account.

Server coverage is in `server/billing/test/accountRecovery.test.ts` (`moves an account-bound purchase only for that account session`, the refund test, and the deletion test). The Flutter restore message is in `test/local_pro_billing_test.dart`.

Sequential check on 28 September 2026, after this rule change: server tests 26 passed, 0 failed; `tsc --noEmit` passed; `flutter analyze` reported no issues; `flutter test test/local_pro_billing_test.dart test/local_pro_screen_test.dart` passed 23 tests; `flutter test` passed 303 tests.

## Remaining blockers

An installation-only purchase still needs its recovery code. An account-bound purchase needs the owning account's session, and this server cannot send that verification email until a real `EmailDelivery` provider is configured. Store acceptance is still required before enabling purchases.

- Play Console app for `com.registry.app`, one-time product `local_pro`, license testers, Play Developer API service account, and Pub/Sub push for real-time developer notifications.
- Decision on the iOS bundle id before creating the App Store Connect app. Current value remains `com.example.theRegistry`.
- App Store Connect non-consumable `local_pro`, Paid Applications agreement, App Store Server API key, Apple root certificates, Sandbox Apple ID, and Server Notifications V2 URLs.
- A deployed `server/billing` with the values from `server/billing/.env.example` replaced on the server only. Generate the grant key there. Do not commit it.
- `BillingConfiguration.storeVerificationConfigured` stays false until the sandbox checklist below has evidence from a real store. A URL and public key alone are not enough, and the flag alone is not enough: `BillingRuntime.isReady` requires the flag, the URL, the public key, and `sandbox` or `production`.

## Release-enablement checklist

Do not check these from the mocked tests. The steps are the sandbox checklist in `docs/setup/local_pro_billing.md`.

- [ ] Play product `local_pro` exists for `com.registry.app` and is a one-time product, not a subscription.
- [ ] App Store product `local_pro` exists for the chosen bundle id and is a non-consumable. Family Sharing stays off.
- [ ] Server credentials, grant key, token key, and restore-code pepper exist only on the server.
- [ ] A build that points at the server but still has `storeVerificationConfigured` false shows no price and Buy does not grant.
- [ ] A sandbox build with the flag true, the sandbox public key, and the server URL shows the store-localized price.
- [ ] A license-tester or Sandbox Apple ID purchase returns a signed grant and turns Local Pro on for that installation only.
- [ ] Force-stop during purchase, then relaunch, verifies the transaction once and finishes or acknowledges it. Play does not show it as consumed.
- [ ] Restore purchases on the same installation reads the platform store, the server verifies that purchase again, and Local Pro stays active without the restore code.
- [ ] A reinstall stays Free until Restore purchases returns the store transaction and the server accepts it. An account-bound purchase moves only for a session of that same account. A recovery code alone, or another account, does not move it and does not reveal the owner's email. An installation-only purchase still needs its current recovery code, and it becomes account-bound only when that code is restored with a verified session. A copied token without that proof does not grant. The old installation loses Local Pro on its next successful revalidation. Records are not deleted.
- [ ] A refund or revocation turns Local Pro off. Existing records can still be edited, exported, and restored. A new record past the Free limit cannot be added.
- [ ] A Play purchase does not unlock the iOS app, and an App Store purchase does not unlock Android.
- [ ] Only after that evidence, a production build may set `storeVerificationConfigured` to true.
