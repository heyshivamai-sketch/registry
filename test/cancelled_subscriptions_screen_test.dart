import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/cancelled_subscriptions_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_detail_screen.dart';

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
    'CancelledSubscriptionsScreen shows empty state when no subscriptions are cancelled',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('subscriptions-cancelled-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CancelledSubscriptionsScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('cancelled-subscriptions-empty')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Cancelled subscription appears on CancelledSubscriptionsScreen and can be opened',
    (tester) async {
      await subscriptions.save(
        sampleSubscription(
          id: 'sub-gym',
          serviceName: 'Fitness Club',
          planName: 'Gold Plan',
          category: SubscriptionCategory.healthFitness,
          lifecycle: SubscriptionLifecycle.cancelled,
          updatedAt: DateTime(2026, 9, 15),
        ),
      );

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('subscriptions-cancelled-link')),
        findsOneWidget,
      );
      expect(find.text('1 cancelled plan'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey<String>('subscriptions-cancelled-link')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CancelledSubscriptionsScreen), findsOneWidget);
      expect(find.text('Fitness Club'), findsOneWidget);
      expect(find.text('Gold Plan'), findsOneWidget);

      await tester.tap(find.text('Fitness Club'));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
      expect(find.text('Reactivate'), findsOneWidget);
    },
  );
}
