import 'dart:typed_data';

import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/csv_import/csv_import_limits.dart';
import 'package:the_registry/features/csv_import/csv_table.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/entitlements/entitlement_policy.dart';
import 'package:the_registry/features/entitlements/entitlement_service.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_repository.dart';

enum CsvImportStep { choose, map, review }

enum CsvImportNotice {
  none,
  cancelled,
  tooLarge,
  tooManyRows,
  tooManyColumns,
  invalidFile,
  columnsRequired,
  noCharges,
  noSuggestions,
  nothingSelected,
  subscriptionLimit,
  duplicateId,
}

class CsvColumnMapping {
  const CsvColumnMapping({
    this.date,
    this.merchant,
    this.amount,
    this.currency,
  });

  final int? date;
  final int? merchant;
  final int? amount;
  final int? currency;

  bool get isComplete {
    final indexes = [date, merchant, amount, currency];
    if (indexes.any((index) => index == null)) {
      return false;
    }
    return indexes.toSet().length == indexes.length;
  }

  CsvColumnMapping copyWith({
    int? date,
    int? merchant,
    int? amount,
    int? currency,
  }) {
    return CsvColumnMapping(
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }
}

class CsvChargeRow {
  const CsvChargeRow({
    required this.lineNumber,
    required this.date,
    required this.merchant,
    required this.minorUnits,
    required this.currencyCode,
  });

  final int lineNumber;
  final DateTime date;
  final String merchant;
  final int minorUnits;
  final String currencyCode;
}

class RecurringChargeCandidate {
  const RecurringChargeCandidate({
    required this.id,
    required this.merchant,
    required this.minorUnits,
    required this.currencyCode,
    required this.cycle,
    required this.nextPaymentDate,
    required this.sourceRows,
    required this.selected,
    required this.possibleDuplicate,
  });

  final String id;
  final String merchant;
  final int minorUnits;
  final String currencyCode;
  final BillingCycle cycle;
  final DateTime nextPaymentDate;
  final List<int> sourceRows;
  final bool selected;
  final bool possibleDuplicate;

  RecurringChargeCandidate copyWith({
    String? merchant,
    int? minorUnits,
    String? currencyCode,
    BillingCycle? cycle,
    DateTime? nextPaymentDate,
    bool? selected,
    bool? possibleDuplicate,
  }) {
    return RecurringChargeCandidate(
      id: id,
      merchant: merchant ?? this.merchant,
      minorUnits: minorUnits ?? this.minorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      cycle: cycle ?? this.cycle,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      sourceRows: sourceRows,
      selected: selected ?? this.selected,
      possibleDuplicate: possibleDuplicate ?? this.possibleDuplicate,
    );
  }
}

class CsvMappedCharges {
  const CsvMappedCharges({required this.charges, required this.skippedLines});

  final List<CsvChargeRow> charges;
  final List<int> skippedLines;
}

/// Reads the documented generic charge CSV and suggests recurring charges.
///
/// A suggestion is not a confirmed subscription. Nothing is written until
/// [confirm] runs, and a refusal leaves the repository unchanged.
class CsvChargeImportSession {
  CsvChargeImportSession({
    required this.subscriptions,
    required this.writes,
    required Clock clock,
  }) {
    _clock = clock;
  }

  final SubscriptionRepository subscriptions;
  final RegistryWrites writes;
  late final Clock _clock;

  CsvImportStep step = CsvImportStep.choose;
  CsvImportNotice notice = CsvImportNotice.none;
  CsvRawTable? table;
  CsvColumnMapping mapping = const CsvColumnMapping();
  List<RecurringChargeCandidate> candidates = const [];
  List<int> skippedLines = const [];
  var savedCount = 0;

