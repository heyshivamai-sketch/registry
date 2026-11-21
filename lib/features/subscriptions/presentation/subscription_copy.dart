import 'package:flutter/material.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class SubscriptionCopy {
  static String category(AppLocalizations l10n, SubscriptionCategory category) {
    return switch (category) {
      SubscriptionCategory.aiServices => 'AI services',
      SubscriptionCategory.business => 'Business',
      SubscriptionCategory.cloudStorage => 'Cloud storage',
      SubscriptionCategory.communication => 'Communication',
      SubscriptionCategory.development => 'Development',
      SubscriptionCategory.donations => 'Donations',
      SubscriptionCategory.education => l10n.subscriptionCategoryEducation,
      SubscriptionCategory.entertainment =>
        l10n.subscriptionCategoryEntertainment,
      SubscriptionCategory.fashionBeauty => 'Fashion & beauty',
      SubscriptionCategory.finance => l10n.subscriptionCategoryFinance,
      SubscriptionCategory.fitness => 'Fitness',
      SubscriptionCategory.food => 'Food',
      SubscriptionCategory.healthFitness => l10n.subscriptionCategoryHealth,
      SubscriptionCategory.productivity =>
        l10n.subscriptionCategoryProductivity,
      SubscriptionCategory.security => 'Security',
      SubscriptionCategory.shopping => 'Shopping',
      SubscriptionCategory.socialMedia => 'Social media',
      SubscriptionCategory.software => 'Software',
      SubscriptionCategory.sport => 'Sport',
      SubscriptionCategory.tools => 'Tools',
      SubscriptionCategory.transportation => 'Transportation',
      SubscriptionCategory.travel => 'Travel',
      SubscriptionCategory.utilities => l10n.subscriptionCategoryUtilities,
      SubscriptionCategory.videoTv => 'Video & TV',
      SubscriptionCategory.other => l10n.subscriptionCategoryOther,
    };
  }

  static String cycle(AppLocalizations l10n, BillingCycle cycle) {
    return switch (cycle) {
      BillingCycle.weekly => l10n.billingWeekly,
      BillingCycle.monthly => l10n.billingMonthly,
      BillingCycle.quarterly => l10n.billingQuarterly,
      BillingCycle.yearly => l10n.billingYearly,
    };
  }

  static String cycleSuffix(AppLocalizations l10n, BillingCycle cycle) {
    return switch (cycle) {
      BillingCycle.weekly => l10n.billingPerWeek,
      BillingCycle.monthly => l10n.billingPerMonth,
      BillingCycle.quarterly => l10n.billingPerQuarter,
      BillingCycle.yearly => l10n.billingPerYear,
    };
  }

  static String reminder(AppLocalizations l10n, SubscriptionReminder reminder) {
    return switch (reminder) {
      SubscriptionReminder.sevenDaysBefore => l10n.subscriptionReminder7Days,
      SubscriptionReminder.oneDayBefore => l10n.subscriptionReminder1Day,
      SubscriptionReminder.onChargeDay => l10n.subscriptionReminderOnCharge,
    };
  }

  static String impact(AppLocalizations l10n, DocumentImpact impact) {
    return switch (impact) {
      DocumentImpact.low => l10n.impactLow,
      DocumentImpact.medium => l10n.impactMedium,
      DocumentImpact.high => l10n.impactHigh,
      DocumentImpact.critical => l10n.impactCritical,
    };
  }

  static IconData iconFor(SubscriptionCategory category) {
    return switch (category) {
      SubscriptionCategory.aiServices => Icons.auto_awesome_outlined,
      SubscriptionCategory.business => Icons.business_center_outlined,
      SubscriptionCategory.cloudStorage => Icons.cloud_outlined,
      SubscriptionCategory.communication => Icons.chat_bubble_outline,
      SubscriptionCategory.development => Icons.code_outlined,
      SubscriptionCategory.donations => Icons.volunteer_activism_outlined,
      SubscriptionCategory.education => Icons.school_outlined,
      SubscriptionCategory.entertainment => Icons.subscriptions_outlined,
      SubscriptionCategory.fashionBeauty => Icons.checkroom_outlined,
      SubscriptionCategory.finance => Icons.account_balance_outlined,
      SubscriptionCategory.fitness => Icons.fitness_center_outlined,
      SubscriptionCategory.food => Icons.restaurant_outlined,
      SubscriptionCategory.healthFitness => Icons.fitness_center_outlined,
      SubscriptionCategory.productivity => Icons.work_outline,
      SubscriptionCategory.security => Icons.security_outlined,
      SubscriptionCategory.shopping => Icons.shopping_bag_outlined,
      SubscriptionCategory.socialMedia => Icons.share_outlined,
      SubscriptionCategory.software => Icons.apps_outlined,
      SubscriptionCategory.sport => Icons.sports_soccer_outlined,
      SubscriptionCategory.tools => Icons.build_outlined,
      SubscriptionCategory.transportation => Icons.directions_car_outlined,
      SubscriptionCategory.travel => Icons.flight_outlined,
      SubscriptionCategory.utilities => Icons.bolt_outlined,
      SubscriptionCategory.videoTv => Icons.tv_outlined,
      SubscriptionCategory.other => Icons.payments_outlined,
    };
  }
}
