import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/features/entitlements/local_pro_entitlement.dart';
import 'package:the_registry/features/entitlements/local_pro_store.dart';
import 'package:the_registry/features/entitlements/presentation/local_pro_screen.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/phase2_fakes.dart';

void main() {
  Future<void> openLocalPro(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    await tapProfileControl(tester, const ValueKey<String>('local-pro-open'));
  }

  Future<void> scrollTo(WidgetTester tester, String key) async {
    await tester.scrollUntilVisible(
      find.byKey(ValueKey<String>(key)),
      200,
      scrollable: find.descendant(
        of: find.byType(LocalProScreen),
        matching: find.byType(Scrollable),
      ),
    );
  }

  RegistryPlan planOf(WidgetTester tester) {
    return RegistryDependencies.of(
      tester.element(find.byType(LocalProScreen)),
    ).entitlements.plan;
  }

  testWidgets('with purchases off, Buy explains why and Restore is hidden', (
    tester,
  ) async {
    await openLocalPro(
      tester,
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
      ),
    );

    expect(find.byType(LocalProScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('An ad-free experience'),
      180,
      scrollable: find.descendant(
        of: find.byType(LocalProScreen),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.textContaining('An ad-free experience'), findsOneWidget);
    await scrollTo(tester, 'local-pro-buy');
    expect(
      find.byKey(const ValueKey<String>('local-pro-purchases-disabled')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Purchases are not available yet'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('local-pro-price')), findsNothing);
    expect(find.textContaining('\$'), findsNothing);
    expect(_buyButton(tester).onPressed, isNull);
    expect(
      find.byKey(const ValueKey<String>('local-pro-restore')),
      findsNothing,
    );
    expect(planOf(tester), RegistryPlan.free);
  });

  testWidgets('shows the store price and turns Pro on after a store purchase', (
    tester,
  ) async {
    final store =
        FakeLocalProStore(
            product: const StoreProduct.available(
              localizedPrice: 'DZD 2,400.00',
            ),
          )
          ..onBuy = (store) {
            store.ownership = StoreOwnership.owned;
            store.emit([
              localProTransaction(
                StoreTransactionStatus.purchased,
                storeConfirmed: true,
              ),
            ]);
          };
    await openLocalPro(
      tester,
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
        localPro: LocalProEntitlement(purchasesEnabled: true, store: store),
      ),
    );

    await scrollTo(tester, 'local-pro-buy');
    expect(find.text('DZD 2,400.00'), findsOneWidget);
    expect(planOf(tester), RegistryPlan.free);
    await tester.tap(find.byKey(const ValueKey<String>('local-pro-buy')));
    await tester.pumpAndSettle();

    expect(store.buyCalls, 1);
    expect(planOf(tester), RegistryPlan.localPro);
    expect(store.completed, hasLength(1));
    expect(find.text('Regiday Pro is active.'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('local-pro-buy')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('local-pro-status-active')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await store.close();
  });

  testWidgets('a missing product disables Buy and keeps Restore available', (
    tester,
  ) async {
    final store = FakeLocalProStore(product: const StoreProduct.missing());
    await openLocalPro(
      tester,
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
        localPro: LocalProEntitlement(purchasesEnabled: true, store: store),
      ),
    );

    await scrollTo(tester, 'local-pro-restore');
    expect(
      find.byKey(const ValueKey<String>('local-pro-price-unavailable')),
      findsOneWidget,
    );
    expect(_buyButton(tester).onPressed, isNull);

    store.ownership = StoreOwnership.owned;
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('local-pro-restore')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('local-pro-restore')));
    await tester.pumpAndSettle();
    expect(store.syncCalls, 1);
    expect(planOf(tester), RegistryPlan.localPro);
    expect(find.text('Regiday Pro is active.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await store.close();
  });

  testWidgets('a pending purchase is shown and does not turn Pro on', (
    tester,
  ) async {
    final store = FakeLocalProStore()
      ..onBuy = (store) {
        store.ownership = StoreOwnership.pending;
        store.emit([localProTransaction(StoreTransactionStatus.pending)]);
      };
    final localPro = LocalProEntitlement(
      purchasesEnabled: true,
      store: store,
      purchaseTimeout: const Duration(seconds: 1),
    );
    await openLocalPro(
      tester,
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
        localPro: localPro,
      ),
    );

    await scrollTo(tester, 'local-pro-buy');
    await tester.tap(find.byKey(const ValueKey<String>('local-pro-buy')));
    await tester.pumpAndSettle();
    expect(localPro.pendingPurchase, isTrue);
    expect(planOf(tester), RegistryPlan.free);
    expect(
      find.byKey(const ValueKey<String>('local-pro-pending')),
      findsOneWidget,
    );
    expect(store.completed, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await store.close();
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
    final store = FakeLocalProStore(
      product: const StoreProduct.available(localizedPrice: 'DZD 2,400.00'),
    );
    await openLocalPro(
      tester,
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('ar'),
        localPro: LocalProEntitlement(purchasesEnabled: true, store: store),
      ),
    );
    expect(
      Directionality.of(tester.element(find.byType(LocalProScreen))),
      TextDirection.rtl,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('local-pro-restore')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await store.close();
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
