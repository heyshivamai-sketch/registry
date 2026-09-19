import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/core/widgets/registry_navigation_dock.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/presentation/document_detail_screen.dart';
import 'package:the_registry/features/documents/presentation/documents_screen.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/home/widgets/home_attention_card.dart';
import 'package:the_registry/features/home/widgets/home_header.dart';
import 'package:the_registry/features/home/widgets/home_metrics_row.dart';
import 'package:the_registry/features/home/widgets/home_search_field.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/features/home/widgets/priority_hero_card.dart';
import 'package:the_registry/features/home/presentation/horizon_90_day_screen.dart';
import 'package:the_registry/features/notifications/presentation/notifications_placeholder_screen.dart';
import 'package:the_registry/features/profile/presentation/profile_placeholder_screen.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
import 'support/sample_subscription.dart';

final _clock = FixedClock(DateTime(2026, 9, 19));

Widget _app({
  Locale locale = const Locale('en'),
  InMemoryDocumentRepository? documents,
  InMemorySubscriptionRepository? subscriptions,
}) {
  return RegistryApp(
    onboardingRepository: FakeOnboardingRepository(completed: true),
    documentRepository: documents ?? InMemoryDocumentRepository(),
    subscriptionRepository: subscriptions ?? InMemorySubscriptionRepository(),
    clock: _clock,
    locale: locale,
  );
}

