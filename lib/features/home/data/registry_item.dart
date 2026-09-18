import 'package:flutter/material.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

enum RegistryItemType { document, subscription }

enum RegistryImpact { high, medium, low }

class RegistryItem {
  const RegistryItem({
    required this.id,
    required this.type,
    required this.status,
    required this.impact,
    required this.impactScore,
    required this.actionDate,
    required this.dueDate,
    required this.isHero,
    required this.needsAttention,
  });

  final String id;
  final RegistryItemType type;
  final RegistryStatus status;
  final RegistryImpact impact;
  final int impactScore;
  final DateTime actionDate;
  final DateTime dueDate;
  final bool isHero;

  /// Catalog flag retained for callers. Home attention uses [requiresAttention].
  final bool needsAttention;

  /// Status-based attention: Action needed or Overdue only.
  bool get requiresAttention => DocumentStatus.isAttentionStatus(status);

  String title(AppLocalizations l10n) {
    return switch (id) {
      'car_insurance' => l10n.itemCarInsurance,
      'passport' => l10n.itemPassport,
      'streaming' => l10n.itemStreaming,
      'driving_licence' => l10n.itemDrivingLicence,
      'gym' => l10n.itemGym,
      _ => id,
    };
  }

  String heroTitle(AppLocalizations l10n) {
    return switch (id) {
      'car_insurance' => l10n.heroCarInsurance,
      _ => title(l10n),
    };
  }

  String actionLabel(AppLocalizations l10n) {
    return switch (id) {
      'car_insurance' => l10n.actionStartRenewalSoon,
      'passport' => l10n.actionUpcomingExpiry,
      'streaming' => l10n.actionDecideBeforeCharge,
      'driving_licence' => l10n.actionPrepareRenewal,
      'gym' => l10n.actionReviewMembership,
      _ => title(l10n),
    };
  }

  String typeLabel(AppLocalizations l10n) {
    return type == RegistryItemType.document
        ? l10n.typeDocument
        : l10n.typeSubscription;
  }

  String statusLabel(AppLocalizations l10n) {
    return DocumentStatus.label(l10n, status);
  }

  String impactLabel(AppLocalizations l10n) {
    return switch (impact) {
      RegistryImpact.high => l10n.highImpactLabel,
      RegistryImpact.medium => l10n.impactMedium,
      RegistryImpact.low => l10n.impactLow,
    };
  }

  String actionDateLabel(AppLocalizations l10n, String formattedDate) {
    return type == RegistryItemType.subscription
        ? l10n.decideByDate(formattedDate)
        : l10n.startByDate(formattedDate);
  }

  String dueDateLabel(AppLocalizations l10n, String formattedDate) {
    return type == RegistryItemType.subscription
        ? l10n.nextChargeDate(formattedDate)
        : l10n.expiresDate(formattedDate);
  }

  String remainingLabel(AppLocalizations l10n, {DateTime? now}) {
    final days = RegistryDateFormatter.daysUntil(actionDate, now: now);
    if (days == 0) {
      return l10n.dueToday;
    }
    if (days == 1) {
      return l10n.oneDayRemaining;
    }
    if (days > 1) {
      return l10n.daysRemaining(days);
    }
    if (days == -1) {
      return l10n.oneDayOverdue;
    }
    return l10n.daysOverdue(-days);
  }

  int remainingDays({DateTime? now}) {
    return RegistryDateFormatter.daysUntil(actionDate, now: now);
  }

  String countdownValueLabel({DateTime? now}) {
    final days = remainingDays(now: now);
    if (days == 0) {
      return '0';
    }
    return '${days.abs()}';
  }

  String countdownUnitLabel(AppLocalizations l10n, {DateTime? now}) {
    final days = remainingDays(now: now);
    if (days == 0) {
      return l10n.countdownTodayUnit;
    }
    if (days < 0) {
      return l10n.countdownOverdueUnit;
    }
    if (days.abs() == 1) {
      return l10n.countdownDayUnit;
    }
    return l10n.countdownDaysUnit;
  }

  IconData get icon {
    return switch (id) {
      'car_insurance' => Icons.directions_car_outlined,
      'passport' => Icons.badge_outlined,
      'streaming' => Icons.subscriptions_outlined,
      'driving_licence' => Icons.credit_card_outlined,
      'gym' => Icons.fitness_center_outlined,
      _ =>
        type == RegistryItemType.document
            ? Icons.description_outlined
            : Icons.subscriptions_outlined,
    };
  }
}
