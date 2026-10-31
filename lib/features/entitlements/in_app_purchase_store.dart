import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:the_registry/features/entitlements/local_pro_store.dart';

/// Play Billing on Android and StoreKit 2 on iOS through `in_app_purchase`.
///
/// Only [InAppPurchase.buyNonConsumable] and [InAppPurchase.completePurchase]
/// are used for buying. Nothing here calls `buyConsumable` or
/// `consumePurchase`. Construct this only when purchases are enabled: reading
/// [InAppPurchase.instance] connects to the store.
class InAppPurchaseLocalProStore implements LocalProStore {
  InAppPurchaseLocalProStore({InAppPurchase? billing})
    : _billing = billing ?? InAppPurchase.instance;

  final InAppPurchase _billing;

  @override
  Future<StoreProduct> loadProduct(String productId) async {
    try {
      if (!await _billing.isAvailable()) {
        return const StoreProduct.unavailable();
      }
      final response = await _billing.queryProductDetails({productId});
      for (final product in response.productDetails) {
        final price = product.price.trim();
        if (product.id == productId && price.isNotEmpty) {
          return StoreProduct.available(localizedPrice: price, handle: product);
        }
      }
      if (response.error != null) {
        return const StoreProduct.error();
      }
      return const StoreProduct.missing();
    } on PlatformException {
      return const StoreProduct.error();
    }
  }

  @override
  Future<OwnershipQuery> queryOwnership(String productId) async {
    try {
      if (Platform.isAndroid) {
        if (!await _billing.isAvailable()) {
          return const OwnershipQuery(StoreOwnership.unavailable);
        }
        final response = await _billing
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
            .queryPastPurchases();
        return androidOwnership(response, productId);
      }
      if (Platform.isIOS) {
        final all = await SK2Transaction.transactions();
        final unfinished = await SK2Transaction.unfinishedTransactions();
        return appleOwnership(all, unfinished, productId);
      }
      return const OwnershipQuery(StoreOwnership.unavailable);
    } on PlatformException {
      return const OwnershipQuery(StoreOwnership.error);
    }
  }

  @override
  Future<bool> syncWithStore() async {
    if (!Platform.isIOS) {
      return true;
    }
    try {
      await _billing
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>()
          .sync();
      return true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> buy(StoreProduct product) async {
    final details = product.handle;
    if (!product.isAvailable || details is! ProductDetails) {
      return false;
    }
    try {
      return await _billing.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<List<StoreTransaction>> get transactions {
    return _billing.purchaseStream.map(
      (purchases) => [for (final purchase in purchases) transaction(purchase)],
    );
  }

  @override
  Future<void> complete(StoreTransaction transaction) async {
    final handle = transaction.handle;
    if (handle is PurchaseDetails) {
      await _billing.completePurchase(handle);
    } else if (handle is SK2Transaction) {
      await SK2Transaction.finish(int.parse(handle.id));
    }
  }
}

/// Play Billing: only `PURCHASED` counts. `PENDING` never unlocks Pro.
OwnershipQuery androidOwnership(
  QueryPurchaseDetailsResponse response,
  String productId,
) {
  final unfinished = <StoreTransaction>[];
  var owned = false;
  var pending = false;
  for (final purchase in response.pastPurchases) {
    if (purchase.productID != productId) {
      continue;
    }
    final state = purchase.billingClientPurchase.purchaseState;
    if (state == PurchaseStateWrapper.purchased) {
      owned = true;
      if (!purchase.billingClientPurchase.isAcknowledged) {
        unfinished.add(transaction(purchase));
      }
    } else if (state == PurchaseStateWrapper.pending) {
      pending = true;
    }
  }
  if (owned) {
    return OwnershipQuery(StoreOwnership.owned, unfinished: unfinished);
  }
  if (response.error != null) {
    return const OwnershipQuery(StoreOwnership.error);
  }
  return OwnershipQuery(
    pending ? StoreOwnership.pending : StoreOwnership.notOwned,
  );
}

/// StoreKit 2: [all] is `Transaction.all` after StoreKit verification. A
/// transaction with a `revocationDate` was refunded or revoked.
OwnershipQuery appleOwnership(
  List<SK2Transaction> all,
  List<SK2Transaction> unfinished,
  String productId,
) {
  final owned = all.any(
    (item) =>
        item.productId == productId &&
        !appleTransactionRevoked(item.jsonRepresentation),
  );
  if (!owned) {
    return const OwnershipQuery(StoreOwnership.notOwned);
  }
  return OwnershipQuery(
    StoreOwnership.owned,
    unfinished: [
      for (final item in unfinished)
        if (item.productId == productId &&
            !appleTransactionRevoked(item.jsonRepresentation))
          StoreTransaction(
            productId: item.productId,
            status: StoreTransactionStatus.purchased,
            purchaseId: item.id,
            needsCompletion: true,
            handle: item,
          ),
    ],
  );
}

/// Reads `revocationDate` from the StoreKit transaction JSON.
///
/// A payload that cannot be read is treated as revoked so it cannot unlock
/// Local Pro.
bool appleTransactionRevoked(String? json) {
  if (json == null || json.isEmpty) {
    return true;
  }
  try {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?>) {
      return true;
    }
    return decoded['revocationDate'] != null;
  } on FormatException {
    return true;
  }
}

StoreTransaction transaction(PurchaseDetails details) {
  var status = switch (details.status) {
    PurchaseStatus.pending => StoreTransactionStatus.pending,
    PurchaseStatus.purchased => StoreTransactionStatus.purchased,
    PurchaseStatus.restored => StoreTransactionStatus.restored,
    PurchaseStatus.canceled => StoreTransactionStatus.cancelled,
    PurchaseStatus.error => StoreTransactionStatus.error,
  };
  var playPurchased = false;
  if (details is GooglePlayPurchaseDetails) {
    playPurchased =
        details.billingClientPurchase.purchaseState ==
        PurchaseStateWrapper.purchased;
    if (!playPurchased && status == StoreTransactionStatus.purchased) {
      status = StoreTransactionStatus.pending;
    }
  }
  return StoreTransaction(
    productId: details.productID,
    status: status,
    purchaseId: details.purchaseID,
    needsCompletion:
        details.pendingCompletePurchase &&
        status != StoreTransactionStatus.pending,
    storeConfirmed: playPurchased && status == StoreTransactionStatus.purchased,
    errorCode: details.error?.code,
    handle: details,
  );
}
