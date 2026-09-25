import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/reminders/data/notification_prompt_store.dart';
import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/domain/reminder_plan.dart';
import 'package:the_registry/features/reminders/reminder_copy.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_repository.dart';
import 'package:the_registry/l10n/app_localizations.dart';

enum ReminderUiStatus {
  none,
  pending,
  scheduled,
  permissionOff,
  past,
  limited,
  cancelled,
  unavailable,
}

Locale resolveReminderLocale(List<Locale>? locales) {
  const supported = ['en', 'fr', 'ar'];
  if (locales != null) {
    for (final candidate in locales) {
      if (supported.contains(candidate.languageCode)) {
        return Locale(candidate.languageCode);
      }
    }
  }
  return const Locale('en');
}

/// Rebuilds the device's pending local reminders from saved records.
///
/// Startup and resume both reconcile, so a force stop (which drops Android
/// alarms) is repaired the next time Registry opens, and a time-zone change
/// is picked up the next time the app runs. Android's boot receiver can
/// restore the last saved alarms without opening the app; this reconcile
/// replaces them with the current local zone.
class ReminderCoordinator extends ChangeNotifier {
  ReminderCoordinator({
    required this.documents,
    required this.subscriptions,
    required this.scheduler,
    required this.clock,
    required this.timeZone,
    NotificationPromptStore? promptStore,
    this.locale = const Locale('en'),
  }) : promptStore = promptStore ?? MemoryNotificationPromptStore();

  final DocumentRepository documents;
  final SubscriptionRepository subscriptions;
  final LocalReminderScheduler scheduler;
  final Clock clock;
  final TimeZoneSource timeZone;
  final NotificationPromptStore promptStore;
  Locale locale;

  ReminderPermission permission = ReminderPermission.unknown;
  ReminderSyncReport report = const ReminderSyncReport.unknown();
  bool ready = false;

  final Map<String, Set<int>> _futureIds = {};
  var _disposed = false;
  var _started = false;
  var _prompted = false;
  Future<void> _chain = Future<void>.value();
  Future<void>? _promptLoaded;
  Future<ReminderPermission>? _promptInFlight;

  /// True after the system dialog has already been shown, including on a
  /// previous launch. Further saves do not raise it again.
  bool get notificationPrompted => _prompted;

  /// After a denial, the way back on is system settings rather than another
  /// permission dialog.
  bool get shouldOpenNotificationSettings =>
      _prompted &&
      _promptInFlight == null &&
      permission == ReminderPermission.denied;

  Future<void> start() {
    _promptLoaded ??= _loadPrompted();
    if (_started) {
      return _promptLoaded!.then((_) => reconcile());
    }
    _started = true;
    documents.addListener(_onDataChanged);
    subscriptions.addListener(_onDataChanged);
    return _promptLoaded!.then((_) => reconcile());
  }

  Future<void> _loadPrompted() async {
    _prompted = await promptStore.wasPrompted();
  }

  /// Shows the system dialog at most once. A save that follows turning a
  /// reminder on shares that request and does not ask again.
  Future<ReminderPermission> requestPermission() async {
    await (_promptLoaded ??= _loadPrompted());
    final inFlight = _promptInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    if (_prompted) {
      return permission;
    }
    _prompted = true;
    final run = _askForPermission();
    _promptInFlight = run;
    try {
      return await run;
    } finally {
      _promptInFlight = null;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<ReminderPermission> _askForPermission() async {
    await promptStore.markPrompted();
    permission = await scheduler.requestPermission();
    if (!_disposed) {
      notifyListeners();
    }
    return permission;
  }

  /// The explicit control for turning notifications on later.
  ///
  /// The first use shows the system dialog. After that dialog has been
  /// denied, this opens system notification settings and does not ask again.
  Future<void> enableNotifications() async {
    await (_promptLoaded ??= _loadPrompted());
    if (shouldOpenNotificationSettings) {
      await scheduler.openNotificationSettings();
      permission = await scheduler.permissionStatus();
      if (!_disposed) {
        notifyListeners();
      }
      await reconcile();
      return;
    }
    await requestPermission();
    await reconcile();
  }

  Future<void> reconcile() {
    final run = _chain.then((_) => _reconcile());
    _chain = run.catchError((Object error, StackTrace stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'registry reminders',
          context: ErrorDescription('reconciling local reminders'),
        ),
      );
    });
    return run;
  }

