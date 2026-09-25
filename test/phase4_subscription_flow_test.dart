import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/home/widgets/home_attention_card.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/features/home/widgets/priority_hero_card.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_detail_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscriptions_screen.dart';
import 'package:the_registry/features/subscriptions/widgets/subscription_list_card.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/sample_subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final clock = FixedClock(DateTime(2026, 9, 19));
  late InMemoryDocumentRepository documents;
  late InMemorySubscriptionRepository subscriptions;
  late FakeDatePickerService dates;

  Widget app({Locale locale = const Locale('en')}) {
    return RegistryApp(
      key: UniqueKey(),
      onboardingRepository: FakeOnboardingRepository(completed: true),
      documentRepository: documents,
      subscriptionRepository: subscriptions,
      datePickerService: dates,
      clock: clock,
      locale: locale,
    );
  }

  setUp(() {
    documents = InMemoryDocumentRepository();
    subscriptions = InMemorySubscriptionRepository();
    dates = FakeDatePickerService();
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openWizard(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-subscription')));
    await tester.pumpAndSettle();
  }

  Future<void> addPlan(
    WidgetTester tester, {
    required String name,
    required String category,
    required String amount,
    required String currency,
    required Key cycle,
    required DateTime nextPayment,
    DateTime? decideBy,
  }) async {
    dates.results['next-payment'] = nextPayment;
    dates.results['decide-by'] = decideBy;
    await openWizard(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-service-name')),
      name,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('field-subscription-category')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(category));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-amount')),
      amount,
    );
    await tester.tap(find.byKey(const ValueKey<String>('field-currency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(currency));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(cycle));
    await tester.tap(find.byKey(const ValueKey<String>('date-next-payment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    if (decideBy != null) {
      await tester.tap(find.byKey(const ValueKey<String>('date-decide-by')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey<String>('sub-impact-low')));
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-subscription')));
    await tester.pumpAndSettle();
  }

  testWidgets('mixed-currency plans keep separate totals and unique ids', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await addPlan(
      tester,
      name: 'Monthly Test',
      category: 'Entertainment',
      amount: '12.00',
      currency: 'USD',
      cycle: const ValueKey<String>('cycle-monthly'),
      nextPayment: DateTime(2026, 9, 29),
      decideBy: DateTime(2026, 9, 19),
    );
    await addPlan(
      tester,
      name: 'Annual Test',
      category: 'Productivity',
      amount: '120.00',
      currency: 'USD',
      cycle: const ValueKey<String>('cycle-yearly'),
      nextPayment: DateTime(2026, 10, 19),
      decideBy: DateTime(2026, 10, 9),
    );
    await addPlan(
      tester,
      name: 'Euro Test',
      category: 'Other',
      amount: '9.00',
      currency: 'EUR',
      cycle: const ValueKey<String>('cycle-monthly'),
      nextPayment: DateTime(2026, 10, 4),
    );

    expect(subscriptions.subscriptions, hasLength(3));
    expect(
      subscriptions.subscriptions.map((item) => item.id).toSet(),
      hasLength(3),
    );
    expect(find.text('22.00 USD'), findsWidgets);
    expect(find.text('9.00 EUR'), findsWidgets);
    expect(find.textContaining('31.00'), findsNothing);
    expect(find.textContaining('Pause'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('9.00 EUR'), findsWidgets);
    expect(find.text('22.00 USD'), findsWidgets);
    expect(find.byType(PriorityHeroCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PriorityHeroCard),
        matching: find.textContaining('Monthly Test'),
      ),
      findsOneWidget,
    );
    expect(find.byType(HomeAttentionCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeUpcomingItem),
        matching: find.text('Monthly Test'),
      ),
      findsNothing,
    );

    final monthly = subscriptions.subscriptions.firstWhere(
      (item) => item.serviceName == 'Monthly Test',
    );
    expect(monthly.lifecycle, SubscriptionLifecycle.active);
  });

  testWidgets('last subscription card stays tappable above the dock', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final scale in <double>[1.0, 1.5, 1.8]) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      subscriptions = InMemorySubscriptionRepository();
      for (var index = 0; index < 6; index++) {
        await subscriptions.save(
          sampleSubscription(
            id: 'sub_$index',
            serviceName:
                'Reachable plan $index with a wrapping title for dock QA',
            planName: 'Enterprise collaboration suite wrapping onto two lines',
          ),
        );
      }
      await phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await tester.pumpAndSettle();

      final last = find.byKey(const ValueKey<String>('sub_5'));
      final scrollable = find.descendant(
        of: find.byType(SubscriptionsScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(last, 90, scrollable: scrollable.first);
      await tester.pumpAndSettle();

      var card = tester.getRect(last);
      final dock = tester.getRect(
        find.byKey(const ValueKey<String>('nav-dock')),
      );
      if (card.bottom > dock.top) {
        await tester.drag(
          scrollable.first,
          Offset(0, -(card.bottom - dock.top + 24)),
        );
        await tester.pumpAndSettle();
        card = tester.getRect(last);
      }

      expect(
        card.bottom,
        lessThanOrEqualTo(dock.top + 1),
        reason: 'last card still under dock at ${scale}x',
      );
      expect(last.hitTestable(), findsOneWidget, reason: '${scale}x');
    }
  });

  testWidgets('single wrapping subscription card clears the dock at 1.8x', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    await subscriptions.save(
      sampleSubscription(
        id: 'solo_wrap',
        serviceName: 'Reachable plan with a wrapping title for dock QA',
        planName: 'Enterprise collaboration suite wrapping onto two lines',
      ),
    );
    await phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();

    final cardFinder = find.byKey(const ValueKey<String>('solo_wrap'));
    final scrollable = find.descendant(
      of: find.byType(SubscriptionsScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      cardFinder,
      90,
      scrollable: scrollable.first,
    );
    await tester.pumpAndSettle();

    var card = tester.getRect(cardFinder);
    final dock = tester.getRect(find.byKey(const ValueKey<String>('nav-dock')));
    if (card.bottom > dock.top) {
      await tester.drag(
        scrollable.first,
        Offset(0, -(card.bottom - dock.top + 24)),
      );
      await tester.pumpAndSettle();
      card = tester.getRect(cardFinder);
    }

    expect(card.bottom, lessThanOrEqualTo(dock.top + 1));
    expect(cardFinder.hitTestable(), findsOneWidget);

    await tester.tap(cardFinder);
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
  });

  test('attention copy stays natural in English, French, and Arabic', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));
    final ar = lookupAppLocalizations(const Locale('ar'));

    expect(en.subscriptionsAttentionSummary(0), 'No decisions due');
    expect(en.subscriptionsAttentionSummary(1), '1 decision due');
    expect(en.subscriptionsAttentionSummary(3), '3 decisions due');

    expect(fr.subscriptionsAttentionSummary(0), 'Aucune décision à prendre');
    expect(fr.subscriptionsAttentionSummary(1), '1 décision à prendre');
    expect(fr.subscriptionsAttentionSummary(3), '3 décisions à prendre');

    expect(ar.subscriptionsAttentionSummary(0), 'لا قرارات مستحقة');
    expect(ar.subscriptionsAttentionSummary(1), 'قرار واحد مستحق');
    expect(ar.subscriptionsAttentionSummary(3), '3 قرارات مستحقة');
  });

  testWidgets('French attention summary uses natural wording', (tester) async {
    await phone(tester);
    await subscriptions.save(
      sampleSubscription(
        nextPaymentDate: DateTime(2026, 9, 29),
        decideByDate: DateTime(2026, 9, 19),
      ),
    );
    await tester.pumpWidget(app(locale: const Locale('fr')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();
    expect(find.text('1 décision à prendre'), findsOneWidget);
    expect(find.textContaining('décision due'), findsNothing);
  });

  testWidgets('save snackbar stays above the navigation dock', (tester) async {
    await phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    dates.results['next-payment'] = DateTime(2026, 10, 4);
    await openWizard(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-service-name')),
      'Streamio',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('field-subscription-category')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entertainment'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-amount')),
      '12.99',
    );
    await tester.tap(find.byKey(const ValueKey<String>('field-currency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('cycle-monthly')));
    await tester.tap(find.byKey(const ValueKey<String>('date-next-payment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-impact-low')));
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-subscription')));
    await tester.pumpAndSettle();

    expect(find.text('Subscription saved on this device.'), findsOneWidget);
    final message = tester.getRect(
      find.text('Subscription saved on this device.'),
    );
    final fab = tester.getRect(find.byKey(const ValueKey<String>('home-fab')));
    expect(message.bottom, lessThanOrEqualTo(fab.top + 1));
    expect(
      find.byKey(const ValueKey<String>('nav-subscriptions')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('save snackbar stays clear of the dock at large text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await phone(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    dates.results['next-payment'] = DateTime(2026, 10, 4);
    await openWizard(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-service-name')),
      'Streamio',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('field-subscription-category')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entertainment'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-amount')),
      '12.99',
    );
    await tester.tap(find.byKey(const ValueKey<String>('field-currency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('cycle-monthly')));
    await tester.tap(find.byKey(const ValueKey<String>('date-next-payment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-impact-low')));
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-subscription')));
    await tester.pumpAndSettle();

    final message = tester.getRect(
      find.text('Subscription saved on this device.'),
    );
    final fab = tester.getRect(find.byKey(const ValueKey<String>('home-fab')));
    expect(message.bottom, lessThanOrEqualTo(fab.top + 1));
    expect(
      find.byKey(const ValueKey<String>('nav-home')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('long service names stay available on detail and semantics', (
    tester,
  ) async {
    const longName =
        'North Atlantic Collaborative Streaming Service With Extra Words';
    await phone(tester);
    await subscriptions.save(
      sampleSubscription(id: 'long-name', serviceName: longName),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();

    final card = find.byType(SubscriptionListCard);
    expect(tester.getSemantics(card.first).label, contains(longName));

    await tester.tap(find.byKey(const ValueKey<String>('long-name')));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SubscriptionDetailScreen),
        matching: find.text(longName),
      ),
      findsWidgets,
    );
  });

  testWidgets('Arabic populated list stays RTL', (tester) async {
    await phone(tester);
    await tester.pumpWidget(app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(AppShell))),
      TextDirection.rtl,
    );
  });
}
