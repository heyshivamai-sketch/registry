import 'package:flutter/foundation.dart';
import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_ocr_parser.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';
import 'package:the_registry/l10n/app_localizations.dart';

enum DocumentFormMode { create, edit }

enum AddDocumentStep { source, identity, dates, renewal, review }

enum OcrUiStatus { idle, processing, review, failed }

class AddDocumentController extends ChangeNotifier {
  static const schemaRegistry = DocumentSchemaRegistry();

  DocumentFormMode mode = DocumentFormMode.create;
  String? existingId;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<RenewalHistoryEntry> renewalHistory = const [];

  AddDocumentStep step = AddDocumentStep.source;
  String schemaId = DocumentSchemaIds.genericOther;
  String? countryCode;

  String name = '';
  DocumentCategory? category;
  String ownerName = '';
  String issuingAuthority = '';
  String documentNumber = '';
  bool obscureDocumentNumber = true;
  DateTime? issueDate;
  DateTime? expiryDate;
  DateTime? actionDate;
  bool actionDateUserSet = false;
  DocumentImpact? impact;
  RenewalEffort? renewalEffort;
  String costOfLapsing = '';
  String dependency = '';
  String expectedChanges = '';
  String notes = '';
  Set<ReminderPreference> reminders = {};
  Uint8List? attachmentBytes;
  List<DocumentFieldValue> dynamicFields = const [];
  bool additionalOpen = false;
  bool identityExtrasOpen = false;

  OcrUiStatus ocrStatus = OcrUiStatus.idle;
  DocumentOcrResult? ocrResult;
  List<ExtractedDocumentField> ocrFields = const [];
  int _ocrGeneration = 0;
  bool ocrConfirmed = false;

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

  bool get hasIdentityExtras {
    return issuingAuthority.trim().isNotEmpty ||
        documentNumber.trim().isNotEmpty ||
        optionalDynamicFields.any((field) => !field.isEmpty);
  }

  List<DocumentFieldValue> get requiredDynamicFields => [
    for (final field in dynamicFields)
      if (_isRequiredDynamic(field)) field,
  ];

  List<DocumentFieldValue> get optionalDynamicFields => [
    for (final field in dynamicFields)
      if (!_isRequiredDynamic(field)) field,
  ];

  bool _isRequiredDynamic(DocumentFieldValue field) {
    if (field.isCustom) {
      return false;
    }
    final spec = schema.fieldById(field.fieldKey);
    if (spec == null) {
      return false;
    }
    return spec.required || !spec.optional;
  }

  bool get hasAdditionalDetails {
    return costOfLapsing.trim().isNotEmpty ||
        dependency.trim().isNotEmpty ||
        expectedChanges.trim().isNotEmpty ||
        notes.trim().isNotEmpty;
  }

  int get stepIndex => AddDocumentStep.values.indexOf(step);

  int get stepCount => AddDocumentStep.values.length;

  DocumentSchema get schema => schemaRegistry.byId(schemaId);

  DateTime? get suggestedActionDate {
    if (expiryDate == null) {
      return null;
    }
    return expiryDate!.subtract(const Duration(days: 30));
  }

  List<DynamicDocumentField> get unboundSchemaFields => [
    for (final field in schema.orderedFields)
      if (field.binding == DocumentBaseBinding.none) field,
  ];

  bool get isDirty {
    final current = _snapshot();
    if (_baseline != null) {
      return current != _baseline;
    }
    return current != const _FormSnapshot();
  }

  bool get canGoBack =>
      ocrStatus != OcrUiStatus.processing &&
      (step != AddDocumentStep.source || ocrStatus == OcrUiStatus.review);

