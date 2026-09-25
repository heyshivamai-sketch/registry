import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/document_detail_screen.dart';
import 'package:the_registry/features/reminders/data/memory_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/domain/reminder_plan.dart';
import 'package:the_registry/features/reminders/reminder_coordinator.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_document_ocr_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
import 'support/sample_subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting();
  });

  late tz.Location utc;

  setUp(() {
    utc = tz.UTC;
  });

  ReminderCoordinator coordinator({
    required InMemoryDocumentRepository documents,
    required InMemorySubscriptionRepository subscriptions,
    required MemoryReminderScheduler scheduler,
    required Clock clock,
    tz.Location? location,
    Locale locale = const Locale('en'),
  }) {
    return ReminderCoordinator(
      documents: documents,
      subscriptions: subscriptions,
      scheduler: scheduler,
      clock: clock,
      timeZone: FixedTimeZoneSource(location ?? utc),
      locale: locale,
    );
  }

  test('schedules selected document reminders at 9:00 and skips the past', () {
    final future = planDocumentReminders(
      document: sampleDocument(
        reminders: {
          ReminderPreference.onActionDate,
          ReminderPreference.sevenDaysBefore,
          ReminderPreference.thirtyDaysBefore,
        },
      ),
      now: DateTime.utc(2026, 1, 1),
      location: utc,
    );
    expect(future, hasLength(3));
    expect(future.map((item) => item.when.hour), everyElement(9));
    expect(future.map((item) => item.id).toSet(), hasLength(3));

    final sameDayAfterNine = planDocumentReminders(
      document: sampleDocument(
        actionDate: DateTime(2026, 9, 25),
        reminders: {ReminderPreference.onActionDate},
      ),
      now: DateTime.utc(2026, 9, 25, 9),
      location: utc,
    );
    expect(sameDayAfterNine, isEmpty);

    final sameDayBeforeNine = planDocumentReminders(
      document: sampleDocument(
        actionDate: DateTime(2026, 9, 25),
        reminders: {ReminderPreference.onActionDate},
      ),
      now: DateTime.utc(2026, 9, 25, 8),
      location: utc,
    );
    expect(sameDayBeforeNine, hasLength(1));
    expect(sameDayBeforeNine.single.when, tz.TZDateTime.utc(2026, 9, 25, 9));
  });

  test('uses the expiry date when a document has no action date', () {
    final planned = planDocumentReminders(
      document: sampleDocument().copyWith(actionDate: null),
      now: DateTime.utc(2026, 1, 1),
      location: utc,
    );
    expect(planned, hasLength(1));
    expect(planned.single.messageKind, ReminderMessageKind.documentExpiryIn7);
    expect(planned.single.when, tz.TZDateTime.utc(2027, 9, 28, 9));
  });

  test('subscription reminders follow decide-by and the payment date', () {
    final planned = planSubscriptionReminders(
      subscription: sampleSubscription(
        reminders: {
          SubscriptionReminder.sevenDaysBefore,
          SubscriptionReminder.oneDayBefore,
          SubscriptionReminder.onChargeDay,
        },
      ),
      now: DateTime.utc(2026, 9, 1),
      location: utc,
    );
    expect(planned.map((item) => item.when).toList(), [
      tz.TZDateTime.utc(2026, 10, 3, 9),
      tz.TZDateTime.utc(2026, 10, 9, 9),
      tz.TZDateTime.utc(2026, 10, 18, 9),
    ]);
    expect(planned.map((item) => item.messageKind).toList(), [
      ReminderMessageKind.subscriptionDecideIn7,
      ReminderMessageKind.subscriptionDecideIn1,
      ReminderMessageKind.subscriptionChargeToday,
    ]);

    final paymentOnly = planSubscriptionReminders(
      subscription: sampleSubscription(
        includeDecideBy: false,
        reminders: {
          SubscriptionReminder.sevenDaysBefore,
          SubscriptionReminder.onChargeDay,
        },
      ),
      now: DateTime.utc(2026, 9, 1),
      location: utc,
    );
    expect(paymentOnly.map((item) => item.messageKind).toList(), [
      ReminderMessageKind.subscriptionPaymentIn7,
      ReminderMessageKind.subscriptionChargeToday,
    ]);
    expect(paymentOnly.first.when, tz.TZDateTime.utc(2026, 10, 11, 9));
  });

  test('daylight saving changes the offset of the same local hour', () {
    final newYork = tz.getLocation('America/New_York');
    final summer = planDocumentReminders(
      document: sampleDocument(
        actionDate: DateTime(2026, 7, 15),
        reminders: {ReminderPreference.onActionDate},
      ),
      now: DateTime.utc(2026, 1, 1),
      location: newYork,
    ).single;
    final winter = planDocumentReminders(
      document: sampleDocument(
        actionDate: DateTime(2026, 12, 15),
        reminders: {ReminderPreference.onActionDate},
      ),
      now: DateTime.utc(2026, 1, 1),
      location: newYork,
    ).single;

    expect(summer.when.hour, 9);
    expect(winter.when.hour, 9);
    expect(summer.when.timeZoneOffset, const Duration(hours: -4));
    expect(winter.when.timeZoneOffset, const Duration(hours: -5));
    expect(summer.when.toUtc(), DateTime.utc(2026, 7, 15, 13));
    expect(winter.when.toUtc(), DateTime.utc(2026, 12, 15, 14));
  });

  test('ids stay stable and a second schedule does not duplicate', () async {
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    final scheduler = MemoryReminderScheduler();
    final reminders = coordinator(
      documents: documents,
      subscriptions: subscriptions,
      scheduler: scheduler,
      clock: FixedClock(DateTime.utc(2026, 9, 1)),
    );
    final document = sampleDocument(
      reminders: {ReminderPreference.onActionDate},
    );
    await documents.save(document);
    await reminders.start();

    final first = scheduler.pending.values.single;
    await reminders.reconcile();
    expect(scheduler.pending, hasLength(1));
    expect(scheduler.pending.values.single.id, first.id);
    expect(scheduler.applyCount, greaterThan(1));

    final moved = document.copyWith(actionDate: DateTime(2027, 12, 1));
    await documents.update(moved);
    await reminders.reconcile();
    expect(scheduler.pending, hasLength(1));
    expect(scheduler.pending.values.single.id, first.id);
    expect(
      scheduler.pending.values.single.when,
      tz.TZDateTime.utc(2027, 12, 1, 9),
    );
    reminders.dispose();
  });

  test('deletion, cancellation and reactivation update the same ids', () async {
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    final scheduler = MemoryReminderScheduler();
    final reminders = coordinator(
      documents: documents,
      subscriptions: subscriptions,
      scheduler: scheduler,
      clock: FixedClock(DateTime.utc(2026, 9, 1)),
    );
    final subscription = sampleSubscription(
      reminders: {SubscriptionReminder.onChargeDay},
    );
    await subscriptions.save(subscription);
    await documents.save(
      sampleDocument(reminders: {ReminderPreference.onActionDate}),
    );
    await reminders.start();
    expect(scheduler.pending, hasLength(2));

    await subscriptions.update(
      subscription.copyWith(lifecycle: SubscriptionLifecycle.cancelled),
    );
    await reminders.reconcile();
    expect(scheduler.pending.values.map((item) => item.subject), [
      ReminderSubject.document,
    ]);
    expect(
      reminders.statusForSubscription(
        subscription.copyWith(lifecycle: SubscriptionLifecycle.cancelled),
      ),
      ReminderUiStatus.cancelled,
    );

    await subscriptions.update(
      subscription.copyWith(lifecycle: SubscriptionLifecycle.active),
    );
    await reminders.reconcile();
    expect(scheduler.pending, hasLength(2));

    await documents.delete('doc_1');
    await reminders.reconcile();
    expect(scheduler.pending.values.map((item) => item.subject), [
      ReminderSubject.subscription,
    ]);
    reminders.dispose();
  });

  test('restart restores a cleared schedule without duplicating it', () async {
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    final scheduler = MemoryReminderScheduler();
    final clock = FixedClock(DateTime.utc(2026, 9, 1));
    final first = coordinator(
      documents: documents,
      subscriptions: subscriptions,
      scheduler: scheduler,
      clock: clock,
    );
    await documents.save(
      sampleDocument(reminders: {ReminderPreference.sevenDaysBefore}),
    );
    await first.start();
    final id = scheduler.pending.values.single.id;
    first.dispose();

    scheduler.clearPending();
    final restarted = coordinator(
      documents: documents,
      subscriptions: subscriptions,
      scheduler: scheduler,
      clock: clock,
    );
    await restarted.start();
    expect(scheduler.pending, hasLength(1));
    expect(scheduler.pending.values.single.id, id);
    await restarted.reconcile();
    expect(scheduler.pending, hasLength(1));
    restarted.dispose();
  });

  test('a time zone change replaces the pending instant', () async {
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    final scheduler = MemoryReminderScheduler();
    final zone = _MutableZone(tz.getLocation('America/New_York'));
    final reminders = ReminderCoordinator(
      documents: documents,
      subscriptions: subscriptions,
      scheduler: scheduler,
      clock: FixedClock(DateTime.utc(2026, 1, 1)),
      timeZone: zone,
    );
    await documents.save(
      sampleDocument(
        actionDate: DateTime(2026, 7, 15),
        reminders: {ReminderPreference.onActionDate},
      ),
    );
    await reminders.start();
    final id = scheduler.pending.values.single.id;
    expect(
      scheduler.pending.values.single.when.timeZoneOffset,
      const Duration(hours: -4),
    );

    zone.location = tz.getLocation('Europe/Paris');
    await reminders.reconcile();
    expect(scheduler.pending, hasLength(1));
    expect(scheduler.pending.values.single.id, id);
    expect(
      scheduler.pending.values.single.when.timeZoneOffset,
      const Duration(hours: 2),
    );
    reminders.dispose();
  });

  test('permission denial keeps the record and schedules nothing', () async {
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    final scheduler = MemoryReminderScheduler(
      permission: ReminderPermission.denied,
    );
    final reminders = coordinator(
      documents: documents,
      subscriptions: subscriptions,
      scheduler: scheduler,
      clock: FixedClock(DateTime.utc(2026, 9, 1)),
    );
    final document = sampleDocument(
      reminders: {ReminderPreference.onActionDate},
    );
    await documents.save(document);
    await reminders.start();

    expect(documents.documents, hasLength(1));
    expect(scheduler.pending, isEmpty);
    expect(
      reminders.statusForDocument(document),
      ReminderUiStatus.permissionOff,
    );
    expect(scheduler.permissionRequestCount, 0);
    final requested = await reminders.requestPermission();
    expect(requested, ReminderPermission.denied);
    expect(scheduler.permissionRequestCount, 1);
    final again = await reminders.requestPermission();
    expect(again, ReminderPermission.denied);
    expect(scheduler.permissionRequestCount, 1);
    expect(reminders.shouldOpenNotificationSettings, isTrue);
    await reminders.enableNotifications();
    expect(scheduler.settingsOpenCount, 1);
    expect(scheduler.permissionRequestCount, 1);
    expect(documents.documents, hasLength(1));
    expect(scheduler.pending, isEmpty);
    reminders.dispose();
  });

  test('only the soonest 64 reminders are scheduled', () async {
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    final scheduler = MemoryReminderScheduler();
    final reminders = coordinator(
      documents: documents,
      subscriptions: subscriptions,
      scheduler: scheduler,
      clock: FixedClock(DateTime.utc(2026, 1, 1)),
    );
    for (var index = 0; index < maxPendingLocalReminders + 1; index++) {
      await documents.save(
        sampleDocument(
          id: 'doc_$index',
          actionDate: DateTime(2026, 6, 1).add(Duration(days: index)),
          reminders: {ReminderPreference.onActionDate},
        ),
      );
    }
    await reminders.start();
    expect(scheduler.pending, hasLength(maxPendingLocalReminders));
    expect(
      reminders.statusForDocument(documents.findById('doc_0')!),
      ReminderUiStatus.scheduled,
    );
    expect(
      reminders.statusForDocument(
        documents.findById('doc_$maxPendingLocalReminders')!,
      ),
      ReminderUiStatus.limited,
    );
    reminders.dispose();
  });

  test('notification copy is localized and Arabic stays Arabic', () async {
    final english = lookupAppLocalizations(const Locale('en'));
    final french = lookupAppLocalizations(const Locale('fr'));
    final arabic = lookupAppLocalizations(const Locale('ar'));
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await documents.save(
      sampleDocument().copyWith(
        actionDate: null,
        reminders: {ReminderPreference.onActionDate},
      ),
    );

    Future<String> body(Locale locale) async {
      final scheduler = MemoryReminderScheduler();
      final reminders = coordinator(
        documents: documents,
        subscriptions: subscriptions,
        scheduler: scheduler,
        clock: FixedClock(DateTime.utc(2026, 1, 1)),
        locale: locale,
      );
      await reminders.start();
      final text = scheduler.pending.values.single.body;
      reminders.dispose();
      return text;
    }

    final englishScheduler = MemoryReminderScheduler();
    final englishReminders = coordinator(
      documents: documents,
      subscriptions: subscriptions,
      scheduler: englishScheduler,
      clock: FixedClock(DateTime.utc(2026, 1, 1)),
    );
    await englishReminders.start();
    final scheduled = englishScheduler.pending.values.single;
    expect(scheduled.title, english.notificationTitle);
    expect(scheduled.body, english.reminderDocumentExpiryToday);
    expect(scheduled.title, isNot(contains('Family passport')));
    expect(scheduled.body, isNot(contains('Family passport')));
    expect(scheduled.body, isNot(contains('AB12345678')));
    expect(scheduled.body, isNot(contains('Amira')));
    expect(scheduled.body, isNot(contains('Keep a copy')));
    expect(scheduled.title, isNot(contains('AB12345678')));
    englishReminders.dispose();

    expect(await body(const Locale('fr')), french.reminderDocumentExpiryToday);
    final arabicBody = await body(const Locale('ar'));
    expect(arabicBody, arabic.reminderDocumentExpiryToday);
    expect(arabicBody, isNot(contains('Family passport')));
    expect(arabicBody, isNot(contains('Today is')));
    expect(RegExp(r'[\u0600-\u06FF]').hasMatch(arabicBody), isTrue);
  });

  testWidgets('denied permission still saves and does not claim a schedule', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final scheduler = MemoryReminderScheduler(
      permission: ReminderPermission.denied,
    );
    final dates = FakeDatePickerService();
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        documentRepository: documents,
        imagePickerService: FakeImagePickerService(),
        datePickerService: dates,
        documentOcrService: FakeDocumentOcrService(),
        reminderScheduler: scheduler,
        clock: FixedClock(DateTime.utc(2026, 9, 1)),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Probe passport',
    );
    await tester.tap(find.byKey(const ValueKey<String>('field-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('category-passport')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    dates.results['expiry'] = DateTime(2027, 10, 5);
    await tester.tap(find.byKey(const ValueKey<String>('date-expiry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('impact-high')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('impact-high')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('reminder-action')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('reminder-action')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('reminder-permission-note')),
      findsWidgets,
    );
    expect(find.textContaining('You can still save'), findsWidgets);
    expect(find.text('Notification settings'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
    await tester.pumpAndSettle();

    expect(documents.documents, hasLength(1));
    expect(documents.documents.single.reminders, {
      ReminderPreference.onActionDate,
    });
    expect(scheduler.pending, isEmpty);
    expect(scheduler.permissionRequestCount, 1);

    await tester.tap(
      find.byKey(const ValueKey<String>('featured-document-pass')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.textContaining('no reminder is scheduled'), findsOneWidget);
    expect(find.textContaining('A local reminder is scheduled'), findsNothing);
  });

  testWidgets('Arabic reminder status keeps right-to-left layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    await documents.save(
      sampleDocument(reminders: {ReminderPreference.onActionDate}),
    );
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        documentRepository: documents,
        locale: const Locale('ar'),
        clock: FixedClock(DateTime.utc(2026, 9, 1)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('featured-document-pass')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(DocumentDetailScreen))),
      TextDirection.rtl,
    );
    expect(find.textContaining('تمت جدولة تذكير محلي'), findsOneWidget);
    expect(find.textContaining('A local reminder is scheduled'), findsNothing);
  });
}

class _MutableZone implements TimeZoneSource {
  _MutableZone(this.location);

  tz.Location location;

  @override
  Future<tz.Location> current() async => location;
}
