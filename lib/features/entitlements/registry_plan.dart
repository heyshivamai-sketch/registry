import 'package:flutter/foundation.dart';

/// Commercial plan for record-count limits and ads.
///
/// This is not a statement about database encryption, backup encryption,
/// or cloud services.
enum RegistryPlan { free, localPro }

/// Where the current plan comes from.
///
/// Production uses the platform store through `LocalProEntitlement`. A
/// backup file, a debug switch, or a value typed into the app is never a
/// source.
abstract class RegistryPlanSource implements Listenable {
  RegistryPlan get plan;

  /// False for Local Pro, and while a returning Local Pro user is still being
  /// resolved by the store.
  bool get adsMayBeRequested;
}
