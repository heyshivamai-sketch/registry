import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/subscriptions/data/detected_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/detected_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/gmail_subscription_detection_service.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_discovery_service.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_controller.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/detected_subscriptions_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscriptions_screen.dart';
import 'package:the_registry/app/navigation/app_routes.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_onboarding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDate = DateTime(2026, 11, 20);
  final clock = FixedClock(testDate);

  late InMemoryDocumentRepository documents;
  late InMemorySubscriptionRepository subscriptions;
  late InMemoryDetectedSubscriptionRepository detectedRepo;
  late SubscriptionDiscoveryService discovery;
  late FakeDatePickerService dates;

  setUp(() {
    documents = InMemoryDocumentRepository();
    subscriptions = InMemorySubscriptionRepository();
    detectedRepo = InMemoryDetectedSubscriptionRepository();
    discovery = SubscriptionDiscoveryService(
      detectedRepository: detectedRepo,
      subscriptionRepository: subscriptions,
    );
    dates = FakeDatePickerService();
  });

  Widget fullApp() {
    return RegistryApp(
      key: UniqueKey(),
      onboardingRepository: FakeOnboardingRepository(completed: true),
      documentRepository: documents,
      subscriptionRepository: subscriptions,
      datePickerService: dates,
      clock: clock,
      locale: const Locale('en'),
      detectedSubscriptionRepository: detectedRepo,
    );
  }

  group('Picking Subscription from Email Tests', () {
    test('extracts billing details from Gmail receipt into subscription candidate', () {
      final detectionService = GmailSubscriptionDetectionService();
      const rawEmail = GmailRawMessage(
        id: 'msg_netflix_123',
        headers: {
          'From': 'Netflix <info@mailer.netflix.com>',
          'Subject': 'Your Netflix monthly membership receipt',
          'Date': '2026-11-10T08:00:00Z',
        },
        snippet: 'Payment of ₹649 for your Netflix Premium plan was successful.',
        plainTextBody: 'Your monthly membership of ₹649 was charged on 10 Nov 2026.',
      );

      final extracted = detectionService.parseMessage(rawEmail);
      expect(extracted, isNotNull);
      expect(extracted!.merchantName, 'Netflix');
      expect(extracted.amount?.minorUnits, 64900);
      expect(extracted.amount?.code, 'INR');
      expect(extracted.billingCycle, BillingCycle.monthly);
      expect(extracted.eventType, GmailEventType.paymentSuccess);
    });

    test('AddSubscriptionController pre-fills correctly from detected candidate', () {
      final candidate = DetectedSubscriptionCandidate(
        id: 'cand-netflix',
        merchantName: 'Netflix',
        amount: const Money(minorUnits: 64900, currencyCode: 'INR'),
        billingCycle: BillingCycle.monthly,
        lastPaymentDate: DateTime(2026, 11, 10),
        nextPaymentDate: DateTime(2026, 12, 10),
        sourceTypes: {DetectionSource.gmail},
        confidenceScore: 0.9,
        createdAt: testDate,
      );

      final controller = AddSubscriptionController(clock: clock);
      controller.prefillCandidate(candidate);

      expect(controller.serviceName, 'Netflix');
      expect(controller.amountText, '649.00');
      expect(controller.currencyCode, 'INR');
      expect(controller.billingCycle, BillingCycle.monthly);
      expect(controller.nextPaymentDate, DateTime(2026, 12, 10));
    });

    testWidgets(
      'Picking candidate from Detected Subscriptions opens pre-filled wizard and saves as active subscription',
      (tester) async {
        tester.view.physicalSize = const Size(412, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Seed a detected candidate from Gmail
        final candidate = DetectedSubscriptionCandidate(
          id: 'cand-gmail-spotify',
          merchantName: 'Spotify Premium',
          amount: const Money(minorUnits: 11900, currencyCode: 'INR'),
          billingCycle: BillingCycle.monthly,
          lastPaymentDate: DateTime(2026, 11, 5),
          nextPaymentDate: DateTime(2026, 12, 5),
          sourceTypes: {DetectionSource.gmail},
          confidenceScore: 0.95,
          createdAt: testDate,
        );
        await detectedRepo.saveCandidates([candidate]);

        await tester.pumpWidget(fullApp());
        await tester.pumpAndSettle();

        // 1. Go to Subscriptions Tab
        await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
        await tester.pumpAndSettle();

        // 2. Open the Detected Subscriptions screen (no Gmail/Discover entry
        // point in v1, so navigate to it directly)
        unawaited(
          AppRoutes.openDetectedSubscriptions(
            tester.element(find.byType(SubscriptionsScreen)),
          ),
        );
        await tester.pumpAndSettle();

        // 3. Verify Detected Subscriptions Screen displays the candidate with Gmail badge
        expect(find.byType(DetectedSubscriptionsScreen), findsOneWidget);
        expect(find.text('Spotify Premium'), findsOneWidget);
        expect(find.text('Gmail'), findsOneWidget);

        // 4. Tap '+ Add' button on the candidate card
        final addButton = find.byKey(const ValueKey<String>('add-candidate-cand-gmail-spotify'));
        expect(addButton, findsOneWidget);
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // 5. Verify Add Subscription wizard is opened and pre-filled with candidate data
        expect(find.byType(AddSubscriptionScreen), findsOneWidget);
        expect(find.text('Spotify Premium'), findsOneWidget);

        // Select category
        await tester.tap(find.byKey(const ValueKey<String>('field-subscription-category')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('sub-category-entertainment')));
        await tester.pumpAndSettle();

        // Continue to Billing step
        await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
        await tester.pumpAndSettle();

        // Billing is pre-filled: 119.00 INR
        expect(find.text('119.00'), findsOneWidget);

        // Continue to Preferences step
        await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
        await tester.pumpAndSettle();

        // Continue to Review step
        await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
        await tester.pumpAndSettle();

        // Save subscription
        await tester.tap(find.byKey(const ValueKey<String>('save-subscription')));
        await tester.pumpAndSettle();

        // 6. Verify subscription is saved in repository as active
        expect(subscriptions.subscriptions.length, 1);
        final savedSub = subscriptions.subscriptions.first;
        expect(savedSub.serviceName, 'Spotify Premium');
        expect(savedSub.isActive, isTrue);
        expect(savedSub.amount.minorUnits, 11900);
        expect(savedSub.amount.code, 'INR');

        // 7. Verify candidate is now accepted and no longer in pending list
        expect(discovery.pendingCandidates, isEmpty);
      },
    );
  });
}
