# Client reply draft (for Lahcene)

**Attach:** `The_Registry_App_Screens.pptx`  
**Do not rely on Google Drive** — attach the PPT (and APK only if he still wants it later).

---

Hi Lahcene,

Thank you for the clear feedback.

As requested, I am attaching a PowerPoint that walks through all the main screens of The Registry (Home, Documents, Add Document / scan, Subscriptions, Profile, Backup, App Lock, Notifications, and related flows), with screenshots from the current build. Please use this for review instead of the APK.

### About Firebase / third-party APIs

Understood: the app should not *require* third-party APIs.

**Important clarification:**  
The Registry is built **local-first**. Documents, subscriptions, reminders, backup/restore, and App Lock all work **on the device** with no cloud account and no paid API.

The two helpers below are **optional convenience features only**. Users can enter everything manually. If you prefer a 100% offline product, we can remove them from the build.

### Will Firebase cost money?

We use **Firebase AI Logic** only for the optional “scan document → fill form fields” feature (Gemini via Firebase).

- Firebase AI Logic itself has **no separate fee**.
- Usage goes through the **Gemini Developer API**.
- There is a **free tier** on Firebase’s no-cost Spark plan (no billing card required), with rate limits.
- A paid (Blaze) plan is only needed for **higher volume** or certain models.
- For normal personal/app testing scan volume, **expected cost is $0** on the free tier.

If we disable AI scan, Firebase is not needed for core app use.

### Will Gmail API cost money?

Gmail detection is also **optional** (Connect Gmail → read-only scan of billing/renewal emails).

- **Standard Gmail API use is free** today.
- Limits are very large for this kind of app; typical consumer usage stays well under them.
- Google has said that **only extreme usage above huge daily thresholds** may be billed later (details TBD later in 2026). For The Registry’s expected use, **expected cost is $0**.

Users can still add subscriptions manually, or import a bank CSV, without Gmail.

### What I need from you

1. Please review the attached PPT and share any screen / UX feedback.
2. Please confirm one product direction:
   - **A)** Keep optional AI scan + Gmail detection (then we need access to *your* Firebase / Google Cloud project so credentials are not on my personal account), or  
   - **B)** Remove both helpers so the shipped app has **no third-party API dependency**.

Happy to adjust the build either way.

Best regards,  
Shivam

---

## Quick answers (for you)

| Question | Short answer |
|---|---|
| Firebase se billing aayegi? | Core app: no. AI scan: free tier available; paid only if high volume. Expected ≈ $0 for this app. |
| Gmail API enable kiya to billing? | Standard use is free. Expected ≈ $0 for this app’s scan volume. |
| Client said no third-party API | Correct to offer Option B (remove AI + Gmail). Core features already work without them. |
| PPT location | `docs/client/The_Registry_App_Screens.pptx` |
