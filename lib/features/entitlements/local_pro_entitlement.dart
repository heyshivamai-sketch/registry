import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_registry/app/launch_config.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/entitlements/local_pro_store.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';

/// What the Local Pro screen and Profile show.
enum LocalProStatus {
  /// This build does not sell Local Pro. Everyone is on Free.
  disabled,

  /// Waiting for the first store answer since launch.
  checking,

  /// The store confirmed Local Pro in this session.
  active,

  /// The store confirmed Local Pro earlier and cannot be reached now.
  activeUnconfirmed,

  /// The store answered: no Local Pro for this store account.
  free,

  /// The store could not be reached and has not confirmed Local Pro here.
  unknown,
}

/// Why the store could not answer. Not a statement about ownership.
enum StoreProblem { none, unavailable, error }

enum LocalProActionResult {
  /// Purchases are off in this build or the store has no product.
  unavailable,

  /// The store confirmed Local Pro.
  active,

  /// The store is still processing payment. Local Pro stays off.
  pending,

  cancelled,

  /// The store answered and has no Local Pro purchase for this account.
  notFound,

  /// Billing is not available on this device or account.
  storeUnavailable,

  /// No network, a timeout, or a store error. Nothing was confirmed.
  storeError,

  /// The store reported a purchase error.
  failed,
}

/// The last store answer about ownership, kept outside the registry database
/// and outside `.rgry` backups.
///
/// Only a store query writes it. It lets a returning Local Pro user keep Pro
/// while the store is unreachable. A confirmed absence clears it.
class LocalProHint {
  const LocalProHint({required this.owned, this.confirmedAt});

  static const none = LocalProHint(owned: false);

  final bool owned;
  final DateTime? confirmedAt;
}

abstract class LocalProHintStore {
  Future<LocalProHint> read();

  Future<void> write(LocalProHint hint);
}

class MemoryLocalProHintStore implements LocalProHintStore {
  MemoryLocalProHintStore([this.hint = LocalProHint.none]);

  LocalProHint hint;
  var writes = 0;

  @override
  Future<LocalProHint> read() async => hint;

  @override
  Future<void> write(LocalProHint hint) async {
    writes += 1;
    this.hint = hint;
  }
}

class PreferencesLocalProHintStore implements LocalProHintStore {
  PreferencesLocalProHintStore(this._preferences);

  static const ownedKey = 'local_pro.store_confirmed_owned';
  static const confirmedAtKey = 'local_pro.store_confirmed_at';

  final SharedPreferences _preferences;

  @override
  Future<LocalProHint> read() async {
    final owned = _preferences.getBool(ownedKey) ?? false;
    final at = _preferences.getInt(confirmedAtKey);
    return LocalProHint(
      owned: owned,
      confirmedAt: at == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
    );
  }

  @override
  Future<void> write(LocalProHint hint) async {
    if (!hint.owned) {
      await _preferences.remove(ownedKey);
      await _preferences.remove(confirmedAtKey);
      return;
    }
    await _preferences.setBool(ownedKey, true);
    final at = hint.confirmedAt;
    if (at != null) {
      await _preferences.setInt(confirmedAtKey, at.millisecondsSinceEpoch);
    }
  }
}

/// Local Pro from Google Play or the App Store, with no app server.
///
/// Pro is on only when the store reports an owned, paid, not revoked
/// `local_pro`, or when the store confirmed that earlier and is unreachable
/// now. A pending, cancelled, or failed purchase never turns it on. A backup
/// file or a switch in the app cannot turn it on.
class LocalProEntitlement extends ChangeNotifier implements RegistryPlanSource {
  LocalProEntitlement({
    required this.purchasesEnabled,
    this.store,
    LocalProHintStore? hints,
    this.productId = LaunchConfig.localProProductId,
    this.clock = const Clock(),
    this.queryTimeout = const Duration(seconds: 20),
    this.purchaseTimeout = const Duration(minutes: 10),
    this.resumeInterval = const Duration(seconds: 30),
  }) : hints = hints ?? MemoryLocalProHintStore();

  /// Purchases are off, so nothing talks to a store.
  factory LocalProEntitlement.disabled() {
    return LocalProEntitlement(purchasesEnabled: false);
  }

  final bool purchasesEnabled;
  final LocalProStore? store;
  final LocalProHintStore hints;
  final String productId;
  final Clock clock;
  final Duration queryTimeout;
  final Duration purchaseTimeout;
  final Duration resumeInterval;

  bool? _confirmedOwned;
  var _cachedOwned = false;
  var _checking = false;
  var _started = false;
  var _pending = false;
  var _revoked = false;
  var _problem = StoreProblem.none;
  DateTime? _confirmedAt;
  DateTime? _lastQuery;
  StoreProduct? _product;
  Future<StoreOwnership>? _inflight;
  Future<StoreProduct>? _productLoad;
  Completer<LocalProActionResult>? _purchase;
  StreamSubscription<List<StoreTransaction>>? _updates;
  final _completed = <String>{};
  var _disposed = false;

