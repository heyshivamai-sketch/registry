import 'package:timezone/timezone.dart' as tz;
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

/// Requested local wall-clock time. Android may deliver later than this.
const int reminderLocalHour = 9;

/// iOS keeps at most 64 pending local notifications. Some Android devices
/// also cap alarms (Samsung has reported 500). Scheduling the soonest 64
/// stays inside both limits.
const int maxPendingLocalReminders = 64;

enum ReminderSubject { document, subscription }

enum ReminderMessageKind {
  documentActionToday,
  documentActionIn7,
  documentActionIn30,
  documentExpiryToday,
  documentExpiryIn7,
  documentExpiryIn30,
  subscriptionDecideIn7,
  subscriptionDecideIn1,
  subscriptionPaymentIn7,
  subscriptionPaymentIn1,
  subscriptionChargeToday,
}

class ReminderIntent {
  const ReminderIntent({
    required this.id,
    required this.payload,
    required this.when,
    required this.recordId,
    required this.subject,
    required this.kind,
    required this.recordName,
    required this.eventDate,
    required this.messageKind,
  });

  final int id;
  final String payload;
  final tz.TZDateTime when;
  final String recordId;
  final ReminderSubject subject;
  final String kind;
  final String recordName;
  final DateTime eventDate;
  final ReminderMessageKind messageKind;
}

class CappedReminders {
  const CappedReminders({required this.accepted, required this.omitted});

  final List<ReminderIntent> accepted;
  final List<ReminderIntent> omitted;
}

/// Future reminders only. A time that is not after [now] is left out.
List<ReminderIntent> planDocumentReminders({
  required RegistryDocument document,
  required DateTime now,
  required tz.Location location,
}) {
  final usesExpiry = document.actionDate == null;
  final anchor = document.displayActionDate;
  final intents = <ReminderIntent>[];
  for (final preference in ReminderPreference.values) {
    if (!document.reminders.contains(preference)) {
      continue;
    }
    final daysBefore = switch (preference) {
      ReminderPreference.onActionDate => 0,
      ReminderPreference.sevenDaysBefore => 7,
      ReminderPreference.thirtyDaysBefore => 30,
    };
    final messageKind = switch ((usesExpiry, preference)) {
      (true, ReminderPreference.onActionDate) =>
        ReminderMessageKind.documentExpiryToday,
      (true, ReminderPreference.sevenDaysBefore) =>
        ReminderMessageKind.documentExpiryIn7,
      (true, ReminderPreference.thirtyDaysBefore) =>
        ReminderMessageKind.documentExpiryIn30,
      (false, ReminderPreference.onActionDate) =>
        ReminderMessageKind.documentActionToday,
      (false, ReminderPreference.sevenDaysBefore) =>
        ReminderMessageKind.documentActionIn7,
      (false, ReminderPreference.thirtyDaysBefore) =>
        ReminderMessageKind.documentActionIn30,
    };
    final intent = _intent(
      subject: ReminderSubject.document,
      recordId: document.id,
      kind: preference.name,
      recordName: document.name,
      anchor: anchor,
      daysBefore: daysBefore,
      now: now,
      location: location,
      messageKind: messageKind,
    );
    if (intent != null) {
      intents.add(intent);
    }
  }
  return intents;
}

/// Active plans only. Day-before reminders follow the decide-by date when
/// one is saved, and the payment date otherwise. Charge day follows the
/// payment date.
List<ReminderIntent> planSubscriptionReminders({
  required RegistrySubscription subscription,
  required DateTime now,
  required tz.Location location,
}) {
  if (!subscription.isActive) {
    return const [];
  }
  final payment = RegistryDateFormatter.dateOnly(subscription.nextPaymentDate);
  final decideBy = subscription.decideByDate == null
      ? payment
      : RegistryDateFormatter.dateOnly(subscription.decideByDate!);
  final beforePayment = subscription.decideByDate == null;
  final intents = <ReminderIntent>[];
  for (final reminder in SubscriptionReminder.values) {
    if (!subscription.reminders.contains(reminder)) {
      continue;
    }
    final (anchor, daysBefore, messageKind) = switch (reminder) {
      SubscriptionReminder.sevenDaysBefore => (
        decideBy,
        7,
        beforePayment
            ? ReminderMessageKind.subscriptionPaymentIn7
            : ReminderMessageKind.subscriptionDecideIn7,
      ),
      SubscriptionReminder.oneDayBefore => (
        decideBy,
        1,
        beforePayment
            ? ReminderMessageKind.subscriptionPaymentIn1
            : ReminderMessageKind.subscriptionDecideIn1,
      ),
      SubscriptionReminder.onChargeDay => (
        payment,
        0,
        ReminderMessageKind.subscriptionChargeToday,
      ),
    };
    final intent = _intent(
      subject: ReminderSubject.subscription,
      recordId: subscription.id,
      kind: reminder.name,
      recordName: subscription.serviceName,
      anchor: anchor,
      daysBefore: daysBefore,
      now: now,
      location: location,
      messageKind: messageKind,
    );
    if (intent != null) {
      intents.add(intent);
    }
  }
  return intents;
}

CappedReminders capReminders(List<ReminderIntent> intents) {
  final sorted = [...intents]
    ..sort((a, b) {
      final byTime = a.when.compareTo(b.when);
      if (byTime != 0) {
        return byTime;
      }
      return a.id.compareTo(b.id);
    });
  if (sorted.length <= maxPendingLocalReminders) {
    return CappedReminders(accepted: sorted, omitted: const []);
  }
  return CappedReminders(
    accepted: sorted.sublist(0, maxPendingLocalReminders),
    omitted: sorted.sublist(maxPendingLocalReminders),
  );
}

ReminderIntent? _intent({
  required ReminderSubject subject,
  required String recordId,
  required String kind,
  required String recordName,
  required DateTime anchor,
  required int daysBefore,
  required DateTime now,
  required tz.Location location,
  required ReminderMessageKind messageKind,
}) {
  final day = RegistryDateFormatter.dateOnly(anchor);
  final event = DateTime(day.year, day.month, day.day - daysBefore);
  final when = tz.TZDateTime(
    location,
    event.year,
    event.month,
    event.day,
    reminderLocalHour,
  );
  if (!when.isAfter(now)) {
    return null;
  }
  return ReminderIntent(
    id: reminderNotificationId(
      subject: subject,
      recordId: recordId,
      kind: kind,
    ),
    payload: reminderPayload(subject: subject, recordId: recordId, kind: kind),
    when: when,
    recordId: recordId,
    subject: subject,
    kind: kind,
    recordName: recordName,
    eventDate: event,
    messageKind: messageKind,
  );
}

/// Stable notification id for one saved reminder choice.
///
/// The same record and reminder kind always map to the same id, so a later
/// schedule replaces the previous one. Dart's [String.hashCode] is not stable
/// across runs, so this uses FNV-1a.
int reminderNotificationId({
  required ReminderSubject subject,
  required String recordId,
  required String kind,
}) {
  final hash = _fnv1a32('registry|${subject.name}|$recordId|$kind');
  final id = hash & 0x7fffffff;
  return id == 0 ? 1 : id;
}

String reminderPayload({
  required ReminderSubject subject,
  required String recordId,
  required String kind,
}) {
  return 'registry:${subject.name}:$recordId:$kind';
}

bool isRegistryReminderPayload(String? payload) {
  return payload != null && payload.startsWith('registry:');
}

int _fnv1a32(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}
