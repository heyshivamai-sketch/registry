import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/ads/ads_config.dart';
import 'package:the_registry/features/ads/ads_controller.dart';
import 'package:the_registry/features/ads/ads_platform.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/entitlements/local_pro_entitlement.dart';
import 'package:the_registry/features/entitlements/local_pro_store.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/phase2_fakes.dart';
import 'support/sample_document.dart';
import 'support/sample_subscription.dart';

// A scripted ads boundary stands in for Google Mobile Ads and UMP. No ad is
// requested from Google in these tests.
void main() {
  AdsConfig resolve({
    bool enabled = true,
    String mode = 'test',
    String android = '',
    String ios = '',
    TargetPlatform platform = TargetPlatform.android,
    bool release = false,
  }) {
    return AdsConfig.resolve(
      adsEnabled: enabled,
      mode: mode,
      androidBannerUnitId: android,
      iosBannerUnitId: ios,
      platform: platform,
      releaseMode: release,
    );
  }

  const testConsent = AdsConsentState(
    canRequestAds: true,
    privacyOptionsRequired: false,
  );

  group('AdsConfig', () {
    test('ads are off unless ADS_ENABLED is set', () {
      expect(AdsConfig.fromEnvironment().enabled, isFalse);
      expect(resolve(enabled: false).mode, AdsMode.off);
      expect(resolve(enabled: false, mode: 'live').problem, isNull);
    });

    test('test mode uses Google sample banner IDs per platform', () {
      expect(resolve().bannerUnitId, GoogleSampleAdIds.androidAdaptiveBanner);
      expect(
        resolve(platform: TargetPlatform.iOS).bannerUnitId,
        GoogleSampleAdIds.iosAdaptiveBanner,
      );
      expect(resolve().mode, AdsMode.test);
    });

    test('a release build refuses test mode', () {
      final config = resolve(release: true);
      expect(config.enabled, isFalse);
      expect(config.problem, AdsConfigProblem.testIdsInRelease);
    });

    test('live mode needs a real platform banner unit ID', () {
      expect(
        resolve(mode: 'live', release: true).problem,
        AdsConfigProblem.missingBannerUnitId,
      );
      expect(
        resolve(
          mode: 'live',
          android: GoogleSampleAdIds.androidAdaptiveBanner,
          release: true,
        ).problem,
        AdsConfigProblem.sampleIdInLive,
      );
      expect(
        resolve(
          mode: 'live',
          android: 'ca-app-pub-1234567890123456~1234567890',
          release: true,
        ).problem,
        AdsConfigProblem.invalidBannerUnitId,
        reason: 'An App ID is not a banner ad unit ID.',
      );
      expect(
        resolve(
          mode: 'live',
          ios: 'ca-app-pub-1234567890123456/1234567890',
          release: true,
        ).problem,
        AdsConfigProblem.missingBannerUnitId,
        reason: 'The iOS unit ID does not serve Android.',
      );
      final live = resolve(
        mode: 'live',
        android: 'ca-app-pub-1234567890123456/1234567890',
        release: true,
      );
      expect(live.enabled, isTrue);
      expect(live.mode, AdsMode.live);
      expect(live.bannerUnitId, 'ca-app-pub-1234567890123456/1234567890');
    });

    test('an unknown mode or platform stays off', () {
      expect(resolve(mode: 'on').problem, AdsConfigProblem.unknownMode);
      expect(
        resolve(platform: TargetPlatform.macOS).problem,
        AdsConfigProblem.unsupportedPlatform,
      );
    });
  });

  group('AdsController', () {
    test('ads off never calls the ads or consent SDK', () async {
      final platform = FakeAdsPlatform();
      final plan = FakePlanSource();
      final ads = AdsController(
        config: AdsConfig.off,
        plan: plan,
        platform: platform,
      )..start();
      plan.set(plan: RegistryPlan.free);
      await ads.showPrivacyOptions();
      await pumpEventQueue();
      expect(platform.calls, 0);
      expect(ads.showBanners, isFalse);
      expect(ads.privacyOptionsRequired, isFalse);
      ads.dispose();
    });

    test('Free in test mode gathers consent, then initializes', () async {
      final platform = FakeAdsPlatform(consent: testConsent);
      final ads = AdsController(
        config: resolve(),
        plan: FakePlanSource(),
        platform: platform,
      )..start();
      await pumpEventQueue();
      expect(platform.consentCalls, 1);
      expect(platform.initializeCalls, 1);
      expect(ads.showBanners, isTrue);
      expect(ads.bannerUnitId, GoogleSampleAdIds.androidAdaptiveBanner);
      ads.dispose();
    });

    test('no initialization or ads until consent allows requests', () async {
      final platform =
          FakeAdsPlatform(
              consent: const AdsConsentState(
                canRequestAds: false,
                privacyOptionsRequired: true,
              ),
            )
            ..afterPrivacyOptions = const AdsConsentState(
              canRequestAds: true,
              privacyOptionsRequired: true,
            );
      final ads = AdsController(
        config: resolve(),
        plan: FakePlanSource(),
        platform: platform,
      )..start();
      await pumpEventQueue();
      expect(platform.consentCalls, 1);
      expect(platform.initializeCalls, 0);
      expect(ads.showBanners, isFalse);
      expect(ads.privacyOptionsRequired, isTrue);

      await ads.showPrivacyOptions();
      expect(platform.privacyCalls, 1);
      expect(platform.initializeCalls, 1);
      expect(ads.showBanners, isTrue);
      ads.dispose();
    });

    test('Local Pro never reaches consent or the ads SDK', () async {
      final platform = FakeAdsPlatform(consent: testConsent);
      final ads = AdsController(
        config: resolve(),
        plan: FakePlanSource(
          plan: RegistryPlan.localPro,
          adsMayBeRequested: false,
        ),
        platform: platform,
      )..start();
      await pumpEventQueue();
      expect(platform.calls, 0);
      expect(ads.showBanners, isFalse);
      ads.dispose();
    });

    test('nothing starts while a returning Pro user is resolving', () async {
      final platform = FakeAdsPlatform(consent: testConsent);
      final plan = FakePlanSource(adsMayBeRequested: false);
      final ads = AdsController(
        config: resolve(),
        plan: plan,
        platform: platform,
      )..start();
      await pumpEventQueue();
      expect(platform.calls, 0);

      plan.set(plan: RegistryPlan.localPro);
      await pumpEventQueue();
      expect(platform.calls, 0);
      expect(ads.showBanners, isFalse);
      ads.dispose();
    });

    test('buying Pro hides banners immediately', () async {
      final platform = FakeAdsPlatform(consent: testConsent);
      final plan = FakePlanSource();
      final ads = AdsController(
        config: resolve(),
        plan: plan,
        platform: platform,
      )..start();
      await pumpEventQueue();
      expect(ads.showBanners, isTrue);
      plan.set(plan: RegistryPlan.localPro, adsMayBeRequested: false);
      expect(ads.showBanners, isFalse);
      ads.dispose();
    });

    test('a consent SDK failure means no ads', () async {
      final platform = _ThrowingConsentPlatform();
      final ads = AdsController(
        config: resolve(),
        plan: FakePlanSource(),
        platform: platform,
      )..start();
      await pumpEventQueue();
      expect(platform.initializeCalls, 0);
      expect(ads.showBanners, isFalse);
      ads.dispose();
    });
  });

  group('Home banner', () {
    Future<InMemoryDocumentRepository> seeded() async {
      final documents = InMemoryDocumentRepository();
      await documents.save(sampleDocument());
      return documents;
    }

    Future<InMemorySubscriptionRepository> seededSubscriptions() async {
      final subscriptions = InMemorySubscriptionRepository();
      await subscriptions.save(sampleSubscription());
      return subscriptions;
    }

    Future<void> scrollToEnd(WidgetTester tester) async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
    }

    testWidgets('ads off: no slot space, no SDK calls', (tester) async {
      final platform = FakeAdsPlatform(consent: testConsent);
      await tester.pumpWidget(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: await seeded(),
          subscriptionRepository: await seededSubscriptions(),
          clock: FixedClock(DateTime(2026, 9, 28)),
          locale: const Locale('en'),
          adsPlatform: platform,
        ),
      );
      await tester.pumpAndSettle();
      await scrollToEnd(tester);
      expect(
        find.byKey(const ValueKey<String>('home-banner-slot')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('home-banner-slot')))
            .height,
        0,
      );
      expect(
        find.byKey(const ValueKey<String>('registry-banner')),
        findsNothing,
      );
      expect(platform.calls, 0);
    });

    testWidgets('test mode shows a sample banner to Free and disposes it', (
      tester,
    ) async {
      final platform = FakeAdsPlatform(consent: testConsent);
      await tester.pumpWidget(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: await seeded(),
          subscriptionRepository: await seededSubscriptions(),
          clock: FixedClock(DateTime(2026, 9, 28)),
          locale: const Locale('en'),
          adsConfig: resolve(),
          adsPlatform: platform,
        ),
      );
      await tester.pumpAndSettle();
      await scrollToEnd(tester);
      expect(
        find.byKey(const ValueKey<String>('registry-banner')),
        findsOneWidget,
      );
      expect(
        platform.bannerRequests.single.unitId,
        GoogleSampleAdIds.androidAdaptiveBanner,
      );
      expect(platform.bannerRequests.single.width, greaterThan(0));
      final dock = find.byKey(const ValueKey<String>('nav-profile'));
      final banner = tester.getRect(
        find.byKey(const ValueKey<String>('registry-banner')),
      );
      expect(banner.bottom, lessThanOrEqualTo(tester.getRect(dock).top));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(platform.banners.single.disposed, isTrue);
    });

    testWidgets('a failed load leaves no empty space', (tester) async {
      final platform = FakeAdsPlatform(
        consent: testConsent,
        bannerLoads: false,
      );
      await tester.pumpWidget(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: await seeded(),
          subscriptionRepository: await seededSubscriptions(),
          clock: FixedClock(DateTime(2026, 9, 28)),
          locale: const Locale('en'),
          adsConfig: resolve(),
          adsPlatform: platform,
        ),
      );
      await tester.pumpAndSettle();
      await scrollToEnd(tester);
      expect(platform.bannerRequests, hasLength(1));
      expect(
        find.byKey(const ValueKey<String>('registry-banner')),
        findsNothing,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('home-banner-slot')))
            .height,
        0,
      );
    });

    testWidgets('Local Pro receives no ad request, even in test mode', (
      tester,
    ) async {
      final platform = FakeAdsPlatform(consent: testConsent);
      final store = FakeLocalProStore(ownership: StoreOwnership.owned);
      await tester.pumpWidget(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: await seeded(),
          subscriptionRepository: await seededSubscriptions(),
          clock: FixedClock(DateTime(2026, 9, 28)),
          locale: const Locale('en'),
          localPro: LocalProEntitlement(purchasesEnabled: true, store: store),
          adsConfig: resolve(),
          adsPlatform: platform,
        ),
      );
      await tester.pumpAndSettle();
      await scrollToEnd(tester);
      expect(
        find.byKey(const ValueKey<String>('registry-banner')),
        findsNothing,
      );
      expect(platform.calls, 0);
      await tester.pumpWidget(const SizedBox());
      await store.close();
    });

    testWidgets('a refund makes a Free user eligible again', (tester) async {
      final platform = FakeAdsPlatform(consent: testConsent);
      final store = FakeLocalProStore(ownership: StoreOwnership.owned);
      final localPro = LocalProEntitlement(
        purchasesEnabled: true,
        store: store,
        clock: MutableClock(DateTime(2026, 9, 28)),
        resumeInterval: Duration.zero,
      );
      await tester.pumpWidget(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: await seeded(),
          subscriptionRepository: await seededSubscriptions(),
          clock: FixedClock(DateTime(2026, 9, 28)),
          locale: const Locale('en'),
          localPro: localPro,
          adsConfig: resolve(),
          adsPlatform: platform,
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.calls, 0);

      store.ownership = StoreOwnership.notOwned;
      await localPro.onResumed();
      await tester.pumpAndSettle();
      await scrollToEnd(tester);
      expect(localPro.plan, RegistryPlan.free);
      expect(platform.consentCalls, 1);
      expect(
        find.byKey(const ValueKey<String>('registry-banner')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await store.close();
    });

    testWidgets('Arabic RTL Home with a test banner has no overflow', (
      tester,
    ) async {
      final platform = FakeAdsPlatform(consent: testConsent);
      await tester.pumpWidget(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: await seeded(),
          subscriptionRepository: await seededSubscriptions(),
          clock: FixedClock(DateTime(2026, 9, 28)),
          locale: const Locale('ar'),
          adsConfig: resolve(),
          adsPlatform: platform,
        ),
      );
      await tester.pumpAndSettle();
      await scrollToEnd(tester);
      expect(
        find.byKey(const ValueKey<String>('registry-banner')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Local Pro copy names the Home banner only in an ads build', (
    tester,
  ) async {
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
        adsConfig: resolve(),
        adsPlatform: FakeAdsPlatform(consent: testConsent),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    await tapProfileControl(tester, const ValueKey<String>('local-pro-open'));
    expect(find.textContaining('one small banner on Home'), findsOneWidget);
    expect(find.textContaining('Ads are off in this version'), findsNothing);
  });

  group('Profile privacy options', () {
    Future<void> openProfile(WidgetTester tester, Widget app) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
      await tester.pumpAndSettle();
    }

    testWidgets('hidden with ads off', (tester) async {
      await openProfile(
        tester,
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          locale: const Locale('en'),
        ),
      );
      expect(
        find.byKey(
          const ValueKey<String>('ads-privacy-options'),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });

    testWidgets('shown when UMP requires it and opens the form', (
      tester,
    ) async {
      final platform = FakeAdsPlatform(
        consent: const AdsConsentState(
          canRequestAds: true,
          privacyOptionsRequired: true,
        ),
      );
      await openProfile(
        tester,
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          locale: const Locale('fr'),
          adsConfig: resolve(),
          adsPlatform: platform,
        ),
      );
      await tapProfileControl(
        tester,
        const ValueKey<String>('ads-privacy-options'),
      );
      expect(platform.privacyCalls, 1);
      expect(find.text('Confidentialité des publicités'), findsOneWidget);
    });
  });
}

class _ThrowingConsentPlatform extends FakeAdsPlatform {
  @override
  Future<AdsConsentState> gatherConsent() async {
    consentCalls += 1;
    throw StateError('consent SDK unavailable');
  }
}
