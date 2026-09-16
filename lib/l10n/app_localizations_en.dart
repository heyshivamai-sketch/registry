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

  @override
  String get navHome => 'Home';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navSubscriptions => 'Subscriptions';

  @override
  String get homeGreeting => 'Stay ahead of what matters';

  @override
  String get homeTitle => 'Your Registry';

  @override
  String get searchPlaceholder => 'Search documents and subscriptions';

  @override
  String get searchClear => 'Clear search';

  @override
  String get filterTooltip => 'Filter';

  @override
  String get filtersComingSoon =>
      'Filters will be available in a later version.';

  @override
  String get reviewAction => 'Review';

  @override
  String get highImpactLabel => 'High impact';

  @override
  String get summaryDocuments => 'Documents';

  @override
  String get summarySubscriptions => 'Subscriptions';

  @override
  String get summaryNeedsAttention => 'Needs attention';

  @override
  String get sectionNeedsAttention => 'Needs your attention';

  @override
  String get sectionComingUp => 'Coming up';

  @override
  String startByDate(String date) {
    return 'Start by $date';
  }

  @override
  String expiresDate(String date) {
    return 'Expires $date';
  }

  @override
  String nextChargeDate(String date) {
    return 'Next charge $date';
  }

  @override
  String decideByDate(String date) {
    return 'Decide by $date';
  }

  @override
  String get typeDocument => 'Document';

  @override
  String get typeSubscription => 'Subscription';

  @override
  String get statusUrgent => 'Urgent';

  @override
  String get statusUpcoming => 'Upcoming';

  @override
  String get statusActive => 'Active';

  @override
  String get itemCarInsurance => 'Car insurance';

  @override
  String get heroCarInsurance => 'Start insurance renewal';

  @override
  String get actionStartRenewalSoon => 'Start renewal soon';

  @override
  String get itemPassport => 'Passport';

  @override
  String get actionUpcomingExpiry => 'Upcoming expiry';

  @override
  String get itemStreaming => 'Streaming subscription';

  @override
  String get actionDecideBeforeCharge => 'Decide before next charge';

  @override
  String get itemDrivingLicence => 'Driving licence';

  @override
  String get actionPrepareRenewal => 'Prepare renewal';

  @override
  String get itemGym => 'Gym membership';

  @override
  String get actionReviewMembership => 'Review before renewal';

  @override
  String get addDocument => 'Add Document';

  @override
  String get addSubscription => 'Add Subscription';

  @override
  String get addSheetTitle => 'Add to Registry';

  @override
  String get addSheetSubtitle => 'Choose what you want to keep on track.';

  @override
  String get addFabTooltip => 'Add';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsEmptyTitle => 'No documents yet';

  @override
  String get documentsEmptyMessage =>
      'Add passports, insurance and other records to see renewal dates here.';

  @override
  String get subscriptionsTitle => 'Subscriptions';

  @override
  String get subscriptionsEmptyTitle => 'No subscriptions yet';

  @override
  String get subscriptionsEmptyMessage =>
      'Add streaming, gym and other recurring charges to stay ahead of payments.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileMessage =>
      'There is no account in this version. Registry will keep your records private on this device.';

  @override
  String get profileButton => 'Open profile';

  @override
  String get addDocumentTitle => 'Add document';

  @override
  String get addDocumentMessage =>
      'The document form, optional scan and on-device storage will be built next. You can go back and keep exploring Home.';

  @override
  String get addSubscriptionTitle => 'Add subscription';

  @override
  String get addSubscriptionMessage =>
      'The subscription form and payment reminders will be built next. You can go back and keep exploring Home.';

  @override
  String get searchNoResultsTitle => 'No matching items';

  @override
  String get searchNoResultsMessage =>
      'Try a different name, or clear search to see everything that needs attention.';
}
