import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:the_registry/features/entitlements/purchase_service.dart';

/// The methods [InAppPurchase] uses for a non-consumable.
///
/// There is no consume or [InAppPurchase.buyConsumable] method here.
abstract class BillingPlugin {
  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});

  Future<void> restorePurchases({String? applicationUserName});

  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<void> completePurchase(PurchaseDetails purchase);
}

class InAppPurchaseBillingPlugin implements BillingPlugin {
  InAppPurchaseBillingPlugin({InAppPurchase? billing})
    : _billing = billing ?? InAppPurchase.instance;

  final InAppPurchase _billing;

  @override
  Future<bool> isAvailable() => _billing.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return _billing.queryProductDetails(identifiers);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) {
    return _billing.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (Platform.isIOS) {
      try {
        await _billing
            .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>()
            .sync();
      } catch (_) {
        // A dismissed App Store prompt still leaves on-device entitlements.
      }
    }
    return _billing.restorePurchases(applicationUserName: applicationUserName);
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _billing.purchaseStream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _billing.completePurchase(purchase);
  }
}

class InAppPurchaseLocalProStore implements LocalProStore {
  InAppPurchaseLocalProStore({BillingPlugin? plugin})
    : _plugin = plugin ?? InAppPurchaseBillingPlugin();

  final BillingPlugin _plugin;
  ProductDetails? _product;
  final _details = <String, PurchaseDetails>{};

  @override
  Future<StoreListing?> loadProduct(String productId) async {
    if (!await _plugin.isAvailable()) {
      return null;
    }
    final response = await _plugin.queryProductDetails({productId});
    if (response.error != null) {
      return null;
    }
    ProductDetails? match;
    for (final product in response.productDetails) {
      if (product.id == productId) {
        match = product;
      }
    }
    if (match == null) {
      return null;
    }
    final price = match.price.trim();
    if (price.isEmpty) {
      return null;
    }
    _product = match;
    return StoreListing(productId: match.id, localizedPrice: price);
  }

  @override
  Future<bool> buyNonConsumable({
    required String productId,
    required String applicationUserName,
  }) {
    final product = _product;
    if (product == null || product.id != productId) {
      return Future.value(false);
    }
    return _plugin.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: applicationUserName,
      ),
    );
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) {
    return _plugin.restorePurchases(applicationUserName: applicationUserName);
  }

  @override
  Stream<List<StorePurchaseUpdate>> get updates {
    return _plugin.purchaseStream.map((purchases) {
      return [for (final purchase in purchases) _remember(purchase)];
    });
  }

  @override
  Future<void> complete(String purchaseKey) {
    final details = _details[purchaseKey];
    if (details == null) {
      throw StateError('missing_purchase');
    }
    return _plugin.completePurchase(details);
  }

  StorePurchaseUpdate _remember(PurchaseDetails details) {
    final update = billingUpdateFromPurchase(details);
    final key = update.purchaseKey;
    if (key != null) {
      _details[key] = details;
    }
    return update;
  }
}

StorePurchaseUpdate billingUpdateFromPurchase(PurchaseDetails details) {
  final payload = _verificationPayload(details);
  return StorePurchaseUpdate(
    productId: details.productID,
    purchaseKey: details.purchaseID ?? payload,
    status: switch (details.status) {
      PurchaseStatus.pending => StorePurchaseStatus.pending,
      PurchaseStatus.purchased => StorePurchaseStatus.purchased,
      PurchaseStatus.restored => StorePurchaseStatus.restored,
      PurchaseStatus.canceled => StorePurchaseStatus.canceled,
      PurchaseStatus.error => StorePurchaseStatus.error,
    },
    platform: details.verificationData.source == 'google_play'
        ? 'google'
        : 'apple',
    payload: payload,
    pendingComplete: details.pendingCompletePurchase,
    errorCode: details.error?.code,
  );
}

String? _verificationPayload(PurchaseDetails details) {
  if (details is GooglePlayPurchaseDetails) {
    final token = details.billingClientPurchase.purchaseToken.trim();
    if (token.isNotEmpty) {
      return token;
    }
  }
  final server = details.verificationData.serverVerificationData.trim();
  if (server.isEmpty) {
    return null;
  }
  return server;
}
