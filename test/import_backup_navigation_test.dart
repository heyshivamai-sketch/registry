import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/backup_service.dart';
import 'package:the_registry/features/backup/presentation/import_backup_screen.dart';
import 'package:the_registry/features/backup/registry_archive.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/reminders/data/memory_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
import 'support/sample_subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'successful replace leaves Import and shows restored Home counts',
    (tester) async {
      final harness = _Harness();
      final hold = Completer<void>();
      await harness.pump(tester);
      await _openImport(tester);
      await _check(tester, 'right-password');

      harness.scheduler.holdNextApply = hold;
      await tester.tap(find.byKey(const ValueKey<String>('import-replace')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('import-replace-confirm')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(harness.backup.restored, isTrue);
      expect(harness.documents.documents.single.name, 'Preview passport');
      expect(harness.subscriptions.subscriptions, hasLength(2));
      expect(find.byType(ImportBackupScreen), findsOneWidget);
      expect(_selectedTab(tester), 3);
      expect(find.textContaining('was replaced'), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('import-password')),
            )
            .controller
            ?.text,
        'right-password',
      );

      hold.complete();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );

      expect(find.byType(ImportBackupScreen), findsNothing);
      expect(_selectedTab(tester), 0);
      expect(find.text('Your Registry'), findsOneWidget);
      expect(harness.documents.documents.single.name, 'Preview passport');
      expect(harness.subscriptions.subscriptions, hasLength(2));
      expect(find.text('2 subscriptions'), findsOneWidget);
      expect(find.textContaining('35.00 USD'), findsWidgets);
      expect(find.textContaining('980 JPY'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('metric-documents')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('was replaced from the backup'),
        findsOneWidget,
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
      expect(await navigator.maybePop(), isFalse);
      await tester.pumpAndSettle();
      expect(find.byType(ImportBackupScreen), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('import-preview')),
        findsNothing,
      );
      expect(_selectedTab(tester), 0);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('backup-import')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('import-password')),
            )
            .controller
            ?.text,
        isEmpty,
      );
      expect(
        find.byKey(const ValueKey<String>('import-file-name')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('import-preview')),
        findsNothing,
      );
    },
  );

  testWidgets('wrong password stays on Import and keeps current records', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.pump(tester);
    await _openImport(tester);
    await _check(tester, 'wrong-password');

    expect(find.byType(ImportBackupScreen), findsOneWidget);
    expect(_selectedTab(tester), 3);
    expect(find.textContaining('does not open this backup'), findsOneWidget);
    expect(
      find.textContaining('Nothing on this device was changed'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('import-file-name')),
      findsOneWidget,
    );
    expect(harness.backup.restored, isFalse);
    harness.expectUnchanged();
  });

  testWidgets('cancelling the file picker stays on Import', (tester) async {
    final harness = _Harness(chooseFile: false);
    await harness.pump(tester);
    await _openImport(tester);
    await tester.tap(find.byKey(const ValueKey<String>('import-pick')));
    await tester.pumpAndSettle();

    expect(find.text('Import cancelled.'), findsOneWidget);
    expect(find.byType(ImportBackupScreen), findsOneWidget);
    expect(_selectedTab(tester), 3);
    expect(find.byKey(const ValueKey<String>('import-preview')), findsNothing);
    expect(harness.backup.restored, isFalse);
    harness.expectUnchanged();
  });

  testWidgets('cancelling Replace stays on the preview', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await _openImport(tester);
    await _check(tester, 'right-password');
    await tester.tap(find.byKey(const ValueKey<String>('import-replace')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('import-replace-cancel')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Import cancelled.'), findsOneWidget);
    expect(find.byType(ImportBackupScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('import-preview')),
      findsOneWidget,
    );
    expect(_selectedTab(tester), 3);
    expect(harness.backup.restored, isFalse);
    harness.expectUnchanged();
  });

  testWidgets('a failed restore stays on Import and keeps current records', (
    tester,
  ) async {
    final harness = _Harness(failRestore: true);
    await harness.pump(tester);
    await _openImport(tester);
    await _check(tester, 'right-password');
    await tester.tap(find.byKey(const ValueKey<String>('import-replace')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('import-replace-confirm')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byType(ImportBackupScreen), findsOneWidget);
    expect(_selectedTab(tester), 3);
    expect(find.text('Your Registry'), findsNothing);
    expect(find.textContaining('did not finish'), findsOneWidget);
    expect(
      find.textContaining('Nothing on this device was changed'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('import-preview')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('import-password')),
          )
          .controller
          ?.text,
      'right-password',
    );
    expect(harness.backup.restored, isFalse);
    harness.expectUnchanged();
  });
}

