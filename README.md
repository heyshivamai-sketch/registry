# Regiday (The Registry)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-grey.svg)](#)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Local--First-brightgreen)](#)

A modern, privacy-first personal registry and smart wallet for documents, subscriptions, and renewals. Built with Flutter, **Regiday** operates with a local-first philosophy—keeping sensitive documents, financial subscriptions, attachments, and reminders securely on your device.

---

## 🌟 Key Features

### 📄 Smart Document Wallet
- **Comprehensive Document Storage**: Securely organize IDs, driver's licenses, passports, vehicle registrations, insurance policies, warranties, and contracts.
- **Multi-Attachment Support**: Attach primary photos and up to five high-resolution images or document scans per record.
- **Expiry Status Tracking**: Clear visual indicators for active, expiring-soon, and expired documents with countdown indicators.

### 🤖 On-Device AI Document Scanning (Gemini)
- **Firebase AI Logic**: Powered by Google's Gemini models via Firebase AI Logic and secured by Firebase App Check.
- **Zero API Key Exposure**: The app requires no embedded Gemini API keys.
- **Privacy-Safe OCR**: Document images are sent only when explicitly initiated via **Scan all images**. Extracted fields (title, issuer, document number, expiry date) open directly in a review flow and are never saved automatically.

### 💳 Intelligent Subscription Management & Discovery
- **Recurring Cycle Tracking**: Track weekly, monthly, quarterly, and annual subscriptions with renewal calendars and spending summaries.
- **Bank Statement CSV Ingestion**: Import transaction statements to discover recurring charges. Employs merchant normalization (stripping processor prefixes like `UPI/`, `POS-`, `STRIPE*`, `RAZORPAY*`), interval cadence scoring, and intelligent false-positive filtering (excluding rent, utilities, and grocery runs).
- **Gmail Subscription Detection**: Perform on-device, read-only OAuth scans to detect subscription receipts, renewal notices, and trial periods.
- **Unified Discovery Engine**: Consolidate candidates across sources with duplicate suppression and one-tap addition.

### ⏰ Reliable Local Reminders
- **Offline Notification Engine**: Schedule local device notifications for document expiries and subscription renewals without any external notification server.
- **Custom Alert Windows**: Receive reminders across customizable lead times (30 days, 7 days, 1 day, same day).
- **Timezone Aware**: Synchronizes accurately with device timezone changes using `timezone` and `flutter_timezone`.

### 🔐 Security & Privacy by Default
- **Biometric App Lock**: Protect sensitive records with Face ID, Touch ID, fingerprint, or system passcode using `local_auth`.
- **Screen Shielding**: Hides app content and prevents screenshots in system recents on Android (`FLAG_SECURE`).
- **Encrypted Backup & Restore**: Export full database archives and attachments to password-protected, AES-256 encrypted `.rgry` files for safe offline migration.

### 💎 Fair Entitlement & Local Pro
- **Generous Free Tier**: Track up to 10 documents and 5 subscriptions with full access to all essential tools. Records above limits always remain viewable, editable, and exportable.
- **Local Pro**: Non-consumable one-time purchase via Google Play Billing or Apple StoreKit that unlocks unlimited items and advanced features.
- **Clean Monetization Boundary**: Zero tracking, telemetry, or third-party ads for Local Pro users; ads and purchases can be toggled via compile-time build flags.

### 🌍 Multilingual & Accessible
- Full internationalization support with localized strings for:
  - English (`en`)
  - French (`fr`)
  - Arabic (`ar` with native RTL layout support)
- Modern Material 3 interface with dynamic theming and high-contrast accessibility.

---

## 🏗️ Architecture & Project Structure

The project follows clean architecture principles, separating concerns across presentation, domain, and data layers:

