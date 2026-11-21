# ResiDay: Existing Import & Subscription Architecture Audit

**Author:** Senior Flutter Engineer & Integration Architect  
**Date:** November 2026  
**Target Features:** Bank Statement Subscription Detection & Gmail Subscription Detection  

---

## 1. Executive Summary

ResiDay already possesses a complete, privacy-first local financial architecture:
1. **Import Data Module (`lib/features/csv_import/`)**: Parses CSV charge tables, suggests recurring charges based on date intervals, permits candidate editing, and commits subscriptions through entitlement-checked atomic batch writes.
2. **Subscription Management (`lib/features/subscriptions/`)**: Handles full subscription lifecycles, SQLite persistence, multi-currency support, custom reminder policies, and entitlement enforcement (Local Pro).
3. **Local Database & Sync (`lib/core/persistence/registry_database.dart`)**: SQLite schema (version 3) managing `subscriptions` and `documents` with encrypted, zero-cloud local backup capability (`lib/features/backup/`).
4. **Notification Engine (`lib/features/reminders/`)**: `ReminderCoordinator` automatically reconciles alarms with system notifications upon subscription changes.

This audit establishes how to integrate **Bank Statement Subscription Detection** directly into the existing import flow and add **Gmail Subscription Detection** alongside it without creating redundant import modules, breaking existing data workflows, or requiring paid cloud services.

---

## 2. Existing Import Data Architecture

### 2.1 File Location & Workflow
- **Directory**: `lib/features/csv_import/`
- **UI Entry Point**: `ImportChargesScreen` (`lib/features/csv_import/presentation/import_charges_screen.dart`), accessed via `AppRoutes.openImportCharges(context)` from `ProfileScreen` (`csv-import-open` button).
- **Core Orchestrator**: `CsvChargeImportSession` (`lib/features/csv_import/csv_charge_import.dart`).

### 2.2 Ingestion & Parsing Pipeline
```
[FilePicker: pickCsv()]
         │
         ▼ (Uint8List bytes)
[CsvTableParser.parse] ──► Validates limits: 256KB max, ≤2000 rows, ≤32 columns
         │
         ▼ (CsvRawTable)
[Column Mapping Step]  ──► Matches date, merchant, amount, currency (auto or manual)
         │
         ▼ (CsvColumnMapping complete)
[mapCharges()]         ──► Parses yyyy-MM-dd date, integer minor units, currency code
         │
         ▼ (List<CsvChargeRow>)
[suggestRecurringCharges()] ──► Groups by (normalized merchant, currency, amount)
         │                       Calculates median interval between charges
         │                       Maps delta to BillingCycle (weekly, monthly, quarterly, yearly)
         ▼
[Review Step]          ──► User selects/edits RecurringChargeCandidate items
         │
         ▼
[session.confirm()]    ──► Calls RegistryWrites.createSubscriptions()
```

### 2.3 Existing Import Models
- `CsvRawTable` / `CsvRawRow`: In-memory tabular view parsed from raw CSV bytes.
- `CsvColumnMapping`: Column indexes for `date`, `merchant`, `amount`, and `currency`.
- `CsvChargeRow`: Extracted single transaction (`lineNumber`, `date`, `merchant`, `minorUnits`, `currencyCode`).
- `RecurringChargeCandidate`: Suggested subscription (`id`, `merchant`, `minorUnits`, `currencyCode`, `cycle`, `nextPaymentDate`, `sourceRows`, `selected`, `possibleDuplicate`).

### 2.4 Existing Parsers & Validation
- **Date Parser**: `parseCsvDate()` strictly parses `yyyy-MM-dd`.
- **Amount Parser**: `parseMinorUnits()` parses integer-only digits up to 12 digits.
- **Merchant Normalization**: `normalizeMerchant()` trims whitespace and converts to lowercase.

---

## 3. Existing Subscription Architecture

### 3.1 Domain Models
- `RegistrySubscription` (`lib/features/subscriptions/domain/registry_subscription.dart`):
  - `id`: Unique string ID (format `sub_<microseconds>_<seq>` or `csv_<microseconds>_<seq>`).
  - `createdAt`, `updatedAt`: Timestamps.
  - `serviceName`: Normalized merchant/service name.
  - `planName`: Optional tier/plan name.
  - `category`: `SubscriptionCategory` enum (entertainment, utilities, software, fitness, news, gaming, cloud, education, other).
  - `amount`: `Money` class (minor units integer + 3-character ISO currency code).
  - `billingCycle`: `weekly`, `monthly`, `quarterly`, `yearly`.
  - `nextPaymentDate`: `DateTime` (date-only normalized).
  - `decideByDate`: Optional date for cancellation decision.
  - `autoRenew`: Boolean.
  - `lifecycle`: `active`, `paused`, `cancelled`.
  - `impact`: `DocumentImpact` (low, medium, high, critical).
  - `reminders`: `Set<SubscriptionReminder>`.
  - `notes`: Optional user notes.