  void loadDocument(RegistryDocument document) {
    mode = DocumentFormMode.edit;
    existingId = document.id;
    createdAt = document.createdAt;
    updatedAt = document.updatedAt;
    renewalHistory = List<RenewalHistoryEntry>.unmodifiable(
      document.renewalHistory,
    );
    schemaId = document.schemaId;
    countryCode = document.countryCode;
    name = document.name;
    category = document.category;
    ownerName = document.ownerName ?? '';
    issuingAuthority = document.issuingAuthority ?? '';
    documentNumber = document.documentNumber ?? '';
    issueDate = document.issueDate;
    expiryDate = document.expiryDate;
    actionDate = document.actionDate;
    actionDateUserSet = document.actionDate != null;
    impact = document.impact;
    renewalEffort = document.renewalEffort;
    costOfLapsing = document.costOfLapsing ?? '';
    dependency = document.dependency ?? '';
    expectedChanges = document.expectedChanges ?? '';
    notes = document.notes ?? '';
    reminders = Set<ReminderPreference>.from(document.reminders);
    attachmentBytes = document.attachmentBytes;
    dynamicFields = List<DocumentFieldValue>.unmodifiable(
      document.dynamicFields,
    );
    additionalOpen = hasAdditionalDetails;
    identityExtrasOpen = hasIdentityExtras;
    step = AddDocumentStep.source;
    ocrStatus = OcrUiStatus.idle;
    ocrConfirmed = false;
    _baseline = _snapshot();
    notifyListeners();
  }

  void goToStep(AddDocumentStep value) {
    step = value;
    notifyListeners();
  }

  bool continueStep(AppLocalizations l10n) {
    if (!validateCurrentStep(l10n)) {
      return false;
    }
    if (stepIndex >= stepCount - 1) {
      return true;
    }
    step = AddDocumentStep.values[stepIndex + 1];
    if (step == AddDocumentStep.identity) {
      upsertUnboundSchemaValues();
    }
    notifyListeners();
    return true;
  }

  void backStep() {
    if (ocrStatus == OcrUiStatus.review) {
      closeOcrReview();
      return;
    }
    if (stepIndex == 0) {
      return;
    }
    step = AddDocumentStep.values[stepIndex - 1];
    notifyListeners();
  }

