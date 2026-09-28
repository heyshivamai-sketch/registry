import 'package:flutter/foundation.dart';
import 'package:the_registry/features/entitlements/billing_configuration.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';

/// A purchase result after a store or backend check.
///
/// [clientSuppliedOnly] marks a callback, backup flag, or other value the
/// app produced by itself. Those proofs never change the plan.
class VerifiedEntitlementProof {
  const VerifiedEntitlementProof({
    required this.productId,
    required this.accepted,
    this.clientSuppliedOnly = false,
    this.revoked = false,
  });

  final String productId;
  final bool accepted;
  final bool clientSuppliedOnly;

  /// A store refund, revocation, or binding move. Ignored when the proof is
  /// only a client claim.
  final bool revoked;
}

/// Decides the plan from a proof. Production always passes
/// [BillingConfiguration.storeVerificationConfigured], which is false until
/// Play Console, App Store Connect, and the backend verifier exist.
RegistryPlan planAfterProof({
  required RegistryPlan current,
  required bool storeVerificationConfigured,
  required VerifiedEntitlementProof? proof,
}) {
  if (!storeVerificationConfigured || proof == null) {
    return current;
  }
  if (proof.clientSuppliedOnly) {
    return current;
  }
  if (proof.productId != BillingConfiguration.localProProductId) {
    return current;
  }
  if (proof.revoked) {
    return RegistryPlan.free;
  }
  if (!proof.accepted) {
    return current;
  }
  return RegistryPlan.localPro;
}

abstract class VerifiedEntitlementSource implements Listenable {
  RegistryPlan get plan;

  /// Applies a proof. Client booleans and unverified callbacks are ignored
  /// by the production implementation.
  void applyVerified(VerifiedEntitlementProof? proof);
}

class ProductionVerifiedEntitlementSource extends ChangeNotifier
    implements VerifiedEntitlementSource {
  ProductionVerifiedEntitlementSource({bool? storeVerificationConfigured})
    : _configured =
          storeVerificationConfigured ??
          BillingConfiguration.storeVerificationConfigured;

  final bool _configured;
  RegistryPlan _plan = RegistryPlan.free;

  @override
  RegistryPlan get plan => _plan;

  @override
  void applyVerified(VerifiedEntitlementProof? proof) {
    final next = planAfterProof(
      current: _plan,
      storeVerificationConfigured: _configured,
      proof: proof,
    );
    if (next == _plan) {
      return;
    }
    _plan = next;
    notifyListeners();
  }
}