  void loadBytes(Uint8List? bytes) {
    savedCount = 0;
    candidates = const [];
    skippedLines = const [];
    if (bytes == null) {
      notice = CsvImportNotice.cancelled;
      step = CsvImportStep.choose;
      table = null;
      return;
    }
    final parsed = CsvTableParser.parse(bytes);
    final failure = parsed.failure;
    if (failure != null || parsed.table == null) {
      table = null;
      step = CsvImportStep.choose;
      notice = switch (failure) {
        CsvFileFailure.tooLarge => CsvImportNotice.tooLarge,
        CsvFileFailure.tooManyRows => CsvImportNotice.tooManyRows,
        CsvFileFailure.tooManyColumns => CsvImportNotice.tooManyColumns,
        _ => CsvImportNotice.invalidFile,
      };
      return;
    }
    table = parsed.table;
    mapping = _suggestedMapping(parsed.table!.headers);
    notice = CsvImportNotice.none;
    step = CsvImportStep.map;
  }

  void setDateColumn(int? index) => mapping = mapping.copyWith(date: index);

  void setMerchantColumn(int? index) =>
      mapping = mapping.copyWith(merchant: index);

  void setAmountColumn(int? index) => mapping = mapping.copyWith(amount: index);

  void setCurrencyColumn(int? index) =>
      mapping = mapping.copyWith(currency: index);

  void continueFromMapping() {
    final current = table;
    if (current == null) {
      return;
    }
    if (!mapping.isComplete) {
      notice = CsvImportNotice.columnsRequired;
      return;
    }
    final mapped = mapCharges(current, mapping);
    skippedLines = mapped.skippedLines;
    if (mapped.charges.isEmpty) {
      candidates = const [];
      notice = CsvImportNotice.noCharges;
      step = CsvImportStep.review;
      return;
    }
    candidates = suggestRecurringCharges(
      charges: mapped.charges,
      subscriptions: subscriptions.subscriptions,
      idFor: (index) => 'suggestion-$index',
    );
    notice = candidates.isEmpty
        ? CsvImportNotice.noSuggestions
        : CsvImportNotice.none;
    step = CsvImportStep.review;
  }

  void back() {
    notice = CsvImportNotice.none;
    if (step == CsvImportStep.review) {
      step = CsvImportStep.map;
      return;
    }
    if (step == CsvImportStep.map) {
      step = CsvImportStep.choose;
    }
  }

  void setSelected(String id, bool selected) {
    candidates = [
      for (final candidate in candidates)
        if (candidate.id == id)
          candidate.copyWith(selected: selected)
        else
          candidate,
    ];
  }

  /// Returns false when the edited values are not a date and integer amount.
  bool updateCandidate({
    required String id,
    required String merchant,
    required String minorUnitsText,
    required String currencyCode,
    required BillingCycle cycle,
    required String nextDateText,
  }) {
    final minorUnits = parseMinorUnits(minorUnitsText);
    final nextDate = parseCsvDate(nextDateText);
    final name = merchant.trim();
    final currency = currencyCode.trim().toUpperCase();
    if (minorUnits == null ||
        nextDate == null ||
        name.isEmpty ||
        name.length > CsvImportLimits.maxFieldChars ||
        !CurrencyInfo.supportedCodes.contains(currency)) {
      return false;
    }
    candidates = [
      for (final candidate in candidates)
        if (candidate.id == id)
          candidate.copyWith(
            merchant: name,
            minorUnits: minorUnits,
            currencyCode: currency,
            cycle: cycle,
            nextPaymentDate: nextDate,
            possibleDuplicate: _duplicates(
              merchant: name,
              minorUnits: minorUnits,
              currencyCode: currency,
            ),
          )
        else
          candidate,
    ];
    return true;
  }

