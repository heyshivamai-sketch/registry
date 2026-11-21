# ResiDay: Subscription Detection Implementation Report

**Author:** Senior Flutter Engineer, Integration Architect & Fintech Application Developer  
**Date:** November 2026  
**Scope:** Bank Statement Subscription Detection & Gmail Subscription Detection  

---

## 1. Executive Summary

ResiDay has been extended to support intelligent subscription discovery from two independent channels:
1. **Bank Statement Ingestion**: Recurring subscription payments (monthly, quarterly, yearly, weekly) are identified from imported transaction statements within the existing Import Data module.
2. **Gmail Subscription Detection**: Read-only Google OAuth scans and extracts recurring billing receipts, renewal notifications, and trial starts on-device.

Both channels converge into a unified **Subscription Discovery Engine** (`SubscriptionDiscoveryService`), allowing multi-evidence cross-source candidate consolidation, duplicate suppression, and one-tap prefilled addition to ResiDay through the existing user review and reminder pipeline.

---

## 2. Existing Code Reused

- **Import Data Module (`lib/features/csv_import/`)**:
  - Reused `CsvChargeImportSession`, `CsvTableParser`, `PlatformCsvFileGateway`, and `ImportChargesScreen`.
  - Upgraded `suggestRecurringCharges` and `parseCsvDate` to benefit directly from merchant normalization, multi-format date recognition (`yyyy-MM-dd`, `dd-MMM-yyyy`, `dd/MM/yyyy`), and false-positive filtering without breaking existing CSV workflows.
- **Subscription Management (`lib/features/subscriptions/`)**:
  - Reused `RegistrySubscription`, `Money`, `MoneyFormat`, `BillingCycle`, and `SqliteSubscriptionRepository`.
  - Reused `AddSubscriptionController` and `AddSubscriptionScreen` by introducing candidate prefilling (`prefillCandidate`).
  - Reused `RegistryWrites.createSubscription` to guarantee Local Pro entitlement enforcement.
- **Reminder & Notification Engine (`lib/features/reminders/`)**:
  - Reused `ReminderCoordinator` which automatically reconciles and schedules local device alarms as soon as subscriptions are accepted.
- **Database & Persistence (`lib/core/persistence/registry_database.dart`)**:
  - Maintained schema backward compatibility by upgrading from schema version 3 to 4, preserving all existing documents, subscriptions, and backup payload compatibility.
- **Localization (`lib/l10n/`)**:
  - Integrated with the existing `.arb` localization system across English (`en`), French (`fr`), and Arabic (`ar`, RTL).

---

## 3. New Architecture & Implemented Components

### 3.1 Bank Statement Detection (`BankSubscriptionDetectionService`)
- **Location**: `lib/features/subscriptions/domain/bank_subscription_detection_service.dart`
- **Merchant Normalization**: Strips channel prefixes (`UPI/`, `POS-`, `ACH-`, `NEFT-`, `RTGS-`), payment processor tags (`RAZORPAY*`, `PAYU*`, `STRIPE*`, `BILLDESK*`, `GOOGLE*`, `APPLE.COM/BILL`), legal corporate entity suffixes (`PVT LTD`, `PRIVATE LIMITED`, `LTD`, `INC`, `LLC`), domain extensions (`.COM`, `.IN`, `.ORG`), and trailing payment terms (`PAYMENT`, `AUTOPAY`, `MEMBERSHIP`).
- **Interval Scoring**:
  - Computes median deltas across transaction dates.
  - Recognizes Weekly ($7 \pm 2$ days), Monthly ($30 \pm 4$ days), Quarterly ($91 \pm 10$ days), and Yearly ($365 \pm 25$ days).
- **False-Positive Prevention**:
  - Filters out: Rent payments, electricity & water utilities, supermarkets & groceries (Blinkit, Zepto, DMart, Walmart), loan EMIs (Bajaj, HDFC Home Loan), credit card repayments (CRED, CC payment), salary deposits, and internal account transfers.
  - Automatically filters out credit/deposit transactions (only debits are considered).
- **Weighted Scoring**:
  - Merchant Similarity: 30%
  - Billing Interval Consistency: 30%
  - Amount Consistency: 20%
  - Subscription Keywords: 15%
  - Multi-occurrence Evidence: 5%
  - Single payments are rejected; 2 payments yield medium confidence; 3+ payments produce high confidence.

