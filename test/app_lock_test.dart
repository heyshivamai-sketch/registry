import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/app_lock/app_lock_controller.dart';
import 'package:the_registry/features/app_lock/app_lock_policy.dart';
import 'package:the_registry/features/app_lock/app_lock_store.dart';
import 'package:the_registry/features/app_lock/device_authenticator.dart';
import 'package:the_registry/features/app_lock/platform_device_authenticator.dart';
import 'package:the_registry/features/app_lock/presentation/app_lock_gate.dart';
import 'package:the_registry/features/backup/presentation/profile_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/phase2_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'app lock covers cold start, cancel, timeout, and unavailable auth',
    () async {
      expect(AppLockPolicy.relockTimeout, const Duration(seconds: 30));
      final clock = MutableClock(DateTime(2026, 9, 27, 12));
      final store = MemoryAppLockStore(enabled: true);
      final auth = ScriptedDeviceAuthenticator();
      final privacy = RecordingPrivacyFlag();
      final lock = AppLockController(
        store: store,
        authenticator: auth,
        clock: clock,
        privacy: privacy,
      );
      expect(lock.sessionLocked, isTrue);
      expect(privacy.secure, isTrue);

      auth.authenticateResult = DeviceAuthAttempt.cancelled;
      expect(await lock.unlock(localizedReason: 'Unlock'), isFalse);
      expect(lock.sessionLocked, isTrue);
      expect(lock.block, AppLockBlock.cancelled);
      expect(auth.authenticateCalls, 1);

      auth.availabilityResult = DeviceAuthAvailability.unavailable;
      expect(await lock.unlock(localizedReason: 'Unlock'), isFalse);
      expect(lock.block, AppLockBlock.unavailable);
      expect(auth.authenticateCalls, 1);

      auth.availabilityResult = DeviceAuthAvailability.ready;
      auth.authenticateResult = DeviceAuthAttempt.authenticated;
      final duringAuth = _AuthThatBackgrounds(clock);
      final unlockedStore = MemoryAppLockStore(enabled: true);
      final session = AppLockController(
        store: unlockedStore,
        authenticator: duringAuth,
        clock: clock,
        privacy: RecordingPrivacyFlag(),
      );
      duringAuth.lock = session;
      expect(await session.unlock(localizedReason: 'Unlock'), isTrue);
      expect(session.sessionLocked, isFalse);

      session.onLifecycle(AppLifecycleState.inactive);
      expect(session.obscured, isTrue);
      expect(session.sessionLocked, isFalse);
      clock.advance(const Duration(seconds: 29));
      session.onLifecycle(AppLifecycleState.resumed);
      expect(session.sessionLocked, isFalse);
      expect(session.obscured, isFalse);

      session.onLifecycle(AppLifecycleState.paused);
      clock.advance(AppLockPolicy.relockTimeout);
      session.onLifecycle(AppLifecycleState.resumed);
      expect(session.sessionLocked, isTrue);

      final off = MemoryAppLockStore();
      final enableAuth = ScriptedDeviceAuthenticator()
        ..availabilityResult = DeviceAuthAvailability.unavailable;
      final enabling = AppLockController(
        store: off,
        authenticator: enableAuth,
        clock: clock,
        privacy: RecordingPrivacyFlag(),
      );
      expect(
        await enabling.enable(localizedReason: 'Enable'),
        AppLockEnableResult.unavailable,
      );
      expect(off.enabled, isFalse);
      expect(enableAuth.authenticateCalls, 0);

      enableAuth.availabilityResult = DeviceAuthAvailability.ready;
      enableAuth.authenticateResult = DeviceAuthAttempt.cancelled;
      expect(
        await enabling.enable(localizedReason: 'Enable'),
        AppLockEnableResult.cancelled,
      );
      expect(off.enabled, isFalse);

      enableAuth.authenticateResult = DeviceAuthAttempt.authenticated;
      expect(
        await enabling.enable(localizedReason: 'Enable'),
        AppLockEnableResult.enabled,
      );
      expect(off.enabled, isTrue);
      expect(enabling.sessionLocked, isFalse);
    },
  );

  testWidgets('cold start hides records until authentication succeeds', (
    tester,
  ) async {
    final auth = ScriptedDeviceAuthenticator()
      ..authenticateResult = DeviceAuthAttempt.cancelled;
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
        appLockStore: MemoryAppLockStore(enabled: true),
        deviceAuthenticator: auth,
        privacyFlag: RecordingPrivacyFlag(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppLockScreen), findsOneWidget);
    expect(find.text('Your Registry'), findsNothing);
    expect(find.textContaining('does not encrypt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('app-lock-unlock')));
    await tester.pumpAndSettle();
    expect(find.byType(AppLockScreen), findsOneWidget);
    expect(find.text('Your Registry'), findsNothing);

    auth.authenticateResult = DeviceAuthAttempt.authenticated;
    await tester.tap(find.byKey(const ValueKey<String>('app-lock-unlock')));
    await tester.pumpAndSettle();
    expect(find.byType(AppLockScreen), findsNothing);
    expect(find.text('Your Registry'), findsOneWidget);

    final lock = RegistryDependencies.of(
      tester.element(find.byType(AppShell)),
    ).appLock;
    lock.onLifecycle(AppLifecycleState.inactive);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('app-privacy-cover')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Your Registry'), findsNothing);
  });

  test(
    'successful disable stores the off setting only after authentication',
    () async {
      final harness = _DisableHarness(DeviceAuthAttempt.authenticated);
      expect(
        await harness.lock.disable(localizedReason: 'Turn off app lock'),
        AppLockDisableResult.disabled,
      );
      expect(harness.auth.enabledDuringAuthenticate, isTrue);
      expect(harness.auth.authenticateCalls, 1);
      expect(harness.auth.lastReason, 'Turn off app lock');
      expect(harness.store.enabled, isFalse);
      expect(harness.store.writes, [false]);
      expect(harness.privacy.secure, isFalse);
      expect(harness.lock.sessionLocked, isFalse);
    },
  );

  test('cancelled disable keeps app lock enabled', () async {
    final harness = _DisableHarness(DeviceAuthAttempt.authenticated);
    expect(await harness.lock.unlock(localizedReason: 'Unlock'), isTrue);
    harness.auth.authenticateResult = DeviceAuthAttempt.cancelled;
    expect(
      await harness.lock.disable(localizedReason: 'Turn off app lock'),
      AppLockDisableResult.cancelled,
    );
    expect(harness.auth.enabledDuringAuthenticate, isTrue);
    expect(harness.store.enabled, isTrue);
    expect(harness.store.writes, isEmpty);
    expect(harness.privacy.secure, isTrue);
    expect(harness.lock.sessionLocked, isFalse);
  });

  test('failed authentication keeps app lock enabled', () async {
    final harness = _DisableHarness(DeviceAuthAttempt.failed);
    expect(
      await harness.lock.disable(localizedReason: 'Turn off app lock'),
      AppLockDisableResult.failed,
    );
    expect(harness.store.enabled, isTrue);
    expect(harness.store.writes, isEmpty);
    expect(harness.privacy.secure, isTrue);
  });

  test('a platform error keeps app lock enabled', () async {
    final harness = _DisableHarness(DeviceAuthAttempt.platformError);
    expect(
      await harness.lock.disable(localizedReason: 'Turn off app lock'),
      AppLockDisableResult.platformError,
    );
    expect(harness.store.enabled, isTrue);
    expect(harness.store.writes, isEmpty);
    expect(harness.privacy.secure, isTrue);

    harness.auth.availabilityResult = DeviceAuthAvailability.unavailable;
    expect(
      await harness.lock.disable(localizedReason: 'Turn off app lock'),
      AppLockDisableResult.unavailable,
    );
    expect(harness.auth.authenticateCalls, 1);
    expect(harness.store.enabled, isTrue);
    expect(harness.store.writes, isEmpty);
  });

  test('local_auth distinguishes cancellation from platform errors', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<DeviceAuthAttempt> attempt(Object outcome) {
      return PlatformDeviceAuthenticator(
        gateway: _ScriptedLocalAuth(outcome),
      ).authenticate(localizedReason: 'Confirm it is you');
    }

    expect(await attempt(true), DeviceAuthAttempt.authenticated);
    expect(await attempt(false), DeviceAuthAttempt.cancelled);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(await attempt(false), DeviceAuthAttempt.failed);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(await attempt(false), DeviceAuthAttempt.failed);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(await attempt(false), DeviceAuthAttempt.failed);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const secret = 'pin 1357 PersistQAPassport';
    expect(
      await attempt(PlatformException(code: 'UserCancelled', message: secret)),
      DeviceAuthAttempt.cancelled,
    );
    expect(
      await attempt(PlatformException(code: 'UserFallback', message: secret)),
      DeviceAuthAttempt.cancelled,
    );
    for (final code in const [
      'NotAvailable',
      'NotEnrolled',
      'PasscodeNotSet',
      'LockedOut',
      'PermanentlyLockedOut',
      'no_fragment_activity',
      'no_activity',
      'auth_in_progress',
      'BiometricNotAvailable',
      'channel-error',
    ]) {
      expect(
        await attempt(PlatformException(code: code, message: secret)),
        DeviceAuthAttempt.platformError,
        reason: code,
      );
    }
    expect(await attempt(StateError(secret)), DeviceAuthAttempt.platformError);

    final unsupported = PlatformDeviceAuthenticator(
      gateway: _ScriptedLocalAuth(false, supported: false),
    );
    expect(
      await unsupported.availability(),
      DeviceAuthAvailability.unavailable,
    );
    expect(
      await PlatformDeviceAuthenticator(
        gateway: _ScriptedLocalAuth(false, throwsOnSupport: true),
      ).availability(),
      DeviceAuthAvailability.unavailable,
    );
  });

  test(
    'app lock errors have distinct English, French, and Arabic copy',
    () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final ar = await AppLocalizations.delegate.load(const Locale('ar'));

      expect(
        en.appLockDisableCancelled,
        'Authentication was cancelled. App lock stays on.',
      );
      expect(
        en.appLockDisableFailed,
        'Authentication failed. App lock stays on.',
      );
      expect(
        en.appLockPlatformError,
        "Regiday could not use this device's authentication. App lock was not changed.",
      );
      expect(
        en.appLockPlatformError.toLowerCase(),
        isNot(contains('cancelled')),
      );
      expect(en.appLockDisableCancelled, isNot(en.appLockCancelled));
      expect(fr.appLockDisableCancelled, isNot(en.appLockDisableCancelled));
      expect(fr.appLockDisableFailed, isNot(en.appLockDisableFailed));
      expect(fr.appLockPlatformError, isNot(en.appLockPlatformError));
      expect(ar.appLockDisableCancelled, isNot(en.appLockDisableCancelled));
      expect(ar.appLockDisableFailed, isNot(en.appLockDisableFailed));
      expect(ar.appLockPlatformError, isNot(en.appLockPlatformError));
      expect(fr.appLockUnlockPlatformError, isNotEmpty);
      expect(ar.appLockUnlockFailed, isNotEmpty);
    },
  );

  testWidgets(
    'profile keeps app lock on until a disable authentication succeeds',
    (tester) async {
      final store = _WriteLogStore();
      final auth = ScriptedDeviceAuthenticator();
      final privacy = RecordingPrivacyFlag();
      await tester.pumpWidget(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          locale: const Locale('en'),
          appLockStore: store,
          deviceAuthenticator: auth,
          privacyFlag: privacy,
        ),
      );
      await tester.pumpAndSettle();
      await _openLockSwitch(tester);

      expect(find.text('App lock is off'), findsOneWidget);
      await _toggleLock(tester);
      expect(store.enabled, isTrue);
      expect(store.writes, [true]);
      expect(privacy.secure, isTrue);
      expect(find.text('App lock is on'), findsOneWidget);
      expect(auth.lastReason, 'Confirm it is you before turning on app lock.');

      auth.authenticateResult = DeviceAuthAttempt.cancelled;
      await _toggleLock(tester);
      expect(
        find.text('Authentication was cancelled. App lock stays on.'),
        findsOneWidget,
      );
      expect(store.enabled, isTrue);
      expect(store.writes, [true]);
      expect(privacy.secure, isTrue);
      expect(find.text('App lock is on'), findsOneWidget);

      auth.authenticateResult = DeviceAuthAttempt.failed;
      await _toggleLock(tester);
      expect(
        find.text('Authentication failed. App lock stays on.'),
        findsOneWidget,
      );
      expect(store.enabled, isTrue);
      expect(privacy.secure, isTrue);

      auth.authenticateResult = DeviceAuthAttempt.platformError;
      await _toggleLock(tester);
      expect(
        find.text(
          "Regiday could not use this device's authentication. App lock was not changed.",
        ),
        findsOneWidget,
      );
      expect(find.textContaining('no_fragment_activity'), findsNothing);
      expect(store.enabled, isTrue);
      expect(store.writes, [true]);
      expect(privacy.secure, isTrue);

      auth.authenticateResult = DeviceAuthAttempt.authenticated;
      await _toggleLock(tester);
      expect(store.enabled, isFalse);
      expect(store.writes, [true, false]);
      expect(privacy.secure, isFalse);
      expect(find.text('App lock is off'), findsOneWidget);
      expect(auth.lastReason, 'Confirm it is you before turning off app lock.');
    },
  );
}