### 3.2 Repositories and Persistence
- `SubscriptionRepository` (`lib/features/subscriptions/domain/subscription_repository.dart`): Interface for subscription access.
- `SqliteSubscriptionRepository` (`lib/features/subscriptions/data/sqlite_subscription_repository.dart`): SQLite implementation reading/writing to `subscriptions` table.
- Database: `RegistryDatabase` (`lib/core/persistence/registry_database.dart`), current schema version 3.

### 3.3 Creation and Review Flow
- `AddSubscriptionScreen` (`lib/features/subscriptions/presentation/add_subscription_screen.dart`): Multi-step form controller (`AddSubscriptionController`) with steps `service`, `billing`, `preferences`, and `review`.
- Saving is gated by `RegistryWrites.createSubscription(subscription)`, which calls `EntitlementService.admitNewSubscriptions()` before writing to SQLite.
- Reminder integration: `ReminderCoordinator` listens to repository mutations and immediately schedules notifications via `flutter_local_notifications`.

---

## 4. Integration Points & Strategy

### 4.1 Bank Statement Subscription Detection (Feature A)
*Goal:* Detect recurring subscriptions from imported bank statements without creating a second import screen.

1. **Parser Extension**:
   - Extend existing CSV/table parsing capabilities in `lib/features/csv_import/` to handle standard bank statement variations:
     - Multi-format date parsing: `dd/MM/yyyy`, `dd-MM-yyyy`, `yyyy-MM-dd`, `MM/dd/yyyy`.
     - Debit/Credit columns and decimal amounts (e.g. `649.00` converted to minor units `64900` or `649` depending on currency representation).
     - Filtering out credit (deposit) transactions, retaining only debit (expenditure) transactions.
2. **Dedicated Detection Logic (`BankSubscriptionDetectionService`)**:
   - Resides in `lib/features/subscriptions/domain/` or `lib/features/subscriptions/data/`.
   - Normalizes merchant strings: strips payment aggregators (`RAZORPAY*`, `PAYU*`, `STRIPE*`, `BILLDESK`), bank prefixes (`UPI/`, `POS/`, `ACH/`, `NEFT/`), company suffixes (`.COM`, `PVT LTD`, `LIMITED`, `LLC`, `INC`).
   - Evaluates recurring intervals: weekly (7d), monthly (28–31d), quarterly (~90d), half-yearly (~180d), yearly (~365d).
   - False-positive filtering: rejects rent, electricity, water, groceries, loan EMIs, salary, internal transfers, and peer UPI payments.
   - Confidence scoring:
     - Merchant consistency: 30%
     - Interval consistency: 30%
     - Amount consistency: 20%
     - Description keywords: 15%
     - Supporting email evidence: 5%
     - $\ge 3$ transactions = High confidence; 2 transactions = Medium confidence; 1 transaction = Rejected.
3. **User Suppression Preference**:
   - Users can mark any merchant as "Not a Subscription", persisted in SQLite table `ignored_merchants`.

### 4.2 Gmail Subscription Detection (Feature B)
*Goal:* Connect Gmail with read-only OAuth and search billing emails locally without sending email bodies to any external service.

1. **Google OAuth**:
   - Use `google_sign_in` with read-only scope: `https://www.googleapis.com/auth/gmail.readonly`.
   - Authenticate client-side only; tokens kept in secure storage/session; disconnect action provided.
2. **Gmail API Search & Processing (`GmailSubscriptionDetectionService`)**:
   - Target queries using `q` parameter (e.g., `subject:(receipt OR subscription OR renewal OR invoice OR "payment successful") newer_than:365d`).
   - Retrieve message metadata and parse text/HTML MIME bodies locally using base64 decoding.
   - Extract merchant, amount, currency, billing interval, payment date, renewal date, and event type.
   - Ignore cancellations, refunds, and one-off ecommerce orders.
   - Record `last_scan_timestamp` and scanned message IDs to prevent redundant processing.
3. **UI Integration**:
   - Add Gmail connection management in a dedicated, cohesive screen / section accessible from Subscriptions or Profile.