Future<void> _seedAttention(
  InMemoryDocumentRepository documents,
  InMemorySubscriptionRepository subscriptions,
) async {
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

bool _rectsOverlap(Rect a, Rect b) {
  return a.left < b.right &&
      a.right > b.left &&
      a.top < b.bottom &&
      a.bottom > b.top;
}

void _expectDockClearsHomeContent(
  WidgetTester tester, {
  required bool includeHorizon,
}) {
  final dock = tester.getRect(find.byType(RegistryAuraNavigationDock));

  if (includeHorizon) {
    expect(
      _rectsOverlap(
        dock,
        tester.getRect(
          find.byKey(const ValueKey<String>('upcoming-driving_licence')),
        ),
      ),
      isFalse,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home renders the Registry Aura dashboard sections', (
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
    expect(
      find.byKey(const ValueKey<String>('home-notifications')),
      findsOneWidget,
    );
    expect(find.byType(HomeSearchField), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('home-filter')), findsNothing);
    expect(find.text('⌘K'), findsNothing);
    expect(find.byType(PriorityHeroCard), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('home-calm-empty')),
      findsOneWidget,
    );
    expect(find.text('Registry snapshot'), findsOneWidget);
    expect(find.byType(HomeMetricsRow), findsOneWidget);
    expect(find.byType(HomeAttentionCard), findsNothing);
    final metrics = tester.widget<HomeMetricsRow>(
      find.byKey(const ValueKey<String>('home-metrics')),
    );
    expect(metrics.documentCount, 0);
    expect(metrics.subscriptionCount, 0);
    expect(metrics.horizonCount, 0);
  });

  testWidgets('Search filters and clears live items', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedAttention(documents, subscriptions);

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
    expect(find.text('Streamio'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('home-search')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Streamio', skipOffstage: false), findsWidgets);
    expect(find.text('Passport', skipOffstage: false), findsWidgets);
  });

  testWidgets('Search empty state appears for unknown queries', (tester) async {
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
    expect(find.text('No matching items'), findsOneWidget);
    expect(find.byType(PriorityHeroCard), findsNothing);
  });

  testWidgets('Profile control opens Profile', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-profile')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePlaceholderScreen), findsWidgets);
  });

  testWidgets('Notifications control opens the placeholder', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-notifications')));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPlaceholderScreen), findsOneWidget);
  });

  testWidgets('Central Add button opens the Add sheet', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Quick Add'), findsOneWidget);
    expect(find.text('What would you like to track?'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('add-document')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('add-subscription')),
      findsOneWidget,
    );
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
    expect(find.text('Streaming subscription'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('documents-add')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();
    expect(find.text('No subscriptions yet'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('subscriptions-add')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('home-search')))
          .controller!
          .text,
      'Passport',
    );
    expect(find.text('Streaming subscription'), findsNothing);
  });

  testWidgets('Floating dock switches tabs including Profile', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.home_rounded), findsWidgets);
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.byIcon(Icons.article_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(
      tester
          .widget<RegistryAuraNavigationDock>(
            find.byType(RegistryAuraNavigationDock),
          )
          .selectedIndex,
      1,
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'There is no account in this version. Registry will keep your records private on this device.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(DocumentsScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('Arabic Home stays RTL', (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('سجلك'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AppShell))),
      TextDirection.rtl,
    );
    expect(find.text('يلزم اتخاذ إجراء'), findsNothing);
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
      find.byKey(const ValueKey<String>('home-calm-empty')),
      findsOneWidget,
    );

    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('Large text scale Home has no overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final overflows = _captureOverflows(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('Horizon is chronological by action date', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final upcoming = tester
        .widgetList<HomeUpcomingItem>(
          find.byType(HomeUpcomingItem, skipOffstage: false),
        )
        .toList();
    expect(upcoming, isEmpty);
  });

  testWidgets('Small-screen last Horizon card clears the dock', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = _captureOverflows(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    _expectDockClearsHomeContent(tester, includeHorizon: false);
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('Pixel-sized layout keeps metrics above the dock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(RegistryAuraNavigationDock), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('home-metrics')), findsOneWidget);
  });

  testWidgets('1.5x text Home has no overflow and clears the dock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final overflows = _captureOverflows(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('1.8x text Home has no overflow and clears the dock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final overflows = _captureOverflows(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('Arabic RTL dock stays usable', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(AppShell))),
      TextDirection.rtl,
    );
    expect(find.byType(RegistryAuraNavigationDock), findsOneWidget);
  });

  testWidgets('Status pills use a colour dot and text together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedAttention(documents, subscriptions);

    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RegistryStatusChip), findsWidgets);
    final chips = find.byType(RegistryStatusChip);
    expect(
      find.descendant(of: chips, matching: find.byType(DecoratedBox)),
      findsWidgets,
    );
    expect(
      find.descendant(of: chips, matching: find.byType(Text)),
      findsWidgets,
    );
    expect(find.text('Action needed'), findsWidgets);
  });

  test('Relative remaining copy uses existing dates', () {
    final item = RegistryItem(
      id: 'car_insurance',
      type: RegistryItemType.document,
      status: RegistryStatus.urgent,
      impact: RegistryImpact.high,
      impactScore: 100,
      actionDate: DateTime.utc(2026, 9, 20),
      dueDate: DateTime.utc(2026, 10, 5),
      isHero: true,
      needsAttention: true,
    );
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(
      item.remainingLabel(l10n, now: DateTime(2026, 9, 18)),
      '2 days remaining',
    );
    expect(item.remainingLabel(l10n, now: DateTime(2026, 9, 20)), 'Due today');
    expect(
      item.remainingLabel(l10n, now: DateTime(2026, 9, 22)),
      '2 days overdue',
    );
    expect(
      RegistryDateFormatter.dayMonthYear(item.dueDate, 'en'),
      '05 Oct 2026',
    );
    expect(item.requiresAttention, isTrue);
  });

  test('Upcoming and active items are excluded from attention', () {
    expect(DocumentStatus.isAttentionStatus(RegistryStatus.upcoming), isFalse);
    expect(DocumentStatus.isAttentionStatus(RegistryStatus.active), isFalse);
    expect(DocumentStatus.isAttentionStatus(RegistryStatus.urgent), isTrue);
    expect(DocumentStatus.isAttentionStatus(RegistryStatus.expired), isTrue);
  });

  testWidgets('Pulse Review opens the real document detail', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedAttention(documents, subscriptions);

    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('hero-review')));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('Passport'), findsWidgets);
  });

  testWidgets('Back from Pulse Review preserves Home search state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedAttention(documents, subscriptions);

    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('home-search')),
      'Passport',
    );
    await tester.pumpAndSettle();
    expect(find.text('Streamio'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('hero-review')));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentDetailScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('home-search')))
          .controller!
          .text,
      'Passport',
    );
    expect(find.text('Streamio'), findsNothing);
    expect(find.byType(PriorityHeroCard), findsOneWidget);
  });

  testWidgets('90-day view lists live items chronologically', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seedAttention(documents, subscriptions);

    await tester.pumpWidget(
      _app(documents: documents, subscriptions: subscriptions),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-ninety-day')));
    await tester.pumpAndSettle();

    expect(find.byType(Horizon90DayScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('horizon-90-day')),
      findsOneWidget,
    );
    final ordered = tester
        .widgetList<HomeUpcomingItem>(find.byType(HomeUpcomingItem))
        .map((item) => item.item.sourceId)
        .toList();
    expect(ordered, ['passport', 'stream']);
    expect(find.byType(RegistryStatusChip), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(PriorityHeroCard), findsOneWidget);
  });

  testWidgets('Horizon metric opens the 90-day view', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('metric-horizon')));
    await tester.pumpAndSettle();
    expect(find.byType(Horizon90DayScreen), findsOneWidget);
  });

  testWidgets('90-day view shows an empty state when injected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Horizon90DayScreen(items: []),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('horizon-90-empty')),
      findsOneWidget,
    );
    expect(find.text('Nothing in the next 90 days'), findsOneWidget);
  });

  testWidgets('Arabic 90-day stays RTL', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('home-ninety-day')));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(Horizon90DayScreen))),
      TextDirection.rtl,
    );
    expect(find.text('عرض 90 يومًا'), findsWidgets);
  });
}
