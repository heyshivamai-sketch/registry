/// Play Console, App Store Connect, and backend verification for Local Pro.
///
/// [storeVerificationConfigured] stays false until every item below exists.
/// Flipping it without that work must not be done: the production catalog
/// and purchase service still refuse to invent a price or a plan.
///
/// Google Play Console, application id `com.registry.app`:
/// * Create a one-time product (not a subscription) with product id
///   `local_pro`.
/// * Activate it and attach a price in Play Console. The app reads that
///   localized price from the Play Billing query. It does not hard-code one.
/// * Enable the Play Developer API and a service account that can call
///   `purchases.products.get` for package `com.registry.app` and product
///   `local_pro`.
/// * Treat `purchaseState` purchased, and a matching product id, as the
///   only Android success signal. Acknowledge the purchase from the backend.
///
/// App Store Connect, bundle id `com.example.theRegistry`:
/// * Create a non-consumable in-app purchase with product id `local_pro`.
/// * Complete the Paid Applications agreement and add the localized price
///   in App Store Connect.
/// * Verify with the App Store Server API (`Get Transaction Info` or the
///   signed transaction JWS). Require product id `local_pro`, this bundle
///   id, and no revocation.
///
/// Backend in `server/billing`, which is not deployed by this build:
/// * Receive the store purchase token or signed transaction from the app.
/// * Call the store API above. Do not trust the client callback, a boolean
///   in the app, a backup file, or a debug switch.
/// * Return a signed grant only after the store call succeeds.
/// * An optional verified email can be attached to a new purchase. The
///   email confirmation itself is not a grant.
/// * The app may cache that signed grant. It must not cache a client-written
///   "premium" flag.
///
/// Setup, ownership, and the release checklist are in
/// `docs/setup/local_pro_billing.md`. [storeVerificationConfigured] stays
/// false until a real sandbox purchase has been verified.
///
/// The display name, application id, and bundle id stay as they are today.
/// A future brand such as Regiday is not a reason to change those ids
/// until the name is approved and the store listings are created for it.
abstract final class BillingConfiguration {
  static const localProProductId = 'local_pro';
  static const androidApplicationId = 'com.registry.app';
  static const iosBundleId = 'com.example.theRegistry';

  /// Empty until a deployment build is allowed to verify grants.
  static const String? verificationBaseUrl = null;
  static const grantPublicKeyBase64 = '';

  /// `sandbox` or `production` once that build is pointed at a live server.
  static const String? storeEnvironment = null;

  static const storeVerificationConfigured = false;
}
