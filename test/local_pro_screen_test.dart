import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/features/entitlements/billing_configuration.dart';
import 'package:the_registry/features/entitlements/presentation/local_pro_screen.dart';
import 'package:the_registry/features/entitlements/purchase_service.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/features/entitlements/verified_entitlement.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/phase2_fakes.dart';

void main() {
  testWidgets('unconfigured Local Pro has no price and no working buy button', (
    tester,
  ) async {
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    await tapProfileControl(tester, const ValueKey<String>('local-pro-open'));

    expect(find.byType(LocalProScreen), findsOneWidget);
    expect(find.textContaining('cloud'), findsWidgets);
    final scrollable = find.descendant(
      of: find.byType(LocalProScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('local-pro-account-explanation')),
      200,
      scrollable: scrollable,
    );
    expect(
      find.byKey(const ValueKey<String>('local-pro-account-explanation')),
      findsOneWidget,
    );
    expect(
      find.textContaining('verify your email before you buy'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('local-pro-account-unavailable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('local-pro-account-send')),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('local-pro-buy')),
      200,
      scrollable: find.descendant(
        of: find.byType(LocalProScreen),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('local-pro-price-unavailable')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('local-pro-price')), findsNothing);
    expect(find.textContaining('\$'), findsNothing);
    expect(_buyButton(tester).onPressed, isNull);
    expect(
      RegistryDependencies.of(
        tester.element(find.byType(LocalProScreen)),
      ).entitlements.plan,
      RegistryPlan.free,
    );
  });

  testWidgets('a store price can be shown without granting an unverified buy', (
    tester,
  ) async {
    final purchases = ScriptedPurchaseService(
      proof: const VerifiedEntitlementProof(
        productId: BillingConfiguration.localProProductId,
        accepted: true,
        clientSuppliedOnly: true,
      ),
    );
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
        storeProducts: ScriptedStoreProductSource(
          const StoreListing(
            productId: BillingConfiguration.localProProductId,
            localizedPrice: 'DZD 2,400.00',
          ),
        ),
        purchaseService: purchases,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    await tapProfileControl(tester, const ValueKey<String>('local-pro-open'));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('local-pro-buy')),
      200,
      scrollable: find.descendant(
        of: find.byType(LocalProScreen),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('DZD 2,400.00'), findsOneWidget);
    expect(_buyButton(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey<String>('local-pro-buy')));
    await tester.pumpAndSettle();

    expect(purchases.calls, 1);
    expect(
      RegistryDependencies.of(
        tester.element(find.byType(LocalProScreen)),
      ).entitlements.plan,
      RegistryPlan.free,
    );
    expect(find.textContaining('stays off'), findsOneWidget);
  });

  testWidgets('Arabic Local Pro scrolls at large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('ar'),
        storeProducts: ScriptedStoreProductSource(
          const StoreListing(
            productId: 'local_pro',
            localizedPrice: 'DZD 2,400.00',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    await tapProfileControl(tester, const ValueKey<String>('local-pro-open'));
    expect(
      Directionality.of(tester.element(find.byType(LocalProScreen))),
      TextDirection.rtl,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('local-pro-buy')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });
}

FilledButton _buyButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.descendant(
      of: find.byKey(const ValueKey<String>('local-pro-buy')),
      matching: find.byType(FilledButton),
    ),
  );
}
