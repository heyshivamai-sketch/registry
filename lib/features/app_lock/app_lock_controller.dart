import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/app_lock/app_lock_policy.dart';
import 'package:the_registry/features/app_lock/app_lock_store.dart';
import 'package:the_registry/features/app_lock/device_authenticator.dart';
import 'package:the_registry/features/app_lock/privacy_flag.dart';

enum AppLockEnableResult {
  enabled,
  cancelled,
  failed,
  unavailable,
  platformError,
}

enum AppLockDisableResult {
  disabled,
  cancelled,
  failed,
  unavailable,
  platformError,
}

enum AppLockBlock { cancelled, failed, unavailable, platformError }

/// Optional device authentication. It hides records; it does not encrypt them.
class AppLockController extends ChangeNotifier {
  AppLockController({
    required AppLockStore store,
    required DeviceAuthenticator authenticator,
    required Clock clock,
    PrivacyFlag? privacy,
  }) : _store = store,
       _privacy = privacy ?? const PlatformPrivacyFlag(),
       _sessionLocked = store.enabled,
       _obscured = store.enabled {
    _authenticator = authenticator;
    _clock = clock;
    _store.addListener(_onStoreChanged);
    if (store.enabled) {
      unawaited(_privacy.setSecure(true));
    }
  }

  final AppLockStore _store;
  late final DeviceAuthenticator _authenticator;
  late final Clock _clock;
  final PrivacyFlag _privacy;

  bool _sessionLocked;
  bool _obscured;
  var _authenticating = false;
  DateTime? _backgroundedAt;
  AppLockBlock? _block;

  bool get enabled => _store.enabled;

  bool get sessionLocked => _sessionLocked;

  bool get obscured => _obscured;

  bool get authenticating => _authenticating;

  AppLockBlock? get block => _block;

  Future<AppLockEnableResult> enable({required String localizedReason}) async {
    if (_store.enabled) {
      return AppLockEnableResult.enabled;
    }
    final attempt = await _prompt(localizedReason);
    if (attempt == null) {
      _block = AppLockBlock.unavailable;
      notifyListeners();
      return AppLockEnableResult.unavailable;
    }
    if (attempt != DeviceAuthAttempt.authenticated) {
      _obscured = false;
      _block = _blockFor(attempt);
      notifyListeners();
      return _enableResult(attempt);
    }
    await _store.setEnabled(true);
    _sessionLocked = false;
    _obscured = false;
    _block = null;
    await _privacy.setSecure(true);
    notifyListeners();
    return AppLockEnableResult.enabled;
  }

  /// Asks for a fresh system authentication, then stores the off state.
  ///
  /// Cancellation, a failed attempt, unavailable authentication, and a
  /// platform error leave the stored setting on. The off value is written
  /// only after authentication succeeds.
  Future<AppLockDisableResult> disable({
    required String localizedReason,
  }) async {
    if (!_store.enabled) {
      return AppLockDisableResult.disabled;
    }
    final wasLocked = _sessionLocked;
    final attempt = await _prompt(localizedReason);
    if (attempt == null) {
      if (wasLocked) {
        _sessionLocked = true;
        _obscured = true;
        _block = AppLockBlock.unavailable;
      }
      notifyListeners();
      return AppLockDisableResult.unavailable;
    }
    if (attempt != DeviceAuthAttempt.authenticated) {
      if (wasLocked) {
        _sessionLocked = true;
        _obscured = true;
        _block = _blockFor(attempt);
      } else {
        _obscured = false;
      }
      notifyListeners();
      return _disableResult(attempt);
    }
    await _store.setEnabled(false);
    _sessionLocked = false;
    _obscured = false;
    _backgroundedAt = null;
    _block = null;
    await _privacy.setSecure(false);
    notifyListeners();
    return AppLockDisableResult.disabled;
  }

  Future<bool> unlock({required String localizedReason}) async {
    if (!_sessionLocked) {
      return true;
    }
    final attempt = await _prompt(localizedReason);
    if (attempt == null) {
      _block = AppLockBlock.unavailable;
      _sessionLocked = true;
      notifyListeners();
      return false;
    }
    if (attempt != DeviceAuthAttempt.authenticated) {
      _sessionLocked = true;
      _obscured = true;
      _block = _blockFor(attempt);
      notifyListeners();
      return false;
    }
    _sessionLocked = false;
    _obscured = false;
    _block = null;
    notifyListeners();
    return true;
  }

  /// Null when the device cannot authenticate. The prompt flag is cleared
  /// before this returns.
  Future<DeviceAuthAttempt?> _prompt(String localizedReason) async {
    final availability = await _authenticator.availability();
    if (availability != DeviceAuthAvailability.ready) {
      return null;
    }
    _authenticating = true;
    _backgroundedAt = null;
    _block = null;
    notifyListeners();
    final attempt = await _authenticator.authenticate(
      localizedReason: localizedReason,
    );
    _authenticating = false;
    return attempt;
  }

  AppLockBlock _blockFor(DeviceAuthAttempt attempt) {
    return switch (attempt) {
      DeviceAuthAttempt.cancelled => AppLockBlock.cancelled,
      DeviceAuthAttempt.failed => AppLockBlock.failed,
      DeviceAuthAttempt.platformError => AppLockBlock.platformError,
      DeviceAuthAttempt.authenticated => throw StateError(
        'Successful authentication has no block',
      ),
    };
  }

  AppLockEnableResult _enableResult(DeviceAuthAttempt attempt) {
    return switch (attempt) {
      DeviceAuthAttempt.authenticated => AppLockEnableResult.enabled,
      DeviceAuthAttempt.cancelled => AppLockEnableResult.cancelled,
      DeviceAuthAttempt.failed => AppLockEnableResult.failed,
      DeviceAuthAttempt.platformError => AppLockEnableResult.platformError,
    };
  }

  AppLockDisableResult _disableResult(DeviceAuthAttempt attempt) {
    return switch (attempt) {
      DeviceAuthAttempt.authenticated => AppLockDisableResult.disabled,
      DeviceAuthAttempt.cancelled => AppLockDisableResult.cancelled,
      DeviceAuthAttempt.failed => AppLockDisableResult.failed,
      DeviceAuthAttempt.platformError => AppLockDisableResult.platformError,
    };
  }

  void onLifecycle(AppLifecycleState state) {
    if (_isBackground(state)) {
      if (_store.enabled || _authenticating) {
        _obscured = true;
      }
      if (_store.enabled && !_authenticating && _backgroundedAt == null) {
        _backgroundedAt = _clock.now();
      }
      notifyListeners();
      return;
    }
    if (state != AppLifecycleState.resumed) {
      return;
    }
    if (_authenticating) {
      notifyListeners();
      return;
    }
    final started = _backgroundedAt;
    _backgroundedAt = null;
    if (_store.enabled && started != null) {
      final away = _clock.now().difference(started);
      if (away >= AppLockPolicy.relockTimeout) {
        _sessionLocked = true;
      }
    }
    _obscured = _sessionLocked;
    notifyListeners();
  }

  void _onStoreChanged() {
    notifyListeners();
  }

  bool _isBackground(AppLifecycleState state) {
    return state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }
}
