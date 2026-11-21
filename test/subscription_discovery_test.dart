import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/subscriptions/data/detected_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/detected_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_discovery_service.dart';

void main() {
  late InMemoryDetectedSubscriptionRepository detectedRepo;
  late InMemorySubscriptionRepository subscriptionRepo;
  late SubscriptionDiscoveryService discoveryService;
  final now = DateTime(2026, 11, 17, 12, 0);

  setUp(() {
    detectedRepo = InMemoryDetectedSubscriptionRepository();
    subscriptionRepo = InMemorySubscriptionRepository();
    discoveryService = SubscriptionDiscoveryService(
      detectedRepository: detectedRepo,
      subscriptionRepository: subscriptionRepo,
    );
  });

  group('SubscriptionDiscoveryService Cross-Source Merging & Deduplication', () {
    test('merges Bank statement and Gmail candidates for Netflix into ONE candidate with combined evidence', () async {
      final bankCandidate = DetectedSubscriptionCandidate(
        id: 'bank_cand_1',
        merchantName: 'NETFLIX.COM',
        amount: const Money(minorUnits: 649, currencyCode: 'INR'),
        billingCycle: BillingCycle.monthly,
        lastPaymentDate: DateTime(2026, 10, 5),
        nextPaymentDate: DateTime(2026, 11, 5),
        nextPaymentIsEstimated: true,
        sourceTypes: {DetectionSource.bankStatement},
        confidenceScore: 0.80,
        bankEvidence: [
          BankTransactionEvidence(
            lineNumber: 12,
            date: DateTime(2026, 10, 5),
            originalDescription: 'NETFLIX.COM',
            amount: const Money(minorUnits: 649, currencyCode: 'INR'),
          ),
        ],
        createdAt: DateTime(2026, 10, 5),
      );

      final gmailCandidate = DetectedSubscriptionCandidate(
        id: 'gmail_cand_1',
        merchantName: 'Netflix',
        amount: const Money(minorUnits: 649, currencyCode: 'INR'),
        billingCycle: BillingCycle.monthly,
        lastPaymentDate: DateTime(2026, 11, 5),
        nextPaymentDate: DateTime(2026, 12, 5),
        nextPaymentIsEstimated: false,
        sourceTypes: {DetectionSource.gmail},
        confidenceScore: 0.85,
        emailEvidence: [
          EmailEvidence(
            messageId: 'msg_netflix_nov',
            subject: 'Your Netflix payment confirmation',
            sender: 'Netflix <info@mailer.netflix.com>',
            date: DateTime(2026, 11, 5),
          ),
        ],
        createdAt: DateTime(2026, 11, 5),
      );

      // Ingest Bank candidate first
      await discoveryService.mergeAndIngestCandidates([bankCandidate], now: () => now);
      expect(discoveryService.pendingCandidates.length, 1);
      expect(discoveryService.pendingCandidates.first.sourceTypes, {DetectionSource.bankStatement});

      // Now ingest Gmail candidate
      await discoveryService.mergeAndIngestCandidates([gmailCandidate], now: () => now);

      // Should still be exactly ONE candidate!
      expect(discoveryService.pendingCandidates.length, 1);
      final merged = discoveryService.pendingCandidates.first;
      expect(merged.merchantName, 'NETFLIX.COM');
      expect(merged.sourceTypes, {DetectionSource.bankStatement, DetectionSource.gmail});
      expect(merged.bankEvidence.length, 1);
      expect(merged.emailEvidence.length, 1);
      expect(merged.lastPaymentDate, DateTime(2026, 11, 5));
      expect(merged.nextPaymentDate, DateTime(2026, 12, 5));
      expect(merged.nextPaymentIsEstimated, isFalse);
      expect(merged.confidenceScore, greaterThanOrEqualTo(0.95));
    });

    test('handles price change for same merchant gracefully', () async {
      final bankCandidate = DetectedSubscriptionCandidate(
        id: 'bank_sub_price_old',
        merchantName: 'Spotify',
        amount: const Money(minorUnits: 119, currencyCode: 'INR'),
        billingCycle: BillingCycle.monthly,
        lastPaymentDate: DateTime(2026, 9, 10),
        sourceTypes: {DetectionSource.bankStatement},
        confidenceScore: 0.75,
        createdAt: DateTime(2026, 9, 10),
      );

      final gmailCandidate = DetectedSubscriptionCandidate(
        id: 'gmail_sub_price_new',
        merchantName: 'Spotify',
        amount: const Money(minorUnits: 139, currencyCode: 'INR'), // price increased
        billingCycle: BillingCycle.monthly,
        lastPaymentDate: DateTime(2026, 10, 10),
        sourceTypes: {DetectionSource.gmail},
        confidenceScore: 0.80,
        createdAt: DateTime(2026, 10, 10),
      );

      await discoveryService.mergeAndIngestCandidates([bankCandidate], now: () => now);
      await discoveryService.mergeAndIngestCandidates([gmailCandidate], now: () => now);

      expect(discoveryService.pendingCandidates.length, 1);
      final merged = discoveryService.pendingCandidates.first;
      // Retains newer amount
      expect(merged.amount.minorUnits, 139);
      expect(merged.sourceTypes.length, 2);
    });

    test('bank-only and gmail-only candidates persist independently', () async {
      final bankOnly = DetectedSubscriptionCandidate(
        id: 'bank_only',
        merchantName: 'Apple iCloud',
        amount: const Money(minorUnits: 75, currencyCode: 'INR'),
        billingCycle: BillingCycle.monthly,
        lastPaymentDate: DateTime(2026, 11, 1),
        sourceTypes: {DetectionSource.bankStatement},
        confidenceScore: 0.80,
        createdAt: DateTime(2026, 11, 1),
      );

      final gmailOnly = DetectedSubscriptionCandidate(
        id: 'gmail_only',
        merchantName: 'ChatGPT Plus',
        amount: const Money(minorUnits: 2000, currencyCode: 'USD'),
        billingCycle: BillingCycle.monthly,
        lastPaymentDate: DateTime(2026, 11, 2),
        sourceTypes: {DetectionSource.gmail},
        confidenceScore: 0.85,
        createdAt: DateTime(2026, 11, 2),
      );

      await discoveryService.mergeAndIngestCandidates([bankOnly, gmailOnly], now: () => now);

      expect(discoveryService.pendingCandidates.length, 2);
    });

    test('suppression preference marks merchant as ignored and suppresses new detections', () async {
      final candidate = DetectedSubscriptionCandidate(
        id: 'cand_gym',
        merchantName: 'Gold Gym',
        amount: const Money(minorUnits: 3000, currencyCode: 'INR'),
        billingCycle: BillingCycle.monthly,
        lastPaymentDate: DateTime(2026, 11, 1),
        sourceTypes: {DetectionSource.bankStatement},
        confidenceScore: 0.80,
        createdAt: DateTime(2026, 11, 1),
      );

      await discoveryService.mergeAndIngestCandidates([candidate], now: () => now);
      expect(discoveryService.pendingCandidates.length, 1);

      // User marks as "Not a Subscription"
      await discoveryService.ignoreCandidate('cand_gym');
      expect(discoveryService.pendingCandidates, isEmpty);
      expect(discoveryService.ignoredMerchants.contains('gold gym'), isTrue);

      // Subsequent scan with Gold Gym is suppressed
      await discoveryService.mergeAndIngestCandidates([candidate], now: () => now);
      expect(discoveryService.pendingCandidates, isEmpty);
    });

    test('acceptCandidate marks reviewStatus as accepted', () async {
      final candidate = DetectedSubscriptionCandidate(
        id: 'cand_sub_1',
        merchantName: 'Notion',
        amount: const Money(minorUnits: 1000, currencyCode: 'USD'),
        billingCycle: BillingCycle.monthly,
        lastPaymentDate: DateTime(2026, 11, 1),
        sourceTypes: {DetectionSource.gmail},
        confidenceScore: 0.80,
        createdAt: DateTime(2026, 11, 1),
      );

      await discoveryService.mergeAndIngestCandidates([candidate], now: () => now);
      expect(discoveryService.pendingCandidates.length, 1);

      await discoveryService.acceptCandidate('cand_sub_1');
      expect(discoveryService.pendingCandidates, isEmpty);
      expect(discoveryService.allCandidates.first.reviewStatus, DetectionReviewStatus.accepted);
    });
  });
}

