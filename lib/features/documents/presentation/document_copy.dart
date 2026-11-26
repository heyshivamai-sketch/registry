import '../../../l10n/app_localizations.dart';
import '../domain/document_field_value.dart';
import '../domain/document_schema.dart';
import '../domain/registry_document.dart';
import '../domain/world_countries.dart';
import 'add_document_controller.dart';

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

  static String reminder(AppLocalizations l10n, ReminderPreference preference) {
    return switch (preference) {
      ReminderPreference.onActionDate => l10n.reminderOnActionDate,
      ReminderPreference.sevenDaysBefore => l10n.reminder7Days,
      ReminderPreference.thirtyDaysBefore => l10n.reminder30Days,
    };
  }

  static String country(AppLocalizations l10n, String? code) {
    return switch (code) {
      DocumentCountryCodes.generic => l10n.countryGeneric,
      DocumentCountryCodes.india => l10n.countryIndia,
      DocumentCountryCodes.france => l10n.countryFrance,
      DocumentCountryCodes.uae => l10n.countryUae,
      DocumentCountryCodes.other => l10n.countryOther,
      _ => WorldCountries.nameOf(code) ?? l10n.countryOther,
    };
  }

  static String schema(AppLocalizations l10n, String schemaId) {
    return switch (schemaId) {
      DocumentSchemaIds.genericPassport => l10n.schemaGenericPassport,
      DocumentSchemaIds.indiaAadhaar => l10n.schemaIndiaAadhaar,
      DocumentSchemaIds.franceNationalId => l10n.schemaFranceNationalId,
      DocumentSchemaIds.uaeEmiratesId => l10n.schemaUaeEmiratesId,
      _ => l10n.schemaGenericOther,
    };
  }

  static String fieldLabel(AppLocalizations l10n, DocumentFieldValue field) {
    if (field.isCustom) {
      final label = field.customLabel?.trim();
      return (label == null || label.isEmpty) ? l10n.customFieldValue : label;
    }
    return schemaFieldLabel(l10n, field.fieldKey);
  }

  static String schemaFieldLabel(AppLocalizations l10n, String fieldKey) {
    return switch (fieldKey) {
      DocumentFieldKeys.passportNumber => l10n.fieldPassportNumber,
      DocumentFieldKeys.fullName => l10n.fieldFullName,
      DocumentFieldKeys.nationality => l10n.fieldNationality,
      DocumentFieldKeys.dateOfBirth => l10n.fieldDateOfBirth,
      DocumentFieldKeys.issueDate => l10n.fieldIssueDate,
      DocumentFieldKeys.expiryDate => l10n.fieldExpiryDate,
      DocumentFieldKeys.issuingAuthority => l10n.fieldIssuingAuthority,
      DocumentFieldKeys.aadhaarNumber => l10n.fieldAadhaarNumber,
      DocumentFieldKeys.gender => l10n.fieldGender,
      DocumentFieldKeys.address => l10n.fieldAddress,
      DocumentFieldKeys.documentNumber => l10n.fieldDocumentNumber,
      DocumentFieldKeys.surname => l10n.fieldSurname,
      DocumentFieldKeys.givenNames => l10n.fieldGivenNames,
      DocumentFieldKeys.idNumber => l10n.fieldIdNumber,
      DocumentFieldKeys.name => l10n.fieldFullName,
      _ => l10n.customFieldValue,
    };
  }

  static String wizardStep(AppLocalizations l10n, AddDocumentStep step) {
    return switch (step) {
      AddDocumentStep.source => l10n.stepSourceTitle,
      AddDocumentStep.identity => l10n.stepIdentityTitle,
      AddDocumentStep.dates => l10n.stepDatesTitle,
      AddDocumentStep.renewal => l10n.stepRenewalTitle,
      AddDocumentStep.review => l10n.stepReviewTitle,
    };
  }
}
