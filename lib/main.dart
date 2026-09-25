import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_bootstrap.dart';

/// Reset first-run onboarding during development:
/// `flutter run --dart-define=RESET_ONBOARDING=true`
const bool kResetOnboarding = bool.fromEnvironment('RESET_ONBOARDING');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RegistryBootstrap(resetOnboarding: kResetOnboarding));
}
