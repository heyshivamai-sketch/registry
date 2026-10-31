# Firebase AI Logic document scanning

Regiday sends document images directly from the Flutter app through the
Firebase AI Logic SDK. There is no custom scanning server and no Gemini API key
in the app. Firebase AI Logic keeps the Gemini credential behind its proxy and
uses Firebase App Check to authorize the installed app.

The source screen accepts one primary image and up to five optional images.
Nothing is sent when an image is selected. **Scan all images** sends every side
in one request. The structured response always opens in Review and is never
saved automatically. Empty or uncertain values, including an absent expiry
date, stay empty for the user to confirm or enter manually.

## One-time Firebase setup

1. Install the Firebase CLI and FlutterFire CLI, then sign in:

   ```sh
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```

2. Create or select the production Firebase project in the Firebase console.
   From this repository root run:

   ```sh
   flutterfire configure --project=regiday-b1f5b --platforms=android
   ```

   This task configures Android only and leaves the existing iOS app and
   Firebase options unchanged. Select or register this app identifier when
   prompted:

   - Android package: `com.ventrovatech.residay`

   The command generates the Android options in `lib/firebase_options.dart`,
   `android/app/google-services.json`, and the Android FlutterFire metadata from
   the Firebase project. It does not update the existing iOS options. These
   values are not a Gemini API key.

3. In **Firebase console > Build > Firebase AI Logic**, click **Get started**.
   Choose **Gemini Developer API**, finish the guided setup, and let it enable
   the required APIs. Do not create, copy, or pass a Gemini API key to Flutter.
   The app currently uses `gemini-3.8-flash`, the current stable model in the
   Firebase guide; its Standard tier supports no-cost usage on Spark. Do not
   enable billing. A temporary model override is possible with
   `--dart-define=FIREBASE_AI_MODEL=MODEL_NAME`.

4. In **Firebase console > Security > App Check > Apps**, register the Android
   app:

   - Android: in **Play Console > Release > App integrity > Play Integrity
     API**, link the same Google Cloud project used by Firebase. Register
     **Play Integrity** in Firebase App Check with the release signing
     certificate's SHA-256 fingerprint. Enable **Meets basic device integrity**
     only if the chosen App Check policy requires it. The app uses Play
     Integrity in release builds.

5. In **Security > App Check > APIs > Firebase AI Logic**, set **Baseline
   protection** to **Enforced**. The app already requests limited-use App Check
   tokens, so enable **Replay protection** after verified requests appear in
   the App Check metrics. Firebase's guided AI Logic setup now enforces App
   Check, and enforcement becomes mandatory on 2 November 2026.

6. Restrict the Firebase API key in Google Cloud Console to the Android
   package and SHA-1 fingerprint. Keep the Firebase AI Logic API
   (`firebasevertexai.googleapis.com`) allowed for this Firebase key. These are
   Firebase project identifiers used by the SDK; do not add a separate Gemini
   API key.

## Local debug setup

Debug builds use the App Check debug provider. Run the Android app once on each
local emulator or device. Copy the token printed by `DebugAppCheckProvider` in
logcat. Add it at **Firebase console > Security > App Check > Apps > Manage
debug tokens**. Keep debug tokens private and never ship a debug build.

Then rebuild:

```sh
flutter pub get
flutter run
```

If Firebase initialization or App Check configuration is missing, Regiday
shows that AI Scan is unavailable, disables the scan action, and leaves image
capture and manual entry available.

## Release and test checks

- Verify AI Scan on test documents made only from synthetic data.
- Confirm front and back are reviewed together and no result is saved before
  **Confirm details** followed by the normal final **Save** action.
- Confirm documents without a printed expiry date leave expiry empty.
- Update the privacy policy and store disclosures to state that images are sent
  to Gemini through Firebase AI Logic only after the user taps Scan.
- Review App Check metrics before and after enforcing replay protection.

Official references:

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/ai-logic/get-started?platform=flutter
- https://firebase.google.com/docs/ai-logic/app-check
- https://firebase.google.com/docs/app-check/flutter/default-providers
- https://firebase.google.com/docs/app-check/flutter/debug-provider
- https://firebase.google.com/docs/app-check/android/play-integrity-provider
- https://firebase.google.com/docs/app-check/ios/app-attest-provider
- https://firebase.google.com/docs/ai-logic/security-checklist

Automated tests use a tiny generated PNG and fake structured responses. They do
not contact Firebase, call Gemini, or include real identity document images.