### 3.2 Gmail Subscription Detection (`GmailSubscriptionDetectionService` & `GmailClientGateway`)
- **Location**:
  - Domain: `lib/features/subscriptions/domain/gmail_subscription_detection_service.dart`
  - Client Gateway: `lib/features/subscriptions/data/gmail_client_gateway.dart`
  - UI: `lib/features/subscriptions/presentation/gmail_connect_screen.dart`
- **OAuth & Permissions**:
  - Uses `google_sign_in` with the minimal read-only scope: `https://www.googleapis.com/auth/gmail.readonly`.
  - No access to send, delete, modify, or mark messages as read.
  - Client credentials and secrets are managed via standard platform OAuth without hardcoded tokens.
- **Targeted Querying**:
  - `q: 'subject:(subscription OR renewal OR "payment successful" OR receipt OR invoice OR "membership renewal" OR "free trial" OR "upcoming payment") newer_than:365d'`
  - Messages fetched by ID and MIME parts decoded via `base64UrlSafe`.
- **Parsing & Event Classification**:
  - Classifies events into `paymentSuccess`, `subscriptionRenewal`, `subscriptionStarted`, `trialStarted`, `priceChanged`, `cancellation`, `refund`.
  - **Exclusion rules**: Cancellation and refund emails are explicitly prevented from generating subscription candidates.
  - Extracts amounts (INR, USD, EUR, GBP), billing cycles, and next renewal dates (or estimates based on cycle).
  - Preserves privacy: full email bodies are never stored; only metadata (`EmailEvidence`) is retained.

### 3.3 Common Discovery Engine (`SubscriptionDiscoveryService`)
- **Location**: `lib/features/subscriptions/domain/subscription_discovery_service.dart`
- **Cross-Source Merging**:
  - Merges bank statement candidates and Gmail candidates matching the same normalized merchant and currency.
  - Accommodates price changes (e.g. ₹649 in bank vs ₹749 in recent email) by keeping the latest transaction's amount.
  - Fuses evidence (`bankEvidence` + `emailEvidence`) and boosts confidence score ($\ge 0.90$).
  - Bank-only and Gmail-only candidates persist and operate independently.
- **Suppression Management**:
  - User can tap "Not a Subscription" on any candidate to suppress future suggestions for that merchant permanently.
  - Suppressed merchants are saved locally in SQLite table `ignored_merchants`.

### 3.4 User Review & Confirmation Flow
- **Location**: `lib/features/subscriptions/presentation/detected_subscriptions_screen.dart`
- Candidates are displayed with:
  - Merchant name and formatted amount.
  - Source badge (Bank Statement, Gmail, or Both).
  - Confidence badge (High, Medium, Low).
  - Last payment date and next payment date (annotated with estimated status).
- **Actions**:
  - **Add to ResiDay**: Opens the existing `AddSubscriptionScreen` pre-filled with the candidate's service name, amount, currency, and cycle. The user reviews and edits details, and saves via `RegistryWrites`. Once saved, the candidate is marked as `accepted`.
  - **Not a Subscription**: Dismisses the candidate and saves the suppression preference locally.

---

## 4. Database Schema Changes (Version 4)

SQLite database schema (`RegistryDatabase`) was upgraded from version 3 to 4 with three dedicated tables:
1. `detected_subscriptions`:
   - `id TEXT PRIMARY KEY`
   - `merchant_name TEXT NOT NULL`
   - `minor_units INTEGER NOT NULL`
   - `currency_code TEXT NOT NULL`
   - `billing_cycle TEXT NOT NULL`
   - `last_payment_date TEXT NOT NULL`
   - `next_payment_date TEXT`
   - `next_payment_is_estimated INTEGER NOT NULL`
   - `source_types TEXT NOT NULL`
   - `confidence_score REAL NOT NULL`
   - `review_status TEXT NOT NULL`
   - `bank_evidence TEXT`
   - `email_evidence TEXT`
   - `created_at TEXT NOT NULL`
   - `updated_at TEXT`
2. `ignored_merchants`:
   - `merchant_name TEXT PRIMARY KEY`
   - `suppressed_at TEXT NOT NULL`
3. `gmail_sync_metadata`:
   - `key TEXT PRIMARY KEY`
   - `email_address TEXT`
   - `last_successful_scan TEXT`
   - `last_scanned_message_id TEXT`
   - `connected_at TEXT`

*Note on Backup Compatibility:* Backup payload versioning is unaffected, ensuring existing `.rgpy` backup files restore seamlessly without modification.

