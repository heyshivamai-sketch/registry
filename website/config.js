/**
 * Regiday public website configuration (single source of truth).
 *
 * Set `playStoreUrl` to the verified Google Play Store listing URL once
 * Regiday is publicly listed. Both the primary Download CTA buttons and the
 * locally rendered QR code read from this single value.
 *
 * While `playStoreUrl` is empty, the website displays a "Coming soon" state
 * and never links to private QA APK builds.
 */
window.REGIDAY_CONFIG = {
  appName: 'Regiday',
  playStoreUrl: '',
  supportEmail: '',
  websiteUrl: '',
};
