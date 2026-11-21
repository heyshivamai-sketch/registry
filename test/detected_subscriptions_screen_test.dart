import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/ads/ads_config.dart';
import 'package:the_registry/features/ads/ads_controller.dart';
import 'package:the_registry/features/app_lock/app_lock_controller.dart';
import 'package:the_registry/features/app_lock/app_lock_store.dart';
import 'package:the_registry/features/backup/backup_service.dart';
import 'package:the_registry/features/backup/platform_backup_file_gateway.dart';
import 'package:the_registry/features/backup/registry_archive.dart';
import 'package:the_registry/features/csv_import/csv_file_gateway.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/entitlements/entitlement_service.dart';
import 'package:the_registry/features/entitlements/local_pro_entitlement.dart';
import 'package:the_registry/features/reminders/data/memory_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/reminder_coordinator.dart';
import 'package:the_registry/features/subscriptions/data/detected_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/data/gmail_client_gateway.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/detected_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/gmail_subscription_detection_service.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_discovery_service.dart';
import 'package:the_registry/features/subscriptions/presentation/detected_subscriptions_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_date_picker_service.dart';
import 'support/fake_document_ocr_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/phase2_fakes.dart';

class FakeGmailGateway implements GmailClientGateway {
  @override
  Future<String?> getCurrentUserEmail() async => 'user@gmail.com';

  @override
  Future<List<GmailRawMessage>> searchBillingEmails(
      {DateTime? since, int maxResults = 50}) async =>
      const [];

  @override
  Future<String?> signIn() async => 'user@gmail.com';

  @override
  Future<void> signOut() async {}
}

Widget buildTestScreen({
  required InMemorySubscriptionRepository subscriptions,
  required InMemoryDetectedSubscriptionRepository detectedRepo,
  required SubscriptionDiscoveryService discovery,
}) {
  final docs = InMemoryDocumentRepository();
  const clock = Clock();
  final localPro = LocalProEntitlement.disabled();
  final entitlements = EntitlementService(
    documents: docs,
    subscriptions: subscriptions,
    source: localPro,
  );
  final writes = RegistryWrites(
    documents: docs,
    subscriptions: subscriptions,
    entitlements: entitlements,
  );

  return RegistryDependencies(
    documents: docs,
    subscriptions: subscriptions,
    imagePicker: FakeImagePickerService(),
    datePicker: FakeDatePickerService(),
    documentOcr: FakeDocumentOcrService(),
    clock: clock,
    reminders: ReminderCoordinator(
      documents: docs,
      subscriptions: subscriptions,
      scheduler: MemoryReminderScheduler(),
      clock: clock,
      timeZone: FixedTimeZoneSource(tz.UTC),
    ),
    backups: RegistryBackupService(
      archive: MemoryRegistryArchive(
        documentsRepository: docs,
        subscriptionsRepository: subscriptions,
      ),
      files: const PlatformBackupFileGateway(),
      clock: clock,
      tempDirectory: Directory.systemTemp,
    ),
    backupFiles: const PlatformBackupFileGateway(),
    entitlements: entitlements,
    writes: writes,
    appLock: AppLockController(
      store: MemoryAppLockStore(),
      authenticator: ScriptedDeviceAuthenticator(),
      clock: clock,
    ),
    localPro: localPro,
    ads: AdsController(config: AdsConfig.off, plan: localPro),
    csvFiles: const PlatformCsvFileGateway(),
    discovery: discovery,
    gmailClient: FakeGmailGateway(),
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: DetectedSubscriptionsScreen(),
    ),
  );
}

