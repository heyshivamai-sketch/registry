import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
import 'support/sample_subscription.dart';
import 'support/save_screenshot.dart';

const _folder = 'aura_home_redesign';
final _clock = FixedClock(DateTime(2026, 9, 19));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Aura Home redesign evidence screenshots', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      wrapForScreenshot(
        RegistryApp(
          key: const ValueKey<String>('home-shot-empty'),
          onboardingRepository: FakeOnboardingRepository(completed: true),
          clock: _clock,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'flutter_empty_home',
      folder: _folder,
      pixelRatio: 2,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'flutter_empty_home_bottom',
      folder: _folder,
      pixelRatio: 2,
    );

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await documents.save(
      sampleDocument(
        id: 'insurance',
        name: 'Car insurance',
        category: DocumentCategory.insurance,
        actionDate: DateTime(2026, 9, 19),
        expiryDate: DateTime(2026, 10, 5),
      ),
    );
    await documents.save(
      sampleDocument(
        id: 'passport',
        name: 'Passport',
        actionDate: DateTime(2026, 10, 12),
        expiryDate: DateTime(2026, 11, 12),
      ),
    );
    await subscriptions.save(
      sampleSubscription(
        id: 'stream',
        serviceName: 'Streaming',
        minorUnits: 1200,
        nextPaymentDate: DateTime(2026, 9, 24),
        decideByDate: DateTime(2026, 9, 24),
      ),
    );
    await subscriptions.save(
      sampleSubscription(
        id: 'gym',
        serviceName: 'Gym membership',
        minorUnits: 900,
        currencyCode: 'EUR',
        nextPaymentDate: DateTime(2026, 9, 28),
        decideByDate: DateTime(2026, 9, 28),
      ),
    );

    await tester.pumpWidget(
      wrapForScreenshot(
        RegistryApp(
          key: const ValueKey<String>('home-shot-populated'),
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: documents,
          subscriptionRepository: subscriptions,
          clock: _clock,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'flutter_populated_top',
      folder: _folder,
      pixelRatio: 2,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'flutter_attention_coming_up',
      folder: _folder,
      pixelRatio: 2,
    );

    await tester.pumpWidget(
      wrapForScreenshot(
        RegistryApp(
          key: const ValueKey<String>('home-shot-arabic'),
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: documents,
          subscriptionRepository: subscriptions,
          clock: _clock,
          locale: const Locale('ar'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'flutter_arabic_populated',
      folder: _folder,
      pixelRatio: 2,
    );

    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      wrapForScreenshot(
        RegistryApp(
          key: const ValueKey<String>('home-shot-large'),
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: documents,
          subscriptionRepository: subscriptions,
          clock: _clock,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'flutter_populated_large_text',
      folder: _folder,
      pixelRatio: 2,
    );
  });
}
