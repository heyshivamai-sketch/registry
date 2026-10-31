import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/ads/ads_platform.dart';
import 'package:the_registry/features/app_lock/device_authenticator.dart';
import 'package:the_registry/features/backup/presentation/profile_screen.dart';
import 'package:the_registry/features/app_lock/privacy_flag.dart';
import 'package:the_registry/features/csv_import/csv_file_gateway.dart';
import 'package:the_registry/features/entitlements/local_pro_store.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';

class ScriptedDeviceAuthenticator implements DeviceAuthenticator {
  DeviceAuthAvailability availabilityResult = DeviceAuthAvailability.ready;
  DeviceAuthAttempt authenticateResult = DeviceAuthAttempt.authenticated;
  var authenticateCalls = 0;
  String? lastReason;
  bool? enabledDuringAuthenticate;
  bool Function()? readEnabled;

  @override
  Future<DeviceAuthAvailability> availability() async => availabilityResult;

  @override
  Future<DeviceAuthAttempt> authenticate({
    required String localizedReason,
  }) async {
    authenticateCalls += 1;
    lastReason = localizedReason;
    enabledDuringAuthenticate = readEnabled?.call();
    return authenticateResult;
  }
}

class RecordingPrivacyFlag implements PrivacyFlag {
  var secure = false;
  var calls = 0;

  @override
  Future<void> setSecure(bool secure) async {
    calls += 1;
    this.secure = secure;
  }
}

/// A scripted Play Billing / StoreKit boundary. It is not a store.
class FakeLocalProStore implements LocalProStore {
  FakeLocalProStore({
    this.ownership = StoreOwnership.notOwned,
    StoreProduct? product,
  }) : product =
           product ?? const StoreProduct.available(localizedPrice: '€4.99');

  StoreOwnership ownership;
  StoreProduct product;
  List<StoreTransaction> unfinished = const [];
  bool syncResult = true;
  bool buyStarts = true;
  Object? completeError;

  /// When set, a query waits for it before answering.
  Completer<void>? queryGate;

  /// Called by [buy] after it returns, to emit store updates.
  void Function(FakeLocalProStore store)? onBuy;

  var queryCalls = 0;
  var loadCalls = 0;
  var syncCalls = 0;
  var buyCalls = 0;
  final completed = <StoreTransaction>[];
  final _updates = StreamController<List<StoreTransaction>>.broadcast();

  void emit(List<StoreTransaction> updates) => _updates.add(updates);

  @override
  Future<StoreProduct> loadProduct(String productId) async {
    loadCalls += 1;
    return product;
  }

  @override
  Future<OwnershipQuery> queryOwnership(String productId) async {
    queryCalls += 1;
    final gate = queryGate;
    if (gate != null) {
      await gate.future;
    }
    return OwnershipQuery(
      ownership,
      unfinished: ownership == StoreOwnership.owned ? unfinished : const [],
    );
  }

  @override
  Future<bool> syncWithStore() async {
    syncCalls += 1;
    return syncResult;
  }

  @override
  Future<bool> buy(StoreProduct product) async {
    buyCalls += 1;
    if (buyStarts) {
      scheduleMicrotask(() => onBuy?.call(this));
    }
    return buyStarts;
  }

  @override
  Stream<List<StoreTransaction>> get transactions => _updates.stream;

  @override
  Future<void> complete(StoreTransaction transaction) async {
    final error = completeError;
    if (error != null) {
      throw error;
    }
    completed.add(transaction);
    unfinished = [
      for (final item in unfinished)
        if (item.purchaseId != transaction.purchaseId) item,
    ];
  }

  Future<void> close() => _updates.close();
}

StoreTransaction localProTransaction(
  StoreTransactionStatus status, {
  String purchaseId = 'GPA.0001',
  bool needsCompletion = true,
  bool storeConfirmed = false,
}) {
  return StoreTransaction(
    productId: 'local_pro',
    status: status,
    purchaseId: purchaseId,
    needsCompletion: needsCompletion,
    storeConfirmed: storeConfirmed,
  );
}

class FakePlanSource extends ChangeNotifier implements RegistryPlanSource {
  FakePlanSource({
    this._plan = RegistryPlan.free,
    this._adsMayBeRequested = true,
  });

  RegistryPlan _plan;
  bool _adsMayBeRequested;

  @override
  RegistryPlan get plan => _plan;

  @override
  bool get adsMayBeRequested => _adsMayBeRequested;

  void set({RegistryPlan? plan, bool? adsMayBeRequested}) {
    _plan = plan ?? _plan;
    _adsMayBeRequested = adsMayBeRequested ?? _adsMayBeRequested;
    notifyListeners();
  }
}

/// A scripted Mobile Ads / UMP boundary. It never contacts Google.
class FakeAdsPlatform implements AdsPlatform {
  FakeAdsPlatform({
    this.consent = const AdsConsentState(
      canRequestAds: true,
      privacyOptionsRequired: false,
    ),
    this.bannerLoads = true,
  });

  AdsConsentState consent;
  AdsConsentState? afterPrivacyOptions;
  bool bannerLoads;
  var consentCalls = 0;
  var initializeCalls = 0;
  var privacyCalls = 0;
  final bannerRequests = <({String unitId, int width})>[];
  final banners = <FakeBanner>[];

  int get calls =>
      consentCalls + initializeCalls + privacyCalls + bannerRequests.length;

  @override
  Future<AdsConsentState> gatherConsent() async {
    consentCalls += 1;
    return consent;
  }

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<AdsConsentState> showPrivacyOptions() async {
    privacyCalls += 1;
    return consent = afterPrivacyOptions ?? consent;
  }

  @override
  Future<LoadedBanner?> loadBanner({
    required String unitId,
    required int width,
  }) async {
    bannerRequests.add((unitId: unitId, width: width));
    if (!bannerLoads) {
      return null;
    }
    final banner = FakeBanner(Size(width.toDouble(), 60));
    banners.add(banner);
    return banner;
  }
}

class FakeBanner implements LoadedBanner {
  FakeBanner(this.size);

  @override
  final Size size;
  var disposed = false;

  @override
  Widget build() {
    return ColoredBox(
      key: const ValueKey<String>('fake-test-banner'),
      color: const Color(0xFFE8EAED),
      child: Center(
        child: Text(
          'Test Ad · Google sample banner',
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 12, color: Color(0xFF3C4043)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    disposed = true;
  }
}

Future<void> tapProfileControl(
  WidgetTester tester,
  ValueKey<String> key,
) async {
  final scrollable = find.descendant(
    of: find.byType(ProfileScreen),
    matching: find.byType(Scrollable),
  );
  final target = find.byKey(key);
  await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
  for (var attempt = 0; attempt < 8; attempt++) {
    if (tester.getCenter(target).dy < 420) {
      break;
    }
    await tester.drag(scrollable, const Offset(0, -160));
    await tester.pumpAndSettle();
  }
  await tester.tap(target);
  await tester.pumpAndSettle();
}

class ScriptedCsvFileGateway implements CsvFileGateway {
  ScriptedCsvFileGateway(this.bytes);

  Uint8List? bytes;
  var calls = 0;

  @override
  Future<Uint8List?> pickCsv() async {
    calls += 1;
    return bytes;
  }
}
