import 'dart:typed_data';

import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';

enum DocumentCategory {
  passport,
  idCard,
  drivingLicence,
  insurance,
  visaResidence,
  certificate,
  warranty,
  other,
}

enum DocumentImpact { low, medium, high, critical }

enum RenewalEffort { easy, moderate, difficult }

enum ReminderPreference { onActionDate, sevenDaysBefore, thirtyDaysBefore }

class RegistryDocument {
  const RegistryDocument({
    required this.id,
    required this.name,
    required this.category,
    required this.expiryDate,
    required this.impact,
    required this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.issuingAuthority,
    this.documentNumber,
    this.issueDate,
    this.actionDate,
    this.renewalEffort,
    this.costOfLapsing,
    this.dependency,
    this.expectedChanges,
    this.notes,
    this.reminders = const {},
    this.attachmentBytes,
    this.renewalHistory = const [],
    this.schemaId = DocumentSchemaIds.genericOther,
    this.countryCode,
    this.dynamicFields = const [],
  });

  static const Object _unset = Object();

  final String id;
  final String name;
  final DocumentCategory category;
  final String? ownerName;
  final String? issuingAuthority;
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime expiryDate;
  final DateTime? actionDate;
  final DocumentImpact impact;
  final RenewalEffort? renewalEffort;
  final String? costOfLapsing;
  final String? dependency;
  final String? expectedChanges;
  final String? notes;
  final Set<ReminderPreference> reminders;
  final Uint8List? attachmentBytes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<RenewalHistoryEntry> renewalHistory;
  final String schemaId;
  final String? countryCode;
  final List<DocumentFieldValue> dynamicFields;

  List<DocumentFieldValue> get visibleDynamicFields => [
    for (final field in dynamicFields)
      if (!field.isEmpty) field,
  ];

  DateTime get displayActionDate => actionDate ?? expiryDate;

  bool get hasDistinctActionDate {
    if (actionDate == null) {
      return false;
    }
    final action = DateTime(
      actionDate!.year,
      actionDate!.month,
      actionDate!.day,
    );
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return action != expiry;
  }

  bool get hasAttachment =>
      attachmentBytes != null && attachmentBytes!.isNotEmpty;

  String get maskedDocumentNumber {
    final value = documentNumber?.trim() ?? '';
    if (value.isEmpty) {
      return '';
    }
    if (value.length <= 4) {
      return '•' * value.length;
    }
    return '${'•' * (value.length - 4)}${value.substring(value.length - 4)}';
  }

  RegistryDocument copyWith({
    String? id,
    String? name,
    DocumentCategory? category,
    Object? ownerName = _unset,
    Object? issuingAuthority = _unset,
    Object? documentNumber = _unset,
    Object? issueDate = _unset,
    DateTime? expiryDate,
    Object? actionDate = _unset,
    DocumentImpact? impact,
    Object? renewalEffort = _unset,
    Object? costOfLapsing = _unset,
    Object? dependency = _unset,
    Object? expectedChanges = _unset,
    Object? notes = _unset,
    Set<ReminderPreference>? reminders,
    Object? attachmentBytes = _unset,
    DateTime? createdAt,
    Object? updatedAt = _unset,
    List<RenewalHistoryEntry>? renewalHistory,
    String? schemaId,
    Object? countryCode = _unset,
    List<DocumentFieldValue>? dynamicFields,
  }) {
    return RegistryDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      ownerName: identical(ownerName, _unset)
          ? this.ownerName
          : ownerName as String?,
      issuingAuthority: identical(issuingAuthority, _unset)
          ? this.issuingAuthority
          : issuingAuthority as String?,
      documentNumber: identical(documentNumber, _unset)
          ? this.documentNumber
          : documentNumber as String?,
      issueDate: identical(issueDate, _unset)
          ? this.issueDate
          : issueDate as DateTime?,
      expiryDate: expiryDate ?? this.expiryDate,
      actionDate: identical(actionDate, _unset)
          ? this.actionDate
          : actionDate as DateTime?,
      impact: impact ?? this.impact,
      renewalEffort: identical(renewalEffort, _unset)
          ? this.renewalEffort
          : renewalEffort as RenewalEffort?,
      costOfLapsing: identical(costOfLapsing, _unset)
          ? this.costOfLapsing
          : costOfLapsing as String?,
      dependency: identical(dependency, _unset)
          ? this.dependency
          : dependency as String?,
      expectedChanges: identical(expectedChanges, _unset)
          ? this.expectedChanges
          : expectedChanges as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      reminders: reminders ?? this.reminders,
      attachmentBytes: identical(attachmentBytes, _unset)
          ? this.attachmentBytes
          : attachmentBytes as Uint8List?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
      renewalHistory: renewalHistory ?? this.renewalHistory,
      schemaId: schemaId ?? this.schemaId,
      countryCode: identical(countryCode, _unset)
          ? this.countryCode
          : countryCode as String?,
      dynamicFields: dynamicFields ?? this.dynamicFields,
    );
  }
}
