import 'package:the_registry/features/reminders/domain/reminder_plan.dart';
import 'package:the_registry/l10n/app_localizations.dart';

/// Lock-screen and shade copy. It names the kind of date, not the record,
/// so a preview cannot reveal a document name, number, or attachment.
String reminderBody(
  AppLocalizations l10n,
  ReminderMessageKind kind,
  String date,
) {
  return switch (kind) {
    ReminderMessageKind.documentActionToday => l10n.reminderDocumentActionToday,
    ReminderMessageKind.documentActionIn7 => l10n.reminderDocumentActionIn7(
      date,
    ),
    ReminderMessageKind.documentActionIn30 => l10n.reminderDocumentActionIn30(
      date,
    ),
    ReminderMessageKind.documentExpiryToday => l10n.reminderDocumentExpiryToday,
    ReminderMessageKind.documentExpiryIn7 => l10n.reminderDocumentExpiryIn7(
      date,
    ),
    ReminderMessageKind.documentExpiryIn30 => l10n.reminderDocumentExpiryIn30(
      date,
    ),
    ReminderMessageKind.subscriptionDecideIn7 =>
      l10n.reminderSubscriptionDecideIn7(date),
    ReminderMessageKind.subscriptionDecideIn1 =>
      l10n.reminderSubscriptionDecideIn1(date),
    ReminderMessageKind.subscriptionPaymentIn7 =>
      l10n.reminderSubscriptionPaymentIn7(date),
    ReminderMessageKind.subscriptionPaymentIn1 =>
      l10n.reminderSubscriptionPaymentIn1(date),
    ReminderMessageKind.subscriptionChargeToday =>
      l10n.reminderSubscriptionChargeToday,
  };
}
