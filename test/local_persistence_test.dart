import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/persistence/persisted_values.dart';
import 'package:the_registry/core/persistence/registry_database.dart';
import 'package:the_registry/core/persistence/registry_store.dart';
import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_estimate.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_status.dart';

import 'support/sample_document.dart';
import 'support/sample_subscription.dart';
import 'support/tiny_png.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late String databasePath;
  late Directory attachments;
  final stores = <RegistryStore>[];

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('registry_store_');
    databasePath = p.join(root.path, 'registry.db');
    attachments = Directory(p.join(root.path, 'attachments'));
  });

  tearDown(() async {
    for (final store in stores) {
      await store.close();
    }
    stores.clear();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  Future<RegistryStore> openStore() async {
    final store = await RegistryStore.open(
      databasePath: databasePath,
      attachmentsDirectory: attachments,
    );
    stores.add(store);
    return store;
  }

  Future<void> release(RegistryStore store) async {
    await store.close();
    stores.remove(store);
  }

  test(
    'documents create, update, delete, and reopen on the same files',
    () async {
      final created = _fullDocument(attachmentBytes: kTinyPngBytes);
      final store = await openStore();
      var notifications = 0;
      store.documents.addListener(() => notifications++);

      await store.documents.save(created);
      expect(notifications, 1);
      expect(store.documents.documents.single.id, created.id);
      expect(
        () => store.documents.documents.add(sampleDocument(id: 'other')),
        throwsUnsupportedError,
      );

      notifications = 0;
      final renamed = created.copyWith(
        name: 'Updated passport',
        updatedAt: DateTime.utc(2026, 8, 2, 3, 4, 5),
      );
      expect(await store.documents.update(renamed), isTrue);
      expect(notifications, 1);
      expect(store.documents.documents.map((item) => item.id), [created.id]);

      final second = sampleDocument(id: 'doc_second', name: 'Visa');
      await store.documents.save(second);
      expect(store.documents.documents.map((item) => item.id), [
        second.id,
        created.id,
      ]);
      await store.documents.update(renamed.copyWith(notes: 'Still first'));
      expect(store.documents.documents.map((item) => item.id), [
        second.id,
        created.id,
      ]);

      notifications = 0;
      expect(
        await store.documents.update(sampleDocument(id: 'missing')),
        isFalse,
      );
      expect(notifications, 0);
      expect(await store.documents.delete('missing'), isFalse);
      expect(notifications, 0);

      await release(store);
      final reopened = await openStore();
      expect(reopened.documents.documents.map((item) => item.id), [
        second.id,
        created.id,
      ]);
      expectDocument(
        reopened.documents.findById(created.id)!,
        renamed.copyWith(notes: 'Still first'),
      );
      expect(
        DocumentStatus.resolve(
          reopened.documents.findById(created.id)!,
          now: DateTime(2026, 9, 23),
        ),
        DocumentStatus.resolve(
          renamed.copyWith(notes: 'Still first'),
          now: DateTime(2026, 9, 23),
        ),
      );

      expect(await reopened.documents.delete(created.id), isTrue);
      expect(reopened.documents.findById(created.id), isNull);
      await release(reopened);
      final afterDelete = await openStore();
      expect(afterDelete.documents.findById(created.id), isNull);
      expect(afterDelete.documents.findById(second.id)?.name, 'Visa');
    },
  );

  test('dynamic fields, dates, and renewal history keep their order', () async {
    final history = [
      RenewalHistoryEntry(
        id: 'ren_new',
        renewedOn: DateTime(2026, 6, 1, 9, 30),
        previousExpiryDate: DateTime(2026, 5, 1),
        newExpiryDate: DateTime(2028, 5, 1),
        note: 'Photo updated',
      ),
      RenewalHistoryEntry(
        id: 'ren_old',
        renewedOn: DateTime.utc(2024, 1, 2, 3, 4, 5, 6, 7),
        previousExpiryDate: DateTime(2023, 1, 1),
        newExpiryDate: DateTime(2026, 5, 1),
      ),
    ];
    final fields = [
      const DocumentFieldValue(
        id: 'passport_number',
        fieldKey: 'passport_number',
        value: 'AB12345678',
        sensitive: true,
      ),
      const DocumentFieldValue(
        id: 'nationality',
        fieldKey: 'nationality',
        value: 'DZ',
      ),
      const DocumentFieldValue(
        id: 'custom_blank',
        fieldKey: 'custom',
        value: '',
        customLabel: 'Locker',
        isCustom: true,
      ),
      const DocumentFieldValue(
        id: 'date_of_birth',
        fieldKey: 'date_of_birth',
        value: '1990-01-02',
        isDate: true,
      ),
    ];
    final document = _fullDocument(
      dynamicFields: fields,
      renewalHistory: history,
    );
    final empty = RegistryDocument(
      id: 'doc_empty',
      name: 'Spare card',
      category: DocumentCategory.other,
      expiryDate: DateTime(2030, 1, 1),
      impact: DocumentImpact.low,
      createdAt: DateTime(2026, 2, 2),
      schemaId: DocumentSchemaIds.genericOther,
    );

    final store = await openStore();
    await store.documents.save(document);
    await store.documents.save(empty);
    await release(store);

    final reopened = await openStore();
    final loaded = reopened.documents.findById(document.id)!;
    expectDocument(loaded, document);
    expect(loaded.dynamicFields, fields);
    expect(loaded.visibleDynamicFields.map((field) => field.id), [
      'passport_number',
      'nationality',
      'date_of_birth',
    ]);
    expect(loaded.dynamicFields[0].maskedValue, '••••••5678');
    expect(loaded.maskedDocumentNumber, '••••••5678');
    expect(loaded.renewalHistory.map((entry) => entry.id), [
      'ren_new',
      'ren_old',
    ]);
    expect(loaded.renewalHistory.last.note, isNull);
    final blank = reopened.documents.findById('doc_empty')!;
    expect(blank.ownerName, isNull);
    expect(blank.notes, isNull);
    expect(blank.reminders, isEmpty);
    expect(blank.actionDate, isNull);
    expect(blank.dynamicFields, isEmpty);
    expect(blank.renewalHistory, isEmpty);
  });

  test('attachments survive replace, removal, and a new repository', () async {
    final original = _fullDocument(attachmentBytes: kTinyPngBytes);
    final store = await openStore();
    await store.documents.save(original);
    final firstName = store.documents.attachmentFileNameFor(original.id)!;
    expect(
      p.isWithin(attachments.path, p.join(attachments.path, firstName)),
      isTrue,
    );
    expect(
      await File(p.join(attachments.path, '.$firstName.tmp')).exists(),
      isFalse,
    );

    final replacedBytes = Uint8List.fromList(const [9, 8, 7, 6]);
    expect(
      await store.documents.update(
        original.copyWith(attachmentBytes: replacedBytes),
      ),
      isTrue,
    );
    final secondName = store.documents.attachmentFileNameFor(original.id);
    expect(secondName, isNot(firstName));
    expect(await File(p.join(attachments.path, firstName)).exists(), isFalse);
    expect(
      store.documents.findById(original.id)!.attachmentBytes,
      replacedBytes,
    );

    await expectLater(
      store.documents.save(
        original.copyWith(attachmentBytes: Uint8List.fromList(const [1])),
      ),
      throwsStateError,
    );
    expect(store.documents.documents, hasLength(1));
    expect(
      store.documents.findById(original.id)!.attachmentBytes,
      replacedBytes,
    );

    await release(store);
    final reopened = await openStore();
    expect(
      reopened.documents.findById(original.id)!.attachmentBytes,
      replacedBytes,
    );
    expect(
      reopened.documents.attachmentByteLengthFor(original.id),
      replacedBytes.length,
    );

    final keptName = reopened.documents.attachmentFileNameFor(original.id);
    await reopened.documents.update(
      reopened.documents.findById(original.id)!.copyWith(name: 'Named only'),
    );
    expect(reopened.documents.attachmentFileNameFor(original.id), keptName);
    expect(
      reopened.documents.findById(original.id)!.attachmentBytes,
      replacedBytes,
    );

    await reopened.documents.update(
      reopened.documents.findById(original.id)!.copyWith(attachmentBytes: null),
    );
    expect(reopened.documents.attachmentFileNameFor(original.id), isNull);
    expect(reopened.documents.findById(original.id)!.hasAttachment, isFalse);
    expect(await File(p.join(attachments.path, secondName!)).exists(), isFalse);

    await reopened.documents.delete(original.id);
    await release(reopened);
    final afterDelete = await openStore();
    expect(afterDelete.documents.findById(original.id), isNull);
    final leftovers = await attachments
        .list()
        .where((entity) => entity is File)
        .toList();
    expect(leftovers, isEmpty);
  });

  test('unsafe attachment names stay inside the private directory', () async {
    final document = _fullDocument(
      id: r'../../outside',
      attachmentBytes: kTinyPngBytes,
    );
    final store = await openStore();
    await store.documents.save(document);
    final name = store.documents.attachmentFileNameFor(document.id)!;
    expect(name.contains('/'), isFalse);
    expect(name.contains('..'), isFalse);
    final saved = File(p.join(attachments.path, name));
    expect(p.isWithin(attachments.path, saved.path), isTrue);
    expect(await saved.exists(), isTrue);
    expect(await File(p.join(root.path, 'outside.bin')).exists(), isFalse);

    await release(store);
    final reopened = await openStore();
    expect(
      reopened.documents.findById(document.id)!.attachmentBytes,
      kTinyPngBytes,
    );
  });

  test('a missing attachment does not delete the document', () async {
    final document = _fullDocument(attachmentBytes: kTinyPngBytes);
    final store = await openStore();
    await store.documents.save(document);
    final name = store.documents.attachmentFileNameFor(document.id)!;
    await release(store);
    await File(p.join(attachments.path, name)).delete();

    final reopened = await openStore();
    final loaded = reopened.documents.findById(document.id)!;
    expect(loaded.name, document.name);
    expect(loaded.documentNumber, document.documentNumber);
    expect(loaded.attachmentBytes, isNull);
    expect(reopened.documents.attachmentFileNameFor(document.id), name);

    await reopened.documents.update(loaded.copyWith(name: 'Still stored'));
    expect(reopened.documents.attachmentFileNameFor(document.id), name);
    expect(reopened.documents.findById(document.id)!.name, 'Still stored');
  });

  test('an unreadable attachment does not delete the document', () async {
    final document = _fullDocument(attachmentBytes: kTinyPngBytes);
    final store = await openStore();
    await store.documents.save(document);
    final name = store.documents.attachmentFileNameFor(document.id)!;
    await release(store);
    final path = p.join(attachments.path, name);
    await File(path).delete();
    await Directory(path).create();

    final reopened = await openStore();
    final loaded = reopened.documents.findById(document.id)!;
    expect(loaded.category, document.category);
    expect(loaded.expiryDate, document.expiryDate);
    expect(loaded.attachmentBytes, isNull);
    expect(loaded.dynamicFields, document.dynamicFields);
    expect(reopened.documents.documents, hasLength(1));
  });

  test(
    'opening storage removes orphan files and keeps the live image',
    () async {
      final document = _fullDocument(attachmentBytes: kTinyPngBytes);
      final store = await openStore();
      await store.documents.save(document);
      final liveName = store.documents.attachmentFileNameFor(document.id)!;
      final orphan = File(p.join(attachments.path, 'orphan_1.bin'));
      final partial = File(p.join(attachments.path, '.partial.bin.tmp'));
      await orphan.writeAsBytes(const [1, 2, 3]);
      await partial.writeAsBytes(const [4]);
      await release(store);

      final reopened = await openStore();
      expect(await orphan.exists(), isFalse);
      expect(await partial.exists(), isFalse);
      expect(await File(p.join(attachments.path, liveName)).exists(), isTrue);
      expect(
        reopened.documents.findById(document.id)!.attachmentBytes,
        kTinyPngBytes,
      );
    },
  );

  test('subscriptions persist cancellation, reactivation, and money', () async {
    final gym = sampleSubscription(
      id: 'sub_gym',
      minorUnits: 3500,
      currencyCode: 'USD',
      billingCycle: BillingCycle.monthly,
    );
    final news = sampleSubscription(
      id: 'sub_news',
      serviceName: 'Morning paper',
      planName: null,
      minorUnits: 1200,
      currencyCode: 'JPY',
      billingCycle: BillingCycle.yearly,
      includeDecideBy: false,
      autoRenew: false,
      impact: DocumentImpact.low,
      reminders: const {},
      notes: null,
      lifecycle: SubscriptionLifecycle.active,
    );
    final store = await openStore();
    var notifications = 0;
    store.subscriptions.addListener(() => notifications++);
    await store.subscriptions.save(gym);
    await store.subscriptions.save(news);
    expect(notifications, 2);
    expect(store.subscriptions.subscriptions.map((item) => item.id), [
      news.id,
      gym.id,
    ]);

    final cancelled = gym.copyWith(
      lifecycle: SubscriptionLifecycle.cancelled,
      updatedAt: DateTime(2026, 4, 4),
    );
    expect(await store.subscriptions.update(cancelled), isTrue);
    expect(
      await store.subscriptions.update(sampleSubscription(id: 'missing')),
      isFalse,
    );
    final totalsWhileCancelled = SubscriptionEstimate.monthlyTotals(
      store.subscriptions.subscriptions,
    );
    expect(totalsWhileCancelled, hasLength(1));
    expect(totalsWhileCancelled.single.code, 'JPY');

    await release(store);
    final reopened = await openStore();
    final loadedGym = reopened.subscriptions.findById(gym.id)!;
    final loadedNews = reopened.subscriptions.findById(news.id)!;
    expectSubscription(loadedGym, cancelled);
    expectSubscription(loadedNews, news);
    expect(loadedGym.isCancelled, isTrue);
    expect(
      SubscriptionStatus.resolve(loadedGym, now: DateTime(2026, 9, 23)),
      RegistryStatus.neutral,
    );
    expect(loadedNews.amount.minorUnits, 1200);
    expect(loadedNews.amount.currencyCode, 'JPY');
    expect(loadedNews.decideByDate, isNull);
    expect(loadedNews.planName, isNull);
    expect(loadedNews.notes, isNull);
    expect(loadedNews.reminders, isEmpty);
    expect(reopened.subscriptions.subscriptions.map((item) => item.id), [
      news.id,
      gym.id,
    ]);
    expect(
      SubscriptionEstimate.monthlyTotals(reopened.subscriptions.subscriptions),
      totalsWhileCancelled,
    );

    final reactivated = loadedGym.copyWith(
      lifecycle: SubscriptionLifecycle.active,
      nextPaymentDate: DateTime(2027, 1, 15),
      decideByDate: DateTime(2027, 1, 10),
      updatedAt: DateTime(2026, 9, 1),
    );
    await reopened.subscriptions.update(reactivated);
    await release(reopened);
    final afterReactivation = await openStore();
    final active = afterReactivation.subscriptions.findById(gym.id)!;
    expect(active.isActive, isTrue);
    expect(active.amount, const Money(minorUnits: 3500, currencyCode: 'USD'));
    expect(
      SubscriptionStatus.resolve(active, now: DateTime(2026, 9, 23)),
      RegistryStatus.active,
    );
    final totals = SubscriptionEstimate.monthlyTotals(
      afterReactivation.subscriptions.subscriptions,
    );
    expect(totals.map((total) => total.code), ['JPY', 'USD']);
    expect(
      totals,
      SubscriptionEstimate.monthlyTotals([
        afterReactivation.subscriptions.findById(news.id)!,
        active,
      ]),
    );

    expect(await afterReactivation.subscriptions.delete(news.id), isTrue);
    expect(await afterReactivation.subscriptions.delete(news.id), isFalse);
    await release(afterReactivation);
    final afterDelete = await openStore();
    expect(afterDelete.subscriptions.findById(news.id), isNull);
    expect(afterDelete.subscriptions.findById(gym.id)?.amount.minorUnits, 3500);
  });

  test('version 1 rows survive the version 2 migration', () async {
    final created = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await RegistryDatabase.applyMigrations(db, 0, 1);
      },
    );
    await created.insert('documents', {
      'id': 'legacy_doc',
      'name': 'Legacy passport',
      'category': DocumentCategory.passport.name,
      'document_number': 'ZZ9988',
      'expiry_date': PersistedValues.encodeDate(DateTime(2028, 1, 1)),
      'impact': DocumentImpact.high.name,
      'reminders': ReminderPreference.thirtyDaysBefore.name,
      'created_at': PersistedValues.encodeDate(DateTime(2025, 5, 5)),
      'schema_id': DocumentSchemaIds.genericPassport,
      'country_code': 'DZ',
      'sort_rank': 1,
    });
    await created.insert('subscriptions', {
      'id': 'legacy_sub',
      'created_at': PersistedValues.encodeDate(DateTime(2025, 5, 5)),
      'service_name': 'Legacy news',
      'category': SubscriptionCategory.education.name,
      'minor_units': 500,
      'currency_code': 'EUR',
      'billing_cycle': BillingCycle.monthly.name,
      'next_payment_date': PersistedValues.encodeDate(DateTime(2026, 12, 1)),
      'auto_renew': 0,
      'lifecycle': SubscriptionLifecycle.active.name,
      'impact': DocumentImpact.low.name,
      'reminders': '',
      'sort_rank': 1,
    });
    final tablesBefore = await created.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(
      tablesBefore.map((row) => row['name']),
      isNot(contains('document_fields')),
    );
    await created.close();

    final store = await openStore();
    final legacy = store.documents.findById('legacy_doc')!;
    expect(legacy.name, 'Legacy passport');
    expect(legacy.documentNumber, 'ZZ9988');
    expect(legacy.countryCode, 'DZ');
    expect(legacy.reminders, {ReminderPreference.thirtyDaysBefore});
    expect(legacy.dynamicFields, isEmpty);
    expect(legacy.renewalHistory, isEmpty);
    expect(legacy.attachmentBytes, isNull);
    expect(
      store.subscriptions.findById('legacy_sub')!.amount,
      const Money(minorUnits: 500, currencyCode: 'EUR'),
    );
    expect(store.subscriptions.findById('legacy_sub')!.autoRenew, isFalse);

    final added = _fullDocument(id: 'doc_after_migration');
    await store.documents.save(added);
    expect(store.documents.documents.first.id, added.id);
    await release(store);

    final versionDb = await openDatabase(
      databasePath,
      version: RegistryDatabase.schemaVersion,
      singleInstance: false,
      onCreate: (db, version) async => fail('schema should already exist'),
      onUpgrade: (db, oldVersion, newVersion) async => fail('already migrated'),
    );
    final userVersion = await versionDb.rawQuery('PRAGMA user_version');
    expect(userVersion.single['user_version'], RegistryDatabase.schemaVersion);
    final tablesAfter = await versionDb.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(
      tablesAfter.map((row) => row['name']),
      containsAll(['document_fields', 'renewal_history', 'subscriptions']),
    );
    await versionDb.close();

    final reopened = await openStore();
    expect(reopened.documents.findById('legacy_doc')?.name, 'Legacy passport');
    expectDocument(reopened.documents.findById(added.id)!, added);
    expect(
      reopened.subscriptions.findById('legacy_sub')?.serviceName,
      'Legacy news',
    );
  });

  test(
    'a failed open leaves the database bytes and records in place',
    () async {
      final document = _fullDocument();
      final subscription = sampleSubscription();
      final store = await openStore();
      await store.documents.save(document);
      await store.subscriptions.save(subscription);
      await release(store);
      final before = await File(databasePath).readAsBytes();

      await expectLater(
        RegistryStore.open(
          databasePath: databasePath,
          attachmentsDirectory: attachments,
          openDatabase: (_) async => throw StateError('storage unavailable'),
        ),
        throwsA(isA<StateError>()),
      );
      expect(await File(databasePath).readAsBytes(), before);

      final reopened = await openStore();
      expectDocument(reopened.documents.findById(document.id)!, document);
      expectSubscription(
        reopened.subscriptions.findById(subscription.id)!,
        subscription,
      );
    },
  );

  test('a failed read or upgrade does not erase existing records', () async {
    final document = _fullDocument();
    final subscription = sampleSubscription();
    final store = await openStore();
    await store.documents.save(document);
    await store.subscriptions.save(subscription);
    await release(store);

    final corrupt = await openDatabase(
      databasePath,
      version: RegistryDatabase.schemaVersion,
      singleInstance: false,
    );
    await corrupt.update(
      'documents',
      {'category': 'not-a-category'},
      where: 'id = ?',
      whereArgs: [document.id],
    );
    await corrupt.close();
    await expectLater(openStore(), throwsA(isA<FormatException>()));

    final repair = await openDatabase(
      databasePath,
      version: RegistryDatabase.schemaVersion,
      singleInstance: false,
    );
    await repair.update(
      'documents',
      {'category': document.category.name},
      where: 'id = ?',
      whereArgs: [document.id],
    );
    await repair.close();
    final restored = await openStore();
    expectDocument(restored.documents.findById(document.id)!, document);
    expectSubscription(
      restored.subscriptions.findById(subscription.id)!,
      subscription,
    );
    await release(restored);

    Object? upgradeFailure;
    try {
      await openDatabase(
        databasePath,
        version: RegistryDatabase.schemaVersion + 1,
        singleInstance: false,
        onUpgrade: (db, oldVersion, newVersion) async {
          throw StateError('upgrade failed');
        },
      );
    } catch (error) {
      upgradeFailure = error;
    }
    expect(upgradeFailure, isNotNull);

    final afterUpgradeFailure = await openStore();
    expectDocument(
      afterUpgradeFailure.documents.findById(document.id)!,
      document,
    );
    expect(
      afterUpgradeFailure.subscriptions.findById(subscription.id)?.amount,
      subscription.amount,
    );
  });
}