void main() {
  testWidgets('renders detected candidate card and ignores it on tap',
      (tester) async {
    final subscriptions = InMemorySubscriptionRepository();
    final detectedRepo = InMemoryDetectedSubscriptionRepository(
      initialCandidates: [
        DetectedSubscriptionCandidate(
          id: 'cand_test_netflix',
          merchantName: 'Netflix',
          amount: const Money(minorUnits: 649, currencyCode: 'INR'),
          billingCycle: BillingCycle.monthly,
          lastPaymentDate: DateTime(2026, 11, 5),
          sourceTypes: {DetectionSource.bankStatement, DetectionSource.gmail},
          confidenceScore: 0.90,
          createdAt: DateTime(2026, 11, 5),
        ),
      ],
    );
    final discovery = SubscriptionDiscoveryService(
      detectedRepository: detectedRepo,
      subscriptionRepository: subscriptions,
    );

    await tester.pumpWidget(
      buildTestScreen(
        subscriptions: subscriptions,
        detectedRepo: detectedRepo,
        discovery: discovery,
      ),
    );
    await tester.pumpAndSettle();

    // Verify candidate elements render
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Bank Statement'), findsOneWidget);
    expect(find.text('Gmail'), findsOneWidget);
    expect(find.text('High confidence'), findsOneWidget);

    // Tap "Ignore"
    final ignoreButton =
        find.byKey(const ValueKey('ignore-candidate-cand_test_netflix'));
    expect(ignoreButton, findsOneWidget);
    await tester.tap(ignoreButton);
    await tester.pumpAndSettle();

    // Candidate should now be removed from pending list
    expect(find.text('Netflix'), findsNothing);
    expect(detectedRepo.ignoredMerchants.contains('netflix'), isTrue);
  });

  testWidgets(
      'candidate remains in detected list when added and displays Added in green',
      (tester) async {
    final subscriptions = InMemorySubscriptionRepository();
    final candidate = DetectedSubscriptionCandidate(
      id: 'cand_google_ai',
      merchantName: 'Google Ai Plus',
      amount: const Money(minorUnits: 300, currencyCode: 'INR'),
      billingCycle: BillingCycle.monthly,
      lastPaymentDate: DateTime(2026, 9, 23),
      nextPaymentDate: DateTime(2026, 10, 23),
      sourceTypes: {DetectionSource.gmail},
      confidenceScore: 0.60,
      createdAt: DateTime(2026, 11, 21),
    );
    final detectedRepo = InMemoryDetectedSubscriptionRepository(
      initialCandidates: [candidate],
    );
    final discovery = SubscriptionDiscoveryService(
      detectedRepository: detectedRepo,
      subscriptionRepository: subscriptions,
    );

    await tester.pumpWidget(
      buildTestScreen(
        subscriptions: subscriptions,
        detectedRepo: detectedRepo,
        discovery: discovery,
      ),
    );
    await tester.pumpAndSettle();

    // Before adding: options are there
    expect(find.text('Google Ai Plus'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('add-candidate-cand_google_ai')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ignore-candidate-cand_google_ai')),
      findsOneWidget,
    );
    expect(find.text('Added'), findsNothing);

    // Accept / Add candidate
    await discovery.acceptCandidate('cand_google_ai');
    await tester.pumpAndSettle();

    // After adding: card is NOT removed from detected subscriptions list
    expect(find.text('Google Ai Plus'), findsOneWidget);
    // Says "Added" in green (both top badge and bottom banner)
    expect(find.text('Added'), findsWidgets);
    expect(
      find.byKey(const ValueKey('candidate-added-cand_google_ai')),
      findsOneWidget,
    );
    // Add/Ignore buttons are gone
    expect(
      find.byKey(const ValueKey('add-candidate-cand_google_ai')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ignore-candidate-cand_google_ai')),
      findsNothing,
    );
  });

  testWidgets('button labels are single-line and fitted', (tester) async {
    final subscriptions = InMemorySubscriptionRepository();
    final detectedRepo = InMemoryDetectedSubscriptionRepository(
      initialCandidates: [
        DetectedSubscriptionCandidate(
          id: 'cand_google_ai',
          merchantName: 'Google Ai Plus',
          amount: const Money(minorUnits: 300, currencyCode: 'INR'),
          billingCycle: BillingCycle.monthly,
          lastPaymentDate: DateTime(2026, 9, 23),
          sourceTypes: {DetectionSource.gmail},
          confidenceScore: 0.85,
          createdAt: DateTime(2026, 9, 23),
        ),
      ],
    );
    final discovery = SubscriptionDiscoveryService(
      detectedRepository: detectedRepo,
      subscriptionRepository: subscriptions,
    );

    await tester.pumpWidget(
      buildTestScreen(
        subscriptions: subscriptions,
        detectedRepo: detectedRepo,
        discovery: discovery,
      ),
    );
    await tester.pumpAndSettle();

    final ignoreBtnText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('ignore-candidate-cand_google_ai')),
        matching: find.byType(Text),
      ),
    );
    expect(ignoreBtnText.maxLines, 1);
    expect(ignoreBtnText.softWrap, isFalse);
    expect(ignoreBtnText.data, 'Ignore');

    final addBtnText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('add-candidate-cand_google_ai')),
        matching: find.byType(Text),
      ),
    );
    expect(addBtnText.maxLines, 1);
    expect(addBtnText.softWrap, isFalse);
  });
}