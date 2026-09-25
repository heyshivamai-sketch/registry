import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/domain/reminder_plan.dart';

/// In-memory scheduler used by tests and by app previews that have no
/// platform notification plugin.
class MemoryReminderScheduler implements LocalReminderScheduler {
  MemoryReminderScheduler({
    this.permission = ReminderPermission.granted,
    this.available = true,
  });

  ReminderPermission permission;
  bool available;
  final Map<int, ScheduledReminder> pending = {};
  int applyCount = 0;
  int permissionRequestCount = 0;
  int settingsOpenCount = 0;

  void clearPending() {
    pending.clear();
  }

  @override
  Future<void> ensureReady() async {}

  @override
  Future<ReminderPermission> permissionStatus() async {
    if (!available) {
      return ReminderPermission.unavailable;
    }
    return permission;
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    permissionRequestCount += 1;
    return permissionStatus();
  }

  @override
  Future<void> openNotificationSettings() async {
    settingsOpenCount += 1;
  }

  @override
  Future<ReminderSyncReport> apply(ReminderBatch batch) async {
    applyCount += 1;
    if (!available) {
      return const ReminderSyncReport.unavailable();
    }
    final omittedIds = batch.omitted.map((item) => item.id).toSet();
    final attemptedIds = batch.accepted.map((item) => item.id).toSet();
    if (permission != ReminderPermission.granted) {
      pending.removeWhere((_, item) => isRegistryReminderPayload(item.payload));
      return ReminderSyncReport(
        permission: permission,
        schedulingAvailable: true,
        scheduledIds: const {},
        omittedIds: omittedIds,
        attemptedIds: attemptedIds,
      );
    }
    final acceptedIds = attemptedIds;
    pending.removeWhere(
      (id, item) =>
          isRegistryReminderPayload(item.payload) && !acceptedIds.contains(id),
    );
    for (final reminder in batch.accepted) {
      pending[reminder.id] = reminder;
    }
    return ReminderSyncReport(
      permission: permission,
      schedulingAvailable: true,
      scheduledIds: acceptedIds,
      omittedIds: omittedIds,
      attemptedIds: attemptedIds,
    );
  }
}
