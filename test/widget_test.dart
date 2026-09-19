import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/app/theme/app_theme.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_secondary_button.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_summary_card.dart';
import 'package:the_registry/features/design_preview/presentation/design_preview_screen.dart';

import 'support/fake_onboarding_repository.dart';

void main() {
  testWidgets('Design preview shows foundation components', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const DesignPreviewScreen(),
      ),
    );

    expect(find.text('Registry'), findsOneWidget);
    expect(
      find.text(
        'A calm place to track documents and subscriptions before they expire.',
      ),
      findsOneWidget,
    );
    expect(find.byType(RegistrySummaryCard), findsOneWidget);
    expect(find.text('Upcoming actions'), findsOneWidget);
    expect(find.byType(RegistryStatusChip), findsNWidgets(4));
    expect(find.text('Action needed'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.byType(RegistryPrimaryButton), findsOneWidget);
    expect(find.byType(RegistrySecondaryButton), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(RegistryEmptyState),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byType(RegistryEmptyState), findsOneWidget);
    expect(find.text('Nothing to review'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('Completed onboarding does not open design preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DesignPreviewScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });
}
