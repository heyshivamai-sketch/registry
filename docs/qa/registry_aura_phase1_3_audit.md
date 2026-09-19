# Registry Aura Phases 1–3 — UI/UX fidelity and functional audit

**Date:** 19 September 2026  
**Reference:** https://registry-aura-prototype.shivamagrawal0107.chatgpt.site/  
**Mode (original):** Audit only.  
**Mode (this update):** Phase 1–3 corrections implemented on `feature/registry-aura-ui`. Phase 4 was not started. No commit or push.

---

## Corrections session — 19 September 2026 (later)

### Executive verdict

**READY FOR PHASE 4**

Required functional gaps from the original audit are closed: Pulse **Review now** opens a read-only catalog-item review, **90-day view / Open calendar** opens a chronological Horizon list, and identity selectors no longer overlap labels with values. Wizard **Continue** uses a directional Material arrow (LTR and RTL), dock icons match the closest Material equivalents of the prototype glyphs, and Documents status copy is the full **Action needed** string. A debug APK was built from the corrected source with JDK 17, installed on `emulator-5554`, and the create / ML Kit OCR / Documents / Detail loop was exercised on that binary.

### Accepted product/data differences — no correction required

1. **Action Queue eligibility** — Show only Action needed and Overdue. Upcoming and Active stay in Horizon. Impact does not determine attention. Prototype count of 3 is not reproduced.
2. **Countdown** — Remaining time is calculated from the real current date (1 day on 19 Sep 2026). The prototype’s frozen “2 DAYS” is not hardcoded.
3. **Snapshot subscription value** — Real catalog count (`2 tracked`) is shown. Fake `$47.99 / month` is not displayed. Monthly spend waits for Phase 4 repository prices.
4. **Profile initials** — Neutral Aura monogram `R` until profile data exists. Prototype persona `SA` is not hardcoded.

### Chosen Pulse Review / 90-day design

- Home catalog items remain in `MockRegistryCatalog`. They are **not** written to `DocumentRepository`.
- `AppRoutes.openCatalogItemReview(itemId)` pushes `CatalogItemDetailScreen`, which looks up `MockRegistryCatalog.byId` and reuses Aura `RegistrySurface`, `RegistryAuraStatusPill`, `RegistryInfoRow`, and `RegistryCallout`.
- No Edit / Delete / Renew. Android back pops to `AppShell`; `HomeScreen` stays in the `IndexedStack`, so search/scroll/tab state is preserved.
- `AppRoutes.openHorizon90Day()` pushes `Horizon90DayScreen` with `MockRegistryCatalog.withinHorizonItems` (action date, due-date tie-break). The snapshot header, Next 90 days metric, and Horizon **Open calendar** action all use this route. Empty state is injectable via `items: []`.
- Feature flag `kHomeHeroReviewOpensDetail` was removed.

### Identity overlap root cause and fix

`InputDecorator` treated country as empty while still painting `DocumentCopy.country(null)` → **Other** in the same slot as the floating **Country or region** label. Category duplicated its label as the empty-state child. Shared `RegistrySelectorField` now always floats the label and leaves the value blank when empty. Labels: Document type (schema / Aadhaar), Category (ID card), Country or region.

### Build / install

| Item | Value |
| --- | --- |
| JDK | Homebrew OpenJDK 17.0.20.1 (`JAVA_HOME` for this build only) |
| Gradle wrapper URL | Unchanged `https://services.gradle.org/distributions/gradle-9.1.0-all.zip` (local zip used only for this assemble; not committed) |
| APK | `build/app/outputs/flutter-apk/app-debug.apk` (rebuilt 19 Sep 2026 ~14:00 for P2 polish; prior 12:27 binary superseded) |
| Install | `adb -s emulator-5554 install -r` → Success |
| applicationId | `com.registry.app` 1.0.0 debug |

### Automated validation (this session)