```
lib/
├── app/                  # Application bootstrap, navigation, routing, and theme
│   ├── navigation/       # AppShell, bottom dock, route definitions
│   ├── theme/            # Material 3 Aura tokens (colors, typography, spacing, shadows)
│   ├── launch_config.dart# Compile-time build configuration (--dart-define)
│   └── registry_bootstrap.dart # Top-level dependency wiring
├── core/                 # Shared foundations and reusable components
│   ├── persistence/      # SQLite database (sqflite), key-value stores, attachment storage
│   ├── time/             # Clock abstractions and timezone utilities
│   └── widgets/          # Design system components (surfaces, chips, buttons, forms)
├── features/             # Domain feature modules
│   ├── ads/              # Google Mobile Ads platform isolation and controllers
│   ├── app_lock/         # Biometric authentication and window privacy policies
│   ├── backup/           # Encrypted .rgry archive generator and restore pipeline
│   ├── csv_import/       # Bank statement CSV parser, date normalizer, and charge importer
│   ├── documents/        # Document repository, multi-image manager, and Gemini OCR
│   ├── entitlements/     # In-app purchase verification, limits, and Local Pro state
│   ├── home/             # Dashboard, summary cards, and quick actions
│   ├── onboarding/       # First-run guided setup flow
│   ├── reminders/        # Local reminder scheduling and notification coordinator
│   └── subscriptions/    # Subscription tracker, Gmail detector, and discovery engine
├── l10n/                 # Localization templates (.arb) and generated localization delegates
└── main.dart             # App entry point
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `>= 3.12.2` (Dart SDK `>= 3.12.2`)
- **Android Studio / Xcode**: For platform builds and emulators/simulators
- **CocoaPods**: For iOS dependency management (`pod install`)

### Setup Instructions

1. **Clone the repository**:
   ```sh
   git clone <repository-url>
   cd registry
   ```

2. **Install Flutter dependencies**:
   ```sh
   flutter pub get
   ```

3. **Run Code Generation / Localization**:
   ```sh
   flutter gen-l10n
   ```

4. **Launch the application**:
   ```sh
   flutter run
   ```

---

## ⚙️ Build Configuration & Flags

Regiday uses compile-time `--dart-define` switches in [`lib/app/launch_config.dart`](file:///Users/shahbazkhan/StudioProjects/registry/lib/app/launch_config.dart) to govern features cleanly:

| Flag | Type | Default | Description |
| --- | --- | --- | --- |
| `RESET_ONBOARDING` | `bool` | `false` | Resets first-run onboarding for development when set to `true`. |
| `ENABLE_APP_CHECK` | `bool` | `false` | Enables Firebase App Check (Play Integrity on Android, App Attest on iOS). |
| `FIREBASE_AI_MODEL` | `string` | `gemini-3.5-flash-lite` | Selects the Gemini model used for document field extraction. |
| `PURCHASES_ENABLED` | `bool` | `false` | Enables Google Play Billing and Apple StoreKit for Local Pro. |
| `ADS_ENABLED` | `bool` | `false` | Enables Google Mobile Ads banner integration. |
| `ADS_MODE` | `string` | `""` | Set to `test` for Google sample units or `live` for production. |
| `ADMOB_ANDROID_BANNER_UNIT_ID` | `string` | `""` | Banner ad unit ID for Android. |
| `ADMOB_IOS_BANNER_UNIT_ID` | `string` | `""` | Banner ad unit ID for iOS. |

### Development Examples

- **Run with Onboarding Reset**:
  ```sh
  flutter run --dart-define=RESET_ONBOARDING=true
  ```

- **Run with Test Ads Enabled**:
  ```sh
  flutter run --dart-define=ADS_ENABLED=true --dart-define=ADS_MODE=test
  ```

- **Run with Store Purchases Enabled**:
  ```sh
  flutter run --dart-define=PURCHASES_ENABLED=true
  ```

---

## 🧪 Testing & Quality Assurance

The codebase maintains rigorous automated test suites covering unit logic, repositories, biometric authentication, CSV parsing, OCR resilience, and UI flows.

- **Run all unit and widget tests**:
  ```sh
  flutter test
  ```

- **Run static analysis**:
  ```sh
  flutter analyze
  ```

- **Run integration tests**:
  ```sh
  flutter test integration_test/aura_home_redesign_qa_test.dart
  ```

---

## 🔒 Privacy & Data Guarantee

- **Zero Cloud Persistence**: There is no remote account registration, user profiling, or background tracking.
- **User-Controlled Data**: Backups are saved only where you choose (local storage, iCloud Drive, Google Drive, or shared via system sheet) using strong AES-256 encryption.
- **Selective OCR**: Images are sent to Gemini through Firebase AI Logic exclusively when the user taps **Scan all images**, and results require explicit user approval before saving.
