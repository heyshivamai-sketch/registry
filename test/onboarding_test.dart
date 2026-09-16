import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/features/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'package:the_registry/features/onboarding/presentation/onboarding_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_onboarding_repository.dart';

Widget _app({
  required FakeOnboardingRepository repository,
  Locale locale = const Locale('en'),
}) {
  return RegistryApp(onboardingRepository: repository, locale: locale);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('First launch displays onboarding', (tester) async {
    await tester.pumpWidget(_app(repository: FakeOnboardingRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Never miss an important date'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('Continue changes pages', (tester) async {
    await tester.pumpWidget(_app(repository: FakeOnboardingRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Stay ahead of every charge'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Skip completes onboarding', (tester) async {
    final repository = FakeOnboardingRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(repository.completed, isTrue);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('Get started completes onboarding', (tester) async {
    final repository = FakeOnboardingRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('onboarding-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Your information stays with you'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('onboarding-skip')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding-get-started')),
    );
    await tester.pumpAndSettle();

    expect(repository.completed, isTrue);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('Completed onboarding opens Home', (tester) async {
    await tester.pumpWidget(
      _app(repository: FakeOnboardingRepository(completed: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Your Registry'), findsOneWidget);
  });

  testWidgets('Arabic locale renders RTL', (tester) async {
    await tester.pumpWidget(
      _app(repository: FakeOnboardingRepository(), locale: const Locale('ar')),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا تفوّت موعدًا مهمًا'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(OnboardingScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('Unsupported device language falls back to English', (
    tester,
  ) async {
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(),
        locale: const Locale('de'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Never miss an important date'), findsOneWidget);
    expect(
      AppLocalizations.of(
        tester.element(find.byType(OnboardingScreen)),
      ).localeName,
      'en',
    );
  });

  test('Shared preferences repository stores completion', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesOnboardingRepository(preferences);

    expect(await repository.isCompleted(), isFalse);
    await repository.complete();
    expect(await repository.isCompleted(), isTrue);
    await repository.reset();
    expect(await repository.isCompleted(), isFalse);
  });
}
