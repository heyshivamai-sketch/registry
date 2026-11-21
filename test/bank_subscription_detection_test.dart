import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/domain/bank_subscription_detection_service.dart';
import 'package:the_registry/features/subscriptions/domain/detected_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

void main() {
  late BankSubscriptionDetectionService service;
  final now = DateTime(2026, 11, 17, 12, 0);

  setUp(() {
    service = const BankSubscriptionDetectionService();
  });

  group('BankSubscriptionDetectionService Merchant Normalization', () {
    test('normalizes complex merchant aliases to brand name', () {
      expect(service.normalizeMerchant('NETFLIX.COM'), 'Netflix');
      expect(service.normalizeMerchant('NETFLIX INDIA'), 'Netflix');
      expect(service.normalizeMerchant('NETFLIX PAYMENT'), 'Netflix');
      expect(service.normalizeMerchant('RAZORPAY*NETFLIX'), 'Netflix');
      expect(service.normalizeMerchant('UPI/netflix/1234@okaxis'), 'Netflix');
      expect(service.normalizeMerchant('SPOTIFY INDIA PVT LTD'), 'Spotify');
      expect(service.normalizeMerchant('GOOGLE*YOUTUBE PREMIUM'), 'Youtube Premium');
      expect(service.normalizeMerchant('APPLE.COM/BILL'), 'Apple');
    });
  });

  group('BankSubscriptionDetectionService False-Positive Filtering', () {
    test('identifies rent, electricity, groceries, and loans as false positives', () {
      expect(service.isFalsePositive('HOUSE RENT PAYMENT TO LANDLORD'), isTrue);
      expect(service.isFalsePositive('BESCOM ELECTRICITY BILL 2026'), isTrue);
      expect(service.isFalsePositive('BLINKIT GROCERY PURCHASE'), isTrue);
      expect(service.isFalsePositive('ZEPTO ONLINE STORE'), isTrue);
      expect(service.isFalsePositive('BAJAJ FINANCE EMI DEDUCTION'), isTrue);
      expect(service.isFalsePositive('HDFC HOME LOAN EMI'), isTrue);
      expect(service.isFalsePositive('CRED CLUB CREDIT CARD PAYMENT'), isTrue);
      expect(service.isFalsePositive('SELF TRANSFER TO SAVINGS'), isTrue);
      expect(service.isFalsePositive('NETFLIX.COM MONTHLY'), isFalse);
      expect(service.isFalsePositive('SPOTIFY PREMIUM'), isFalse);
    });
  });

  group('BankSubscriptionDetectionService Recurring Pattern Detection', () {
    test('detects monthly Netflix subscription from 3 consistent payments', () {
      final transactions = [
        BankTransaction(
          lineNumber: 1,
          date: DateTime(2026, 9, 5),
          description: 'NETFLIX.COM',
          amount: const Money(minorUnits: 649, currencyCode: 'INR'),
        ),
        BankTransaction(
          lineNumber: 2,
          date: DateTime(2026, 10, 5),
          description: 'NETFLIX INDIA',
          amount: const Money(minorUnits: 649, currencyCode: 'INR'),
        ),
        BankTransaction(
          lineNumber: 3,
          date: DateTime(2026, 11, 5),
          description: 'NETFLIX PAYMENT',
          amount: const Money(minorUnits: 649, currencyCode: 'INR'),
        ),
      ];

      final candidates = service.detectSubscriptions(
        transactions: transactions,
        existingSubscriptions: const [],
        now: () => now,
      );

      expect(candidates.length, 1);
      final candidate = candidates.first;
      expect(candidate.merchantName, 'Netflix');
      expect(candidate.amount.minorUnits, 649);
      expect(candidate.amount.code, 'INR');
      expect(candidate.billingCycle, BillingCycle.monthly);
      expect(candidate.lastPaymentDate, DateTime(2026, 11, 5));
      expect(candidate.nextPaymentDate, DateTime(2026, 12, 5));
      expect(candidate.nextPaymentIsEstimated, isTrue);
      expect(candidate.confidence, DetectionConfidence.high);
      expect(candidate.bankEvidence.length, 3);
    });

    test('detects quarterly and yearly subscriptions', () {
      final quarterlyTxns = [
        BankTransaction(
          lineNumber: 10,
          date: DateTime(2026, 1, 15),
          description: 'PlayStation Plus Quarterly',
          amount: const Money(minorUnits: 1999, currencyCode: 'INR'),
        ),
        BankTransaction(
          lineNumber: 11,
          date: DateTime(2026, 4, 16),
          description: 'PlayStation Plus Quarterly',
          amount: const Money(minorUnits: 1999, currencyCode: 'INR'),
        ),
        BankTransaction(
          lineNumber: 12,
          date: DateTime(2026, 7, 16),
          description: 'PlayStation Plus Quarterly',
          amount: const Money(minorUnits: 1999, currencyCode: 'INR'),
        ),
      ];

      final quarterlyCandidates = service.detectSubscriptions(
        transactions: quarterlyTxns,
        existingSubscriptions: const [],
        now: () => now,
      );
      expect(quarterlyCandidates.length, 1);
      expect(quarterlyCandidates.first.billingCycle, BillingCycle.quarterly);

      final yearlyTxns = [
        BankTransaction(
          lineNumber: 20,
          date: DateTime(2024, 11, 10),
          description: 'Amazon Prime Annual',
          amount: const Money(minorUnits: 1499, currencyCode: 'INR'),
        ),
        BankTransaction(
          lineNumber: 21,
          date: DateTime(2025, 11, 10),
          description: 'Amazon Prime Annual',
          amount: const Money(minorUnits: 1499, currencyCode: 'INR'),
        ),
      ];

      final yearlyCandidates = service.detectSubscriptions(
        transactions: yearlyTxns,
        existingSubscriptions: const [],
        now: () => now,
      );
      expect(yearlyCandidates.length, 1);
      expect(yearlyCandidates.first.billingCycle, BillingCycle.yearly);
    });

    test('single payment does not become a subscription candidate', () {
      final transactions = [
        BankTransaction(
          lineNumber: 1,
          date: DateTime(2026, 10, 5),
          description: 'ONE TIME PURCHASE',
          amount: const Money(minorUnits: 500, currencyCode: 'USD'),
        ),
      ];

      final candidates = service.detectSubscriptions(
        transactions: transactions,
        existingSubscriptions: const [],
        now: () => now,
      );

      expect(candidates, isEmpty);
    });

    test('credit/deposit transactions are excluded from subscription detection', () {
      final transactions = [
        BankTransaction(
          lineNumber: 1,
          date: DateTime(2026, 9, 1),
          description: 'SALARY CREDIT COMPANY XYZ',
          amount: const Money(minorUnits: 100000, currencyCode: 'USD'),
          direction: TransactionDirection.credit,
        ),
        BankTransaction(
          lineNumber: 2,
          date: DateTime(2026, 10, 1),
          description: 'SALARY CREDIT COMPANY XYZ',
          amount: const Money(minorUnits: 100000, currencyCode: 'USD'),
          direction: TransactionDirection.credit,
        ),
      ];

      final candidates = service.detectSubscriptions(
        transactions: transactions,
        existingSubscriptions: const [],
        now: () => now,
      );

      expect(candidates, isEmpty);
    });

    test('suppresses merchants present in ignoredMerchants', () {
      final transactions = [
        BankTransaction(
          lineNumber: 1,
          date: DateTime(2026, 9, 5),
          description: 'GYM MEMBERSHIP',
          amount: const Money(minorUnits: 2000, currencyCode: 'INR'),
        ),
        BankTransaction(
          lineNumber: 2,
          date: DateTime(2026, 10, 5),
          description: 'GYM MEMBERSHIP',
          amount: const Money(minorUnits: 2000, currencyCode: 'INR'),
        ),
      ];

      final candidates = service.detectSubscriptions(
        transactions: transactions,
        existingSubscriptions: const [],
        ignoredMerchants: {'gym'},
        now: () => now,
      );

      expect(candidates, isEmpty);
    });

    test('flags candidate as possibleDuplicate if already in existingSubscriptions', () {
      final existingSub = RegistrySubscription(
        id: 'sub_existing_1',
        createdAt: DateTime(2026, 1, 1),
        serviceName: 'Netflix',
        category: SubscriptionCategory.entertainment,
        amount: const Money(minorUnits: 649, currencyCode: 'INR'),
        billingCycle: BillingCycle.monthly,
        nextPaymentDate: DateTime(2026, 12, 5),
        autoRenew: true,
        lifecycle: SubscriptionLifecycle.active,
        impact: DocumentImpact.medium,
      );

      final transactions = [
        BankTransaction(
          lineNumber: 1,
          date: DateTime(2026, 9, 5),
          description: 'NETFLIX.COM',
          amount: const Money(minorUnits: 649, currencyCode: 'INR'),
        ),
        BankTransaction(
          lineNumber: 2,
          date: DateTime(2026, 10, 5),
          description: 'NETFLIX.COM',
          amount: const Money(minorUnits: 649, currencyCode: 'INR'),
        ),
      ];

      final candidates = service.detectSubscriptions(
        transactions: transactions,
        existingSubscriptions: [existingSub],
        now: () => now,
      );

      expect(candidates.length, 1);
      expect(candidates.first.possibleDuplicate, isTrue);
    });
  });
}