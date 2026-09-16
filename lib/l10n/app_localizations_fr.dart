// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get onboardingSkip => 'Ignorer';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingPage1Title => 'Ne manquez plus une date importante';

  @override
  String get onboardingPage1Subtitle =>
      'Suivez les dates d’expiration de vos documents et sachez quand commencer le renouvellement.';

  @override
  String get onboardingPage2Title => 'Anticipez chaque prélèvement';

  @override
  String get onboardingPage2Subtitle =>
      'Gardez vos abonnements organisés et décidez avant le prochain paiement.';

  @override
  String get onboardingPage3Title => 'Vos informations restent les vôtres';

  @override
  String get onboardingPage3Subtitle =>
      'Commencez sans compte. Vos dossiers restent privés sur votre appareil.';

  @override
  String get onboardingPage1IllustrationLabel =>
      'Rappel d’expiration d’un document';

  @override
  String get onboardingPage2IllustrationLabel =>
      'Prélèvement d’abonnement à venir';

  @override
  String get onboardingPage3IllustrationLabel =>
      'Dossiers privés enregistrés sur cet appareil';

  @override
  String get onboardingDocumentName => 'Passeport';

  @override
  String get onboardingDocumentExpiry => 'Expire le 12 juin';

  @override
  String get onboardingReminder => 'Rappel activé';

  @override
  String get onboardingSubscriptionName => 'Streaming';

  @override
  String get onboardingUpcomingCharge => 'Prélèvement dans 5 jours';

  @override
  String get onboardingDecisionDate => 'Décider avant vendredi';

  @override
  String get onboardingPrivacyLock => 'Sur l’appareil uniquement';
}
