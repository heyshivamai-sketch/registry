import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/core/widgets/registry_countdown_ring.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/home/widgets/home_attention_card.dart';
import 'package:the_registry/features/home/widgets/home_header.dart';
import 'package:the_registry/features/home/widgets/home_metrics_row.dart';
import 'package:the_registry/features/home/widgets/home_search_field.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/features/home/widgets/priority_hero_card.dart';
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

void _expectFabClearsHomeContent(
  WidgetTester tester, {
  required bool includeHorizon,
}) {
  final fab = tester.getRect(find.byKey(const ValueKey<String>('home-fab')));
  final metrics = find.byKey(const ValueKey<String>('home-metrics'));
  if (metrics.evaluate().isNotEmpty) {
    expect(_rectsOverlap(fab, tester.getRect(metrics)), isFalse);
  }

  if (includeHorizon) {
    expect(
      _rectsOverlap(
        fab,
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

  testWidgets('Home renders the modern dashboard sections', (tester) async {
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.text('Stay ahead of what matters'), findsOneWidget);
    expect(find.text('Your Registry'), findsOneWidget);
    expect(find.byType(HomeSearchField), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('home-filter')), findsNothing);
    expect(find.byType(PriorityHeroCard), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('hero-countdown')),
      findsOneWidget,
    );
    expect(find.byType(RegistryCountdownRing), findsOneWidget);
    expect(find.text('Action needed'), findsOneWidget);
    expect(find.text('Next action'), findsOneWidget);
    expect(find.byType(HomeMetricsRow), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Needs your attention'), findsOneWidget);
    expect(find.byType(HomeAttentionCard), findsWidgets);
    expect(find.text('Coming up', skipOffstage: false), findsOneWidget);
    expect(find.byType(HomeUpcomingItem, skipOffstage: false), findsWidgets);
    expect(find.textContaining('20 Sep 2026'), findsWidgets);
    expect(find.textContaining('05 Oct 2026'), findsWidgets);
    expect(find.textContaining('Start by'), findsWidgets);
    expect(find.textContaining('Expires'), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'day')), findsWidgets);
    expect(
      tester.widget<HomeMetricsRow>(
        find.byKey(const ValueKey<String>('home-metrics')),
      ),
      isA<HomeMetricsRow>(),
    );
    final metrics = tester.widget<HomeMetricsRow>(
      find.byKey(const ValueKey<String>('home-metrics')),
    );
    expect(metrics.documentCount, 3);
    expect(metrics.subscriptionCount, 2);
    expect(metrics.attentionCount, 3);
    expect(
      tester
          .widgetList<HomeAttentionCard>(find.byType(HomeAttentionCard))
          .map((card) => card.item.id),
      ['car_insurance', 'passport', 'streaming'],
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

  testWidgets('Profile control opens Profile', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-profile')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePlaceholderScreen), findsOneWidget);
  });

  testWidgets('FAB still opens the Add sheet', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Add to Registry'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('add-document')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('add-subscription')),
      findsOneWidget,
    );
  });

  testWidgets('Bottom navigation preserves Home search state', (tester) async {
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

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Documents'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('documents-add')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Subscriptions'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No subscriptions yet'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('subscriptions-add')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
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

  testWidgets('Bottom navigation still switches tabs', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Documents'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No documents yet'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Arabic Home stays RTL', (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('سجلك'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AppShell))),
      TextDirection.rtl,
    );
    expect(find.text('يلزم اتخاذ إجراء'), findsOneWidget);
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
      find.text('Coming up'),
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

  testWidgets('Coming up is chronological by action date', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
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
    expect(upcoming.map((item) => item.item.id), ['gym', 'driving_licence']);
    expect(upcoming.first.item.dueDate, DateTime.utc(2026, 10, 18));
    expect(upcoming.last.item.dueDate, DateTime.utc(2026, 12, 1));
    expect(
      upcoming.first.item.actionDate.isBefore(upcoming.last.item.actionDate),
      isTrue,
    );
  });

  testWidgets('Small-screen last Coming up card clears the FAB', (
    tester,
  ) async {
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

    final lastCard = tester.getRect(
      find.byKey(const ValueKey<String>('upcoming-driving_licence')),
    );
    final fab = tester.getRect(find.byKey(const ValueKey<String>('home-fab')));
    final overlapsHorizontally =
        lastCard.left < fab.right && lastCard.right > fab.left;
    final overlapsVertically =
        lastCard.top < fab.bottom && lastCard.bottom > fab.top;
    expect(overlapsHorizontally && overlapsVertically, isFalse);
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
    _expectFabClearsHomeContent(tester, includeHorizon: true);
  });

  testWidgets('Default layout uses an extended FAB that clears metrics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final fab = tester.widget<FloatingActionButton>(
      find.byKey(const ValueKey<String>('home-fab')),
    );
    expect(fab.isExtended, isTrue);
    _expectFabClearsHomeContent(tester, includeHorizon: false);
  });

  testWidgets('1.5x text uses a compact FAB that clears metrics', (
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

    final fab = tester.widget<FloatingActionButton>(
      find.byKey(const ValueKey<String>('home-fab')),
    );
    expect(fab.isExtended, isFalse);
    _expectFabClearsHomeContent(tester, includeHorizon: false);
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('1.8x text uses a compact FAB that clears metrics', (
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

    final fab = tester.widget<FloatingActionButton>(
      find.byKey(const ValueKey<String>('home-fab')),
    );
    expect(fab.isExtended, isFalse);
    _expectFabClearsHomeContent(tester, includeHorizon: false);
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('Narrow phone uses a compact FAB that clears metrics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final fab = tester.widget<FloatingActionButton>(
      find.byKey(const ValueKey<String>('home-fab')),
    );
    expect(fab.isExtended, isFalse);
    _expectFabClearsHomeContent(tester, includeHorizon: false);
  });

  testWidgets('Arabic RTL compact and extended FAB stay on the start edge', (
    tester,
  ) async {
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
    final fab = tester.widget<FloatingActionButton>(
      find.byKey(const ValueKey<String>('home-fab')),
    );
    expect(fab.isExtended, isTrue);
    final fabRect = tester.getRect(
      find.byKey(const ValueKey<String>('home-fab')),
    );
    expect(fabRect.left, lessThan(412 / 2));
    _expectFabClearsHomeContent(tester, includeHorizon: false);

    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    final compact = tester.widget<FloatingActionButton>(
      find.byKey(const ValueKey<String>('home-fab')),
    );
    expect(compact.isExtended, isFalse);
    final compactRect = tester.getRect(
      find.byKey(const ValueKey<String>('home-fab')),
    );
    expect(compactRect.left, lessThan(412 / 2));
    _expectFabClearsHomeContent(tester, includeHorizon: false);
  });

  testWidgets('Status chips use icon and text together', (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(RegistryStatusChip), findsWidgets);
    final chips = find.byType(RegistryStatusChip);
    expect(
      find.descendant(of: chips, matching: find.byType(Icon)),
      findsWidgets,
    );
    expect(
      find.descendant(of: chips, matching: find.byType(Text)),
      findsWidgets,
    );
    expect(find.text('Urgent'), findsWidgets);
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text('Active', skipOffstage: false), findsWidgets);
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
  });
}