```
dart format lib test
flutter analyze          # No issues found
flutter test             # 162/162 passed
git diff --check         # exit 0
flutter build apk --debug  # ✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

### P2 polish (later 19 September 2026)

1. **Wizard Continue** — **Resolved.** `l10n.wizardContinue` stays “Continue” / “Continuer” / “متابعة”. Trailing `Icons.arrow_forward_rounded` (`IconData.matchTextDirection: true`), not a Unicode arrow in the string. RTL places the mirrored arrow at the start (visual left). Back and Save document have no arrow. Evidence: `wizard_continue_arrow.png`, `arabic_continue_rtl.png`.
2. **Navigation dock icons** — **Resolved** with one documented library difference. Prototype glyphs are custom Unicode `⌂ ▱ ＋ ◎ ◉`. Production mapping (18dp, outlined vs filled selected): Home `home_outlined` / `home_rounded`; Documents `article_outlined` / `article_rounded`; Add `Icons.add`; Plans `circle_outlined` / `adjust`; Profile `account_circle_outlined` / `account_circle`. No extra icon package. Evidence: `navigation_dock_final.png`.
3. **Documents “Action needed”** — **Resolved.** `DocumentStatus.urgent` uses `l10n.actionNeeded` (EN/FR/AR) on filters, pass, cards, detail, and `statusUrgent`. Chips wrap at 1.8×. Attention rule unchanged. Evidence: `documents_action_needed.png`, `large_text_action_needed.png`.

---

## A. Executive verdict

**READY FOR PHASE 4** *(original audit session was CORRECTIONS REQUIRED; see the corrections session above)*

Phases 1–3 remain a coherent Aura product. The original P1 functional gaps (Pulse Review no-op, non-interactive 90-day/Open calendar, identity label overlap, no native rebuild) are **Resolved** or **Accepted product/data difference**. Live create, ML Kit OCR review, populated wallet, Detail, Arabic Home, and 1.8× identity were recaptured on the rebuilt APK.

P2 visual mismatches that remain are platform/type only (Roboto vs Inter). Wizard Continue, dock icons, and Action needed copy are **Resolved**.

---

## B. Verified baseline

| Item | Value |
| --- | --- |
| Branch | `feature/registry-aura-ui` |
| Commit | `a2a407832a0602cb55206fa1139939dfaeb275dc` (`a2a4078 feat: add Aura document wizard and on-device OCR`) |
| Working tree | Production tree clean. Untracked only: `screenshots/`, `tooling/`, `registry_preview_screenshot.png`, and this audit’s evidence. |
| Flutter | 3.44.8 stable · Dart 3.12.2 · Framework `058e0af2c2` (23 Jul 2026) |
| Device | `emulator-5554` · `sdk gphone16k arm64` / `sdk_gphone16k_arm64` |
| Android | 17 (API 37) |
| Physical resolution | 1080 × 2400 |
| Density | 420 dpi |
| Logical viewport | sw411dp · w411dp · h914dp |
| Locale during live capture | `en-US`, LTR |
| Text scale | 1.0 |
| App | `com.registry.app` 1.0.0 debug · `MainActivity` resumed |
| Build this session | `flutter run` / `assembleDebug` **failed** (Gradle wrapper download `ConnectException`; offline Gradle plugin resolve failed). Live app is the **already-installed debug binary**, which matched current source for Home, dock, empty wallet, and add wizard. |

Prototype CSS tokens (from live `styles.css`): `--ink:#111936`, `--violet:#6558f5`, `--aqua:#42d8b7`, `--coral:#ff675d`, `--gold:#e9aa27`, `--paper:#f7f8fc`, `--muted:#66718b`, `--line:#e7e9f2`, Inter. Flutter `AppColors` / `AppSpacing` / `AppRadius` align with those numbers.

---

## C. Phase-by-phase inventory

### Phase 1 — Foundation / Home / navigation

