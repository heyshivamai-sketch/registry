import 'package:the_registry/features/entitlements/billing_configuration.dart';

/// What this build is allowed to ask the store and the billing server.
///
/// [isReady] is false in the default build because
/// [BillingConfiguration.storeVerificationConfigured] is false and the server
/// URL, grant key, and environment are empty.
class BillingRuntime {
  const BillingRuntime({
    this.storeVerificationConfigured =
        BillingConfiguration.storeVerificationConfigured,
    this.productId = BillingConfiguration.localProProductId,
    this.androidApplicationId = BillingConfiguration.androidApplicationId,
    this.iosBundleId = BillingConfiguration.iosBundleId,
    this.verificationBaseUrl = BillingConfiguration.verificationBaseUrl,
    this.grantPublicKeyBase64 = BillingConfiguration.grantPublicKeyBase64,
    this.environment = BillingConfiguration.storeEnvironment,
  });

  final bool storeVerificationConfigured;
  final String productId;
  final String androidApplicationId;
  final String iosBundleId;
  final String? verificationBaseUrl;
  final String grantPublicKeyBase64;

  /// `sandbox` or `production`.
  final String? environment;

  bool get isReady {
    final url = verificationBaseUrl;
    final storeEnvironment = environment;
    return storeVerificationConfigured &&
        url != null &&
        url.isNotEmpty &&
        grantPublicKeyBase64.isNotEmpty &&
        (storeEnvironment == 'sandbox' || storeEnvironment == 'production');
  }
}
