import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/core/widgets/registry_navigation_dock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/documents/presentation/document_detail_screen.dart';
import 'package:the_registry/features/documents/presentation/documents_screen.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscriptions_screen.dart';
import '../test/support/fake_onboarding_repository.dart';
import '../test/support/sample_document.dart';
import '../test/support/sample_subscription.dart';

Finder _homeScrollable() {
  return find.descendant(
    of: find.byType(HomeScreen),
    matching: find.byType(Scrollable),
  );
}

Future<void> _assertAboveDock(WidgetTester tester, Finder item) async {
  final dock = tester.getRect(find.byType(RegistryAuraNavigationDock));
  final box = tester.getRect(item);
  expect(box.bottom, lessThanOrEqualTo(dock.top + 2));
  expect(item.hitTestable(), findsOneWidget);
}

Future<void> _hold(WidgetTester tester, String tag) async {
  debugPrint('AURA_QA:$tag');
  await tester.pump(const Duration(seconds: 6));
}

Future<void> _seed(
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final clock = FixedClock(DateTime(2026, 9, 19));

  testWidgets('Aura Home device frames', (tester) async {
    await tester.pumpWidget(
      RegistryApp(
        key: const ValueKey<String>('home-qa-empty'),
        onboardingRepository: FakeOnboardingRepository(completed: true),
        clock: clock,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    await _hold(tester, 'empty');

    await tester.tap(
      find.byKey(const ValueKey<String>('home-add-first-document')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AddDocumentScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('home-add-first-subscription')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AddSubscriptionScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final emptyBenefit = find.text('Stay in control of your spending.');
    await tester.scrollUntilVisible(
      emptyBenefit,
      80,
      scrollable: _homeScrollable().first,
    );
    await tester.pumpAndSettle();
    await _assertAboveDock(tester, emptyBenefit);
    await _hold(tester, 'empty_bottom');

    final documents = InMemoryDocumentRepository();
    final subscriptions = InMemorySubscriptionRepository();
    await _seed(documents, subscriptions);
    await tester.pumpWidget(
      RegistryApp(
        key: const ValueKey<String>('home-qa-populated'),
        onboardingRepository: FakeOnboardingRepository(completed: true),
        documentRepository: documents,
        subscriptionRepository: subscriptions,
        clock: clock,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    await _hold(tester, 'populated');

    await tester.tap(find.byKey(const ValueKey<String>('hero-review')));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    await tester.pageBack();
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
    expect(find.byType(SubscriptionsScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(HomeScreen), const Offset(0, -720));
    await tester.pumpAndSettle();
    final lastComingUp = find.text('Passport');
    if (lastComingUp.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        lastComingUp.first,
        80,
        scrollable: _homeScrollable().first,
      );
      await tester.pumpAndSettle();
      await _assertAboveDock(tester, lastComingUp.first);
    }
    await _hold(tester, 'populated_bottom');

    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    tester.state<AppShellState>(find.byType(AppShell)).selectTab(1);
    await tester.pumpAndSettle();
    final documentsAdd = find.byKey(const ValueKey<String>('documents-add'));
    expect(documentsAdd, findsOneWidget);
    await tester.ensureVisible(documentsAdd);
    await tester.pumpAndSettle();
    await _assertAboveDock(tester, documentsAdd);
    await tester.tap(documentsAdd);
    await tester.pumpAndSettle();
    expect(find.byType(AddDocumentScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _hold(tester, 'documents');

    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();
    tester.state<AppShellState>(find.byType(AppShell)).selectTab(2);
    await tester.pumpAndSettle();
    await _hold(tester, 'subscriptions');
    final subscriptionsAdd = find.byKey(
      const ValueKey<String>('subscriptions-add'),
      skipOffstage: false,
    );
    expect(subscriptionsAdd, findsOneWidget);
    await tester.ensureVisible(subscriptionsAdd);
    await tester.pumpAndSettle();
    await _assertAboveDock(tester, subscriptionsAdd);
    await tester.tap(subscriptionsAdd);
    await tester.pumpAndSettle();
    expect(find.byType(AddSubscriptionScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    await tester.pumpAndSettle();
    final messenger = ScaffoldMessenger.of(
      tester.element(find.byType(AppShell)),
    );
    messenger.showSnackBar(const SnackBar(content: Text('QA snackbar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _assertAboveDock(tester, find.text('QA snackbar'));
    await _hold(tester, 'snackbar');
    messenger.hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(HomeScreen), const Offset(0, 800));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('home-search')),
      'zzzzzz',
    );
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('home-search-empty')),
      findsOneWidget,
    );
    await _hold(tester, 'search');

    await tester.pumpWidget(
      RegistryApp(
        key: const ValueKey<String>('home-qa-arabic'),
        onboardingRepository: FakeOnboardingRepository(completed: true),
        documentRepository: documents,
        subscriptionRepository: subscriptions,
        clock: clock,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(AppShell))),
      TextDirection.rtl,
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey<String>('nav-home'))).label,
      isNotEmpty,
    );
    await _hold(tester, 'arabic');

    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      RegistryApp(
        key: const ValueKey<String>('home-qa-large'),
        onboardingRepository: FakeOnboardingRepository(completed: true),
        documentRepository: documents,
        subscriptionRepository: subscriptions,
        clock: clock,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RegistryAuraNavigationDock), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey<String>('nav-home'))).label,
      isNotEmpty,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('nav-documents')))
          .label,
      isNotEmpty,
    );
    await _hold(tester, 'large');
  });
}
