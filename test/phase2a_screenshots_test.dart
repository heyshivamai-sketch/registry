import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/app_lock/app_lock_store.dart';
import 'package:the_registry/features/entitlements/local_pro_entitlement.dart';
import 'package:the_registry/features/entitlements/local_pro_store.dart';
import 'package:the_registry/features/entitlements/presentation/local_pro_screen.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/phase2_fakes.dart';
import 'support/save_screenshot.dart';

const _folder = 'phase2a_local_pro';
const _launchFolder = 'launch_local_pro_ads';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.textScaleFactorTestValue = 1;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.clearTextScaleFactorTestValue();
  });

  testWidgets('fixture screenshots for Local Pro, app lock, and CSV review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      wrapForScreenshot(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          locale: const Locale('en'),
          clock: FixedClock(DateTime(2026, 9, 27)),
          appLockStore: MemoryAppLockStore(enabled: true),
          deviceAuthenticator: ScriptedDeviceAuthenticator(),
          privacyFlag: RecordingPrivacyFlag(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'fixture_app_lock', folder: _folder);

    await tester.pumpWidget(
      wrapForScreenshot(
        RegistryApp(
          key: const ValueKey<String>('phase2-unlocked'),
          onboardingRepository: FakeOnboardingRepository(completed: true),
          locale: const Locale('en'),
          clock: FixedClock(DateTime(2026, 9, 27)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    await tapProfileControl(tester, const ValueKey<String>('local-pro-open'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('local-pro-buy')),
      200,
      scrollable: find.descendant(
        of: find.byType(LocalProScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await saveScreenshot(
      tester,
      'fixture_local_pro_purchases_disabled',
      folder: _launchFolder,
    );

    final store = FakeLocalProStore(
      product: const StoreProduct.available(localizedPrice: 'DZD 2,400.00'),
    );
    await tester.pumpWidget(
      wrapForScreenshot(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          locale: const Locale('en'),
          clock: FixedClock(DateTime(2026, 9, 27)),
          localPro: LocalProEntitlement(purchasesEnabled: true, store: store),
          csvFiles: ScriptedCsvFileGateway(
            Uint8List.fromList(
              utf8.encode(
                'date,merchant,amount_minor,currency\n'
                '2026-01-01,City Gym,3500,USD\n'
                '2026-02-01,City Gym,3500,USD\n',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    await tapProfileControl(tester, const ValueKey<String>('local-pro-open'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('local-pro-restore')),
      200,
      scrollable: find.descendant(
        of: find.byType(LocalProScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await saveScreenshot(
      tester,
      'fixture_local_pro_fake_store_price',
      folder: _launchFolder,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapProfileControl(tester, const ValueKey<String>('csv-import-open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('csv-choose-file')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('csv-continue')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'fixture_csv_review', folder: _folder);
    await tester.pumpWidget(const SizedBox());
    await store.close();
  });
}
