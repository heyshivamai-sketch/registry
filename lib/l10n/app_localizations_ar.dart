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
}
