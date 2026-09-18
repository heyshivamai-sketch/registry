import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';

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
  }) {
    if (actionDate == null) {
      return true;
    }
    return !RegistryDateFormatter.dateOnly(
      actionDate,
    ).isAfter(RegistryDateFormatter.dateOnly(newExpiry));
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
