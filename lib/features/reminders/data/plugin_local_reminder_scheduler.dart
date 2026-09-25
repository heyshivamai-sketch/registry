import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/domain/reminder_plan.dart';

/// Local notifications through [FlutterLocalNotificationsPlugin].
///
/// Android uses [AndroidScheduleMode.inexactAllowWhileIdle], so delivery can
/// be later than the requested local time and does not need the exact-alarm
/// permission. The plugin's boot receiver restores saved alarms after a
/// normal restart. A force stop clears them until the app opens and
/// reconciles again. iOS keeps the calendar trigger, including its time
/// zone, across restart, up to 64 pending requests.
class PluginLocalReminderScheduler implements LocalReminderScheduler {
  PluginLocalReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  bool _available = false;

  static const _androidIcon = 'ic_notification';

  @override
  Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    _ready = true;
    try {
      tz_data.initializeTimeZones();
      const android = AndroidInitializationSettings(_androidIcon);
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      final initialized = await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
      );
      // Android returns true when the plugin is ready. iOS returns false when
      // init is told not to present the system prompt; the plugin is still
      // ready, and requestPermission() shows that dialog later.
      _available = defaultTargetPlatform == TargetPlatform.iOS
          ? initialized != null
          : initialized != false;
    } catch (error, stack) {
      _available = false;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'registry reminders',
          context: ErrorDescription('initializing local reminders'),
        ),
      );
    }
  }

  @override
  Future<ReminderPermission> permissionStatus() async {
    await ensureReady();
    if (!_available) {
      return ReminderPermission.unavailable;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      return enabled == true
          ? ReminderPermission.granted
          : ReminderPermission.denied;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled == true
          ? ReminderPermission.granted
          : ReminderPermission.denied;
    }
    return ReminderPermission.unavailable;
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    await ensureReady();
    if (!_available) {
      return ReminderPermission.unavailable;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted == true
          ? ReminderPermission.granted
          : ReminderPermission.denied;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
      return granted == true
          ? ReminderPermission.granted
          : ReminderPermission.denied;
    }
    return ReminderPermission.unavailable;
  }

  @override
  Future<void> openNotificationSettings() async {
    await ensureReady();
    if (!_available) {
      return;
    }
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<ReminderSyncReport> apply(ReminderBatch batch) async {
    await ensureReady();
    if (!_available) {
      return const ReminderSyncReport.unavailable();
    }
    final permission = await permissionStatus();
    final omittedIds = batch.omitted.map((item) => item.id).toSet();
    final attemptedIds = batch.accepted.map((item) => item.id).toSet();
    if (permission != ReminderPermission.granted) {
      await _cancelRegistryPending(keep: const {});
      return ReminderSyncReport(
        permission: permission,
        schedulingAvailable: true,
        scheduledIds: const {},
        omittedIds: omittedIds,
        attemptedIds: attemptedIds,
      );
    }

    final acceptedIds = batch.accepted.map((item) => item.id).toSet();
    await _cancelRegistryPending(keep: acceptedIds);
    final scheduled = <int>{};
    for (final reminder in batch.accepted) {
      if (!reminder.when.isAfter(tz.TZDateTime.now(reminder.when.location))) {
        continue;
      }
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: reminder.when,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'registry_reminders',
              reminder.channelName,
              channelDescription: reminder.channelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              // Secure lock screens redact a private notification. The title
              // and body are also neutral, so a preview cannot show a record
              // name, number, or attachment.
              visibility: NotificationVisibility.private,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: false,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: reminder.payload,
        );
        scheduled.add(reminder.id);
      } catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'registry reminders',
            context: ErrorDescription('scheduling a local reminder'),
          ),
        );
      }
    }
    return ReminderSyncReport(
      permission: permission,
      schedulingAvailable: true,
      scheduledIds: scheduled,
      omittedIds: omittedIds,
      attemptedIds: attemptedIds,
    );
  }

  Future<void> _cancelRegistryPending({required Set<int> keep}) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (!isRegistryReminderPayload(request.payload) ||
          keep.contains(request.id)) {
        continue;
      }
      await _plugin.cancel(id: request.id);
    }
  }
}
