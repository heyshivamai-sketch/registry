import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_estimate.dart';

import 'support/sample_subscription.dart';

void main() {
  test('parses USD amounts into minor units', () {
    expect(MoneyParser.parse('12.99', 'USD').minorUnits, 1299);
    expect(MoneyParser.parse('0', 'USD').minorUnits, 0);
    expect(MoneyParser.parse('0.00', 'usd').minorUnits, 0);
    expect(MoneyParser.parse('12', 'USD').minorUnits, 1200);
  });

  test('parses zero-decimal JPY and rejects extra fractions', () {
    expect(MoneyParser.parse('100', 'JPY').minorUnits, 100);
    expect(
      () => MoneyParser.parse('100.5', 'JPY'),
      throwsA(isA<MoneyParseException>()),
    );
  });

  test('rejects negative and invalid amounts', () {
    expect(
      () => MoneyParser.parse('-1', 'USD'),
      throwsA(isA<MoneyParseException>()),
    );
    expect(
      () => MoneyParser.parse('12.999', 'USD'),
      throwsA(isA<MoneyParseException>()),
    );
    expect(
      () => MoneyParser.parse('', 'USD'),
      throwsA(isA<MoneyParseException>()),
    );
  });

  test('formats with an unambiguous currency code', () {
    expect(
      MoneyFormat.format(
        const Money(minorUnits: 1299, currencyCode: 'USD'),
        'en',
      ),
      '12.99 USD',
    );
    expect(
      MoneyFormat.format(
        const Money(minorUnits: 100, currencyCode: 'JPY'),
        'en',
      ),
      '100 JPY',
    );
  });

  test('weekly quarterly yearly normalize with exact arithmetic', () {
    final weekly = sampleSubscription(
      minorUnits: 1000,
      billingCycle: BillingCycle.weekly,
    );
    final quarterly = sampleSubscription(
      id: 'q',
      minorUnits: 3000,
      billingCycle: BillingCycle.quarterly,
    );
    final yearly = sampleSubscription(
      id: 'y',
      minorUnits: 12000,
      billingCycle: BillingCycle.yearly,
    );

    expect(
      SubscriptionEstimate.monthlyShare(weekly).roundHalfUp().minorUnits,
      4333,
    );
    expect(
      SubscriptionEstimate.monthlyShare(quarterly).roundHalfUp().minorUnits,
      1000,
    );
    expect(
      SubscriptionEstimate.monthlyShare(yearly).roundHalfUp().minorUnits,
      1000,
    );
  });

  test('does not add mixed currencies together', () {
    final totals = SubscriptionEstimate.monthlyTotals([
      sampleSubscription(id: 'usd', minorUnits: 1299),
      sampleSubscription(id: 'eur', minorUnits: 1000, currencyCode: 'EUR'),
      sampleSubscription(
        id: 'cancelled',
        minorUnits: 9999,
        lifecycle: SubscriptionLifecycle.cancelled,
      ),
    ]);

    expect(totals.map((item) => '${item.code}:${item.minorUnits}'), [
      'EUR:1000',
      'USD:1299',
    ]);
  });
}
