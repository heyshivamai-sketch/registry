import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

abstract final class SubscriptionEstimate {
  static MoneyRational monthlyShare(RegistrySubscription subscription) {
    final amount = subscription.amount;
    return switch (subscription.billingCycle) {
      BillingCycle.weekly => MoneyRational(
        numerator: BigInt.from(amount.minorUnits) * BigInt.from(52),
        denominator: BigInt.from(12),
        currencyCode: amount.code,
      ),
      BillingCycle.monthly => MoneyRational.fromMinor(
        amount.minorUnits,
        amount.code,
      ),
      BillingCycle.quarterly => MoneyRational(
        numerator: BigInt.from(amount.minorUnits),
        denominator: BigInt.from(3),
        currencyCode: amount.code,
      ),
      BillingCycle.yearly => MoneyRational(
        numerator: BigInt.from(amount.minorUnits),
        denominator: BigInt.from(12),
        currencyCode: amount.code,
      ),
    };
  }

  static List<Money> monthlyTotals(
    Iterable<RegistrySubscription> subscriptions,
  ) {
    final totals = <String, MoneyRational>{};
    for (final subscription in subscriptions) {
      if (!subscription.isActive) {
        continue;
      }
      final share = monthlyShare(subscription);
      final existing = totals[share.currencyCode];
      totals[share.currencyCode] = existing == null ? share : existing + share;
    }
    final codes = totals.keys.toList()..sort();
    return [for (final code in codes) totals[code]!.roundHalfUp()];
  }
}
