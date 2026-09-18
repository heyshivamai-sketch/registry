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
  String get navProfile => 'Profile';

  @override
  String get homeGreeting => 'Stay ahead of what matters';

  @override
  String get homeTitle => 'Your Registry';

  @override
  String get notificationsButton => 'Notifications';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsPlaceholderMessage =>
      'Reminders are not scheduled in this version. This screen is a placeholder.';

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
  String get actionNeeded => 'Action needed';

  @override
  String get dueToday => 'Due today';

  @override
  String get oneDayRemaining => '1 day remaining';

  @override
  String daysRemaining(int count) {
    return '$count days remaining';
  }

  @override
  String get oneDayOverdue => '1 day overdue';

  @override
  String daysOverdue(int count) {
    return '$count days overdue';
  }

  @override
  String get highImpactLabel => 'High impact';

  @override
  String get summaryDocuments => 'Documents';

  @override
  String get summarySubscriptions => 'Subscriptions';

  @override
  String get summaryNeedsAttention => 'Needs attention';

  @override
  String get summaryNext90Days => 'Next 90 days';

  @override
  String get snapshotDocumentsHint => 'Records in your registry';

  @override
  String get snapshotSubscriptionsHint => 'Plans you are tracking';

  @override
  String get snapshotNext90Hint => 'Across your registry';

  @override
  String snapshotDocumentsSupporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need action',
      one: '1 action due',
      zero: 'None need action',
    );
    return '$_temp0';
  }

  @override
  String snapshotSubscriptionsSupporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracked',
      one: '1 tracked',
    );
    return '$_temp0';
  }

  @override
  String get pulseEyebrow => 'Next best action';

  @override
  String get pulseStartByEyebrow => 'Start by';

  @override
  String get pulseExpiresEyebrow => 'Expires';

  @override
  String get countdownDayUnit => 'day';

  @override
  String get countdownDaysUnit => 'days';

  @override
  String get countdownTodayUnit => 'today';

  @override
  String get countdownOverdueUnit => 'overdue';

  @override
  String get addSheetDocumentSubtitle => 'Scan or enter a document';

  @override
  String get addSheetSubscriptionSubtitle => 'Track a charge or renewal';

  @override
  String documentsSummary(int count) {
    return '$count saved';
  }

  @override
  String documentsAttentionSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need attention',
      one: '$count needs attention',
    );
    return '$_temp0';
  }

  @override
  String get sectionNeedsAttention => 'Action queue';

  @override
  String get sectionComingUp => 'Horizon';

  @override
  String get sectionRegistrySnapshot => 'Registry snapshot';

  @override
  String sectionItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

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
  String get statusNeutral => 'Info';

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
  String get addSheetTitle => 'Quick Add';

  @override
  String get addSheetSubtitle => 'What would you like to track?';

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

  @override
  String get addDocumentHeadline => 'Add a document';

  @override
  String get addDocumentSubtitle => 'Scan or enter the details manually.';

  @override
  String get attachmentSectionTitle => 'Attachment';

  @override
  String get attachmentEmptyLabel => 'Add a photo of this document';

  @override
  String get attachmentTakePhoto => 'Take photo';

  @override
  String get attachmentChooseGallery => 'Choose from gallery';

  @override
  String get attachmentReplace => 'Replace';

  @override
  String get attachmentRemove => 'Remove';

  @override
  String get attachmentPrivacy =>
      'Your image stays on this device and is not uploaded.';

  @override
  String get replaceAttachmentTitle => 'Replace photo';

  @override
  String get attachmentPickerFailed =>
      'The photo could not be added. Check camera or library permission and try again.';

  @override
  String get sectionBasicInfo => 'Basic information';

  @override
  String get fieldDocumentName => 'Document name';

  @override
  String get fieldDocumentType => 'Document type';

  @override
  String get fieldOwnerName => 'Owner or profile name';

  @override
  String get fieldIssuingAuthority => 'Issuing country or authority';

  @override
  String get fieldDocumentNumber => 'Document number';

  @override
  String get showDocumentNumber => 'Show document number';

  @override
  String get hideDocumentNumber => 'Hide document number';

  @override
  String get sectionImportantDates => 'Important dates';

  @override
  String get fieldIssueDate => 'Issue date';

  @override
  String get fieldExpiryDate => 'Expiry date';

  @override
  String get fieldActionDate => 'Renewal start date';

  @override
  String get actionDateHelper =>
      'The date you should start taking action, which may be earlier than the expiry date.';

  @override
  String get sectionPriorityRenewal => 'Priority and renewal';

  @override
  String get fieldImpact => 'Impact if lapsed';

  @override
  String get fieldRenewalEffort => 'Renewal effort';

  @override
  String get fieldCostOfLapsing => 'Cost of lapsing';

  @override
  String get fieldCostHelper =>
      'Amount or a short description. No currency is required.';

  @override
  String get fieldDependency => 'Dependency';

  @override
  String get fieldDependencyHelper =>
      'What depends on this document remaining valid?';

  @override
  String get fieldExpectedChanges => 'Expected changes at renewal';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get sectionReminders => 'Reminder preference';

  @override
  String get remindersHelper =>
      'These options are saved with the document. Notifications are not scheduled yet.';

  @override
  String get reminderOnActionDate => 'On action date';

  @override
  String get reminder7Days => '7 days before';

  @override
  String get reminder30Days => '30 days before';

  @override
  String get saveDocument => 'Save document';

  @override
  String get documentSaved => 'Document saved to this session.';

  @override
  String get discardDraftTitle => 'Discard this draft?';

  @override
  String get discardDraftMessage =>
      'Your entered details and selected image will not be kept.';

  @override
  String get discardDraftConfirm => 'Discard';

  @override
  String get discardDraftKeep => 'Keep editing';

  @override
  String get errorRequired => 'This field is required.';

  @override
  String get errorIssueAfterExpiry =>
      'Issue date cannot be after the expiry date.';

  @override
  String get errorActionAfterExpiry =>
      'Renewal start date cannot be after the expiry date.';

  @override
  String get categoryPassport => 'Passport';

  @override
  String get categoryIdCard => 'ID card';

  @override
  String get categoryDrivingLicence => 'Driving licence';

  @override
  String get categoryInsurance => 'Insurance';

  @override
  String get categoryVisa => 'Visa / residence permit';

  @override
  String get categoryCertificate => 'Certificate';

  @override
  String get categoryWarranty => 'Warranty';

  @override
  String get categoryOther => 'Other';

  @override
  String get impactLow => 'Low';

  @override
  String get impactMedium => 'Medium';

  @override
  String get impactHigh => 'High';

  @override
  String get impactCritical => 'Critical';

  @override
  String get effortEasy => 'Easy';

  @override
  String get effortModerate => 'Moderate';

  @override
  String get effortDifficult => 'Difficult';

  @override
  String get requiredMarker => 'Required';

  @override
  String get optionalMarker => 'Optional';

  @override
  String get hasAttachment => 'Has attachment';

  @override
  String get selectDate => 'Select date';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get documentDetailsTitle => 'Document details';

  @override
  String get editDocumentTitle => 'Edit document';

  @override
  String get editDocumentHeadline => 'Update this document';

  @override
  String get editDocumentSubtitle =>
      'Changes stay on this device for this session.';

  @override
  String get requiredFieldsHint => 'Fields marked with * are required.';

  @override
  String get sectionEssential => 'Essential information';

  @override
  String get sectionAdditional => 'Additional details';

  @override
  String get deleteDocument => 'Delete document';

  @override
  String get deleteDocumentTitle => 'Delete this document?';

  @override
  String deleteDocumentMessage(String name) {
    return '$name will be removed from this session.';
  }

  @override
  String get deleteDocumentConfirm => 'Delete';

  @override
  String get deleteDocumentCancel => 'Cancel';

  @override
  String get documentUpdated => 'Document updated for this session.';

  @override
  String get documentDeleted => 'Document deleted from this session.';

  @override
  String get deadlineHealth => 'Deadline health';

  @override
  String get deadlineRemaining => 'Time remaining';

  @override
  String get issuedBy => 'Issued by';

  @override
  String get documentInformation => 'Document information';

  @override
  String get noRemindersSelected => 'No reminders selected';

  @override
  String get attachmentPreview => 'Attachment preview';

  @override
  String get renewalHistory => 'Renewal history';

  @override
  String get noRenewalHistory => 'No renewals recorded yet.';

  @override
  String get recordRenewal => 'Record renewal';

  @override
  String get recordRenewalSubtitle =>
      'Add one renewal to this session. Other document details stay as they are unless you set a new start date.';

  @override
  String get previousExpiry => 'Previous expiry';

  @override
  String get newExpiry => 'New expiry';

  @override
  String get renewalDate => 'Renewal date';

  @override
  String get renewalNoteOptional => 'Note (optional)';

  @override
  String get renewalRecorded => 'Renewal recorded for this session.';

  @override
  String get errorNewExpiryNotAfterPrevious =>
      'New expiry date must be after the previous expiry date.';

  @override
  String get errorNewExpiryRequired => 'New expiry date is required.';

  @override
  String get errorActionAfterNewExpiry =>
      'Renewal start date cannot be after the new expiry date.';

  @override
  String get documentUnavailableTitle => 'Document not available';

  @override
  String get documentUnavailableMessage =>
      'This document is no longer in this session.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMessage => 'Your edits will not be kept.';

  @override
  String get moreActions => 'More actions';

  @override
  String get editAction => 'Edit';

  @override
  String maskedDocumentNumberLabel(String number) {
    return 'Masked document number $number';
  }

  @override
  String get ownerLabel => 'Owner';

  @override
  String get optionalNewActionDate => 'New renewal start date (optional)';

  @override
  String get saveRenewal => 'Save renewal';

  @override
  String get viewAttachment => 'View photo';

  @override
  String get noPhotoAttached => 'No photo attached';

  @override
  String get documentPassLabel => 'Document summary';

  @override
  String get documentsEyebrow => 'Digital wallet';

  @override
  String get documentsSearchPlaceholder => 'Search your documents';

  @override
  String get documentsFilterAll => 'All';

  @override
  String get documentsSearchEmptyTitle => 'No matching documents';

  @override
  String get documentsSearchEmptyMessage =>
      'Try a different name, type or owner, or clear search to see your wallet.';

  @override
  String get documentsFilterEmptyTitle => 'Nothing in this filter';

  @override
  String get documentsFilterEmptyMessage =>
      'Choose another status, or select All to see every saved document.';

  @override
  String get documentsRemainingHeader => 'All documents';

  @override
  String get documentPassTitle => 'Document pass';

  @override
  String get documentPassEyebrow => 'Verified details';

  @override
  String get viewScan => 'View scan';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get renewalHistoryEmptyTitle => 'No renewals yet';
}
