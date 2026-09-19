import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/home/data/mock_registry_catalog.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_status.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class RegistryIds {
  static String document(String id) => 'document:$id';
  static String subscription(String id) => 'subscription:$id';

  static bool isDocument(String id) => id.startsWith('document:');
  static bool isSubscription(String id) => id.startsWith('subscription:');

  static String sourceId(String id) {
    final index = id.indexOf(':');
    return index < 0 ? id : id.substring(index + 1);
  }
}

abstract final class RegistryReadModel {
  static List<RegistryItem> fromRepositories({
    required Iterable<RegistryDocument> documents,
    required Iterable<RegistrySubscription> subscriptions,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    return [
      for (final document in documents) fromDocument(document, l10n, now: now),
      for (final subscription in subscriptions)
        fromSubscription(subscription, l10n, now: now),
    ];
  }

  static RegistryItem fromDocument(
    RegistryDocument document,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final status = DocumentStatus.resolve(document, now: now);
    return RegistryItem(
      id: RegistryIds.document(document.id),
      sourceId: document.id,
      type: RegistryItemType.document,
      titleText: document.name,
      status: status,
      impact: _impact(document.impact),
      impactScore: _score(document.impact),
      actionDate: document.displayActionDate,
      dueDate: document.expiryDate,
      isHero: false,
      needsAttention: DocumentStatus.isAttentionStatus(status),
      searchTerms: [
        document.name,
        document.ownerName ?? '',
        document.issuingAuthority ?? '',
      ],
    );
  }

  static RegistryItem fromSubscription(
    RegistrySubscription subscription,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final status = SubscriptionStatus.resolve(subscription, now: now);
    return RegistryItem(
      id: RegistryIds.subscription(subscription.id),
      sourceId: subscription.id,
      type: RegistryItemType.subscription,
      titleText: subscription.serviceName,
      status: status,
      impact: _impact(subscription.impact),
      impactScore: _score(subscription.impact),
      actionDate: subscription.displayActionDate,
      dueDate: subscription.nextPaymentDate,
      isHero: false,
      needsAttention: SubscriptionStatus.needsAttention(subscription, now: now),
      searchTerms: [
        subscription.serviceName,
        subscription.planName ?? '',
        SubscriptionCopy.category(l10n, subscription.category),
      ],
    );
  }

  static List<RegistryItem> attentionItems(Iterable<RegistryItem> source) {
    return MockRegistryCatalog.byImpact(
      source.where((item) => item.requiresAttention),
    );
  }

  static RegistryItem? pulseItem(Iterable<RegistryItem> source) {
    final attention = attentionItems(source);
    return attention.isEmpty ? null : attention.first;
  }

  static List<RegistryItem> horizonItems(
    Iterable<RegistryItem> source, {
    DateTime? now,
  }) {
    return MockRegistryCatalog.byUpcomingDate(
      source.where(
        (item) =>
            !item.requiresAttention && item.status == RegistryStatus.upcoming,
      ),
    );
  }

  static RegistryImpact _impact(DocumentImpact impact) {
    return switch (impact) {
      DocumentImpact.critical || DocumentImpact.high => RegistryImpact.high,
      DocumentImpact.medium => RegistryImpact.medium,
      DocumentImpact.low => RegistryImpact.low,
    };
  }

  static int _score(DocumentImpact impact) {
    return switch (impact) {
      DocumentImpact.critical => 100,
      DocumentImpact.high => 80,
      DocumentImpact.medium => 50,
      DocumentImpact.low => 20,
    };
  }
}
