// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingContinue => 'متابعة';

  @override
  String get onboardingGetStarted => 'ابدأ';

  @override
  String get onboardingPage1Title => 'لا تفوّت موعدًا مهمًا';

  @override
  String get onboardingPage1Subtitle =>
      'تتبّع تواريخ انتهاء صلاحية المستندات واعرف متى يحين وقت التجديد.';

  @override
  String get onboardingPage2Title => 'ابقَ سابقًا لكل دفعة';

  @override
  String get onboardingPage2Subtitle =>
      'نظّم اشتراكاتك واتخذ قرارك قبل الدفعة التالية.';

  @override
  String get onboardingPage3Title => 'معلوماتك تبقى معك';

  @override
  String get onboardingPage3Subtitle =>
      'ابدأ بدون حساب. تبقى سجلاتك خاصة على جهازك.';

  @override
  String get onboardingPage1IllustrationLabel => 'تذكير بانتهاء صلاحية مستند';

  @override
  String get onboardingPage2IllustrationLabel => 'دفعة اشتراك قادمة';

  @override
  String get onboardingPage3IllustrationLabel =>
      'سجلات خاصة محفوظة على هذا الجهاز';

  @override
  String get onboardingDocumentName => 'جواز السفر';

  @override
  String get onboardingDocumentExpiry => 'ينتهي في 12 يونيو';

  @override
  String get onboardingReminder => 'تم ضبط التذكير';

  @override
  String get onboardingSubscriptionName => 'البث';

  @override
  String get onboardingUpcomingCharge => 'الدفعة خلال 5 أيام';

  @override
  String get onboardingDecisionDate => 'قرّر قبل الجمعة';

  @override
  String get onboardingPrivacyLock => 'على الجهاز فقط';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navDocuments => 'المستندات';

  @override
  String get navSubscriptions => 'الاشتراكات';

  @override
  String get navProfile => 'الملف';

  @override
  String get homeGreeting => 'ابقَ سابقًا لما يهم';

  @override
  String get homeTitle => 'سجلك';

  @override
  String get notificationsButton => 'الإشعارات';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsPlaceholderMessage =>
      'لا تُجدول التذكيرات في هذا الإصدار. هذه الشاشة عنصر نائب.';

  @override
  String get searchPlaceholder => 'ابحث في المستندات والاشتراكات';

  @override
  String get searchClear => 'مسح البحث';

  @override
  String get filterTooltip => 'تصفية';

  @override
  String get filtersComingSoon => 'ستتوفر عوامل التصفية في إصدار لاحق.';

  @override
  String get reviewAction => 'مراجعة';

  @override
  String get actionNeeded => 'يلزم اتخاذ إجراء';

  @override
  String get dueToday => 'مستحق اليوم';

  @override
  String get oneDayRemaining => 'متبقي يوم واحد';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متبقي $count يوم',
      many: 'متبقي $count يومًا',
      few: 'متبقي $count أيام',
      two: 'متبقي يومين',
      one: 'متبقي يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get oneDayOverdue => 'متأخر يومًا واحدًا';

  @override
  String daysOverdue(int count) {
    return 'متأخر $count أيام';
  }

  @override
  String get highImpactLabel => 'تأثير مرتفع';

  @override
  String get summaryDocuments => 'المستندات';

  @override
  String get summarySubscriptions => 'الاشتراكات';

  @override
  String get summaryNeedsAttention => 'يحتاج انتباهك';

  @override
  String get summaryNext90Days => 'الـ 90 يومًا القادمة';

  @override
  String get snapshotDocumentsHint => 'سجلات في سجلك';

  @override
  String get snapshotSubscriptionsHint => 'الخطط التي تتابعها';

  @override
  String get snapshotNext90Hint => 'عبر سجلك بالكامل';

  @override
  String snapshotDocumentsSupporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تحتاج إجراء',
      one: 'إجراء واحد مستحق',
      zero: 'لا إجراء مطلوب',
    );
    return '$_temp0';
  }

  @override
  String snapshotSubscriptionsSupporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count متتبَّعة',
      one: 'واحد متتبَّع',
    );
    return '$_temp0';
  }

  @override
  String get pulseEyebrow => 'أفضل إجراء تالٍ';

  @override
  String get pulseStartByEyebrow => 'ابدأ قبل';

  @override
  String get pulseExpiresEyebrow => 'ينتهي في';

  @override
  String get countdownDayUnit => 'يوم';

  @override
  String get countdownDaysUnit => 'أيام';

  @override
  String get countdownTodayUnit => 'اليوم';

  @override
  String get countdownOverdueUnit => 'متأخر';

  @override
  String get addSheetDocumentSubtitle => 'امسح أو أدخل مستندًا';

  @override
  String get addSheetSubscriptionSubtitle => 'تتبّع رسومًا أو تجديدًا';

  @override
  String documentsSummary(int count) {
    return '$count محفوظ';
  }

  @override
  String documentsAttentionSummary(int count) {
    return '$count يحتاج انتباهك';
  }

  @override
  String get sectionNeedsAttention => 'قائمة الإجراءات';

  @override
  String get sectionComingUp => 'الأفق';

  @override
  String get sectionRegistrySnapshot => 'لمحة عن السجل';

  @override
  String sectionItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عناصر',
      one: 'عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String startByDate(String date) {
    return 'ابدأ قبل $date';
  }

  @override
  String expiresDate(String date) {
    return 'ينتهي في $date';
  }

  @override
  String nextChargeDate(String date) {
    return 'الدفعة التالية $date';
  }

  @override
  String decideByDate(String date) {
    return 'قرّر قبل $date';
  }

  @override
  String get typeDocument => 'مستند';

  @override
  String get typeSubscription => 'اشتراك';

  @override
  String get statusUrgent => 'عاجل';

  @override
  String get statusUpcoming => 'قادم';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusNeutral => 'معلومة';

  @override
  String get itemCarInsurance => 'تأمين السيارة';

  @override
  String get heroCarInsurance => 'ابدأ تجديد التأمين';

  @override
  String get actionStartRenewalSoon => 'ابدأ التجديد قريبًا';

  @override
  String get itemPassport => 'جواز السفر';

  @override
  String get actionUpcomingExpiry => 'انتهاء قريب';

  @override
  String get itemStreaming => 'اشتراك البث';

  @override
  String get actionDecideBeforeCharge => 'قرّر قبل الدفعة التالية';

  @override
  String get itemDrivingLicence => 'رخصة القيادة';

  @override
  String get actionPrepareRenewal => 'جهّز التجديد';

  @override
  String get itemGym => 'عضوية النادي';

  @override
  String get actionReviewMembership => 'راجع قبل التجديد';

  @override
  String get addDocument => 'إضافة مستند';

  @override
  String get addSubscription => 'إضافة اشتراك';

  @override
  String get addSheetTitle => 'إضافة سريعة';

  @override
  String get addSheetSubtitle => 'ماذا تريد أن تتبّع؟';

  @override
  String get addFabTooltip => 'إضافة';

  @override
  String get documentsTitle => 'المستندات';

  @override
  String get documentsEmptyTitle => 'لا توجد مستندات بعد';

  @override
  String get documentsEmptyMessage =>
      'أضف جوازات السفر والتأمين وسجلات أخرى لترى مواعيد التجديد هنا.';

  @override
  String get subscriptionsTitle => 'الاشتراكات';

  @override
  String get subscriptionsEmptyTitle => 'لا توجد اشتراكات بعد';

  @override
  String get subscriptionsEmptyMessage =>
      'أضف البث والنادي والمدفوعات المتكررة لتبقى سابقًا للدفعات.';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileMessage =>
      'لا يوجد حساب في هذا الإصدار. سيبقى سجلك خاصًا على هذا الجهاز.';

  @override
  String get profileButton => 'فتح الملف الشخصي';

  @override
  String get addDocumentTitle => 'إضافة مستند';

  @override
  String get addDocumentMessage =>
      'سيتم لاحقًا بناء نموذج المستند والمسح الضوئي والتخزين على الجهاز. يمكنك الرجوع ومتابعة استكشاف الرئيسية.';

  @override
  String get addSubscriptionTitle => 'إضافة اشتراك';

  @override
  String get addSubscriptionMessage =>
      'سيتم لاحقًا بناء نموذج الاشتراك وتذكيرات الدفع. يمكنك الرجوع ومتابعة استكشاف الرئيسية.';

  @override
  String get searchNoResultsTitle => 'لا توجد نتائج';

  @override
  String get searchNoResultsMessage =>
      'جرّب اسمًا آخر، أو امسح البحث لعرض كل ما يحتاج انتباهك.';

  @override
  String get addDocumentHeadline => 'إضافة مستند';

  @override
  String get addDocumentSubtitle => 'امسح أو أدخل التفاصيل يدويًا.';

  @override
  String get attachmentSectionTitle => 'مرفق';

  @override
  String get attachmentEmptyLabel => 'أضف صورة لهذا المستند';

  @override
  String get attachmentTakePhoto => 'التقاط صورة';

  @override
  String get attachmentChooseGallery => 'اختيار من المعرض';

  @override
  String get attachmentReplace => 'استبدال';

  @override
  String get attachmentRemove => 'إزالة';

  @override
  String get attachmentPrivacy => 'تبقى صورتك على هذا الجهاز ولا يتم رفعها.';

  @override
  String get replaceAttachmentTitle => 'استبدال الصورة';

  @override
  String get attachmentPickerFailed =>
      'تعذّر إضافة الصورة. تحقق من إذن الكاميرا أو المكتبة ثم أعد المحاولة.';

  @override
  String get sectionBasicInfo => 'معلومات أساسية';

  @override
  String get fieldDocumentName => 'اسم المستند';

  @override
  String get fieldDocumentType => 'نوع المستند';

  @override
  String get fieldCategory => 'الفئة';

  @override
  String get fieldOwnerName => 'اسم المالك أو الملف';

  @override
  String get fieldIssuingAuthority => 'البلد أو الجهة المُصدِرة';

  @override
  String get fieldDocumentNumber => 'رقم المستند';

  @override
  String get showDocumentNumber => 'إظهار رقم المستند';

  @override
  String get hideDocumentNumber => 'إخفاء رقم المستند';

  @override
  String get sectionImportantDates => 'تواريخ مهمة';

  @override
  String get fieldIssueDate => 'تاريخ الإصدار';

  @override
  String get fieldExpiryDate => 'تاريخ الانتهاء';

  @override
  String get fieldActionDate => 'تاريخ بدء التجديد';

  @override
  String get actionDateHelper =>
      'التاريخ الذي ينبغي أن تبدأ فيه الإجراء، وقد يكون قبل تاريخ الانتهاء.';

  @override
  String get sectionPriorityRenewal => 'الأولوية والتجديد';

  @override
  String get fieldImpact => 'الأثر عند انتهاء الصلاحية';

  @override
  String get fieldRenewalEffort => 'جهد التجديد';

  @override
  String get fieldCostOfLapsing => 'تكلفة انتهاء الصلاحية';

  @override
  String get fieldCostHelper => 'مبلغ أو وصف قصير. لا يُطلب رمز عملة.';

  @override
  String get fieldDependency => 'الاعتماد';

  @override
  String get fieldDependencyHelper =>
      'ما الذي يعتمد على بقاء هذا المستند صالحًا؟';

  @override
  String get fieldExpectedChanges => 'التغييرات المتوقعة عند التجديد';

  @override
  String get fieldNotes => 'ملاحظات';

  @override
  String get sectionReminders => 'تفضيل التذكير';

  @override
  String get remindersHelper =>
      'تُحفظ هذه الخيارات مع المستند. لن تُجدول الإشعارات بعد.';

  @override
  String get reminderOnActionDate => 'في تاريخ الإجراء';

  @override
  String get reminder7Days => 'قبل 7 أيام';

  @override
  String get reminder30Days => 'قبل 30 يومًا';

  @override
  String get saveDocument => 'حفظ المستند';

  @override
  String get documentSaved => 'تم حفظ المستند لهذه الجلسة.';

  @override
  String get discardDraftTitle => 'تجاهل هذه المسودة؟';

  @override
  String get discardDraftMessage =>
      'لن تُحفظ التفاصيل المدخلة والصورة المحددة.';

  @override
  String get discardDraftConfirm => 'تجاهل';

  @override
  String get discardDraftKeep => 'متابعة التعديل';

  @override
  String get errorRequired => 'هذا الحقل مطلوب.';

  @override
  String get errorIssueAfterExpiry =>
      'لا يمكن أن يكون تاريخ الإصدار بعد تاريخ الانتهاء.';

  @override
  String get errorActionAfterExpiry =>
      'لا يمكن أن يكون تاريخ بدء التجديد بعد تاريخ الانتهاء.';

  @override
  String get categoryPassport => 'جواز السفر';

  @override
  String get categoryIdCard => 'بطاقة الهوية';

  @override
  String get categoryDrivingLicence => 'رخصة القيادة';

  @override
  String get categoryInsurance => 'تأمين';

  @override
  String get categoryVisa => 'تأشيرة / إقامة';

  @override
  String get categoryCertificate => 'شهادة';

  @override
  String get categoryWarranty => 'ضمان';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get impactLow => 'منخفض';

  @override
  String get impactMedium => 'متوسط';

  @override
  String get impactHigh => 'مرتفع';

  @override
  String get impactCritical => 'حرج';

  @override
  String get effortEasy => 'سهل';

  @override
  String get effortModerate => 'متوسط';

  @override
  String get effortDifficult => 'صعب';

  @override
  String get requiredMarker => 'مطلوب';

  @override
  String get optionalMarker => 'اختياري';

  @override
  String get hasAttachment => 'يوجد مرفق';

  @override
  String get selectDate => 'اختر تاريخًا';

  @override
  String get statusOverdue => 'متأخر';

  @override
  String get documentDetailsTitle => 'تفاصيل المستند';

  @override
  String get editDocumentTitle => 'تعديل المستند';

  @override
  String get editDocumentHeadline => 'حدّث هذا المستند';

  @override
  String get editDocumentSubtitle =>
      'تبقى التغييرات على هذا الجهاز لهذه الجلسة.';

  @override
  String get requiredFieldsHint => 'الحقول التي تحمل * مطلوبة.';

  @override
  String get sectionEssential => 'المعلومات الأساسية';

  @override
  String get sectionAdditional => 'تفاصيل إضافية';

  @override
  String get deleteDocument => 'حذف المستند';

  @override
  String get deleteDocumentTitle => 'حذف هذا المستند؟';

  @override
  String deleteDocumentMessage(String name) {
    return 'ستتم إزالة $name من هذه الجلسة.';
  }

  @override
  String get deleteDocumentConfirm => 'حذف';

  @override
  String get deleteDocumentCancel => 'إلغاء';

  @override
  String get documentUpdated => 'تم تحديث المستند لهذه الجلسة.';

  @override
  String get documentDeleted => 'تم حذف المستند من هذه الجلسة.';

  @override
  String get deadlineHealth => 'حالة المواعيد';

  @override
  String get deadlineRemaining => 'الوقت المتبقي';

  @override
  String get issuedBy => 'جهة الإصدار';

  @override
  String get documentInformation => 'معلومات المستند';

  @override
  String get noRemindersSelected => 'لم يتم اختيار تذكيرات';

  @override
  String get attachmentPreview => 'معاينة المرفق';

  @override
  String get renewalHistory => 'سجل التجديد';

  @override
  String get noRenewalHistory => 'لا يوجد تجديد مسجّل بعد.';

  @override
  String get recordRenewal => 'تسجيل تجديد';

  @override
  String get recordRenewalSubtitle =>
      'أضف تجديدًا واحدًا لهذه الجلسة. تبقى بقية التفاصيل كما هي ما لم تختر تاريخ بدء جديد.';

  @override
  String get previousExpiry => 'تاريخ الانتهاء السابق';

  @override
  String get newExpiry => 'تاريخ الانتهاء الجديد';

  @override
  String get renewalDate => 'تاريخ التجديد';

  @override
  String get renewalNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get renewalRecorded => 'تم تسجيل التجديد لهذه الجلسة.';

  @override
  String get errorNewExpiryNotAfterPrevious =>
      'يجب أن يكون تاريخ الانتهاء الجديد بعد التاريخ السابق.';

  @override
  String get errorNewExpiryRequired => 'تاريخ الانتهاء الجديد مطلوب.';

  @override
  String get errorActionAfterNewExpiry =>
      'لا يمكن أن يكون تاريخ بدء التجديد بعد تاريخ الانتهاء الجديد.';

  @override
  String get documentUnavailableTitle => 'المستند غير متاح';

  @override
  String get documentUnavailableMessage =>
      'لم يعد هذا المستند موجودًا في هذه الجلسة.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get discardChangesTitle => 'تجاهل التغييرات؟';

  @override
  String get discardChangesMessage => 'لن تُحفظ تعديلاتك.';

  @override
  String get moreActions => 'المزيد من الإجراءات';

  @override
  String get editAction => 'تعديل';

  @override
  String maskedDocumentNumberLabel(String number) {
    return 'رقم المستند المخفي $number';
  }

  @override
  String get ownerLabel => 'المالك';

  @override
  String get optionalNewActionDate => 'تاريخ بدء التجديد الجديد (اختياري)';

  @override
  String get saveRenewal => 'حفظ التجديد';

  @override
  String get viewAttachment => 'عرض الصورة';

  @override
  String get noPhotoAttached => 'لا توجد صورة مرفقة';

  @override
  String get documentPassLabel => 'ملخص المستند';

  @override
  String get documentsEyebrow => 'محفظة رقمية';

  @override
  String get documentsSearchPlaceholder => 'ابحث في مستنداتك';

  @override
  String get documentsFilterAll => 'الكل';

  @override
  String get documentsSearchEmptyTitle => 'لا توجد مستندات مطابقة';

  @override
  String get documentsSearchEmptyMessage =>
      'جرّب اسمًا أو نوعًا أو مالكًا آخر، أو امسح البحث لعرض محفظتك.';

  @override
  String get documentsFilterEmptyTitle => 'لا شيء في هذا التصفية';

  @override
  String get documentsFilterEmptyMessage =>
      'اختر حالة أخرى، أو حدد الكل لعرض كل المستندات المحفوظة.';

  @override
  String get documentsRemainingHeader => 'كل المستندات';

  @override
  String get documentPassTitle => 'بطاقة المستند';

  @override
  String get documentPassEyebrow => 'تفاصيل موثّقة';

  @override
  String get viewScan => 'عرض المسح';

  @override
  String get remindersTitle => 'التذكيرات';

  @override
  String get renewalHistoryEmptyTitle => 'لا توجد تجديدات بعد';

  @override
  String wizardStepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get wizardContinue => 'متابعة';

  @override
  String get wizardBack => 'رجوع';

  @override
  String get stepSourceTitle => 'مسح أو إدخال يدوي';

  @override
  String get stepIdentityTitle => 'هوية المستند';

  @override
  String get stepDatesTitle => 'التواريخ المهمة';

  @override
  String get stepRenewalTitle => 'تخطيط التجديد';

  @override
  String get stepReviewTitle => 'مراجعة وحفظ';

  @override
  String get howToAddTitle => 'كيف تريد إضافته؟';

  @override
  String get scanDocumentTitle => 'مسح المستند';

  @override
  String get scanDocumentRecommended => 'موصى به';

  @override
  String get scanDocumentSubtitle =>
      'التقط صورة أو اختر صورة، ثم راجع التفاصيل المستخرجة.';

  @override
  String get enterManuallyTitle => 'إدخال يدوي';

  @override
  String get enterManuallySubtitle => 'أدخل التفاصيل بنفسك خطوة بخطوة.';

  @override
  String get ocrPrivacy =>
      'تتم معالجة المسح على هذا الجهاز. لا يُحفظ شيء حتى تؤكد.';

  @override
  String get ocrReviewPrivacy =>
      'تتم معالجة المسح على هذا الجهاز. راجع كل التفاصيل المستخرجة قبل الحفظ.';

  @override
  String get scanAgain => 'مسح مرة أخرى';

  @override
  String get ocrProcessingTitle => 'جارٍ قراءة هذا المستند';

  @override
  String get ocrProcessingMessage =>
      'يتم التعرف على النص على هذا الجهاز. يمكنك الإلغاء وإدخال التفاصيل يدويًا.';

  @override
  String get ocrCancel => 'إلغاء المسح';

  @override
  String get ocrFailedTitle => 'تعذر قراءة هذا المسح';

  @override
  String get ocrFailedMessage =>
      'احتفظ بالصورة وأدخل التفاصيل يدويًا، أو جرّب صورة أخرى.';

  @override
  String get ocrRetry => 'إعادة المحاولة';

  @override
  String get ocrReviewTitle => 'مراجعة المسح';

  @override
  String ocrFieldsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم العثور على $count حقلًا',
      few: 'تم العثور على $count حقول',
      two: 'تم العثور على حقلين',
      one: 'تم العثور على حقل واحد',
      zero: 'لم يتم العثور على حقول',
    );
    return '$_temp0';
  }

  @override
  String get ocrConfidenceHigh => 'ثقة عالية';

  @override
  String get ocrConfidenceReview => 'راجع';

  @override
  String get ocrConfidenceMissing => 'غير مكتشَف';

  @override
  String get ocrReviewField => 'راجع هذا الحقل';

  @override
  String get ocrSuggestedCountry => 'البلد المقترح';

  @override
  String get ocrSuggestedType => 'نوع المستند المقترح';

  @override
  String get ocrAddMissingField => 'إضافة حقل ناقص';

  @override
  String get ocrConfirmContinue => 'تأكيد ومتابعة';

  @override
  String get ocrRetake => 'إعادة الالتقاط أو الاستبدال';

  @override
  String get fieldCountry => 'البلد أو المنطقة';

  @override
  String get schemaChangeTitle => 'تغيير نوع المستند؟';

  @override
  String get schemaChangeMessage =>
      'بعض التفاصيل التي أدخلتها لا تنتمي إلى النوع الجديد وسيتم حذفها.';

  @override
  String get schemaChangeConfirm => 'تغيير النوع';

  @override
  String get schemaChangeCancel => 'الإبقاء على النوع الحالي';

  @override
  String get addCustomField => 'إضافة حقل مخصص';

  @override
  String get customFieldLabel => 'اسم الحقل';

  @override
  String get customFieldValue => 'القيمة';

  @override
  String get removeCustomField => 'إزالة الحقل';

  @override
  String get markFieldSensitive => 'إخفاء هذه القيمة خارج المراجعة';

  @override
  String get reviewJumpIdentity => 'تعديل الهوية';

  @override
  String get reviewJumpDates => 'تعديل التواريخ';

  @override
  String get reviewJumpRenewal => 'تعديل خطة التجديد';

  @override
  String get reviewJumpScan => 'تعديل المسح';

  @override
  String get reviewAttachmentYes => 'توجد صورة مرفقة';

  @override
  String get reviewAttachmentNo => 'لا توجد صورة مرفقة';

  @override
  String reviewDynamicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حقلًا إضافيًا',
      few: '$count حقول إضافية',
      two: 'حقلان إضافيان',
      one: 'حقل إضافي واحد',
      zero: 'لا توجد حقول إضافية',
    );
    return '$_temp0';
  }

  @override
  String suggestedActionDate(String date) {
    return 'تاريخ البدء المقترح: $date';
  }

  @override
  String get useSuggestedActionDate => 'استخدام التاريخ المقترح';

  @override
  String get countryGeneric => 'دولي';

  @override
  String get countryIndia => 'الهند';

  @override
  String get countryFrance => 'فرنسا';

  @override
  String get countryUae => 'الإمارات العربية المتحدة';

  @override
  String get countryOther => 'أخرى';

  @override
  String get schemaGenericPassport => 'جواز سفر';

  @override
  String get schemaIndiaAadhaar => 'آدهار';

  @override
  String get schemaFranceNationalId => 'بطاقة الهوية الفرنسية';

  @override
  String get schemaUaeEmiratesId => 'هوية الإمارات';

  @override
  String get schemaGenericOther => 'مستند آخر';

  @override
  String get fieldPassportNumber => 'رقم جواز السفر';

  @override
  String get fieldFullName => 'الاسم الكامل';

  @override
  String get fieldNationality => 'الجنسية';

  @override
  String get fieldDateOfBirth => 'تاريخ الميلاد';

  @override
  String get fieldGender => 'الجنس';

  @override
  String get fieldAddress => 'العنوان';

  @override
  String get fieldSurname => 'اسم العائلة';

  @override
  String get fieldGivenNames => 'الأسماء الأولى';

  @override
  String get fieldAadhaarNumber => 'رقم آدهار';

  @override
  String get fieldIdNumber => 'رقم الهوية';

  @override
  String get navDocumentsShort => 'مستندات';

  @override
  String get navSubscriptionsShort => 'خطط';

  @override
  String get navProfileShort => 'أنا';

  @override
  String get snapshotNinetyDayView => 'عرض 90 يومًا';

  @override
  String get profileMonogram => 'R';

  @override
  String get guidedSetup => 'إعداد موجّه';

  @override
  String get ocrOnDeviceEyebrow => 'استخراج على الجهاز';

  @override
  String get howToAddBody => 'امسح للبدء بسرعة، أو أدخل التفاصيل بنفسك.';

  @override
  String get identityIntro => 'نعرض فقط الحقول المناسبة لهذا المستند.';

  @override
  String get datesIntro => 'تشمل التواريخ دائمًا اليوم والشهر والسنة.';

  @override
  String get planningIntro =>
      'التفاصيل الاختيارية تساعدك على معرفة ما يستحق الانتباه.';

  @override
  String get reviewIntro => 'راجع التفاصيل المهمة. يمكنك تعديل كل شيء لاحقًا.';

  @override
  String get readyToSave => 'جاهز للحفظ';

  @override
  String get scanToFill => 'امسح لتعبئة هذه الحقول تلقائيًا';

  @override
  String get ocrDynamicTemplateTitle => 'قالب حقول ديناميكي';

  @override
  String get ocrDynamicTemplateBody =>
      'تتغير الحقول حسب البلد ونوع المستند. تظهر التسميات غير المعروفة كحقول مخصصة.';

  @override
  String get ocrReviewHint => 'راجع القيم المميّزة قبل المتابعة.';

  @override
  String get ocrProcessingHint => 'يتم التعرف على النص على هذا الجهاز.';
}
