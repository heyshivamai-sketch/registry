import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:the_registry/features/reminders/domain/reminder_plan.dart';

enum ReminderPermission { unknown, granted, denied, unavailable }

class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.payload,
    required this.when,
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
    required this.recordId,
    required this.subject,
    required this.kind,
  });

  final int id;
  final String payload;
  final tz.TZDateTime when;
  final String title;
  final String body;
  final String channelName;
  final String channelDescription;
  final String recordId;
  final ReminderSubject subject;
  final String kind;
}

class ReminderBatch {
  const ReminderBatch({required this.accepted, required this.omitted});

  final List<ScheduledReminder> accepted;
  final List<ReminderIntent> omitted;
}

class ReminderSyncReport {
  const ReminderSyncReport({
    required this.permission,
    required this.schedulingAvailable,
    required this.scheduledIds,
    required this.omittedIds,
    required this.attemptedIds,
  });

  const ReminderSyncReport.unknown()
    : permission = ReminderPermission.unknown,
      schedulingAvailable = false,
      scheduledIds = const {},
      omittedIds = const {},
      attemptedIds = const {};

  const ReminderSyncReport.unavailable()
    : permission = ReminderPermission.unavailable,
      schedulingAvailable = false,
      scheduledIds = const {},
      omittedIds = const {},
      attemptedIds = const {};

  final ReminderPermission permission;
  final bool schedulingAvailable;
  final Set<int> scheduledIds;
  final Set<int> omittedIds;
  final Set<int> attemptedIds;
}

/// Schedules local notifications. Implementations must not send anything
/// off the device.
abstract class LocalReminderScheduler {
  Future<void> ensureReady();

  Future<ReminderPermission> permissionStatus();

  Future<ReminderPermission> requestPermission();

  /// Opens the system screen where notifications can be turned on after a
  /// denial. Does not raise the permission dialog.
  Future<void> openNotificationSettings();

  Future<ReminderSyncReport> apply(ReminderBatch batch);
}

abstract class TimeZoneSource {
  Future<tz.Location> current();
}

class FixedTimeZoneSource implements TimeZoneSource {
  const FixedTimeZoneSource(this.location);

  final tz.Location location;

  @override
  Future<tz.Location> current() async {
    tz_data.initializeTimeZones();
    return location;
  }
}
