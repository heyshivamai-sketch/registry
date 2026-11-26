import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
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

  Future<void> openSubscriptions(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();
  }

  void expectNoGmailEntryPoints() {
    expect(find.textContaining('Gmail'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('subscriptions-connect-gmail')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('subscriptions-connect-gmail-bottom')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('subscriptions-connect-gmail-calendar'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('subscriptions-discover')),
      findsNothing,
    );
  }

  testWidgets('empty state offers Add Subscription and no Gmail entry point', (
    tester,
  ) async {
    await openSubscriptions(tester);

    expect(find.byType(SubscriptionsScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('subscriptions-empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('subscriptions-add')),
      findsOneWidget,
    );
    expectNoGmailEntryPoints();
  });

  testWidgets('list with subscriptions has no Gmail entry point', (
    tester,
  ) async {
    await subscriptions.save(
      sampleSubscription(
        id: 'sub-netflix',
        serviceName: 'Netflix',
        lifecycle: SubscriptionLifecycle.active,
      ),
    );

    await openSubscriptions(tester);

    expect(
      find.byKey(const ValueKey<String>('subscriptions-empty')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('subscriptions-add')),
      findsOneWidget,
    );
    expectNoGmailEntryPoints();
  });

  testWidgets('calendar view has Add Subscription and no Gmail entry point', (
    tester,
  ) async {
    await openSubscriptions(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('subscriptions-calendar-toggle')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('subscriptions-add-calendar')),
      findsOneWidget,
    );
    expectNoGmailEntryPoints();
  });
}
