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
  String get homeGreeting => 'ابقَ سابقًا لما يهم';

  @override
  String get homeTitle => 'سجلك';

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
  String get oneDayRemaining => 'متبقٍ يوم واحد';

  @override
  String daysRemaining(int count) {
    return 'متبقٍ $count أيام';
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
  String get pulseEyebrow => 'الإجراء التالي';

  @override
  String get countdownDayUnit => 'يوم';

  @override
  String get countdownDaysUnit => 'أيام';

  @override
  String get countdownTodayUnit => 'اليوم';

  @override
  String get countdownOverdueUnit => 'متأخر';

  @override
  String get addSheetDocumentSubtitle => 'جوازات السفر والرخص والسجلات الأخرى.';

  @override
  String get addSheetSubscriptionSubtitle =>
      'الرسوم والعضويات التي تريد مراجعتها.';

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
  String get sectionComingUp => 'قادمًا';

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
  String get addSheetTitle => 'أضف إلى السجل';

  @override
  String get addSheetSubtitle => 'اختر ما تريد تتبّعه.';

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
}
