import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:the_registry/features/subscriptions/domain/gmail_subscription_detection_service.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_discovery_service.dart';
import 'package:the_registry/features/subscriptions/presentation/gmail_connect_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_date_picker_service.dart';
import 'support/fake_document_ocr_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/phase2_fakes.dart';

class MockGmailClient implements GmailClientGateway {
  String? email = 'user@gmail.com';
  bool throwDeadlockOnSearch = false;
  bool throwDeadlockOnSignIn = false;
  int searchCallCount = 0;
  int signInCallCount = 0;
  int signOutCallCount = 0;

  @override
  Future<String?> getCurrentUserEmail() async => email;

  @override
  Future<String?> signIn() async {
    signInCallCount++;
    if (throwDeadlockOnSignIn) {
      throw PlatformException(
        code: 'exception',
        message: 'Calling this from your main thread can lead to deadlock',
      );
    }
    return email;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    email = null;
  }

  @override
  Future<List<GmailRawMessage>> searchBillingEmails({
    DateTime? since,
    int maxResults = 50,
  }) async {
    searchCallCount++;
    if (throwDeadlockOnSearch) {
      throw PlatformException(
        code: 'exception',
        message: 'Calling this from your main thread can lead to deadlock',
      );
    }
    return const [];
  }
}

Widget buildTestScreen({
  required InMemoryDetectedSubscriptionRepository detectedRepo,
  required SubscriptionDiscoveryService discovery,
  required MockGmailClient gmailClient,
}) {
  final docs = InMemoryDocumentRepository();
  final subscriptions = InMemorySubscriptionRepository();
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
    gmailClient: gmailClient,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: GmailConnectScreen(),
    ),
  );
}

void main() {
  group('GmailConnectScreen', () {
    testWidgets('formats deadlock error into friendly retry guidance',
        (tester) async {
      final detectedRepo = InMemoryDetectedSubscriptionRepository();
      final subscriptions = InMemorySubscriptionRepository();
      final discovery = SubscriptionDiscoveryService(
        detectedRepository: detectedRepo,
        subscriptionRepository: subscriptions,
      );
      final gmailClient = MockGmailClient()..throwDeadlockOnSignIn = true;

      await tester.pumpWidget(
        buildTestScreen(
          detectedRepo: detectedRepo,
          discovery: discovery,
          gmailClient: gmailClient,
        ),
      );
      await tester.pumpAndSettle();

      // Connect button is present
      final connectBtn = find.byKey(const ValueKey('gmail-connect-button'));
      expect(connectBtn, findsOneWidget);

      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      // Error banner displays friendly message rather than raw PlatformException
      expect(
        find.text(
          'Google Play Services was busy authenticating. Please tap "Scan New Emails" to retry.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Calling this from your main thread can lead to deadlock'),
        findsNothing,
      );
    });

    testWidgets('handles deadlock during post-connect scan gracefully',
        (tester) async {
      final detectedRepo = InMemoryDetectedSubscriptionRepository();
      final subscriptions = InMemorySubscriptionRepository();
      final discovery = SubscriptionDiscoveryService(
        detectedRepository: detectedRepo,
        subscriptionRepository: subscriptions,
      );
      final gmailClient = MockGmailClient()..throwDeadlockOnSearch = true;

      await tester.pumpWidget(
        buildTestScreen(
          detectedRepo: detectedRepo,
          discovery: discovery,
          gmailClient: gmailClient,
        ),
      );
      await tester.pumpAndSettle();

      final connectBtn = find.byKey(const ValueKey('gmail-connect-button'));
      await tester.tap(connectBtn);
      // Wait for delay and scan attempt
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Google Play Services was busy authenticating. Please tap "Scan New Emails" to retry.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('connects, scans, and disconnects successfully',
        (tester) async {
      final detectedRepo = InMemoryDetectedSubscriptionRepository();
      final subscriptions = InMemorySubscriptionRepository();
      final discovery = SubscriptionDiscoveryService(
        detectedRepository: detectedRepo,
        subscriptionRepository: subscriptions,
      );
      final gmailClient = MockGmailClient();

      await tester.pumpWidget(
        buildTestScreen(
          detectedRepo: detectedRepo,
          discovery: discovery,
          gmailClient: gmailClient,
        ),
      );
      await tester.pumpAndSettle();

      // Tap connect
      await tester.tap(find.byKey(const ValueKey('gmail-connect-button')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Now connected
      expect(find.text('Connected as: user@gmail.com'), findsOneWidget);
      expect(find.byKey(const ValueKey('gmail-scan-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('gmail-disconnect-button')), findsOneWidget);

      // Tap Scan
      await tester.tap(find.byKey(const ValueKey('gmail-scan-button')));
      await tester.pumpAndSettle();
      expect(gmailClient.searchCallCount, greaterThanOrEqualTo(2));

      // Tap Disconnect
      await tester.tap(find.byKey(const ValueKey('gmail-disconnect-button')));
      await tester.pumpAndSettle();

      expect(gmailClient.signOutCallCount, 1);
      expect(find.byKey(const ValueKey('gmail-connect-button')), findsOneWidget);
    });
  });
}
