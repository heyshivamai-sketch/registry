import 'dart:async';
import 'dart:convert';

import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/entitlements/billing_records.dart';
import 'package:the_registry/features/entitlements/billing_runtime.dart';
import 'package:the_registry/features/entitlements/grant_codec.dart';
import 'package:the_registry/features/entitlements/pro_account.dart';
import 'package:the_registry/features/entitlements/purchase_service.dart';
import 'package:the_registry/features/entitlements/verified_entitlement.dart';

/// Play Billing and StoreKit purchase flow behind [PurchaseService].
///
/// The store plugin and the billing server are injected. This class never
/// consumes Local Pro. A transport failure does not replace the cached grant.
class PlatformBillingCoordinator implements BillingCoordinator {
  PlatformBillingCoordinator({
    required this.runtime,
    required this.store,
    required this.verifier,
    required this.installationIds,
    required this.cache,
    required this.pending,
    required this.clock,
    this.sessions,
    this.updateTimeout = const Duration(minutes: 5),
  });

  @override
  final BillingRuntime runtime;
  final LocalProStore store;
  final BillingVerificationClient verifier;
  final InstallationIdStore installationIds;
  final EntitlementCacheStore cache;
  final PendingPurchaseStore pending;
  final Clock clock;
  final ProAccountSessionStore? sessions;
  final Duration updateTimeout;

  StreamSubscription<List<StorePurchaseUpdate>>? _updates;
  Completer<PurchaseAttempt>? _waiter;
  String? _recoveryCode;
  final _busy = <String>{};

  @override
  Future<VerifiedEntitlementProof?> warmUp() async {
    if (!runtime.isReady) {
      return null;
    }
    _updates ??= store.updates.listen(_onUpdates);
    await _retryPending();
    final cached = await _proofFromCache();
    await _revalidateIfDue(cached);
    return _proofFromCache();
  }

  Future<void> dispose() async {
    await _updates?.cancel();
    _updates = null;
  }

  @override
  Future<PurchaseAttempt> purchaseLocalPro() {
    return _begin(restore: false);
  }

  @override
  Future<PurchaseAttempt> restoreLocalPro({String? recoveryCode}) {
    return _begin(restore: true, recoveryCode: recoveryCode);
  }

  Future<PurchaseAttempt> _begin({
    required bool restore,
    String? recoveryCode,
  }) async {
    if (!runtime.isReady) {
      return const PurchaseAttempt();
    }
    _updates ??= store.updates.listen(_onUpdates);
    final listing = await store.loadProduct(runtime.productId);
    if (listing == null) {
      return const PurchaseAttempt();
    }
    final installationId = await installationIds.getOrCreate();
    final waiter = Completer<PurchaseAttempt>();
    _waiter = waiter;
    _recoveryCode = recoveryCode;
    try {
      if (restore) {
        await store.restorePurchases(applicationUserName: installationId);
      } else {
        final sent = await store.buyNonConsumable(
          productId: runtime.productId,
          applicationUserName: installationId,
        );
        if (!sent && !waiter.isCompleted) {
          return const PurchaseAttempt(outcome: PurchaseFlowOutcome.failed);
        }
      }
      return await waiter.future.timeout(
        updateTimeout,
        onTimeout: () =>
            const PurchaseAttempt(outcome: PurchaseFlowOutcome.unchanged),
      );
    } finally {
      if (identical(_waiter, waiter)) {
        _waiter = null;
        _recoveryCode = null;
      }
    }
  }

  Future<void> _onUpdates(List<StorePurchaseUpdate> updates) async {
    for (final update in updates) {
      if (update.productId != runtime.productId) {
        continue;
      }
      final attempt = await _handle(update);
      final waiter = _waiter;
      if (attempt != null && waiter != null && !waiter.isCompleted) {
        waiter.complete(attempt);
      }
    }
  }

  Future<PurchaseAttempt?> _handle(StorePurchaseUpdate update) async {
    final key = update.purchaseKey ?? update.payload ?? update.productId;
    if (!_busy.add(key)) {
      return null;
    }
    try {
      return await _process(update, key);
    } finally {
      _busy.remove(key);
    }
  }

