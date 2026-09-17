import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class DocumentCopy {
  static String category(AppLocalizations l10n, DocumentCategory category) {
    return switch (category) {
      DocumentCategory.passport => l10n.categoryPassport,
      DocumentCategory.idCard => l10n.categoryIdCard,
      DocumentCategory.drivingLicence => l10n.categoryDrivingLicence,
      DocumentCategory.insurance => l10n.categoryInsurance,
      DocumentCategory.visaResidence => l10n.categoryVisa,
      DocumentCategory.certificate => l10n.categoryCertificate,
      DocumentCategory.warranty => l10n.categoryWarranty,
      DocumentCategory.other => l10n.categoryOther,
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

  static String effort(AppLocalizations l10n, RenewalEffort effort) {
    return switch (effort) {
      RenewalEffort.easy => l10n.effortEasy,
      RenewalEffort.moderate => l10n.effortModerate,
      RenewalEffort.difficult => l10n.effortDifficult,
    };
  }
}
