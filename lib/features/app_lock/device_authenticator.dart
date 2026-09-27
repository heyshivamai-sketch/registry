enum DeviceAuthAvailability { ready, unavailable }

/// One system-authentication prompt.
///
/// [cancelled] means the person dismissed the prompt.
/// [failed] means the attempt finished without authenticating.
/// [platformError] means the device or plugin could not run authentication.
/// That is separate from a dismissal.
enum DeviceAuthAttempt { authenticated, cancelled, failed, platformError }

/// Platform biometrics, with a device passcode fallback where the OS allows it.
abstract class DeviceAuthenticator {
  Future<DeviceAuthAvailability> availability();

  /// [DeviceAuthAttempt.authenticated] only after the person authenticates.
  Future<DeviceAuthAttempt> authenticate({required String localizedReason});
}
