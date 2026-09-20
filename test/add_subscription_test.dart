import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_controller.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_detail_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/sample_subscription.dart';

class _FailingSubscriptionRepository extends InMemorySubscriptionRepository {
  bool failSaves = false;

  @override
  Future<void> save(RegistrySubscription subscription) async {
    if (failSaves) {
      throw StateError('unavailable');
    }
    await super.save(subscription);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryDocumentRepository documents;
  late InMemorySubscriptionRepository subscriptions;
  late FakeDatePickerService dates;
  final clock = FixedClock(DateTime(2026, 9, 19));

  Widget app({
    Locale locale = const Locale('en'),
    InMemorySubscriptionRepository? repository,
  }) {
    return RegistryApp(
      key: UniqueKey(),
      onboardingRepository: FakeOnboardingRepository(completed: true),
      documentRepository: documents,
      subscriptionRepository: repository ?? subscriptions,
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

  Future<void> openWizard(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-subscription')));
    await tester.pumpAndSettle();
  }

  test('controller validates steps and retains values', () {
    final controller = AddSubscriptionController(clock: clock);
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(controller.continueStep(l10n), isFalse);
    expect(controller.serviceNameError, isNotNull);
    controller
      ..setServiceName('News')
      ..setCategory(SubscriptionCategory.entertainment);
    expect(controller.continueStep(l10n), isTrue);
    expect(controller.step, AddSubscriptionStep.billing);

    expect(controller.continueStep(l10n), isFalse);
    controller
      ..setAmountText('9.99')
      ..setCurrencyCode('USD')
      ..setBillingCycle(BillingCycle.monthly)
      ..setNextPaymentDate(DateTime(2026, 10, 1))
      ..setDecideByDate(DateTime(2026, 10, 2));
    expect(controller.continueStep(l10n), isFalse);
    expect(controller.decideByError, isNotNull);
    controller.setDecideByDate(DateTime(2026, 9, 28));
    expect(controller.continueStep(l10n), isTrue);

    controller.setImpact(DocumentImpact.low);
    expect(controller.continueStep(l10n), isTrue);
    controller.backStep();
    expect(controller.step, AddSubscriptionStep.preferences);
    expect(controller.serviceName, 'News');
    expect(controller.amountText, '9.99');
  });

  test('zero-cost plans save and invalid amounts fail', () {
    final controller = AddSubscriptionController(clock: clock);
    final l10n = lookupAppLocalizations(const Locale('en'));
    controller
      ..setServiceName('Free tier')
      ..setCategory(SubscriptionCategory.other)
      ..setAmountText('0')
      ..setCurrencyCode('USD')
      ..setBillingCycle(BillingCycle.yearly)
      ..setNextPaymentDate(DateTime(2026, 10, 1))
      ..setImpact(DocumentImpact.low);
    expect(controller.validate(l10n), isTrue);
    expect(controller.toSubscription().amount.minorUnits, 0);

    final second = AddSubscriptionController(clock: clock)
      ..setServiceName('Also free')
      ..setCategory(SubscriptionCategory.other)
      ..setAmountText('0')
      ..setCurrencyCode('USD')
      ..setBillingCycle(BillingCycle.yearly)
      ..setNextPaymentDate(DateTime(2026, 10, 1))
      ..setImpact(DocumentImpact.low);
    expect(second.toSubscription().id, isNot(controller.toSubscription().id));

    controller.setAmountText('-3');
    expect(controller.validate(l10n), isFalse);
  });

  test('edit prefill keeps the same id', () {
    final controller = AddSubscriptionController(clock: clock);
    controller.loadSubscription(sampleSubscription(id: 'keep-me'));
    expect(controller.isEditing, isTrue);
    expect(controller.serviceName, 'City Gym');
    expect(controller.amountText, '35.00');
    final saved = controller.toSubscription();
    expect(saved.id, 'keep-me');
  });

  testWidgets(
    'wizard continue validates and discard keeps the user in the form',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await openWizard(tester);

      expect(find.byType(AddSubscriptionScreen), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('sub-wizard-continue')),
      );
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsWidgets);

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
      await tester.tap(
        find.byKey(const ValueKey<String>('sub-wizard-continue')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Billing details'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard this draft?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(AddSubscriptionScreen), findsOneWidget);
    },
  );

  testWidgets('save failure keeps the draft', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final failing = _FailingSubscriptionRepository()..failSaves = true;
    dates.results['next-payment'] = DateTime(2026, 10, 1);
    await tester.pumpWidget(app(repository: failing));
    await tester.pumpAndSettle();
    await openWizard(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('field-service-name')),
      'News',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('field-subscription-category')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('field-amount')),
      '8',
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

    expect(
      find.byKey(const ValueKey<String>('subscription-save-error')),
      findsOneWidget,
    );
    expect(find.byType(AddSubscriptionScreen), findsOneWidget);
    expect(failing.subscriptions, isEmpty);
  });

