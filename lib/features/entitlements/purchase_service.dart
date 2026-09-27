import 'package:the_registry/features/entitlements/billing_configuration.dart';
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

class PurchaseAttempt {
  const PurchaseAttempt({this.proof});

  /// Null unless a configured verifier accepted the store purchase.
  final VerifiedEntitlementProof? proof;
}

abstract class PurchaseService {
  Future<PurchaseAttempt> purchaseLocalPro();
}

/// No Play Billing or StoreKit call is configured, so there is no price.
class ProductionStoreProductSource implements StoreProductSource {
  const ProductionStoreProductSource();

  @override
  Future<StoreListing?> loadLocalPro() async {
    if (!BillingConfiguration.storeVerificationConfigured) {
      return null;
    }
    return null;
  }
}

/// Does not grant Local Pro. A store callback is not a verified proof.
class ProductionPurchaseService implements PurchaseService {
  const ProductionPurchaseService();

  @override
  Future<PurchaseAttempt> purchaseLocalPro() async {
    return const PurchaseAttempt();
  }
}
