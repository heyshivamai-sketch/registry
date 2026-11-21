import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_calendar_view.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/sample_subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDate = DateTime(2026, 11, 15);
  final clock = FixedClock(testDate);

  late InMemoryDocumentRepository documents;
  late InMemorySubscriptionRepository subscriptions;
  late FakeDatePickerService dates;

  setUp(() {
    documents = InMemoryDocumentRepository();
    subscriptions = InMemorySubscriptionRepository();
    dates = FakeDatePickerService();
  });

  Widget createCalendarWidget({
    required List<RegistrySubscription> subs,
    DateTime? now,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SubscriptionCalendarView(
            subscriptions: subs,
            now: now ?? testDate,
          ),
        ),
      ),
    );
  }

  Widget fullApp() {
    return RegistryApp(
      key: UniqueKey(),
      onboardingRepository: FakeOnboardingRepository(completed: true),
      documentRepository: documents,
      subscriptionRepository: subscriptions,
      datePickerService: dates,
      clock: clock,
      locale: const Locale('en'),
    );
  }

  group('SubscriptionCalendarView Unit & Widget Tests', () {
    testWidgets('renders month header, weekday names, and day cells', (
      tester,
    ) async {
      await tester.pumpWidget(createCalendarWidget(subs: []));
      await tester.pumpAndSettle();

      expect(find.text('November'), findsOneWidget);
      for (final day in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']) {
        expect(find.text(day), findsOneWidget);
      }
      expect(find.textContaining('Total'), findsOneWidget);
      expect(find.textContaining('Upcoming'), findsOneWidget);
    });

    testWidgets(
      'displays only active subscriptions on calendar; inactive are excluded',
      (tester) async {
        final activeNetflix = sampleSubscription(
          id: 'sub-active',
          serviceName: 'Netflix',
          minorUnits: 64900,
          currencyCode: 'INR',
          billingCycle: BillingCycle.monthly,
          nextPaymentDate: DateTime(2026, 11, 20),
          lifecycle: SubscriptionLifecycle.active,
        );

        final cancelledSpotify = sampleSubscription(
          id: 'sub-cancelled',
          serviceName: 'Spotify',
          minorUnits: 11900,
          currencyCode: 'INR',
          billingCycle: BillingCycle.monthly,
          nextPaymentDate: DateTime(2026, 11, 20),
          lifecycle: SubscriptionLifecycle.cancelled,
        );

        await tester.pumpWidget(
          createCalendarWidget(
            subs: [activeNetflix, cancelledSpotify],
            now: testDate,
          ),
        );
        await tester.pumpAndSettle();

        // Active Netflix should be shown on the cell
        expect(find.text('Netflix'), findsOneWidget);
        // Cancelled Spotify must NOT be shown
        expect(find.text('Spotify'), findsNothing);
      },
    );

    testWidgets('month navigation (< and >) shifts focused month', (
      tester,
    ) async {
      await tester.pumpWidget(createCalendarWidget(subs: [], now: testDate));
      await tester.pumpAndSettle();

      expect(find.text('November'), findsOneWidget);

      // Tap next month
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text('December'), findsOneWidget);

      // Tap prev month twice
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      expect(find.text('November'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      expect(find.text('October'), findsOneWidget);
    });

    testWidgets(
      'tapping a day cell opens day drawer with due subscriptions details',
      (tester) async {
        final prime = sampleSubscription(
          id: 'sub-prime',
          serviceName: 'Amazon Prime',
          minorUnits: 149900,
          currencyCode: 'INR',
          billingCycle: BillingCycle.monthly,
          nextPaymentDate: DateTime(2026, 11, 16),
          lifecycle: SubscriptionLifecycle.active,
        );

        await tester.pumpWidget(
          createCalendarWidget(
            subs: [prime],
            now: DateTime(2026, 11, 15),
          ),
        );
        await tester.pumpAndSettle();

        // Tap day 16 cell
        final day16 = find.text('16');
        expect(day16, findsOneWidget);
        await tester.tap(day16);
        await tester.pumpAndSettle();

        // Drawer should display Prime details
        expect(find.text('Due on November 16, 2026'), findsOneWidget);
        expect(find.text('Amazon Prime'), findsWidgets);
        expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
      },
    );

    testWidgets(
      'calculates Total and Upcoming monthly spend accurately',
      (tester) async {
        // Now is Nov 15
        // Past in November: Nov 5 (already paid, counted in Total, not in Upcoming)
        final subPast = sampleSubscription(
          id: 'sub-past',
          serviceName: 'Google One',
          minorUnits: 13000,
          currencyCode: 'INR',
          billingCycle: BillingCycle.monthly,
          nextPaymentDate: DateTime(2026, 11, 5),
          lifecycle: SubscriptionLifecycle.active,
        );

        // Upcoming in November: Nov 25 (counted in both Total and Upcoming)
        final subFuture = sampleSubscription(
          id: 'sub-future',
          serviceName: 'YouTube Premium',
          minorUnits: 14900,
          currencyCode: 'INR',
          billingCycle: BillingCycle.monthly,
          nextPaymentDate: DateTime(2026, 11, 25),
          lifecycle: SubscriptionLifecycle.active,
        );

        await tester.pumpWidget(
          createCalendarWidget(
            subs: [subPast, subFuture],
            now: DateTime(2026, 11, 15),
          ),
        );
        await tester.pumpAndSettle();

        // Total should include both: 130 + 149 = 279
        expect(find.textContaining('279.00'), findsOneWidget);
        // Upcoming should only include subFuture: 149
        expect(find.textContaining('149.00'), findsOneWidget);
      },
    );
  });

  group('SubscriptionsScreen Calendar Toggle Integration', () {
    testWidgets('toggles between list view and calendar view on icon tap', (
      tester,
    ) async {
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

      await tester.pumpWidget(fullApp());
      await tester.pumpAndSettle();

      // Navigate to Subscriptions tab using nav key
      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await tester.pumpAndSettle();

      // Initially in list view: search field and cards exist
      expect(
        find.byKey(const ValueKey<String>('subscriptions-search')),
        findsOneWidget,
      );
      expect(find.byType(SubscriptionCalendarView), findsNothing);

      // Tap calendar toggle icon in header
      final toggleBtn =
          find.byKey(const ValueKey<String>('subscriptions-calendar-toggle'));
      expect(toggleBtn, findsOneWidget);
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      // Now calendar view should be active
      expect(find.byType(SubscriptionCalendarView), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('subscriptions-search')),
        findsNothing,
      );

      // Tap again to toggle back to list view
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionCalendarView), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('subscriptions-search')),
        findsOneWidget,
      );
    });
  });
}
