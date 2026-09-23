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
  String get searchPlaceholder => 'Search your registry';

  @override
  String get searchClear => 'Clear search';

  @override
  String get filterTooltip => 'Filter';

  @override
  String get filtersComingSoon =>
      'Filters will be available in a later version.';

  @override
  String get reviewAction => 'Review now';

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
  String get sectionNeedsAttention => 'Needs attention';

  @override
  String get sectionComingUp => 'Coming up';

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
  String get statusUrgent => 'Action needed';

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
  String get fieldCategory => 'Category';

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
  String get selectDate => 'Choose date';

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
  String get renewAction => 'Renew';

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
  String get documentPassEyebrow => 'Document details';

  @override
  String get viewScan => 'View scan';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get reminderPreferencesTitle => 'Reminder preferences';

  @override
  String get renewalHistoryEmptyTitle => 'No renewals yet';

  @override
  String wizardStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get wizardContinue => 'Continue';

  @override
  String get wizardBack => 'Back';

  @override
  String get stepSourceTitle => 'Scan or manual entry';

  @override
  String get stepIdentityTitle => 'Make it yours';

  @override
  String get stepDatesTitle => 'Important dates';

  @override
  String get stepRenewalTitle => 'Renewal planning';

  @override
  String get stepReviewTitle => 'Review and save';

  @override
  String get howToAddTitle => 'How would you like to add it?';

  @override
  String get scanDocumentTitle => 'Scan document';

  @override
  String get scanDocumentRecommended => 'Recommended';

  @override
  String get scanDocumentSubtitle =>
      'Take a photo or choose an image, then review extracted details.';

  @override
  String get enterManuallyTitle => 'Enter manually';

  @override
  String get enterManuallySubtitle =>
      'Type the details yourself, one step at a time.';

  @override
  String get ocrPrivacy =>
      'Your scan is processed on this device. Nothing is saved until you confirm.';

  @override
  String get ocrReviewPrivacy =>
      'Your scan is processed on this device. Review all extracted details before saving.';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get ocrProcessingTitle => 'Reading this document';

  @override
  String get ocrProcessingMessage =>
      'Text is being recognised on this device. You can cancel and enter details manually.';

  @override
  String get ocrCancel => 'Cancel scan';

  @override
  String get ocrFailedTitle => 'We could not read this scan';

  @override
  String get ocrFailedMessage =>
      'Keep the photo and enter details manually, or try another image.';

  @override
  String get ocrRetry => 'Try again';

  @override
  String get ocrReviewTitle => 'Review your scan';

  @override
  String ocrFieldsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields found',
      one: '1 field found',
      zero: 'No fields found',
    );
    return '$_temp0';
  }

  @override
  String get ocrConfidenceHigh => 'High confidence';

  @override
  String get ocrConfidenceReview => 'Review';

  @override
  String get ocrConfidenceMissing => 'Not detected';

  @override
  String get ocrReviewField => 'Check this value';

  @override
  String get ocrSuggestedCountry => 'Suggested country';

  @override
  String get ocrSuggestedType => 'Suggested document type';

  @override
  String get ocrAddMissingField => 'Add missing field';

  @override
  String get ocrConfirmContinue => 'Confirm details';

  @override
  String get ocrRetake => 'Retake scan';

  @override
  String get fieldCountry => 'Country or region';

  @override
  String get schemaChangeTitle => 'Change document type?';

  @override
  String get schemaChangeMessage =>
      'Some details you entered do not belong to the new type and will be removed.';

  @override
  String get schemaChangeConfirm => 'Change type';

  @override
  String get schemaChangeCancel => 'Keep current type';

  @override
  String get addCustomField => 'Add custom field';

  @override
  String get customFieldLabel => 'Field name';

  @override
  String get customFieldValue => 'Value';

  @override
  String get removeCustomField => 'Remove field';

  @override
  String get markFieldSensitive => 'Hide this value outside review';

  @override
  String get reviewJumpIdentity => 'Edit identity';

  @override
  String get reviewJumpDates => 'Edit dates';

  @override
  String get reviewJumpRenewal => 'Edit renewal plan';

  @override
  String get reviewJumpScan => 'Edit scan';

  @override
  String get reviewAttachmentYes => 'Photo attached';

  @override
  String get reviewAttachmentNo => 'No photo attached';

  @override
  String reviewDynamicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count extra fields',
      one: '1 extra field',
      zero: 'No extra fields',
    );
    return '$_temp0';
  }

  @override
  String suggestedActionDate(String date) {
    return 'Suggested start date: $date';
  }

  @override
  String get useSuggestedActionDate => 'Use suggested date';

  @override
  String get countryGeneric => 'International';

  @override
  String get countryIndia => 'India';

  @override
  String get countryFrance => 'France';

  @override
  String get countryUae => 'United Arab Emirates';

  @override
  String get countryOther => 'Other';

  @override
  String get schemaGenericPassport => 'Passport';

  @override
  String get schemaIndiaAadhaar => 'Aadhaar';

  @override
  String get schemaFranceNationalId => 'French national ID';

  @override
  String get schemaUaeEmiratesId => 'Emirates ID';

  @override
  String get schemaGenericOther => 'Other document';

  @override
  String get fieldPassportNumber => 'Passport number';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldNationality => 'Nationality';

  @override
  String get fieldDateOfBirth => 'Date of birth';

  @override
  String get fieldGender => 'Gender';

  @override
  String get fieldAddress => 'Address';

  @override
  String get fieldSurname => 'Surname';

  @override
  String get fieldGivenNames => 'Given names';

  @override
  String get fieldAadhaarNumber => 'Aadhaar number';

  @override
  String get fieldIdNumber => 'ID number';

  @override
  String get navDocumentsShort => 'Docs';

  @override
  String get navSubscriptionsShort => 'Plans';

  @override
  String get navProfileShort => 'Me';

  @override
  String get snapshotNinetyDayView => '90-day view';

  @override
  String get profileMonogram => 'R';

  @override
  String get guidedSetup => 'Guided setup';

  @override
  String get ocrOnDeviceEyebrow => 'On-device extraction';

  @override
  String get howToAddBody =>
      'Scan for a faster start, or enter the details yourself.';

  @override
  String get identityIntro => 'A few details to organise your document.';

  @override
  String get datesIntro => 'Dates always include day, month and year.';

  @override
  String get planningIntro =>
      'Optional details help you decide what deserves attention.';

  @override
  String get reviewIntro =>
      'Review the important details. You can edit everything later.';

  @override
  String get readyToSave => 'Ready to save';

  @override
  String get scanToFill => 'Scan to fill these automatically';

  @override
  String get ocrDynamicTemplateTitle => 'Dynamic field template';

  @override
  String get ocrDynamicTemplateBody =>
      'Fields change by country and document type. Unknown labels appear as custom fields.';

  @override
  String get ocrReviewHint => 'Review highlighted values before continuing.';

  @override
  String get ocrProcessingHint => 'Text is being recognised on this device.';

  @override
  String get horizonOpenCalendar => 'Open calendar';

  @override
  String get horizon90EmptyTitle => 'Nothing in the next 90 days';

  @override
  String get horizon90EmptyMessage =>
      'Items with an action or renewal date in the next 90 days will appear here, earliest first.';

  @override
  String get catalogReviewEyebrow => 'Highlighted item';

  @override
  String get catalogReviewTitle => 'Review';

  @override
  String get catalogNotInWalletTitle => 'Home catalog';

  @override
  String get catalogNotInWallet =>
      'This is the highlighted Home item. It is not saved in Documents, so editing, deleting and recording a renewal are not available.';

  @override
  String get catalogActionLabel => 'Next action';

  @override
  String get catalogRemainingLabel => 'Time remaining';

  @override
  String get catalogChargeDate => 'Next charge date';

  @override
  String get documentStatusLabel => 'Status';

  @override
  String get homeEmptyTitle => 'Your registry is empty';

  @override
  String get homeEmptyMessage =>
      'Add a document or subscription to start tracking important dates.';

  @override
  String get homeCalmTitle => 'Nothing needs attention right now';

  @override
  String get homeCalmMessage =>
      'Saved items are up to date. Upcoming dates appear in Coming up.';

  @override
  String homeEstimatedMonthly(String amount) {
    return '$amount / month';
  }

  @override
  String get pulseDecideByEyebrow => 'Decide by';

  @override
  String get pulseNextChargeEyebrow => 'Next charge';

  @override
  String get subscriptionsEyebrow => 'Spend with intention';

  @override
  String get subscriptionsSearchPlaceholder => 'Search subscriptions';

  @override
  String subscriptionsSavedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved',
      one: '1 saved',
    );
    return '$_temp0';
  }

  @override
  String subscriptionsActiveSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active plans',
      one: '1 active plan',
    );
    return '$_temp0';
  }

  @override
  String subscriptionsAttentionSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decisions due',
      one: '1 decision due',
      zero: 'No decisions due',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionsListHeader => 'Plans';

  @override
  String get addSubscriptionShort => 'Add new';

  @override
  String get subscriptionsSearchEmptyTitle => 'No matching plans';

  @override
  String get subscriptionsSearchEmptyMessage =>
      'Try a different name or category, or clear search to see every plan.';

  @override
  String get subscriptionsFilterEmptyTitle => 'Nothing in this filter';

  @override
  String get subscriptionsFilterEmptyMessage =>
      'Choose another status, or select All to see every saved plan.';

  @override
  String get monthlySnapshotEyebrow => 'Monthly snapshot';

  @override
  String get estimatedMonthlyCost => 'Estimated monthly cost';

  @override
  String get estimatedMonthlyDisclaimer =>
      'A normalized estimate for active plans. It is not actual spending or payments already made.';

  @override
  String estimatedMonthlyMultiple(int count) {
    return '$count currencies';
  }

  @override
  String get fieldServiceName => 'Service name';

  @override
  String get fieldPlanName => 'Plan name';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get fieldBillingCycle => 'Billing cycle';

  @override
  String get fieldNextPayment => 'Next payment date';

  @override
  String get fieldDecideBy => 'Decide-by date';

  @override
  String get fieldAutoRenew => 'Auto-renew';

  @override
  String get billingWeekly => 'Weekly';

  @override
  String get billingMonthly => 'Monthly';

  @override
  String get billingQuarterly => 'Quarterly';

  @override
  String get billingYearly => 'Yearly';

  @override
  String get billingPerWeek => '/ week';

  @override
  String get billingPerMonth => '/ month';

  @override
  String get billingPerQuarter => '/ quarter';

  @override
  String get billingPerYear => '/ year';

  @override
  String get subscriptionCategoryEntertainment => 'Entertainment';

  @override
  String get subscriptionCategoryHealth => 'Health';

  @override
  String get subscriptionCategoryProductivity => 'Productivity';

  @override
  String get subscriptionCategoryUtilities => 'Utilities';

  @override
  String get subscriptionCategoryFinance => 'Finance';

  @override
  String get subscriptionCategoryEducation => 'Education';

  @override
  String get subscriptionCategoryOther => 'Other';

  @override
  String get subscriptionServiceIntroTitle => 'What are you tracking?';

  @override
  String get subscriptionServiceIntro => 'Start with the service and category.';

  @override
  String get subscriptionBillingIntroTitle => 'Set your billing';

  @override
  String get subscriptionBillingIntro => 'Track your subscription details.';

  @override
  String get subscriptionPreferencesIntroTitle => 'Stay ahead of the charge';

  @override
  String get subscriptionPreferencesIntro =>
      'Choose when you want to make a decision.';

  @override
  String get subscriptionReviewIntroTitle => 'Ready to track';

  @override
  String get subscriptionReviewIntro =>
      'Confirm the plan before adding it to your Registry.';

  @override
  String get saveSubscription => 'Save subscription';

  @override
  String get subscriptionSaved => 'Subscription saved to this session.';

  @override
  String get subscriptionUpdated => 'Subscription updated for this session.';

  @override
  String get subscriptionDeleted => 'Subscription deleted from this session.';

  @override
  String get subscriptionSaveFailed =>
      'The plan could not be saved. Your draft is still here. Try again.';

  @override
  String get editSubscriptionTitle => 'Edit subscription';

  @override
  String get subscriptionDetailsTitle => 'Subscription';

  @override
  String get planDetailsEyebrow => 'Plan details';

  @override
  String get planInformation => 'Plan information';

  @override
  String get nextDecision => 'Next decision';

  @override
  String get subscriptionUnavailableTitle => 'Plan not available';

  @override
  String get subscriptionUnavailableMessage =>
      'This plan is no longer in this session.';

  @override
  String get nextPaymentHelper =>
      'Past dates stay as unresolved tracking. Dates are not advanced automatically.';

  @override
  String get decideByHelper => 'Must be on or before the next payment date.';

  @override
  String get clearDecideBy => 'Clear decide-by date';

  @override
  String get autoRenewHelper =>
      'A preference you track in this app. It does not change the provider.';

  @override
  String get autoRenewOn => 'On';

  @override
  String get autoRenewOff => 'Off';

  @override
  String get subscriptionRemindersHelper =>
      'These options are saved with the plan. Notifications are not scheduled.';

  @override
  String get subscriptionReminder7Days => '7 days before';

  @override
  String get subscriptionReminder1Day => '1 day before';

  @override
  String get subscriptionReminderOnCharge => 'On charge day';

  @override
  String get decideByWhyTitle => 'Why decide-by?';

  @override
  String get decideByWhyMessage =>
      'It gives you time to review or cancel before the payment date.';

  @override
  String get reviewJumpService => 'Edit service';

  @override
  String get reviewJumpBilling => 'Edit billing';

  @override
  String get reviewJumpPreferences => 'Edit preferences';

  @override
  String get subscriptionSessionNote =>
      'Plans stay on this device for this session. There is no bank connection or payment processing.';

  @override
  String get errorDecideByAfterPayment =>
      'Decide-by date must be on or before the next payment date.';

  @override
  String get errorAmountNegative => 'Amount cannot be negative.';

  @override
  String get errorAmountInvalid => 'Enter a valid amount for this currency.';

  @override
  String get errorAmountPrecision =>
      'This currency does not allow that many decimal places.';

  @override
  String get subscriptionCancelled => 'Cancelled';

  @override
  String get subscriptionActive => 'Active';

  @override
  String get lifecycleLabel => 'Tracking status';

  @override
  String get markCancelled => 'Mark as cancelled';

  @override
  String get cancelPlanTitle => 'Stop tracking this plan?';

  @override
  String cancelPlanMessage(String name) {
    return 'This only updates tracking for $name in this app. It does not cancel the subscription with the provider.';
  }

  @override
  String get planMarkedCancelled => 'Plan marked as cancelled in this session.';

  @override
  String get reactivatePlan => 'Reactivate';

  @override
  String get reactivatePlanTitle => 'Reactivate this plan?';

  @override
  String reactivatePlanMessage(String name) {
    return 'Confirm the next payment date for $name. This only resumes tracking in this app.';
  }

  @override
  String get planReactivated => 'Plan reactivated in this session.';

  @override
  String get deleteSubscription => 'Delete plan';

  @override
  String get deleteSubscriptionTitle => 'Delete this plan?';

  @override
  String deleteSubscriptionMessage(String name) {
    return '$name will be removed from this session.';
  }

  @override
  String get subscriptionTrackingDisclaimer =>
      'Registry tracks this plan but does not cancel or charge it automatically.';

  @override
  String homeHeroReview(String title) {
    return 'Review $title';
  }

  @override
  String get homeHeroRenewalToday => 'Renewal starts today';

  @override
  String homeHeroRenewalOn(String date) {
    return 'Renewal starts $date';
  }

  @override
  String get homeHeroDecideToday => 'Decision due today';

  @override
  String homeHeroDecideOn(String date) {
    return 'Decide by $date';
  }

  @override
  String get homeCalmUpcomingCta => 'View upcoming';

  @override
  String get homeEmptyHeadline =>
      'A little organisation.\nA lot of peace of mind.';

  @override
  String get homeEmptySupporting =>
      'Keep your documents and subscriptions together, and know what needs attention.';

  @override
  String get homeAddFirstDocument => 'Add your first document';

  @override
  String get homeAddASubscription => 'Add a subscription';

  @override
  String get homeBenefitDatesTitle => 'See important dates at a glance';

  @override
  String get homeBenefitDatesMessage => 'Never miss what matters.';

  @override
  String get homeBenefitPlansTitle => 'Review plans before they renew';

  @override
  String get homeBenefitPlansMessage => 'Stay in control of your spending.';

  @override
  String get homeEstimatedMonthlyCost => 'Estimated monthly cost';

  @override
  String homeSubscriptionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscriptions',
      one: '1 subscription',
      zero: 'No subscriptions',
    );
    return '$_temp0';
  }

  @override
  String get homeViewAll => 'View all';

  @override
  String get homeAttentionListTitle => 'Needs attention';

  @override
  String get comingUpFilterAll => 'All';

  @override
  String get comingUpFilterDocuments => 'Documents';

  @override
  String get comingUpFilterSubscriptions => 'Subscriptions';

  @override
  String comingUpThisWeek(String year) {
    return 'This week · $year';
  }

  @override
  String comingUpLaterThisMonth(String year) {
    return 'Later this month · $year';
  }

  @override
  String comingUpMonthYear(String month, String year) {
    return '$month · $year';
  }

  @override
  String get comingUpEmptyFilter => 'Nothing coming up in this view.';

  @override
  String get attentionEmpty => 'Nothing needs attention right now.';

  @override
  String get statusToday => 'Today';

  @override
  String get homeStartRenewal => 'Start renewal';

  @override
  String get homeNextPayment => 'Next payment';

  @override
  String get homeDecideBeforeRenewal => 'Decide before renewal';

  @override
  String get homeSeeAllCurrencies => 'See all currency totals';

  @override
  String get homeNoActivePlans => 'No active plans';

  @override
  String get homeCurrencyBreakdownTitle => 'Monthly estimates';

  @override
  String get homeDocumentsTile => 'Documents';

  @override
  String get changeSelection => 'Change';

  @override
  String get fromScan => 'From scan';

  @override
  String get checkThisDate => 'Check this date';

  @override
  String get searchListHint => 'Search';

  @override
  String get identityExtrasTitle => 'Additional details (optional)';

  @override
  String get identityExtrasSubtitle => 'Number, issuer and custom fields';

  @override
  String get ocrReviewSubtitle =>
      'Check the extracted details before continuing.';

  @override
  String get ocrNothingSavedHint =>
      'Nothing is saved until you choose Save document.';

  @override
  String get remindMePrefix => 'Remind me';

  @override
  String attachmentAddedOn(String date) {
    return 'Added $date';
  }

  @override
  String estimatedMonthlyCostValue(String amount) {
    return 'Estimated monthly cost $amount';
  }

  @override
  String get selectedDocumentType => 'Selected document type';

  @override
  String get chooseOption => 'Choose';
}
