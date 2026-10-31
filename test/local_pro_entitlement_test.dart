import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/entitlements/in_app_purchase_store.dart';
import 'package:the_registry/features/entitlements/local_pro_entitlement.dart';
import 'package:the_registry/features/entitlements/local_pro_store.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';

import 'support/phase2_fakes.dart';

// These tests drive LocalProEntitlement through a scripted store boundary.
// They are not Google Play or App Store sandbox acceptance.
void main() {
  late FakeLocalProStore store;
  late MemoryLocalProHintStore hints;
  late MutableClock clock;

  setUp(() {
    store = FakeLocalProStore();
    hints = MemoryLocalProHintStore();
    clock = MutableClock(DateTime.utc(2026, 9, 28, 9));
  });

  tearDown(() async {
    await store.close();
  });

  LocalProEntitlement entitlement({
    Duration purchaseTimeout = const Duration(seconds: 2),
  }) {
    return LocalProEntitlement(
      purchasesEnabled: true,
      store: store,
      hints: hints,
      clock: clock,
      purchaseTimeout: purchaseTimeout,
    );
  }

  group('purchases off', () {
    test('never touches the store and stays Free', () async {
      final localPro = LocalProEntitlement(
        purchasesEnabled: false,
        store: store,
        hints: hints,
      );
      await localPro.start();
      await localPro.onResumed();
      expect(localPro.plan, RegistryPlan.free);
      expect(localPro.status, LocalProStatus.disabled);
      expect(localPro.restoreAvailable, isFalse);
      expect(await localPro.buy(), LocalProActionResult.unavailable);
      expect(await localPro.restore(), LocalProActionResult.unavailable);
      expect(
        (await localPro.loadProduct()).status,
        StoreProductStatus.unavailable,
      );
      expect(store.queryCalls + store.loadCalls + store.buyCalls, 0);
      expect(store.syncCalls, 0);
      expect(localPro.adsMayBeRequested, isTrue);
    });
  });

  group('launch', () {
    test('a store answer of not owned is Free', () async {
      final localPro = entitlement();
      await localPro.start();
      expect(localPro.plan, RegistryPlan.free);
      expect(localPro.status, LocalProStatus.free);
      expect(localPro.adsMayBeRequested, isTrue);
    });

    test('reinstall: an owned store purchase restores Pro on launch', () async {
      store.ownership = StoreOwnership.owned;
      final localPro = entitlement();
      await localPro.start();
      expect(localPro.plan, RegistryPlan.localPro);
      expect(localPro.status, LocalProStatus.active);
      expect(hints.hint.owned, isTrue);
      expect(hints.hint.confirmedAt, clock.now());
    });

    test('no ad may be requested while the store resolves', () async {
      store.queryGate = Completer<void>();
      final localPro = entitlement();
      final started = localPro.start();
      await pumpEventQueue();
      expect(localPro.resolving, isTrue);
      expect(localPro.status, LocalProStatus.checking);
      expect(localPro.plan, RegistryPlan.free);
      expect(localPro.adsMayBeRequested, isFalse);
      store.queryGate!.complete();
      await started;
      expect(localPro.resolving, isFalse);
      expect(localPro.adsMayBeRequested, isTrue);
    });

    test(
      'restart offline keeps Pro from the last store confirmation',
      () async {
        hints.hint = LocalProHint(owned: true, confirmedAt: clock.now());
        store.ownership = StoreOwnership.error;
        final localPro = entitlement();
        await localPro.start();
        expect(localPro.plan, RegistryPlan.localPro);
        expect(localPro.status, LocalProStatus.activeUnconfirmed);
        expect(localPro.problem, StoreProblem.error);
        expect(localPro.adsMayBeRequested, isFalse);
        expect(hints.hint.owned, isTrue);
      },
    );

    test('offline with no earlier confirmation is unknown and Free', () async {
      store.ownership = StoreOwnership.error;
      final localPro = entitlement();
      await localPro.start();
      expect(localPro.plan, RegistryPlan.free);
      expect(localPro.status, LocalProStatus.unknown);
      expect(localPro.revokedThisSession, isFalse);
    });

    test('store unavailable is not treated as a confirmed absence', () async {
      hints.hint = LocalProHint(owned: true, confirmedAt: clock.now());
      store.ownership = StoreOwnership.unavailable;
      final localPro = entitlement();
      await localPro.start();
      expect(localPro.plan, RegistryPlan.localPro);
      expect(localPro.problem, StoreProblem.unavailable);
      expect(localPro.revokedThisSession, isFalse);
    });
  });

  group('purchase', () {
    test('Play PURCHASED is acknowledged once and turns Pro on', () async {
      store.onBuy = (store) {
        store.ownership = StoreOwnership.owned;
        store.emit([
          localProTransaction(
            StoreTransactionStatus.purchased,
            storeConfirmed: true,
          ),
        ]);
      };
      final localPro = entitlement();
      await localPro.start();
      await localPro.loadProduct();
      expect(await localPro.buy(), LocalProActionResult.active);
      expect(localPro.plan, RegistryPlan.localPro);
      expect(store.completed.map((item) => item.purchaseId), ['GPA.0001']);

      store.emit([
        localProTransaction(
          StoreTransactionStatus.purchased,
          storeConfirmed: true,
        ),
      ]);
      await pumpEventQueue();
      expect(store.completed, hasLength(1));
    });

    test('pending does not unlock and is not acknowledged', () async {
      store.onBuy = (store) {
        store.ownership = StoreOwnership.pending;
        store.emit([
          localProTransaction(
            StoreTransactionStatus.pending,
            needsCompletion: false,
          ),
        ]);
      };
      final localPro = entitlement(
        purchaseTimeout: const Duration(milliseconds: 200),
      );
      await localPro.start();
      expect(await localPro.buy(), LocalProActionResult.pending);
      expect(localPro.plan, RegistryPlan.free);
      expect(localPro.pendingPurchase, isTrue);
      expect(store.completed, isEmpty);

      store.ownership = StoreOwnership.owned;
      store.emit([
        localProTransaction(
          StoreTransactionStatus.purchased,
          storeConfirmed: true,
        ),
      ]);
      await pumpEventQueue();
      expect(localPro.plan, RegistryPlan.localPro);
      expect(localPro.pendingPurchase, isFalse);
      expect(store.completed, hasLength(1));
    });

    test('cancelled stays Free', () async {
      store.onBuy = (store) {
        store.emit([
          localProTransaction(
            StoreTransactionStatus.cancelled,
            needsCompletion: false,
          ),
        ]);
      };
      final localPro = entitlement();
      await localPro.start();
      expect(await localPro.buy(), LocalProActionResult.cancelled);
      expect(localPro.plan, RegistryPlan.free);
      expect(hints.hint.owned, isFalse);
    });

    test('a store error during purchase stays Free', () async {
      store.onBuy = (store) {
        store.emit([localProTransaction(StoreTransactionStatus.error)]);
      };
      final localPro = entitlement();
      await localPro.start();
      expect(await localPro.buy(), LocalProActionResult.failed);
      expect(localPro.plan, RegistryPlan.free);
    });

    test('a missing product cannot be bought', () async {
      store.product = const StoreProduct.missing();
      final localPro = entitlement();
      await localPro.start();
      expect(await localPro.buy(), LocalProActionResult.unavailable);
      expect(store.buyCalls, 0);
      expect(localPro.product?.status, StoreProductStatus.missing);
    });

    test(
      'network loss after Play reports PURCHASED keeps the purchase',
      () async {
        store.onBuy = (store) {
          store.ownership = StoreOwnership.error;
          store.emit([
            localProTransaction(
              StoreTransactionStatus.purchased,
              storeConfirmed: true,
            ),
          ]);
        };
        final localPro = entitlement();
        await localPro.start();
        expect(await localPro.buy(), LocalProActionResult.active);
        expect(localPro.plan, RegistryPlan.localPro);
        expect(store.completed, hasLength(1));
      },
    );

    test(
      'an unconfirmed StoreKit update with no network does not unlock',
      () async {
        store.onBuy = (store) {
          store.ownership = StoreOwnership.error;
          store.emit([localProTransaction(StoreTransactionStatus.purchased)]);
        };
        final localPro = entitlement();
        await localPro.start();
        expect(await localPro.buy(), LocalProActionResult.storeError);
        expect(localPro.plan, RegistryPlan.free);
        expect(store.completed, isEmpty);
      },
    );

    test('a failed acknowledgement is retried on the next query', () async {
      store.completeError = StateError('billing service disconnected');
      store.unfinished = [
        localProTransaction(
          StoreTransactionStatus.purchased,
          storeConfirmed: true,
        ),
      ];
      store.ownership = StoreOwnership.owned;
      final localPro = entitlement();
      await localPro.start();
      expect(localPro.plan, RegistryPlan.localPro);
      expect(store.completed, isEmpty);

      store.completeError = null;
      clock.advance(const Duration(minutes: 1));
      await localPro.onResumed();
      expect(store.completed, hasLength(1));
      expect(store.unfinished, isEmpty);
      expect(localPro.plan, RegistryPlan.localPro);
    });
  });

  group('restore', () {
    test('restores an owned purchase and is safe to repeat', () async {
      final localPro = entitlement();
      await localPro.start();
      store.ownership = StoreOwnership.owned;
      expect(await localPro.restore(), LocalProActionResult.active);
      expect(await localPro.restore(), LocalProActionResult.active);
      expect(store.syncCalls, 2);
      expect(localPro.plan, RegistryPlan.localPro);
      expect(hints.hint.owned, isTrue);
    });

    test('a confirmed empty answer is not found', () async {
      final localPro = entitlement();
      await localPro.start();
      expect(await localPro.restore(), LocalProActionResult.notFound);
      expect(localPro.plan, RegistryPlan.free);
    });

    test('a failed App Store sync with no purchase is a store error', () async {
      store.syncResult = false;
      final localPro = entitlement();
      await localPro.start();
      expect(await localPro.restore(), LocalProActionResult.storeError);
    });

    test('no network during restore changes nothing', () async {
      hints.hint = LocalProHint(owned: true, confirmedAt: clock.now());
      store.ownership = StoreOwnership.error;
      final localPro = entitlement();
      await localPro.start();
      expect(await localPro.restore(), LocalProActionResult.storeError);
      expect(localPro.plan, RegistryPlan.localPro);
      expect(hints.hint.owned, isTrue);
    });

    test('billing unavailable is reported as such', () async {
      store.ownership = StoreOwnership.unavailable;
      final localPro = entitlement();
      await localPro.start();
      expect(await localPro.restore(), LocalProActionResult.storeUnavailable);
    });
  });

  group('refund and revocation', () {
    test('a refund seen on the next launch turns Pro off', () async {
      hints.hint = LocalProHint(owned: true, confirmedAt: clock.now());
      store.ownership = StoreOwnership.notOwned;
      final localPro = entitlement();
      await localPro.start();
      expect(localPro.plan, RegistryPlan.free);
      expect(localPro.revokedThisSession, isTrue);
      expect(hints.hint.owned, isFalse);
      expect(localPro.adsMayBeRequested, isTrue);
    });

    test('a revocation seen on resume turns Pro off', () async {
      store.ownership = StoreOwnership.owned;
      final localPro = entitlement();
      await localPro.start();
      expect(localPro.plan, RegistryPlan.localPro);

      store.ownership = StoreOwnership.notOwned;
      clock.advance(const Duration(minutes: 5));
      await localPro.onResumed();
      expect(localPro.plan, RegistryPlan.free);
      expect(localPro.revokedThisSession, isTrue);
      expect(hints.hint.owned, isFalse);
    });

    test('a transient error after confirmation does not revoke', () async {
      store.ownership = StoreOwnership.owned;
      final localPro = entitlement();
      await localPro.start();
      store.ownership = StoreOwnership.error;
      clock.advance(const Duration(minutes: 5));
      await localPro.onResumed();
      expect(localPro.plan, RegistryPlan.localPro);
      expect(localPro.revokedThisSession, isFalse);
    });

    test('resume checks are throttled', () async {
      final localPro = entitlement();
      await localPro.start();
      await localPro.onResumed();
      expect(store.queryCalls, 1);
      clock.advance(const Duration(minutes: 1));
      await localPro.onResumed();
      expect(store.queryCalls, 2);
    });
  });

  group('hint storage', () {
    test('is written only from store answers and cleared on absence', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final stored = PreferencesLocalProHintStore(preferences);
      expect((await stored.read()).owned, isFalse);
      await stored.write(LocalProHint(owned: true, confirmedAt: clock.now()));
      final read = await stored.read();
      expect(read.owned, isTrue);
      expect(read.confirmedAt, clock.now());
      await stored.write(LocalProHint.none);
      expect(preferences.getKeys(), isEmpty);
    });
  });

  group('Play Billing mapping', () {
    GooglePlayPurchaseDetails play(
      PurchaseStateWrapper state, {
      bool acknowledged = false,
      String product = 'local_pro',
    }) {
      return GooglePlayPurchaseDetails.fromPurchase(
        PurchaseWrapper(
          orderId: 'GPA.1',
          packageName: 'com.residay.app',
          purchaseTime: 0,
          purchaseToken: 'token',
          signature: 'signature',
          products: [product],
          isAutoRenewing: false,
          originalJson: '{}',
          isAcknowledged: acknowledged,
          purchaseState: state,
        ),
      ).single;
    }

    test('only PURCHASED is owned; unacknowledged is left to complete', () {
      final owned = androidOwnership(
        QueryPurchaseDetailsResponse(
          pastPurchases: [play(PurchaseStateWrapper.purchased)],
        ),
        'local_pro',
      );
      expect(owned.ownership, StoreOwnership.owned);
      expect(owned.unfinished.single.needsCompletion, isTrue);

      final acknowledged = androidOwnership(
        QueryPurchaseDetailsResponse(
          pastPurchases: [
            play(PurchaseStateWrapper.purchased, acknowledged: true),
          ],
        ),
        'local_pro',
      );
      expect(acknowledged.ownership, StoreOwnership.owned);
      expect(acknowledged.unfinished, isEmpty);
    });

    test('PENDING and other products do not unlock', () {
      expect(
        androidOwnership(
          QueryPurchaseDetailsResponse(
            pastPurchases: [play(PurchaseStateWrapper.pending)],
          ),
          'local_pro',
        ).ownership,
        StoreOwnership.pending,
      );
      expect(
        androidOwnership(
          QueryPurchaseDetailsResponse(
            pastPurchases: [
              play(PurchaseStateWrapper.purchased, product: 'other'),
            ],
          ),
          'local_pro',
        ).ownership,
        StoreOwnership.notOwned,
      );
    });

    test('a query error is not a confirmed absence', () {
      expect(
        androidOwnership(
          QueryPurchaseDetailsResponse(
            pastPurchases: const [],
            error: IAPError(source: 'google_play', code: 'x', message: 'x'),
          ),
          'local_pro',
        ).ownership,
        StoreOwnership.error,
      );
    });

    test('a pending purchase update never needs acknowledgement', () {
      final pending = transaction(play(PurchaseStateWrapper.pending));
      expect(pending.status, StoreTransactionStatus.pending);
      expect(pending.needsCompletion, isFalse);
      expect(pending.storeConfirmed, isFalse);

      final purchased = transaction(play(PurchaseStateWrapper.purchased));
      expect(purchased.status, StoreTransactionStatus.purchased);
      expect(purchased.needsCompletion, isTrue);
      expect(purchased.storeConfirmed, isTrue);
    });
  });

  group('StoreKit mapping', () {
    SK2Transaction apple(String id, {Map<String, Object?>? json}) {
      return SK2Transaction(
        id: id,
        originalId: id,
        productId: 'local_pro',
        purchaseDate: '2026-09-28T09:00:00Z',
        appAccountToken: null,
        jsonRepresentation: jsonEncode(
          json ?? {'productId': 'local_pro', 'transactionId': id},
        ),
      );
    }

    test('a verified, not revoked transaction is owned', () {
      final result = appleOwnership([apple('1')], [apple('1')], 'local_pro');
      expect(result.ownership, StoreOwnership.owned);
      expect(result.unfinished.single.purchaseId, '1');
    });

    test('a revoked transaction is not owned', () {
      final revoked = apple(
        '2',
        json: {'productId': 'local_pro', 'revocationDate': 1790000000000},
      );
      expect(
        appleOwnership([revoked], [revoked], 'local_pro').ownership,
        StoreOwnership.notOwned,
      );
      expect(
        appleOwnership(const [], const [], 'local_pro').ownership,
        StoreOwnership.notOwned,
      );
    });

    test('an unreadable payload cannot unlock', () {
      expect(appleTransactionRevoked(null), isTrue);
      expect(appleTransactionRevoked('not json'), isTrue);
      expect(appleTransactionRevoked('[]'), isTrue);
      expect(appleTransactionRevoked('{"productId":"local_pro"}'), isFalse);
    });
  });
}
