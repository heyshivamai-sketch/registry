import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/backup/backup_crypto.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/backup_payload.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

/// Synthetic Phase 2A device fixtures. Not a bank export.
///
/// Run with `flutter test tool/phase2a_qa_fixtures.dart`.
/// Password for every `.rgry` file: `phase2a-qa-password`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'write synthetic phase 2a qa files',
    () async {
      const password = 'phase2a-qa-password';
      final out = Directory('screenshots/phase2a_local_pro/fixtures');
      await out.create(recursive: true);

      await _writeBackup(
        file: File('${out.path}/qa_lock_marker.rgry'),
        password: password,
        documents: [
          _document(
            id: 'qa-lock-marker',
            name: 'QA Lock Marker',
            index: 1,
            withAttachment: true,
            withHistory: true,
          ),
        ],
        subscriptions: const [],
      );

      await _writeBackup(
        file: File('${out.path}/qa_exact_free_limit.rgry'),
        password: password,
        documents: [
          for (var index = 1; index <= 10; index++)
            _document(
              id: 'qa-exact-doc-${index.toString().padLeft(2, '0')}',
              name: 'QA Exact Doc ${index.toString().padLeft(2, '0')}',
              index: index,
              withAttachment: true,
              withHistory: true,
            ),
        ],
        subscriptions: [
          for (var index = 1; index <= 5; index++)
            _subscription(
              id: 'qa-exact-sub-${index.toString().padLeft(2, '0')}',
              name: 'QA Exact Plan ${index.toString().padLeft(2, '0')}',
              index: index,
            ),
        ],
      );

      await _writeBackup(
        file: File('${out.path}/qa_above_free_limit.rgry'),
        password: password,
        documents: [
          for (var index = 1; index <= 12; index++)
            _document(
              id: 'qa-above-doc-${index.toString().padLeft(2, '0')}',
              name: 'QA Above Doc ${index.toString().padLeft(2, '0')}',
              index: 100 + index,
              withAttachment: true,
              withHistory: true,
            ),
        ],
        subscriptions: [
          for (var index = 1; index <= 7; index++)
            _subscription(
              id: 'qa-above-sub-${index.toString().padLeft(2, '0')}',
              name: 'QA Above Plan ${index.toString().padLeft(2, '0')}',
              index: index,
            ),
        ],
      );

      File('${out.path}/small_recurring.csv').writeAsStringSync(_smallCsv);
      File('${out.path}/malformed_mixed.csv').writeAsStringSync(_mixedCsv);
      File('${out.path}/over_limit.csv').writeAsStringSync(_overLimitCsv);
      File(
        '${out.path}/invalid.csv',
      ).writeAsStringSync('this is not a charge table\n');
      File('${out.path}/FIXTURES.txt').writeAsStringSync('''
Synthetic Phase 2A QA fixtures. Not a bank statement.
Backup password: phase2a-qa-password
qa_lock_marker.rgry: 1 document, attachment, one renewal.
qa_exact_free_limit.rgry: 10 documents and 5 subscriptions, each document has a unique attachment and one renewal.
qa_above_free_limit.rgry: 12 documents and 7 subscriptions, each document has a unique attachment and one renewal.
CSV files use the documented date,merchant,amount_minor,currency header.
''');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _writeBackup({
  required File file,
  required String password,
  required List<RegistryDocument> documents,
  required List<RegistrySubscription> subscriptions,
}) async {
  final plaintext = RegistryBackupPayload.encode(
    BackupSnapshot(documents: documents, subscriptions: subscriptions),
  );
  final encrypted = await RegistryBackupCrypto.encrypt(
    plaintext: plaintext,
    password: password,
    cancel: BackupCancelToken(),
  );
  await file.writeAsBytes(encrypted, flush: true);
}

RegistryDocument _document({
  required String id,
  required String name,
  required int index,
  required bool withAttachment,
  required bool withHistory,
}) {
  final expiry = DateTime(2027, 6, index.clamp(1, 28));
  return RegistryDocument(
    id: id,
    name: name,
    category: DocumentCategory.other,
    expiryDate: expiry,
    impact: DocumentImpact.medium,
    createdAt: DateTime.utc(2026, 1, 15, 12, index),
    schemaId: DocumentSchemaIds.genericOther,
    notes: 'Synthetic QA fixture $id',
    reminders: const {},
    attachmentBytes: withAttachment ? _attachment(id) : null,
    renewalHistory: withHistory
        ? [
            RenewalHistoryEntry(
              id: '$id-renewal-1',
              renewedOn: DateTime.utc(2026, 1, 20),
              previousExpiryDate: DateTime(2026, 6, index.clamp(1, 28)),
              newExpiryDate: expiry,
              note: 'Synthetic renewal $id',
            ),
          ]
        : const [],
  );
}

RegistrySubscription _subscription({
  required String id,
  required String name,
  required int index,
}) {
  return RegistrySubscription(
    id: id,
    createdAt: DateTime.utc(2026, 1, 15, 12, index),
    serviceName: name,
    category: SubscriptionCategory.other,
    amount: Money(minorUnits: 1000 + index, currencyCode: 'USD'),
    billingCycle: BillingCycle.monthly,
    nextPaymentDate: DateTime(2026, 11, index.clamp(1, 28)),
    autoRenew: true,
    lifecycle: SubscriptionLifecycle.active,
    impact: DocumentImpact.low,
    reminders: const {},
    notes: 'Synthetic QA fixture $id',
  );
}

Uint8List _attachment(String id) {
  return Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature only
    ...id.codeUnits,
    0x51, 0x41, // QA
  ]);
}

const _smallCsv = '''
date,merchant,amount_minor,currency
2026-01-15,QA Synth Stream,1200,USD
2026-02-14,QA Synth Stream,1200,USD
2026-03-16,QA Synth Stream,1200,USD
''';

const _mixedCsv = '''
date,merchant,amount_minor,currency
2026-01-15,QA Synth Stream,1200,USD
2026-02-14,QA Synth Stream,1200,USD
2026-03-16,QA Synth Stream,1200,USD
01/15/2026,QA Ambiguous Date,500,USD
2026-02-31,QA Bad Date,500,USD
2026-04-01,QA Broken Amount,12.50,USD
2026-04-01,QA Bad Currency,500,XYZ
not-a-date,QA Junk,500,USD
2026-01-10,QA Mixed Coin,800,USD
2026-02-10,QA Mixed Coin,800,EUR
2026-03-10,QA Mixed Coin,800,USD
2026-04-10,QA Mixed Coin,800,EUR
''';

const _overLimitCsv = '''
date,merchant,amount_minor,currency
2026-01-01,QA Over Alpha,1000,USD
2026-01-31,QA Over Alpha,1000,USD
2026-01-02,QA Over Beta,1100,USD
2026-02-01,QA Over Beta,1100,USD
2026-01-03,QA Over Gamma,1200,USD
2026-02-02,QA Over Gamma,1200,USD
2026-01-04,QA Over Delta,1300,USD
2026-02-03,QA Over Delta,1300,USD
2026-01-05,QA Over Epsilon,1400,USD
2026-02-04,QA Over Epsilon,1400,USD
2026-01-06,QA Over Zeta,1500,USD
2026-02-05,QA Over Zeta,1500,USD
''';
