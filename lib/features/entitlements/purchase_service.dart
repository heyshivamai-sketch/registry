import 'package:the_registry/features/entitlements/billing_runtime.dart';
import 'package:the_registry/features/entitlements/verified_entitlement.dart';

/// A price the store itself localized. The app must not invent one.
class StoreListing {
  const StoreListing({required this.productId, required this.localizedPrice});

  final String productId;
  final String localizedPrice;
}

abstract class StoreProductSource {
  Future<StoreListing?> loadLocalPro();
}

enum PurchaseFlowOutcome {
  unavailable,
  verified,
  pending,
  cancelled,
  failed,
  restored,
  bindingMismatch,
  unchanged,
  revoked,
}

class PurchaseAttempt {
  const PurchaseAttempt({
    this.proof,
    this.outcome = PurchaseFlowOutcome.unavailable,
    this.recoveryCode,
  });

  /// Null unless a configured verifier accepted the store purchase.
  final VerifiedEntitlementProof? proof;
  final PurchaseFlowOutcome outcome;

  /// Shown when this installation first receives the binding.
  final String? recoveryCode;
}

abstract class PurchaseService {
  Future<PurchaseAttempt> purchaseLocalPro();

  Future<PurchaseAttempt> restoreLocalPro({String? recoveryCode});

  /// Loads a signed grant, if this build is allowed to use one.
  Future<void> warmUp(VerifiedEntitlementSource source) async {}
}

/// Asks the store and the billing server. Absent when verification is not ready.
abstract class BillingCoordinator {
  BillingRuntime get runtime;

  Future<VerifiedEntitlementProof?> warmUp();

  Future<PurchaseAttempt> purchaseLocalPro();

  Future<PurchaseAttempt> restoreLocalPro({String? recoveryCode});
}

/// No Play Billing or StoreKit call is configured, so there is no price.
class ProductionStoreProductSource implements StoreProductSource {
  const ProductionStoreProductSource({
    this.runtime = const BillingRuntime(),
    this.store,
  });

  final BillingRuntime runtime;
  final LocalProStore? store;

  @override
  Future<StoreListing?> loadLocalPro() async {
    final store = this.store;
    if (!runtime.isReady || store == null) {
      return null;
    }
    return store.loadProduct(runtime.productId);
  }
}

/// Does not grant Local Pro unless [coordinator] is ready.
///
/// The default constructor has no coordinator. A store callback is not a
/// verified proof.
class ProductionPurchaseService implements PurchaseService {
  const ProductionPurchaseService({this.coordinator});

  final BillingCoordinator? coordinator;

  @override
  Future<PurchaseAttempt> purchaseLocalPro() {
    return _forward((coordinator) => coordinator.purchaseLocalPro());
  }

  @override
  Future<PurchaseAttempt> restoreLocalPro({String? recoveryCode}) {
    return _forward(
      (coordinator) => coordinator.restoreLocalPro(recoveryCode: recoveryCode),
    );
  }

  @override
  Future<void> warmUp(VerifiedEntitlementSource source) async {
    final coordinator = this.coordinator;
    if (coordinator == null || !coordinator.runtime.isReady) {
      return;
    }
    final proof = await coordinator.warmUp();
    if (proof != null) {
      source.applyVerified(proof);
    }
  }

  Future<PurchaseAttempt> _forward(
    Future<PurchaseAttempt> Function(BillingCoordinator coordinator) call,
  ) {
    final coordinator = this.coordinator;
    if (coordinator == null || !coordinator.runtime.isReady) {
      return Future.value(const PurchaseAttempt());
    }
    return call(coordinator);
  }
}

/// Store catalog and purchase updates. Implementations must not consume
/// Local Pro.
abstract class LocalProStore {
  Future<StoreListing?> loadProduct(String productId);

  Future<bool> buyNonConsumable({
    required String productId,
    required String applicationUserName,
  });

  Future<void> restorePurchases({String? applicationUserName});

  Stream<List<StorePurchaseUpdate>> get updates;

  Future<void> complete(String purchaseKey);
}

enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

class StorePurchaseUpdate {
  const StorePurchaseUpdate({
    required this.productId,
    required this.status,
    required this.platform,
    required this.pendingComplete,
    this.purchaseKey,
    this.payload,
    this.errorCode,
  });

  final String productId;
  final String? purchaseKey;
  final StorePurchaseStatus status;

  /// Google purchase token or Apple signed transaction. Never a typed receipt.
  final String? payload;
  final String platform;
  final bool pendingComplete;
  final String? errorCode;
}