  bool validateCurrentStep(AppLocalizations l10n) {
    switch (step) {
      case AddDocumentStep.source:
        return true;
      case AddDocumentStep.identity:
        return _validateIdentity(l10n);
      case AddDocumentStep.dates:
        return _validateDates(l10n);
      case AddDocumentStep.renewal:
        return _validateRenewal(l10n);
      case AddDocumentStep.review:
        return validate(l10n);
    }
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setCategory(DocumentCategory? value) {
    category = value;
    final mapped = schemaIdFor(category, countryCode);
    if (mapped != schemaId) {
      setSchemaId(mapped);
      return;
    }
    notifyListeners();
  }

  void setCountryCode(String? value) {
    countryCode = value;
    final mapped = schemaIdFor(category, countryCode);
    if (mapped != schemaId) {
      setSchemaId(mapped);
      return;
    }
    notifyListeners();
  }

  static String schemaIdFor(DocumentCategory? category, String? country) {
    if (category == DocumentCategory.passport) {
      return DocumentSchemaIds.genericPassport;
    }
    if (category == DocumentCategory.idCard) {
      return switch (country) {
        DocumentCountryCodes.india => DocumentSchemaIds.indiaAadhaar,
        DocumentCountryCodes.france => DocumentSchemaIds.franceNationalId,
        DocumentCountryCodes.uae => DocumentSchemaIds.uaeEmiratesId,
        _ => DocumentSchemaIds.genericOther,
      };
    }
    return DocumentSchemaIds.genericOther;
  }

  bool wouldDiscardDynamicFields(String nextSchemaId) {
    if (nextSchemaId == schemaId) {
      return false;
    }
    final next = schemaRegistry.byId(nextSchemaId);
    return dynamicFields.any(
      (field) =>
          !field.isEmpty &&
          !field.isCustom &&
          !next.fieldIds.contains(field.fieldKey),
    );
  }

  void setSchemaId(String value, {bool discardIncompatible = false}) {
    if (value == schemaId) {
      return;
    }
    final next = schemaRegistry.byId(value);
    schemaId = next.id;
    category = next.id == DocumentSchemaIds.genericOther
        ? (category ?? DocumentCategory.other)
        : next.category;
    countryCode ??= next.countryCode;
    if (next.countryCode != DocumentCountryCodes.other) {
      countryCode = next.countryCode;
    }
    dynamicFields = [
      for (final field in dynamicFields)
        if (field.isCustom || next.fieldIds.contains(field.fieldKey)) field,
    ];
    if (discardIncompatible) {
      dynamicFields = [
        for (final field in dynamicFields)
          if (field.isCustom || next.fieldIds.contains(field.fieldKey)) field,
      ];
    }
    notifyListeners();
  }

  void assignCategory(DocumentCategory value) {
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

  void setActionDate(DateTime? value, {bool fromSuggestion = false}) {
    actionDate = value;
    if (!fromSuggestion) {
      actionDateUserSet = value != null;
    }
    notifyListeners();
  }

  void applySuggestedActionDate() {
    actionDate = suggestedActionDate;
    actionDateUserSet = true;
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
    if (bytes == null) {
      ocrStatus = OcrUiStatus.idle;
      ocrResult = null;
    }
    notifyListeners();
  }

  void setDynamicFieldValue(String id, String value) {
    dynamicFields = [
      for (final field in dynamicFields)
        if (field.id == id) field.copyWith(value: value) else field,
    ];
    notifyListeners();
  }

  void setDynamicFieldLabel(String id, String label) {
    dynamicFields = [
      for (final field in dynamicFields)
        if (field.id == id) field.copyWith(customLabel: label) else field,
    ];
    notifyListeners();
  }

  void toggleDynamicFieldSensitive(String id) {
    dynamicFields = [
      for (final field in dynamicFields)
        if (field.id == id)
          field.copyWith(sensitive: !field.sensitive)
        else
          field,
    ];
    notifyListeners();
  }

  void addCustomField({String label = '', String value = ''}) {
    final field = DocumentFieldValue(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      fieldKey: 'custom',
      customLabel: label,
      value: value,
      isCustom: true,
    );
    dynamicFields = [...dynamicFields, field];
    identityExtrasOpen = true;
    notifyListeners();
  }

  void removeDynamicField(String id) {
    dynamicFields = [
      for (final field in dynamicFields)
        if (field.id != id) field,
    ];
    notifyListeners();
  }

  void upsertUnboundSchemaValues() {
    final existing = {for (final field in dynamicFields) field.fieldKey};
    final additions = <DocumentFieldValue>[
      for (final field in unboundSchemaFields)
        if (!existing.contains(field.id))
          DocumentFieldValue(
            id: field.id,
            fieldKey: field.id,
            sensitive: field.sensitive,
            isDate: field.isDate,
            value: '',
          ),
    ];
    if (additions.isEmpty) {
      return;
    }
    dynamicFields = [...dynamicFields, ...additions];
    notifyListeners();
  }

  Future<void> recognizeAttachment(DocumentOcrService ocr) async {
    if (!hasAttachment) {
      return;
    }
    final generation = ++_ocrGeneration;
    ocrStatus = OcrUiStatus.processing;
    ocrResult = null;
    notifyListeners();
    try {
      final result = await ocr.recognize(attachmentBytes!);
      if (generation != _ocrGeneration) {
        return;
      }
      if (result.status == OcrRecognitionStatus.cancelled) {
        ocrStatus = OcrUiStatus.idle;
        ocrResult = null;
        notifyListeners();
        return;
      }
      if (result.status == OcrRecognitionStatus.failed) {
        ocrStatus = OcrUiStatus.failed;
        ocrResult = result;
        notifyListeners();
        return;
      }
      ocrResult = result;
      ocrFields = List<ExtractedDocumentField>.from(result.fields);
      ocrStatus = OcrUiStatus.review;
      notifyListeners();
    } catch (_) {
      if (generation != _ocrGeneration) {
        return;
      }
      ocrStatus = OcrUiStatus.failed;
      ocrResult = const DocumentOcrResult.failed();
      notifyListeners();
    }
  }

  void cancelOcr() {
    _ocrGeneration++;
    ocrStatus = OcrUiStatus.idle;
    ocrResult = null;
    notifyListeners();
  }

  void closeOcrReview() {
    ocrStatus = OcrUiStatus.idle;
    notifyListeners();
  }

  void retryOcr(DocumentOcrService ocr) {
    recognizeAttachment(ocr);
  }

  void toggleAdditional() {
    additionalOpen = !additionalOpen;
    notifyListeners();
  }

  void toggleIdentityExtras() {
    identityExtrasOpen = !identityExtrasOpen;
    notifyListeners();
  }

  void setOcrCountry(String countryCode) {
    final schemas = schemaRegistry.byCountry(countryCode);
    final preferred = schemas.first.id;
    changeOcrSchema(preferred);
    final current = ocrResult;
    if (current != null) {
      ocrResult = current.copyWith(
        classification: current.classification.copyWith(
          countryCode: countryCode,
        ),
      );
      notifyListeners();
    }
  }

  void setOcrFieldValue(String id, String value) {
    ocrFields = [
      for (final field in ocrFields)
        if (field.id == id)
          field.copyWith(
            value: value,
            confidence: value.trim().isEmpty
                ? OcrConfidence.notDetected
                : OcrConfidence.review,
          )
        else
          field,
    ];
    notifyListeners();
  }

  void clearOcrField(String id) {
    setOcrFieldValue(id, '');
  }

  void removeOcrField(String id) {
    ocrFields = [
      for (final field in ocrFields)
        if (field.id != id) field,
    ];
    notifyListeners();
  }

  void addOcrCustomField({String label = '', String value = ''}) {
    ocrFields = [
      ...ocrFields,
      ExtractedDocumentField(
        id: 'ocr_custom_${DateTime.now().microsecondsSinceEpoch}',
        fieldKey: 'custom',
        customLabel: label,
        value: value,
        confidence: OcrConfidence.review,
        isCustom: true,
        removable: true,
      ),
    ];
    notifyListeners();
  }

  void changeOcrSchema(String nextSchemaId) {
    final schema = schemaRegistry.byId(nextSchemaId);
    final remapped = DocumentOcrParser.remap(
      current: ocrResult ?? const DocumentOcrResult.failed(),
      schema: schema,
      confirmedFields: ocrFields,
    );
    ocrResult = remapped;
    ocrFields = List<ExtractedDocumentField>.from(remapped.fields);
    notifyListeners();
  }

  void confirmOcr() {
    final result = ocrResult;
    if (result == null) {
      return;
    }
    final schema = schemaRegistry.byId(result.classification.schemaId);
    schemaId = schema.id;
    countryCode = result.classification.countryCode;
    category = schema.category;
    final nextDynamic = <DocumentFieldValue>[];
    for (final field in ocrFields) {
      final definition = schema.fieldById(field.fieldKey);
      final binding = definition?.binding ?? DocumentBaseBinding.none;
      final value = field.value.trim();
      switch (binding) {
        case DocumentBaseBinding.title:
          if (value.isNotEmpty) {
            name = value;
          }
        case DocumentBaseBinding.owner:
          if (value.isNotEmpty) {
            ownerName = value;
          }
        case DocumentBaseBinding.issuer:
          if (value.isNotEmpty) {
            issuingAuthority = value;
          }
        case DocumentBaseBinding.number:
          if (value.isNotEmpty) {
            documentNumber = value;
          }
        case DocumentBaseBinding.issueDate:
          issueDate = _tryParseDate(value) ?? issueDate;
        case DocumentBaseBinding.expiryDate:
          expiryDate = _tryParseDate(value) ?? expiryDate;
        case DocumentBaseBinding.none:
          nextDynamic.add(
            DocumentFieldValue(
              id: field.id,
              fieldKey: field.fieldKey,
              customLabel: field.customLabel,
              value: field.value,
              sensitive: field.sensitive,
              isDate: field.isDate,
              isCustom: field.isCustom,
            ),
          );
      }
    }
    dynamicFields = nextDynamic;
    if (name.trim().isEmpty && ownerName.trim().isNotEmpty) {
      name = ownerName;
    }
    ocrConfirmed = true;
    ocrStatus = OcrUiStatus.idle;
    step = AddDocumentStep.identity;
    identityExtrasOpen = hasIdentityExtras;
    notifyListeners();
  }

  DateTime? _tryParseDate(String raw) => tryParseLooseDate(raw);

  /// Parses ISO dates, numeric dates, and day-month-year text.
  static DateTime? tryParseLooseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final iso = DateTime.tryParse(value);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }
    final match = RegExp(
      r'^(\d{1,2})[./\-\s](\d{1,2}|\p{L}{2,})[./\-\s](\d{2,4})$',
      unicode: true,
    ).firstMatch(value);
    if (match == null) {
      if (RegExp(r'^(19|20)\d{2}$').hasMatch(value)) {
        return DateTime(int.parse(value), 1, 1);
      }
      return null;
    }
    final day = int.tryParse(match.group(1)!);
    final yearRaw = int.tryParse(match.group(3)!);
    if (day == null || yearRaw == null) {
      return null;
    }
    final year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
    final monthToken = match.group(2)!;
    final month = int.tryParse(monthToken) ?? _monthFromName(monthToken);
    if (month == null || day < 1 || day > 31) {
      return null;
    }
    return DateTime(year, month, day);
  }

