import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/registry_status_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../documents/domain/document_status.dart';
import '../../home/data/registry_date_formatter.dart';
import 'registry_subscription.dart';

abstract final class SubscriptionStatus {
  static RegistryStatus resolve(
    RegistrySubscription subscription, {
    DateTime? now,
  }) {
    if (subscription.isCancelled) {
      return RegistryStatus.neutral;
    }
    final paymentDays = RegistryDateFormatter.daysUntil(
      subscription.nextPaymentDate,
      now: now,
    );
    if (paymentDays < 0) {
      return RegistryStatus.expired;
    }
    final actionDays = RegistryDateFormatter.daysUntil(
      subscription.displayActionDate,
      now: now,
    );
    if (actionDays <= 0) {
      return RegistryStatus.urgent;
    }
    if (actionDays <= AppSpacing.horizonDays) {
      return RegistryStatus.upcoming;
    }
    return RegistryStatus.active;
  }

  static bool needsAttention(
    RegistrySubscription subscription, {
    DateTime? now,
  }) {
    if (subscription.isCancelled) {
      return false;
    }
    return DocumentStatus.isAttentionStatus(resolve(subscription, now: now));
  }

  static int attentionCount(
    Iterable<RegistrySubscription> subscriptions, {
    DateTime? now,
  }) {
    return subscriptions.where((item) => needsAttention(item, now: now)).length;
  }

  static String label(
    AppLocalizations l10n,
    RegistrySubscription subscription, {
    DateTime? now,
  }) {
    if (subscription.isCancelled) {
      return l10n.subscriptionCancelled;
    }
    return DocumentStatus.label(l10n, resolve(subscription, now: now));
  }

  static String remainingLabel(
    AppLocalizations l10n,
    RegistrySubscription subscription, {
    DateTime? now,
  }) {
    final status = resolve(subscription, now: now);
    final target = status == RegistryStatus.expired
        ? subscription.nextPaymentDate
        : subscription.displayActionDate;
    final days = RegistryDateFormatter.daysUntil(target, now: now);
    if (days == 0) {
      return l10n.dueToday;
    }
    if (days == 1) {
      return l10n.oneDayRemaining;
    }
    if (days > 1) {
      return l10n.daysRemaining(days);
    }
    if (days == -1) {
      return l10n.oneDayOverdue;
    }
    return l10n.daysOverdue(-days);
  }
}
