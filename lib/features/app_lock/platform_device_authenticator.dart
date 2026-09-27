import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:the_registry/features/app_lock/device_authenticator.dart';

/// The slice of `local_auth` 2.3.0 this app uses.
///
/// Tests supply a fake. Production uses [_PluginLocalAuthGateway].
@visibleForTesting
abstract class LocalAuthGateway {
  Future<bool> isDeviceSupported();

  Future<bool> authenticate({required String localizedReason});
}

class _PluginLocalAuthGateway implements LocalAuthGateway {
  _PluginLocalAuthGateway({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<bool> isDeviceSupported() => _authentication.isDeviceSupported();

  @override
  Future<bool> authenticate({required String localizedReason}) {
    return _authentication.authenticate(
      localizedReason: localizedReason,
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  }
}

/// Reads [local_auth] 2.3.0 without logging the exception text.
///
/// Android completes a dismissed prompt as `false` (`AuthResult.failure`),
/// including the cancel button. Darwin reports a user cancel as
/// [PlatformException] code `UserCancelled`, and `false` when the attempt
/// ended without success. `UserFallback` is the person leaving biometrics
/// without authenticating. Every other [PlatformException] code is a
/// configuration or plugin failure, including `NotAvailable`, which Darwin
/// also uses for `LAError.authenticationFailed`.
///
/// Only [PlatformException.code] is read. The message and details are
/// ignored so credentials and record data are never logged or shown.
class PlatformDeviceAuthenticator implements DeviceAuthenticator {
  PlatformDeviceAuthenticator({
    LocalAuthentication? authentication,
    @visibleForTesting LocalAuthGateway? gateway,
  }) : _gateway =
           gateway ?? _PluginLocalAuthGateway(authentication: authentication);

  final LocalAuthGateway _gateway;

  @override
  Future<DeviceAuthAvailability> availability() async {
    try {
      final supported = await _gateway.isDeviceSupported();
      if (!supported) {
        return DeviceAuthAvailability.unavailable;
      }
      return DeviceAuthAvailability.ready;
    } on Object {
      return DeviceAuthAvailability.unavailable;
    }
  }

  @override
  Future<DeviceAuthAttempt> authenticate({
    required String localizedReason,
  }) async {
    try {
      final authenticated = await _gateway.authenticate(
        localizedReason: localizedReason,
      );
      if (authenticated) {
        return DeviceAuthAttempt.authenticated;
      }
      return _falseAttempt(defaultTargetPlatform);
    } on PlatformException catch (error) {
      return _fromPlatformCode(error.code);
    } on Object {
      return DeviceAuthAttempt.platformError;
    }
  }
}

DeviceAuthAttempt _falseAttempt(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.iOS ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => DeviceAuthAttempt.failed,
    TargetPlatform.android ||
    TargetPlatform.linux ||
    TargetPlatform.fuchsia => DeviceAuthAttempt.cancelled,
  };
}

DeviceAuthAttempt _fromPlatformCode(String code) {
  return switch (code) {
    'UserCancelled' || 'UserFallback' => DeviceAuthAttempt.cancelled,
    _ => DeviceAuthAttempt.platformError,
  };
}
