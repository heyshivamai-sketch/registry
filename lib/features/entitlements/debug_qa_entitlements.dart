import 'package:flutter/foundation.dart';
import 'package:the_registry/features/entitlements/purchase_service.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/features/entitlements/verified_entitlement.dart';

/// Throws in release builds. Production startup must not construct this.
void ensureDebugQaBuild({required bool releaseMode}) {
  if (releaseMode) {
    throw StateError(
      'Debug QA entitlements are unavailable in release builds.',
    );
  }
}

/// In-memory plan for debug QA and tests. It is not a store verification.
class DebugQaVerifiedEntitlementSource extends ChangeNotifier
    implements VerifiedEntitlementSource {
  DebugQaVerifiedEntitlementSource({
    RegistryPlan plan = RegistryPlan.free,
    bool? releaseMode,
  }) {
    ensureDebugQaBuild(releaseMode: releaseMode ?? kReleaseMode);
    _plan = plan;
  }

  late RegistryPlan _plan;

  @override
  RegistryPlan get plan => _plan;

  void setPlanForDebugQa(RegistryPlan plan, {bool? releaseMode}) {
    ensureDebugQaBuild(releaseMode: releaseMode ?? kReleaseMode);
    if (_plan == plan) {
      return;
    }
    _plan = plan;
    notifyListeners();
  }

  @override
  void applyVerified(VerifiedEntitlementProof? proof) {
    ensureDebugQaBuild(releaseMode: kReleaseMode);
    // Purchase callbacks are not verification, including in debug QA.
    if (proof != null && proof.clientSuppliedOnly) {
      return;
    }
  }
}

/// Debug catalog. Production screens must use [ProductionStoreProductSource].
class DebugQaStoreProductSource implements StoreProductSource {
  DebugQaStoreProductSource({this.listing, bool? releaseMode}) {
    ensureDebugQaBuild(releaseMode: releaseMode ?? kReleaseMode);
  }

  final StoreListing? listing;

  @override
  Future<StoreListing?> loadLocalPro() async => listing;
}

/// Debug purchase that never writes a verified proof.
class DebugQaPurchaseService implements PurchaseService {
  DebugQaPurchaseService({this.proof, bool? releaseMode}) {
    ensureDebugQaBuild(releaseMode: releaseMode ?? kReleaseMode);
  }

  final VerifiedEntitlementProof? proof;
  var calls = 0;

  @override
  Future<PurchaseAttempt> purchaseLocalPro() async {
    calls += 1;
    return PurchaseAttempt(proof: proof);
  }
}
