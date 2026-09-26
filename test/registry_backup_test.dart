import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:the_registry/core/persistence/registry_store.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/backup/backup_crypto.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/backup_payload.dart';
import 'package:the_registry/features/backup/backup_service.dart';
import 'package:the_registry/features/backup/registry_archive.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';
import 'package:the_registry/features/reminders/data/memory_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/data/notification_prompt_store.dart';
import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/reminder_coordinator.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

import 'support/sample_document.dart';
import 'support/sample_subscription.dart';
import 'support/tiny_png.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const password = 'backup-password-9f3c';
  const sentinel = 'UNIQUE_BACKUP_SENTINEL_9f3c2a';

  late Directory root;
  late Directory tempDirectory;
  late _CapturingGateway gateway;
  late RegistryBackupService service;
  late MemoryRegistryArchive memory;
  late Uint8List sealed;
  late OpenedBackup opened;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tz_data.initializeTimeZones();
    await initializeDateFormatting();
    root = await Directory.systemTemp.createTemp('registry_backup_suite_');
    tempDirectory = Directory(p.join(root.path, 'temps'));
    await tempDirectory.create();
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await documents.save(_richDocument());
    await subscriptions.save(_usdPlan());
    await subscriptions.save(_jpyPlan());
    memory = MemoryRegistryArchive(
      documentsRepository: documents,
      subscriptionsRepository: subscriptions,
    );
    gateway = _CapturingGateway();
    service = RegistryBackupService(
      archive: memory,
      files: gateway,
      clock: FixedClock(DateTime.utc(2026, 9, 25)),
      tempDirectory: tempDirectory,
    );
    await service.exportBackup(password: password, cancel: BackupCancelToken());
    sealed = Uint8List.fromList(gateway.saved!);
    opened = await service.openBackup(
      bytes: sealed,
      password: password,
      cancel: BackupCancelToken(),
    );
  });

  tearDownAll(() async {
    opened.wipeAttachments();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test(
    'export and import keep ids, money, dates, fields, history, and image',
    () {
      final document = opened.snapshot.documents.single;
      final original = _richDocument();
      expect(document.id, original.id);
      expect(document.name, sentinel);
      expect(document.category, original.category);
      expect(document.ownerName, original.ownerName);
      expect(document.issuingAuthority, original.issuingAuthority);
      expect(document.documentNumber, original.documentNumber);
      expect(document.issueDate, original.issueDate);
      expect(document.expiryDate, original.expiryDate);
      expect(document.actionDate, original.actionDate);
      expect(document.impact, original.impact);
      expect(document.renewalEffort, original.renewalEffort);
      expect(document.costOfLapsing, original.costOfLapsing);
      expect(document.dependency, original.dependency);
      expect(document.expectedChanges, original.expectedChanges);
      expect(document.notes, original.notes);
      expect(document.reminders, original.reminders);
      expect(document.createdAt, original.createdAt);
      expect(document.updatedAt, original.updatedAt);
      expect(document.schemaId, original.schemaId);
      expect(document.countryCode, original.countryCode);
      expect(document.dynamicFields, original.dynamicFields);
      expect(
        document.renewalHistory.single.id,
        original.renewalHistory.single.id,
      );
      expect(
        document.renewalHistory.single.renewedOn,
        original.renewalHistory.single.renewedOn,
      );
      expect(
        document.renewalHistory.single.previousExpiryDate,
        original.renewalHistory.single.previousExpiryDate,
      );
      expect(
        document.renewalHistory.single.newExpiryDate,
        original.renewalHistory.single.newExpiryDate,
      );
      expect(
        document.renewalHistory.single.note,
        original.renewalHistory.single.note,
      );
      expect(listEquals(document.attachmentBytes, kTinyPngBytes), isTrue);
      expect(opened.preview.documents, 1);
      expect(opened.preview.subscriptions, 2);
      expect(opened.preview.attachments, 1);

      final usd = opened.snapshot.subscriptions.firstWhere(
        (item) => item.id == 'sub_usd',
      );
      final jpy = opened.snapshot.subscriptions.firstWhere(
        (item) => item.id == 'sub_jpy',
      );
      expect(usd.amount, const Money(minorUnits: 1250, currencyCode: 'USD'));
      expect(jpy.amount, const Money(minorUnits: 980, currencyCode: 'JPY'));
      expect(usd.amount.currencyCode, 'USD');
      expect(jpy.amount.currencyCode, 'JPY');
      expect(usd.nextPaymentDate, _usdPlan().nextPaymentDate);
      expect(jpy.decideByDate, _jpyPlan().decideByDate);
      expect(jpy.reminders, _jpyPlan().reminders);
      expect(sealed.sublist(0, 4), RegistryBackupCrypto.magic);
      expect(sealed.sublist(8, 12), [0x00, 0x00, 0x4C, 0x00]);
      expect(_containsBytes(sealed, sentinel.codeUnits), isFalse);
      expect(_containsBytes(sealed, password.codeUnits), isFalse);
    },
  );

  test(
    'replace all restores the same rows and leaves no path from the file',
    () async {
      final store = await _openStore(root);
      await store.documents.save(
        sampleDocument(id: 'doc_changed', name: 'Changed passport'),
      );
      await store.subscriptions.save(
        sampleSubscription(id: 'sub_changed', serviceName: 'Changed plan'),
      );
      final archive = SqliteRegistryArchive(store);
      await archive.replaceAll(
        documents: opened.snapshot.documents,
        subscriptions: opened.snapshot.subscriptions,
        cancel: BackupCancelToken(),
      );
      expect(store.documents.documents.single.id, 'doc_roundtrip');
      expect(store.subscriptions.findById('sub_changed'), isNull);
      expect(store.subscriptions.findById('sub_usd')!.amount.minorUnits, 1250);
      expect(
        store.subscriptions.findById('sub_jpy')!.amount.currencyCode,
        'JPY',
      );
      expect(
        listEquals(
          store.documents.findById('doc_roundtrip')!.attachmentBytes,
          kTinyPngBytes,
        ),
        isTrue,
      );
      final names = store.documents.attachmentFileNames;
      expect(names, hasLength(1));
      final attachmentDir = Directory(p.join(root.path, 'round_attachments'));
      await for (final entity in attachmentDir.list(followLinks: false)) {
        final name = p.basename(entity.path);
        expect(p.isWithin(attachmentDir.path, entity.path), isTrue);
        expect(name.startsWith('.'), isFalse);
        expect(RegExp(r'^[A-Za-z0-9_-]+\.bin$').hasMatch(name), isTrue);
      }

      await store.close();
      final reopened = await RegistryStore.open(
        databasePath: p.join(root.path, 'round.db'),
        attachmentsDirectory: attachmentDir,
      );
      expect(reopened.documents.documents.single.name, sentinel);
      expect(
        listEquals(
          reopened.documents.findById('doc_roundtrip')!.attachmentBytes,
          kTinyPngBytes,
        ),
        isTrue,
      );
      expect(
        reopened.subscriptions.findById('sub_usd')!.amount.minorUnits,
        1250,
      );
      await reopened.close();
    },
  );

  test('wrong password does not change the registry', () async {
    final store = await _openStore(root, name: 'wrong');
    await store.documents.save(sampleDocument(id: 'doc_keep', name: 'Keep me'));
    final archive = SqliteRegistryArchive(store);
    final protected = RegistryBackupService(
      archive: archive,
      files: _CapturingGateway(),
      clock: const Clock(),
      tempDirectory: tempDirectory,
    );
    await expectLater(
      protected.openBackup(
        bytes: sealed,
        password: 'another-password',
        cancel: BackupCancelToken(),
      ),
      throwsA(isA<BackupWrongPassword>()),
    );
    expect(store.documents.documents.single.name, 'Keep me');
    expect(store.subscriptions.subscriptions, isEmpty);
    await store.close();
  });

  test('a changed ciphertext is rejected and the registry stays', () async {
    final tampered = Uint8List.fromList(sealed);
    tampered[tampered.length - 1] ^= 0x01;
    final store = await _openStore(root, name: 'tamper');
    await store.documents.save(sampleDocument(id: 'doc_keep', name: 'Keep me'));
    final archive = SqliteRegistryArchive(store);
    final protected = RegistryBackupService(
      archive: archive,
      files: _CapturingGateway(),
      clock: const Clock(),
      tempDirectory: tempDirectory,
    );
    await expectLater(
      protected.openBackup(
        bytes: tampered,
        password: password,
        cancel: BackupCancelToken(),
      ),
      throwsA(isA<BackupTampered>()),
    );
    expect(store.documents.documents.single.name, 'Keep me');
    await store.close();
  });

  test('an unsupported container version is rejected before restore', () async {
    final newer = Uint8List.fromList(sealed);
    newer[5] = 2;
    await expectLater(
      RegistryBackupCrypto.decrypt(
        file: newer,
        password: password,
        cancel: BackupCancelToken(),
      ),
      throwsA(isA<BackupUnsupportedVersion>()),
    );
    final payload = Uint8List.fromList([
      ...RegistryBackupPayload.magic,
      0,
      99,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]);
    expect(
      () => RegistryBackupPayload.decode(payload),
      throwsA(isA<BackupUnsupportedVersion>()),
    );
  });

  test('unsafe, truncated, and oversized input is rejected', () async {
    expect(
      () => RegistryBackupPayload.decode(Uint8List.fromList(const [1, 2, 3])),
      throwsA(isA<BackupInvalid>()),
    );
    expect(
      () => RegistryBackupPayload.encode(
        BackupSnapshot(
          documents: [_richDocument().copyWith(id: '../outside')],
          subscriptions: const [],
        ),
      ),
      throwsA(isA<BackupInvalid>()),
    );
    expect(
      () => RegistryBackupPayload.encode(
        BackupSnapshot(
          documents: [
            _richDocument().copyWith(
              attachmentBytes: Uint8List(BackupLimits.maxAttachmentBytes + 1),
            ),
          ],
          subscriptions: const [],
        ),
      ),
      throwsA(isA<BackupOversized>()),
    );
    await expectLater(
      RegistryBackupCrypto.decrypt(
        file: Uint8List(BackupLimits.maxBackupFileBytes + 1),
        password: password,
        cancel: BackupCancelToken(),
      ),
      throwsA(isA<BackupOversized>()),
    );
  });

  test('cancellation writes nothing and removes temporary files', () async {
    final cancel = BackupCancelToken();
    final files = _CapturingGateway();
    final exporting = RegistryBackupService(
      archive: memory,
      files: files,
      clock: const Clock(),
      tempDirectory: tempDirectory,
    );
    await expectLater(
      exporting.exportBackup(
        password: password,
        cancel: cancel,
        onProgress: (phase) {
          if (phase == BackupPhase.protecting) {
            cancel.cancel();
          }
        },
      ),
      throwsA(isA<BackupCancelled>()),
    );
    expect(files.saved, isNull);
    await _expectNoTemps(tempDirectory);
  });

  test('a failed destination write is not described as saved', () async {
    final files = _CapturingGateway(fail: const BackupDestinationException());
    final exporting = RegistryBackupService(
      archive: memory,
      files: files,
      clock: const Clock(),
      tempDirectory: tempDirectory,
    );
    await expectLater(
      exporting.exportBackup(password: password, cancel: BackupCancelToken()),
      throwsA(isA<BackupDestinationException>()),
    );
    expect(files.attempts, 1);
    await _expectNoTemps(tempDirectory);

    final full = _CapturingGateway(
      fail: const FileSystemException(
        'write',
        'dest',
        OSError('No space left on device', 28),
      ),
    );
    final tight = RegistryBackupService(
      archive: memory,
      files: full,
      clock: const Clock(),
      tempDirectory: tempDirectory,
    );
    await expectLater(
      tight.exportBackup(password: password, cancel: BackupCancelToken()),
      throwsA(isA<BackupInsufficientStorage>()),
    );
    await _expectNoTemps(tempDirectory);
  });

  test(
    'a failed restore leaves the previous registry and attachments',
    () async {
      final store = await _openStore(root, name: 'rollback');
      final original = sampleDocument(
        id: 'doc_old',
        name: 'Old passport',
        attachmentBytes: kTinyPngBytes,
      );
      await store.documents.save(original);
      await store.subscriptions.save(
        sampleSubscription(
          id: 'sub_old',
          serviceName: 'Old plan',
          minorUnits: 400,
        ),
      );
      final previousName = store.documents.attachmentFileNameFor('doc_old');
      final archive = SqliteRegistryArchive(store)
        ..beforeCommit = () async {
          throw StateError('interrupted restore');
        };
      final restoring = RegistryBackupService(
        archive: archive,
        files: _CapturingGateway(),
        clock: const Clock(),
        tempDirectory: tempDirectory,
      );
      await expectLater(
        restoring.restoreBackup(opened: opened, cancel: BackupCancelToken()),
        throwsA(isA<BackupRestoreFailed>()),
      );
      expect(store.documents.documents.single.name, 'Old passport');
      expect(store.subscriptions.findById('sub_usd'), isNull);
      expect(store.subscriptions.findById('sub_old')!.amount.minorUnits, 400);
      expect(store.documents.attachmentFileNameFor('doc_old'), previousName);
      expect(
        listEquals(
          store.documents.findById('doc_old')!.attachmentBytes,
          kTinyPngBytes,
        ),
        isTrue,
      );
      final attachmentDir = Directory(
        p.join(root.path, 'rollback_attachments'),
      );
      final names = await attachmentDir
          .list(followLinks: false)
          .map((entity) => p.basename(entity.path))
          .toList();
      expect(names, [previousName]);
      await store.close();
    },
  );

  test('a cancelled restore leaves the previous registry', () async {
    final store = await _openStore(root, name: 'cancel_restore');
    await store.documents.save(
      sampleDocument(id: 'doc_old', name: 'Old passport'),
    );
    final archive = SqliteRegistryArchive(store);
    final cancel = BackupCancelToken()..cancel();
    await expectLater(
      archive.replaceAll(
        documents: opened.snapshot.documents,
        subscriptions: opened.snapshot.subscriptions,
        cancel: cancel,
      ),
      throwsA(isA<BackupCancelled>()),
    );
    expect(store.documents.documents.single.name, 'Old passport');
    await store.close();
  });

  test(
    'successful restore reconciles reminders without a new prompt',
    () async {
      final documents = InMemoryDocumentRepository();
      final subscriptions = InMemorySubscriptionRepository();
      await documents.save(
        sampleDocument(id: 'doc_other', name: 'Other', reminders: {}),
      );
      final archive = MemoryRegistryArchive(
        documentsRepository: documents,
        subscriptionsRepository: subscriptions,
      );
      final scheduler = MemoryReminderScheduler();
      final prompts = MemoryNotificationPromptStore();
      final coordinator = ReminderCoordinator(
        documents: documents,
        subscriptions: subscriptions,
        scheduler: scheduler,
        clock: FixedClock(DateTime.utc(2026, 1, 1)),
        timeZone: FixedTimeZoneSource(tz.UTC),
        promptStore: prompts,
      );
      await coordinator.start();
      expect(scheduler.permissionRequestCount, 0);
      expect(prompts.prompted, isFalse);
      final requestsBefore = scheduler.permissionRequestCount;
      await archive.replaceAll(
        documents: opened.snapshot.documents,
        subscriptions: opened.snapshot.subscriptions,
        cancel: BackupCancelToken(),
      );
      await coordinator.reconcile();
      expect(scheduler.permissionRequestCount, requestsBefore);
      expect(prompts.prompted, isFalse);
      expect(documents.findById('doc_roundtrip'), isNotNull);
      expect(documents.findById('doc_other'), isNull);
      expect(
        scheduler.pending.values.map((item) => item.recordId),
        contains('doc_roundtrip'),
      );
      coordinator.dispose();
    },
  );
}

RegistryDocument _richDocument() {
  return sampleDocument(
    id: 'doc_roundtrip',
    name: 'UNIQUE_BACKUP_SENTINEL_9f3c2a',
    schemaId: DocumentSchemaIds.indiaAadhaar,
    countryCode: 'IN',
    issueDate: DateTime.utc(2024, 3, 2, 1, 2, 3, 4, 5),
    expiryDate: DateTime(2030, 4, 5, 6, 7, 8, 9, 10),
    actionDate: DateTime(2030, 3, 1),
    createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5, 6, 7),
    updatedAt: DateTime(2026, 8, 9, 10, 11, 12, 13, 14),
    reminders: {
      ReminderPreference.onActionDate,
      ReminderPreference.thirtyDaysBefore,
    },
    attachmentBytes: kTinyPngBytes,
    dynamicFields: const [
      DocumentFieldValue(
        id: 'field_aadhaar',
        fieldKey: 'aadhaar_number',
        customLabel: 'رقم',
        value: '1234 5678 9012',
        sensitive: true,
        isCustom: true,
      ),
    ],
    renewalHistory: [
      RenewalHistoryEntry(
        id: 'ren_roundtrip',
        renewedOn: DateTime.utc(2025, 5, 6),
        previousExpiryDate: DateTime(2026, 5, 6),
        newExpiryDate: DateTime(2030, 4, 5),
        note: 'Renewed on paper',
      ),
    ],
  );
}

