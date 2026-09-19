import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_status.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

enum SubscriptionWalletFilter {
  all,
  actionNeeded,
  upcoming,
  active,
  overdue,
  cancelled,
}

abstract final class SubscriptionWallet {
  static bool matchesQuery(
    RegistrySubscription subscription,
    String query,
    AppLocalizations l10n,
  ) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    final haystack = <String>[
      subscription.serviceName,
      subscription.planName ?? '',
      SubscriptionCopy.category(l10n, subscription.category),
      subscription.amount.code,
      SubscriptionCopy.cycle(l10n, subscription.billingCycle),
      subscription.notes ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }

  static bool matchesFilter(
    RegistrySubscription subscription,
    SubscriptionWalletFilter filter, {
    DateTime? now,
  }) {
    if (filter == SubscriptionWalletFilter.all) {
      return true;
    }
    if (filter == SubscriptionWalletFilter.cancelled) {
      return subscription.isCancelled;
    }
    if (subscription.isCancelled) {
      return false;
    }
    final status = SubscriptionStatus.resolve(subscription, now: now);
    return switch (filter) {
      SubscriptionWalletFilter.all => true,
      SubscriptionWalletFilter.cancelled => false,
      SubscriptionWalletFilter.actionNeeded => status == RegistryStatus.urgent,
      SubscriptionWalletFilter.upcoming => status == RegistryStatus.upcoming,
      SubscriptionWalletFilter.active => status == RegistryStatus.active,
      SubscriptionWalletFilter.overdue => status == RegistryStatus.expired,
    };
  }

  static List<RegistrySubscription> visible(
    Iterable<RegistrySubscription> subscriptions, {
    required String query,
    required SubscriptionWalletFilter filter,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    return subscriptions
        .where((item) => matchesQuery(item, query, l10n))
        .where((item) => matchesFilter(item, filter, now: now))
        .toList(growable: false);
  }

  static int compareRelevance(
    RegistrySubscription a,
    RegistrySubscription b, {
    DateTime? now,
  }) {
    if (a.isCancelled != b.isCancelled) {
      return a.isCancelled ? 1 : -1;
    }
    final rankA = _rank(SubscriptionStatus.resolve(a, now: now));
    final rankB = _rank(SubscriptionStatus.resolve(b, now: now));
    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }
    final byAction = a.displayActionDate.compareTo(b.displayActionDate);
    if (byAction != 0) {
      return byAction;
    }
    return a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase());
  }

  static int _rank(RegistryStatus status) {
    return switch (status) {
      RegistryStatus.expired => 0,
      RegistryStatus.urgent => 1,
      RegistryStatus.upcoming => 2,
      RegistryStatus.active => 3,
      RegistryStatus.neutral => 4,
    };
  }
}