  static int? _monthFromName(String token) {
    final folded = token
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('û', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c');
    const months = {
      'jan': 1,
      'janv': 1,
      'january': 1,
      'janvier': 1,
      'يناير': 1,
      'feb': 2,
      'fev': 2,
      'fevr': 2,
      'february': 2,
      'fevrier': 2,
      'فبراير': 2,
      'mar': 3,
      'mars': 3,
      'march': 3,
      'مارس': 3,
      'apr': 4,
      'avr': 4,
      'avril': 4,
      'april': 4,
      'أبريل': 4,
      'ابريل': 4,
      'may': 5,
      'mai': 5,
      'مايو': 5,
      'jun': 6,
      'juin': 6,
      'june': 6,
      'يونيو': 6,
      'jul': 7,
      'juil': 7,
      'juillet': 7,
      'july': 7,
      'يوليو': 7,
      'aug': 8,
      'aou': 8,
      'aout': 8,
      'august': 8,
      'أغسطس': 8,
      'اغسطس': 8,
      'sep': 9,
      'sept': 9,
      'septembre': 9,
      'september': 9,
      'سبتمبر': 9,
      'oct': 10,
      'octobre': 10,
      'october': 10,
      'أكتوبر': 10,
      'اكتوبر': 10,
      'nov': 11,
      'novembre': 11,
      'november': 11,
      'نوفمبر': 11,
      'dec': 12,
      'decembre': 12,
      'december': 12,
      'ديسمبر': 12,
    };
    return months[folded] ?? months[token];
  }

  bool _validateIdentity(AppLocalizations l10n) {
    nameError = name.trim().isEmpty ? l10n.errorRequired : null;
    categoryError = category == null ? l10n.errorRequired : null;
    notifyListeners();
    return nameError == null && categoryError == null;
  }

  bool _validateDates(AppLocalizations l10n) {
    expiryError = expiryDate == null ? l10n.errorRequired : null;
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
    return expiryError == null &&
        issueDateError == null &&
        actionDateError == null;
  }

  bool _validateRenewal(AppLocalizations l10n) {
    impactError = impact == null ? l10n.errorRequired : null;
    notifyListeners();
    return impactError == null;
  }

  bool validate(AppLocalizations l10n) {
    _validateIdentity(l10n);
    _validateDates(l10n);
    _validateRenewal(l10n);
    return nameError == null &&
        categoryError == null &&
        expiryError == null &&
        impactError == null &&
        issueDateError == null &&
        actionDateError == null;
  }

  RegistryDocument toDocument() {
    final now = DateTime.now();
    final storedFields = [
      for (final field in dynamicFields)
        if (!field.isEmpty) field,
    ];
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
        schemaId: schemaId,
        countryCode: countryCode,
        dynamicFields: storedFields,
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
      schemaId: schemaId,
      countryCode: countryCode,
      dynamicFields: storedFields,
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
      if (nameError != null || categoryError != null) {
        step = AddDocumentStep.identity;
      } else if (expiryError != null ||
          issueDateError != null ||
          actionDateError != null) {
        step = AddDocumentStep.dates;
      } else if (impactError != null) {
        step = AddDocumentStep.renewal;
      }
      notifyListeners();
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
      schemaId: schemaId,
      countryCode: countryCode,
      dynamicFields: dynamicFields,
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
    this.schemaId = DocumentSchemaIds.genericOther,
    this.countryCode,
    this.dynamicFields = const [],
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
  final String schemaId;
  final String? countryCode;
  final List<DocumentFieldValue> dynamicFields;

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
        listEquals(other.attachmentBytes, attachmentBytes) &&
        other.schemaId == schemaId &&
        other.countryCode == countryCode &&
        listEquals(other.dynamicFields, dynamicFields);
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
    schemaId,
    countryCode,
    Object.hashAll(dynamicFields),
  );
}