  Future<PurchaseAttempt> _process(
    StorePurchaseUpdate update,
    String key,
  ) async {
    final records = await pending.read();
    final existing = _find(records, key);
    if (update.status == StorePurchaseStatus.pending) {
      await _save(records, _record(update, key, 'pending'));
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.pending);
    }
    if (update.status == StorePurchaseStatus.canceled) {
      if (update.pendingComplete) {
        await store.complete(key);
      }
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.cancelled);
    }
    if (update.status == StorePurchaseStatus.error || _isCancel(update)) {
      if (_isCancel(update)) {
        if (update.pendingComplete) {
          await store.complete(key);
        }
        return const PurchaseAttempt(outcome: PurchaseFlowOutcome.cancelled);
      }
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.failed);
    }
    if (existing?.stage == 'completed') {
      return _attemptFromCache(
        update.status == StorePurchaseStatus.restored
            ? PurchaseFlowOutcome.restored
            : PurchaseFlowOutcome.verified,
      );
    }
    if (existing?.stage == 'verified') {
      await _finish(update, records, key, existing!);
      return _attemptFromCache(
        update.status == StorePurchaseStatus.restored
            ? PurchaseFlowOutcome.restored
            : PurchaseFlowOutcome.verified,
      );
    }
    final payload = update.payload;
    if (payload == null || payload.isEmpty) {
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.failed);
    }
    final installationId = await installationIds.getOrCreate();
    final sessionToken = await _sessionToken();
    final BillingServerResponse response;
    try {
      response = await verifier.post(
        update.status == StorePurchaseStatus.restored
            ? '/v1/purchases/restore'
            : '/v1/purchases/verify',
        {
          'platform': update.platform,
          'environment': runtime.environment,
          'installationId': installationId,
          'productId': runtime.productId,
          if (update.platform == 'google') 'purchaseToken': payload,
          if (update.platform == 'apple') 'signedTransaction': payload,
          if (_recoveryCode != null) 'recoveryCode': _recoveryCode,
        },
        sessionToken: sessionToken,
      );
    } catch (_) {
      await _save(records, _record(update, key, 'needsVerification'));
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.unchanged);
    }
    if (_retryable(response)) {
      await _save(records, _record(update, key, 'needsVerification'));
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.unchanged);
    }
    if (response.statusCode == 409) {
      await _save(records, _record(update, key, 'mismatch'));
      await _finishAppleQueue(update, key);
      if (response.body['result'] == 'recovery_code_required') {
        return const PurchaseAttempt(
          outcome: PurchaseFlowOutcome.recoveryCodeRequired,
        );
      }
      if (response.body['result'] == 'account_sign_in_required') {
        return const PurchaseAttempt(
          outcome: PurchaseFlowOutcome.accountSignInRequired,
        );
      }
      return const PurchaseAttempt(
        outcome: PurchaseFlowOutcome.bindingMismatch,
      );
    }
    if (response.body['result'] == 'pending') {
      await _save(records, _record(update, key, 'pending'));
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.pending);
    }
    if (response.statusCode != 200) {
      await _save(records, _record(update, key, 'rejected'));
      if (response.statusCode == 400) {
        await _finishAppleQueue(update, key);
      }
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.failed);
    }
    final canonical = response.body['canonical'];
    final signature = response.body['signature'];
    if (canonical is! String || signature is! String) {
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.failed);
    }
    final proof = await proofFromSignedGrant(
      runtime: runtime,
      installationId: installationId,
      canonical: canonical,
      signatureBase64: signature,
    );
    if (proof == null) {
      return const PurchaseAttempt(outcome: PurchaseFlowOutcome.failed);
    }
    await cache.write(CachedGrant(canonical: canonical, signature: signature));
    final record = _record(update, key, 'verified');
    await _save(records, record);
    await _finish(update, await pending.read(), key, record);
    final recovery = response.body['recoveryCode'];
    final accountLink = response.body['accountLink'];
    return PurchaseAttempt(
      proof: proof,
      outcome: proof.revoked
          ? PurchaseFlowOutcome.revoked
          : update.status == StorePurchaseStatus.restored
          ? PurchaseFlowOutcome.restored
          : PurchaseFlowOutcome.verified,
      recoveryCode: recovery is String ? recovery : null,
      accountLink: accountLink is String ? accountLink : null,
    );
  }

  Future<void> _finish(
    StorePurchaseUpdate update,
    List<PendingPurchaseRecord> records,
    String key,
    PendingPurchaseRecord record,
  ) async {
    if (!update.pendingComplete) {
      await _save(records, record.copyWith(stage: 'completed'));
      return;
    }
    try {
      await store.complete(key);
      await _save(records, record.copyWith(stage: 'completed'));
    } catch (_) {
      await _save(records, record.copyWith(stage: 'verified'));
    }
  }

  Future<void> _retryPending() async {
    final records = await pending.read();
    for (final record in records) {
      if (record.productId != runtime.productId || record.payload.isEmpty) {
        continue;
      }
      if (!_busy.add(record.purchaseKey)) {
        continue;
      }
      try {
        if (record.stage == 'verified') {
          await _finishStored(record);
        } else if (record.stage == 'needsVerification') {
          await _verifyStored(record);
        }
      } finally {
        _busy.remove(record.purchaseKey);
      }
    }
  }

  Future<void> _verifyStored(PendingPurchaseRecord record) async {
    final installationId = await installationIds.getOrCreate();
    final BillingServerResponse response;
    try {
      response = await verifier.post('/v1/purchases/verify', {
        'platform': record.platform,
        'environment': runtime.environment,
        'installationId': installationId,
        'productId': runtime.productId,
        if (record.platform == 'google') 'purchaseToken': record.payload,
        if (record.platform == 'apple') 'signedTransaction': record.payload,
      }, sessionToken: await _sessionToken());
    } catch (_) {
      return;
    }
    if (_retryable(response)) {
      return;
    }
    if (response.statusCode == 409) {
      await _save(await pending.read(), record.copyWith(stage: 'mismatch'));
      return;
    }
    if (response.statusCode != 200) {
      await _save(await pending.read(), record.copyWith(stage: 'rejected'));
      return;
    }
    final canonical = response.body['canonical'];
    final signature = response.body['signature'];
    if (canonical is! String || signature is! String) {
      return;
    }
    final proof = await proofFromSignedGrant(
      runtime: runtime,
      installationId: installationId,
      canonical: canonical,
      signatureBase64: signature,
    );
    if (proof == null) {
      return;
    }
    await cache.write(CachedGrant(canonical: canonical, signature: signature));
    final verified = record.copyWith(stage: 'verified');
    await _save(await pending.read(), verified);
    await _finishStored(verified);
  }

  Future<void> _finishStored(PendingPurchaseRecord record) async {
    try {
      await store.complete(record.purchaseKey);
      await _save(await pending.read(), record.copyWith(stage: 'completed'));
    } catch (_) {
      await _save(await pending.read(), record.copyWith(stage: 'verified'));
    }
  }

  Future<void> _finishAppleQueue(StorePurchaseUpdate update, String key) async {
    if (update.platform != 'apple' || !update.pendingComplete) {
      return;
    }
    try {
      await store.complete(key);
    } catch (_) {
      return;
    }
  }

  Future<String?> _sessionToken() async {
    final session = await sessions?.read();
    final token = session?.token;
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  bool _retryable(BillingServerResponse response) {
    return response.transportFailure ||
        response.statusCode == 429 ||
        response.statusCode == 503 ||
        response.statusCode >= 500;
  }

  Future<void> _revalidateIfDue(VerifiedEntitlementProof? cached) async {
    if (cached == null) {
      return;
    }
    final stored = await cache.read();
    if (stored == null) {
      return;
    }
    final due = revalidateAfter(stored.canonical);
    if (due == null) {
      return;
    }
    final deadline = DateTime.tryParse(due);
    if (deadline == null || clock.now().isBefore(deadline)) {
      return;
    }
    final decoded = _jsonMap(stored.canonical);
    if (decoded == null) {
      return;
    }
    final installationId = await installationIds.getOrCreate();
    final BillingServerResponse response;
    try {
      response = await verifier.post('/v1/entitlements/revalidate', {
        'platform': decoded['platform'],
        'environment': runtime.environment,
        'installationId': installationId,
        'productId': runtime.productId,
        'purchaseKey': decoded['purchaseKey'],
      });
    } catch (_) {
      return;
    }
    if (response.transportFailure || response.statusCode == 503) {
      return;
    }
    final canonical = response.body['canonical'];
    final signature = response.body['signature'];
    if (canonical is! String || signature is! String) {
      return;
    }
    final proof = await proofFromSignedGrant(
      runtime: runtime,
      installationId: installationId,
      canonical: canonical,
      signatureBase64: signature,
    );
    if (proof == null) {
      return;
    }
    await cache.write(CachedGrant(canonical: canonical, signature: signature));
  }

  Future<VerifiedEntitlementProof?> _proofFromCache() async {
    final stored = await cache.read();
    if (stored == null) {
      return null;
    }
    return proofFromSignedGrant(
      runtime: runtime,
      installationId: await installationIds.getOrCreate(),
      canonical: stored.canonical,
      signatureBase64: stored.signature,
    );
  }

  Future<PurchaseAttempt> _attemptFromCache(PurchaseFlowOutcome outcome) async {
    final proof = await _proofFromCache();
    if (proof == null) {
      return PurchaseAttempt(outcome: outcome);
    }
    return PurchaseAttempt(
      proof: proof,
      outcome: proof.revoked ? PurchaseFlowOutcome.revoked : outcome,
    );
  }

  Future<void> _save(
    List<PendingPurchaseRecord> records,
    PendingPurchaseRecord record,
  ) async {
    final next = [
      for (final item in records)
        if (item.purchaseKey != record.purchaseKey) item,
      record,
    ];
    await pending.write(next);
  }

  PendingPurchaseRecord? _find(
    List<PendingPurchaseRecord> records,
    String key,
  ) {
    for (final record in records) {
      if (record.purchaseKey == key) {
        return record;
      }
    }
    return null;
  }

  PendingPurchaseRecord _record(
    StorePurchaseUpdate update,
    String key,
    String stage,
  ) {
    return PendingPurchaseRecord(
      purchaseKey: key,
      productId: update.productId,
      platform: update.platform,
      payload: update.payload ?? '',
      stage: stage,
    );
  }

  bool _isCancel(StorePurchaseUpdate update) {
    final code = update.errorCode?.toLowerCase() ?? '';
    return code.contains('cancel');
  }

  Map<String, Object?>? _jsonMap(String canonical) {
    try {
      final decoded = jsonDecode(canonical);
      if (decoded is! Map) {
        return null;
      }
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } on FormatException {
      return null;
    }
  }
}
