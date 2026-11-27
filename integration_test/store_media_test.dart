// Store media walkthrough for Google Play and YouTube.
//
// Drives the real app on a 1080x1920 device through the main screens. Each
// scene holds with a slow, steady scroll so the screen recording shows smooth
// motion, saves a still, and logs a PROMO:<scene> marker that
// tool/store_media/record_promo.py uses to line up the narration.
//
// Uses in-memory repositories only, so nothing is written to the device database.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/documents/presentation/document_detail_screen.dart';
import 'package:the_registry/features/documents/presentation/documents_screen.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/subscriptions_screen.dart';
import '../test/support/fake_onboarding_repository.dart';
import '../test/support/sample_document.dart';
import '../test/support/sample_subscription.dart';

/// First scrollable inside a screen, or null if the screen isn't on stage.
Finder _scrollIn(Type screen) {
  return find.descendant(of: find.byType(screen), matching: find.byType(Scrollable));
}

Future<void> _scene(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String name, {
  required Duration hold,
  Finder? scroll,
}) async {
  await tester.pumpAndSettle();
  debugPrint('PROMO:$name');

  // Hold in small steps. A slow drift keeps the recording moving; a static
  // screen would be recorded as a few frames. The drift moves the scroll
  // position directly instead of sending a drag, so no card gets tapped.
  const steps = 40;
  final stepDelay = Duration(milliseconds: hold.inMilliseconds ~/ steps);
  for (var i = 0; i < steps; i++) {
    if (scroll != null && scroll.evaluate().isNotEmpty) {
      final position = tester.state<ScrollableState>(scroll.first).position;
      final target = (position.pixels + 6)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      position.jumpTo(target);
    }
    await Future<void>.delayed(stepDelay);
    await tester.pump();
  }

  // Android needs the Flutter surface converted before a screenshot is taken.
  await binding.convertFlutterSurfaceToImage();
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
  await tester.pump();
}

Future<void> _seed(
  InMemoryDocumentRepository documents,
  InMemorySubscriptionRepository subscriptions,
) async {
  await documents.save(
    sampleDocument(
      id: 'passport',
      name: 'Passport',
      ownerName: 'Amina Laurent',
      issuingAuthority: 'France',
      countryCode: 'FR',
      category: DocumentCategory.passport,
      expiryDate: DateTime(2026, 12, 10),
      actionDate: DateTime(2026, 11, 24),
    ),
  );
  await documents.save(
    sampleDocument(
      id: 'insurance',
      name: 'Car insurance',
      ownerName: 'Amina Laurent',
      issuingAuthority: 'Allianz',
      category: DocumentCategory.insurance,
      expiryDate: DateTime(2027, 1, 20),
      actionDate: DateTime(2026, 12, 20),
    ),
  );
  await documents.save(
    sampleDocument(
      id: 'licence',
      name: 'Driving licence',
      ownerName: 'Amina Laurent',
      issuingAuthority: 'France',
      category: DocumentCategory.drivingLicence,
      expiryDate: DateTime(2030, 6, 1),
    ),
  );
  await subscriptions.save(
    sampleSubscription(
      id: 'streaming',
      serviceName: 'Streaming',
      category: SubscriptionCategory.entertainment,
      minorUnits: 1599,
      nextPaymentDate: DateTime(2026, 12, 3),
      decideByDate: DateTime(2026, 11, 26),
    ),
  );
  await subscriptions.save(
    sampleSubscription(
      id: 'cloud',
      serviceName: 'Cloud storage',
      category: SubscriptionCategory.cloudStorage,
      minorUnits: 299,
      nextPaymentDate: DateTime(2026, 12, 14),
      decideByDate: DateTime(2026, 12, 7),
    ),
  );
  await subscriptions.save(
    sampleSubscription(
      id: 'gym',
      serviceName: 'Gym membership',
      category: SubscriptionCategory.healthFitness,
      minorUnits: 4500,
      currencyCode: 'EUR',
      billingCycle: BillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 12, 28),
      decideByDate: DateTime(2026, 12, 21),
    ),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;
  final clock = FixedClock(DateTime(2026, 11, 27));

  testWidgets('store media walkthrough', (tester) async {
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seed(documents, subscriptions);

    await tester.pumpWidget(
      RegistryApp(
        key: const ValueKey<String>('store-media'),
        onboardingRepository: FakeOnboardingRepository(completed: true),
        documentRepository: documents,
        subscriptionRepository: subscriptions,
        clock: clock,
        locale: const Locale('en'),
      ),
    );
    await _scene(
      tester,
      binding,
      '01_home',
      hold: const Duration(seconds: 7),
      scroll: _scrollIn(HomeScreen),
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await _scene(
      tester,
      binding,
      '02_documents',
      hold: const Duration(seconds: 6),
      scroll: _scrollIn(DocumentsScreen),
    );

    await tester.tap(find.text('Passport').first);
    await _scene(
      tester,
      binding,
      '03_document_detail',
      hold: const Duration(seconds: 7),
      scroll: _scrollIn(DocumentDetailScreen),
    );
    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final documentsList = _scrollIn(DocumentsScreen).first;
    final documentsAdd = find.byKey(const ValueKey<String>('documents-add'));
    await tester.scrollUntilVisible(documentsAdd, 300, scrollable: documentsList);
    await tester.pumpAndSettle();
    await tester.tap(documentsAdd);
    await _scene(
      tester,
      binding,
      '04_add_document',
      hold: const Duration(seconds: 6),
      scroll: _scrollIn(AddDocumentScreen),
    );
    expect(find.byType(AddDocumentScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await _scene(
      tester,
      binding,
      '05_subscriptions',
      hold: const Duration(seconds: 6),
      scroll: _scrollIn(SubscriptionsScreen),
    );

    // Return to the top, where the List/Calendar toggle lives.
    final subscriptionsPosition =
        tester.state<ScrollableState>(_scrollIn(SubscriptionsScreen).first).position;
    subscriptionsPosition.jumpTo(subscriptionsPosition.minScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('subscriptions-calendar-toggle')));
    await _scene(
      tester,
      binding,
      '06_calendar',
      hold: const Duration(seconds: 7),
      scroll: _scrollIn(SubscriptionsScreen),
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await _scene(
      tester,
      binding,
      '07_profile',
      hold: const Duration(seconds: 6),
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await _scene(
      tester,
      binding,
      '08_home_end',
      hold: const Duration(seconds: 3),
    );
    expect(find.byType(AppShell), findsOneWidget);
  });
}
