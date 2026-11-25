import '../../home/data/registry_date_formatter.dart';
import 'registry_document.dart';
import 'renewal_history_entry.dart';

abstract final class DocumentRenewal {
  static bool isNewExpiryValid({
    required DateTime previousExpiry,
    required DateTime newExpiry,
  }) {
    return RegistryDateFormatter.dateOnly(
      newExpiry,
    ).isAfter(RegistryDateFormatter.dateOnly(previousExpiry));
  }

  static bool isActionDateValid({
    required DateTime newExpiry,
    DateTime? actionDate,
    DateTime? issueDate,
  }) {
    if (actionDate == null) {
      return true;
    }
    final action = RegistryDateFormatter.dateOnly(actionDate);
    if (action.isAfter(RegistryDateFormatter.dateOnly(newExpiry))) {
      return false;
    }
    if (issueDate != null &&
        action.isBefore(RegistryDateFormatter.dateOnly(issueDate))) {
      return false;
    }
    return true;
  }

  static RegistryDocument record({
    required RegistryDocument document,
    required DateTime renewedOn,
    required DateTime newExpiryDate,
    DateTime? newActionDate,
    String? note,
  }) {
    final trimmedNote = note?.trim();
    final entry = RenewalHistoryEntry(
      id: 'ren_${DateTime.now().microsecondsSinceEpoch}',
      renewedOn: renewedOn,
      previousExpiryDate: document.expiryDate,
      newExpiryDate: newExpiryDate,
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
    );
    return document.copyWith(
      expiryDate: newExpiryDate,
      actionDate: newActionDate ?? document.actionDate,
      renewalHistory: [entry, ...document.renewalHistory],
      updatedAt: DateTime.now(),
    );
  }
}
