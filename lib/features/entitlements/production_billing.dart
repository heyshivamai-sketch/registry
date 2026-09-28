import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/entitlements/billing_records.dart';
import 'package:the_registry/features/entitlements/billing_runtime.dart';
import 'package:the_registry/features/entitlements/http_billing_client.dart';
import 'package:the_registry/features/entitlements/in_app_purchase_store.dart';
import 'package:the_registry/features/entitlements/platform_billing_coordinator.dart';
import 'package:the_registry/features/entitlements/purchase_service.dart';

class ProductionBilling {
  const ProductionBilling({required this.purchases, required this.products});

  final PurchaseService purchases;
  final StoreProductSource products;
}

/// Opens Play Billing and StoreKit only when [BillingRuntime.isReady].
///
/// The default build is not ready, so this returns null and does not construct
/// the store plugin.
Future<ProductionBilling?> openProductionBilling({
  Clock clock = const Clock(),
  Future<Directory> Function()? supportDirectory,
}) async {
  const runtime = BillingRuntime();
  if (!runtime.isReady) {
    return null;
  }
  final root = await (supportDirectory ?? getApplicationSupportDirectory)();
  final directory = Directory('${root.path}/billing');
  await directory.create(recursive: true);
  final url = Uri.parse(runtime.verificationBaseUrl!);
  final store = InAppPurchaseLocalProStore();
  final coordinator = PlatformBillingCoordinator(
    runtime: runtime,
    store: store,
    verifier: HttpBillingVerificationClient(url),
    installationIds: FileInstallationIdStore(
      File('${directory.path}/installation_id'),
    ),
    cache: FileEntitlementCache(File('${directory.path}/grant.json')),
    pending: FilePendingPurchaseStore(File('${directory.path}/pending.json')),
    clock: clock,
  );
  return ProductionBilling(
    purchases: ProductionPurchaseService(coordinator: coordinator),
    products: ProductionStoreProductSource(runtime: runtime, store: store),
  );
}
