import 'package:flutter/foundation.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';
import 'package:the_registry/l10n/app_localizations.dart';

enum DocumentFormMode { create, edit }

class AddDocumentController extends ChangeNotifier {
  DocumentFormMode mode = DocumentFormMode.create;
  String? existingId;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<RenewalHistoryEntry> renewalHistory = const [];

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
  _FormSnapshot? _baseline;

  bool get isEditing => mode == DocumentFormMode.edit;

  bool get hasAttachment =>
      attachmentBytes != null && attachmentBytes!.isNotEmpty;

  bool get hasAdditionalDetails {
    return issuingAuthority.trim().isNotEmpty ||
        costOfLapsing.trim().isNotEmpty ||
        dependency.trim().isNotEmpty ||
        expectedChanges.trim().isNotEmpty ||
        notes.trim().isNotEmpty;
  }

  bool get isDirty {
    final current = _snapshot();
    if (_baseline != null) {
      return current != _baseline;
    }
    return current != const _FormSnapshot();
  }

  void loadDocument(RegistryDocument document) {
    mode = DocumentFormMode.edit;
    existingId = document.id;
    createdAt = document.createdAt;
    updatedAt = document.updatedAt;
    renewalHistory = List<RenewalHistoryEntry>.unmodifiable(
      document.renewalHistory,
    );
    name = document.name;
    category = document.category;
    ownerName = document.ownerName ?? '';
    issuingAuthority = document.issuingAuthority ?? '';
    documentNumber = document.documentNumber ?? '';
    issueDate = document.issueDate;
    expiryDate = document.expiryDate;
    actionDate = document.actionDate;
    impact = document.impact;
    renewalEffort = document.renewalEffort;
    costOfLapsing = document.costOfLapsing ?? '';
    dependency = document.dependency ?? '';
    expectedChanges = document.expectedChanges ?? '';
    notes = document.notes ?? '';
    reminders = Set<ReminderPreference>.from(document.reminders);
    attachmentBytes = document.attachmentBytes;
    _baseline = _snapshot();
    notifyListeners();
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
    final now = DateTime.now();
    if (isEditing) {
      return RegistryDocument(
        id: existingId!,
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
        createdAt: createdAt ?? now,
        updatedAt: now,
        renewalHistory: renewalHistory,
      );
    }
    return RegistryDocument(
      id: 'doc_${now.microsecondsSinceEpoch}',
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
      createdAt: now,
    );
  }

  Future<bool> submit({
    required AppLocalizations l10n,
    required Future<void> Function(RegistryDocument document) save,
    Future<bool> Function(RegistryDocument document)? update,
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
      final document = toDocument();
      if (isEditing) {
        return await (update ?? _unsupportedUpdate)(document);
      }
      await save(document);
      return true;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> _unsupportedUpdate(RegistryDocument document) async {
    return false;
  }

  _FormSnapshot _snapshot() {
    return _FormSnapshot(
      name: name,
      category: category,
      ownerName: ownerName,
      issuingAuthority: issuingAuthority,
      documentNumber: documentNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      actionDate: actionDate,
      impact: impact,
      renewalEffort: renewalEffort,
      costOfLapsing: costOfLapsing,
      dependency: dependency,
      expectedChanges: expectedChanges,
      notes: notes,
      reminders: reminders,
      attachmentBytes: attachmentBytes,
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _FormSnapshot {
  const _FormSnapshot({
    this.name = '',
    this.category,
    this.ownerName = '',
    this.issuingAuthority = '',
    this.documentNumber = '',
    this.issueDate,
    this.expiryDate,
    this.actionDate,
    this.impact,
    this.renewalEffort,
    this.costOfLapsing = '',
    this.dependency = '',
    this.expectedChanges = '',
    this.notes = '',
    this.reminders = const {},
    this.attachmentBytes,
  });

  final String name;
  final DocumentCategory? category;
  final String ownerName;
  final String issuingAuthority;
  final String documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final DateTime? actionDate;
  final DocumentImpact? impact;
  final RenewalEffort? renewalEffort;
  final String costOfLapsing;
  final String dependency;
  final String expectedChanges;
  final String notes;
  final Set<ReminderPreference> reminders;
  final Uint8List? attachmentBytes;

  @override
  bool operator ==(Object other) {
    return other is _FormSnapshot &&
        other.name.trim() == name.trim() &&
        other.category == category &&
        other.ownerName.trim() == ownerName.trim() &&
        other.issuingAuthority.trim() == issuingAuthority.trim() &&
        other.documentNumber.trim() == documentNumber.trim() &&
        other.issueDate == issueDate &&
        other.expiryDate == expiryDate &&
        other.actionDate == actionDate &&
        other.impact == impact &&
        other.renewalEffort == renewalEffort &&
        other.costOfLapsing.trim() == costOfLapsing.trim() &&
        other.dependency.trim() == dependency.trim() &&
        other.expectedChanges.trim() == expectedChanges.trim() &&
        other.notes.trim() == notes.trim() &&
        setEquals(other.reminders, reminders) &&
        listEquals(other.attachmentBytes, attachmentBytes);
  }

  @override
  int get hashCode => Object.hash(
    name,
    category,
    ownerName,
    issuingAuthority,
    documentNumber,
    issueDate,
    expiryDate,
    actionDate,
    impact,
    renewalEffort,
    costOfLapsing,
    dependency,
    expectedChanges,
    notes,
    Object.hashAll(reminders),
    attachmentBytes == null ? 0 : Object.hashAll(attachmentBytes!),
  );
}
