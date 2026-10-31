import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/registry_archive.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/presentation/add_document_controller.dart';
import 'package:the_registry/app/launch_config.dart';
import 'package:the_registry/features/ads/ads_config.dart';
import 'package:the_registry/features/entitlements/entitlement_policy.dart';
import 'package:the_registry/features/entitlements/entitlement_service.dart';
import 'package:the_registry/features/entitlements/local_pro_entitlement.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_controller.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/phase2_fakes.dart';
import 'support/sample_document.dart';
import 'support/sample_subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('free plan blocks only net-new records past the commercial limits', () {
    expect(
      EntitlementPolicy.admitDocuments(
        plan: RegistryPlan.free,
        currentCount: 10,
        additional: 1,
      ).denial,
      EntitlementDenialKind.documentLimit,
    );
    expect(
      EntitlementPolicy.admitDocuments(
        plan: RegistryPlan.free,
        currentCount: 9,
        additional: 1,
      ).allowed,
      isTrue,
    );
    expect(
      EntitlementPolicy.admitSubscriptions(
        plan: RegistryPlan.free,
        currentCount: 5,
        additional: 1,
      ).denial,
      EntitlementDenialKind.subscriptionLimit,
    );
    expect(
      EntitlementPolicy.admitSubscriptions(
        plan: RegistryPlan.free,
        currentCount: 4,
        additional: 2,
      ).allowed,
      isFalse,
    );
    expect(
      EntitlementPolicy.admitDocuments(
        plan: RegistryPlan.localPro,
        currentCount: 10,
        additional: 1,
      ).allowed,
      isTrue,
    );
    expect(EntitlementPolicy.existingRecordAccess().allowed, isTrue);
    expect(
      EntitlementPolicy.technicalBackupDocumentCap,
      BackupLimits.maxDocuments,
    );
    expect(
      EntitlementPolicy.technicalBackupSubscriptionCap,
      BackupLimits.maxSubscriptions,
    );
    expect(EntitlementPolicy.technicalReminderCap, 64);
  });

  test(
    'restore keeps records above the free limits and edits keep the id',
    () async {
      final documents = InMemoryDocumentRepository();
      final subscriptions = InMemorySubscriptionRepository();
      final archive = MemoryRegistryArchive(
        documentsRepository: documents,
        subscriptionsRepository: subscriptions,
      );
      await archive.replaceAll(
        documents: [
          for (var index = 0; index < 11; index++)
            sampleDocument(id: 'doc_$index', name: 'Doc $index'),
        ],
        subscriptions: [
          for (var index = 0; index < 6; index++)
            sampleSubscription(id: 'sub_$index', serviceName: 'Sub $index'),
        ],
        cancel: BackupCancelToken(),
      );
      expect(documents.documents, hasLength(11));
      expect(subscriptions.subscriptions, hasLength(6));

      final source = LocalProEntitlement.disabled();
      final writes = RegistryWrites(
        documents: documents,
        subscriptions: subscriptions,
        entitlements: EntitlementService(
          documents: documents,
          subscriptions: subscriptions,
          source: source,
        ),
      );
      await expectLater(
        writes.createDocument(sampleDocument(id: 'extra-doc')),
        throwsA(isA<EntitlementDenied>()),
      );
      await expectLater(
        writes.createSubscription(sampleSubscription(id: 'extra-sub')),
        throwsA(isA<EntitlementDenied>()),
      );
      expect(documents.documents, hasLength(11));
      expect(subscriptions.subscriptions, hasLength(6));

      expect(
        await documents.update(sampleDocument(id: 'doc_0', name: 'Edited')),
        isTrue,
      );
      expect(documents.documents, hasLength(11));
      expect(documents.findById('doc_0')?.name, 'Edited');
      expect(
        documents.documents.where((item) => item.id == 'doc_0'),
        hasLength(1),
      );
    },
  );

  test('creating an existing id does not insert a duplicate', () async {
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await documents.save(sampleDocument());
    await subscriptions.save(sampleSubscription());
    final writes = RegistryWrites(
      documents: documents,
      subscriptions: subscriptions,
      entitlements: EntitlementService(
        documents: documents,
        subscriptions: subscriptions,
        source: LocalProEntitlement.disabled(),
      ),
    );
    await expectLater(
      writes.createDocument(sampleDocument(name: 'Copy')),
      throwsA(isA<DuplicateRecordId>()),
    );
    await expectLater(
      writes.createSubscription(sampleSubscription(serviceName: 'Copy')),
      throwsA(isA<DuplicateRecordId>()),
    );
    expect(documents.documents, hasLength(1));
    expect(documents.documents.single.name, 'Family passport');
    expect(subscriptions.subscriptions, hasLength(1));
  });

  test('edit forms update the same id and do not call create', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final documents = AddDocumentController()..loadDocument(sampleDocument());
    var documentCreates = 0;
    String? documentId;
    final documentSaved = await documents.submit(
      l10n: l10n,
      save: (_) async => documentCreates += 1,
      update: (document) async {
        documentId = document.id;
        return true;
      },
    );
    expect(documentSaved, isTrue);
    expect(documentCreates, 0);
    expect(documentId, 'doc_1');

    final subscriptions = AddSubscriptionController()
      ..loadSubscription(sampleSubscription());
    var subscriptionCreates = 0;
    String? subscriptionId;
    final subscriptionSaved = await subscriptions.submit(
      l10n: l10n,
      save: (_) async => subscriptionCreates += 1,
      update: (subscription) async {
        subscriptionId = subscription.id;
        return true;
      },
    );
    expect(subscriptionSaved, isTrue);
    expect(subscriptionCreates, 0);
    expect(subscriptionId, 'sub_1');
  });

  test('Local Pro lifts both limits and a lost entitlement blocks only new '
      'records', () async {
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    for (var index = 0; index < EntitlementPolicy.freeDocumentLimit; index++) {
      await documents.save(sampleDocument(id: 'doc_$index'));
    }
    for (
      var index = 0;
      index < EntitlementPolicy.freeSubscriptionLimit;
      index++
    ) {
      await subscriptions.save(sampleSubscription(id: 'sub_$index'));
    }
    final plan = FakePlanSource();
    final writes = RegistryWrites(
      documents: documents,
      subscriptions: subscriptions,
      entitlements: EntitlementService(
        documents: documents,
        subscriptions: subscriptions,
        source: plan,
      ),
    );
    await expectLater(
      writes.createDocument(sampleDocument(id: 'doc_free_extra')),
      throwsA(
        isA<EntitlementDenied>().having(
          (error) => error.decision.denial,
          'denial',
          EntitlementDenialKind.documentLimit,
        ),
      ),
    );
    await expectLater(
      writes.createSubscription(sampleSubscription(id: 'sub_free_extra')),
      throwsA(
        isA<EntitlementDenied>().having(
          (error) => error.decision.denial,
          'denial',
          EntitlementDenialKind.subscriptionLimit,
        ),
      ),
    );

    plan.set(plan: RegistryPlan.localPro);
    await writes.createDocument(sampleDocument(id: 'doc_pro_1'));
    await writes.createDocument(sampleDocument(id: 'doc_pro_2'));
    await writes.createSubscription(sampleSubscription(id: 'sub_pro_1'));
    expect(documents.documents, hasLength(12));
    expect(subscriptions.subscriptions, hasLength(6));

    // Refund or revocation: the store no longer reports Local Pro.
    plan.set(plan: RegistryPlan.free);
    await expectLater(
      writes.createDocument(sampleDocument(id: 'doc_after_refund')),
      throwsA(isA<EntitlementDenied>()),
    );
    expect(
      await documents.update(sampleDocument(id: 'doc_pro_1', name: 'Kept')),
      isTrue,
    );
    expect(documents.findById('doc_pro_1')?.name, 'Kept');
    expect(documents.documents, hasLength(12));

    // Back below the Free limit, creating works again.
    for (final id in ['doc_pro_1', 'doc_pro_2', 'doc_0']) {
      await documents.delete(id);
    }
    await writes.createDocument(sampleDocument(id: 'doc_free_again'));
    expect(documents.documents, hasLength(10));
  });

  test('the launch build ships with purchases off and ads off', () {
    expect(LaunchConfig.purchasesEnabled, isFalse);
    expect(LaunchConfig.adsEnabled, isFalse);
    expect(LaunchConfig.localProProductId, 'local_pro');
    expect(AdsConfig.fromEnvironment().enabled, isFalse);
    final localPro = LocalProEntitlement.disabled();
    expect(localPro.plan, RegistryPlan.free);
    expect(localPro.status, LocalProStatus.disabled);
    expect(localPro.restoreAvailable, isFalse);
  });
}
