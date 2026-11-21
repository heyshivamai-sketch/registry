import 'dart:convert';

import 'bank_subscription_detection_service.dart';
import 'detected_subscription.dart';
import 'money.dart';
import 'registry_subscription.dart';

enum GmailEventType {
  subscriptionStarted,
  paymentSuccess,
  subscriptionRenewal,
  upcomingPayment,
  trialStarted,
  cancellation,
  priceChanged,
  refund,
  unknown,
}

class GmailRawMessage {
  const GmailRawMessage({
    required this.id,
    required this.headers,
    this.threadId = '',
    this.snippet = '',
    this.plainTextBody,
    this.htmlBody,
  });

  final String id;
  final String threadId;
  final Map<String, String> headers;
  final String snippet;
  final String? plainTextBody;
  final String? htmlBody;

  String? get subject => headers['Subject'] ?? headers['subject'];

  String? get from => headers['From'] ?? headers['from'];

  String? get dateHeader => headers['Date'] ?? headers['date'];
}

class ExtractedEmailSubscription {
  const ExtractedEmailSubscription({
    required this.messageId,
    required this.merchantName,
    required this.eventType,
    required this.paymentDate,
    required this.sender,
    required this.subject,
    required this.snippet,
    required this.confidenceScore,
    this.planName,
    this.amount,
    this.billingCycle,
    this.nextRenewalDate,
    this.renewalDateIsEstimated = true,
  });

  final String messageId;
  final String merchantName;
  final String? planName;
  final GmailEventType eventType;
  final Money? amount;
  final BillingCycle? billingCycle;
  final DateTime paymentDate;
  final DateTime? nextRenewalDate;
  final bool renewalDateIsEstimated;
  final String sender;
  final String subject;
  final String snippet;
  final double confidenceScore;
}

class GmailSubscriptionDetectionService {
  GmailSubscriptionDetectionService({BankSubscriptionDetectionService? bankService})
    : _bankService = bankService ?? const BankSubscriptionDetectionService();

  final BankSubscriptionDetectionService _bankService;

  static const String billingSearchQuery =
      '(subject:(subscription OR renewal OR "payment successful" OR receipt OR invoice OR "membership renewal" OR "free trial" OR "upcoming payment" OR "Google Play order" OR "order receipt" OR "order confirmation" OR "Google One" OR "YouTube Premium") OR from:(googleplay-noreply@google.com OR googlepayments-noreply@google.com OR googleone-noreply@google.com OR payments-noreply@google.com)) newer_than:365d';

