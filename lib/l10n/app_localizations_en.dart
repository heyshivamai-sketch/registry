// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingPage1Title => 'Never miss an important date';

  @override
  String get onboardingPage1Subtitle =>
      'Track document expiry dates and know when it is time to start renewing.';

  @override
  String get onboardingPage2Title => 'Stay ahead of every charge';

  @override
  String get onboardingPage2Subtitle =>
      'Keep subscriptions organised and decide before the next payment.';

  @override
  String get onboardingPage3Title => 'Your information stays with you';

  @override
  String get onboardingPage3Subtitle =>
      'Start without an account. Your records remain private on your device.';

  @override
  String get onboardingPage1IllustrationLabel => 'Document expiry reminder';

  @override
  String get onboardingPage2IllustrationLabel => 'Upcoming subscription charge';

  @override
  String get onboardingPage3IllustrationLabel =>
      'Private records stored on this device';

  @override
  String get onboardingDocumentName => 'Passport';

  @override
  String get onboardingDocumentExpiry => 'Expires 12 Jun';

  @override
  String get onboardingReminder => 'Reminder set';

  @override
  String get onboardingSubscriptionName => 'Streaming';

  @override
  String get onboardingUpcomingCharge => 'Charge in 5 days';

  @override
  String get onboardingDecisionDate => 'Decide by Friday';

  @override
  String get onboardingPrivacyLock => 'On-device only';
}
