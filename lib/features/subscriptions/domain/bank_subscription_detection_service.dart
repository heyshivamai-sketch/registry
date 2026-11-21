import 'dart:math' as math;

import 'package:the_registry/features/subscriptions/domain/detected_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

enum TransactionDirection {
  debit,
  credit,
}

class BankTransaction {
  const BankTransaction({
    required this.lineNumber,
    required this.date,
    required this.description,
    required this.amount,
    this.direction = TransactionDirection.debit,
    this.reference = '',
    this.merchantOverride,
  });

  final int lineNumber;
  final DateTime date;
  final String description;
  final Money amount;
  final TransactionDirection direction;
  final String reference;
  final String? merchantOverride;

  bool get isDebit => direction == TransactionDirection.debit;
  bool get isCredit => direction == TransactionDirection.credit;
}

/// Normalizes bank statement transactions, detects recurring payment patterns,
/// eliminates non-subscription false positives, and generates subscription candidates.
class BankSubscriptionDetectionService {
  const BankSubscriptionDetectionService({
    this.merchantSimilarityWeight = 0.30,
    this.intervalConsistencyWeight = 0.30,
    this.amountConsistencyWeight = 0.20,
    this.descriptionKeywordsWeight = 0.15,
    this.supportingEvidenceWeight = 0.05,
  });

  final double merchantSimilarityWeight;
  final double intervalConsistencyWeight;
  final double amountConsistencyWeight;
  final double descriptionKeywordsWeight;
  final double supportingEvidenceWeight;

  static final RegExp _processorPrefixes = RegExp(
    r'^(?:RAZORPAY\*?|PAYU\*?|STRIPE\*?|BILLDESK\*?|CCAVENUE\*?|PAYTM\*?|PAYPAL\*?|GOOGLE\*|APPLE\.COM/BILL|AMZN MKTP|AMAZON PAY|MICROSOFT\*)\s*',
    caseSensitive: false,
  );

  static final RegExp _channelPrefixes = RegExp(
    r'^(?:UPI[-/]|POS[-/]|ACH[-/]|NEFT[-/]|RTGS[-/]|IMPS[-/]|DEBIT CARD[-/]|DIRECT DEBIT[-/]|NACH[-/]|SI[-/]|ECS[-/])\s*',
    caseSensitive: false,
  );

  static final RegExp _upiSuffix = RegExp(
    r'(?:/[0-9A-Za-z_\.\-]+)?@[a-zA-Z0-9_\.\-]+$',
    caseSensitive: false,
  );

  static final RegExp _domainSuffixes = RegExp(
    r'\.(?:COM|IN|ORG|NET|IO|CO|AI|APP|UK|DE|FR|US|INFO)\b',
    caseSensitive: false,
  );

  static final RegExp _legalEntitySuffixes = RegExp(
    r'\b(?:PVT\.?\s*LTD\.?|PRIVATE\s+LIMITED|LTD\.?|LIMITED|INC\.?|LLC\.?|CORP\.?|SERVICES|INDIA|GLOBAL)\b',
    caseSensitive: false,
  );

  static final RegExp _trailingNoise = RegExp(
    r'\b(?:PAYMENT|PAYMENTS|MEMBERSHIP|BILL|AUTOPAY|MANDATE|RECURRING|SUB|SUBSCRIPTION|CHARGE|PURCHASE|TXN|TRX)\b',
    caseSensitive: false,
  );

  static final List<RegExp> _falsePositivePatterns = [
    // Rent & Housing
    RegExp(r'\b(?:RENT|HOUSE\s*RENT|FLAT\s*RENT|SOCIETY\s*MAINTENANCE|LANDLORD|TENANT)\b', caseSensitive: false),
    // Utilities
    RegExp(r'\b(?:ELECTRICITY|POWER|WATER\s*BILL|WATER\s*BOARD|JAL\s*BOARD|GAS\s*BILL|CYLINDER|BESCOM|TNEB|MSEB|ADANI\s*ELECTRICITY|DHBVN|UPPCL)\b', caseSensitive: false),
    // Groceries & Food Delivery / Supermarkets
    RegExp(r'\b(?:GROCERY|GROCERIES|SUPERMARKET|BLINKIT|ZEPTO|INSTAMART|BIGBASKET|DMART|WALMART|COSTCO|RELIANCE\s*FRESH|NATURES\s*BASKET|SPENCERS)\b', caseSensitive: false),
    // Loan & EMI
    RegExp(r'\b(?:EMI|LOAN|HOME\s*LOAN|CAR\s*LOAN|PERSONAL\s*LOAN|BAJAJ\s*FINANCE|HDFC\s*CREDILA|IDFC\s*FIRST\s*LOAN|MUTHOOT|MANAPPURAM)\b', caseSensitive: false),
    // Credit card bill payments
    RegExp(r'\b(?:CREDIT\s*CARD|CC\s*PAYMENT|CARD\s*PAYMENT|CRED\s*PAYMENT|CRED\.CLUB|CARD\s*BILL)\b', caseSensitive: false),
    // Salary & Deposits (in case not tagged credit)
    RegExp(r'\b(?:SALARY|PAYROLL|STIPEND|DIVIDEND|INTEREST\s*CREDIT|CASH\s*DEPOSIT)\b', caseSensitive: false),
    // Internal & P2P bank transfers
    RegExp(r'\b(?:SELF\s*TRANSFER|FUND\s*TRANSFER|TRANSFER\s*TO\s*SELF|INTER\s*ACCOUNT|TO\s*SAVINGS)\b', caseSensitive: false),
  ];