---

## 5. Files Created and Modified

### Files Created:
1. `docs/subscription_detection/EXISTING_IMPORT_AND_SUBSCRIPTION_AUDIT.md`
2. `lib/features/subscriptions/domain/detected_subscription.dart`
3. `lib/features/subscriptions/domain/bank_subscription_detection_service.dart`
4. `lib/features/subscriptions/domain/gmail_subscription_detection_service.dart`
5. `lib/features/subscriptions/domain/subscription_discovery_service.dart`
6. `lib/features/subscriptions/data/detected_subscription_repository.dart`
7. `lib/features/subscriptions/data/gmail_client_gateway.dart`
8. `lib/features/subscriptions/presentation/detected_subscriptions_screen.dart`
9. `lib/features/subscriptions/presentation/gmail_connect_screen.dart`
10. `test/bank_subscription_detection_test.dart`
11. `test/gmail_subscription_detection_test.dart`
12. `test/subscription_discovery_test.dart`
13. `test/detected_subscriptions_screen_test.dart`
14. `docs/subscription_detection/IMPLEMENTATION_REPORT.md`

### Files Modified:
1. `pubspec.yaml`: Added `google_sign_in: ^6.2.2`, `http: ^1.2.2`, and `googleapis: ^13.2.0`.
2. `lib/core/persistence/registry_database.dart`: Incremented `schemaVersion` to 4 and added `_upgradeToVersion4`.
3. `lib/core/persistence/registry_store.dart`: Loaded and exposed `SqliteDetectedSubscriptionRepository`.
4. `lib/features/csv_import/csv_charge_import.dart`: Integrated flexible date parsing, merchant normalization, and false-positive filtering.
5. `lib/features/subscriptions/presentation/add_subscription_controller.dart`: Added `prefillCandidate()`.
6. `lib/features/subscriptions/presentation/add_subscription_screen.dart`: Accepted `initialCandidate`.
7. `lib/features/subscriptions/presentation/subscriptions_screen.dart`: Added "Discover Subscriptions" entry point in the header.
8. `lib/app/navigation/app_routes.dart`: Added routes `openDetectedSubscriptions` and `openGmailConnect`.
9. `lib/app/registry_dependencies.dart`: Registered `discovery` and `gmailClient` in the inherited widget.
10. `lib/app/app.dart`: Wired discovery repository and Gmail gateway into `RegistryApp`.
11. `lib/app/registry_bootstrap.dart`: Injected SQLite detected subscription repository from `RegistryStore`.
12. `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_ar.arb`: Localized all new user-facing strings in English, French, and Arabic.

---

## 6. Test Suite Results

Automated unit and widget test suites were executed:
- `test/bank_subscription_detection_test.dart`: **8/8 tests passed** (Netflix monthly, quarterly, annual, false positives, merchant normalization, credits excluded, ignored merchants, duplicate flagging).
- `test/gmail_subscription_detection_test.dart`: **8/8 tests passed** (monthly Netflix, Spotify HTML/base64, AWS annual, trial started, cancellation exclusion, refund exclusion, grouping/boosting, ignored merchants).
- `test/subscription_discovery_test.dart`: **5/5 tests passed** (cross-source Netflix bank + Gmail merging, price change handling, bank-only, Gmail-only, merchant suppression).
- `test/detected_subscriptions_screen_test.dart`: **Passed** (card rendering, confidence badges, ignoring candidates).
- `test/csv_import_test.dart`: **4/4 regression tests passed** (verified existing CSV import workflow remained 100% backward compatible).

---

## 7. Security, Privacy & External Setup

1. **Local Processing**:
   - Bank statement CSV parsing and Gmail message analysis occur entirely on-device.
   - Raw statements or email bodies are never transmitted to Firebase AI, Gemini, or external APIs.
2. **Google OAuth Verification**:
   - Scope `https://www.googleapis.com/auth/gmail.readonly` is classified as a Restricted Scope by Google.
   - For production launch on Google Play:
     - Register the app in the Google Cloud Console.
     - Configure OAuth Consent Screen.
     - Complete Google's CASA (Cloud Application Security Assessment) or Tier 2 verification for restricted scopes.
     - For local development and testing, test user Gmail accounts can be added directly to the OAuth consent screen test list.
3. **No Paid Infrastructure**:
   - Zero additional monthly costs; no Cloud Functions, Pub/Sub, or third-party bank aggregators required.

