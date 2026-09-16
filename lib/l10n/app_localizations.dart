import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// Skips remaining onboarding pages and enters the app.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Advances to the next onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// Completes onboarding from the last page.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Never miss an important date'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track document expiry dates and know when it is time to start renewing.'**
  String get onboardingPage1Subtitle;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Stay ahead of every charge'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep subscriptions organised and decide before the next payment.'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Your information stays with you'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start without an account. Your records remain private on your device.'**
  String get onboardingPage3Subtitle;

  /// No description provided for @onboardingPage1IllustrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Document expiry reminder'**
  String get onboardingPage1IllustrationLabel;

  /// No description provided for @onboardingPage2IllustrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming subscription charge'**
  String get onboardingPage2IllustrationLabel;

  /// No description provided for @onboardingPage3IllustrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Private records stored on this device'**
  String get onboardingPage3IllustrationLabel;

  /// No description provided for @onboardingDocumentName.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get onboardingDocumentName;

  /// No description provided for @onboardingDocumentExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expires 12 Jun'**
  String get onboardingDocumentExpiry;

  /// No description provided for @onboardingReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get onboardingReminder;

  /// No description provided for @onboardingSubscriptionName.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get onboardingSubscriptionName;

  /// No description provided for @onboardingUpcomingCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge in 5 days'**
  String get onboardingUpcomingCharge;

  /// No description provided for @onboardingDecisionDate.
  ///
  /// In en, this message translates to:
  /// **'Decide by Friday'**
  String get onboardingDecisionDate;

  /// No description provided for @onboardingPrivacyLock.
  ///
  /// In en, this message translates to:
  /// **'On-device only'**
  String get onboardingPrivacyLock;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get navDocuments;

  /// No description provided for @navSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get navSubscriptions;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Stay ahead of what matters'**
  String get homeGreeting;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Registry'**
  String get homeTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search documents and subscriptions'**
  String get searchPlaceholder;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @filterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTooltip;

  /// No description provided for @filtersComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Filters will be available in a later version.'**
  String get filtersComingSoon;

  /// No description provided for @reviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewAction;

  /// No description provided for @highImpactLabel.
  ///
  /// In en, this message translates to:
  /// **'High impact'**
  String get highImpactLabel;

  /// No description provided for @summaryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get summaryDocuments;

  /// No description provided for @summarySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get summarySubscriptions;

  /// No description provided for @summaryNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get summaryNeedsAttention;

  /// No description provided for @sectionNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get sectionNeedsAttention;

  /// No description provided for @sectionComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get sectionComingUp;

  /// No description provided for @startByDate.
  ///
  /// In en, this message translates to:
  /// **'Start by {date}'**
  String startByDate(String date);

  /// No description provided for @expiresDate.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresDate(String date);

  /// No description provided for @nextChargeDate.
  ///
  /// In en, this message translates to:
  /// **'Next charge {date}'**
  String nextChargeDate(String date);

  /// No description provided for @decideByDate.
  ///
  /// In en, this message translates to:
  /// **'Decide by {date}'**
  String decideByDate(String date);

  /// No description provided for @typeDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get typeDocument;

  /// No description provided for @typeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get typeSubscription;

  /// No description provided for @statusUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get statusUrgent;

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @itemCarInsurance.
  ///
  /// In en, this message translates to:
  /// **'Car insurance'**
  String get itemCarInsurance;

  /// No description provided for @heroCarInsurance.
  ///
  /// In en, this message translates to:
  /// **'Start insurance renewal'**
  String get heroCarInsurance;

  /// No description provided for @actionStartRenewalSoon.
  ///
  /// In en, this message translates to:
  /// **'Start renewal soon'**
  String get actionStartRenewalSoon;

  /// No description provided for @itemPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get itemPassport;

  /// No description provided for @actionUpcomingExpiry.
  ///
  /// In en, this message translates to:
  /// **'Upcoming expiry'**
  String get actionUpcomingExpiry;

  /// No description provided for @itemStreaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming subscription'**
  String get itemStreaming;

  /// No description provided for @actionDecideBeforeCharge.
  ///
  /// In en, this message translates to:
  /// **'Decide before next charge'**
  String get actionDecideBeforeCharge;

  /// No description provided for @itemDrivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get itemDrivingLicence;

  /// No description provided for @actionPrepareRenewal.
  ///
  /// In en, this message translates to:
  /// **'Prepare renewal'**
  String get actionPrepareRenewal;

  /// No description provided for @itemGym.
  ///
  /// In en, this message translates to:
  /// **'Gym membership'**
  String get itemGym;

  /// No description provided for @actionReviewMembership.
  ///
  /// In en, this message translates to:
  /// **'Review before renewal'**
  String get actionReviewMembership;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @addSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get addSubscription;

  /// No description provided for @addSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to Registry'**
  String get addSheetTitle;

  /// No description provided for @addSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to keep on track.'**
  String get addSheetSubtitle;

  /// No description provided for @addFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addFabTooltip;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @documentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get documentsEmptyTitle;

  /// No description provided for @documentsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add passports, insurance and other records to see renewal dates here.'**
  String get documentsEmptyMessage;

  /// No description provided for @subscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptionsTitle;

  /// No description provided for @subscriptionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get subscriptionsEmptyTitle;

  /// No description provided for @subscriptionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add streaming, gym and other recurring charges to stay ahead of payments.'**
  String get subscriptionsEmptyMessage;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileMessage.
  ///
  /// In en, this message translates to:
  /// **'There is no account in this version. Registry will keep your records private on this device.'**
  String get profileMessage;

  /// No description provided for @profileButton.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get profileButton;

  /// No description provided for @addDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get addDocumentTitle;

  /// No description provided for @addDocumentMessage.
  ///
  /// In en, this message translates to:
  /// **'The document form, optional scan and on-device storage will be built next. You can go back and keep exploring Home.'**
  String get addDocumentMessage;

  /// No description provided for @addSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get addSubscriptionTitle;

  /// No description provided for @addSubscriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'The subscription form and payment reminders will be built next. You can go back and keep exploring Home.'**
  String get addSubscriptionMessage;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, or clear search to see everything that needs attention.'**
  String get searchNoResultsMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
