import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/features/onboarding/data/shared_preferences_onboarding_repository.dart';

/// Reset first-run onboarding during development:
/// `flutter run --dart-define=RESET_ONBOARDING=true`
const bool kResetOnboarding = bool.fromEnvironment('RESET_ONBOARDING');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final onboardingRepository = SharedPreferencesOnboardingRepository(
    preferences,
  );
  if (kResetOnboarding) {
    await onboardingRepository.reset();
  }
  runApp(RegistryApp(onboardingRepository: onboardingRepository));
}
