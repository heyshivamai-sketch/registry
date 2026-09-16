/// Persistence for whether first-run onboarding has been completed.
///
/// To reset onboarding during development (no UI control is exposed):
/// `flutter run --dart-define=RESET_ONBOARDING=true`
abstract class OnboardingRepository {
  Future<bool> isCompleted();

  Future<void> complete();

  Future<void> reset();
}
