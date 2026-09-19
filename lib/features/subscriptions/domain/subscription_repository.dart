import 'package:flutter/foundation.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

abstract class SubscriptionRepository implements Listenable {
  List<RegistrySubscription> get subscriptions;

  RegistrySubscription? findById(String id);

  Future<void> save(RegistrySubscription subscription);

  Future<bool> update(RegistrySubscription subscription);

  Future<bool> delete(String id);
}