int _selectedTab(WidgetTester tester) {
  return tester
      .state<AppShellState>(find.byType(AppShell, skipOffstage: false))
      .selectedIndex;
}

Future<void> _openImport(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey<String>('backup-import')));
  await tester.pumpAndSettle();
  expect(find.byType(ImportBackupScreen), findsOneWidget);
}

Future<void> _check(WidgetTester tester, String password) async {
  await tester.tap(find.byKey(const ValueKey<String>('import-pick')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey<String>('import-password')),
    password,
  );
  await tester.tap(find.byKey(const ValueKey<String>('import-check')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

class _Harness {
  _Harness({Uint8List? pick, this.failRestore = false, bool chooseFile = true})
    : documents = InMemoryDocumentRepository(),
      subscriptions = InMemorySubscriptionRepository(),
      scheduler = _HoldScheduler() {
    picked = chooseFile ? (pick ?? Uint8List.fromList(const [1])) : null;
    documents.replaceContents([
      sampleDocument(id: 'old_doc', name: 'Old passport'),
      sampleDocument(id: 'old_card', name: 'Old card'),
    ]);
    subscriptions.replaceContents([
      sampleSubscription(
        id: 'old_sub',
        serviceName: 'Old Gym',
        minorUnits: 1000,
      ),
    ]);
    files = _PickGateway(picked);
    backup = _RestoringBackup(
      documents: documents,
      subscriptions: subscriptions,
      files: files,
      failRestore: failRestore,
    );
  }

  final InMemoryDocumentRepository documents;
  final InMemorySubscriptionRepository subscriptions;
  final _HoldScheduler scheduler;
  final bool failRestore;
  late final Uint8List? picked;
  late final _PickGateway files;
  late final _RestoringBackup backup;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
        documentRepository: documents,
        subscriptionRepository: subscriptions,
        backupService: backup,
        backupFiles: files,
        reminderScheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();
    expect(_selectedTab(tester), 0);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Old Gym'), findsWidgets);
  }

  void expectUnchanged() {
    expect(documents.documents.map((item) => item.name), [
      'Old passport',
      'Old card',
    ]);
    expect(subscriptions.subscriptions.single.serviceName, 'Old Gym');
    expect(subscriptions.subscriptions.single.amount.minorUnits, 1000);
  }
}

class _PickGateway implements BackupFileGateway {
  _PickGateway(this.pick);

  final Uint8List? pick;

  @override
  Future<Uint8List?> pickBackup() async => pick;

  @override
  Future<void> saveBackup({
    required Uint8List bytes,
    required String suggestedName,
  }) async {}
}

class _HoldScheduler extends MemoryReminderScheduler {
  Completer<void>? holdNextApply;

  @override
  Future<ReminderSyncReport> apply(ReminderBatch batch) async {
    final hold = holdNextApply;
    holdNextApply = null;
    if (hold != null) {
      await hold.future;
    }
    return super.apply(batch);
  }
}

class _RestoringBackup extends RegistryBackupService {
  _RestoringBackup({
    required this.documents,
    required this.subscriptions,
    required super.files,
    required this.failRestore,
  }) : super(
         archive: MemoryRegistryArchive(
           documentsRepository: documents,
           subscriptionsRepository: subscriptions,
         ),
         clock: const Clock(),
         tempDirectory: Directory.systemTemp,
       );

  final InMemoryDocumentRepository documents;
  final InMemorySubscriptionRepository subscriptions;
  final bool failRestore;
  var restored = false;

  @override
  Future<OpenedBackup> openBackup({
    required Uint8List bytes,
    required String password,
    required BackupCancelToken cancel,
    void Function(BackupPhase phase)? onProgress,
  }) async {
    onProgress?.call(BackupPhase.checking);
    if (password != 'right-password') {
      throw const BackupWrongPassword();
    }
    return OpenedBackup(
      BackupSnapshot(
        documents: [
          sampleDocument(id: 'doc_preview', name: 'Preview passport'),
        ],
        subscriptions: [
          sampleSubscription(id: 'sub_preview_usd', currencyCode: 'USD'),
          sampleSubscription(
            id: 'sub_preview_jpy',
            currencyCode: 'JPY',
            minorUnits: 980,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> restoreBackup({
    required OpenedBackup opened,
    required BackupCancelToken cancel,
    void Function(BackupPhase phase)? onProgress,
  }) async {
    onProgress?.call(BackupPhase.restoring);
    cancel.throwIfCancelled();
    if (failRestore) {
      throw const BackupRestoreFailed();
    }
    documents.replaceContents(opened.snapshot.documents, notify: false);
    subscriptions.replaceContents(opened.snapshot.subscriptions, notify: false);
    documents.notifyReplacement();
    subscriptions.notifyReplacement();
    restored = true;
    opened.consumed = true;
  }
}
