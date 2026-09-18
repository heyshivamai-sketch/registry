class RenewalHistoryEntry {
  const RenewalHistoryEntry({
    required this.id,
    required this.renewedOn,
    required this.previousExpiryDate,
    required this.newExpiryDate,
    this.note,
  });

  final String id;
  final DateTime renewedOn;
  final DateTime previousExpiryDate;
  final DateTime newExpiryDate;
  final String? note;
}
