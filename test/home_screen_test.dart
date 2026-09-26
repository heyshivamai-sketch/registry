import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/core/widgets/registry_navigation_dock.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/document_detail_screen.dart';
import 'package:the_registry/features/documents/presentation/documents_screen.dart';
import 'package:the_registry/features/home/data/coming_up_grouping.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/presentation/attention_list_screen.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/home/presentation/horizon_90_day_screen.dart';
import 'package:the_registry/features/home/widgets/home_attention_card.dart';
import 'package:the_registry/features/home/widgets/home_first_visit.dart';
import 'package:the_registry/features/home/widgets/home_header.dart';
import 'package:the_registry/features/home/widgets/home_metrics_row.dart';
import 'package:the_registry/features/home/widgets/home_search_field.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/features/home/widgets/priority_hero_card.dart';
import 'package:the_registry/features/backup/presentation/profile_screen.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
import 'support/sample_subscription.dart';

final _clock = FixedClock(DateTime(2026, 9, 19));

Widget _app({
  Locale locale = const Locale('en'),
  InMemoryDocumentRepository? documents,
  InMemorySubscriptionRepository? subscriptions,
  Clock? clock,
}) {
  return RegistryApp(
    onboardingRepository: FakeOnboardingRepository(completed: true),
    documentRepository: documents ?? InMemoryDocumentRepository(),
    subscriptionRepository: subscriptions ?? InMemorySubscriptionRepository(),
    clock: clock ?? _clock,
    locale: locale,
  );
}