RegistrySubscription _usdPlan() {
  return sampleSubscription(
    id: 'sub_usd',
    serviceName: 'City Gym',
    minorUnits: 1250,
    currencyCode: 'USD',
    createdAt: DateTime.utc(2026, 1, 2, 3),
    updatedAt: DateTime(2026, 2, 3),
  );
}

RegistrySubscription _jpyPlan() {
  return sampleSubscription(
    id: 'sub_jpy',
    serviceName: 'Newsstand',
    minorUnits: 980,
    currencyCode: 'JPY',
    billingCycle: BillingCycle.yearly,
    reminders: {
      SubscriptionReminder.onChargeDay,
      SubscriptionReminder.oneDayBefore,
    },
    createdAt: DateTime(2026, 4, 4),
  );
}

Future<RegistryStore> _openStore(Directory root, {String name = 'round'}) {
  return RegistryStore.open(
    databasePath: p.join(root.path, '$name.db'),
    attachmentsDirectory: Directory(p.join(root.path, '${name}_attachments')),
  );
}

Future<void> _expectNoTemps(Directory directory) async {
  final leftovers = await directory
      .list(followLinks: false)
      .where(
        (entity) => p.basename(entity.path).startsWith('.registry-backup-'),
      )
      .toList();
  expect(leftovers, isEmpty);
}

bool _containsBytes(Uint8List data, List<int> needle) {
  if (needle.isEmpty || needle.length > data.length) {
    return false;
  }
  for (var start = 0; start <= data.length - needle.length; start++) {
    var found = true;
    for (var index = 0; index < needle.length; index++) {
      if (data[start + index] != needle[index]) {
        found = false;
        break;
      }
    }
    if (found) {
      return true;
    }
  }
  return false;
}

class _CapturingGateway implements BackupFileGateway {
  _CapturingGateway({this.fail});

  final Object? fail;
  Uint8List? saved;
  var attempts = 0;

  @override
  Future<Uint8List?> pickBackup() async => saved;

  @override
  Future<void> saveBackup({
    required Uint8List bytes,
    required String suggestedName,
  }) async {
    attempts += 1;
    final error = fail;
    if (error != null) {
      throw error;
    }
    saved = Uint8List.fromList(bytes);
  }
}
