import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';

enum BillingCycle { weekly, monthly, quarterly, yearly }

enum SubscriptionLifecycle { active, cancelled }

enum SubscriptionCategory {
  entertainment,
  healthFitness,
  productivity,
  utilities,
  finance,
  education,
  other,
}

enum SubscriptionReminder { sevenDaysBefore, oneDayBefore, onChargeDay }

class RegistrySubscription {
  const RegistrySubscription({
    required this.id,
    required this.createdAt,
    required this.serviceName,
    required this.category,
    required this.amount,
    required this.billingCycle,
    required this.nextPaymentDate,
    required this.autoRenew,
    required this.lifecycle,
    required this.impact,
    this.updatedAt,
    this.planName,
    this.decideByDate,
    this.reminders = const {},
    this.notes,
  });

  static const Object _unset = Object();

  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String serviceName;
  final String? planName;
  final SubscriptionCategory category;
  final Money amount;
  final BillingCycle billingCycle;
  final DateTime nextPaymentDate;
  final DateTime? decideByDate;
  final bool autoRenew;
  final SubscriptionLifecycle lifecycle;
  final DocumentImpact impact;
  final Set<SubscriptionReminder> reminders;
  final String? notes;

  bool get isActive => lifecycle == SubscriptionLifecycle.active;

  bool get isCancelled => lifecycle == SubscriptionLifecycle.cancelled;

  DateTime get displayActionDate => decideByDate ?? nextPaymentDate;

  bool get hasDistinctDecideBy {
    if (decideByDate == null) {
      return false;
    }
    return RegistryDateFormatter.dateOnly(decideByDate!) !=
        RegistryDateFormatter.dateOnly(nextPaymentDate);
  }

  RegistrySubscription copyWith({
    String? id,
    DateTime? createdAt,
    Object? updatedAt = _unset,
    String? serviceName,
    Object? planName = _unset,
    SubscriptionCategory? category,
    Money? amount,
    BillingCycle? billingCycle,
    DateTime? nextPaymentDate,
    Object? decideByDate = _unset,
    bool? autoRenew,
    SubscriptionLifecycle? lifecycle,
    DocumentImpact? impact,
    Set<SubscriptionReminder>? reminders,
    Object? notes = _unset,
  }) {
    return RegistrySubscription(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
      serviceName: serviceName ?? this.serviceName,
      planName: identical(planName, _unset)
          ? this.planName
          : planName as String?,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      decideByDate: identical(decideByDate, _unset)
          ? this.decideByDate
          : decideByDate as DateTime?,
      autoRenew: autoRenew ?? this.autoRenew,
      lifecycle: lifecycle ?? this.lifecycle,
      impact: impact ?? this.impact,
      reminders: reminders ?? this.reminders,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }
}