  Future<bool> confirm({required String note}) async {
    final selected = [
      for (final candidate in candidates)
        if (candidate.selected) candidate,
    ];
    if (selected.isEmpty) {
      notice = CsvImportNotice.nothingSelected;
      return false;
    }
    final createdAt = _clock.now();
    final records = <RegistrySubscription>[];
    final taken = <String>{};
    for (var index = 0; index < selected.length; index++) {
      final candidate = selected[index];
      records.add(
        RegistrySubscription(
          id: _freshId(createdAt, index, taken),
          createdAt: createdAt,
          serviceName: candidate.merchant,
          category: SubscriptionCategory.other,
          amount: Money(
            minorUnits: candidate.minorUnits,
            currencyCode: candidate.currencyCode,
          ),
          billingCycle: candidate.cycle,
          nextPaymentDate: candidate.nextPaymentDate,
          autoRenew: true,
          lifecycle: SubscriptionLifecycle.active,
          impact: DocumentImpact.medium,
          notes: note,
        ),
      );
    }
    try {
      await writes.createSubscriptions(records);
    } on EntitlementDenied {
      notice = CsvImportNotice.subscriptionLimit;
      return false;
    } on DuplicateRecordId {
      notice = CsvImportNotice.duplicateId;
      return false;
    }
    savedCount = records.length;
    notice = CsvImportNotice.none;
    return true;
  }

  bool _duplicates({
    required String merchant,
    required int minorUnits,
    required String currencyCode,
  }) {
    final name = normalizeMerchant(merchant);
    for (final subscription in subscriptions.subscriptions) {
      if (normalizeMerchant(subscription.serviceName) == name &&
          subscription.amount.minorUnits == minorUnits &&
          subscription.amount.code == currencyCode) {
        return true;
      }
    }
    return false;
  }

  String _freshId(DateTime createdAt, int index, Set<String> taken) {
    var salt = 0;
    while (true) {
      final suffix = salt == 0 ? '$index' : '${index}_$salt';
      final id = 'csv_${createdAt.microsecondsSinceEpoch}_$suffix';
      if (subscriptions.findById(id) == null && taken.add(id)) {
        return id;
      }
      salt += 1;
    }
  }
}

CsvColumnMapping _suggestedMapping(List<String> headers) {
  int? match(String name) {
    for (var index = 0; index < headers.length; index++) {
      if (headers[index].trim().toLowerCase() == name) {
        return index;
      }
    }
    return null;
  }

  return CsvColumnMapping(
    date: match(CsvImportLimits.dateHeader),
    merchant: match(CsvImportLimits.merchantHeader),
    amount: match(CsvImportLimits.amountHeader),
    currency: match(CsvImportLimits.currencyHeader),
  );
}

CsvMappedCharges mapCharges(CsvRawTable table, CsvColumnMapping mapping) {
  final dateIndex = mapping.date!;
  final merchantIndex = mapping.merchant!;
  final amountIndex = mapping.amount!;
  final currencyIndex = mapping.currency!;
  final charges = <CsvChargeRow>[];
  final skipped = <int>[];
  for (final row in table.rows) {
    final charge = _chargeFromRow(
      row,
      dateIndex: dateIndex,
      merchantIndex: merchantIndex,
      amountIndex: amountIndex,
      currencyIndex: currencyIndex,
    );
    if (charge == null) {
      skipped.add(row.lineNumber);
    } else {
      charges.add(charge);
    }
  }
  return CsvMappedCharges(charges: charges, skippedLines: skipped);
}

CsvChargeRow? _chargeFromRow(
  CsvRawRow row, {
  required int dateIndex,
  required int merchantIndex,
  required int amountIndex,
  required int currencyIndex,
}) {
  final cells = row.cells;
  final needed = [dateIndex, merchantIndex, amountIndex, currencyIndex];
  if (needed.any((index) => index < 0 || index >= cells.length)) {
    return null;
  }
  final date = parseCsvDate(cells[dateIndex]);
  final minorUnits = parseMinorUnits(cells[amountIndex]);
  final merchant = cells[merchantIndex].trim();
  final currency = cells[currencyIndex].trim().toUpperCase();
  if (date == null ||
      minorUnits == null ||
      merchant.isEmpty ||
      merchant.length > CsvImportLimits.maxFieldChars ||
      !CurrencyInfo.supportedCodes.contains(currency)) {
    return null;
  }
  return CsvChargeRow(
    lineNumber: row.lineNumber,
    date: date,
    merchant: merchant,
    minorUnits: minorUnits,
    currencyCode: currency,
  );
}

DateTime? parseCsvDate(String raw) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw.trim());
  if (match == null) {
    return null;
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12) {
    return null;
  }
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

