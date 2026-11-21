import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

enum DetectionSource {
  bankStatement,
  gmail,
}

enum DetectionReviewStatus {
  pendingReview,
  accepted,
  ignored,
  duplicate,
  expired,
}

enum DetectionConfidence {
  low,
  medium,
  high,
}

class EmailEvidence {
  const EmailEvidence({
    required this.messageId,
    required this.subject,
    required this.sender,
    required this.date,
    this.snippet = '',
  });

  final String messageId;
  final String subject;
  final String sender;
  final DateTime date;
  final String snippet;

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'subject': subject,
        'sender': sender,
        'date': date.toIso8601String(),
        'snippet': snippet,
      };

  factory EmailEvidence.fromJson(Map<String, dynamic> json) => EmailEvidence(
        messageId: json['messageId'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        sender: json['sender'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        snippet: json['snippet'] as String? ?? '',
      );
}

class BankTransactionEvidence {
  const BankTransactionEvidence({
    required this.lineNumber,
    required this.date,
    required this.originalDescription,
    required this.amount,
    this.reference = '',
  });

  final int lineNumber;
  final DateTime date;
  final String originalDescription;
  final Money amount;
  final String reference;

  Map<String, dynamic> toJson() => {
        'lineNumber': lineNumber,
        'date': date.toIso8601String(),
        'originalDescription': originalDescription,
        'minorUnits': amount.minorUnits,
        'currencyCode': amount.code,
        'reference': reference,
      };

  factory BankTransactionEvidence.fromJson(Map<String, dynamic> json) =>
      BankTransactionEvidence(
        lineNumber: json['lineNumber'] as int? ?? 0,
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        originalDescription: json['originalDescription'] as String? ?? '',
        amount: Money(
          minorUnits: json['minorUnits'] as int? ?? 0,
          currencyCode: json['currencyCode'] as String? ?? 'USD',
        ),
        reference: json['reference'] as String? ?? '',
      );
}

class DetectedSubscriptionCandidate {
  const DetectedSubscriptionCandidate({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.billingCycle,
    required this.lastPaymentDate,
    this.nextPaymentDate,
    this.nextPaymentIsEstimated = true,
    required this.sourceTypes,
    required this.confidenceScore,
    this.reviewStatus = DetectionReviewStatus.pendingReview,
    this.bankEvidence = const [],
    this.emailEvidence = const [],
    required this.createdAt,
    this.updatedAt,
    this.possibleDuplicate = false,
  });

  final String id;
  final String merchantName;
  final Money amount;
  final BillingCycle billingCycle;
  final DateTime lastPaymentDate;
  final DateTime? nextPaymentDate;
  final bool nextPaymentIsEstimated;
  final Set<DetectionSource> sourceTypes;
  final double confidenceScore;
  final DetectionReviewStatus reviewStatus;
  final List<BankTransactionEvidence> bankEvidence;
  final List<EmailEvidence> emailEvidence;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool possibleDuplicate;

  DetectionConfidence get confidence {
    if (confidenceScore >= 0.75) {
      return DetectionConfidence.high;
    }
    if (confidenceScore >= 0.45) {
      return DetectionConfidence.medium;
    }
    return DetectionConfidence.low;
  }

  bool get hasBankSource => sourceTypes.contains(DetectionSource.bankStatement);
  bool get hasGmailSource => sourceTypes.contains(DetectionSource.gmail);

  DetectedSubscriptionCandidate copyWith({
    String? id,
    String? merchantName,
    Money? amount,
    BillingCycle? billingCycle,
    DateTime? lastPaymentDate,
    DateTime? nextPaymentDate,
    bool? nextPaymentIsEstimated,
    Set<DetectionSource>? sourceTypes,
    double? confidenceScore,
    DetectionReviewStatus? reviewStatus,
    List<BankTransactionEvidence>? bankEvidence,
    List<EmailEvidence>? emailEvidence,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? possibleDuplicate,
  }) {
    return DetectedSubscriptionCandidate(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      nextPaymentIsEstimated:
          nextPaymentIsEstimated ?? this.nextPaymentIsEstimated,
      sourceTypes: sourceTypes ?? this.sourceTypes,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      bankEvidence: bankEvidence ?? this.bankEvidence,
      emailEvidence: emailEvidence ?? this.emailEvidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      possibleDuplicate: possibleDuplicate ?? this.possibleDuplicate,
    );
  }
}