  bool get _enabled => purchasesEnabled && store != null;

  @override
  RegistryPlan get plan {
    if (!_enabled) {
      return RegistryPlan.free;
    }
    final confirmed = _confirmedOwned;
    if (confirmed != null) {
      return confirmed ? RegistryPlan.localPro : RegistryPlan.free;
    }
    return _cachedOwned ? RegistryPlan.localPro : RegistryPlan.free;
  }

  LocalProStatus get status {
    if (!_enabled) {
      return LocalProStatus.disabled;
    }
    final confirmed = _confirmedOwned;
    if (confirmed != null) {
      return confirmed ? LocalProStatus.active : LocalProStatus.free;
    }
    if (_checking || !_started) {
      return _cachedOwned
          ? LocalProStatus.activeUnconfirmed
          : LocalProStatus.checking;
    }
    return _cachedOwned
        ? LocalProStatus.activeUnconfirmed
        : LocalProStatus.unknown;
  }

  /// True while the first store check since launch has not answered.
  bool get resolving =>
      _enabled && _confirmedOwned == null && (_checking || !_started);

  /// Ads may be requested only for a Free user and never while a returning
  /// Local Pro user is still being resolved.
  @override
  bool get adsMayBeRequested {
    if (!_enabled) {
      return true;
    }
    if (plan == RegistryPlan.localPro || resolving) {
      return false;
    }
    return true;
  }

  StoreProblem get problem => _problem;

  /// A purchase is waiting for payment in the store.
  bool get pendingPurchase => _pending;

  /// The store no longer reports a Local Pro purchase this app had seen.
  bool get revokedThisSession => _revoked;

  DateTime? get lastConfirmedAt => _confirmedAt;

  StoreProduct? get product => _product;

  /// Restore can reach a store in this build.
  bool get restoreAvailable => _enabled;

  Future<void> start() async {
    if (_started) {
      return;
    }
    if (!_enabled) {
      _started = true;
      return;
    }
    _checking = true;
    final hint = await hints.read();
    _cachedOwned = hint.owned;
    _confirmedAt = hint.confirmedAt;
    _updates = store!.transactions.listen(
      (updates) => unawaited(_onTransactions(updates)),
    );
    _started = true;
    _notify();
    await _query();
  }

  /// Checks again when the app returns to the foreground.
  Future<void> onResumed() async {
    if (!_enabled || !_started) {
      return;
    }
    final last = _lastQuery;
    if (last != null && clock.now().difference(last) < resumeInterval) {
      return;
    }
    await _query();
  }

  Future<StoreProduct> loadProduct({bool force = false}) {
    if (!_enabled) {
      return Future.value(const StoreProduct.unavailable());
    }
    final existing = _productLoad;
    if (existing != null && !force) {
      return existing;
    }
    final load = _loadProduct();
    _productLoad = load;
    return load;
  }

  Future<StoreProduct> _loadProduct() async {
    StoreProduct product;
    try {
      product = await store!
          .loadProduct(productId)
          .timeout(queryTimeout, onTimeout: () => const StoreProduct.error());
    } catch (_) {
      product = const StoreProduct.error();
    }
    if (!product.isAvailable) {
      _productLoad = null;
    }
    _product = product;
    _notify();
    return product;
  }

  Future<LocalProActionResult> buy() async {
    if (!_enabled) {
      return LocalProActionResult.unavailable;
    }
    if (_confirmedOwned == true) {
      return LocalProActionResult.active;
    }
    final existing = _purchase;
    if (existing != null) {
      return existing.future;
    }
    final product = _product ?? await loadProduct();
    if (!product.isAvailable) {
      return LocalProActionResult.unavailable;
    }
    final waiter = Completer<LocalProActionResult>();
    _purchase = waiter;
    try {
      bool started;
      try {
        started = await store!.buy(product);
      } catch (_) {
        started = false;
      }
      if (!started) {
        if (!waiter.isCompleted) {
          final ownership = await _query();
          return ownership == StoreOwnership.owned
              ? LocalProActionResult.active
              : LocalProActionResult.failed;
        }
      }
      return await waiter.future.timeout(
        purchaseTimeout,
        onTimeout: () => _pending
            ? LocalProActionResult.pending
            : LocalProActionResult.storeError,
      );
    } finally {
      if (identical(_purchase, waiter)) {
        _purchase = null;
      }
    }
  }

  /// The visible Restore purchases action.
  ///
  /// StoreKit is asked to sync first, which can show an App Store sign-in.
  /// Play Billing reads the purchases for the signed-in Google account.
  Future<LocalProActionResult> restore() async {
    if (!_enabled) {
      return LocalProActionResult.unavailable;
    }
    bool synced;
    try {
      synced = await store!.syncWithStore();
    } catch (_) {
      synced = false;
    }
    final ownership = await _query(force: true);
    return switch (ownership) {
      StoreOwnership.owned => LocalProActionResult.active,
      StoreOwnership.notOwned =>
        synced
            ? LocalProActionResult.notFound
            : LocalProActionResult.storeError,
      StoreOwnership.pending => LocalProActionResult.pending,
      StoreOwnership.unavailable => LocalProActionResult.storeUnavailable,
      StoreOwnership.error => LocalProActionResult.storeError,
    };
  }

