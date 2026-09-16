import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_registry/features/onboarding/data/onboarding_repository.dart';

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  SharedPreferencesOnboardingRepository(this._preferences);

  static const completedKey = 'onboarding_completed';

  final SharedPreferences _preferences;

  @override
  Future<bool> isCompleted() async {
    return _preferences.getBool(completedKey) ?? false;
  }

  @override
  Future<void> complete() {
    return _preferences.setBool(completedKey, true);
  }

  @override
  Future<void> reset() {
    return _preferences.remove(completedKey);
  }
}
