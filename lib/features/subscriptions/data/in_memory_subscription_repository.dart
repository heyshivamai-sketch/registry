import 'package:flutter/foundation.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_repository.dart';

class InMemorySubscriptionRepository extends ChangeNotifier
    implements SubscriptionRepository {
  final List<RegistrySubscription> _subscriptions = [];

  @override
  List<RegistrySubscription> get subscriptions =>
      List.unmodifiable(_subscriptions);

  @override
  RegistrySubscription? findById(String id) {
    for (final subscription in _subscriptions) {
      if (subscription.id == id) {
        return subscription;
      }
    }
    return null;
  }

  @override
  Future<void> save(RegistrySubscription subscription) async {
    _subscriptions.insert(0, subscription);
    notifyListeners();
  }

  @override
  Future<void> saveAll(List<RegistrySubscription> subscriptions) async {
    if (subscriptions.isEmpty) {
      return;
    }
    final seen = <String>{};
    for (final subscription in subscriptions) {
      if (!seen.add(subscription.id) || findById(subscription.id) != null) {
        throw StateError(
          'A subscription with id ${subscription.id} already exists.',
        );
      }
    }
    for (final subscription in subscriptions.reversed) {
      _subscriptions.insert(0, subscription);
    }
    notifyListeners();
  }

  @override
  Future<bool> update(RegistrySubscription subscription) async {
    final index = _subscriptions.indexWhere(
      (item) => item.id == subscription.id,
    );
    if (index < 0) {
      return false;
    }
    _subscriptions[index] = subscription;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> delete(String id) async {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index < 0) {
      return false;
    }
    _subscriptions.removeAt(index);
    notifyListeners();
    return true;
  }

  void replaceContents(
    List<RegistrySubscription> subscriptions, {
    bool notify = true,
  }) {
    _subscriptions
      ..clear()
      ..addAll(subscriptions);
    if (notify) {
      notifyListeners();
    }
  }

  void notifyReplacement() {
    notifyListeners();
  }
}