| Capability | Status | Notes |
| --- | --- | --- |
| Shared theme and reusable surfaces | Implemented | `lib/app/theme/*`, `lib/core/widgets/*` |
| Home header + profile entry | Implemented | Live date line; monogram `R` not `SA` |
| Search, clear, no-results | Implemented | Live PASS |
| Pulse / countdown | Implemented | Live; 1 day on 19 Sep 2026 vs prototype 2 DAYS on frozen 18 Sep |
| Snapshot metrics | Implemented | Copy and 90-day control differ |
| Action queue | Implemented | Product rule: urgent/expired only (1 item). Prototype shows 3 including Upcoming |
| Horizon | Implemented | 4 remaining catalog items; prototype shows 2 |
| Floating dock + selected tab | Implemented | Live; Material icons vs prototype glyphs |
| Centre Add + Quick Add sheet | Implemented | Live |
| Tab preservation / back-to-Home | Implemented | Code + tests; live tab switch PASS for Home/Docs/Me |
| Notifications / 90-day / Review / calendar | Implemented (Review + 90-day) | Pulse Review and 90-day Horizon are functional. Notifications remain a placeholder. |

### Phase 2 — Document wallet / detail

| Capability | Status | Notes |
| --- | --- | --- |
| Empty wallet | Implemented | Live PASS |
| Populated wallet, featured pass, remaining cards | Implemented | Not recaptured populated in this session (empty in-memory store after process restart) |
| Search / filters / no-results | Implemented | Tests PASS; live filter not captured |
| Document Detail, deadline health, information | Implemented | Tests PASS; live Detail not recaptured this session |
| Masked sensitive fields | Implemented | `RegistryDocument.maskedDocumentNumber`; tests |
| Attachment thumbnail + full-screen | Implemented | Tests |
| Reminder preferences | Implemented | Saved preferences only; notifications not scheduled |
| Renewal history + Record renewal | Implemented | Tests (exactly one history entry) |
| Edit / Delete + confirm | Implemented | Tests |

### Phase 3 — Add / edit / OCR / dynamic fields

| Capability | Status | Notes |
| --- | --- | --- |
| Five-step flow | Implemented | Live: source + identity (+ validation + back) |
| Progress, Back, Continue, pinned Save | Implemented | Live; Continue has no `→` |
| Required/optional + validation | Implemented | Live identity errors PASS |
| Dirty discard | Implemented | Tests; not recaptured live |
| Attachment pick/replace/remove | Implemented | Tests; live gallery/camera not completed |
| OCR process / review / cancel / fail / retry | Implemented | Tests with fakes; **live ML Kit NOT TESTED this session** |
| Schema/country + dynamic/custom fields | Implemented | Live identity shows overlapping dropdown labels (P1) |
| Edit prefill / same-id update | Implemented | Tests |
| Review-and-save | Implemented | Tests; live save of one document NOT completed |

### Out of scope (future reference screens)

Do **not** count as missing Phase 1–3 work:

01 Splash · 02 Onboarding redesign · 08 Subscriptions populated · 09 Plan detail · 10 Add plan · 11 Calendar · 12 Notifications (full) · 13 Profile (full) · 14 Settings.

App currently has: existing onboarding (not Aura splash), subscriptions **empty placeholder**, add-subscription placeholder, notifications placeholder, profile placeholder. Those destinations are placeholders, not Phase 1–3 defects except where Home still points at them.

---

## D. Screen/state comparison matrix

Reference screens were captured from the live prototype phone UI (Puppeteer, `.device`), excluding the desktop studio. App screens are real emulator captures with Android fonts, unless marked *prior Pixel 8 capture on this branch*.

