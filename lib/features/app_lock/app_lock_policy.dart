/// How long Registry may stay in the background before the next resume
/// requires device authentication again.
///
/// The privacy cover appears as soon as the app becomes inactive, including
/// during this window. Returning before [relockTimeout] keeps the unlocked
/// session. A cold start always requires authentication when the lock is on.
/// The system authentication sheet does not itself start this timer.
abstract final class AppLockPolicy {
  static const relockTimeout = Duration(seconds: 30);
}
