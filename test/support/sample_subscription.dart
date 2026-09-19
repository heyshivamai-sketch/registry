import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

RegistrySubscription sampleSubscription({
  String id = 'sub_1',
  String serviceName = 'City Gym',
  String? planName = 'Standard',
  SubscriptionCategory category = SubscriptionCategory.healthFitness,
  int minorUnits = 3500,
  String currencyCode = 'USD',
  BillingCycle billingCycle = BillingCycle.monthly,
  DateTime? nextPaymentDate,
  DateTime? decideByDate,
  bool includeDecideBy = true,
  bool autoRenew = true,
  SubscriptionLifecycle lifecycle = SubscriptionLifecycle.active,
  DocumentImpact impact = DocumentImpact.medium,
  Set<SubscriptionReminder> reminders = const {
    SubscriptionReminder.sevenDaysBefore,
  },
  String? notes = 'Review before charge',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return RegistrySubscription(
    id: id,
    createdAt: createdAt ?? DateTime(2026, 1, 2),
    updatedAt: updatedAt,
    serviceName: serviceName,
    planName: planName,
    category: category,
    amount: Money(minorUnits: minorUnits, currencyCode: currencyCode),
    billingCycle: billingCycle,
    nextPaymentDate: nextPaymentDate ?? DateTime(2026, 10, 18),
    decideByDate: includeDecideBy
        ? (decideByDate ?? DateTime(2026, 10, 10))
        : null,
    autoRenew: autoRenew,
    lifecycle: lifecycle,
    impact: impact,
    reminders: reminders,
    notes: notes,
  );
}