| Screen / state | Reference | App | Result | Findings |
| --- | --- | --- | --- | --- |
| Home top (header, search, pulse, snapshot, queue) | `screenshots/registry_aura_phase1_3_audit/reference/03_home_top_app.png` | `app/home_snapshot_queue.png` | Mismatch | See P1/P2 list. Comparison: `comparisons/home_top_side_by_side.png` |
| Home horizon + dock | `reference/03_home_horizon_app.png` | `app/home_horizon_dock.png` | Mismatch | Queue/horizon membership and copy. `comparisons/home_horizon_side_by_side.png` |
| Home search Passport | Prototype search is a static input | `app/live_home_search_passport.png` | Match (behaviour) | Pulse hidden; Passport remains on Horizon. Snapshot counts stay catalog-wide (3/2/5) — differs from filtering the whole dashboard |
| Home search empty | Not a dedicated prototype state | `app/live_home_search_empty.png` | Match (product) | “No matching items” |
| Home search clear | — | `app/live_home_search_cleared.png` | Pass | Query cleared; dashboard restored |
| Quick Add | `reference/03_quick_add_sheet_app.png` | `app/cal_add.png` | Mismatch (minor) | Copy close; eyebrow `Quick Add` vs `QUICK ADD`; Material icons vs glyphs. `comparisons/quick_add_side_by_side.png` |
| Documents empty | Prototype has no empty wallet (always 3 docs) | `app/live_documents_wallet.png` | Partial | Empty is required product state; not in prototype. Visual language matches Aura empty card. `comparisons/documents_side_by_side.png` compares populated ref vs empty app |
| Documents populated | `reference/04_documents_wallet_app.png` | `app/prior_device_documents_wallet.png` | Mismatch | Not recaptured populated this session. Prior device shot on this Pixel 8. Filter “Action” vs “Action needed”; featured pass duplicates in remaining list in prototype |
| Document pass / Detail | `reference/05_document_pass_top_app.png` | `app/prior_device_document_pass.png` | Mismatch / incomplete live | Prototype keeps dock on Detail; Flutter uses AppBar (no dock). Four quick actions vs three. Copy `START ACTION` vs `Start by` |
| Add step 1 | `reference/06_add_start_app.png` | `app/live_wizard_start.png` | Mismatch | Extra title “Add a document”; camera/gallery on scan card; no `→`; notifications on prototype only. `comparisons/add_start_side_by_side.png` |
| Add identity | `reference/06_add_identity_app.png` | `app/live_wizard_continue.png` | Mismatch | Separate country, schema, and category fields; overlapping “Other” / “Country or region”. `comparisons/add_identity_side_by_side.png` |
| Add dates | `reference/06_add_dates_app.png` | `app/prior_device_add_document_dates.png` | Partial | Live dates step not recaptured. Copy/helper similar in source |
| Add planning | `reference/06_add_planning_app.png` | Source `add_document_screen.dart` `_RenewalStep` | Partial | Live not recaptured |
| Add review | `reference/06_add_review_app.png` | `app/prior_device_add_document_review.png` | Partial | Live save not completed |
| OCR review | `reference/07_ocr_review_app.png` | `app/prior_device_ocr_review.png` | Partial / live blocked | Prototype is a static 94% review. App uses real/heuristic confidence. Live ML Kit not run this session |
| Nav selected Docs / Me | Prototype dock | `app/live_documents_wallet.png`, `app/live_profile_tab.png` | Match (structure) | Selected pill + labels Home/Docs/Plans/Me |
| Profile / Notifications / Plans | Full Aura screens | Placeholders | Out of scope | Explicit placeholders |

Cursor’s embedded browser screenshot pipeline captured the studio chrome, not the phone. Prototype evidence used a separate Chromium session.

---

## E. Detailed discrepancies (ranked)

### P0

None observed. No crash, data-loss bug, or unusable Home/empty-wallet/add-start path on the installed debug app.

### P1 — major reference mismatch or broken interaction

1. **Home Action queue membership** — **Accepted product/data difference**  
   - Screen: Home  
   - Reference: “Action queue · 3 items” — Car insurance Urgent, Passport Upcoming, Streamio Upcoming.  
   - App: “Action queue · 1 item” — Car insurance only (`DocumentStatus.isAttentionStatus`: urgent/expired).  
   - Evidence: `reference/03_home_horizon_app.png` vs `app/home_snapshot_queue.png`  
   - Code: `lib/features/home/data/registry_item.dart`, `home_screen.dart`, `document_status.dart`  

