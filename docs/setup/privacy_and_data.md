# Privacy and data

The Registry is local-first. There is no Registry server, cloud database, account, email sign-in, or recovery code.

## What stays on the device

| Data | Where |
| --- | --- |
| Documents, subscriptions, renewal history | SQLite database in app storage |
| Photos and attachments | App storage, referenced by the database; selected images are sent for AI scanning only after the user taps **Scan all images** |
| Fields returned by AI Scan | Returned by Gemini through Firebase AI Logic; shown in Review and saved only after the user confirms them and completes the normal Save flow |
| Reminders | Scheduled with the OS local notification service |
| Settings, onboarding, app lock preference | `SharedPreferences` |
| Last store answer about Local Pro | `SharedPreferences` (`local_pro.store_confirmed_owned`, `local_pro.store_confirmed_at`), written only from a store query |

App lock uses the device authenticator (Face ID, Touch ID, fingerprint, passcode). It hides the app; it does not encrypt the database.

## Moving data

The only way to move records to another device is the encrypted `.rgry` backup in Profile. The user chooses where the file goes (Files, Drive, AirDrop, and so on). The file contains documents, subscriptions, and attachments. It does not contain Local Pro state, purchase tokens, or store transactions, so restoring a backup never unlocks Local Pro. If the backup file or its password is lost, the data cannot be recovered by anyone, because there is no server copy.

## What talks to the network

- **Firebase AI Scan configured:** Firebase App Check verifies the app, then Firebase AI Logic sends the explicitly selected document images to Gemini when the user taps **Scan all images**. Regiday has no scanning server and the app contains no Gemini API key. Choosing or storing an image does not send it.
- **Firebase AI Scan not configured:** the scan action is disabled and manual entry remains available.
- **Purchases on (future build):** Play Billing or StoreKit, to load the `local_pro` price, buy, restore, and check ownership. The store sees its own account as usual. The app sends no registry data.
- **Ads on (future build), Free users only:** UMP (consent) and the Google Mobile Ads SDK. Google receives device and ad-related data according to the user's consent choices. No registry data is sent to ads.

## No-backend tradeoff

- Regiday has no account, document database, or custom scanning backend.
- Document images leave the device only when the user explicitly starts AI Scan or exports a backup to a destination they choose.
- There is no account recovery. A lost device without a backup means lost records.
- Local Pro is checked on the device against Play Billing or StoreKit only. There is no server-side receipt validation or refund monitoring (details in `docs/setup/local_pro_billing.md`).

## Store privacy forms

Answer them for the build being submitted:

- A Firebase AI-enabled build must disclose the user-initiated transfer of document images to Gemini through Firebase AI Logic and describe the purpose as extracting fields for user review. Confirm the current Google/Firebase data handling terms when completing Play Data safety and App Store privacy details.
- For an ads-off build, the Android merged manifest has no `AD_ID` permission. The Google Mobile Ads SDK is still linked on both platforms (never started), and the iOS build carries a real AdMob App ID in `Info.plist` because the SDK requires it (`docs/setup/ads.md`). The SDK's bundled privacy manifest therefore appears in Xcode's privacy report; reconcile it with the App Store answers before submitting.
- A build with ads on needs the Advertising ID declaration and ads data types (Play Data safety, App Store privacy details), plus the UMP messages described in `docs/setup/ads.md`.
