// Device QA for the ads-off launch build.
//
// Run only on an isolated emulator or simulator, with no ads defines:
//   flutter test integration_test/launch_ads_off_qa_test.dart -d <isolated device>
//
// The real Google Mobile Ads platform is handed to the app on purpose, so the
// test proves the ads-off config alone keeps every ad and consent call away.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/ads/ads_config.dart';
import 'package:the_registry/features/ads/ads_platform.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';

import '../test/support/fake_onboarding_repository.dart';
import '../test/support/sample_document.dart';
import '../test/support/sample_subscription.dart';

class _RecordingAdsPlatform implements AdsPlatform {
  _RecordingAdsPlatform(this._inner);

  final AdsPlatform _inner;
  final calls = <String>[];

  @override
  Future<AdsConsentState> gatherConsent() {
    calls.add('gatherConsent');
    return _inner.gatherConsent();
  }

  @override
  Future<void> initialize() {
    calls.add('initialize');
    return _inner.initialize();
  }

  @override
  Future<AdsConsentState> showPrivacyOptions() {
    calls.add('showPrivacyOptions');
    return _inner.showPrivacyOptions();
  }

  @override
  Future<LoadedBanner?> loadBanner({
    required String unitId,
    required int width,
  }) {
    calls.add('loadBanner');
    return _inner.loadBanner(unitId: unitId, width: width);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ads-off build: no ad or consent calls, no ad slot', (
    tester,
  ) async {
    final ads = AdsConfig.fromEnvironment();
    expect(ads.mode, AdsMode.off, reason: 'Run without ads defines.');
    expect(ads.enabled, isFalse);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await documents.save(sampleDocument(id: 'passport', name: 'Passport'));
    await subscriptions.save(
      sampleSubscription(id: 'gym', serviceName: 'Gym membership'),
    );
    final platform = _RecordingAdsPlatform(const GoogleMobileAdsPlatform());
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        documentRepository: documents,
        subscriptionRepository: subscriptions,
        clock: FixedClock(DateTime(2026, 9, 28)),
        locale: const Locale('en'),
        adsConfig: ads,
        adsPlatform: platform,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find
          .descendant(
            of: find.byType(HomeScreen),
            matching: find.byType(Scrollable),
          )
          .first,
      const Offset(0, -3000),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    final slot = find.byKey(const ValueKey<String>('home-banner-slot'));
    expect(slot, findsOneWidget);
    expect(tester.getSize(slot).height, 0);
    expect(find.byKey(const ValueKey<String>('registry-banner')), findsNothing);
    debugPrint('LAUNCH_QA:ads_off_home_slot_height_0');

    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('ads-privacy-section')),
      findsNothing,
    );

    expect(platform.calls, isEmpty);
    debugPrint('LAUNCH_QA:ads_off_platform_calls=${platform.calls.length}');
  });
}