2. **Home Horizon membership and date column** — membership **Accepted product/data difference**; Open calendar **Resolved**  
   - Reference: Gym 18 OCT, Driving licence 01 DEC; header action “Open calendar”.  
   - App: catalog remaining items in Horizon; **Open calendar** now opens the 90-day view.  
   - Evidence: `screenshots/registry_aura_phase1_3_corrections/horizon_90_day.png`  
   - Code: `home_screen.dart`, `horizon_90_day_screen.dart`

3. **Snapshot supporting copy and 90-day control** — `$47.99` **Accepted product/data difference**; 90-day **Resolved**  
   - App: `2 tracked`; 90-day view / metric / Open calendar open `Horizon90DayScreen`.  
   - Code: `home_metrics_row.dart`, `home_screen.dart`, `app_en.arb`

4. **Pulse CTA** — **Resolved**  
   - App: “Review now”; `AppRoutes.openCatalogItemReview`. Flag removed.  
   - Evidence: `screenshots/registry_aura_phase1_3_corrections/home_pulse.png`, `pulse_review_detail.png`

5. **Add Document identity overlap** — overlap **Resolved**; three controls **Accepted product/data difference**  
   - Labels: Country or region / Document type / Category. No Other-on-label collision.  
   - Evidence: `identity_empty.png`, `identity_selected.png`, `ocr_review_labels.png`, `review_and_save_labels.png`

6. **Wizard CTAs omit the prototype arrow and scan card extras** — Continue arrow **Resolved**; scan-card extras remain a P2 visual remainder (not this polish).

7. **Detail chrome** — **Accepted product/data difference** (full-screen AppBar, no dock)

### P2 — spacing, type, colour, copy, minor interaction

| Issue | Reference | App | File |
| --- | --- | --- | --- |
| Font | Inter | Android / Roboto (Material 2021) | `app_typography.dart` |
| Header date | `FRIDAY · 18 SEPTEMBER` | `SATURDAY · SEPTEMBER 19, 2026` | `home_header.dart` — live clock vs frozen prototype |
| Countdown | `2 DAYS` | `1 day` on 19 Sep 2026 | **Accepted product/data difference** |
| Profile orb | `SA` | `R` (`profileMonogram`) | **Accepted product/data difference** |
| Search `⌘K` | Shown | Correctly omitted | `registry_search_field.dart` |
| Pulse CTA height | 43px | Theme button 48px (a11y) | `registry_primary_button.dart` |
| Action queue meta | “Start renewal · 05 Oct 2026” + pill Urgent | “Start renewal soon · 05 Oct 2026” + “Action needed” | `home_attention_card.dart`, l10n |
| Horizon date format | `18` / `OCT` | `22` / `Sep 2026` (day + month year) | `home_upcoming_item.dart` |
| Dock icons | Custom glyphs ⌂ ▱ ＋ ◎ ◉ | Closest Material: home / article / add / circle+adjust / account_circle | **Resolved** (library difference documented) |
| Documents filters | All 3, Action, Upcoming, Active (no Overdue in prototype row) | All N, **Action needed**, Upcoming, Active, Overdue | **Resolved** for copy; Overdue chip remains product-complete |
| Add Document button | “＋ Add document” dashed ghost | “Add Document” filled (empty) / outlined (populated) | `documents_screen.dart` |
| OCR 94% | Static | Heuristic estimate | `document_ocr_parser.dart` |
| Onboarding / splash | Aura splash + 3 pages including scan | Existing onboarding, not Aura | Out of scope |
| Notification bell on wizard | Present | Absent (good; prototype chrome) | — |

