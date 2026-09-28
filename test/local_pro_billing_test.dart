// Store and server boundaries in this file are fakes.
// They are not Play Console, App Store Connect, or live purchase verification.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/backup_payload.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/entitlements/billing_configuration.dart';
import 'package:the_registry/features/entitlements/billing_records.dart';
import 'package:the_registry/features/entitlements/billing_runtime.dart';
import 'package:the_registry/features/entitlements/entitlement_policy.dart';
import 'package:the_registry/features/entitlements/entitlement_service.dart';
import 'package:the_registry/features/entitlements/grant_codec.dart';
import 'package:the_registry/features/entitlements/in_app_purchase_store.dart';
import 'package:the_registry/features/entitlements/platform_billing_coordinator.dart';
import 'package:the_registry/features/entitlements/presentation/local_pro_screen.dart';
import 'package:the_registry/features/entitlements/production_billing.dart';
import 'package:the_registry/features/entitlements/purchase_service.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/features/entitlements/verified_entitlement.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';

import 'support/fake_onboarding_repository.dart';

const _install = '11111111-1111-4111-8111-111111111111';

void main() {
  late SimpleKeyPair keyPair;
  late String publicKey;

  setUpAll(() async {
    final algorithm = Ed25519();
    keyPair = await algorithm.newKeyPair();
    final extracted = await keyPair.extractPublicKey();
    publicKey = base64Encode(extracted.bytes);
  });

  BillingRuntime readyRuntime() {
    return BillingRuntime(
      storeVerificationConfigured: true,
      verificationBaseUrl: 'https://billing.test',
      grantPublicKeyBase64: publicKey,
      environment: 'sandbox',
    );
  }

  Future<String> sign(String canonical) async {
    final signature = await Ed25519().sign(
      utf8.encode(canonical),
      keyPair: keyPair,
    );
    return base64Encode(signature.bytes);
  }

  String grant({
    String status = 'active',
    String environment = 'sandbox',
    String productId = 'local_pro',
    String revalidateAfter = '2026-09-28T12:00:00.000Z',
  }) {
    return jsonEncode({
      'environment': environment,
      'installationId': _install,
      'platform': 'google',
      'productId': productId,
      'purchaseKey': 'GPA.1111',
      'revalidateAfter': revalidateAfter,
      'status': status,
      'v': 1,
      'verifiedAt': '2026-09-27T12:00:00.000Z',
    });
  }

  test('default billing stays closed and does not invent a price', () async {
    expect(BillingConfiguration.storeVerificationConfigured, isFalse);
    expect(const BillingRuntime().isReady, isFalse);
    expect(await const ProductionStoreProductSource().loadLocalPro(), isNull);
    final attempt = await const ProductionPurchaseService().purchaseLocalPro();
    expect(attempt.outcome, PurchaseFlowOutcome.unavailable);
    expect(attempt.proof, isNull);
    expect(await openProductionBilling(), isNull);
    final source = ProductionVerifiedEntitlementSource();
    source.applyVerified(
      const VerifiedEntitlementProof(
        productId: BillingConfiguration.localProProductId,
        accepted: true,
      ),
    );
    expect(source.plan, RegistryPlan.free);
  });

  test('a signed grant round-trips and a bad signature does not', () async {
    final canonical = grant();
    final signature = await sign(canonical);
    final runtime = readyRuntime();
    final proof = await proofFromSignedGrant(
      runtime: runtime,
      installationId: _install,
      canonical: canonical,
      signatureBase64: signature,
    );
    expect(proof?.accepted, isTrue);
    expect(
      await proofFromSignedGrant(
        runtime: runtime,
        installationId: _install,
        canonical: canonical,
        signatureBase64: base64Encode(List<int>.filled(64, 3)),
      ),
      isNull,
    );
  });

  test('purchase, pending, cancel, duplicate, restore, and mismatch', () async {
    final canonical = grant();
    final signature = await sign(canonical);
    final store = _FakeStore(
      const StoreListing(
        productId: 'local_pro',
        localizedPrice: 'DZD 1,200.00',
      ),
    );
    final verifier = _FakeVerifier(
      BillingServerResponse(
        statusCode: 200,
        body: {
          'canonical': canonical,
          'signature': signature,
          'recoveryCode': 'ABCD-EFGH-JKLM-NPQR',
        },
      ),
    );
    final cache = MemoryEntitlementCache();
    final pending = MemoryPendingPurchaseStore();
    final coordinator = _coordinator(
      runtime: readyRuntime(),
      store: store,
      verifier: verifier,
      cache: cache,
      pending: pending,
    );

    store.next = [_update(StorePurchaseStatus.purchased)];
    final purchased = await coordinator.purchaseLocalPro();
    expect(purchased.outcome, PurchaseFlowOutcome.verified);
    expect(purchased.proof?.accepted, isTrue);
    expect(purchased.recoveryCode, 'ABCD-EFGH-JKLM-NPQR');
    expect(verifier.calls, 1);
    expect(verifier.bodies.single['purchaseToken'], 'token-1');
    expect(verifier.bodies.single.containsKey('premium'), isFalse);
    expect(store.completed, ['GPA.1111']);
    expect(cache.writes, 1);

    store.completed.clear();
    store.next = [_update(StorePurchaseStatus.pending)];
    final pendingAttempt = await coordinator.purchaseLocalPro();
    expect(pendingAttempt.outcome, PurchaseFlowOutcome.pending);
    expect(store.completed, isEmpty);
    expect(cache.writes, 1);

    store.completed.clear();
    store.next = [_update(StorePurchaseStatus.canceled)];
    final cancelled = await coordinator.purchaseLocalPro();
    expect(cancelled.outcome, PurchaseFlowOutcome.cancelled);
    expect(verifier.calls, 1);
    expect(store.completed, ['GPA.1111']);

    store.completed.clear();
    store.next = [
      _update(
        StorePurchaseStatus.error,
        errorCode: 'userCanceled',
        purchaseKey: 'GPA.cancel',
      ),
    ];
    final errorCancel = await coordinator.purchaseLocalPro();
    expect(errorCancel.outcome, PurchaseFlowOutcome.cancelled);
    expect(verifier.calls, 1);
    expect(store.completed, ['GPA.cancel']);

    verifier.response = const BillingServerResponse(
      statusCode: 409,
      body: {'error': 'binding_mismatch'},
    );
    store.completed.clear();
    store.next = [_update(StorePurchaseStatus.restored)];
    final mismatch = await coordinator.restoreLocalPro(recoveryCode: 'CODE');
    expect(mismatch.outcome, PurchaseFlowOutcome.bindingMismatch);
    expect(verifier.paths.last, '/v1/purchases/restore');
    expect(verifier.bodies.last['recoveryCode'], 'CODE');
    expect(cache.writes, 1);
    expect(store.completed, isEmpty);
    expect(
      (await pending.read())
          .singleWhere((record) => record.purchaseKey == 'GPA.1111')
          .stage,
      'mismatch',
    );
  });

  test('a second callback for the same purchase is not verified again', () async {
    final canonical = grant();
    final signature = await sign(canonical);
    final store = _FakeStore(
      const StoreListing(
        productId: 'local_pro',
        localizedPrice: 'DZD 1,200.00',
      ),
    );
    final gate = Completer<void>();
    final verifier = _FakeVerifier(
      BillingServerResponse(
        statusCode: 200,
        body: {'canonical': canonical, 'signature': signature},
      ),
    )..gate = gate;
    final coordinator = _coordinator(
      runtime: readyRuntime(),
      store: store,
      verifier: verifier,
      cache: MemoryEntitlementCache(),
      pending: MemoryPendingPurchaseStore(),
    );
    store.burst = 2;
    store.next = [_update(StorePurchaseStatus.purchased)];
    final pendingResult = coordinator.purchaseLocalPro();
    await Future<void>.delayed(Duration.zero);
    expect(verifier.calls, 1);
    gate.complete();
    expect(
      (await pendingResult).outcome,
      PurchaseFlowOutcome.verified,
    );
    expect(verifier.calls, 1);
    await coordinator.dispose();
  });

  test('restart retries completion without a second verification', () async {
    final canonical = grant();
    final signature = await sign(canonical);
    final store = _FakeStore(
      const StoreListing(
        productId: 'local_pro',
        localizedPrice: 'DZD 1,200.00',
      ),
    );
    final verifier = _FakeVerifier(
      BillingServerResponse(
        statusCode: 200,
        body: {'canonical': canonical, 'signature': signature},
      ),
    );
    final cache = MemoryEntitlementCache();
    final pending = MemoryPendingPurchaseStore();
    store.completeThrows = true;
    store.next = [_update(StorePurchaseStatus.purchased)];
    final first = _coordinator(
      runtime: readyRuntime(),
      store: store,
      verifier: verifier,
      cache: cache,
      pending: pending,
    );
    expect(
      (await first.purchaseLocalPro()).outcome,
      PurchaseFlowOutcome.verified,
    );
    expect(store.completed, isEmpty);
    expect(verifier.calls, 1);
    await first.dispose();

    store.completeThrows = false;
    store.next = [_update(StorePurchaseStatus.purchased)];
    final restarted = _coordinator(
      runtime: readyRuntime(),
      store: store,
      verifier: verifier,
      cache: cache,
      pending: pending,
    );
    expect(
      (await restarted.purchaseLocalPro()).outcome,
      PurchaseFlowOutcome.verified,
    );
    expect(verifier.calls, 1);
    expect(store.completed, ['GPA.1111']);
  });

  test(
    'invalid proof, wrong environment, and a dead server leave the cache',
    () async {
      final store = _FakeStore(
        const StoreListing(
          productId: 'local_pro',
          localizedPrice: 'DZD 1,200.00',
        ),
      );
      final cache = MemoryEntitlementCache();
      final kept = grant();
      cache.grant = CachedGrant(canonical: kept, signature: await sign(kept));
      final verifier = _FakeVerifier(
        const BillingServerResponse(
          statusCode: 503,
          body: {'error': 'transient'},
        ),
      );
      final coordinator = _coordinator(
        runtime: readyRuntime(),
        store: store,
        verifier: verifier,
        cache: cache,
        pending: MemoryPendingPurchaseStore(),
      );
      store.next = [_update(StorePurchaseStatus.purchased)];
      final offline = await coordinator.purchaseLocalPro();
      expect(offline.outcome, PurchaseFlowOutcome.unchanged);
      expect(cache.grant?.canonical, kept);
      expect(cache.writes, 0);
      expect(store.completed, isEmpty);

      final wrong = grant(environment: 'production');
      verifier.response = BillingServerResponse(
        statusCode: 200,
        body: {'canonical': wrong, 'signature': await sign(wrong)},
      );
      store.next = [
        _update(StorePurchaseStatus.purchased, purchaseKey: 'GPA.2222'),
      ];
      final rejected = await coordinator.purchaseLocalPro();
      expect(rejected.outcome, PurchaseFlowOutcome.failed);
      expect(cache.grant?.canonical, kept);

      store.next = [
        _update(
          StorePurchaseStatus.purchased,
          productId: 'other_product',
          purchaseKey: 'GPA.3333',
        ),
      ];
      final ignored = await _coordinator(
        runtime: readyRuntime(),
        store: store,
        verifier: verifier,
        cache: cache,
        pending: MemoryPendingPurchaseStore(),
        updateTimeout: const Duration(milliseconds: 20),
      ).purchaseLocalPro();
      expect(ignored.outcome, PurchaseFlowOutcome.unchanged);
      expect(cache.grant?.canonical, kept);
    },
  );

  test(
    'refund replaces the cache and blocks only new over-limit records',
    () async {
      final active = grant();
      final inactive = grant(status: 'inactive');
      final store = _FakeStore(
        const StoreListing(
          productId: 'local_pro',
          localizedPrice: 'DZD 1,200.00',
        ),
      );
      final cache = MemoryEntitlementCache();
      final verifier = _FakeVerifier(
        BillingServerResponse(
          statusCode: 200,
          body: {'canonical': inactive, 'signature': await sign(inactive)},
        ),
      );
      cache.grant = CachedGrant(
        canonical: active,
        signature: await sign(active),
      );
      final coordinator = _coordinator(
        runtime: readyRuntime(),
        store: store,
        verifier: verifier,
        cache: cache,
        pending: MemoryPendingPurchaseStore(),
        clock: FixedClock(DateTime.utc(2026, 9, 29)),
      );
      store.next = [
        _update(StorePurchaseStatus.purchased, purchaseKey: 'GPA.4444'),
      ];
      final revoked = await coordinator.purchaseLocalPro();
      expect(revoked.outcome, PurchaseFlowOutcome.revoked);
      expect(cache.grant?.canonical, inactive);

      final source = ProductionVerifiedEntitlementSource(
        storeVerificationConfigured: true,
      );
      source.applyVerified(revoked.proof);
      expect(source.plan, RegistryPlan.free);
      final documents = InMemoryDocumentRepository();
      for (
        var index = 0;
        index < EntitlementPolicy.freeDocumentLimit;
        index++
      ) {
        await documents.save(_document('doc_$index'));
      }
      expect(
        await documents.update(
          _document('doc_0').copyWith(name: 'Edited passport'),
        ),
        isTrue,
      );
      expect(documents.documents.length, EntitlementPolicy.freeDocumentLimit);
      expect(documents.findById('doc_0')?.name, 'Edited passport');
      final writes = RegistryWrites(
        documents: documents,
        subscriptions: InMemorySubscriptionRepository(),
        entitlements: EntitlementService(
          documents: documents,
          subscriptions: InMemorySubscriptionRepository(),
          source: source,
        ),
      );
      expect(
        () => writes.createDocument(_document('doc_new')),
        throwsA(isA<EntitlementDenied>()),
      );
    },
  );

  test('revalidation failure does not replace a cached grant', () async {
    final canonical = grant(revalidateAfter: '2026-09-27T00:00:00.000Z');
    final cache = MemoryEntitlementCache()
      ..grant = CachedGrant(
        canonical: canonical,
        signature: await sign(canonical),
      );
    final verifier = _FakeVerifier(const BillingServerResponse.unreachable());
    final coordinator = _coordinator(
      runtime: readyRuntime(),
      store: _FakeStore(
        const StoreListing(
          productId: 'local_pro',
          localizedPrice: 'DZD 1,200.00',
        ),
      ),
      verifier: verifier,
      cache: cache,
      pending: MemoryPendingPurchaseStore(),
      clock: FixedClock(DateTime.utc(2026, 9, 28)),
    );
    final proof = await coordinator.warmUp();
    expect(proof?.accepted, isTrue);
    expect(verifier.paths, ['/v1/entitlements/revalidate']);
    expect(cache.grant?.canonical, canonical);
    expect(cache.writes, 0);
  });

  test('a rate limit does not acknowledge Play or replace the cache', () async {
    final kept = grant();
    final cache = MemoryEntitlementCache()
      ..grant = CachedGrant(canonical: kept, signature: await sign(kept));
    final pending = MemoryPendingPurchaseStore();
    final store = _FakeStore(
      const StoreListing(
        productId: 'local_pro',
        localizedPrice: 'DZD 1,200.00',
      ),
    );
    final verifier = _FakeVerifier(
      const BillingServerResponse(statusCode: 429, body: {'error': 'rate_limited'}),
    );
    final coordinator = _coordinator(
      runtime: readyRuntime(),
      store: store,
      verifier: verifier,
      cache: cache,
      pending: pending,
    );
    store.next = [_update(StorePurchaseStatus.purchased)];
    final attempt = await coordinator.purchaseLocalPro();
    expect(attempt.outcome, PurchaseFlowOutcome.unchanged);
    expect(store.completed, isEmpty);
    expect(cache.writes, 0);
    expect(cache.grant?.canonical, kept);
    expect((await pending.read()).single.stage, 'needsVerification');
    expect((await pending.read()).single.payload, 'token-1');
  });

  test(
    'restart verifies a purchase the store does not deliver again',
    () async {
      final canonical = grant();
      final signature = await sign(canonical);
      final pending = MemoryPendingPurchaseStore();
      await pending.write([
        const PendingPurchaseRecord(
          purchaseKey: 'GPA.1111',
          productId: 'local_pro',
          platform: 'google',
          payload: 'token-1',
          stage: 'needsVerification',
        ),
      ]);
      final cache = MemoryEntitlementCache();
      final store = _FakeStore(
        const StoreListing(
          productId: 'local_pro',
          localizedPrice: 'DZD 1,200.00',
        ),
      )..completeThrows = true;
      final verifier = _FakeVerifier(
        BillingServerResponse(
          statusCode: 200,
          body: {'canonical': canonical, 'signature': signature},
        ),
      );
      final coordinator = _coordinator(
        runtime: readyRuntime(),
        store: store,
        verifier: verifier,
        cache: cache,
        pending: pending,
      );
      final proof = await coordinator.warmUp();
      expect(proof?.accepted, isTrue);
      expect(verifier.paths, ['/v1/purchases/verify']);
      expect(verifier.bodies.single['purchaseToken'], 'token-1');
      expect(verifier.bodies.single.containsKey('recoveryCode'), isFalse);
      expect(cache.writes, 1);
      expect(store.completed, isEmpty);
      expect((await pending.read()).single.stage, 'verified');
    },
  );

  test('Apple mismatch finishes the queue and Play mismatch does not', () async {
    final store = _FakeStore(
      const StoreListing(
        productId: 'local_pro',
        localizedPrice: 'DZD 1,200.00',
      ),
    );
    final verifier = _FakeVerifier(
      const BillingServerResponse(
        statusCode: 409,
        body: {'result': 'binding_mismatch'},
      ),
    );
    final coordinator = _coordinator(
      runtime: readyRuntime(),
      store: store,
      verifier: verifier,
      cache: MemoryEntitlementCache(),
      pending: MemoryPendingPurchaseStore(),
    );
    store.next = [
      _update(StorePurchaseStatus.restored, platform: 'apple', purchaseKey: '1000001'),
    ];
    final mismatch = await coordinator.restoreLocalPro();
    expect(mismatch.outcome, PurchaseFlowOutcome.bindingMismatch);
    expect(store.completed, ['1000001']);
    expect(verifier.bodies.single['signedTransaction'], 'header.payload.sig');
    expect(verifier.bodies.single.containsKey('purchaseToken'), isFalse);
  });

  test('backup bytes do not carry entitlement fields', () {
    final bytes = RegistryBackupPayload.encode(
      BackupSnapshot(
        documents: [
          RegistryDocument(
            id: 'doc_1',
            name: 'Passport',
            category: DocumentCategory.passport,
            expiryDate: DateTime.utc(2030, 1, 1),
            impact: DocumentImpact.high,
            createdAt: DateTime.utc(2026, 9, 27),
          ),
        ],
        subscriptions: const [],
      ),
    );
    final text = utf8.decode(bytes, allowMalformed: true);
    expect(RegistryBackupPayload.version, 1);
    expect(text.contains('installationId'), isFalse);
    expect(text.contains('purchaseToken'), isFalse);
    expect(text.contains('recoveryCode'), isFalse);
    expect(text.contains('signedTransaction'), isFalse);
  });

  test('installation id stays outside the registry database file', () async {
    final directory = await Directory.systemTemp.createTemp('registry-billing');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileInstallationIdStore(
      File('${directory.path}/billing/installation_id'),
    );
    final created = await store.getOrCreate();
    expect(created, await store.getOrCreate());
    expect(created.contains('registry.db'), isFalse);
    expect(
      File('${directory.path}/billing/installation_id').existsSync(),
      isTrue,
    );
  });

  test('Play adapter reads the purchase token and never consumes', () async {
    final plugin = _FakePlugin();
    final store = InAppPurchaseLocalProStore(plugin: plugin);
    final listing = await store.loadProduct('local_pro');
    expect(listing?.localizedPrice, 'DZD 1,200.00');

    final seen = <StorePurchaseUpdate>[];
    final subscription = store.updates.listen(seen.addAll);
    await store.buyNonConsumable(
      productId: 'local_pro',
      applicationUserName: _install,
    );
    plugin.emit([
      GooglePlayPurchaseDetails(
        purchaseID: 'GPA.1111',
        productID: 'local_pro',
        verificationData: PurchaseVerificationData(
          localVerificationData: '{}',
          serverVerificationData: 'not-the-token',
          source: 'google_play',
        ),
        transactionDate: '1',
        billingClientPurchase: const PurchaseWrapper(
          orderId: 'GPA.1111',
          packageName: 'com.registry.app',
          purchaseTime: 1,
          purchaseToken: 'play-token',
          signature: 'sig',
          products: ['local_pro'],
          isAutoRenewing: false,
          originalJson: '{}',
          isAcknowledged: false,
          purchaseState: PurchaseStateWrapper.purchased,
        ),
        status: PurchaseStatus.purchased,
      ),
      PurchaseDetails(
        purchaseID: 'apple-1',
        productID: 'local_pro',
        verificationData: PurchaseVerificationData(
          localVerificationData: '{}',
          serverVerificationData: 'header.payload.signature',
          source: 'app_store',
        ),
        transactionDate: '1',
        status: PurchaseStatus.restored,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(seen[0].payload, 'play-token');
    expect(seen[0].platform, 'google');
    expect(seen[1].payload, 'header.payload.signature');
    expect(seen[1].platform, 'apple');
    expect(plugin.buyNonConsumableCalls, 1);
    expect(plugin.methods, ['query', 'buyNonConsumable']);
    await store.complete('GPA.1111');
    expect(plugin.completed.single.purchaseID, 'GPA.1111');
    await subscription.cancel();

    plugin.price = '   ';
    expect(await store.loadProduct('local_pro'), isNull);
  });

  testWidgets('opening and dismissing Local Pro keeps the document draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
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
    final name = find.byKey(const ValueKey<String>('field-name')).first;
    await Scrollable.ensureVisible(
      tester.element(name),
      alignment: 0.35,
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.enterText(name, 'Passport draft');
    final navigator = Navigator.of(
      tester.element(find.byType(AddDocumentScreen)),
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const LocalProScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LocalProScreen), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(AddDocumentScreen), findsOneWidget);
    expect(find.text('Passport draft'), findsOneWidget);
  });
}

PlatformBillingCoordinator _coordinator({
  required BillingRuntime runtime,
  required _FakeStore store,
  required _FakeVerifier verifier,
  required MemoryEntitlementCache cache,
  required MemoryPendingPurchaseStore pending,
  Clock? clock,
  Duration updateTimeout = const Duration(seconds: 2),
}) {
  return PlatformBillingCoordinator(
    runtime: runtime,
    store: store,
    verifier: verifier,
    installationIds: MemoryInstallationIdStore(_install),
    cache: cache,
    pending: pending,
    clock: clock ?? FixedClock(DateTime.utc(2026, 9, 27, 12)),
    updateTimeout: updateTimeout,
  );
}

StorePurchaseUpdate _update(
  StorePurchaseStatus status, {
  String productId = 'local_pro',
  String purchaseKey = 'GPA.1111',
  String platform = 'google',
  String? errorCode,
}) {
  return StorePurchaseUpdate(
    productId: productId,
    purchaseKey: purchaseKey,
    status: status,
    platform: platform,
    payload: platform == 'apple' ? 'header.payload.sig' : 'token-1',
    pendingComplete: true,
    errorCode: errorCode,
  );
}

class _FakeStore implements LocalProStore {
  _FakeStore(this.listing);

  final StoreListing? listing;
  final _updates = StreamController<List<StorePurchaseUpdate>>.broadcast();
  final completed = <String>[];
  List<StorePurchaseUpdate> next = const [];
  var completeThrows = false;
  var burst = 1;

  @override
  Future<StoreListing?> loadProduct(String productId) async => listing;

  @override
  Future<bool> buyNonConsumable({
    required String productId,
    required String applicationUserName,
  }) async {
    for (var index = 0; index < burst; index++) {
      if (next.isNotEmpty) {
        _updates.add(next);
      }
    }
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (next.isNotEmpty) {
      _updates.add(next);
    }
  }

  @override
  Stream<List<StorePurchaseUpdate>> get updates => _updates.stream;

  @override
  Future<void> complete(String purchaseKey) async {
    if (completeThrows) {
      throw StateError('complete');
    }
    completed.add(purchaseKey);
  }
}

class _FakeVerifier implements BillingVerificationClient {
  _FakeVerifier(this.response);

  BillingServerResponse response;
  final paths = <String>[];
  final bodies = <Map<String, Object?>>[];
  var calls = 0;
  Completer<void>? gate;

  @override
  Future<BillingServerResponse> post(
    String path,
    Map<String, Object?> body,
  ) async {
    calls += 1;
    paths.add(path);
    bodies.add(body);
    final gate = this.gate;
    if (gate != null) {
      await gate.future;
    }
    return response;
  }
}

class _FakePlugin implements BillingPlugin {
  final _purchases = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  final methods = <String>[];
  var buyNonConsumableCalls = 0;
  String price = 'DZD 1,200.00';

  void emit(List<PurchaseDetails> purchases) {
    _purchases.add(purchases);
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    methods.add('query');
    return ProductDetailsResponse(
      notFoundIDs: const [],
      productDetails: [
        ProductDetails(
          id: 'local_pro',
          title: 'Local Pro',
          description: 'Local Pro',
          price: price,
          rawPrice: 1200,
          currencyCode: 'DZD',
        ),
      ],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    methods.add('buyNonConsumable');
    buyNonConsumableCalls += 1;
    expect(purchaseParam.applicationUserName, _install);
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchases.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }
}

RegistryDocument _document(String id) {
  return RegistryDocument(
    id: id,
    name: 'Passport',
    category: DocumentCategory.passport,
    expiryDate: DateTime.utc(2030, 1, 1),
    impact: DocumentImpact.high,
    createdAt: DateTime.utc(2026, 9, 27),
  );
}
