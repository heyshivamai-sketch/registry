// Device QA for the launch build's Local Pro and ads states.
//
// Run only on an isolated emulator or simulator, with Google's test IDs:
//   flutter test integration_test/launch_ads_qa_test.dart -d <isolated device> \
//     --dart-define=ADS_ENABLED=true --dart-define=ADS_MODE=test
//
// Local Pro here comes from a scripted store, not Google Play or the App
// Store. The Free banner is a real request to Google with the sample banner
// unit ID, which serves test ads only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/ads/ads_config.dart';
import 'package:the_registry/features/ads/ads_platform.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/entitlements/local_pro_entitlement.dart';
import 'package:the_registry/features/entitlements/local_pro_store.dart';
import 'package:the_registry/features/entitlements/presentation/local_pro_screen.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';

import '../test/support/fake_onboarding_repository.dart';
import '../test/support/phase2_fakes.dart';
import '../test/support/sample_document.dart';
import '../test/support/sample_subscription.dart';

class _RecordingAdsPlatform implements AdsPlatform {
  _RecordingAdsPlatform(this._inner);

  final AdsPlatform _inner;
  var calls = 0;

  @override
  Future<AdsConsentState> gatherConsent() {
    calls += 1;
    return _inner.gatherConsent();
  }

  @override
  Future<void> initialize() {
    calls += 1;
    return _inner.initialize();
  }

  @override
  Future<AdsConsentState> showPrivacyOptions() {
    calls += 1;
    return _inner.showPrivacyOptions();
  }

  @override
  Future<LoadedBanner?> loadBanner({
    required String unitId,
    required int width,
  }) {
    calls += 1;
    return _inner.loadBanner(unitId: unitId, width: width);
  }
}

Future<void> _hold(WidgetTester tester, String tag) async {
  debugPrint('LAUNCH_QA:$tag');
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<Widget> _app({
  required AdsConfig ads,
  required AdsPlatform platform,
  LocalProEntitlement? localPro,
}) async {
  final documents = InMemoryDocumentRepository();
  final subscriptions = InMemorySubscriptionRepository();
  await documents.save(sampleDocument(id: 'passport', name: 'Passport'));
  await subscriptions.save(
    sampleSubscription(id: 'gym', serviceName: 'Gym membership'),
  );
  return RegistryApp(
    key: UniqueKey(),
    onboardingRepository: FakeOnboardingRepository(completed: true),
    documentRepository: documents,
    subscriptionRepository: subscriptions,
    clock: FixedClock(DateTime(2026, 9, 28)),
    locale: const Locale('en'),
    localPro: localPro,
    adsConfig: ads,
    adsPlatform: platform,
  );
}

Future<void> _scrollHomeToEnd(WidgetTester tester) async {
  await tester.drag(
    find
        .descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(Scrollable),
        )
        .first,
    const Offset(0, -3000),
  );
  await tester.pumpAndSettle();
}

Future<void> _openLocalPro(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
  await tester.pumpAndSettle();
  await tapProfileControl(tester, const ValueKey<String>('local-pro-open'));
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey<String>('local-pro-status')),
    200,
    scrollable: find.descendant(
      of: find.byType(LocalProScreen),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launch Local Pro and ads states on device', (tester) async {
    final ads = AdsConfig.fromEnvironment();
    expect(ads.mode, AdsMode.test, reason: 'Run with ADS_MODE=test.');

    // Purchases off (the launch default): Buy explained, no Restore.
    await tester.pumpWidget(
      await _app(ads: AdsConfig.off, platform: const GoogleMobileAdsPlatform()),
    );
    await tester.pumpAndSettle();
    await _openLocalPro(tester);
    expect(
      find.byKey(const ValueKey<String>('local-pro-purchases-disabled')),
      findsOneWidget,
    );
    await _hold(tester, 'free_local_pro_purchases_off');

    // Local Pro from a scripted store, ads build in test mode: no ad calls.
    final store = FakeLocalProStore(ownership: StoreOwnership.owned);
    final proPlatform = _RecordingAdsPlatform(const GoogleMobileAdsPlatform());
    await tester.pumpWidget(
      await _app(
        ads: ads,
        platform: proPlatform,
        localPro: LocalProEntitlement(purchasesEnabled: true, store: store),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollHomeToEnd(tester);
    expect(find.byKey(const ValueKey<String>('registry-banner')), findsNothing);
    await _hold(tester, 'pro_home_no_banner');
    await _openLocalPro(tester);
    expect(
      find.byKey(const ValueKey<String>('local-pro-status-active')),
      findsOneWidget,
    );
    await _hold(tester, 'pro_local_pro_active_fake_store');
    expect(proPlatform.calls, 0);

    // Free, ads build in test mode: a Google sample banner on Home.
    final freePlatform = _RecordingAdsPlatform(const GoogleMobileAdsPlatform());
    await tester.pumpWidget(await _app(ads: ads, platform: freePlatform));
    await tester.pumpAndSettle();
    await _scrollHomeToEnd(tester);
    final banner = find.byKey(const ValueKey<String>('registry-banner'));
    for (var i = 0; i < 60 && banner.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _scrollHomeToEnd(tester);
    expect(banner, findsOneWidget);
    await _hold(tester, 'free_home_test_banner');
    expect(freePlatform.calls, greaterThan(0));

    await tester.pumpWidget(const SizedBox());
    await store.close();
  });
}