RegistryDocument _fullDocument({
  String id = 'doc_full',
  Uint8List? attachmentBytes,
  List<DocumentFieldValue> dynamicFields = const [],
  List<RenewalHistoryEntry> renewalHistory = const [],
}) {
  return RegistryDocument(
    id: id,
    name: 'Family passport',
    category: DocumentCategory.passport,
    ownerName: 'Amira',
    issuingAuthority: 'Algeria',
    documentNumber: 'AB12345678',
    issueDate: DateTime(2024, 2, 29, 23, 59, 58, 7, 6),
    expiryDate: DateTime(2028, 10, 5),
    actionDate: DateTime(2028, 9, 1),
    impact: DocumentImpact.critical,
    renewalEffort: RenewalEffort.difficult,
    costOfLapsing: 'Travel disruption',
    dependency: 'Family travel',
    expectedChanges: 'New photo',
    notes: 'Keep a copy',
    reminders: const {
      ReminderPreference.onActionDate,
      ReminderPreference.sevenDaysBefore,
    },
    attachmentBytes: attachmentBytes,
    createdAt: DateTime(2026, 1, 2, 8, 9, 10),
    updatedAt: DateTime.utc(2026, 5, 1, 12, 30, 15, 8, 9),
    renewalHistory: renewalHistory,
    schemaId: DocumentSchemaIds.genericPassport,
    countryCode: DocumentCountryCodes.generic,
    dynamicFields: dynamicFields,
  );
}

