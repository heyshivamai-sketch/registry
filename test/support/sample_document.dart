import 'dart:typed_data';

import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';

const Object _unset = Object();

RegistryDocument sampleDocument({
  String id = 'doc_1',
  String name = 'Family passport',
  DocumentCategory category = DocumentCategory.passport,
  String? ownerName = 'Amira',
  String? issuingAuthority = 'Algeria',
  String? documentNumber = 'AB12345678',
  Object? issueDate = _unset,
  DateTime? expiryDate,
  Object? actionDate = _unset,
  DocumentImpact impact = DocumentImpact.high,
  RenewalEffort? renewalEffort = RenewalEffort.moderate,
  String? costOfLapsing = 'Travel disruption',
  String? dependency = 'Family travel',
  String? expectedChanges = 'New photo',
  String? notes = 'Keep a copy',
  Set<ReminderPreference> reminders = const {
    ReminderPreference.sevenDaysBefore,
  },
  Uint8List? attachmentBytes,
  List<Uint8List> additionalImages = const [],
  DateTime? createdAt,
  DateTime? updatedAt,
  List<RenewalHistoryEntry> renewalHistory = const [],
  String schemaId = DocumentSchemaIds.genericOther,
  String? countryCode,
  List<DocumentFieldValue> dynamicFields = const [],
}) {
  return RegistryDocument(
    id: id,
    name: name,
    category: category,
    ownerName: ownerName,
    issuingAuthority: issuingAuthority,
    documentNumber: documentNumber,
    issueDate: identical(issueDate, _unset)
        ? DateTime(2026, 9, 17)
        : issueDate as DateTime?,
    expiryDate: expiryDate ?? DateTime(2027, 10, 5),
    actionDate: identical(actionDate, _unset)
        ? DateTime(2027, 9, 1)
        : actionDate as DateTime?,
    impact: impact,
    renewalEffort: renewalEffort,
    costOfLapsing: costOfLapsing,
    dependency: dependency,
    expectedChanges: expectedChanges,
    notes: notes,
    reminders: reminders,
    attachmentBytes: attachmentBytes,
    additionalImages: additionalImages,
    createdAt: createdAt ?? DateTime(2026, 1, 2),
    updatedAt: updatedAt,
    renewalHistory: renewalHistory,
    schemaId: schemaId,
    countryCode: countryCode,
    dynamicFields: dynamicFields,
  );
}