  /// One store query at a time. [force] waits for a query already running and
  /// then asks again, so an answer that predates a purchase is not reused.
  Future<StoreOwnership> _query({bool force = false}) async {
    final existing = _inflight;
    if (existing != null) {
      final answer = await existing;
      if (!force) {
        return answer;
      }
      final newer = _inflight;
      if (newer != null) {
        return newer;
      }
    }
    final next = _runQuery();
    _inflight = next;
    try {
      return await next;
    } finally {
      if (identical(_inflight, next)) {
        _inflight = null;
      }
    }
  }

  Future<StoreOwnership> _runQuery() async {
    _checking = true;
    _notify();
    OwnershipQuery result;
    try {
      result = await store!
          .queryOwnership(productId)
          .timeout(
            queryTimeout,
            onTimeout: () => const OwnershipQuery(StoreOwnership.error),
          );
    } catch (_) {
      result = const OwnershipQuery(StoreOwnership.error);
    }
    _lastQuery = clock.now();
    await _apply(result);
    _checking = false;
    _notify();
    return result.ownership;
  }

  Future<void> _apply(OwnershipQuery result) async {
    switch (result.ownership) {
      case StoreOwnership.owned:
        await _markOwned();
        for (final transaction in result.unfinished) {
          await _complete(transaction);
        }
      case StoreOwnership.notOwned:
        await _markNotOwned(pending: false);
      case StoreOwnership.pending:
        await _markNotOwned(pending: true);
      case StoreOwnership.unavailable:
        _problem = StoreProblem.unavailable;
      case StoreOwnership.error:
        _problem = StoreProblem.error;
    }
  }

  Future<void> _markOwned() async {
    _confirmedOwned = true;
    _cachedOwned = true;
    _pending = false;
    _revoked = false;
    _problem = StoreProblem.none;
    _confirmedAt = clock.now().toUtc();
    await hints.write(LocalProHint(owned: true, confirmedAt: _confirmedAt));
  }

  Future<void> _markNotOwned({required bool pending}) async {
    final hadPro = plan == RegistryPlan.localPro;
    _confirmedOwned = false;
    _pending = pending;
    _problem = StoreProblem.none;
    if (hadPro) {
      _revoked = true;
    }
    if (_cachedOwned) {
      _cachedOwned = false;
      _confirmedAt = null;
      await hints.write(LocalProHint.none);
    }
  }

  Future<void> _onTransactions(List<StoreTransaction> updates) async {
    for (final update in updates) {
      if (update.productId != productId) {
        continue;
      }
      final result = await _handle(update);
      final waiter = _purchase;
      if (result != null && waiter != null && !waiter.isCompleted) {
        waiter.complete(result);
      }
    }
  }

  Future<LocalProActionResult?> _handle(StoreTransaction update) async {
    switch (update.status) {
      case StoreTransactionStatus.pending:
        if (_confirmedOwned != true) {
          _pending = true;
          _notify();
        }
        return LocalProActionResult.pending;
      case StoreTransactionStatus.cancelled:
        await _complete(update);
        return LocalProActionResult.cancelled;
      case StoreTransactionStatus.error:
        await _complete(update);
        final ownership = await _query(force: true);
        return ownership == StoreOwnership.owned
            ? LocalProActionResult.active
            : LocalProActionResult.failed;
      case StoreTransactionStatus.purchased:
      case StoreTransactionStatus.restored:
        final ownership = await _query(force: true);
        if (ownership == StoreOwnership.owned) {
          await _complete(update);
          return LocalProActionResult.active;
        }
        if (update.storeConfirmed &&
            (ownership == StoreOwnership.error ||
                ownership == StoreOwnership.unavailable)) {
          await _markOwned();
          await _complete(update);
          _notify();
          return LocalProActionResult.active;
        }
        if (ownership == StoreOwnership.notOwned) {
          // A StoreKit update for a revoked or unverified transaction.
          await _complete(update);
          return LocalProActionResult.failed;
        }
        if (ownership == StoreOwnership.pending) {
          return LocalProActionResult.pending;
        }
        return LocalProActionResult.storeError;
    }
  }

  /// Acknowledge or finish once. A failure is retried on the next query,
  /// which returns the purchase again while it is unacknowledged.
  Future<void> _complete(StoreTransaction transaction) async {
    if (!transaction.needsCompletion) {
      return;
    }
    final key = transaction.purchaseId;
    if (key != null && _completed.contains(key)) {
      return;
    }
    try {
      await store!.complete(transaction);
      if (key != null) {
        _completed.add(key);
      }
    } catch (_) {
      // Left for the next launch, resume, or restore.
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_updates?.cancel());
    super.dispose();
  }
}
