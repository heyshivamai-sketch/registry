import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class DocumentStatus {
  static RegistryStatus resolve(RegistryDocument document, {DateTime? now}) {
    final expiryDays = RegistryDateFormatter.daysUntil(
      document.expiryDate,
      now: now,
    );
    if (expiryDays < 0) {
      return RegistryStatus.expired;
    }
    final actionDays = RegistryDateFormatter.daysUntil(
      document.displayActionDate,
      now: now,
    );
    if (actionDays <= 0) {
      return RegistryStatus.urgent;
    }
    if (actionDays <= AppSpacing.horizonDays) {
      return RegistryStatus.upcoming;
    }
    return RegistryStatus.active;
  }

  /// True when the derived status currently requires action or recovery.
  ///
  /// Upcoming is a coming-up horizon (Home's "Coming up"), not attention.
  /// Impact never contributes: it describes consequence if the document lapses.
  static bool needsAttention(RegistryDocument document, {DateTime? now}) {
    return isAttentionStatus(resolve(document, now: now));
  }

  static bool isAttentionStatus(RegistryStatus status) {
    return switch (status) {
      RegistryStatus.urgent || RegistryStatus.expired => true,
      RegistryStatus.upcoming ||
      RegistryStatus.active ||
      RegistryStatus.neutral => false,
    };
  }

  static int attentionCount(
    Iterable<RegistryDocument> documents, {
    DateTime? now,
  }) {
    return documents
        .where((document) => needsAttention(document, now: now))
        .length;
  }

  static String label(AppLocalizations l10n, RegistryStatus status) {
    return switch (status) {
      RegistryStatus.expired => l10n.statusOverdue,
      RegistryStatus.urgent => l10n.actionNeeded,
      RegistryStatus.upcoming => l10n.statusUpcoming,
      RegistryStatus.active => l10n.statusActive,
      RegistryStatus.neutral => l10n.statusNeutral,
    };
  }

  static String remainingLabel(
    AppLocalizations l10n,
    RegistryDocument document, {
    DateTime? now,
  }) {
    final status = resolve(document, now: now);
    final target = status == RegistryStatus.expired
        ? document.expiryDate
        : document.displayActionDate;
    final days = RegistryDateFormatter.daysUntil(target, now: now);
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
}