  ReminderUiStatus statusForDocument(RegistryDocument document) {
    if (document.reminders.isEmpty) {
      return ReminderUiStatus.none;
    }
    return _status(recordKey: _documentKey(document.id), cancelled: false);
  }

  ReminderUiStatus statusForSubscription(RegistrySubscription subscription) {
    if (subscription.reminders.isEmpty) {
      return ReminderUiStatus.none;
    }
    return _status(
      recordKey: _subscriptionKey(subscription.id),
      cancelled: subscription.isCancelled,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    if (_started) {
      documents.removeListener(_onDataChanged);
      subscriptions.removeListener(_onDataChanged);
    }
    super.dispose();
  }

  void _onDataChanged() {
    unawaited(reconcile());
  }

  Future<void> _reconcile() async {
    if (_disposed) {
      return;
    }
    try {
      await scheduler.ensureReady();
      await initializeDateFormatting(locale.toString());
      final location = await timeZone.current();
      tz.setLocalLocation(location);
      final now = clock.now();
      final intents = <ReminderIntent>[
        for (final document in documents.documents)
          ...planDocumentReminders(
            document: document,
            now: now,
            location: location,
          ),
        for (final subscription in subscriptions.subscriptions)
          ...planSubscriptionReminders(
            subscription: subscription,
            now: now,
            location: location,
          ),
      ];
      final capped = capReminders(intents);
      final l10n = lookupAppLocalizations(locale);
      final accepted = [
        for (final intent in capped.accepted) _scheduled(intent, l10n),
      ];
      final nextReport = await scheduler.apply(
        ReminderBatch(accepted: accepted, omitted: capped.omitted),
      );
      if (_disposed) {
        return;
      }
      _futureIds
        ..clear()
        ..addEntries(_futureEntries(intents));
      report = nextReport;
      permission = nextReport.permission;
      ready = true;
      notifyListeners();
    } catch (error, stack) {
      if (_disposed) {
        return;
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'registry reminders',
          context: ErrorDescription('reconciling local reminders'),
        ),
      );
      report = const ReminderSyncReport.unavailable();
      permission = ReminderPermission.unavailable;
      ready = true;
      notifyListeners();
    }
  }

  ScheduledReminder _scheduled(ReminderIntent intent, AppLocalizations l10n) {
    final date = RegistryDateFormatter.dayMonthYear(
      intent.eventDate,
      l10n.localeName,
    );
    return ScheduledReminder(
      id: intent.id,
      payload: intent.payload,
      when: intent.when,
      title: l10n.notificationTitle,
      body: reminderBody(l10n, intent.messageKind, date),
      channelName: l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
      recordId: intent.recordId,
      subject: intent.subject,
      kind: intent.kind,
    );
  }

  ReminderUiStatus _status({
    required String recordKey,
    required bool cancelled,
  }) {
    if (!ready) {
      return ReminderUiStatus.pending;
    }
    if (cancelled) {
      return ReminderUiStatus.cancelled;
    }
    if (!report.schedulingAvailable ||
        permission == ReminderPermission.unavailable) {
      return ReminderUiStatus.unavailable;
    }
    if (permission != ReminderPermission.granted) {
      return ReminderUiStatus.permissionOff;
    }
    final future = _futureIds[recordKey] ?? const <int>{};
    final scheduled = future.intersection(report.scheduledIds);
    if (scheduled.isNotEmpty) {
      return ReminderUiStatus.scheduled;
    }
    if (future.intersection(report.omittedIds).isNotEmpty) {
      return ReminderUiStatus.limited;
    }
    if (future.isNotEmpty) {
      return ReminderUiStatus.unavailable;
    }
    return ReminderUiStatus.past;
  }

  Iterable<MapEntry<String, Set<int>>> _futureEntries(
    List<ReminderIntent> intents,
  ) sync* {
    final grouped = <String, Set<int>>{};
    for (final intent in intents) {
      final key = intent.subject == ReminderSubject.document
          ? _documentKey(intent.recordId)
          : _subscriptionKey(intent.recordId);
      grouped.putIfAbsent(key, () => <int>{}).add(intent.id);
    }
    yield* grouped.entries;
  }

  String _documentKey(String id) => 'document:$id';

  String _subscriptionKey(String id) => 'subscription:$id';
}
