import 'dart:typed_data';

import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';

RegistryDocument sampleDocument({
  String id = 'doc_1',
  String name = 'Family passport',
  DocumentCategory category = DocumentCategory.passport,
  String? ownerName = 'Amira',
  String? issuingAuthority = 'Algeria',
  String? documentNumber = 'AB12345678',
  DateTime? issueDate,
  DateTime? expiryDate,
  DateTime? actionDate,
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
  DateTime? createdAt,
  DateTime? updatedAt,
  List<RenewalHistoryEntry> renewalHistory = const [],
}) {
  return RegistryDocument(
    id: id,
    name: name,
    category: category,
    ownerName: ownerName,
    issuingAuthority: issuingAuthority,
    documentNumber: documentNumber,
    issueDate: issueDate ?? DateTime(2026, 9, 17),
    expiryDate: expiryDate ?? DateTime(2027, 10, 5),
    actionDate: actionDate ?? DateTime(2027, 9, 1),
    impact: impact,
    renewalEffort: renewalEffort,
    costOfLapsing: costOfLapsing,
    dependency: dependency,
    expectedChanges: expectedChanges,
    notes: notes,
    reminders: reminders,
    attachmentBytes: attachmentBytes,
    createdAt: createdAt ?? DateTime(2026, 1, 2),
    updatedAt: updatedAt,
    renewalHistory: renewalHistory,
  );
}
