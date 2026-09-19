import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_status.dart';

import 'support/sample_subscription.dart';

void main() {
  final now = DateTime(2026, 9, 19);

  test('overdue when next payment is before today', () {
    final plan = sampleSubscription(
      nextPaymentDate: DateTime(2026, 9, 18),
      decideByDate: DateTime(2026, 9, 17),
    );
    expect(SubscriptionStatus.resolve(plan, now: now), RegistryStatus.expired);
    expect(SubscriptionStatus.needsAttention(plan, now: now), isTrue);
  });

  test('action needed when decide-by is today or earlier', () {
    final today = sampleSubscription(
      nextPaymentDate: DateTime(2026, 10, 1),
      decideByDate: DateTime(2026, 9, 19),
    );
    final yesterday = sampleSubscription(
      id: 'y',
      nextPaymentDate: DateTime(2026, 10, 1),
      decideByDate: DateTime(2026, 9, 18),
    );
    expect(SubscriptionStatus.resolve(today, now: now), RegistryStatus.urgent);
    expect(
      SubscriptionStatus.resolve(yesterday, now: now),
      RegistryStatus.urgent,
    );
  });

  test('uses next payment when decide-by is absent', () {
    final plan = sampleSubscription(
      nextPaymentDate: DateTime(2026, 9, 19),
      includeDecideBy: false,
    );
    expect(SubscriptionStatus.resolve(plan, now: now), RegistryStatus.urgent);
  });

  test('upcoming within 90 days and active beyond', () {
    final upcoming = sampleSubscription(
      nextPaymentDate: DateTime(2026, 12, 16),
      decideByDate: DateTime(2026, 12, 1),
    );
    final active = sampleSubscription(
      id: 'far',
      nextPaymentDate: DateTime(2027, 1, 1),
      decideByDate: DateTime(2026, 12, 20),
    );
    expect(
      SubscriptionStatus.resolve(upcoming, now: now),
      RegistryStatus.upcoming,
    );
    expect(SubscriptionStatus.resolve(active, now: now), RegistryStatus.active);
    expect(SubscriptionStatus.needsAttention(upcoming, now: now), isFalse);
  });

  test('tomorrow is upcoming not overdue', () {
    final plan = sampleSubscription(
      nextPaymentDate: DateTime(2026, 9, 20),
      decideByDate: DateTime(2026, 9, 20),
    );
    expect(SubscriptionStatus.resolve(plan, now: now), RegistryStatus.upcoming);
  });

  test('horizon boundary is upcoming and day after is active', () {
    final onHorizon = sampleSubscription(
      nextPaymentDate: DateTime(2026, 12, 18),
      decideByDate: DateTime(2026, 12, 18),
    );
    final afterHorizon = sampleSubscription(
      id: 'after',
      nextPaymentDate: DateTime(2026, 12, 19),
      decideByDate: DateTime(2026, 12, 19),
    );
    expect(
      SubscriptionStatus.resolve(onHorizon, now: now),
      RegistryStatus.upcoming,
    );
    expect(
      SubscriptionStatus.resolve(afterHorizon, now: now),
      RegistryStatus.active,
    );
  });

  test('cancelled plans are excluded from attention', () {
    final plan = sampleSubscription(
      nextPaymentDate: DateTime(2026, 9, 1),
      lifecycle: SubscriptionLifecycle.cancelled,
    );
    expect(SubscriptionStatus.resolve(plan, now: now), RegistryStatus.neutral);
    expect(SubscriptionStatus.needsAttention(plan, now: now), isFalse);
    expect(SubscriptionStatus.attentionCount([plan], now: now), 0);
  });

  test('month and year changes use calendar dates', () {
    final newYear = DateTime(2027, 1, 1);
    final plan = sampleSubscription(
      nextPaymentDate: DateTime(2026, 12, 31),
      decideByDate: DateTime(2026, 12, 31),
    );
    expect(
      SubscriptionStatus.resolve(plan, now: newYear),
      RegistryStatus.expired,
    );
  });
}
