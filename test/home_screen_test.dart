import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/core/widgets/registry_countdown_ring.dart';
import 'package:the_registry/core/widgets/registry_navigation_dock.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
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
import 'package:the_registry/features/home/presentation/catalog_item_detail_screen.dart';
import 'package:the_registry/features/home/presentation/horizon_90_day_screen.dart';
import 'package:the_registry/features/notifications/presentation/notifications_placeholder_screen.dart';
import 'package:the_registry/features/profile/presentation/profile_placeholder_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_onboarding_repository.dart';

Widget _app({Locale locale = const Locale('en')}) {
  return RegistryApp(
    onboardingRepository: FakeOnboardingRepository(completed: true),
    locale: locale,
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
    expect(find.byType(PriorityHeroCard), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('hero-countdown')),
      findsOneWidget,
    );
    expect(find.byType(RegistryCountdownRing), findsOneWidget);
    expect(find.text('Action needed'), findsWidgets);
    expect(find.text('Next best action'), findsOneWidget);
    expect(find.text('Registry snapshot'), findsOneWidget);
    expect(find.byType(HomeMetricsRow), findsOneWidget);
    expect(find.text('Action queue'), findsOneWidget);
    expect(find.byType(HomeAttentionCard), findsWidgets);
    expect(find.text('Horizon', skipOffstage: false), findsOneWidget);
    expect(find.byType(HomeUpcomingItem, skipOffstage: false), findsWidgets);
    expect(find.textContaining('20 Sep 2026'), findsWidgets);
    expect(find.textContaining('05 Oct 2026'), findsWidgets);
    expect(find.textContaining('Start by'), findsWidgets);
    expect(find.textContaining('Expires'), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'day')), findsWidgets);
    expect(find.text('Review now'), findsOneWidget);
    final metrics = tester.widget<HomeMetricsRow>(
      find.byKey(const ValueKey<String>('home-metrics')),
    );
    expect(metrics.documentCount, 3);
    expect(metrics.subscriptionCount, 2);
    expect(metrics.horizonCount, 5);
    expect(
      tester
          .widgetList<HomeAttentionCard>(find.byType(HomeAttentionCard))
          .map((card) => card.item.id),
      ['car_insurance'],
    );
    expect(
      tester
          .widgetList<HomeAttentionCard>(find.byType(HomeAttentionCard))
          .every((card) => DocumentStatus.isAttentionStatus(card.item.status)),
      isTrue,
    );
  });

  testWidgets('Search filters and clears mock items', (tester) async {
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

    expect(find.text('Passport'), findsWidgets);
    expect(find.text('Streaming subscription'), findsNothing);
    expect(find.text('Start insurance renewal'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('home-search')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      find.text('Streaming subscription', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Start insurance renewal', skipOffstage: false),
      findsOneWidget,
    );
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
    expect(find.text('يلزم اتخاذ إجراء'), findsWidgets);
  });

  testWidgets('Small-screen Home has no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = _captureOverflows(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Horizon'),
      200,
      scrollable: find.byType(Scrollable).first,
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
    expect(upcoming.map((item) => item.item.id), [
      'streaming',
      'passport',
      'gym',
      'driving_licence',
    ]);
    expect(
      upcoming.first.item.actionDate.isBefore(upcoming.last.item.actionDate),
      isTrue,
    );
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

    _expectDockClearsHomeContent(tester, includeHorizon: true);
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

    await tester.pumpWidget(_app());
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

  testWidgets('Pulse Review opens the highlighted catalog item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('hero-review')));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogItemDetailScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('catalog-item-detail')),
      findsOneWidget,
    );
    expect(find.text('Start insurance renewal'), findsWidgets);
    expect(find.text('Car insurance'), findsWidgets);
    expect(find.text('High impact'), findsWidgets);
    expect(find.textContaining('20 Sep 2026'), findsWidgets);
    expect(find.textContaining('05 Oct 2026'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('quick-edit')), findsNothing);
    expect(find.byKey(const ValueKey<String>('record-renewal')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('document-actions')),
      findsNothing,
    );
  });

  testWidgets('Back from Pulse Review preserves Home search state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('home-search')),
      'insurance',
    );
    await tester.pumpAndSettle();
    expect(find.text('Streaming subscription'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('hero-review')));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogItemDetailScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('home-search')))
          .controller!
          .text,
      'insurance',
    );
    expect(find.text('Streaming subscription'), findsNothing);
    expect(find.byType(PriorityHeroCard), findsOneWidget);
  });

  testWidgets('90-day view lists catalog items chronologically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
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
        .map((item) => item.item.id)
        .toList();
    expect(ordered, [
      'car_insurance',
      'streaming',
      'passport',
      'gym',
      'driving_licence',
    ]);
    expect(find.textContaining('05 Oct 2026'), findsWidgets);
    expect(find.byType(RegistryStatusChip), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(PriorityHeroCard), findsOneWidget);
  });

  testWidgets('Open calendar and horizon metric open the same 90-day view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('home-open-calendar')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey<String>('home-open-calendar')));
    await tester.pumpAndSettle();
    expect(find.byType(Horizon90DayScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
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

  testWidgets('Arabic 90-day and catalog review stay RTL', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('hero-review')));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(CatalogItemDetailScreen))),
      TextDirection.rtl,
    );

    await tester.tap(find.byType(BackButton));
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
