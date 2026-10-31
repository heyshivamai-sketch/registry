# Responsive UI and multi-image capture refresh

Implemented:
- Regiday Pro: shorter copy, layered pass illustration, premium accent, and a
  one-time entrance animation that respects reduced-motion settings.
- Home: decorative document art no longer competes with the Documents label;
  metric cards stack on narrow screens and at larger text sizes.
- Documents and Subscriptions: notification controls no longer crowd page titles.
- Toasts: rounded, dismissible styling, corrected dock offset, readable type,
  and a constrained width on tablet home screens.
- Document capture: one primary image plus up to five optional images, explicit
  Scan all images action, editable category fields, and paged image previews.
- Persistence: extra images/categories round-trip through SQLite schema v3 and
  encrypted backup payload v2; existing v1 backups still import.
- Gemini: Firebase AI Logic with App Check, one request containing all images,
  structured extraction review, bounded requests, and accurate disclosure.

Validation:
- `flutter analyze --no-pub`
- `flutter test --reporter compact`: 358 tests passed.
- Focused Firebase AI service tests use synthetic bytes and fake responses.
- Rendered whole-word checks on Home, Documents, Subscriptions, Profile, Pro,
  and document capture at widths 320, 390, 768, 1024 and text scales 1.0 and 1.8.
- Existing Arabic, French, RTL, large-text, persistence, and backup tests pass.
- Front/back images are not scanned until the explicit scan action.
- Results from a scan started before an image is removed cannot overwrite the form.
- Toast bounds checked against the navigation dock.

Previews: `screenshots/responsive_refresh/` (home, pro, toast, scan_source).
These are Flutter widget renders, not physical-device captures.

Live Gemini requests are excluded from automated tests. Firebase and App Check
must be configured before device testing; an unconfigured build disables AI Scan
and keeps manual entry available. See `docs/setup/gemini_scanning.md`.
