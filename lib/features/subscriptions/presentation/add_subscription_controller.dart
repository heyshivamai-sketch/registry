import 'package:flutter/foundation.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/l10n/app_localizations.dart';

enum SubscriptionFormMode { create, edit }

enum AddSubscriptionStep { service, billing, preferences, review }

class AddSubscriptionController extends ChangeNotifier {
  AddSubscriptionController({this._clock = const Clock()});

  final Clock _clock;

  static int _idSeq = 0;

  SubscriptionFormMode mode = SubscriptionFormMode.create;
  String? existingId;
  DateTime? createdAt;
  DateTime? updatedAt;
  SubscriptionLifecycle lifecycle = SubscriptionLifecycle.active;

  AddSubscriptionStep step = AddSubscriptionStep.service;
  String serviceName = '';
  String planName = '';
  SubscriptionCategory? category;
  String amountText = '';
  String? currencyCode;
  BillingCycle? billingCycle;
  DateTime? nextPaymentDate;
  DateTime? decideByDate;
  bool autoRenew = true;
  DocumentImpact? impact;
  Set<SubscriptionReminder> reminders = {};
  String notes = '';

  String? serviceNameError;
  String? categoryError;
  String? amountError;
  String? currencyError;
  String? cycleError;
  String? nextPaymentError;
  String? decideByError;
  String? impactError;
  String? saveError;

  bool saving = false;
  _SubscriptionSnapshot? _baseline;

  bool get isEditing => mode == SubscriptionFormMode.edit;

  int get stepIndex => AddSubscriptionStep.values.indexOf(step);

  int get stepCount => AddSubscriptionStep.values.length;

  bool get canGoBack => step != AddSubscriptionStep.service;

  bool get isDirty {
    final current = _snapshot();
    if (_baseline != null) {
      return current != _baseline;
    }
    return current != const _SubscriptionSnapshot();
  }

  void loadSubscription(RegistrySubscription subscription) {
    mode = SubscriptionFormMode.edit;
    existingId = subscription.id;
    createdAt = subscription.createdAt;
    updatedAt = subscription.updatedAt;
    lifecycle = subscription.lifecycle;
    serviceName = subscription.serviceName;
    planName = subscription.planName ?? '';
    category = subscription.category;
    amountText = _amountInput(subscription.amount);
    currencyCode = subscription.amount.code;
    billingCycle = subscription.billingCycle;
    nextPaymentDate = subscription.nextPaymentDate;
    decideByDate = subscription.decideByDate;
    autoRenew = subscription.autoRenew;
    impact = subscription.impact;
    reminders = Set<SubscriptionReminder>.from(subscription.reminders);
    notes = subscription.notes ?? '';
    step = AddSubscriptionStep.service;
    saveError = null;
    _baseline = _snapshot();
    notifyListeners();
  }

  void goToStep(AddSubscriptionStep value) {
    step = value;
    notifyListeners();
  }

  void setServiceName(String value) {
    serviceName = value;
    notifyListeners();
  }

  void setPlanName(String value) {
    planName = value;
    notifyListeners();
  }

  void setCategory(SubscriptionCategory value) {
    category = value;
    categoryError = null;
    notifyListeners();
  }

  void setAmountText(String value) {
    amountText = value;
    notifyListeners();
  }

  void setCurrencyCode(String value) {
    currencyCode = value;
    currencyError = null;
    notifyListeners();
  }

  void setBillingCycle(BillingCycle value) {
    billingCycle = value;
    cycleError = null;
    notifyListeners();
  }

  void setNextPaymentDate(DateTime value) {
    nextPaymentDate = RegistryDateFormatter.dateOnly(value);
    nextPaymentError = null;
    notifyListeners();
  }

  void setDecideByDate(DateTime? value) {
    decideByDate = value == null ? null : RegistryDateFormatter.dateOnly(value);
    decideByError = null;
    notifyListeners();
  }

  void setAutoRenew(bool value) {
    autoRenew = value;
    notifyListeners();
  }

  void setImpact(DocumentImpact value) {
    impact = value;
    impactError = null;
    notifyListeners();
  }

  void toggleReminder(SubscriptionReminder reminder) {
    reminders = Set<SubscriptionReminder>.from(reminders);
    if (!reminders.add(reminder)) {
      reminders.remove(reminder);
    }
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value;
    notifyListeners();
  }