  static final Map<String, int> _monthMap = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  /// Parses flexible date formats including ISO-8601, "15 Dec 2026", "Dec 15, 2026", and "DD/MM/YYYY".
  static DateTime? tryParseFlexibleDate(String input) {
    final raw = input.trim().replaceAll(',', '');

    // 1. ISO format: 2026-12-15 or 2026-12-15T00:00:00Z
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    // 2. Format: "15 Dec 2026" or "15 December 2026"
    final dayMonthYear = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$').firstMatch(raw);
    if (dayMonthYear != null) {
      final day = int.tryParse(dayMonthYear.group(1)!);
      final monthName = dayMonthYear.group(2)!.toLowerCase();
      final year = int.tryParse(dayMonthYear.group(3)!);
      final month = _monthMap[monthName];
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // 3. Format: "Dec 15 2026" or "December 15 2026"
    final monthDayYear = RegExp(r'^([A-Za-z]+)\s+(\d{1,2})\s+(\d{4})$').firstMatch(raw);
    if (monthDayYear != null) {
      final monthName = monthDayYear.group(1)!.toLowerCase();
      final day = int.tryParse(monthDayYear.group(2)!);
      final year = int.tryParse(monthDayYear.group(3)!);
      final month = _monthMap[monthName];
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // 4. Format: "15/12/2026" or "15-12-2026" (DD/MM/YYYY)
    final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(raw);
    if (dmy != null) {
      final p1 = int.tryParse(dmy.group(1)!);
      final p2 = int.tryParse(dmy.group(2)!);
      final year = int.tryParse(dmy.group(3)!);
      if (p1 != null && p2 != null && year != null) {
        if (p1 > 12) {
          return DateTime(year, p2, p1);
        } else if (p2 > 12) {
          return DateTime(year, p1, p2);
        } else {
          return DateTime(year, p2, p1);
        }
      }
    }

    return null;
  }

  /// Decodes base64url message payload safely.
  static String decodeBase64UrlSafe(String data) {
    try {
      final normalized = base64.normalize(data.replaceAll('-', '+').replaceAll('_', '/'));
      return utf8.decode(base64.decode(normalized));
    } catch (_) {
      return '';
    }
  }

  /// Strips HTML tags and script/style tags for text analysis.
  static String stripHtml(String html) {
    var text = html.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  /// Classifies the event type of a billing-related email.
  GmailEventType classifyEventType({required String subject, required String body}) {
    final lowerSubject = subject.toLowerCase();
    final lowerBody = body.toLowerCase();
    final text = '$lowerSubject $lowerBody';

    // 1. Check refund first (exclusions).
    // Must be a genuine refund confirmation, not merely mentioning "refund policy", "refund rights", or "request a refund".
    final hasRefundSubject = RegExp(r'\b(?:refund|refunded|reversed|credit note)\b').hasMatch(lowerSubject);
    final hasExplicitRefundBody = RegExp(
      r"\b(?:has been refunded|refund has been|refund of (?:₹|rs|\$|usd|eur|gbp|[0-9])|we(?:’|'|\s)ve issued a refund|we have issued a refund|issued a refund|refund was processed|refund confirmation)\b",
    ).hasMatch(lowerBody);
    final isOnlyRefundPolicy =
        !hasRefundSubject &&
        !hasExplicitRefundBody &&
        RegExp(
          r'\b(?:refund policy|request a refund|refund rights|terms of refund|refund rules)\b',
        ).hasMatch(lowerBody);

    if ((hasRefundSubject || hasExplicitRefundBody) && !isOnlyRefundPolicy) {
      return GmailEventType.refund;
    }

    // 2. Check cancellation (exclusions).
    // Must be an actual cancellation, not merely mentioning "cancel anytime" or "cancellation policy".
    final hasCancelSubject = RegExp(r'\b(?:cancellation|cancelled|canceled|unsubscribed)\b').hasMatch(lowerSubject);
    final hasExplicitCancelBody = RegExp(
      r'\b(?:has been cancelled|has been canceled|subscription was cancelled|subscription was canceled|successfully cancelled|successfully canceled|cancellation confirmed|ended your subscription|ending your membership|membership has ended)\b',
    ).hasMatch(lowerBody);
    final isOnlyCancelPolicy =
        !hasCancelSubject &&
        !hasExplicitCancelBody &&
        RegExp(
          r'\b(?:cancel anytime|cancel at any time|how to cancel|cancel your subscription at any time|cancellation policy)\b',
        ).hasMatch(lowerBody);

    if ((hasCancelSubject || hasExplicitCancelBody) && !isOnlyCancelPolicy) {
      return GmailEventType.cancellation;
    }

    // 3. Free trial
    if (RegExp(r'\b(?:free trial|trial started|trial activated)\b').hasMatch(text)) {
      return GmailEventType.trialStarted;
    }

    // 4. Price change
    if (RegExp(r'\b(?:price change|price increase|update to your pricing|plan price)\b').hasMatch(text)) {
      return GmailEventType.priceChanged;
    }

    // 5. Renewal
    if (RegExp(
      r'\b(?:renewed|renewal successful|subscription renewed|membership renewed|automatically renews|auto-renewing|auto-renew|renews on)\b',
    ).hasMatch(text)) {
      return GmailEventType.subscriptionRenewal;
    }

    // 6. Upcoming payment
    if (RegExp(r'\b(?:upcoming payment|upcoming charge|will be charged|next bill)\b').hasMatch(text)) {
      return GmailEventType.upcomingPayment;
    }

    // 7. Payment success
    if (RegExp(
      r'\b(?:payment received|payment successful|payment confirmation|receipt for your payment|receipt|invoice|billed|order receipt|order confirmation|google play order)\b',
    ).hasMatch(text)) {
      return GmailEventType.paymentSuccess;
    }

    // 8. Subscription started
    if (RegExp(
      r"\b(?:subscription|membership|welcome to|plan activated|you(?:’|'|\s)ve subscribed to|subscribed to)\b",
    ).hasMatch(text)) {
      return GmailEventType.subscriptionStarted;
    }

    return GmailEventType.unknown;
  }

  /// Extracts the merchant name from From header, Subject, or Body.
  String extractMerchantName({required String from, required String subject, String body = ''}) {
    final lowerFrom = from.toLowerCase();
    final lowerSubject = subject.toLowerCase();
    final isGoogleSource =
        lowerFrom.contains('google') ||
        lowerFrom.contains('googleplay') ||
        lowerFrom.contains('googleone') ||
        lowerSubject.contains('google play');

    if (isGoogleSource && body.isNotEmpty) {
      // 1. Look for Item: or Product: line in Google Play receipts
      final itemMatch = RegExp(r'(?:Item|Product|Description)[:\s]+([^\r\n<]+)', caseSensitive: false).firstMatch(body);

      if (itemMatch != null) {
        var item = itemMatch.group(1)!.trim();
        // Remove trailing cycle descriptors like (Monthly), (Yearly), (1 Month), (100 GB)
        item = item.replaceAll(
          RegExp(
            r'\s*\((?:monthly|yearly|annual|1\s*month|3\s*months|1\s*year|quarterly|auto-renewing|tier\s*\d+)[^)]*\)',
            caseSensitive: false,
          ),
          '',
        );
        item = item.replaceAll(
          RegExp(r'\s*[-–]\s*(?:monthly|yearly|annual|1\s*month|1\s*year)\b', caseSensitive: false),
          '',
        );
        item = item.trim();
        if (item.isNotEmpty) {
          return _bankService.normalizeMerchant(item);
        }
      }

      // 2. Look for "You've subscribed to <Item>"
      final subscribedMatch = RegExp(
        r"(?:you(?:’|'|\s)ve\s+subscribed\s+to|subscribed\s+to)\s+([^,\r\n<]+?)(?:\s+on\s+google\s+play|\s+from|\.|\n|$)",
        caseSensitive: false,
      ).firstMatch(body);

      if (subscribedMatch != null) {
        final item = subscribedMatch.group(1)!.trim();
        if (item.isNotEmpty) {
          return _bankService.normalizeMerchant(item);
        }
      }

      // 3. Known Google first-party subscription checks
      final combined = '$subject $body'.toLowerCase();
      if (combined.contains('youtube premium')) return 'YouTube Premium';
      if (combined.contains('youtube music')) return 'YouTube Music';
      if (combined.contains('google one')) return 'Google One';
      if (combined.contains('google workspace')) return 'Google Workspace';
      if (combined.contains('google play pass')) return 'Google Play Pass';
    }

    final raw = from.trim();
    // Format: "Netflix <info@mailer.netflix.com>"
    final displayMatch = RegExp(r'^"?([^"<]+)"?\s*<.*>$').firstMatch(raw);
    if (displayMatch != null) {
      final name = displayMatch.group(1)!.trim();
      if (name.isNotEmpty && !name.toLowerCase().contains('no-reply') && !name.toLowerCase().contains('noreply')) {
        return _bankService.normalizeMerchant(name);
      }
    }

    // From email domain: "support@spotify.com"
    final emailMatch = RegExp(r'<([^>]+)>|([a-zA-Z0-9_\.\-]+@[a-zA-Z0-9_\.\-]+)').firstMatch(raw);
    if (emailMatch != null) {
      final email = (emailMatch.group(1) ?? emailMatch.group(2) ?? '').toLowerCase();
      final domainMatch = RegExp(r'@(?:mailer\.|mail\.|news\.|account\.)?([a-zA-Z0-9\-]+)\.').firstMatch(email);
      if (domainMatch != null) {
        final brand = domainMatch.group(1)!;
        if (!['gmail', 'googlemail', 'yahoo', 'hotmail', 'outlook', 'proton'].contains(brand)) {
          return _bankService.normalizeMerchant(brand);
        }
      }
    }

    return _bankService.normalizeMerchant(subject);
  }

  /// Extracts Money from email text.
  Money? extractAmount(String text) {
    // Priority: INR, USD, EUR, GBP
    // Match ₹649 or ₹ 649.00 or INR 649 or 649.00 INR
    final inrMatch = RegExp(
      r'(?:₹|INR|Rs\.?)\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)|([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:INR|Rs\.?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (inrMatch != null) {
      final rawNum = (inrMatch.group(1) ?? inrMatch.group(2))!.replaceAll(',', '');
      final val = double.tryParse(rawNum);
      if (val != null && val > 0) {
        return Money(minorUnits: (val * 100).round(), currencyCode: 'INR');
      }
    }

    // Match $15.99 or USD 15.99
    final usdMatch = RegExp(
      r'(?:\$|USD)\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (usdMatch != null) {
      final rawNum = usdMatch.group(1)!.replaceAll(',', '');
      final val = double.tryParse(rawNum);
      if (val != null && val > 0) {
        return Money(minorUnits: (val * 100).round(), currencyCode: 'USD');
      }
    }

    // Match €9.99 or EUR 9.99
    final eurMatch = RegExp(
      r'(?:€|EUR)\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (eurMatch != null) {
      final rawNum = eurMatch.group(1)!.replaceAll(',', '');
      final val = double.tryParse(rawNum);
      if (val != null && val > 0) {
        return Money(minorUnits: (val * 100).round(), currencyCode: 'EUR');
      }
    }

    // Match £8.99 or GBP 8.99
    final gbpMatch = RegExp(
      r'(?:£|GBP)\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (gbpMatch != null) {
      final rawNum = gbpMatch.group(1)!.replaceAll(',', '');
      final val = double.tryParse(rawNum);
      if (val != null && val > 0) {
        return Money(minorUnits: (val * 100).round(), currencyCode: 'GBP');
      }
    }

    return null;
  }

  /// Extracts BillingCycle from text.
  BillingCycle? extractBillingCycle(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'\b(?:per\s*month|monthly|/month|/mo|\(monthly\))\b').hasMatch(lower)) {
      return BillingCycle.monthly;
    }
    if (RegExp(r'\b(?:per\s*year|annually|yearly|annual|/year|/yr|\(yearly\)|\(annual\))\b').hasMatch(lower)) {
      return BillingCycle.yearly;
    }
    if (RegExp(r'\b(?:per\s*quarter|quarterly|every\s*3\s*months|\(quarterly\))\b').hasMatch(lower)) {
      return BillingCycle.quarterly;
    }
    if (RegExp(r'\b(?:per\s*week|weekly|/week|/wk|\(weekly\))\b').hasMatch(lower)) {
      return BillingCycle.weekly;
    }
    return null;
  }

  /// Extracts explicit next renewal date from text if available.
  DateTime? extractExplicitRenewalDate(String text) {
    // Look for explicit date phrases like "renews on 15 Dec 2026", "automatically renews on Dec 15, 2026", "next billing date: 2027-06-01"
    final dateMatch = RegExp(
      r'(?:automatically\s*renews\s*on|will\s*automatically\s*renew\s*on|renews\s*on|next\s*billing\s*date|next\s*payment(?:\s*date)?|next\s*charge(?:\s*on)?|renewal\s*date|valid\s*until|expiry\s*date|renews)[:\s]+(\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{4}|\d{1,2}\s+[A-Za-z]{3,9},?\s+\d{4}|[A-Za-z]{3,9}\s+\d{1,2},?\s+\d{4})',
      caseSensitive: false,
    ).firstMatch(text);

    if (dateMatch != null) {
      final rawDate = dateMatch.group(1)!.trim();
      final parsed = tryParseFlexibleDate(rawDate);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  /// Estimates renewal date from payment date and cycle.
  DateTime? estimateRenewalDate(DateTime emailDate, BillingCycle? cycle) {
    if (cycle != null) {
      return switch (cycle) {
        BillingCycle.weekly => emailDate.add(const Duration(days: 7)),
        BillingCycle.monthly => DateTime(emailDate.year, emailDate.month + 1, emailDate.day),
        BillingCycle.quarterly => DateTime(emailDate.year, emailDate.month + 3, emailDate.day),
        BillingCycle.yearly => DateTime(emailDate.year + 1, emailDate.month, emailDate.day),
      };
    }
    return null;
  }

  /// Extracts or estimates next renewal date from text or cycle.
  DateTime? extractNextRenewalDate(String text, DateTime emailDate, BillingCycle? cycle) {
    final explicitDate = extractExplicitRenewalDate(text);
    if (explicitDate != null) {
      return explicitDate;
    }
    return estimateRenewalDate(emailDate, cycle);
  }

  /// Parses an individual message into an ExtractedEmailSubscription if applicable.
  ExtractedEmailSubscription? parseMessage(GmailRawMessage message) {
    final subject = message.subject ?? '';
    final from = message.from ?? '';
    final body = message.plainTextBody ?? (message.htmlBody != null ? stripHtml(message.htmlBody!) : message.snippet);

    final eventType = classifyEventType(subject: subject, body: body);

    // Rule: Do not create subscriptions from cancellations or refunds!
    if (eventType == GmailEventType.cancellation || eventType == GmailEventType.refund) {
      return null;
    }

    final merchantName = extractMerchantName(from: from, subject: subject, body: body);
    if (merchantName.isEmpty) {
      return null;
    }

    final fullText = '$subject $body';
    final amount = extractAmount(fullText);
    final cycle = extractBillingCycle(fullText) ?? BillingCycle.monthly;

    DateTime emailDate = DateTime.now();
    if (message.dateHeader != null) {
      final rawDateHeader = message.dateHeader!;
      final parsed = tryParseFlexibleDate(rawDateHeader);
      if (parsed != null) {
        emailDate = parsed;
      } else {
        // Try extracting "15 Nov 2026" or "Nov 15 2026" from RFC-2822 headers like "Wed, 15 Nov 2026 10:14:00 +0000"
        final subMatch = RegExp(r'(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})').firstMatch(rawDateHeader);
        if (subMatch != null) {
          final subParsed = tryParseFlexibleDate(subMatch.group(1)!);
          if (subParsed != null) {
            emailDate = subParsed;
          }
        }
      }
    }

    final explicitRenewal = extractExplicitRenewalDate(fullText);
    final renewalDate = explicitRenewal ?? estimateRenewalDate(emailDate, cycle);
    final isEstimated = explicitRenewal == null;

    // Calculate confidence score
    var confidence = 0.50;
    if (amount != null) confidence += 0.20;
    if (eventType == GmailEventType.subscriptionRenewal || eventType == GmailEventType.subscriptionStarted) {
      confidence += 0.15;
    }
    if (fullText.toLowerCase().contains('subscription') || fullText.toLowerCase().contains('membership')) {
      confidence += 0.10;
    }

    return ExtractedEmailSubscription(
      messageId: message.id,
      merchantName: merchantName,
      eventType: eventType,
      amount: amount,
      billingCycle: cycle,
      paymentDate: emailDate,
      nextRenewalDate: renewalDate,
      renewalDateIsEstimated: isEstimated,
      sender: from,
      subject: subject,
      snippet: message.snippet.isNotEmpty ? message.snippet : subject,
      confidenceScore: double.parse(confidence.clamp(0.0, 1.0).toStringAsFixed(2)),
    );
  }

  /// Converts extracted email subscriptions to DetectedSubscriptionCandidates.
  List<DetectedSubscriptionCandidate> processMessages({
    required List<GmailRawMessage> messages,
    required List<RegistrySubscription> existingSubscriptions,
    required DateTime Function() now,
    Set<String> ignoredMerchants = const {},
    String Function(int index)? idGenerator,
  }) {
    final groups = <String, List<ExtractedEmailSubscription>>{};

    for (final message in messages) {
      final extracted = parseMessage(message);
      if (extracted == null) {
        continue;
      }

      final lowerMerchant = extracted.merchantName.toLowerCase();
      // Suppression check
      if (ignoredMerchants.any(
        (ignored) => lowerMerchant == ignored.toLowerCase() || lowerMerchant.contains(ignored.toLowerCase()),
      )) {
        continue;
      }

      final key = '$lowerMerchant|${extracted.amount?.code ?? "DEFAULT"}';
      groups.putIfAbsent(key, () => []).add(extracted);
    }

    final candidates = <DetectedSubscriptionCandidate>[];
    var candidateIndex = 0;

    for (final entry in groups.entries) {
      final group = entry.value;
      if (group.isEmpty) continue;

      group.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
      final latest = group.last;

      if (latest.amount == null) {
        // If no amount was detected across group, skip creating an empty subscription candidate
        continue;
      }

      final duplicate = existingSubscriptions.any(
        (sub) =>
            _bankService.normalizeMerchant(sub.serviceName).toLowerCase() == latest.merchantName.toLowerCase() &&
            sub.amount.code == latest.amount!.code,
      );

      final emailEvidenceList = group
          .map(
            (e) => EmailEvidence(
              messageId: e.messageId,
              subject: e.subject,
              sender: e.sender,
              date: e.paymentDate,
              snippet: e.snippet,
            ),
          )
          .toList();

      final candidateId = idGenerator != null
          ? idGenerator(candidateIndex++)
          : 'gmail_cand_${now().microsecondsSinceEpoch}_${candidateIndex++}';

      // Higher count of emails boosts confidence
      var score = latest.confidenceScore;
      if (group.length >= 2) {
        score = (score + 0.15).clamp(0.0, 1.0);
      }

      candidates.add(
        DetectedSubscriptionCandidate(
          id: candidateId,
          merchantName: latest.merchantName,
          amount: latest.amount!,
          billingCycle: latest.billingCycle ?? BillingCycle.monthly,
          lastPaymentDate: latest.paymentDate,
          nextPaymentDate: latest.nextRenewalDate,
          nextPaymentIsEstimated: latest.renewalDateIsEstimated,
          sourceTypes: {DetectionSource.gmail},
          confidenceScore: double.parse(score.toStringAsFixed(2)),
          reviewStatus: DetectionReviewStatus.pendingReview,
          emailEvidence: emailEvidenceList,
          createdAt: now(),
          possibleDuplicate: duplicate,
        ),
      );
    }

    return candidates;
  }
}
