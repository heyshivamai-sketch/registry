import 'package:flutter/foundation.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

abstract class SubscriptionRepository implements Listenable {
  List<RegistrySubscription> get subscriptions;

  RegistrySubscription? findById(String id);

  Future<void> save(RegistrySubscription subscription);

  /// Inserts every subscription in one step. A failure leaves the previous
  /// records in place.
  Future<void> saveAll(List<RegistrySubscription> subscriptions);

  Future<bool> update(RegistrySubscription subscription);

  Future<bool> delete(String id);
}