Future<void> _openLockSwitch(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
  await tester.pumpAndSettle();
  final scrollable = find.descendant(
    of: find.byType(ProfileScreen),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey<String>('app-lock-switch')),
    200,
    scrollable: scrollable,
  );
  await tester.pumpAndSettle();
}

Future<void> _toggleLock(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('app-lock-switch')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _AuthThatBackgrounds implements DeviceAuthenticator {
  _AuthThatBackgrounds(this.clock);

  final MutableClock clock;
  AppLockController? lock;

  @override
  Future<DeviceAuthAvailability> availability() async {
    return DeviceAuthAvailability.ready;
  }

  @override
  Future<DeviceAuthAttempt> authenticate({
    required String localizedReason,
  }) async {
    final controller = lock!;
    controller.onLifecycle(AppLifecycleState.inactive);
    clock.advance(const Duration(minutes: 5));
    controller.onLifecycle(AppLifecycleState.resumed);
    return DeviceAuthAttempt.authenticated;
  }
}

class _WriteLogStore extends MemoryAppLockStore {
  _WriteLogStore({super.enabled});

  final writes = <bool>[];

  @override
  Future<void> setEnabled(bool value) async {
    writes.add(value);
    await super.setEnabled(value);
  }
}

class _DisableHarness {
  _DisableHarness(DeviceAuthAttempt result)
    : store = _WriteLogStore(enabled: true),
      privacy = RecordingPrivacyFlag() {
    auth = ScriptedDeviceAuthenticator()
      ..authenticateResult = result
      ..readEnabled = () => store.enabled;
    lock = AppLockController(
      store: store,
      authenticator: auth,
      clock: MutableClock(DateTime(2026, 9, 27, 12)),
      privacy: privacy,
    );
  }

  final _WriteLogStore store;
  final RecordingPrivacyFlag privacy;
  late final ScriptedDeviceAuthenticator auth;
  late final AppLockController lock;
}

class _ScriptedLocalAuth implements LocalAuthGateway {
  _ScriptedLocalAuth(
    this.outcome, {
    this.supported = true,
    this.throwsOnSupport = false,
  });

  final Object outcome;
  final bool supported;
  final bool throwsOnSupport;

  @override
  Future<bool> isDeviceSupported() async {
    if (throwsOnSupport) {
      throw StateError('device check failed');
    }
    return supported;
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    if (outcome is bool) {
      return outcome as bool;
    }
    throw outcome;
  }
}