  testWidgets('edit updates the same id and list refreshes', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await subscriptions.save(sampleSubscription(id: 'keep-me'));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('keep-me')));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionDetailScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('subscription-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-service-name')),
      'Updated gym',
    );
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('sub-wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-subscription')));
    await tester.pumpAndSettle();

    expect(subscriptions.subscriptions, hasLength(1));
    expect(subscriptions.subscriptions.single.id, 'keep-me');
    expect(subscriptions.subscriptions.single.serviceName, 'Updated gym');
    expect(find.text('Updated gym'), findsWidgets);
  });

  testWidgets('delete cancel and confirm', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await subscriptions.save(sampleSubscription(id: 'keep-me'));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('keep-me')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('subscription-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('delete-sub-cancel')));
    await tester.pumpAndSettle();
    expect(subscriptions.subscriptions, hasLength(1));

    await tester.tap(find.byKey(const ValueKey<String>('subscription-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('delete-sub-confirm')));
    await tester.pumpAndSettle();
    expect(subscriptions.subscriptions, isEmpty);
    expect(find.text('No subscriptions yet'), findsOneWidget);
  });

  testWidgets('cancel excludes the plan from Home estimates', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await subscriptions.save(
      sampleSubscription(
        id: 'keep-me',
        nextPaymentDate: DateTime(2026, 9, 10),
        decideByDate: DateTime(2026, 9, 1),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining('USD'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('keep-me')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('subscription-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('cancel-plan-confirm')));
    await tester.pumpAndSettle();
    expect(subscriptions.subscriptions.single.isCancelled, isTrue);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('home-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('hero-review')), findsNothing);
  });

  testWidgets('Arabic and large text keep the form usable', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await openWizard(tester);
    expect(find.byType(AddSubscriptionScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AddSubscriptionScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('docked keyboard inset keeps the field and continue visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openWizard(tester);
    await tester.tap(find.byKey(const ValueKey<String>('field-service-name')));
    await tester.pump();

    final screen = tester.getRect(find.byType(Scaffold).first);
    final field = tester.getRect(
      find.byKey(const ValueKey<String>('field-service-name')),
    );
    final cont = tester.getRect(
      find.byKey(const ValueKey<String>('sub-wizard-continue')),
    );
    expect(cont.bottom, lessThanOrEqualTo(screen.bottom + 1));
    expect(cont.bottom, lessThanOrEqualTo(900 - 360 + 1));
    expect(field.bottom, lessThanOrEqualTo(cont.top + 1));
    expect(
      find.byKey(const ValueKey<String>('sub-wizard-continue')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('system back dismisses the keyboard before discard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openWizard(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-service-name')),
      'Streamio',
    );
    await tester.tap(find.byKey(const ValueKey<String>('field-service-name')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Discard this draft?'), findsNothing);
    expect(find.byType(AddSubscriptionScreen), findsOneWidget);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard this draft?'), findsOneWidget);
  });
}