  static final List<String> _subscriptionKeywords = [
    'subscription',
    'membership',
    'autopay',
    'recurring',
    'monthly',
    'annual',
    'yearly',
    'sub',
    'premium',
    'plan',
    'pro',
    'streaming',
  ];

  /// Cleans and normalizes raw merchant text.
  String normalizeMerchant(String raw) {
    var text = raw.trim();
    if (text.isEmpty) {
      return '';
    }

    if (RegExp(r'^(?:apple\.com(?:/bill)?|itunes\.com|apple\s+services)$', caseSensitive: false).hasMatch(text)) {
      return 'Apple';
    }

    // Remove transaction channel prefixes like UPI- or POS-
    text = text.replaceAll(_channelPrefixes, ' ');
    // Remove UPI VPA suffix like /1234@okaxis or @paytm
    text = text.replaceAll(_upiSuffix, ' ');
    // Remove payment gateway prefixes like RAZORPAY*
    text = text.replaceAll(_processorPrefixes, ' ');
    // Remove domain suffixes like .COM
    text = text.replaceAll(_domainSuffixes, ' ');
    // Remove legal corporate suffixes
    text = text.replaceAll(_legalEntitySuffixes, ' ');
    // Remove trailing payment descriptors
    text = text.replaceAll(_trailingNoise, ' ');
    // Remove non-alphanumeric except spaces
    text = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ');
    // Collapse multiple spaces
    text = text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    // Uppercase first letter of each word for clean display
    if (text.isEmpty) {
      return raw.trim();
    }
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Tests if a transaction description matches non-subscription categories (rent, utilities, EMI, etc.).
  bool isFalsePositive(String description) {
    for (final pattern in _falsePositivePatterns) {
      if (pattern.hasMatch(description)) {
        return true;
      }
    }
    return false;
  }

  /// Processes bank transactions to detect recurring subscription candidates.
  List<DetectedSubscriptionCandidate> detectSubscriptions({
    required List<BankTransaction> transactions,
    required List<RegistrySubscription> existingSubscriptions,
    Set<String> ignoredMerchants = const {},
    required DateTime Function() now,
    String Function(int index)? idGenerator,
  }) {
    // Step 1: Filter out credit transactions (deposits/refunds)
    final debitTransactions = transactions.where((t) => t.isDebit).toList();

    // Step 2: Group by normalized merchant and currency
    final groups = <String, List<BankTransaction>>{};
    for (final t in debitTransactions) {
      final merchantName = t.merchantOverride != null && t.merchantOverride!.trim().isNotEmpty
          ? normalizeMerchant(t.merchantOverride!)
          : normalizeMerchant(t.description);

      if (merchantName.isEmpty) {
        continue;
      }

      // Check user suppression preference
      final lowerMerchant = merchantName.toLowerCase();
      if (ignoredMerchants.any((ignored) {
        final target = ignored.toLowerCase().trim();
        return lowerMerchant == target || lowerMerchant.contains(target);
      })) {
        continue;
      }

      // Check false-positive rule
      if (isFalsePositive(t.description)) {
        continue;
      }

      final key = '${merchantName.toLowerCase()}|${t.amount.code}';
      groups.putIfAbsent(key, () => []).add(t);
    }

    final candidates = <DetectedSubscriptionCandidate>[];
    var candidateIndex = 0;

    for (final entry in groups.entries) {
      final group = entry.value;

      // Single transaction must not become a subscription candidate (requires at least 2 occurrences)
      if (group.length < 2) {
        continue;
      }

      // Sort by date ascending
      group.sort((a, b) => a.date.compareTo(b.date));

      final cycle = _detectBillingCycle(group);
      if (cycle == null) {
        continue;
      }

      final score = _calculateConfidenceScore(group, cycle);
      // Discard very low confidence detections (< 0.40)
      if (score < 0.40) {
        continue;
      }

      final latest = group.last;
      final merchantName = normalizeMerchant(
        latest.merchantOverride ?? latest.description,
      );

      // Check if existing manual or active subscription already exists
      final duplicate = existingSubscriptions.any((sub) =>
          normalizeMerchant(sub.serviceName).toLowerCase() ==
              merchantName.toLowerCase() &&
          sub.amount.code == latest.amount.code &&
          (sub.amount.minorUnits == latest.amount.minorUnits ||
              (sub.amount.minorUnits - latest.amount.minorUnits).abs() <=
                  (latest.amount.minorUnits * 0.15).toInt()));

      final evidence = group.map((t) => BankTransactionEvidence(
            lineNumber: t.lineNumber,
            date: t.date,
            originalDescription: t.description,
            amount: t.amount,
            reference: t.reference,
          )).toList();

      final candidateId = idGenerator != null
          ? idGenerator(candidateIndex++)
          : 'bank_cand_${now().microsecondsSinceEpoch}_${candidateIndex++}';

      candidates.add(
        DetectedSubscriptionCandidate(
          id: candidateId,
          merchantName: merchantName,
          amount: latest.amount,
          billingCycle: cycle,
          lastPaymentDate: latest.date,
          nextPaymentDate: _estimateNextPaymentDate(latest.date, cycle),
          nextPaymentIsEstimated: true,
          sourceTypes: {DetectionSource.bankStatement},
          confidenceScore: score,
          reviewStatus: DetectionReviewStatus.pendingReview,
          bankEvidence: evidence,
          createdAt: now(),
          possibleDuplicate: duplicate,
        ),
      );
    }

    return candidates;
  }

  BillingCycle? _detectBillingCycle(List<BankTransaction> group) {
    final uniqueDates = group.map((t) => DateTime(t.date.year, t.date.month, t.date.day)).toSet().toList()
      ..sort();

    if (uniqueDates.length < 2) {
      return null;
    }

    final intervals = <int>[
      for (var i = 1; i < uniqueDates.length; i++)
        uniqueDates[i].difference(uniqueDates[i - 1]).inDays,
    ];

    final medianInterval = _median(intervals);
    final detectedCycle = _cycleForIntervalDays(medianInterval);
    if (detectedCycle == null) {
      return null;
    }

    // Verify consistency: at least 50% of intervals must match the cycle tolerance
    final matchingCount = intervals.where((days) => _cycleForIntervalDays(days) == detectedCycle).length;
    if (matchingCount * 2 < intervals.length) {
      return null;
    }

    return detectedCycle;
  }

  double _calculateConfidenceScore(List<BankTransaction> group, BillingCycle cycle) {
    // 1. Merchant similarity (30%)
    // Since they are grouped by normalized merchant, base is high.
    // Higher transaction count gives full 0.30, 2 occurrences gives 0.20
    final merchantScore = group.length >= 3 ? 1.0 : 0.70;

    // 2. Billing interval consistency (30%)
    final uniqueDates = group.map((t) => DateTime(t.date.year, t.date.month, t.date.day)).toSet().toList()
      ..sort();
    final intervals = [
      for (var i = 1; i < uniqueDates.length; i++)
        uniqueDates[i].difference(uniqueDates[i - 1]).inDays,
    ];
    final matchCount = intervals.where((days) => _cycleForIntervalDays(days) == cycle).length;
    final intervalRatio = intervals.isNotEmpty ? matchCount / intervals.length : 0.0;

    // 3. Amount consistency (20%)
    final amounts = group.map((t) => t.amount.minorUnits).toList();
    final firstAmount = amounts.first;
    final sameAmountCount = amounts.where((a) => a == firstAmount).length;
    final amountRatio = sameAmountCount / amounts.length;

    // 4. Description keywords (15%)
    var keywordFound = false;
    for (final t in group) {
      final desc = t.description.toLowerCase();
      if (_subscriptionKeywords.any((kw) => desc.contains(kw))) {
        keywordFound = true;
        break;
      }
    }
    final keywordScore = keywordFound ? 1.0 : 0.40;

    // 5. Independent evidence (5%)
    final evidenceScore = group.length >= 3 ? 1.0 : 0.50;

    final totalScore = (merchantScore * merchantSimilarityWeight) +
        (intervalRatio * intervalConsistencyWeight) +
        (amountRatio * amountConsistencyWeight) +
        (keywordScore * descriptionKeywordsWeight) +
        (evidenceScore * supportingEvidenceWeight);

    return double.parse(math.min(1.0, math.max(0.0, totalScore)).toStringAsFixed(2));
  }

  int _median(List<int> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return ((sorted[middle - 1] + sorted[middle]) / 2).round();
  }

  BillingCycle? _cycleForIntervalDays(int days) {
    if ((days - 7).abs() <= 2) {
      return BillingCycle.weekly;
    }
    if ((days - 30).abs() <= 4) {
      return BillingCycle.monthly;
    }
    if ((days - 91).abs() <= 10) {
      return BillingCycle.quarterly;
    }
    if ((days - 365).abs() <= 25) {
      return BillingCycle.yearly;
    }
    return null;
  }

  DateTime _estimateNextPaymentDate(DateTime date, BillingCycle cycle) {
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
}