void expectDocument(RegistryDocument actual, RegistryDocument expected) {
  expect(actual.id, expected.id);
  expect(actual.name, expected.name);
  expect(actual.category, expected.category);
  expect(actual.ownerName, expected.ownerName);
  expect(actual.issuingAuthority, expected.issuingAuthority);
  expect(actual.documentNumber, expected.documentNumber);
  expect(actual.issueDate, expected.issueDate);
  expect(actual.expiryDate, expected.expiryDate);
  expect(actual.actionDate, expected.actionDate);
  expect(actual.impact, expected.impact);
  expect(actual.renewalEffort, expected.renewalEffort);
  expect(actual.costOfLapsing, expected.costOfLapsing);
  expect(actual.dependency, expected.dependency);
  expect(actual.expectedChanges, expected.expectedChanges);
  expect(actual.notes, expected.notes);
  expect(actual.reminders, expected.reminders);
  expect(actual.attachmentBytes, expected.attachmentBytes);
  expect(actual.createdAt, expected.createdAt);
  expect(actual.updatedAt, expected.updatedAt);
  expect(actual.schemaId, expected.schemaId);
  expect(actual.countryCode, expected.countryCode);
  expect(actual.dynamicFields, expected.dynamicFields);
  expect(actual.renewalHistory, hasLength(expected.renewalHistory.length));
  for (var index = 0; index < expected.renewalHistory.length; index++) {
    final loaded = actual.renewalHistory[index];
    final original = expected.renewalHistory[index];
    expect(loaded.id, original.id);
    expect(loaded.renewedOn, original.renewedOn);
    expect(loaded.previousExpiryDate, original.previousExpiryDate);
    expect(loaded.newExpiryDate, original.newExpiryDate);
    expect(loaded.note, original.note);
  }
}

void expectSubscription(
  RegistrySubscription actual,
  RegistrySubscription expected,
) {
  expect(actual.id, expected.id);
  expect(actual.createdAt, expected.createdAt);
  expect(actual.updatedAt, expected.updatedAt);
  expect(actual.serviceName, expected.serviceName);
  expect(actual.planName, expected.planName);
  expect(actual.category, expected.category);
  expect(actual.amount, expected.amount);
  expect(actual.billingCycle, expected.billingCycle);
  expect(actual.nextPaymentDate, expected.nextPaymentDate);
  expect(actual.decideByDate, expected.decideByDate);
  expect(actual.autoRenew, expected.autoRenew);
  expect(actual.lifecycle, expected.lifecycle);
  expect(actual.impact, expected.impact);
  expect(actual.reminders, expected.reminders);
  expect(actual.notes, expected.notes);
}
