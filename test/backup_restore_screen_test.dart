import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/backup_service.dart';
import 'package:the_registry/features/backup/presentation/export_backup_screen.dart';
import 'package:the_registry/features/backup/presentation/import_backup_screen.dart';
import 'package:the_registry/features/backup/presentation/profile_screen.dart';
import 'package:the_registry/features/backup/registry_archive.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
import 'support/sample_subscription.dart';
import 'support/tiny_png.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Profile explains the encrypted backup and keeps 48dp actions', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Locale('en')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('backup-section')),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not encrypt the registry database'),
      findsOneWidget,
    );
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);
    final exportSize = tester.getSize(
      find.byKey(const ValueKey<String>('backup-export')),
    );
    expect(exportSize.height, greaterThanOrEqualTo(48));
    final importSize = tester.getSize(
      find.byKey(const ValueKey<String>('backup-import')),
    );
    expect(importSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets('Arabic backup section follows the locale direction', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();

    expect(find.text('النسخ الاحتياطي والاستعادة'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const ValueKey<String>('backup-section'))),
      ),
      TextDirection.rtl,
    );
  });

  testWidgets(
    'export does not say the file is saved before the write finishes',
    (tester) async {
      final scripted = _ScriptedBackup();
      await tester.pumpWidget(_app(const Locale('en'), scripted));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('backup-export')));
      await tester.pumpAndSettle();

      expect(find.byType(ExportBackupScreen), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey<String>('export-password')),
        '12345678',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('export-confirm-password')),
        '87654321',
      );
      await tester.tap(find.byKey(const ValueKey<String>('export-save')));
      await tester.pumpAndSettle();
      expect(find.text('Those passwords do not match.'), findsOneWidget);
      expect(find.text('Backup saved.'), findsNothing);
      expect(scripted.exportStarted, isFalse);

      await tester.enterText(
        find.byKey(const ValueKey<String>('export-confirm-password')),
        '12345678',
      );
      await tester.tap(find.byKey(const ValueKey<String>('export-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(scripted.exportStarted, isTrue);
      expect(find.text('Backup saved.'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('backup-progress')),
        findsOneWidget,
      );

      scripted.releaseExport();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.text('Backup saved.'), findsOneWidget);
      expect(find.textContaining('was not saved'), findsNothing);
    },
  );

  testWidgets(
    'import shows preview, then replace, and reports a wrong password',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final scripted = _ScriptedBackup();
      await tester.pumpWidget(_app(const Locale('en'), scripted));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('backup-import')));
      await tester.pumpAndSettle();
      expect(find.byType(ImportBackupScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('import-replace')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey<String>('import-pick')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('import-password')),
        'wrong-password',
      );
      await tester.tap(find.byKey(const ValueKey<String>('import-check')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.textContaining('does not open this backup'), findsOneWidget);
      expect(
        find.textContaining('Nothing on this device was changed'),
        findsOneWidget,
      );
      expect(find.textContaining('was replaced'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey<String>('import-password')),
        'right-password',
      );
      await tester.tap(find.byKey(const ValueKey<String>('import-check')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('import-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('import-replace')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('import-replace')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('import-replace-cancel')),
      );
      await tester.pumpAndSettle();
      expect(scripted.restored, isFalse);
      expect(find.text('Import cancelled.'), findsOneWidget);
      expect(find.textContaining('was replaced'), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('import-replace')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('import-replace-confirm')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(scripted.restored, isTrue);
      expect(
        find.textContaining('was replaced from the backup'),
        findsOneWidget,
      );
    },
  );
}

Widget _app(Locale locale, [_ScriptedBackup? backups]) {
  return RegistryApp(
    onboardingRepository: FakeOnboardingRepository(completed: true),
    locale: locale,
    backupService: backups,
    backupFiles: _IdleGateway(),
  );
}

class _IdleGateway implements BackupFileGateway {
  @override
  Future<Uint8List?> pickBackup() async => Uint8List.fromList(const [1]);

  @override
  Future<void> saveBackup({
    required Uint8List bytes,
    required String suggestedName,
  }) async {}
}

class _ScriptedBackup extends RegistryBackupService {
  _ScriptedBackup()
    : super(
        archive: MemoryRegistryArchive(
          documentsRepository: InMemoryDocumentRepository(),
          subscriptionsRepository: InMemorySubscriptionRepository(),
        ),
        files: _IdleGateway(),
        clock: const Clock(),
        tempDirectory: Directory.systemTemp,
      );

  final Completer<void> _exportGate = Completer<void>();
  var exportStarted = false;
  var restored = false;

  void releaseExport() {
    if (!_exportGate.isCompleted) {
      _exportGate.complete();
    }
  }

  @override
  Future<void> exportBackup({
    required String password,
    required BackupCancelToken cancel,
    void Function(BackupPhase phase)? onProgress,
  }) async {
    exportStarted = true;
    onProgress?.call(BackupPhase.writing);
    await _exportGate.future;
    cancel.throwIfCancelled();
  }

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
          sampleDocument(
            id: 'doc_preview',
            name: 'Preview passport',
            attachmentBytes: kTinyPngBytes,
            reminders: {ReminderPreference.sevenDaysBefore},
          ),
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
    restored = true;
    opened.consumed = true;
  }
}