### 4.3 Common Subscription Discovery Engine (Feature C)
*Goal:* Consolidate candidates from bank statements and Gmail into a single discovery view.

1. **Discovery Service (`SubscriptionDiscoveryService`)**:
   - Unifies bank and email candidates.
   - Matches candidates across sources by normalized merchant and approximate billing amounts.
   - Merges evidence (`sourceTypes: [bankStatement, gmail]`), boosting confidence.
   - Deduplicates against existing subscriptions in `SubscriptionRepository`.
2. **Review & Confirmation Workflow**:
   - "Detected Subscriptions" list displaying source badges, confidence, amount, cycle, and estimated next payment date.
   - Tapping "Add" opens `AddSubscriptionScreen` pre-filled with candidate fields.
   - User reviews, edits, and taps Save -> passes through `RegistryWrites` and triggers `ReminderCoordinator`.
   - Tapping "Ignore" stores the merchant in `ignored_merchants` and dismisses the candidate.

---

## 5. Files Requiring Creation & Modification

### 5.1 New Files
| File Path | Description |
|---|---|
| `lib/features/subscriptions/domain/detected_subscription.dart` | Models for candidates, detection sources, evidence, confidence, review statuses. |
| `lib/features/subscriptions/domain/bank_subscription_detection_service.dart` | Normalizes bank transactions, detects cycles, calculates confidence, filters false positives. |
| `lib/features/subscriptions/domain/gmail_subscription_detection_service.dart` | Gmail query builder, MIME parser, subscription/renewal extractor. |
| `lib/features/subscriptions/domain/subscription_discovery_service.dart` | Cross-source matcher, deduplicator, suppression store. |
| `lib/features/subscriptions/data/detected_subscription_repository.dart` | Persistence for detected candidates, ignored merchants, and scan metadata. |
| `lib/features/subscriptions/presentation/detected_subscriptions_screen.dart` | UI for reviewing detected candidates, viewing evidence, adding or ignoring. |
| `lib/features/subscriptions/presentation/gmail_connect_screen.dart` | UI for connecting/disconnecting Gmail and initiating scans. |
| `test/bank_subscription_detection_test.dart` | Unit tests for bank transaction analysis, normalization, and false positives. |
| `test/gmail_subscription_detection_test.dart` | Unit tests for Gmail MIME parsing, queries, and rate-limit/error handling. |
| `test/subscription_discovery_test.dart` | Cross-source deduplication, merging, and candidate lifecycle tests. |

### 5.2 Modified Files
| File Path | Description of Changes |
|---|---|
| `pubspec.yaml` | Add `google_sign_in: ^6.2.2`, `http: ^1.2.2`, and `googleapis: ^13.2.0`. |
| `lib/core/persistence/registry_database.dart` | Add schema version 4 migration for `detected_subscriptions`, `ignored_merchants`, and `gmail_sync_metadata`. |
| `lib/features/csv_import/csv_charge_import.dart` | Add bank statement format adaptations (flexible dates, decimal parsing, debit filtering) and hook into `BankSubscriptionDetectionService`. |
| `lib/features/subscriptions/presentation/add_subscription_controller.dart` | Add `prefillCandidate()` method for pre-populating candidate details. |
| `lib/features/subscriptions/presentation/add_subscription_screen.dart` | Support accepting prefill candidate parameters. |
| `lib/app/navigation/app_routes.dart` | Add routes for Detected Subscriptions and Gmail Connect. |
| `lib/app/registry_dependencies.dart` | Provide `SubscriptionDiscoveryService` and related dependencies. |
| `lib/features/subscriptions/presentation/subscriptions_screen.dart` | Add entry pill or action button for "Discover Subscriptions". |
| `lib/l10n/app_en.arb`, `app_fr.arb`, `app_ar.arb` | Localized strings for discovery, Gmail sync, detected candidates, and suppression. |

---

## 6. Architectural Feasibility & No-Blocker Declaration

- The existing SQLite database schema cleanly supports new tables via standard `applyMigrations` (version 4) without impacting version 3 document/subscription rows or backup payload encoding.
- The existing CSV charge parser and candidate models can be gracefully extended to accept bank statement formats while preserving existing generic CSV charge import functionality.
- `AddSubscriptionController` and `RegistryWrites` provide an ideal prefill and verification pipeline that guarantees user confirmation, entitlement checks, and reminder synchronization.
- **Verdict:** No architectural blockers exist. Proceeding directly with Phase 1.

