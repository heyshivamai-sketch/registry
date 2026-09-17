import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/profile/presentation/profile_placeholder_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_placeholder_screen.dart';

import 'support/fake_onboarding_repository.dart';

Widget _app({Locale locale = const Locale('en')}) {
  return RegistryApp(
    onboardingRepository: FakeOnboardingRepository(completed: true),
    locale: locale,
  );
}

Finder _navLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Completed onboarding opens Home', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Your Registry'), findsOneWidget);
    expect(find.text('Stay ahead of what matters'), findsOneWidget);
  });

  testWidgets('Bottom navigation changes tabs', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No documents yet'), findsNothing);
    await tester.tap(_navLabel('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('No documents yet'), findsOneWidget);

    await tester.tap(_navLabel('Subscriptions'));
    await tester.pumpAndSettle();
    expect(find.text('No subscriptions yet'), findsOneWidget);

    await tester.tap(_navLabel('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Your Registry'), findsOneWidget);
  });

  testWidgets('Profile icon opens Profile placeholder', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-profile')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePlaceholderScreen), findsOneWidget);
    expect(
      find.text(
        'There is no account in this version. Registry will keep your records private on this device.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Search filters mock items', (tester) async {
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
  });

  testWidgets('Search clear restores items', (tester) async {
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
    expect(
      find.byKey(const ValueKey<String>('home-search-clear')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    final controller = tester
        .widget<TextField>(find.byKey(const ValueKey<String>('home-search')))
        .controller!;
    expect(controller.text, isEmpty);
    expect(
      find.text('Streaming subscription', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Start insurance renewal', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('FAB opens Add bottom sheet', (tester) async {
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

  testWidgets('Add Document opens its form', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-document')));
    await tester.pumpAndSettle();

    expect(find.byType(AddDocumentScreen), findsOneWidget);
    expect(find.text('Add a document'), findsOneWidget);
  });

  testWidgets('Add Subscription opens its placeholder', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-subscription')));
    await tester.pumpAndSettle();

    expect(find.byType(AddSubscriptionPlaceholderScreen), findsOneWidget);
    expect(
      find.textContaining('The subscription form and payment reminders'),
      findsOneWidget,
    );
  });

  testWidgets('Arabic renders the shell in RTL', (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('سجلك'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AppShell))),
      TextDirection.rtl,
    );
  });

  testWidgets('No visible overflow at a small-screen test size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details);
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
    expect(find.byType(AppShell), findsOneWidget);
  });
}
