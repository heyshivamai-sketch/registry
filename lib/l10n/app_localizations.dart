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

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

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

  /// No description provided for @notificationsButton.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsButton;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsPlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminders are not scheduled in this version. This screen is a placeholder.'**
  String get notificationsPlaceholderMessage;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search your registry'**
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
  /// **'Review now'**
  String get reviewAction;

  /// No description provided for @actionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get actionNeeded;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @oneDayRemaining.
  ///
  /// In en, this message translates to:
  /// **'1 day remaining'**
  String get oneDayRemaining;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days remaining'**
  String daysRemaining(int count);

  /// No description provided for @oneDayOverdue.
  ///
  /// In en, this message translates to:
  /// **'1 day overdue'**
  String get oneDayOverdue;

  /// No description provided for @daysOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} days overdue'**
  String daysOverdue(int count);

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

  /// No description provided for @summaryNext90Days.
  ///
  /// In en, this message translates to:
  /// **'Next 90 days'**
  String get summaryNext90Days;

  /// No description provided for @snapshotDocumentsHint.
  ///
  /// In en, this message translates to:
  /// **'Records in your registry'**
  String get snapshotDocumentsHint;

  /// No description provided for @snapshotSubscriptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Plans you are tracking'**
  String get snapshotSubscriptionsHint;

  /// No description provided for @snapshotNext90Hint.
  ///
  /// In en, this message translates to:
  /// **'Across your registry'**
  String get snapshotNext90Hint;

  /// No description provided for @snapshotDocumentsSupporting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None need action} one{1 action due} other{{count} need action}}'**
  String snapshotDocumentsSupporting(int count);

  /// No description provided for @snapshotSubscriptionsSupporting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 tracked} other{{count} tracked}}'**
  String snapshotSubscriptionsSupporting(int count);

  /// No description provided for @pulseEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Next best action'**
  String get pulseEyebrow;

  /// No description provided for @pulseStartByEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Start by'**
  String get pulseStartByEyebrow;

  /// No description provided for @pulseExpiresEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get pulseExpiresEyebrow;

  /// No description provided for @countdownDayUnit.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get countdownDayUnit;

  /// No description provided for @countdownDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get countdownDaysUnit;

  /// No description provided for @countdownTodayUnit.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get countdownTodayUnit;

  /// No description provided for @countdownOverdueUnit.
  ///
  /// In en, this message translates to:
  /// **'overdue'**
  String get countdownOverdueUnit;

  /// No description provided for @addSheetDocumentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan or enter a document'**
  String get addSheetDocumentSubtitle;

  /// No description provided for @addSheetSubscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track a charge or renewal'**
  String get addSheetSubscriptionSubtitle;

  /// No description provided for @documentsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String documentsSummary(int count);

  /// No description provided for @documentsAttentionSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} needs attention} other{{count} need attention}}'**
  String documentsAttentionSummary(int count);

  /// No description provided for @sectionNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get sectionNeedsAttention;

  /// No description provided for @sectionComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get sectionComingUp;

  /// No description provided for @sectionRegistrySnapshot.
  ///
  /// In en, this message translates to:
  /// **'Registry snapshot'**
  String get sectionRegistrySnapshot;

  /// No description provided for @sectionItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String sectionItemCount(int count);

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
  /// **'Action needed'**
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

  /// No description provided for @statusNeutral.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get statusNeutral;

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
  /// **'Quick Add'**
  String get addSheetTitle;

  /// No description provided for @addSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to track?'**
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

  /// No description provided for @addDocumentHeadline.
  ///
  /// In en, this message translates to:
  /// **'Add a document'**
  String get addDocumentHeadline;

  /// No description provided for @addDocumentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan or enter the details manually.'**
  String get addDocumentSubtitle;

  /// No description provided for @attachmentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachmentSectionTitle;

  /// No description provided for @attachmentEmptyLabel.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of this document'**
  String get attachmentEmptyLabel;

  /// No description provided for @attachmentTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get attachmentTakePhoto;

  /// No description provided for @attachmentChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get attachmentChooseGallery;

  /// No description provided for @attachmentReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get attachmentReplace;

  /// No description provided for @attachmentRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get attachmentRemove;

  /// No description provided for @attachmentPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your image stays on this device and is not uploaded.'**
  String get attachmentPrivacy;

  /// No description provided for @replaceAttachmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get replaceAttachmentTitle;

  /// No description provided for @attachmentPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be added. Check camera or library permission and try again.'**
  String get attachmentPickerFailed;

  /// No description provided for @sectionBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get sectionBasicInfo;

  /// No description provided for @fieldDocumentName.
  ///
  /// In en, this message translates to:
  /// **'Document name'**
  String get fieldDocumentName;

  /// No description provided for @fieldDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get fieldDocumentType;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner or profile name'**
  String get fieldOwnerName;

  /// No description provided for @fieldIssuingAuthority.
  ///
  /// In en, this message translates to:
  /// **'Issuing country or authority'**
  String get fieldIssuingAuthority;

  /// No description provided for @fieldDocumentNumber.
  ///
  /// In en, this message translates to:
  /// **'Document number'**
  String get fieldDocumentNumber;

  /// No description provided for @showDocumentNumber.
  ///
  /// In en, this message translates to:
  /// **'Show document number'**
  String get showDocumentNumber;

  /// No description provided for @hideDocumentNumber.
  ///
  /// In en, this message translates to:
  /// **'Hide document number'**
  String get hideDocumentNumber;

  /// No description provided for @sectionImportantDates.
  ///
  /// In en, this message translates to:
  /// **'Important dates'**
  String get sectionImportantDates;

  /// No description provided for @fieldIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get fieldIssueDate;

  /// No description provided for @fieldExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get fieldExpiryDate;

  /// No description provided for @fieldActionDate.
  ///
  /// In en, this message translates to:
  /// **'Renewal start date'**
  String get fieldActionDate;

  /// No description provided for @actionDateHelper.
  ///
  /// In en, this message translates to:
  /// **'The date you should start taking action, which may be earlier than the expiry date.'**
  String get actionDateHelper;

  /// No description provided for @sectionPriorityRenewal.
  ///
  /// In en, this message translates to:
  /// **'Priority and renewal'**
  String get sectionPriorityRenewal;

  /// No description provided for @fieldImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact if lapsed'**
  String get fieldImpact;

  /// No description provided for @fieldRenewalEffort.
  ///
  /// In en, this message translates to:
  /// **'Renewal effort'**
  String get fieldRenewalEffort;

  /// No description provided for @fieldCostOfLapsing.
  ///
  /// In en, this message translates to:
  /// **'Cost of lapsing'**
  String get fieldCostOfLapsing;

  /// No description provided for @fieldCostHelper.
  ///
  /// In en, this message translates to:
  /// **'Amount or a short description. No currency is required.'**
  String get fieldCostHelper;

  /// No description provided for @fieldDependency.
  ///
  /// In en, this message translates to:
  /// **'Dependency'**
  String get fieldDependency;

  /// No description provided for @fieldDependencyHelper.
  ///
  /// In en, this message translates to:
  /// **'What depends on this document remaining valid?'**
  String get fieldDependencyHelper;

  /// No description provided for @fieldExpectedChanges.
  ///
  /// In en, this message translates to:
  /// **'Expected changes at renewal'**
  String get fieldExpectedChanges;

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotes;

  /// No description provided for @sectionReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminder preference'**
  String get sectionReminders;

  /// No description provided for @remindersHelper.
  ///
  /// In en, this message translates to:
  /// **'These options are saved with the document. Notifications are not scheduled yet.'**
  String get remindersHelper;

  /// No description provided for @reminderOnActionDate.
  ///
  /// In en, this message translates to:
  /// **'On action date'**
  String get reminderOnActionDate;

  /// No description provided for @reminder7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days before'**
  String get reminder7Days;

  /// No description provided for @reminder30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days before'**
  String get reminder30Days;

  /// No description provided for @saveDocument.
  ///
  /// In en, this message translates to:
  /// **'Save document'**
  String get saveDocument;

  /// No description provided for @documentSaved.
  ///
  /// In en, this message translates to:
  /// **'Document saved to this session.'**
  String get documentSaved;

  /// No description provided for @discardDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this draft?'**
  String get discardDraftTitle;

  /// No description provided for @discardDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'Your entered details and selected image will not be kept.'**
  String get discardDraftMessage;

  /// No description provided for @discardDraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardDraftConfirm;

  /// No description provided for @discardDraftKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get discardDraftKeep;

  /// No description provided for @errorRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get errorRequired;

  /// No description provided for @errorIssueAfterExpiry.
  ///
  /// In en, this message translates to:
  /// **'Issue date cannot be after the expiry date.'**
  String get errorIssueAfterExpiry;

  /// No description provided for @errorActionAfterExpiry.
  ///
  /// In en, this message translates to:
  /// **'Renewal start date cannot be after the expiry date.'**
  String get errorActionAfterExpiry;

  /// No description provided for @categoryPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get categoryPassport;

  /// No description provided for @categoryIdCard.
  ///
  /// In en, this message translates to:
  /// **'ID card'**
  String get categoryIdCard;

  /// No description provided for @categoryDrivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get categoryDrivingLicence;

  /// No description provided for @categoryInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get categoryInsurance;

  /// No description provided for @categoryVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa / residence permit'**
  String get categoryVisa;

  /// No description provided for @categoryCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get categoryCertificate;

  /// No description provided for @categoryWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get categoryWarranty;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @impactLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get impactLow;

  /// No description provided for @impactMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get impactMedium;

  /// No description provided for @impactHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get impactHigh;

  /// No description provided for @impactCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get impactCritical;

  /// No description provided for @effortEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get effortEasy;

  /// No description provided for @effortModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get effortModerate;

  /// No description provided for @effortDifficult.
  ///
  /// In en, this message translates to:
  /// **'Difficult'**
  String get effortDifficult;

  /// No description provided for @requiredMarker.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredMarker;

  /// No description provided for @optionalMarker.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalMarker;

  /// No description provided for @hasAttachment.
  ///
  /// In en, this message translates to:
  /// **'Has attachment'**
  String get hasAttachment;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get selectDate;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @documentDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Document details'**
  String get documentDetailsTitle;

  /// No description provided for @editDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit document'**
  String get editDocumentTitle;

  /// No description provided for @editDocumentHeadline.
  ///
  /// In en, this message translates to:
  /// **'Update this document'**
  String get editDocumentHeadline;

  /// No description provided for @editDocumentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Changes stay on this device for this session.'**
  String get editDocumentSubtitle;

  /// No description provided for @requiredFieldsHint.
  ///
  /// In en, this message translates to:
  /// **'Fields marked with * are required.'**
  String get requiredFieldsHint;

  /// No description provided for @sectionEssential.
  ///
  /// In en, this message translates to:
  /// **'Essential information'**
  String get sectionEssential;

  /// No description provided for @sectionAdditional.
  ///
  /// In en, this message translates to:
  /// **'Additional details'**
  String get sectionAdditional;

  /// No description provided for @deleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get deleteDocument;

  /// No description provided for @deleteDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this document?'**
  String get deleteDocumentTitle;

  /// No description provided for @deleteDocumentMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from this session.'**
  String deleteDocumentMessage(String name);

  /// No description provided for @deleteDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteDocumentConfirm;

  /// No description provided for @deleteDocumentCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteDocumentCancel;

  /// No description provided for @documentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Document updated for this session.'**
  String get documentUpdated;

  /// No description provided for @documentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted from this session.'**
  String get documentDeleted;

  /// No description provided for @deadlineHealth.
  ///
  /// In en, this message translates to:
  /// **'Deadline health'**
  String get deadlineHealth;

  /// No description provided for @deadlineRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get deadlineRemaining;

  /// No description provided for @issuedBy.
  ///
  /// In en, this message translates to:
  /// **'Issued by'**
  String get issuedBy;

  /// No description provided for @documentInformation.
  ///
  /// In en, this message translates to:
  /// **'Document information'**
  String get documentInformation;

  /// No description provided for @noRemindersSelected.
  ///
  /// In en, this message translates to:
  /// **'No reminders selected'**
  String get noRemindersSelected;

  /// No description provided for @attachmentPreview.
  ///
  /// In en, this message translates to:
  /// **'Attachment preview'**
  String get attachmentPreview;

  /// No description provided for @renewalHistory.
  ///
  /// In en, this message translates to:
  /// **'Renewal history'**
  String get renewalHistory;

  /// No description provided for @noRenewalHistory.
  ///
  /// In en, this message translates to:
  /// **'No renewals recorded yet.'**
  String get noRenewalHistory;

  /// No description provided for @recordRenewal.
  ///
  /// In en, this message translates to:
  /// **'Record renewal'**
  String get recordRenewal;

  /// No description provided for @recordRenewalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add one renewal to this session. Other document details stay as they are unless you set a new start date.'**
  String get recordRenewalSubtitle;

  /// No description provided for @previousExpiry.
  ///
  /// In en, this message translates to:
  /// **'Previous expiry'**
  String get previousExpiry;

  /// No description provided for @newExpiry.
  ///
  /// In en, this message translates to:
  /// **'New expiry'**
  String get newExpiry;

  /// No description provided for @renewalDate.
  ///
  /// In en, this message translates to:
  /// **'Renewal date'**
  String get renewalDate;

  /// No description provided for @renewalNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get renewalNoteOptional;

  /// No description provided for @renewalRecorded.
  ///
  /// In en, this message translates to:
  /// **'Renewal recorded for this session.'**
  String get renewalRecorded;

  /// No description provided for @errorNewExpiryNotAfterPrevious.
  ///
  /// In en, this message translates to:
  /// **'New expiry date must be after the previous expiry date.'**
  String get errorNewExpiryNotAfterPrevious;

  /// No description provided for @errorNewExpiryRequired.
  ///
  /// In en, this message translates to:
  /// **'New expiry date is required.'**
  String get errorNewExpiryRequired;

  /// No description provided for @errorActionAfterNewExpiry.
  ///
  /// In en, this message translates to:
  /// **'Renewal start date cannot be after the new expiry date.'**
  String get errorActionAfterNewExpiry;

  /// No description provided for @documentUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Document not available'**
  String get documentUnavailableTitle;

  /// No description provided for @documentUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This document is no longer in this session.'**
  String get documentUnavailableMessage;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Your edits will not be kept.'**
  String get discardChangesMessage;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @renewAction.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renewAction;

  /// No description provided for @maskedDocumentNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Masked document number {number}'**
  String maskedDocumentNumberLabel(String number);

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerLabel;

  /// No description provided for @optionalNewActionDate.
  ///
  /// In en, this message translates to:
  /// **'New renewal start date (optional)'**
  String get optionalNewActionDate;

  /// No description provided for @saveRenewal.
  ///
  /// In en, this message translates to:
  /// **'Save renewal'**
  String get saveRenewal;

  /// No description provided for @viewAttachment.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get viewAttachment;

  /// No description provided for @noPhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'No photo attached'**
  String get noPhotoAttached;

  /// No description provided for @documentPassLabel.
  ///
  /// In en, this message translates to:
  /// **'Document summary'**
  String get documentPassLabel;

  /// No description provided for @documentsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Digital wallet'**
  String get documentsEyebrow;

  /// No description provided for @documentsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search your documents'**
  String get documentsSearchPlaceholder;

  /// No description provided for @documentsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get documentsFilterAll;

  /// No description provided for @documentsSearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching documents'**
  String get documentsSearchEmptyTitle;

  /// No description provided for @documentsSearchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, type or owner, or clear search to see your wallet.'**
  String get documentsSearchEmptyMessage;

  /// No description provided for @documentsFilterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this filter'**
  String get documentsFilterEmptyTitle;

  /// No description provided for @documentsFilterEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose another status, or select All to see every saved document.'**
  String get documentsFilterEmptyMessage;

  /// No description provided for @documentsRemainingHeader.
  ///
  /// In en, this message translates to:
  /// **'All documents'**
  String get documentsRemainingHeader;

  /// No description provided for @documentPassTitle.
  ///
  /// In en, this message translates to:
  /// **'Document pass'**
  String get documentPassTitle;

  /// No description provided for @documentPassEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Document details'**
  String get documentPassEyebrow;

  /// No description provided for @viewScan.
  ///
  /// In en, this message translates to:
  /// **'View scan'**
  String get viewScan;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @reminderPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder preferences'**
  String get reminderPreferencesTitle;

  /// No description provided for @renewalHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No renewals yet'**
  String get renewalHistoryEmptyTitle;

  /// No description provided for @wizardStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String wizardStepOf(int current, int total);

  /// No description provided for @wizardContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get wizardContinue;

  /// No description provided for @wizardBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wizardBack;

  /// No description provided for @stepSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan or manual entry'**
  String get stepSourceTitle;

  /// No description provided for @stepIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get stepIdentityTitle;

  /// No description provided for @stepDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Important dates'**
  String get stepDatesTitle;

  /// No description provided for @stepRenewalTitle.
  ///
  /// In en, this message translates to:
  /// **'Renewal planning'**
  String get stepRenewalTitle;

  /// No description provided for @stepReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review and save'**
  String get stepReviewTitle;

  /// No description provided for @howToAddTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to add it?'**
  String get howToAddTitle;

  /// No description provided for @scanDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan document'**
  String get scanDocumentTitle;

  /// No description provided for @scanDocumentRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get scanDocumentRecommended;

  /// No description provided for @scanDocumentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose an image, then review extracted details.'**
  String get scanDocumentSubtitle;

  /// No description provided for @enterManuallyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get enterManuallyTitle;

  /// No description provided for @enterManuallySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type the details yourself, one step at a time.'**
  String get enterManuallySubtitle;

  /// No description provided for @ocrPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your scan is processed on this device. Nothing is saved until you confirm.'**
  String get ocrPrivacy;

  /// No description provided for @ocrReviewPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your scan is processed on this device. Review all extracted details before saving.'**
  String get ocrReviewPrivacy;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @ocrProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading this document'**
  String get ocrProcessingTitle;

  /// No description provided for @ocrProcessingMessage.
  ///
  /// In en, this message translates to:
  /// **'Text is being recognised on this device. You can cancel and enter details manually.'**
  String get ocrProcessingMessage;

  /// No description provided for @ocrCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel scan'**
  String get ocrCancel;

  /// No description provided for @ocrFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not read this scan'**
  String get ocrFailedTitle;

  /// No description provided for @ocrFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep the photo and enter details manually, or try another image.'**
  String get ocrFailedMessage;

  /// No description provided for @ocrRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get ocrRetry;

  /// No description provided for @ocrReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your scan'**
  String get ocrReviewTitle;

  /// No description provided for @ocrFieldsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No fields found} one{1 field found} other{{count} fields found}}'**
  String ocrFieldsFound(int count);

  /// No description provided for @ocrConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get ocrConfidenceHigh;

  /// No description provided for @ocrConfidenceReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get ocrConfidenceReview;

  /// No description provided for @ocrConfidenceMissing.
  ///
  /// In en, this message translates to:
  /// **'Not detected'**
  String get ocrConfidenceMissing;

  /// No description provided for @ocrReviewField.
  ///
  /// In en, this message translates to:
  /// **'Check this value'**
  String get ocrReviewField;

  /// No description provided for @ocrSuggestedCountry.
  ///
  /// In en, this message translates to:
  /// **'Suggested country'**
  String get ocrSuggestedCountry;

  /// No description provided for @ocrSuggestedType.
  ///
  /// In en, this message translates to:
  /// **'Suggested document type'**
  String get ocrSuggestedType;

  /// No description provided for @ocrAddMissingField.
  ///
  /// In en, this message translates to:
  /// **'Add missing field'**
  String get ocrAddMissingField;

  /// No description provided for @ocrConfirmContinue.
  ///
  /// In en, this message translates to:
  /// **'Confirm details'**
  String get ocrConfirmContinue;

  /// No description provided for @ocrRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake scan'**
  String get ocrRetake;

  /// No description provided for @fieldCountry.
  ///
  /// In en, this message translates to:
  /// **'Country or region'**
  String get fieldCountry;

  /// No description provided for @schemaChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change document type?'**
  String get schemaChangeTitle;

  /// No description provided for @schemaChangeMessage.
  ///
  /// In en, this message translates to:
  /// **'Some details you entered do not belong to the new type and will be removed.'**
  String get schemaChangeMessage;

  /// No description provided for @schemaChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change type'**
  String get schemaChangeConfirm;

  /// No description provided for @schemaChangeCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep current type'**
  String get schemaChangeCancel;

  /// No description provided for @addCustomField.
  ///
  /// In en, this message translates to:
  /// **'Add custom field'**
  String get addCustomField;

  /// No description provided for @customFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get customFieldLabel;

  /// No description provided for @customFieldValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get customFieldValue;

  /// No description provided for @removeCustomField.
  ///
  /// In en, this message translates to:
  /// **'Remove field'**
  String get removeCustomField;

  /// No description provided for @markFieldSensitive.
  ///
  /// In en, this message translates to:
  /// **'Hide this value outside review'**
  String get markFieldSensitive;

  /// No description provided for @reviewJumpIdentity.
  ///
  /// In en, this message translates to:
  /// **'Edit identity'**
  String get reviewJumpIdentity;

  /// No description provided for @reviewJumpDates.
  ///
  /// In en, this message translates to:
  /// **'Edit dates'**
  String get reviewJumpDates;

  /// No description provided for @reviewJumpRenewal.
  ///
  /// In en, this message translates to:
  /// **'Edit renewal plan'**
  String get reviewJumpRenewal;

  /// No description provided for @reviewJumpScan.
  ///
  /// In en, this message translates to:
  /// **'Edit scan'**
  String get reviewJumpScan;

  /// No description provided for @reviewAttachmentYes.
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get reviewAttachmentYes;

  /// No description provided for @reviewAttachmentNo.
  ///
  /// In en, this message translates to:
  /// **'No photo attached'**
  String get reviewAttachmentNo;

  /// No description provided for @reviewDynamicCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No extra fields} one{1 extra field} other{{count} extra fields}}'**
  String reviewDynamicCount(int count);

  /// No description provided for @suggestedActionDate.
  ///
  /// In en, this message translates to:
  /// **'Suggested start date: {date}'**
  String suggestedActionDate(String date);

  /// No description provided for @useSuggestedActionDate.
  ///
  /// In en, this message translates to:
  /// **'Use suggested date'**
  String get useSuggestedActionDate;

  /// No description provided for @countryGeneric.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get countryGeneric;

  /// No description provided for @countryIndia.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get countryIndia;

  /// No description provided for @countryFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get countryFrance;

  /// No description provided for @countryUae.
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get countryUae;

  /// No description provided for @countryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get countryOther;

  /// No description provided for @schemaGenericPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get schemaGenericPassport;

  /// No description provided for @schemaIndiaAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar'**
  String get schemaIndiaAadhaar;

  /// No description provided for @schemaFranceNationalId.
  ///
  /// In en, this message translates to:
  /// **'French national ID'**
  String get schemaFranceNationalId;

  /// No description provided for @schemaUaeEmiratesId.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID'**
  String get schemaUaeEmiratesId;

  /// No description provided for @schemaGenericOther.
  ///
  /// In en, this message translates to:
  /// **'Other document'**
  String get schemaGenericOther;

  /// No description provided for @fieldPassportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport number'**
  String get fieldPassportNumber;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @fieldNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get fieldNationality;

  /// No description provided for @fieldDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get fieldDateOfBirth;

  /// No description provided for @fieldGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get fieldGender;

  /// No description provided for @fieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get fieldAddress;

  /// No description provided for @fieldSurname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get fieldSurname;

  /// No description provided for @fieldGivenNames.
  ///
  /// In en, this message translates to:
  /// **'Given names'**
  String get fieldGivenNames;

  /// No description provided for @fieldAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number'**
  String get fieldAadhaarNumber;

  /// No description provided for @fieldIdNumber.
  ///
  /// In en, this message translates to:
  /// **'ID number'**
  String get fieldIdNumber;

  /// No description provided for @navDocumentsShort.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get navDocumentsShort;

  /// No description provided for @navSubscriptionsShort.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get navSubscriptionsShort;

  /// No description provided for @navProfileShort.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navProfileShort;

  /// No description provided for @snapshotNinetyDayView.
  ///
  /// In en, this message translates to:
  /// **'90-day view'**
  String get snapshotNinetyDayView;

  /// No description provided for @profileMonogram.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get profileMonogram;

  /// No description provided for @guidedSetup.
  ///
  /// In en, this message translates to:
  /// **'Guided setup'**
  String get guidedSetup;

  /// No description provided for @ocrOnDeviceEyebrow.
  ///
  /// In en, this message translates to:
  /// **'On-device extraction'**
  String get ocrOnDeviceEyebrow;

  /// No description provided for @howToAddBody.
  ///
  /// In en, this message translates to:
  /// **'Scan for a faster start, or enter the details yourself.'**
  String get howToAddBody;

  /// No description provided for @identityIntro.
  ///
  /// In en, this message translates to:
  /// **'A few details to organise your document.'**
  String get identityIntro;

  /// No description provided for @datesIntro.
  ///
  /// In en, this message translates to:
  /// **'Dates always include day, month and year.'**
  String get datesIntro;

  /// No description provided for @planningIntro.
  ///
  /// In en, this message translates to:
  /// **'Optional details help you decide what deserves attention.'**
  String get planningIntro;

  /// No description provided for @reviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Review the important details. You can edit everything later.'**
  String get reviewIntro;

  /// No description provided for @readyToSave.
  ///
  /// In en, this message translates to:
  /// **'Ready to save'**
  String get readyToSave;

  /// No description provided for @scanToFill.
  ///
  /// In en, this message translates to:
  /// **'Scan to fill these automatically'**
  String get scanToFill;

  /// No description provided for @ocrDynamicTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Dynamic field template'**
  String get ocrDynamicTemplateTitle;

  /// No description provided for @ocrDynamicTemplateBody.
  ///
  /// In en, this message translates to:
  /// **'Fields change by country and document type. Unknown labels appear as custom fields.'**
  String get ocrDynamicTemplateBody;

  /// No description provided for @ocrReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Review highlighted values before continuing.'**
  String get ocrReviewHint;

  /// No description provided for @ocrProcessingHint.
  ///
  /// In en, this message translates to:
  /// **'Text is being recognised on this device.'**
  String get ocrProcessingHint;

  /// No description provided for @horizonOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get horizonOpenCalendar;

  /// No description provided for @horizon90EmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the next 90 days'**
  String get horizon90EmptyTitle;

  /// No description provided for @horizon90EmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Items with an action or renewal date in the next 90 days will appear here, earliest first.'**
  String get horizon90EmptyMessage;

  /// No description provided for @catalogReviewEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Highlighted item'**
  String get catalogReviewEyebrow;

  /// No description provided for @catalogReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get catalogReviewTitle;

  /// No description provided for @catalogNotInWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Home catalog'**
  String get catalogNotInWalletTitle;

  /// No description provided for @catalogNotInWallet.
  ///
  /// In en, this message translates to:
  /// **'This is the highlighted Home item. It is not saved in Documents, so editing, deleting and recording a renewal are not available.'**
  String get catalogNotInWallet;

  /// No description provided for @catalogActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Next action'**
  String get catalogActionLabel;

  /// No description provided for @catalogRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get catalogRemainingLabel;

  /// No description provided for @catalogChargeDate.
  ///
  /// In en, this message translates to:
  /// **'Next charge date'**
  String get catalogChargeDate;

  /// No description provided for @documentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get documentStatusLabel;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your registry is empty'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a document or subscription to start tracking important dates.'**
  String get homeEmptyMessage;

  /// No description provided for @homeCalmTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs attention right now'**
  String get homeCalmTitle;

  /// No description provided for @homeCalmMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved items are up to date. Upcoming dates appear in Coming up.'**
  String get homeCalmMessage;

  /// No description provided for @homeEstimatedMonthly.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String homeEstimatedMonthly(String amount);

  /// No description provided for @pulseDecideByEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Decide by'**
  String get pulseDecideByEyebrow;

  /// No description provided for @pulseNextChargeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Next charge'**
  String get pulseNextChargeEyebrow;

  /// No description provided for @subscriptionsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Spend with intention'**
  String get subscriptionsEyebrow;

  /// No description provided for @subscriptionsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search subscriptions'**
  String get subscriptionsSearchPlaceholder;

  /// No description provided for @subscriptionsSavedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 saved} other{{count} saved}}'**
  String subscriptionsSavedSummary(int count);

  /// No description provided for @subscriptionsActiveSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 active plan} other{{count} active plans}}'**
  String subscriptionsActiveSummary(int count);

  /// No description provided for @subscriptionsAttentionSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No decisions due} one{1 decision due} other{{count} decisions due}}'**
  String subscriptionsAttentionSummary(int count);

  /// No description provided for @subscriptionsListHeader.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get subscriptionsListHeader;

  /// No description provided for @addSubscriptionShort.
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get addSubscriptionShort;

  /// No description provided for @subscriptionsSearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching plans'**
  String get subscriptionsSearchEmptyTitle;

  /// No description provided for @subscriptionsSearchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or category, or clear search to see every plan.'**
  String get subscriptionsSearchEmptyMessage;

  /// No description provided for @subscriptionsFilterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this filter'**
  String get subscriptionsFilterEmptyTitle;

  /// No description provided for @subscriptionsFilterEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose another status, or select All to see every saved plan.'**
  String get subscriptionsFilterEmptyMessage;

  /// No description provided for @monthlySnapshotEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Monthly snapshot'**
  String get monthlySnapshotEyebrow;

  /// No description provided for @estimatedMonthlyCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated monthly cost'**
  String get estimatedMonthlyCost;

  /// No description provided for @estimatedMonthlyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'A normalized estimate for active plans. It is not actual spending or payments already made.'**
  String get estimatedMonthlyDisclaimer;

  /// No description provided for @estimatedMonthlyMultiple.
  ///
  /// In en, this message translates to:
  /// **'{count} currencies'**
  String estimatedMonthlyMultiple(int count);

  /// No description provided for @fieldServiceName.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get fieldServiceName;

  /// No description provided for @fieldPlanName.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get fieldPlanName;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldCurrency;

  /// No description provided for @fieldBillingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing cycle'**
  String get fieldBillingCycle;

  /// No description provided for @fieldNextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next payment date'**
  String get fieldNextPayment;

  /// No description provided for @fieldDecideBy.
  ///
  /// In en, this message translates to:
  /// **'Decide-by date'**
  String get fieldDecideBy;

  /// No description provided for @fieldAutoRenew.
  ///
  /// In en, this message translates to:
  /// **'Auto-renew'**
  String get fieldAutoRenew;

  /// No description provided for @billingWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get billingWeekly;

  /// No description provided for @billingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingMonthly;

  /// No description provided for @billingQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get billingQuarterly;

  /// No description provided for @billingYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get billingYearly;

  /// No description provided for @billingPerWeek.
  ///
  /// In en, this message translates to:
  /// **'/ week'**
  String get billingPerWeek;

  /// No description provided for @billingPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get billingPerMonth;

  /// No description provided for @billingPerQuarter.
  ///
  /// In en, this message translates to:
  /// **'/ quarter'**
  String get billingPerQuarter;

  /// No description provided for @billingPerYear.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get billingPerYear;

  /// No description provided for @subscriptionCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get subscriptionCategoryEntertainment;

  /// No description provided for @subscriptionCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get subscriptionCategoryHealth;

  /// No description provided for @subscriptionCategoryProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get subscriptionCategoryProductivity;

  /// No description provided for @subscriptionCategoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get subscriptionCategoryUtilities;

  /// No description provided for @subscriptionCategoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get subscriptionCategoryFinance;

  /// No description provided for @subscriptionCategoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get subscriptionCategoryEducation;

  /// No description provided for @subscriptionCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get subscriptionCategoryOther;

  /// No description provided for @subscriptionServiceIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you tracking?'**
  String get subscriptionServiceIntroTitle;

  /// No description provided for @subscriptionServiceIntro.
  ///
  /// In en, this message translates to:
  /// **'Start with the service and category.'**
  String get subscriptionServiceIntro;

  /// No description provided for @subscriptionBillingIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your billing'**
  String get subscriptionBillingIntroTitle;

  /// No description provided for @subscriptionBillingIntro.
  ///
  /// In en, this message translates to:
  /// **'Track your subscription details.'**
  String get subscriptionBillingIntro;

  /// No description provided for @subscriptionPreferencesIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay ahead of the charge'**
  String get subscriptionPreferencesIntroTitle;

  /// No description provided for @subscriptionPreferencesIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose when you want to make a decision.'**
  String get subscriptionPreferencesIntro;

  /// No description provided for @subscriptionReviewIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to track'**
  String get subscriptionReviewIntroTitle;

  /// No description provided for @subscriptionReviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Confirm the plan before adding it to your Registry.'**
  String get subscriptionReviewIntro;

  /// No description provided for @saveSubscription.
  ///
  /// In en, this message translates to:
  /// **'Save subscription'**
  String get saveSubscription;

  /// No description provided for @subscriptionSaved.
  ///
  /// In en, this message translates to:
  /// **'Subscription saved to this session.'**
  String get subscriptionSaved;

  /// No description provided for @subscriptionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Subscription updated for this session.'**
  String get subscriptionUpdated;

  /// No description provided for @subscriptionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Subscription deleted from this session.'**
  String get subscriptionDeleted;

  /// No description provided for @subscriptionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The plan could not be saved. Your draft is still here. Try again.'**
  String get subscriptionSaveFailed;

  /// No description provided for @editSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get editSubscriptionTitle;

  /// No description provided for @subscriptionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionDetailsTitle;

  /// No description provided for @planDetailsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Plan details'**
  String get planDetailsEyebrow;

  /// No description provided for @planInformation.
  ///
  /// In en, this message translates to:
  /// **'Plan information'**
  String get planInformation;

  /// No description provided for @nextDecision.
  ///
  /// In en, this message translates to:
  /// **'Next decision'**
  String get nextDecision;

  /// No description provided for @subscriptionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan not available'**
  String get subscriptionUnavailableTitle;

  /// No description provided for @subscriptionUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This plan is no longer in this session.'**
  String get subscriptionUnavailableMessage;

  /// No description provided for @nextPaymentHelper.
  ///
  /// In en, this message translates to:
  /// **'Past dates stay as unresolved tracking. Dates are not advanced automatically.'**
  String get nextPaymentHelper;

  /// No description provided for @decideByHelper.
  ///
  /// In en, this message translates to:
  /// **'Must be on or before the next payment date.'**
  String get decideByHelper;

  /// No description provided for @clearDecideBy.
  ///
  /// In en, this message translates to:
  /// **'Clear decide-by date'**
  String get clearDecideBy;

  /// No description provided for @autoRenewHelper.
  ///
  /// In en, this message translates to:
  /// **'A preference you track in this app. It does not change the provider.'**
  String get autoRenewHelper;

  /// No description provided for @autoRenewOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get autoRenewOn;

  /// No description provided for @autoRenewOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autoRenewOff;

  /// No description provided for @subscriptionRemindersHelper.
  ///
  /// In en, this message translates to:
  /// **'These options are saved with the plan. Notifications are not scheduled.'**
  String get subscriptionRemindersHelper;

  /// No description provided for @subscriptionReminder7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days before'**
  String get subscriptionReminder7Days;

  /// No description provided for @subscriptionReminder1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get subscriptionReminder1Day;

  /// No description provided for @subscriptionReminderOnCharge.
  ///
  /// In en, this message translates to:
  /// **'On charge day'**
  String get subscriptionReminderOnCharge;

  /// No description provided for @decideByWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why decide-by?'**
  String get decideByWhyTitle;

  /// No description provided for @decideByWhyMessage.
  ///
  /// In en, this message translates to:
  /// **'It gives you time to review or cancel before the payment date.'**
  String get decideByWhyMessage;

  /// No description provided for @reviewJumpService.
  ///
  /// In en, this message translates to:
  /// **'Edit service'**
  String get reviewJumpService;

  /// No description provided for @reviewJumpBilling.
  ///
  /// In en, this message translates to:
  /// **'Edit billing'**
  String get reviewJumpBilling;

  /// No description provided for @reviewJumpPreferences.
  ///
  /// In en, this message translates to:
  /// **'Edit preferences'**
  String get reviewJumpPreferences;

  /// No description provided for @subscriptionSessionNote.
  ///
  /// In en, this message translates to:
  /// **'Plans stay on this device for this session. There is no bank connection or payment processing.'**
  String get subscriptionSessionNote;

  /// No description provided for @errorDecideByAfterPayment.
  ///
  /// In en, this message translates to:
  /// **'Decide-by date must be on or before the next payment date.'**
  String get errorDecideByAfterPayment;

  /// No description provided for @errorAmountNegative.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot be negative.'**
  String get errorAmountNegative;

  /// No description provided for @errorAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount for this currency.'**
  String get errorAmountInvalid;

  /// No description provided for @errorAmountPrecision.
  ///
  /// In en, this message translates to:
  /// **'This currency does not allow that many decimal places.'**
  String get errorAmountPrecision;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subscriptionCancelled;

  /// No description provided for @subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionActive;

  /// No description provided for @lifecycleLabel.
  ///
  /// In en, this message translates to:
  /// **'Tracking status'**
  String get lifecycleLabel;

  /// No description provided for @markCancelled.
  ///
  /// In en, this message translates to:
  /// **'Mark as cancelled'**
  String get markCancelled;

  /// No description provided for @cancelPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking this plan?'**
  String get cancelPlanTitle;

  /// No description provided for @cancelPlanMessage.
  ///
  /// In en, this message translates to:
  /// **'This only updates tracking for {name} in this app. It does not cancel the subscription with the provider.'**
  String cancelPlanMessage(String name);

  /// No description provided for @planMarkedCancelled.
  ///
  /// In en, this message translates to:
  /// **'Plan marked as cancelled in this session.'**
  String get planMarkedCancelled;

  /// No description provided for @reactivatePlan.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivatePlan;

  /// No description provided for @reactivatePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate this plan?'**
  String get reactivatePlanTitle;

  /// No description provided for @reactivatePlanMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm the next payment date for {name}. This only resumes tracking in this app.'**
  String reactivatePlanMessage(String name);

  /// No description provided for @planReactivated.
  ///
  /// In en, this message translates to:
  /// **'Plan reactivated in this session.'**
  String get planReactivated;

  /// No description provided for @deleteSubscription.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get deleteSubscription;

  /// No description provided for @deleteSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this plan?'**
  String get deleteSubscriptionTitle;

  /// No description provided for @deleteSubscriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from this session.'**
  String deleteSubscriptionMessage(String name);

  /// No description provided for @subscriptionTrackingDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Registry tracks this plan but does not cancel or charge it automatically.'**
  String get subscriptionTrackingDisclaimer;

  /// No description provided for @homeHeroReview.
  ///
  /// In en, this message translates to:
  /// **'Review {title}'**
  String homeHeroReview(String title);

  /// No description provided for @homeHeroRenewalToday.
  ///
  /// In en, this message translates to:
  /// **'Renewal starts today'**
  String get homeHeroRenewalToday;

  /// No description provided for @homeHeroRenewalOn.
  ///
  /// In en, this message translates to:
  /// **'Renewal starts {date}'**
  String homeHeroRenewalOn(String date);

  /// No description provided for @homeHeroDecideToday.
  ///
  /// In en, this message translates to:
  /// **'Decision due today'**
  String get homeHeroDecideToday;

  /// No description provided for @homeHeroDecideOn.
  ///
  /// In en, this message translates to:
  /// **'Decide by {date}'**
  String homeHeroDecideOn(String date);

  /// No description provided for @homeCalmUpcomingCta.
  ///
  /// In en, this message translates to:
  /// **'View upcoming'**
  String get homeCalmUpcomingCta;

  /// No description provided for @homeEmptyHeadline.
  ///
  /// In en, this message translates to:
  /// **'A little organisation.\nA lot of peace of mind.'**
  String get homeEmptyHeadline;

  /// No description provided for @homeEmptySupporting.
  ///
  /// In en, this message translates to:
  /// **'Keep your documents and subscriptions together, and know what needs attention.'**
  String get homeEmptySupporting;

  /// No description provided for @homeAddFirstDocument.
  ///
  /// In en, this message translates to:
  /// **'Add your first document'**
  String get homeAddFirstDocument;

  /// No description provided for @homeAddASubscription.
  ///
  /// In en, this message translates to:
  /// **'Add a subscription'**
  String get homeAddASubscription;

  /// No description provided for @homeBenefitDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'See important dates at a glance'**
  String get homeBenefitDatesTitle;

  /// No description provided for @homeBenefitDatesMessage.
  ///
  /// In en, this message translates to:
  /// **'Never miss what matters.'**
  String get homeBenefitDatesMessage;

  /// No description provided for @homeBenefitPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Review plans before they renew'**
  String get homeBenefitPlansTitle;

  /// No description provided for @homeBenefitPlansMessage.
  ///
  /// In en, this message translates to:
  /// **'Stay in control of your spending.'**
  String get homeBenefitPlansMessage;

  /// No description provided for @homeEstimatedMonthlyCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated monthly cost'**
  String get homeEstimatedMonthlyCost;

  /// No description provided for @homeSubscriptionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No subscriptions} one{1 subscription} other{{count} subscriptions}}'**
  String homeSubscriptionCount(int count);

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @homeAttentionListTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get homeAttentionListTitle;

  /// No description provided for @comingUpFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get comingUpFilterAll;

  /// No description provided for @comingUpFilterDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get comingUpFilterDocuments;

  /// No description provided for @comingUpFilterSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get comingUpFilterSubscriptions;

  /// No description provided for @comingUpThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week · {year}'**
  String comingUpThisWeek(String year);

  /// No description provided for @comingUpLaterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Later this month · {year}'**
  String comingUpLaterThisMonth(String year);

  /// No description provided for @comingUpMonthYear.
  ///
  /// In en, this message translates to:
  /// **'{month} · {year}'**
  String comingUpMonthYear(String month, String year);

  /// No description provided for @comingUpEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing coming up in this view.'**
  String get comingUpEmptyFilter;

  /// No description provided for @attentionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs attention right now.'**
  String get attentionEmpty;

  /// No description provided for @statusToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statusToday;

  /// No description provided for @homeStartRenewal.
  ///
  /// In en, this message translates to:
  /// **'Start renewal'**
  String get homeStartRenewal;

  /// No description provided for @homeNextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next payment'**
  String get homeNextPayment;

  /// No description provided for @homeDecideBeforeRenewal.
  ///
  /// In en, this message translates to:
  /// **'Decide before renewal'**
  String get homeDecideBeforeRenewal;

  /// No description provided for @homeSeeAllCurrencies.
  ///
  /// In en, this message translates to:
  /// **'See all currency totals'**
  String get homeSeeAllCurrencies;

  /// No description provided for @homeNoActivePlans.
  ///
  /// In en, this message translates to:
  /// **'No active plans'**
  String get homeNoActivePlans;

  /// No description provided for @homeCurrencyBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly estimates'**
  String get homeCurrencyBreakdownTitle;

  /// No description provided for @homeDocumentsTile.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get homeDocumentsTile;

  /// No description provided for @changeSelection.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeSelection;

  /// No description provided for @fromScan.
  ///
  /// In en, this message translates to:
  /// **'From scan'**
  String get fromScan;

  /// No description provided for @checkThisDate.
  ///
  /// In en, this message translates to:
  /// **'Check this date'**
  String get checkThisDate;

  /// No description provided for @searchListHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchListHint;

  /// No description provided for @identityExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get identityExtrasTitle;

  /// No description provided for @identityExtrasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Number, issuer and custom fields'**
  String get identityExtrasSubtitle;

  /// No description provided for @ocrReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the extracted details before continuing.'**
  String get ocrReviewSubtitle;

  /// No description provided for @ocrNothingSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing is saved until you choose Save document.'**
  String get ocrNothingSavedHint;

  /// No description provided for @remindMePrefix.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMePrefix;

  /// No description provided for @attachmentAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String attachmentAddedOn(String date);

  /// No description provided for @estimatedMonthlyCostValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated monthly cost {amount}'**
  String estimatedMonthlyCostValue(String amount);

  /// No description provided for @selectedDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Selected document type'**
  String get selectedDocumentType;

  /// No description provided for @chooseOption.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get chooseOption;
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
