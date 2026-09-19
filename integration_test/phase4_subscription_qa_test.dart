import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/home/widgets/home_attention_card.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/features/home/widgets/priority_hero_card.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_detail_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscriptions_screen.dart';

import '../test/support/fake_onboarding_repository.dart';

Future<void> settleShort(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Phase 4 live subscription QA on device',
    (tester) async {
      final harness = _Harness(tester);
      await harness.launch();
      final today = harness.today;

      await harness.openAddFromFab();
      await harness.continueWizard();
      expect(find.text('This field is required.'), findsWidgets);

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-service-name')),
        'Draft',
      );
      await tester.pump();
      await tester.showKeyboard(
        find.byKey(const ValueKey<String>('field-service-name')),
      );
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await settleShort(tester);

      await tester.tap(find.byType(BackButton));
      await settleShort(tester);
      expect(find.text('Discard this draft?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await settleShort(tester);
      expect(find.byType(AddSubscriptionScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settleShort(tester);
      await tester.tap(find.byKey(const ValueKey<String>('discard-confirm')));
      await settleShort(tester);

      await harness.addPlan(
        name: 'Monthly Test',
        categoryKey: 'sub-category-entertainment',
        amount: '12.00',
        currency: 'USD',
        cycle: 'cycle-monthly',
        nextPayment: DateTime(today.year, today.month, today.day + 10),
        decideBy: today,
        captureReviewAs: 'review_before_save',
      );
      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await settleShort(tester);
      await harness.addPlan(
        name: 'Annual Test',
        categoryKey: 'sub-category-productivity',
        amount: '120.00',
        currency: 'USD',
        cycle: 'cycle-yearly',
        nextPayment: DateTime(today.year, today.month, today.day + 30),
        decideBy: DateTime(today.year, today.month, today.day + 20),
        planName:
            'Enterprise collaboration suite that wraps onto two lines for QA',
      );
      await harness.addPlan(
        name: 'Euro Test',
        categoryKey: 'sub-category-other',
        amount: '9.00',
        currency: 'EUR',
        cycle: 'cycle-monthly',
        nextPayment: DateTime(today.year, today.month, today.day + 15),
      );

      final repo = harness.repo;
      expect(repo.subscriptions, hasLength(3));
      expect(repo.subscriptions.map((item) => item.id).toSet(), hasLength(3));
      final monthlyId = harness.named('Monthly Test').id;
      expect(find.text('22.00 USD'), findsWidgets);
      expect(find.text('9.00 EUR'), findsWidgets);
      expect(find.textContaining('31.00'), findsNothing);

      await harness.revealSubscriptionsTop();
      await harness.capture('mixed_currency_totals');
      await harness.tapAboveDock(find.text('Euro Test'));
      await tester.pageBack();
      await settleShort(tester);
      await harness.capture('populated_list');

      await harness.tapAboveDock(find.text('Monthly Test'));
      expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
      expect(find.text('12.00 USD'), findsWidgets);
      expect(find.text('Due today'), findsWidgets);
      expect(find.textContaining('Pause'), findsNothing);
      expect(find.textContaining('Not in this version'), findsNothing);
      await harness.capture('plan_detail');
      await tester.tap(find.byType(BackButton));
      await settleShort(tester);

      await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
      await settleShort(tester);
      expect(find.text('9.00 EUR · 22.00 USD'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(PriorityHeroCard),
          matching: find.text('Monthly Test'),
        ),
        findsOneWidget,
      );
      await tester.drag(find.byType(HomeScreen), const Offset(0, -420));
      await settleShort(tester);
      expect(find.byType(HomeAttentionCard), findsOneWidget);
      await tester.drag(find.byType(HomeScreen), const Offset(0, 900));
      await settleShort(tester);
      await tester.enterText(
        find.byKey(const ValueKey<String>('home-search')),
        'Monthly Test',
      );
      await settleShort(tester);
      await tester.tap(find.byKey(const ValueKey<String>('hero-review')));
      await settleShort(tester);
      expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settleShort(tester);
      await tester.tap(find.byKey(const ValueKey<String>('home-search-clear')));
      await settleShort(tester);

      await tester.drag(find.byType(HomeScreen), const Offset(0, -500));
      await settleShort(tester);
      expect(
        find.descendant(
          of: find.byType(HomeUpcomingItem),
          matching: find.text('Monthly Test'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(HomeUpcomingItem),
          matching: find.text('Annual Test'),
        ),
        findsWidgets,
      );
      await harness.capture('home_real_data');

      await tester.tap(find.byKey(const ValueKey<String>('home-ninety-day')));
      await settleShort(tester);
      final horizon = tester
          .widgetList<HomeUpcomingItem>(find.byType(HomeUpcomingItem))
          .toList();
      expect(horizon, hasLength(3));
      expect(horizon[0].item.titleText, 'Monthly Test');
      expect(horizon[1].item.titleText, 'Euro Test');
      expect(horizon[2].item.titleText, 'Annual Test');
      await tester.tap(find.byType(BackButton));
      await settleShort(tester);

      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await settleShort(tester);
      await harness.tapAboveDock(find.text('Monthly Test'));
      await tester.tap(find.byKey(const ValueKey<String>('subscription-edit')));
      await settleShort(tester);
      await harness.continueWizard();
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-amount')),
        '15.00',
      );
      await harness.continueWizard();
      await harness.continueWizard();
      await tester.tap(find.byKey(const ValueKey<String>('save-subscription')));
      await settleShort(tester);
      expect(repo.subscriptions, hasLength(3));
      expect(harness.named('Monthly Test').id, monthlyId);
      expect(find.text('15.00 USD'), findsWidgets);
      await tester.tap(find.byType(BackButton));
      await settleShort(tester);
      await harness.revealSubscriptionsTop();
      expect(find.text('25.00 USD'), findsWidgets);

      await harness.tapAboveDock(find.text('Monthly Test'));
      await tester.tap(
        find.byKey(const ValueKey<String>('subscription-cancel')),
      );
      await settleShort(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('cancel-plan-confirm')),
      );
      await settleShort(tester);
      expect(harness.named('Monthly Test').isCancelled, isTrue);
      await harness.capture('cancelled_plan');
      await tester.tap(find.byType(BackButton));
      await settleShort(tester);
      await harness.revealSubscriptionsTop();
      expect(find.text('10.00 USD'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
      await settleShort(tester);
      expect(
        find.descendant(
          of: find.byType(PriorityHeroCard),
          matching: find.text('Monthly Test'),
        ),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await settleShort(tester);
      await harness.revealSubscriptionsTop();
      await tester.tap(
        find.byKey(const ValueKey<String>('sub-filter-cancelled')),
      );
      await settleShort(tester);
      await harness.tapAboveDock(find.text('Monthly Test'));
      await tester.tap(
        find.byKey(const ValueKey<String>('subscription-reactivate')),
      );
      await settleShort(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('date-reactivate-next-payment')),
      );
      await harness.pickDate(DateTime(today.year, today.month, today.day + 14));
      await tester.tap(
        find.byKey(const ValueKey<String>('reactivate-confirm')),
      );
      await settleShort(tester);
      expect(harness.named('Monthly Test').isActive, isTrue);
      expect(harness.named('Monthly Test').id, monthlyId);
      await harness.capture('reactivation');
      await tester.tap(find.byType(BackButton));
      await settleShort(tester);
      await harness.revealSubscriptionsTop();
      expect(find.text('25.00 USD'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey<String>('sub-filter-all')));
      await settleShort(tester);
      final euroId = harness.named('Euro Test').id;
      await harness.tapAboveDock(find.byKey(ValueKey<String>(euroId)));
      await tester.tap(
        find.byKey(const ValueKey<String>('subscription-delete')),
      );
      await settleShort(tester);
      await tester.tap(find.byKey(const ValueKey<String>('delete-sub-cancel')));
      await settleShort(tester);
      expect(repo.findById(euroId), isNotNull);
      await tester.tap(
        find.byKey(const ValueKey<String>('subscription-delete')),
      );
      await settleShort(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('delete-sub-confirm')),
      );
      await settleShort(tester);
      expect(repo.subscriptions, hasLength(2));
      expect(find.text('Euro Test'), findsNothing);
      expect(find.text('9.00 EUR'), findsNothing);
      await harness.capture('after_delete');

      expect(find.byType(SubscriptionDetailScreen), findsNothing);
      await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
      await settleShort(tester);
      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await settleShort(tester);
      expect(find.byType(SubscriptionDetailScreen), findsNothing);
      expect(find.text('Euro Test'), findsNothing);
      expect(find.text('9.00 EUR'), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 18)),
  );

  testWidgets(
    'Phase 4 populated visual locales and text scale',
    (tester) async {
      final harness = _Harness(tester);
      await harness.launch(locale: const Locale('ar'));
      await harness.seedThreePlans();
      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await settleShort(tester);
      expect(
        Directionality.of(tester.element(find.byType(AppShell))),
        TextDirection.rtl,
      );
      await harness.capture('arabic_populated');

      await harness.launch(locale: const Locale('fr'));
      await harness.seedThreePlans();
      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await settleShort(tester);
      await harness.capture('french_populated');

      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await harness.launch();
      await harness.seedThreePlans();
      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await settleShort(tester);
      await harness.tapAboveDock(find.text('Monthly Test'));
      await harness.capture('large_text_150_detail');

      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      await harness.launch();
      await harness.seedThreePlans();
      await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
      await settleShort(tester);
      await harness.tapAboveDock(find.text('Monthly Test'));
      await harness.capture('large_text_180_detail');
    },
    timeout: const Timeout(Duration(minutes: 18)),
  );
}

class _Harness {
  _Harness(this.tester);

  final WidgetTester tester;

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  InMemorySubscriptionRepository get repo {
    return RegistryDependencies.of(
          tester.element(find.byType(MaterialApp)),
        ).subscriptions
        as InMemorySubscriptionRepository;
  }

  RegistrySubscription named(String name) {
    return repo.subscriptions.firstWhere((item) => item.serviceName == name);
  }

  Future<void> launch({Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(
      RegistryApp(
        key: UniqueKey(),
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: locale,
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> revealSubscriptionsTop() async {
    final scrollable = find.descendant(
      of: find.byType(SubscriptionsScreen),
      matching: find.byType(Scrollable),
    );
    if (scrollable.evaluate().isEmpty) {
      return;
    }
    await tester.drag(scrollable.first, const Offset(0, 900));
    await settleShort(tester);
  }

  Future<void> tapAboveDock(Finder finder) async {
    for (var attempt = 0; attempt < 24; attempt++) {
      await tester.pump();
      final listScrollable = find.descendant(
        of: find.byType(SubscriptionsScreen),
        matching: find.byType(Scrollable),
      );
      if (finder.evaluate().isEmpty) {
        if (listScrollable.evaluate().isEmpty) {
          fail('Missing $finder');
        }
        await tester.drag(listScrollable.first, const Offset(0, -240));
        await settleShort(tester);
        continue;
      }
      final target = finder.first;
      final scrollable = find.ancestor(
        of: target,
        matching: find.byType(Scrollable),
      );
      if (scrollable.evaluate().isNotEmpty) {
        await tester.ensureVisible(target);
        await settleShort(tester);
      }
      if (target.evaluate().isEmpty) {
        continue;
      }
      if (target.hitTestable().evaluate().isEmpty &&
          scrollable.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          target,
          80,
          scrollable: scrollable.first,
        );
        await settleShort(tester);
      }
      if (target.evaluate().isEmpty ||
          target.hitTestable().evaluate().isEmpty) {
        continue;
      }
      final card = tester.getRect(target);
      var obstructTop =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final dock = find.byKey(const ValueKey<String>('nav-dock'));
      if (dock.evaluate().isNotEmpty) {
        obstructTop = tester.getRect(dock).top;
      }
      final fab = find.byKey(const ValueKey<String>('home-fab')).hitTestable();
      if (fab.evaluate().isNotEmpty) {
        obstructTop = obstructTop < tester.getRect(fab.first).top
            ? obstructTop
            : tester.getRect(fab.first).top;
      }
      if (card.bottom > obstructTop - 4 && scrollable.evaluate().isNotEmpty) {
        await tester.drag(
          scrollable.first,
          Offset(0, -(card.bottom - obstructTop + AppSpacing.minTapTarget)),
        );
        await settleShort(tester);
        continue;
      }
      await tester.tap(target.hitTestable().first);
      await settleShort(tester);
      return;
    }
    fail('Could not tap $finder above the dock');
  }

  Future<void> capture(String name) async {
    await settleShort(tester);
    debugPrint('phase4-checkpoint:$name');
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(Uri.parse('http://10.0.2.2:9474/capture?name=$name'))
          .timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await response.transform(utf8.decoder).join();
      expect(
        response.statusCode,
        200,
        reason: 'checkpoint $name failed: $body',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> continueWizard() async {
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await settleShort(tester);
  }

  Future<void> openAddFromFab() async {
    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await settleShort(tester);
    await tester.tap(find.byKey(const ValueKey<String>('add-subscription')));
    await settleShort(tester);
  }

  Future<void> openAdd() async {
    final visibleAdd = find
        .byKey(const ValueKey<String>('subscriptions-add'))
        .hitTestable();
    if (visibleAdd.evaluate().isNotEmpty) {
      await tapAboveDock(visibleAdd.last);
      return;
    }
    await openAddFromFab();
  }

  Future<void> pickDate(DateTime target) async {
    await settleShort(tester);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    final l10n = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    );
    var month = DateTime(DateTime.now().year, DateTime.now().month);
    final goal = DateTime(target.year, target.month);
    var guard = 0;
    while ((month.year != goal.year || month.month != goal.month) &&
        guard < 48) {
      if (month.isBefore(goal)) {
        await tester.tap(find.byTooltip(l10n.nextMonthTooltip));
        month = DateTime(month.year, month.month + 1);
      } else {
        await tester.tap(find.byTooltip(l10n.previousMonthTooltip));
        month = DateTime(month.year, month.month - 1);
      }
      await settleShort(tester);
      guard++;
    }
    await tester.tap(
      find
          .descendant(
            of: find.byType(CalendarDatePicker),
            matching: find.text('${target.day}'),
          )
          .first,
    );
    await settleShort(tester);
    await tester.tap(find.text(l10n.okButtonLabel));
    await settleShort(tester);
  }

  Future<void> addPlan({
    required String name,
    required String categoryKey,
    required String amount,
    required String currency,
    required String cycle,
    required DateTime nextPayment,
    DateTime? decideBy,
    String planName = '',
    String? captureReviewAs,
  }) async {
    await openAdd();
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-service-name')),
      name,
    );
    if (planName.isNotEmpty) {
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-plan-name')),
        planName,
      );
    }
    await tester.tap(
      find.byKey(const ValueKey<String>('field-subscription-category')),
    );
    await settleShort(tester);
    await tester.tap(find.byKey(ValueKey<String>(categoryKey)));
    await settleShort(tester);
    await continueWizard();

    await tester.enterText(
      find.byKey(const ValueKey<String>('field-amount')),
      amount,
    );
    if (captureReviewAs == 'review_before_save') {
      await tester.showKeyboard(
        find.byKey(const ValueKey<String>('field-amount')),
      );
      await tester.pump();
      await capture('keyboard_form');
      FocusManager.instance.primaryFocus?.unfocus();
      await settleShort(tester);
    }
    await tester.tap(find.byKey(const ValueKey<String>('field-currency')));
    await settleShort(tester);
    await tester.tap(find.byKey(ValueKey<String>('currency-$currency')));
    await settleShort(tester);
    await tester.tap(find.byKey(ValueKey<String>(cycle)));
    await tester.tap(find.byKey(const ValueKey<String>('date-next-payment')));
    await pickDate(nextPayment);
    await continueWizard();

    if (decideBy != null) {
      await tester.tap(find.byKey(const ValueKey<String>('date-decide-by')));
      await pickDate(decideBy);
    }
    await tester.tap(find.byKey(const ValueKey<String>('sub-impact-low')));
    await continueWizard();
    if (captureReviewAs != null) {
      await capture(captureReviewAs);
    }
    await tester.tap(find.byKey(const ValueKey<String>('save-subscription')));
    await settleShort(tester);
  }

  Future<void> seedThreePlans() async {
    final today = this.today;
    await addPlan(
      name: 'Monthly Test',
      categoryKey: 'sub-category-entertainment',
      amount: '12.00',
      currency: 'USD',
      cycle: 'cycle-monthly',
      nextPayment: DateTime(today.year, today.month, today.day + 10),
      decideBy: today,
    );
    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await settleShort(tester);
    await addPlan(
      name: 'Annual Test',
      categoryKey: 'sub-category-productivity',
      amount: '120.00',
      currency: 'USD',
      cycle: 'cycle-yearly',
      nextPayment: DateTime(today.year, today.month, today.day + 30),
      decideBy: DateTime(today.year, today.month, today.day + 20),
    );
    await addPlan(
      name: 'Euro Test',
      categoryKey: 'sub-category-other',
      amount: '9.00',
      currency: 'EUR',
      cycle: 'cycle-monthly',
      nextPayment: DateTime(today.year, today.month, today.day + 15),
    );
  }
}