  bool continueStep(AppLocalizations l10n) {
    final valid = switch (step) {
      AddSubscriptionStep.service => _validateService(l10n),
      AddSubscriptionStep.billing => _validateBilling(l10n),
      AddSubscriptionStep.preferences => _validatePreferences(l10n),
      AddSubscriptionStep.review => validate(l10n),
    };
    if (!valid) {
      return false;
    }
    if (step != AddSubscriptionStep.review) {
      step = AddSubscriptionStep.values[stepIndex + 1];
      notifyListeners();
    }
    return true;
  }

  void backStep() {
    if (!canGoBack) {
      return;
    }
    step = AddSubscriptionStep.values[stepIndex - 1];
    notifyListeners();
  }

  bool _validateService(AppLocalizations l10n) {
    serviceNameError = serviceName.trim().isEmpty ? l10n.errorRequired : null;
    categoryError = category == null ? l10n.errorRequired : null;
    notifyListeners();
    return serviceNameError == null && categoryError == null;
  }

  bool _validateBilling(AppLocalizations l10n) {
    currencyError = currencyCode == null || currencyCode!.trim().isEmpty
        ? l10n.errorRequired
        : null;
    cycleError = billingCycle == null ? l10n.errorRequired : null;
    nextPaymentError = nextPaymentDate == null ? l10n.errorRequired : null;
    amountError = null;
    decideByError = null;
    if (currencyError == null) {
      try {
        MoneyParser.parse(amountText, currencyCode!);
      } on MoneyParseException catch (error) {
        amountError = _amountMessage(l10n, error.message);
      }
    } else if (amountText.trim().isEmpty) {
      amountError = l10n.errorRequired;
    }
    if (decideByDate != null &&
        nextPaymentDate != null &&
        RegistryDateFormatter.dateOnly(
          decideByDate!,
        ).isAfter(RegistryDateFormatter.dateOnly(nextPaymentDate!))) {
      decideByError = l10n.errorDecideByAfterPayment;
    }
    notifyListeners();
    return amountError == null &&
        currencyError == null &&
        cycleError == null &&
        nextPaymentError == null &&
        decideByError == null;
  }

  bool _validatePreferences(AppLocalizations l10n) {
    impactError = impact == null ? l10n.errorRequired : null;
    if (decideByDate != null &&
        nextPaymentDate != null &&
        RegistryDateFormatter.dateOnly(
          decideByDate!,
        ).isAfter(RegistryDateFormatter.dateOnly(nextPaymentDate!))) {
      decideByError = l10n.errorDecideByAfterPayment;
    }
    notifyListeners();
    return impactError == null && decideByError == null;
  }

  bool validate(AppLocalizations l10n) {
    _validateService(l10n);
    _validateBilling(l10n);
    _validatePreferences(l10n);
    return serviceNameError == null &&
        categoryError == null &&
        amountError == null &&
        currencyError == null &&
        cycleError == null &&
        nextPaymentError == null &&
        decideByError == null &&
        impactError == null;
  }

  RegistrySubscription toSubscription() {
    final now = _clock.now();
    final amount = MoneyParser.parse(amountText, currencyCode!);
    if (isEditing) {
      return RegistrySubscription(
        id: existingId!,
        createdAt: createdAt ?? now,
        updatedAt: now,
        serviceName: serviceName.trim(),
        planName: _optional(planName),
        category: category!,
        amount: amount,
        billingCycle: billingCycle!,
        nextPaymentDate: RegistryDateFormatter.dateOnly(nextPaymentDate!),
        decideByDate: decideByDate,
        autoRenew: autoRenew,
        lifecycle: lifecycle,
        impact: impact!,
        reminders: Set<SubscriptionReminder>.from(reminders),
        notes: _optional(notes),
      );
    }
    return RegistrySubscription(
      id: 'sub_${now.microsecondsSinceEpoch}_${_idSeq++}',
      createdAt: now,
      serviceName: serviceName.trim(),
      planName: _optional(planName),
      category: category!,
      amount: amount,
      billingCycle: billingCycle!,
      nextPaymentDate: RegistryDateFormatter.dateOnly(nextPaymentDate!),
      decideByDate: decideByDate,
      autoRenew: autoRenew,
      lifecycle: SubscriptionLifecycle.active,
      impact: impact!,
      reminders: Set<SubscriptionReminder>.from(reminders),
      notes: _optional(notes),
    );
  }