Intentional / platform differences that still must be listed (not auto-accepted): no ⌘K; 48px tap targets; Android date picker; Roboto; no fake iPhone status bar / Dynamic Island; session-only storage.

---

## F. Functional QA

| Case | Result | Evidence |
| --- | --- | --- |
| Home search + clear | **PASS** (live) | `live_home_search_passport.png`, `live_home_search_cleared.png`, `live_home_search_empty.png` |
| Attention = urgent/expired only; impact does not qualify | **PASS** (live + tests) | Only Car insurance in queue despite High impact on Passport |
| Horizon order / 90-day window | **PASS** (logic) | Ordered by action date; snapshot `5` matches catalog within 90 days |
| Countdown vs dates | **PASS** | 20 Sep 2026 start → 1 day on 19 Sep 2026; dates `20 Sep 2026` / `05 Oct 2026` |
| Navigation dock Home / Docs / Me | **PASS** (live) | Selected states captured |
| Quick Add sheet | **PASS** (live) | `cal_add.png` |
| Review / 90-day / Open calendar | **FAIL** as prototype actions; **PASS** as documented no-ops | `kHomeHeroReviewOpensDetail`; no `onAction` on 90-day |
| Profile / Notifications destinations | **PASS** as placeholders | `live_profile_tab.png`; notifications live tap not cleanly captured (automation hit system UI) |
| Create exactly one document | **NOT TESTED** live | In-memory store empty after restart; wizard not saved. Tests cover save-once |
| Documents search/filter/featured pass | **NOT TESTED** live (empty wallet) | Tests in `document_experience_test.dart` |
| Open Detail | **NOT TESTED** live | Tests |
| Edit without duplicate | **NOT TESTED** live | Tests |
| Record renewal → one history entry | **NOT TESTED** live | Tests |
| Delete Cancel / Confirm | **NOT TESTED** live | Tests |
| Masked sensitive fields | **NOT TESTED** live | Tests + `maskedDocumentNumber` |
| Wizard step validation | **PASS** (live identity) | `live_identity_errors.png` |
| Back retains source step | **PASS** (live) | `live_back_to_source.png` |
| Review jump / dirty discard / dates DMY | **NOT TESTED** live | Tests PASS (`add_document_test.dart`) |
| Type vs category | **PARTIAL** | Live identity shows both schema “Other document” and category “Document type *” — easy to confuse |
| Dynamic fields survive save/detail/edit | **NOT TESTED** live | Tests |
| OCR live ML Kit | **NOT TESTED** | Gallery/camera path not completed. Tests use `FakeDocumentOcrService` |
| OCR does not auto-save | **PASS** (code/tests) | Confirm moves to later step; save is explicit |
| Final Save creates one document | **PASS** (tests) / **NOT TESTED** live | |

---

## G. Localization, accessibility, responsive

| Check | Result |
| --- | --- |
| English | Live Home / Docs empty / wizard |
| French | Widget tests (dates, overflow). **Not recaptured live** this session |
| Arabic RTL | Tests + prior Pixel 8 `prior_device_home_arabic_rtl.png`. **Not recaptured live** |
| Text 1.0 | Live |
| Text 1.5× / 1.8× | Tests + prior `prior_device_large_text.png`. **Not recaptured live**; empty wallet screens were **not** used as populated-card proof |
| Narrow phone | Pixel 8 411dp |
| Keyboard on form | **NOT TESTED** live |
| Long labels | Tests; compact dock at large text in `AppSpacing.compactNavigation` |
| Populated wallet/Detail at large text and Arabic | Prior captures / tests only this session |
| Tap targets | 48dp tokens; prototype 42–45px controls enlarged |
| Semantics | Search clear tooltip; dock labels; countdown semantics. Android UI Automator dump had **no** Flutter text nodes (`hierarchy` was a single FrameLayout) — a11y for TalkBack not verified live |

---

## H. Automated validation

