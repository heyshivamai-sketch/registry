import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/gmail_connect_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscriptions_screen.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/sample_subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final clock = FixedClock(DateTime(2026, 9, 19));
  late InMemoryDocumentRepository documents;
  late InMemorySubscriptionRepository subscriptions;

  Widget app({Locale locale = const Locale('en')}) {
    return RegistryApp(
      key: UniqueKey(),
      onboardingRepository: FakeOnboardingRepository(completed: true),
      documentRepository: documents,
      subscriptionRepository: subscriptions,
      clock: clock,
      locale: locale,
    );
  }

  setUp(() {
    documents = InMemoryDocumentRepository();
    subscriptions = InMemorySubscriptionRepository();
  });

  testWidgets(
    'empty state shows Add Subscription and Connect from Gmail just below it, tapping navigates to GmailConnectScreen',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionsScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('subscriptions-empty')),
        findsOneWidget,
      );

      final addBtn = find.byKey(const ValueKey<String>('subscriptions-add'));
      final gmailBtn =
          find.byKey(const ValueKey<String>('subscriptions-connect-gmail'));

      expect(addBtn, findsOneWidget);
      expect(gmailBtn, findsOneWidget);
      expect(find.text('Connect from Gmail'), findsOneWidget);

      // Verify Connect from Gmail is rendered below Add Subscription button
      final addOffset = tester.getBottomLeft(addBtn);
      final gmailOffset = tester.getTopLeft(gmailBtn);
      expect(gmailOffset.dy, greaterThan(addOffset.dy));

      // Tap Connect from Gmail and verify it opens GmailConnectScreen
      await tester.tap(gmailBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GmailConnectScreen), findsOneWidget);
    },
  );

  testWidgets(
    'list with subscriptions shows Connect from Gmail below Add Subscription button at bottom',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final netflix = sampleSubscription(
        id: 'sub-netflix',
        serviceName: 'Netflix',
        lifecycle: SubscriptionLifecycle.active,
      );
      await subscriptions.save(netflix);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('subscriptions-empty')),
        findsNothing,
      );

      final addBtn = find.byKey(const ValueKey<String>('subscriptions-add'));
      final gmailBottomBtn = find.byKey(
        const ValueKey<String>('subscriptions-connect-gmail-bottom'),
      );

      expect(addBtn, findsOneWidget);
      expect(gmailBottomBtn, findsOneWidget);
      expect(find.text('Connect from Gmail'), findsOneWidget);

      final addOffset = tester.getBottomLeft(addBtn);
      final gmailOffset = tester.getTopLeft(gmailBottomBtn);
      expect(gmailOffset.dy, greaterThan(addOffset.dy));

      await tester.tap(gmailBottomBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GmailConnectScreen), findsOneWidget);
    },
  );

  testWidgets(
    'calendar view shows Connect from Gmail below Add Subscription button',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await tester.pumpAndSettle();

      // Switch to calendar view
      await tester.tap(
        find.byKey(const ValueKey<String>('subscriptions-calendar-toggle')),
      );
      await tester.pumpAndSettle();

      final addCalendarBtn =
          find.byKey(const ValueKey<String>('subscriptions-add-calendar'));
      final gmailCalendarBtn = find.byKey(
        const ValueKey<String>('subscriptions-connect-gmail-calendar'),
      );

      expect(addCalendarBtn, findsOneWidget);
      expect(gmailCalendarBtn, findsOneWidget);

      final addOffset = tester.getBottomLeft(addCalendarBtn);
      final gmailOffset = tester.getTopLeft(gmailCalendarBtn);
      expect(gmailOffset.dy, greaterThan(addOffset.dy));

      await tester.tap(gmailCalendarBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GmailConnectScreen), findsOneWidget);
    },
  );
}