  Future<bool> submit({
    required AppLocalizations l10n,
    required Future<void> Function(RegistrySubscription subscription) save,
    Future<bool> Function(RegistrySubscription subscription)? update,
  }) async {
    if (saving) {
      return false;
    }
    saveError = null;
    if (!validate(l10n)) {
      if (serviceNameError != null || categoryError != null) {
        step = AddSubscriptionStep.service;
      } else if (amountError != null ||
          currencyError != null ||
          cycleError != null ||
          nextPaymentError != null) {
        step = AddSubscriptionStep.billing;
      } else if (impactError != null || decideByError != null) {
        step = AddSubscriptionStep.preferences;
      }
      notifyListeners();
      return false;
    }
    saving = true;
    notifyListeners();
    try {
      final subscription = toSubscription();
      if (isEditing) {
        final updated = await (update ?? _unsupportedUpdate)(subscription);
        if (!updated) {
          saveError = l10n.subscriptionSaveFailed;
          return false;
        }
        return true;
      }
      await save(subscription);
      return true;
    } catch (_) {
      saveError = l10n.subscriptionSaveFailed;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> _unsupportedUpdate(RegistrySubscription subscription) async {
    return false;
  }

  String _amountInput(Money money) {
    final digits = CurrencyInfo.fractionDigits(money.code);
    if (digits == 0) {
      return '${money.minorUnits}';
    }
    final divisor = CurrencyInfo.pow10(digits);
    final whole = money.minorUnits ~/ divisor;
    final fraction = (money.minorUnits % divisor).toString().padLeft(
      digits,
      '0',
    );
    return '$whole.$fraction';
  }

  String _amountMessage(AppLocalizations l10n, String code) {
    return switch (code) {
      'Amount is required.' => l10n.errorRequired,
      'Amount cannot be negative.' => l10n.errorAmountNegative,
      'Amount has too many decimal places.' => l10n.errorAmountPrecision,
      'Invalid currency.' => l10n.errorRequired,
      _ => l10n.errorAmountInvalid,
    };
  }

  _SubscriptionSnapshot _snapshot() {
    return _SubscriptionSnapshot(
      serviceName: serviceName,
      planName: planName,
      category: category,
      amountText: amountText,
      currencyCode: currencyCode,
      billingCycle: billingCycle,
      nextPaymentDate: nextPaymentDate,
      decideByDate: decideByDate,
      autoRenew: autoRenew,
      impact: impact,
      reminders: reminders,
      notes: notes,
    );
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SubscriptionSnapshot {
  const _SubscriptionSnapshot({
    this.serviceName = '',
    this.planName = '',
    this.category,
    this.amountText = '',
    this.currencyCode,
    this.billingCycle,
    this.nextPaymentDate,
    this.decideByDate,
    this.autoRenew = true,
    this.impact,
    this.reminders = const {},
    this.notes = '',
  });

  final String serviceName;
  final String planName;
  final SubscriptionCategory? category;
  final String amountText;
  final String? currencyCode;
  final BillingCycle? billingCycle;
  final DateTime? nextPaymentDate;
  final DateTime? decideByDate;
  final bool autoRenew;
  final DocumentImpact? impact;
  final Set<SubscriptionReminder> reminders;
  final String notes;

  @override
  bool operator ==(Object other) {
    return other is _SubscriptionSnapshot &&
        other.serviceName.trim() == serviceName.trim() &&
        other.planName.trim() == planName.trim() &&
        other.category == category &&
        other.amountText.trim() == amountText.trim() &&
        other.currencyCode == currencyCode &&
        other.billingCycle == billingCycle &&
        other.nextPaymentDate == nextPaymentDate &&
        other.decideByDate == decideByDate &&
        other.autoRenew == autoRenew &&
        other.impact == impact &&
        setEquals(other.reminders, reminders) &&
        other.notes.trim() == notes.trim();
  }

  @override
  int get hashCode => Object.hash(
    serviceName,
    planName,
    category,
    amountText,
    currencyCode,
    billingCycle,
    nextPaymentDate,
    decideByDate,
    autoRenew,
    impact,
    Object.hashAll(reminders),
    notes,
  );
}