```
flutter analyze
# No issues found! (ran in 1.4s)

flutter test
# 00:07 +150: All tests passed!

git diff --check
# exit 0 (no whitespace errors on tracked diffs; production tree had no staged/unstaged source changes)
```

**Native rebuild:** `flutter run -d emulator-5554 --debug` failed:

`java.net.ConnectException: Operation timed out` while Gradle wrapper downloaded `gradle-9.1.0-all.zip`.

Direct `gradle assembleDebug --offline` failed resolving `org.gradle.kotlin.kotlin-dsl:6.2.0`.

Audit therefore used the **preinstalled** debug APK, which matched current UI source for the screens captured. This is a process limitation, not an app defect.

Passing tests **do not** prove visual fidelity. Widget golden/screenshot tests with blocked glyphs were not used as visual acceptance.

---

## I. Known limitations (not new regressions)

1. **Session-only storage.** `InMemoryDocumentRepository`. Force-stop/process restart empties the wallet. Empty Documents after restart is expected, not a data-loss defect.
2. **Home catalog is mock** and is not the Documents repository. Pulse Review cannot open a real document.
3. **Placeholders:** Notifications, Profile, Subscriptions, Add subscription, Calendar (90-day / Open calendar).
4. **OCR.** Latin-script ML Kit; heuristic confidence; unsupported scripts/documents will fail or classify as generic. Prototype “94%” is marketing, not a calibrated score.
5. **Onboarding/Splash** are not the Aura prototype screens.
6. **Automation gap this session:** no Flutter Driver; UI Automator cannot see widgets; several taps hit Android system UI (Google). Live OCR, save, Detail, Arabic, and large-text populated states were not fully re-run.

---

## J. Prioritized correction checklist

Status after the corrections session:

1. **Identity dropdown overlap (P1)** — **Resolved**
2. **Action queue vs prototype (P1)** — **Accepted product/data difference**
3. **Pulse Review CTA (P1)** — **Resolved**
4. **90-day view / Open calendar (P1/P2)** — **Resolved**
5. **Snapshot subscription supporting line (P2)** — **Accepted product/data difference**
6. **Wizard primary labels (P2)** — **Resolved** (Continue + directional icon; Back/Save unchanged)
7. **Identity information architecture (three controls)** — **Accepted product/data difference** (labels distinct)
8. **Profile monogram (P2)** — **Accepted product/data difference**
9. **Documents filter chip “Action” vs “Action needed” (P2)** — **Resolved**
10. **Detail: dock vs AppBar** — **Accepted product/data difference**
11. **Re-run live QA after rebuild** — **Resolved** (see corrections session)

---

## K. Final git status and confirmation (corrections session)

Working tree includes production `lib/` and `test/` changes for this correction; **no commit and no push**.

- **Phase 4 was not started.**
- **applicationId remains `com.registry.app`.**
- Gradle wrapper distribution URL was not permanently changed.

Evidence: `screenshots/registry_aura_phase1_3_corrections/`.

---

## What was verified vs what remains

**Verified in the corrections + P2 polish sessions:** rebuild + install; Home search; Pulse Review now + catalog detail + back; 90-day chronological view; Quick Add; create Aadhaar document; identity labels; DMY expiry; Review & Save; ML Kit OCR review; populated wallet + Detail; Arabic RTL Home and Continue; 1.8× identity and Action needed chips; Continue directional arrow LTR/RTL; dock outlined/selected icons; `flutter analyze`; `flutter test` 162; `git diff --check`.

**Still open / limited:** live Record renewal blocked when new expiry equals previous expiry (tests cover a later date); live Delete confirm not completed (Cancel/menu captured; tests cover confirm); live Edit-without-duplicate not recaptured; French wizard Continue not recaptured live (l10n + tests cover Continuer); keyboard-open identity only briefly; Roboto vs Inter; prototype Unicode dock glyphs vs Material icons; prototype scan-card extras.

**Phase 4 recommendation:** READY FOR PHASE 4.