Future<void> _seedPopulated(
  InMemoryDocumentRepository documents,
  InMemorySubscriptionRepository subscriptions,
) async {
  await documents.save(
    sampleDocument(
      id: 'insurance',
      name: 'Car insurance',
      category: DocumentCategory.insurance,
      expiryDate: DateTime(2026, 10, 5),
      actionDate: DateTime(2026, 9, 19),
    ),
  );
  await documents.save(
    sampleDocument(
      id: 'passport',
      name: 'Passport',
      expiryDate: DateTime(2026, 11, 12),
      actionDate: DateTime(2026, 10, 12),
    ),
  );
  await subscriptions.save(
    sampleSubscription(
      id: 'stream',
      serviceName: 'Streaming',
      minorUnits: 1200,
      currencyCode: 'USD',
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
}

List<FlutterErrorDetails> _captureOverflows(WidgetTester tester) {
  final overflows = <FlutterErrorDetails>[];
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    overflows.add(details);
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
  return overflows;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Empty repositories show first-visit Home, not populated tiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.text('Your Registry'), findsOneWidget);
    expect(find.byType(HomeFirstVisit), findsOneWidget);
    expect(find.text('Add your first document'), findsOneWidget);
    expect(find.text('Add a subscription'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('home-notifications')),
      findsNothing,
    );
    expect(find.byType(HomeSearchField), findsOneWidget);
    expect(find.byType(HomeMetricsRow), findsNothing);
    expect(find.byType(PriorityHeroCard), findsNothing);
    expect(find.text('0.00 USD'), findsNothing);
  });

  testWidgets('Empty Home last benefit can scroll fully above the dock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final benefit = find.text('Stay in control of your spending.');
    final scrollable = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(benefit, 80, scrollable: scrollable.first);
    await tester.pumpAndSettle();

    var box = tester.getRect(benefit);
    final dock = tester.getRect(find.byKey(const ValueKey<String>('nav-dock')));
    if (box.bottom > dock.top) {
      await tester.drag(
        scrollable.first,
        Offset(0, -(box.bottom - dock.top + 24)),
      );
      await tester.pumpAndSettle();
      box = tester.getRect(benefit);
    }
    expect(box.bottom, lessThanOrEqualTo(dock.top + 1));
    expect(dock.top - box.bottom, lessThan(96));
    expect(benefit.hitTestable(), findsOneWidget);
  });

  testWidgets('Large-text dock keeps destination names in semantics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(const ValueKey<String>('nav-home'))).label,
      'Home',
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('nav-documents')))
          .label,
      'Documents',
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('nav-subscriptions')))
          .label,
      'Subscriptions',
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('nav-profile')))
          .label,
      'Profile',
    );
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('Search empty is not the first-visit illustration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('home-search')),
      'zzzzzz',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-search-empty')),
      findsOneWidget,
    );
    expect(find.byType(HomeFirstVisit), findsNothing);
    expect(find.text('No matching items'), findsOneWidget);
  });

  testWidgets('Populated Home uses live counts and mixed-currency totals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedPopulated(documents, subscriptions);

    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeFirstVisit), findsNothing);
    expect(find.byType(PriorityHeroCard), findsOneWidget);
    expect(find.text('Review Car insurance'), findsOneWidget);
    expect(find.text('12.00 USD'), findsWidgets);
    expect(find.text('9.00 EUR'), findsWidgets);
    expect(find.textContaining('31.00'), findsNothing);
    expect(find.text('2 subscriptions'), findsOneWidget);
    expect(find.byType(HomeAttentionCard), findsWidgets);
    expect(find.byType(HomeUpcomingItem), findsWidgets);
  });

  testWidgets('Cancelled-only repository is populated, not first visit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final subscriptions = InMemorySubscriptionRepository();
    await subscriptions.save(
      sampleSubscription(lifecycle: SubscriptionLifecycle.cancelled),
    );

    await tester.pumpWidget(_app(subscriptions: subscriptions));
    await tester.pumpAndSettle();

    expect(find.byType(HomeFirstVisit), findsNothing);
    expect(find.byType(HomeMetricsRow), findsOneWidget);
    expect(find.text('No active plans'), findsOneWidget);
    expect(find.text('1 subscription'), findsOneWidget);
  });

  testWidgets('Documents-only and subscriptions-only keep overview tiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    await documents.save(
      sampleDocument(
        actionDate: DateTime(2026, 12, 1),
        expiryDate: DateTime(2027, 1, 1),
      ),
    );
    await tester.pumpWidget(_app(documents: documents));
    await tester.pumpAndSettle();
    expect(find.byType(HomeFirstVisit), findsNothing);
    expect(find.text('No active plans'), findsOneWidget);

    final subscriptions = InMemorySubscriptionRepository();
    await subscriptions.save(
      sampleSubscription(
        nextPaymentDate: DateTime(2026, 12, 1),
        decideByDate: DateTime(2026, 11, 20),
      ),
    );
    await tester.pumpWidget(_app(subscriptions: subscriptions));
    await tester.pumpAndSettle();
    expect(find.byType(HomeFirstVisit), findsNothing);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('Home updates after save and delete', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    await tester.pumpWidget(_app(documents: documents));
    await tester.pumpAndSettle();
    expect(find.byType(HomeFirstVisit), findsOneWidget);

    await documents.save(
      sampleDocument(
        name: 'Visa pack',
        actionDate: DateTime(2026, 9, 19),
        expiryDate: DateTime(2026, 10, 5),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeFirstVisit), findsNothing);
    expect(find.text('Visa pack'), findsWidgets);

    await documents.delete('doc_1');
    await tester.pumpAndSettle();
    expect(find.byType(HomeFirstVisit), findsOneWidget);
  });

  testWidgets('Search filters and clears live items', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedPopulated(documents, subscriptions);

    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('home-search')),
      'Passport',
    );
    await tester.pumpAndSettle();
    expect(find.text('Passport'), findsWidgets);
    expect(find.text('Streaming'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Streaming', skipOffstage: false), findsWidgets);
  });

  testWidgets('Profile control opens Profile', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('home-profile')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsWidgets);
  });

  testWidgets('Empty CTAs open real add forms', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('home-add-first-document')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add a document'), findsOneWidget);
  });

  testWidgets('Overview tiles select Documents and Subscriptions tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedPopulated(documents, subscriptions);
    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('metric-documents')));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentsScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('metric-subscriptions')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions'), findsWidgets);
  });

  testWidgets('Review opens the highlighted document', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedPopulated(documents, subscriptions);
    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('hero-review')));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('Car insurance'), findsWidgets);
  });

  testWidgets('Coming up filters change visible rows', (tester) async {
    tester.view.physicalSize = const Size(412, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedPopulated(documents, subscriptions);
    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('coming-up-filter-documents')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Passport'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(HomeUpcomingItem),
        matching: find.text('Streaming'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('coming-up-filter-subscriptions')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(HomeUpcomingItem),
        matching: find.text('Streaming'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('View all opens the live 90-day route', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedPopulated(documents, subscriptions);
    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('home-ninety-day')));
    await tester.pumpAndSettle();
    expect(find.byType(Horizon90DayScreen), findsOneWidget);
  });

  testWidgets('View all attention opens the live attention list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    for (var i = 0; i < 4; i++) {
      await documents.save(
        sampleDocument(
          id: 'attn_$i',
          name: 'Urgent $i',
          actionDate: DateTime(2026, 9, 19),
          expiryDate: DateTime(2026, 10, 1 + i),
        ),
      );
    }
    await tester.pumpWidget(_app(documents: documents));
    await tester.pumpAndSettle();
    expect(find.byType(HomeAttentionCard), findsNWidgets(3));
    await tester.tap(
      find.byKey(const ValueKey<String>('home-attention-view-all')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AttentionListScreen), findsOneWidget);
    expect(find.text('Urgent 0'), findsWidgets);
  });

  testWidgets(
    'Calm hero has no dead Review button when nothing needs attention',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final documents = InMemoryDocumentRepository();
      await documents.save(
        sampleDocument(
          actionDate: DateTime(2026, 11, 1),
          expiryDate: DateTime(2026, 12, 1),
        ),
      );
      await tester.pumpWidget(_app(documents: documents));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('hero-review')), findsNothing);
      expect(find.text('Nothing needs attention right now'), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('hero-view-upcoming')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Header date uses the injected clock', (tester) async {
    await tester.pumpWidget(_app(clock: FixedClock(DateTime(2025, 1, 2))));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 January 2025'), findsOneWidget);
    expect(find.textContaining('19 September 2026'), findsNothing);
  });

  testWidgets('Central Add button opens the Add sheet', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    expect(find.text('Quick Add'), findsOneWidget);
  });

  testWidgets('Floating dock preserves Home search state', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('home-search')),
      'Passport',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('home-search')))
          .controller!
          .text,
      'Passport',
    );
  });

  testWidgets('Floating dock switches tabs including Profile', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.home_rounded), findsWidgets);
    expect(find.byIcon(Icons.description_outlined), findsWidgets);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsWidgets);
    expect(find.byIcon(Icons.person_outline), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    expect(find.text('No documents yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'There is no account in this version. Registry will keep your records private on this device.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Arabic Home stays RTL', (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('سجلك'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AppShell))),
      TextDirection.rtl,
    );
  });

  testWidgets('French Home uses first-visit copy', (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('fr')));
    await tester.pumpAndSettle();
    expect(find.text('Votre registre'), findsOneWidget);
    expect(find.text('Ajouter votre premier document'), findsOneWidget);
  });

  testWidgets('Small-screen Home has no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final overflows = _captureOverflows(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('1.8x populated Home has no overflow and clears the dock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final overflows = _captureOverflows(tester);
    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedPopulated(documents, subscriptions);
    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
    expect(find.byType(RegistryAuraNavigationDock), findsOneWidget);
  });

  test('Upcoming and active items are excluded from attention', () {
    expect(DocumentStatus.isAttentionStatus(RegistryStatus.upcoming), isFalse);
    expect(DocumentStatus.isAttentionStatus(RegistryStatus.active), isFalse);
    expect(DocumentStatus.isAttentionStatus(RegistryStatus.urgent), isTrue);
    expect(DocumentStatus.isAttentionStatus(RegistryStatus.expired), isTrue);
  });

  test('Coming up groups respect locale week and month boundaries', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final now = DateTime(2026, 9, 19);
    final weekStart = RegistryDateFormatter.startOfWeek(now, 'en');
    final weekEnd = RegistryDateFormatter.endOfWeek(now, 'en');
    final insideWeek = weekStart;
    final laterMonth = DateTime(2026, 9, 28);
    final nextMonth = DateTime(2026, 10, 12);
    final nextYear = DateTime(2027, 1, 4);

    expect(
      RegistryDateFormatter.isInRange(laterMonth, weekStart, weekEnd),
      laterMonth.isBefore(weekStart) || laterMonth.isAfter(weekEnd)
          ? isFalse
          : isTrue,
    );

    final groups = ComingUpGrouping.group(
      items: [
        RegistryItem(
          id: 'a',
          type: RegistryItemType.subscription,
          status: RegistryStatus.upcoming,
          impact: RegistryImpact.low,
          impactScore: 1,
          actionDate: insideWeek,
          dueDate: insideWeek,
          isHero: false,
          needsAttention: false,
          titleText: 'Week item',
        ),
        RegistryItem(
          id: 'b',
          type: RegistryItemType.subscription,
          status: RegistryStatus.upcoming,
          impact: RegistryImpact.low,
          impactScore: 1,
          actionDate: laterMonth,
          dueDate: laterMonth,
          isHero: false,
          needsAttention: false,
          titleText: 'Month item',
        ),
        RegistryItem(
          id: 'c',
          type: RegistryItemType.document,
          status: RegistryStatus.upcoming,
          impact: RegistryImpact.low,
          impactScore: 1,
          actionDate: nextMonth,
          dueDate: nextMonth,
          isHero: false,
          needsAttention: false,
          titleText: 'October item',
        ),
        RegistryItem(
          id: 'd',
          type: RegistryItemType.document,
          status: RegistryStatus.upcoming,
          impact: RegistryImpact.low,
          impactScore: 1,
          actionDate: nextYear,
          dueDate: nextYear,
          isHero: false,
          needsAttention: false,
          titleText: 'Next year',
        ),
      ],
      now: now,
      locale: 'en',
      l10n: l10n,
    );

    expect(groups.first.id, 'this-week');
    expect(groups.first.items.single.titleText, 'Week item');
    expect(groups.any((group) => group.id == 'later-month'), isTrue);
    expect(groups.any((group) => group.label.contains('2027')), isTrue);
    expect(
      groups.any((group) => group.items.any((item) => item.id == 'c')),
      isTrue,
    );
  });

  testWidgets('90-day view lists live items chronologically', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await documents.save(
      sampleDocument(
        id: 'passport',
        name: 'Passport',
        expiryDate: DateTime(2026, 11, 12),
        actionDate: DateTime(2026, 9, 19),
      ),
    );
    await subscriptions.save(
      sampleSubscription(
        id: 'stream',
        serviceName: 'Streamio',
        nextPaymentDate: DateTime(2026, 9, 28),
        decideByDate: DateTime(2026, 9, 25),
      ),
    );
    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('home-ninety-day')));
    await tester.pumpAndSettle();
    final ordered = tester
        .widgetList<HomeUpcomingItem>(find.byType(HomeUpcomingItem))
        .map((item) => item.item.sourceId)
        .toList();
    expect(ordered, ['passport', 'stream']);
  });

  testWidgets('Arabic 90-day stays RTL', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final documents = InMemoryDocumentRepository();
    await documents.save(sampleDocument());
    await tester.pumpWidget(
      _app(locale: const Locale('ar'), documents: documents),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('home-ninety-day')));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(Horizon90DayScreen))),
      TextDirection.rtl,
    );
  });
}
