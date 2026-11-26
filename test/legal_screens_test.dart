import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/features/legal/presentation/privacy_policy_screen.dart';
import 'package:the_registry/features/legal/presentation/terms_and_conditions_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_onboarding_repository.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PrivacyPolicyScreen renders correctly with all key sections', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const PrivacyPolicyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsAtLeast(1));
    expect(find.text('Last updated: November 2026'), findsOneWidget);
    expect(find.text('100% Local-First Vault'), findsOneWidget);
    expect(find.text('Private AI Document Scanning'), findsOneWidget);
    expect(find.text('On-Device Receipt Detection'), findsOneWidget);
    expect(find.text('User-Controlled Encrypted Backups'), findsOneWidget);

    // Verify detailed clauses
    expect(find.text('Local-First Data Architecture'), findsOneWidget);
    expect(find.text('AI Document Scanning (Gemini & Firebase AI Logic)'), findsOneWidget);

    // Scroll down to Terms button
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    final termsBtn = find.widgetWithText(OutlinedButton, 'Terms & Conditions');
    expect(termsBtn, findsOneWidget);

    await tester.tap(termsBtn);
    await tester.pumpAndSettle();

    expect(find.byType(TermsAndConditionsScreen), findsOneWidget);
  });

  testWidgets('TermsAndConditionsScreen renders correctly with all key sections', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const TermsAndConditionsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Terms & Conditions'), findsAtLeast(1));
    expect(find.text('Last updated: November 2026'), findsOneWidget);
    expect(find.text('Personal Vault License'), findsOneWidget);
    expect(find.text('Backup & Custody Responsibility'), findsOneWidget);
    expect(find.text('AI Assistance & Verification'), findsOneWidget);
    expect(find.text('Service Disclaimer'), findsOneWidget);

    // Verify detailed clauses
    expect(find.text('Acceptance of Terms'), findsOneWidget);
    expect(find.text('User Custody & Backup Responsibilities'), findsOneWidget);

    // Scroll down to Privacy Policy button
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    final privacyBtn = find.widgetWithText(OutlinedButton, 'Privacy Policy');
    expect(privacyBtn, findsOneWidget);

    await tester.tap(privacyBtn);
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
  });

  testWidgets('Profile / Settings tab shows legal section and can navigate to Privacy Policy and Terms', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Profile in navigation dock
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();

    // Verify legal section is visible
    expect(find.byKey(const ValueKey<String>('legal-section')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('privacy-policy-tile')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('terms-conditions-tile')), findsOneWidget);

    // Tap Privacy Policy tile
    await tester.tap(find.byKey(const ValueKey<String>('privacy-policy-tile')));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);

    // Pop back to Profile
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Tap Terms & Conditions tile
    await tester.tap(find.byKey(const ValueKey<String>('terms-conditions-tile')));
    await tester.pumpAndSettle();

    expect(find.byType(TermsAndConditionsScreen), findsOneWidget);
  });
}
