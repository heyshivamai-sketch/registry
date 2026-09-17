import 'dart:typed_data';

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
  });

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
}
