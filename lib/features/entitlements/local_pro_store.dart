/// What the platform store reported for Local Pro.
///
/// [error] and [unavailable] are not an answer about ownership. Only [owned]
/// and [notOwned] are confirmed store answers.
enum StoreOwnership {
  /// A purchased, not revoked Local Pro transaction for this store account.
  owned,

  /// The store answered and has no owned Local Pro for this store account.
  notOwned,

  /// Only a pending purchase exists. It is not paid and does not unlock Pro.
  pending,

  /// Billing is not available here, for example no signed-in store account.
  unavailable,

  /// The query failed: no network, a timeout, or a store service error.
  error,
}

enum StoreTransactionStatus { pending, purchased, restored, cancelled, error }

/// A purchase update or an owned purchase from the store.
class StoreTransaction {
  const StoreTransaction({
    required this.productId,
    required this.status,
    this.purchaseId,
    this.needsCompletion = false,
    this.storeConfirmed = false,
    this.errorCode,
    this.handle,
  });

  final String productId;
  final StoreTransactionStatus status;
  final String? purchaseId;

  /// Play acknowledgement or StoreKit finish is still outstanding.
  final bool needsCompletion;

  /// The store client itself reported a paid purchase: Play Billing
  /// `PURCHASED`. A StoreKit update is not trusted on its own; StoreKit
  /// ownership is read again from verified `Transaction.all`.
  final bool storeConfirmed;

  final String? errorCode;

  /// Platform object used to acknowledge or finish. Never consumed.
  final Object? handle;
}

class OwnershipQuery {
  const OwnershipQuery(this.ownership, {this.unfinished = const []});

  final StoreOwnership ownership;

  /// Owned Local Pro transactions still waiting for acknowledge or finish.
  final List<StoreTransaction> unfinished;
}

enum StoreProductStatus { available, missing, unavailable, error }

/// The Local Pro product as the store returned it.
class StoreProduct {
  const StoreProduct._(this.status, {this.localizedPrice, this.handle});

  const StoreProduct.available({required String localizedPrice, Object? handle})
    : this._(
        StoreProductStatus.available,
        localizedPrice: localizedPrice,
        handle: handle,
      );

  const StoreProduct.missing() : this._(StoreProductStatus.missing);

  const StoreProduct.unavailable() : this._(StoreProductStatus.unavailable);

  const StoreProduct.error() : this._(StoreProductStatus.error);

  final StoreProductStatus status;

  /// Localized by Google Play or the App Store. The app never supplies one.
  final String? localizedPrice;
  final Object? handle;

  bool get isAvailable => status == StoreProductStatus.available;
}

/// Play Billing or StoreKit for the one Local Pro product.
///
/// Implementations buy a non-consumable, acknowledge or finish it, and never
/// consume it.
abstract class LocalProStore {
  Future<StoreProduct> loadProduct(String productId);

  /// Reads current ownership without showing store UI.
  Future<OwnershipQuery> queryOwnership(String productId);

  /// Asks the store to refresh this account's purchases. StoreKit shows its
  /// sign-in prompt here. Play Billing needs no separate step. Returns false
  /// when the refresh was dismissed or failed.
  Future<bool> syncWithStore();

  /// Starts the store purchase sheet. The result arrives on [transactions].
  Future<bool> buy(StoreProduct product);

  Stream<List<StoreTransaction>> get transactions;

  /// Acknowledges (Play) or finishes (StoreKit). Never consumes.
  Future<void> complete(StoreTransaction transaction);
}
