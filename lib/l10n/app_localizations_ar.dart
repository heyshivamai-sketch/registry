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
      'تبقى التذكيرات على هذا الجهاز. لا توجد رسائل عبر خادم.';

  @override
  String get searchPlaceholder => 'ابحث في سجلك';

  @override
  String get searchClear => 'مسح البحث';

  @override
  String get filterTooltip => 'تصفية';

  @override
  String get filtersComingSoon => 'ستتوفر عوامل التصفية في إصدار لاحق.';

  @override
  String get reviewAction => 'راجع الآن';

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
  String get sectionNeedsAttention => 'يحتاج انتباهك';

  @override
  String get sectionComingUp => 'القادم';

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
  String get statusUrgent => 'يلزم اتخاذ إجراء';

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
      'يُحفظ مع هذا المستند. يطلب Registry من هذا الجهاز إشعارًا محليًا في الساعة 9:00 بتوقيتك المحلي لكل تاريخ محدد لم يمر بعد. قد يسلّمه النظام لاحقًا. يمكنك الحفظ إذا كانت الإشعارات متوقفة.';

  @override
  String get reminderOnActionDate => 'في تاريخ الإجراء';

  @override
  String get reminder7Days => 'قبل 7 أيام';

  @override
  String get reminder30Days => 'قبل 30 يومًا';

  @override
  String get saveDocument => 'حفظ المستند';

  @override
  String get documentSaved => 'تم حفظ المستند على هذا الجهاز.';

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
  String get editDocumentSubtitle => 'تبقى التغييرات على هذا الجهاز.';

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
    return 'ستتم إزالة $name من هذا الجهاز.';
  }

  @override
  String get deleteDocumentConfirm => 'حذف';

  @override
  String get deleteDocumentCancel => 'إلغاء';

  @override
  String get documentUpdated => 'تم تحديث المستند على هذا الجهاز.';

  @override
  String get documentDeleted => 'تم حذف المستند من هذا الجهاز.';

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
      'أضف تجديدًا واحدًا على هذا الجهاز. تبقى بقية التفاصيل كما هي ما لم تختر تاريخ بدء جديد.';

  @override
  String get previousExpiry => 'تاريخ الانتهاء السابق';

  @override
  String get newExpiry => 'تاريخ الانتهاء الجديد';

  @override
  String get renewalDate => 'تاريخ التجديد';

  @override
  String get renewalNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get renewalRecorded => 'تم تسجيل التجديد على هذا الجهاز.';

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
      'لم يعد هذا المستند موجودًا على هذا الجهاز.';

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
  String get renewAction => 'تجديد';

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
  String get documentPassEyebrow => 'تفاصيل المستند';

  @override
  String get viewScan => 'عرض المسح';

  @override
  String get remindersTitle => 'التذكيرات';

  @override
  String get reminderPreferencesTitle => 'تفضيلات التذكير';

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
  String get stepIdentityTitle => 'اجعله خاصًا بك';

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
  String get ocrReviewTitle => 'راجع المسح';

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
  String get ocrReviewField => 'تحقق من هذه القيمة';

  @override
  String get ocrSuggestedCountry => 'البلد المقترح';

  @override
  String get ocrSuggestedType => 'نوع المستند المقترح';

  @override
  String get ocrAddMissingField => 'إضافة حقل ناقص';

  @override
  String get ocrConfirmContinue => 'تأكيد التفاصيل';

  @override
  String get ocrRetake => 'إعادة المسح';

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
  String get identityIntro => 'بعض التفاصيل لتنظيم مستندك.';

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

  @override
  String get horizonOpenCalendar => 'فتح التقويم';

  @override
  String get horizon90EmptyTitle => 'لا شيء خلال الـ 90 يومًا القادمة';

  @override
  String get horizon90EmptyMessage =>
      'ستظهر هنا العناصر التي لها تاريخ إجراء أو تجديد خلال الـ 90 يومًا القادمة، من الأقرب إلى الأبعد.';

  @override
  String get catalogReviewEyebrow => 'عنصر مميز';

  @override
  String get catalogReviewTitle => 'مراجعة';

  @override
  String get catalogNotInWalletTitle => 'كتالوج الصفحة الرئيسية';

  @override
  String get catalogNotInWallet =>
      'هذا هو العنصر المميز في الصفحة الرئيسية. وهو غير محفوظ في المستندات، لذا لا يتوفر التعديل أو الحذف أو تسجيل التجديد.';

  @override
  String get catalogActionLabel => 'الإجراء التالي';

  @override
  String get catalogRemainingLabel => 'الوقت المتبقي';

  @override
  String get catalogChargeDate => 'تاريخ الدفعة التالية';

  @override
  String get documentStatusLabel => 'الحالة';

  @override
  String get homeEmptyTitle => 'سجلك فارغ';

  @override
  String get homeEmptyMessage =>
      'أضف مستندًا أو اشتراكًا لبدء تتبع التواريخ المهمة.';

  @override
  String get homeCalmTitle => 'لا يوجد ما يحتاج انتباهك الآن';

  @override
  String get homeCalmMessage =>
      'العناصر المحفوظة محدّثة. تظهر التواريخ القادمة في قسم القادم.';

  @override
  String homeEstimatedMonthly(String amount) {
    return '$amount / شهر';
  }

  @override
  String get pulseDecideByEyebrow => 'قرّر قبل';

  @override
  String get pulseNextChargeEyebrow => 'الدفعة التالية';

  @override
  String get subscriptionsEyebrow => 'أنفق بنية';

  @override
  String get subscriptionsSearchPlaceholder => 'ابحث في الاشتراكات';

  @override
  String subscriptionsSavedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محفوظة',
      one: 'واحد محفوظ',
    );
    return '$_temp0';
  }

  @override
  String subscriptionsActiveSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خطط نشطة',
      one: 'خطة نشطة واحدة',
    );
    return '$_temp0';
  }

  @override
  String subscriptionsAttentionSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قرارات مستحقة',
      one: 'قرار واحد مستحق',
      zero: 'لا قرارات مستحقة',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionsListHeader => 'الخطط';

  @override
  String get addSubscriptionShort => 'إضافة';

  @override
  String get subscriptionsSearchEmptyTitle => 'لا توجد خطط مطابقة';

  @override
  String get subscriptionsSearchEmptyMessage =>
      'جرّب اسمًا أو فئة أخرى، أو امسح البحث لرؤية كل الخطط.';

  @override
  String get subscriptionsFilterEmptyTitle => 'لا شيء في هذا التصفية';

  @override
  String get subscriptionsFilterEmptyMessage =>
      'اختر حالة أخرى، أو الكل لرؤية كل الخطط المحفوظة.';

  @override
  String get monthlySnapshotEyebrow => 'لمحة شهرية';

  @override
  String get estimatedMonthlyCost => 'التكلفة الشهرية التقديرية';

  @override
  String get estimatedMonthlyDisclaimer =>
      'تقدير موحّد للخطط النشطة. ليس إنفاقًا فعليًا ولا مدفوعات سابقة.';

  @override
  String estimatedMonthlyMultiple(int count) {
    return '$count عملات';
  }

  @override
  String get fieldServiceName => 'اسم الخدمة';

  @override
  String get fieldPlanName => 'اسم الخطة';

  @override
  String get fieldAmount => 'المبلغ';

  @override
  String get fieldCurrency => 'العملة';

  @override
  String get fieldBillingCycle => 'دورة الفوترة';

  @override
  String get fieldNextPayment => 'تاريخ الدفعة التالية';

  @override
  String get fieldDecideBy => 'تاريخ اتخاذ القرار';

  @override
  String get fieldAutoRenew => 'التجديد التلقائي';

  @override
  String get billingWeekly => 'أسبوعي';

  @override
  String get billingMonthly => 'شهري';

  @override
  String get billingQuarterly => 'ربع سنوي';

  @override
  String get billingYearly => 'سنوي';

  @override
  String get billingPerWeek => '/ أسبوع';

  @override
  String get billingPerMonth => '/ شهر';

  @override
  String get billingPerQuarter => '/ ربع سنة';

  @override
  String get billingPerYear => '/ سنة';

  @override
  String get subscriptionCategoryEntertainment => 'ترفيه';

  @override
  String get subscriptionCategoryHealth => 'صحة';

  @override
  String get subscriptionCategoryProductivity => 'إنتاجية';

  @override
  String get subscriptionCategoryUtilities => 'خدمات';

  @override
  String get subscriptionCategoryFinance => 'مالية';

  @override
  String get subscriptionCategoryEducation => 'تعليم';

  @override
  String get subscriptionCategoryOther => 'أخرى';

  @override
  String get subscriptionServiceIntroTitle => 'ماذا تتابع؟';

  @override
  String get subscriptionServiceIntro => 'ابدأ باسم الخدمة والفئة.';

  @override
  String get subscriptionBillingIntroTitle => 'عيّن الفوترة';

  @override
  String get subscriptionBillingIntro => 'تتبع تفاصيل اشتراكك.';

  @override
  String get subscriptionPreferencesIntroTitle => 'ابقَ سابقًا للدفعة';

  @override
  String get subscriptionPreferencesIntro => 'اختر متى تريد اتخاذ القرار.';

  @override
  String get subscriptionReviewIntroTitle => 'جاهز للمتابعة';

  @override
  String get subscriptionReviewIntro => 'أكد الخطة قبل إضافتها إلى سجلك.';

  @override
  String get saveSubscription => 'حفظ الاشتراك';

  @override
  String get subscriptionSaved => 'تم حفظ الاشتراك على هذا الجهاز.';

  @override
  String get subscriptionUpdated => 'تم تحديث الاشتراك على هذا الجهاز.';

  @override
  String get subscriptionDeleted => 'تم حذف الاشتراك من هذا الجهاز.';

  @override
  String get subscriptionSaveFailed =>
      'تعذر حفظ الخطة. المسودة ما زالت هنا. حاول مرة أخرى.';

  @override
  String get editSubscriptionTitle => 'تعديل الاشتراك';

  @override
  String get subscriptionDetailsTitle => 'اشتراك';

  @override
  String get planDetailsEyebrow => 'تفاصيل الخطة';

  @override
  String get planInformation => 'معلومات الخطة';

  @override
  String get nextDecision => 'القرار التالي';

  @override
  String get subscriptionUnavailableTitle => 'الخطة غير متاحة';

  @override
  String get subscriptionUnavailableMessage =>
      'هذه الخطة لم تعد على هذا الجهاز.';

  @override
  String get nextPaymentHelper =>
      'تبقى التواريخ الماضية تتبعًا غير محسوم. لا يتم تقديم التواريخ تلقائيًا.';

  @override
  String get decideByHelper => 'يجب أن يكون في تاريخ الدفعة أو قبله.';

  @override
  String get clearDecideBy => 'مسح تاريخ القرار';

  @override
  String get autoRenewHelper =>
      'تفضيل تتابعه في هذا التطبيق. لا يغيّر شيئًا لدى المزود.';

  @override
  String get autoRenewOn => 'تشغيل';

  @override
  String get autoRenewOff => 'إيقاف';

  @override
  String get subscriptionRemindersHelper =>
      'يُحفظ مع هذه الخطة. قبل 7 أيام وقبل يوم يتبعان تاريخ القرار، أو تاريخ الدفع إذا كان تاريخ القرار فارغًا. يوم الدفعة يتبع تاريخ الدفع. يُطلب كل تذكير للساعة 9:00 بتوقيتك المحلي فقط إذا كان ذلك الوقت لم يأتِ بعد. قد يسلّمه النظام لاحقًا. يمكنك الحفظ إذا كانت الإشعارات متوقفة.';

  @override
  String get subscriptionReminder7Days => 'قبل 7 أيام';

  @override
  String get subscriptionReminder1Day => 'قبل يوم واحد';

  @override
  String get subscriptionReminderOnCharge => 'يوم الدفعة';

  @override
  String get decideByWhyTitle => 'لماذا تاريخ القرار؟';

  @override
  String get decideByWhyMessage =>
      'يمنحك وقتًا للمراجعة أو الإلغاء قبل تاريخ الدفع.';

  @override
  String get reviewJumpService => 'تعديل الخدمة';

  @override
  String get reviewJumpBilling => 'تعديل الفوترة';

  @override
  String get reviewJumpPreferences => 'تعديل التفضيلات';

  @override
  String get subscriptionSessionNote =>
      'تبقى الخطط على هذا الجهاز. لا يوجد ربط بنكي ولا معالجة دفع.';

  @override
  String get errorDecideByAfterPayment =>
      'يجب أن يكون تاريخ القرار في تاريخ الدفعة أو قبله.';

  @override
  String get errorAmountNegative => 'لا يمكن أن يكون المبلغ سالبًا.';

  @override
  String get errorAmountInvalid => 'أدخل مبلغًا صالحًا لهذه العملة.';

  @override
  String get errorAmountPrecision =>
      'هذه العملة لا تسمح بهذا العدد من الخانات العشرية.';

  @override
  String get subscriptionCancelled => 'ملغى';

  @override
  String get subscriptionActive => 'نشط';

  @override
  String get lifecycleLabel => 'حالة التتبع';

  @override
  String get markCancelled => 'وضع علامة ملغى';

  @override
  String get cancelPlanTitle => 'إيقاف تتبع هذه الخطة؟';

  @override
  String cancelPlanMessage(String name) {
    return 'يؤثر هذا فقط على تتبع $name في هذا التطبيق. لا يلغي الاشتراك لدى المزود.';
  }

  @override
  String get planMarkedCancelled => 'تم تعليم الخطة كملغاة على هذا الجهاز.';

  @override
  String get reactivatePlan => 'إعادة التفعيل';

  @override
  String get reactivatePlanTitle => 'إعادة تفعيل هذه الخطة؟';

  @override
  String reactivatePlanMessage(String name) {
    return 'أكد تاريخ الدفعة التالية لـ $name. يستأنف هذا التتبع في هذا التطبيق فقط.';
  }

  @override
  String get planReactivated => 'أُعيد تفعيل الخطة على هذا الجهاز.';

  @override
  String get deleteSubscription => 'حذف الخطة';

  @override
  String get deleteSubscriptionTitle => 'حذف هذه الخطة؟';

  @override
  String deleteSubscriptionMessage(String name) {
    return 'ستُزال $name من هذا الجهاز.';
  }

  @override
  String get subscriptionTrackingDisclaimer =>
      'يتتبع السجل هذه الخطة لكنه لا يلغيها ولا يحصّلها تلقائيًا.';

  @override
  String homeHeroReview(String title) {
    return 'راجع $title';
  }

  @override
  String get homeHeroRenewalToday => 'يبدأ التجديد اليوم';

  @override
  String homeHeroRenewalOn(String date) {
    return 'يبدأ التجديد في $date';
  }

  @override
  String get homeHeroDecideToday => 'القرار مستحق اليوم';

  @override
  String homeHeroDecideOn(String date) {
    return 'قرّر قبل $date';
  }

  @override
  String get homeCalmUpcomingCta => 'عرض القادم';

  @override
  String get homeEmptyHeadline => 'تنظيم بسيط.\nوطمأنينة كبيرة.';

  @override
  String get homeEmptySupporting =>
      'اجمع مستنداتك واشتراكاتك في مكان واحد، واعرف ما يحتاج انتباهك.';

  @override
  String get homeAddFirstDocument => 'أضف أول مستند';

  @override
  String get homeAddASubscription => 'أضف اشتراكًا';

  @override
  String get homeBenefitDatesTitle => 'اطّلع على التواريخ المهمة بنظرة';

  @override
  String get homeBenefitDatesMessage => 'لا تفوّت ما يهم.';

  @override
  String get homeBenefitPlansTitle => 'راجع الخطط قبل تجديدها';

  @override
  String get homeBenefitPlansMessage => 'ابقَ متحكمًا في إنفاقك.';

  @override
  String get homeEstimatedMonthlyCost => 'التكلفة الشهرية المقدّرة';

  @override
  String homeSubscriptionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اشتراكات',
      one: 'اشتراك واحد',
      zero: 'لا اشتراكات',
    );
    return '$_temp0';
  }

  @override
  String get homeViewAll => 'عرض الكل';

  @override
  String get homeAttentionListTitle => 'يحتاج انتباهك';

  @override
  String get comingUpFilterAll => 'الكل';

  @override
  String get comingUpFilterDocuments => 'المستندات';

  @override
  String get comingUpFilterSubscriptions => 'الاشتراكات';

  @override
  String comingUpThisWeek(String year) {
    return 'هذا الأسبوع · $year';
  }

  @override
  String comingUpLaterThisMonth(String year) {
    return 'لاحقًا هذا الشهر · $year';
  }

  @override
  String comingUpMonthYear(String month, String year) {
    return '$month · $year';
  }

  @override
  String get comingUpEmptyFilter => 'لا يوجد قادم في هذا العرض.';

  @override
  String get attentionEmpty => 'لا يوجد ما يحتاج انتباهك الآن.';

  @override
  String get statusToday => 'اليوم';

  @override
  String get homeStartRenewal => 'ابدأ التجديد';

  @override
  String get homeNextPayment => 'الدفعة التالية';

  @override
  String get homeDecideBeforeRenewal => 'قرّر قبل التجديد';

  @override
  String get homeSeeAllCurrencies => 'عرض كل إجماليات العملات';

  @override
  String get homeNoActivePlans => 'لا خطط نشطة';

  @override
  String get homeCurrencyBreakdownTitle => 'التقديرات الشهرية';

  @override
  String get homeDocumentsTile => 'المستندات';

  @override
  String get changeSelection => 'تغيير';

  @override
  String get fromScan => 'من المسح';

  @override
  String get checkThisDate => 'تحقق من هذا التاريخ';

  @override
  String get searchListHint => 'بحث';

  @override
  String get identityExtrasTitle => 'تفاصيل إضافية (اختياري)';

  @override
  String get identityExtrasSubtitle => 'الرقم والجهة المصدرة والحقول المخصصة';

  @override
  String get ocrReviewSubtitle => 'تحقق من التفاصيل المستخرجة قبل المتابعة.';

  @override
  String get ocrNothingSavedHint => 'لن يُحفظ شيء حتى تختار حفظ المستند.';

  @override
  String get remindMePrefix => 'ذكّرني';

  @override
  String attachmentAddedOn(String date) {
    return 'أُضيف في $date';
  }

  @override
  String estimatedMonthlyCostValue(String amount) {
    return 'التكلفة الشهرية التقديرية $amount';
  }

  @override
  String get selectedDocumentType => 'نوع المستند المحدد';

  @override
  String get chooseOption => 'اختر';

  @override
  String get storageLoadingLabel => 'جارٍ تحميل السجلات المحفوظة';

  @override
  String get storageErrorTitle => 'تعذر فتح السجلات المحفوظة';

  @override
  String get storageErrorMessage =>
      'تعذر على Registry فتح السجلات المخزنة بالفعل على هذا الجهاز. تُركت هذه السجلات كما هي. أعد المحاولة دون إعادة ضبط التطبيق.';

  @override
  String get storageErrorRetry => 'إعادة المحاولة';

  @override
  String get reminderPermissionDenied =>
      'الإشعارات متوقفة، لذلك لن يُجدول أي تذكير. يمكنك الحفظ رغم ذلك. فعّلها من إعدادات الإشعارات عندما تريد التذكيرات.';

  @override
  String get reminderStatusScheduled =>
      'تمت جدولة تذكير محلي على هذا الجهاز. لا يضمن النظام التسليم في تمام الساعة 9:00.';

  @override
  String get reminderStatusPermissionOff =>
      'هذه الخيارات محفوظة. الإشعارات غير مسموح بها، لذلك لا يوجد تذكير مجدول.';

  @override
  String get reminderStatusPast =>
      'هذه الخيارات محفوظة. لا يوجد تذكير مجدول لأن كل وقت محدد قد مضى.';

  @override
  String get reminderStatusLimited =>
      'هذه الخيارات محفوظة. لا يوجد تذكير مجدول لهذا السجل لأن هذا الجهاز يحتفظ بعدد محدود من التذكيرات المحلية المنتظرة.';

  @override
  String get reminderStatusCancelled =>
      'هذه الخيارات محفوظة. لا يوجد تذكير مجدول بينما هذه الخطة معلّمة كملغاة.';

  @override
  String get reminderStatusUnavailable =>
      'هذه الخيارات محفوظة. لا يمكن جدولة تذكيرات محلية على هذا الجهاز الآن.';

  @override
  String notificationsScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكيرات محلية مجدولة على هذا الجهاز.',
      one: 'تذكير محلي واحد مجدول على هذا الجهاز.',
      zero: 'لا توجد تذكيرات محلية مجدولة على هذا الجهاز.',
    );
    return '$_temp0';
  }

  @override
  String get notificationsPermissionOff =>
      'الإشعارات متوقفة. تبقى خيارات التذكير محفوظة مع كل سجل، ولا يُجدول شيء حتى تُفعَّل الإشعارات من إعدادات النظام.';

  @override
  String get notificationsLimits =>
      'تبقى التذكيرات على هذا الجهاز. لا يوجد خادم ولا رسائل سحابية. يطلب التطبيق الساعة 9:00 بتوقيتك الحالي، بما في ذلك التوقيت الصيفي، لكن أندرويد قد يسلّم التذكير لاحقًا. يستعيد أندرويد التذكيرات المجدولة بعد إعادة التشغيل العادية، ويسقطها بعد الإيقاف الإجباري إلى أن تفتح التطبيق مرة أخرى. يمكن لـ iOS الاحتفاظ بالتذكيرات المحلية المنتظرة بعد إعادة التشغيل، حتى 64. يجدول التطبيق 64 على الأكثر، الأقرب أولًا.';

  @override
  String notificationsOmittedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لم تُجدول $count تذكيرات محفوظة بسبب هذا الحد.',
      one: 'لم يُجدول تذكير محفوظ واحد بسبب هذا الحد.',
    );
    return '$_temp0';
  }

  @override
  String get notificationsAllow => 'السماح بالإشعارات';

  @override
  String get notificationsOpenSettings => 'إعدادات الإشعارات';

  @override
  String get notificationsUnavailable =>
      'لا يمكن لهذا الجهاز جدولة تذكيرات محلية الآن. خيارات التذكير المحفوظة لم تتغير.';

  @override
  String get notificationChannelName => 'تذكيرات السجل';

  @override
  String get notificationChannelDescription =>
      'تذكيرات محلية لتواريخ المستندات ومدفوعات الاشتراكات. وقت التسليم ليس دقيقًا.';

  @override
  String get notificationTitle => 'تذكير';

  @override
  String get reminderDocumentActionToday => 'تاريخ إجراء مستند هو اليوم.';

  @override
  String reminderDocumentActionIn7(String date) {
    return 'تاريخ إجراء مستند بعد 7 أيام، في $date.';
  }

  @override
  String reminderDocumentActionIn30(String date) {
    return 'تاريخ إجراء مستند بعد 30 يومًا، في $date.';
  }

  @override
  String get reminderDocumentExpiryToday => 'تاريخ انتهاء مستند هو اليوم.';

  @override
  String reminderDocumentExpiryIn7(String date) {
    return 'ينتهي مستند بعد 7 أيام، في $date.';
  }

  @override
  String reminderDocumentExpiryIn30(String date) {
    return 'ينتهي مستند بعد 30 يومًا، في $date.';
  }

  @override
  String reminderSubscriptionDecideIn7(String date) {
    return 'قرار اشتراك مستحق بعد 7 أيام، في $date.';
  }

  @override
  String reminderSubscriptionDecideIn1(String date) {
    return 'قرار اشتراك مستحق غدًا، في $date.';
  }

  @override
  String reminderSubscriptionPaymentIn7(String date) {
    return 'دفعة اشتراك بعد 7 أيام، في $date.';
  }

  @override
  String reminderSubscriptionPaymentIn1(String date) {
    return 'دفعة اشتراك غدًا، في $date.';
  }

  @override
  String get reminderSubscriptionChargeToday => 'تاريخ دفع اشتراك هو اليوم.';

  @override
  String get backupSectionTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupSectionBody =>
      'صدّر ملف نسخة احتياطية مشفّرًا، أو استبدل سجل هذا الجهاز من نسخة احتياطية. يُشفَّر الملف بكلمة مرور تختارها. لا يحفظ Registry كلمة المرور، وهذا لا يشفّر قاعدة السجل الموجودة بالفعل على هذا الجهاز.';

  @override
  String get backupExportAction => 'تصدير نسخة احتياطية';

  @override
  String get backupImportAction => 'استيراد نسخة احتياطية';

  @override
  String get backupExportTitle => 'تصدير نسخة احتياطية';

  @override
  String get backupIncluded =>
      'يتضمن الملف المستندات والاشتراكات والحقول المخصصة وسجل التجديد وخيارات التذكير والتواريخ والمبالغ وصور المستندات.';

  @override
  String get backupPasswordWarning =>
      'اختر كلمة مرور لهذا الملف. إذا فقدتها، لا يمكن استعادة هذه النسخة. لا يحفظ Registry كلمة المرور.';

  @override
  String get backupPasswordLabel => 'كلمة مرور النسخة الاحتياطية';

  @override
  String get backupConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get backupPasswordTooShort => 'استخدم 8 أحرف على الأقل.';

  @override
  String get backupPasswordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get backupShowPassword => 'إظهار كلمة المرور';

  @override
  String get backupHidePassword => 'إخفاء كلمة المرور';

  @override
  String get backupChooseSave => 'اختر مكان الحفظ';

  @override
  String get backupImportTitle => 'استيراد نسخة احتياطية';

  @override
  String get backupImportIntro =>
      'اختر ملف نسخة احتياطية وأدخل كلمة مروره. الاستيراد يستبدل كل مستند وكل اشتراك على هذا الجهاز.';

  @override
  String get backupChooseFile => 'اختيار ملف النسخة الاحتياطية';

  @override
  String get backupSelectedFile => 'تم اختيار ملف النسخة الاحتياطية';

  @override
  String get backupNoFile => 'اختر ملف نسخة احتياطية أولًا.';

  @override
  String get backupCheckAction => 'التحقق من النسخة';

  @override
  String backupPreview(int documents, int subscriptions, int attachments) {
    return 'تحتوي هذه النسخة على $documents مستندات و$subscriptions اشتراكات و$attachments صور. استبدال سجل هذا الجهاز يزيل السجلات المخزنة هنا ويضع هذه النسخة مكانها. لا تُدمج السجلات.';
  }

  @override
  String get backupReplaceAction => 'استبدال سجل هذا الجهاز';

  @override
  String get backupReplaceTitle => 'استبدال سجل هذا الجهاز؟';

  @override
  String get backupReplaceBody =>
      'ستُستبدل المستندات والاشتراكات والصور على هذا الجهاز بهذه النسخة الاحتياطية.';

  @override
  String get backupCancel => 'إلغاء';

  @override
  String get backupPhaseProtecting => 'جارٍ حماية النسخة الاحتياطية…';

  @override
  String get backupPhaseWriting => 'جارٍ حفظ ملف النسخة الاحتياطية…';

  @override
  String get backupPhaseChecking => 'جارٍ التحقق من النسخة الاحتياطية…';

  @override
  String get backupPhaseRestoring => 'جارٍ استبدال سجل هذا الجهاز…';

  @override
  String get backupExportSaved => 'تم حفظ النسخة الاحتياطية.';

  @override
  String get backupExportCancelled =>
      'أُلغي التصدير. لم يُحفظ ملف نسخة احتياطية.';

  @override
  String get backupExportNotSaved =>
      'لم يُحفظ ملف النسخة الاحتياطية. تعذر الكتابة إلى الوجهة.';

  @override
  String get backupExportStorage =>
      'لا توجد مساحة كافية لحفظ هذه النسخة. لم يُحفظ ملف.';

  @override
  String get backupExportTooLarge =>
      'هذا السجل أكبر من أن يُصدَّر في نسخة واحدة. لم يُحفظ ملف.';

  @override
  String get backupExportFailed =>
      'تعذر إنشاء النسخة الاحتياطية. لم يُحفظ ملف.';

  @override
  String get backupImportReplaced =>
      'استُبدل سجل هذا الجهاز من النسخة الاحتياطية.';

  @override
  String get backupImportCancelled => 'أُلغي الاستيراد.';

  @override
  String get backupWrongPassword => 'كلمة المرور هذه لا تفتح هذه النسخة.';

  @override
  String get backupUnsupportedVersion =>
      'أُنشئت هذه النسخة بإصدار أحدث من Registry.';

  @override
  String get backupInvalidFile =>
      'هذا الملف ليس نسخة احتياطية صالحة من Registry.';

  @override
  String get backupTampered => 'ملف النسخة الاحتياطية تالف أو تم تغييره.';

  @override
  String get backupImportTooLarge => 'هذه النسخة أكبر من أن تُستعاد.';

  @override
  String get backupImportStorage => 'لا توجد مساحة كافية لاستعادة هذه النسخة.';

  @override
  String get backupImportFailed => 'لم تكتمل الاستعادة.';

  @override
  String get backupImportUnchanged => 'لم يتغير شيء على هذا الجهاز.';
}
