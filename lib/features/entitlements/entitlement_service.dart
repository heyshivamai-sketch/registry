import 'package:flutter/foundation.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/entitlements/entitlement_policy.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/features/entitlements/verified_entitlement.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_repository.dart';

/// Reads the verified plan and admits new records in one place.
class EntitlementService extends ChangeNotifier {
  EntitlementService({
    required this.documents,
    required this.subscriptions,
    required VerifiedEntitlementSource source,
  }) {
    _source = source;
    _source.addListener(notifyListeners);
  }

  final DocumentRepository documents;
  final SubscriptionRepository subscriptions;
  late final VerifiedEntitlementSource _source;

  RegistryPlan get plan => _source.plan;

  EntitlementDecision admitNewDocuments({int additional = 1}) {
    return EntitlementPolicy.admitDocuments(
      plan: plan,
      currentCount: documents.documents.length,
      additional: additional,
    );
  }

  EntitlementDecision admitNewSubscriptions({int additional = 1}) {
    return EntitlementPolicy.admitSubscriptions(
      plan: plan,
      currentCount: subscriptions.subscriptions.length,
      additional: additional,
    );
  }

  void applyVerified(VerifiedEntitlementProof? proof) {
    _source.applyVerified(proof);
  }

  @override
  void dispose() {
    _source.removeListener(notifyListeners);
    super.dispose();
  }
}

/// New-record writes. Widgets call this instead of checking plan limits.
class RegistryWrites {
  RegistryWrites({
    required this.documents,
    required this.subscriptions,
    required this.entitlements,
  });

  final DocumentRepository documents;
  final SubscriptionRepository subscriptions;
  final EntitlementService entitlements;

  Future<void> createDocument(RegistryDocument document) async {
    if (documents.findById(document.id) != null) {
      throw const DuplicateRecordId();
    }
    final decision = entitlements.admitNewDocuments();
    if (!decision.allowed) {
      throw EntitlementDenied(decision);
    }
    await documents.save(document);
  }

  Future<void> createSubscription(RegistrySubscription subscription) async {
    if (subscriptions.findById(subscription.id) != null) {
      throw const DuplicateRecordId();
    }
    final decision = entitlements.admitNewSubscriptions();
    if (!decision.allowed) {
      throw EntitlementDenied(decision);
    }
    await subscriptions.save(subscription);
  }

  Future<void> createSubscriptions(
    List<RegistrySubscription> subscriptions,
  ) async {
    if (subscriptions.isEmpty) {
      return;
    }
    final seen = <String>{};
    for (final subscription in subscriptions) {
      if (!seen.add(subscription.id) ||
          this.subscriptions.findById(subscription.id) != null) {
        throw const DuplicateRecordId();
      }
    }
    final decision = entitlements.admitNewSubscriptions(
      additional: subscriptions.length,
    );
    if (!decision.allowed) {
      throw EntitlementDenied(decision);
    }
    await this.subscriptions.saveAll(subscriptions);
  }
}
