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
  String get highImpactLabel => 'تأثير مرتفع';

  @override
  String get summaryDocuments => 'المستندات';

  @override
  String get summarySubscriptions => 'الاشتراكات';

  @override
  String get summaryNeedsAttention => 'يحتاج انتباهك';

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
}