int? parseMinorUnits(String raw) {
  final value = raw.trim();
  if (!RegExp(r'^[0-9]+$').hasMatch(value) || value.length > 12) {
    return null;
  }
  return int.tryParse(value);
}

String normalizeMerchant(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Groups charges that look regular. The result is a suggestion only.
List<RecurringChargeCandidate> suggestRecurringCharges({
  required List<CsvChargeRow> charges,
  required List<RegistrySubscription> subscriptions,
  required String Function(int index) idFor,
}) {
  final groups = <String, List<CsvChargeRow>>{};
  for (final charge in charges) {
    final key =
        '${normalizeMerchant(charge.merchant)}|${charge.currencyCode}|${charge.minorUnits}';
    groups.putIfAbsent(key, () => []).add(charge);
  }
  final candidates = <RecurringChargeCandidate>[];
  for (final group in groups.values) {
    final cycle = _suggestedCycle(group);
    if (cycle == null) {
      continue;
    }
    final latest = group
        .map((charge) => charge.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final sample = group.first;
    final duplicate = subscriptions.any(
      (subscription) =>
          normalizeMerchant(subscription.serviceName) ==
              normalizeMerchant(sample.merchant) &&
          subscription.amount.minorUnits == sample.minorUnits &&
          subscription.amount.code == sample.currencyCode,
    );
    final rows = [for (final charge in group) charge.lineNumber]..sort();
    candidates.add(
      RecurringChargeCandidate(
        id: idFor(candidates.length),
        merchant: sample.merchant.trim(),
        minorUnits: sample.minorUnits,
        currencyCode: sample.currencyCode,
        cycle: cycle,
        nextPaymentDate: _addCycle(latest, cycle),
        sourceRows: rows,
        selected: !duplicate,
        possibleDuplicate: duplicate,
      ),
    );
  }
  return candidates;
}

BillingCycle? _suggestedCycle(List<CsvChargeRow> group) {
  final dates = group.map((charge) => charge.date).toSet().toList()..sort();
  if (dates.length < 2) {
    return null;
  }
  final deltas = <int>[
    for (var index = 1; index < dates.length; index++)
      dates[index].difference(dates[index - 1]).inDays,
  ];
  final median = _median(deltas);
  final cycle = _cycleForDays(median);
  if (cycle == null) {
    return null;
  }
  final matched = deltas.where((days) => _cycleForDays(days) == cycle).length;
  if (matched * 2 < deltas.length) {
    return null;
  }
  return cycle;
}

int _median(List<int> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middle];
  }
  return ((sorted[middle - 1] + sorted[middle]) / 2).round();
}

BillingCycle? _cycleForDays(int days) {
  if ((days - 7).abs() <= 2) {
    return BillingCycle.weekly;
  }
  if ((days - 30).abs() <= 4) {
    return BillingCycle.monthly;
  }
  if ((days - 91).abs() <= 10) {
    return BillingCycle.quarterly;
  }
  if ((days - 365).abs() <= 20) {
    return BillingCycle.yearly;
  }
  return null;
}

DateTime _addCycle(DateTime date, BillingCycle cycle) {
  return switch (cycle) {
    BillingCycle.weekly => date.add(const Duration(days: 7)),
    BillingCycle.monthly => _addMonths(date, 1),
    BillingCycle.quarterly => _addMonths(date, 3),
    BillingCycle.yearly => _addMonths(date, 12),
  };
}

DateTime _addMonths(DateTime date, int months) {
  final monthStart = DateTime(date.year, date.month + months, 1);
  final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(monthStart.year, monthStart.month, day);
}
