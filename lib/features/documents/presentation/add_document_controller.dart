import 'package:flutter/foundation.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class AddDocumentController extends ChangeNotifier {
  String name = '';
  DocumentCategory? category;
  String ownerName = '';
  String issuingAuthority = '';
  String documentNumber = '';
  bool obscureDocumentNumber = true;
  DateTime? issueDate;
  DateTime? expiryDate;
  DateTime? actionDate;
  DocumentImpact? impact;
  RenewalEffort? renewalEffort;
  String costOfLapsing = '';
  String dependency = '';
  String expectedChanges = '';
  String notes = '';
  Set<ReminderPreference> reminders = {};
  Uint8List? attachmentBytes;

  String? nameError;
  String? categoryError;
  String? expiryError;
  String? issueDateError;
  String? actionDateError;
  String? impactError;

  bool saving = false;

  bool get hasAttachment =>
      attachmentBytes != null && attachmentBytes!.isNotEmpty;

  bool get isDirty {
    return name.trim().isNotEmpty ||
        category != null ||
        ownerName.trim().isNotEmpty ||
        issuingAuthority.trim().isNotEmpty ||
        documentNumber.trim().isNotEmpty ||
        issueDate != null ||
        expiryDate != null ||
        actionDate != null ||
        impact != null ||
        renewalEffort != null ||
        costOfLapsing.trim().isNotEmpty ||
        dependency.trim().isNotEmpty ||
        expectedChanges.trim().isNotEmpty ||
        notes.trim().isNotEmpty ||
        reminders.isNotEmpty ||
        hasAttachment;
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setCategory(DocumentCategory? value) {
    category = value;
    notifyListeners();
  }

  void setOwnerName(String value) {
    ownerName = value;
    notifyListeners();
  }

  void setIssuingAuthority(String value) {
    issuingAuthority = value;
    notifyListeners();
  }

  void setDocumentNumber(String value) {
    documentNumber = value;
    notifyListeners();
  }

  void toggleDocumentNumberVisibility() {
    obscureDocumentNumber = !obscureDocumentNumber;
    notifyListeners();
  }

  void setIssueDate(DateTime? value) {
    issueDate = value;
    notifyListeners();
  }

  void setExpiryDate(DateTime? value) {
    expiryDate = value;
    notifyListeners();
  }

  void setActionDate(DateTime? value) {
    actionDate = value;
    notifyListeners();
  }

  void setImpact(DocumentImpact? value) {
    impact = value;
    notifyListeners();
  }

  void setRenewalEffort(RenewalEffort? value) {
    renewalEffort = value;
    notifyListeners();
  }

  void setCostOfLapsing(String value) {
    costOfLapsing = value;
    notifyListeners();
  }

  void setDependency(String value) {
    dependency = value;
    notifyListeners();
  }

  void setExpectedChanges(String value) {
    expectedChanges = value;
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value;
    notifyListeners();
  }

  void toggleReminder(ReminderPreference preference) {
    if (reminders.contains(preference)) {
      reminders = {...reminders}..remove(preference);
    } else {
      reminders = {...reminders, preference};
    }
    notifyListeners();
  }

  void setAttachment(Uint8List? bytes) {
    attachmentBytes = bytes;
    notifyListeners();
  }

  bool validate(AppLocalizations l10n) {
    nameError = name.trim().isEmpty ? l10n.errorRequired : null;
    categoryError = category == null ? l10n.errorRequired : null;
    expiryError = expiryDate == null ? l10n.errorRequired : null;
    impactError = impact == null ? l10n.errorRequired : null;

    issueDateError = null;
    actionDateError = null;
    if (issueDate != null &&
        expiryDate != null &&
        _dateOnly(issueDate!).isAfter(_dateOnly(expiryDate!))) {
      issueDateError = l10n.errorIssueAfterExpiry;
    }
    if (actionDate != null &&
        expiryDate != null &&
        _dateOnly(actionDate!).isAfter(_dateOnly(expiryDate!))) {
      actionDateError = l10n.errorActionAfterExpiry;
    }

    notifyListeners();
    return nameError == null &&
        categoryError == null &&
        expiryError == null &&
        impactError == null &&
        issueDateError == null &&
        actionDateError == null;
  }

  RegistryDocument toDocument() {
    return RegistryDocument(
      id: 'doc_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      category: category!,
      ownerName: _optional(ownerName),
      issuingAuthority: _optional(issuingAuthority),
      documentNumber: _optional(documentNumber),
      issueDate: issueDate,
      expiryDate: expiryDate!,
      actionDate: actionDate,
      impact: impact!,
      renewalEffort: renewalEffort,
      costOfLapsing: _optional(costOfLapsing),
      dependency: _optional(dependency),
      expectedChanges: _optional(expectedChanges),
      notes: _optional(notes),
      reminders: Set<ReminderPreference>.from(reminders),
      attachmentBytes: attachmentBytes,
      createdAt: DateTime.now(),
    );
  }

  Future<bool> submit({
    required AppLocalizations l10n,
    required Future<void> Function(RegistryDocument document) save,
  }) async {
    if (saving) {
      return false;
    }
    if (!validate(l10n)) {
      return false;
    }
    saving = true;
    notifyListeners();
    try {
      await save(toDocument());
      return true;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
