import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/subscriptions/domain/detected_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/gmail_subscription_detection_service.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

void main() {
  late GmailSubscriptionDetectionService service;
  final now = DateTime(2026, 11, 17, 12, 0);

  setUp(() {
    service = GmailSubscriptionDetectionService();
  });

  group('GmailSubscriptionDetectionService Event Classification & Extraction', () {
    test('extracts monthly Netflix subscription from payment confirmation email', () {
      const message = GmailRawMessage(
        id: 'msg_netflix_1',
        headers: {
          'From': 'Netflix <info@mailer.netflix.com>',
          'Subject': 'Your Netflix payment confirmation',
          'Date': '2026-11-05T10:00:00Z',
        },
        snippet: 'We have received your payment of ₹649 for your monthly membership.',
        plainTextBody: 'Hi Rishi, Thank you for streaming. Your monthly subscription of ₹649 was successfully charged.',
      );

      final extracted = service.parseMessage(message);
      expect(extracted, isNotNull);
      expect(extracted!.merchantName, 'Netflix');
      expect(extracted.eventType, GmailEventType.paymentSuccess);
      expect(extracted.amount?.minorUnits, 64900);
      expect(extracted.amount?.code, 'INR');
      expect(extracted.billingCycle, BillingCycle.monthly);
      expect(extracted.renewalDateIsEstimated, isTrue);
    });

    test('extracts Google Play subscription from order receipt with refund policy in footer', () {
      const message = GmailRawMessage(
        id: 'msg_gplay_sub_1',
        headers: {
          'From': 'Google Play <googleplay-noreply@google.com>',
          'Subject': 'Your Google Play order receipt from 15 Nov 2026',
          'Date': '15 Nov 2026 10:00:00 GMT',
        },
        snippet: "Thank you. You've subscribed to Truecaller Premium (Monthly) from Truecaller.",
        plainTextBody: '''
Google Play
Order date: 15 Nov 2026
Order number: GPA.3344-5566-7788-99000
Item: Truecaller Premium (Monthly)
Price: ₹529.00/month
Payment method: UPI
Your subscription will automatically renew on 15 Dec 2026 and you will be charged ₹529.00 plus applicable taxes.
Questions? Visit Google Play Help.
View the Google Play refund policy and Terms of Service.
Need to request a refund? You can request a refund within 48 hours.
''',
      );

      final extracted = service.parseMessage(message);
      expect(extracted, isNotNull);
      expect(extracted!.merchantName, 'Truecaller Premium');
      expect(extracted.amount?.minorUnits, 52900);
      expect(extracted.amount?.code, 'INR');
      expect(extracted.billingCycle, BillingCycle.monthly);
      expect(extracted.nextRenewalDate, DateTime(2026, 12, 15));
      expect(extracted.renewalDateIsEstimated, isFalse);
    });

    test('extracts Google One subscription from receipt email', () {
      const message = GmailRawMessage(
        id: 'msg_gone_1',
        headers: {
          'From': 'Google One <googleone-noreply@google.com>',
          'Subject': 'Your Google One receipt',
          'Date': '2026-11-15T00:00:00Z',
        },
        snippet: 'Google One (100 GB) monthly plan receipt',
        plainTextBody: '''
Google One (100 GB)
Monthly plan: ₹130.00
Automatically renews on Dec 15, 2026.
View refund policy.
''',
      );

      final extracted = service.parseMessage(message);
      expect(extracted, isNotNull);
      expect(extracted!.merchantName, 'Google One');
      expect(extracted.amount?.minorUnits, 13000);
      expect(extracted.amount?.code, 'INR');
      expect(extracted.billingCycle, BillingCycle.monthly);
      expect(extracted.nextRenewalDate, DateTime(2026, 12, 15));
      expect(extracted.renewalDateIsEstimated, isFalse);
    });

    test('extracts YouTube Premium membership from Google Payments receipt', () {
      const message = GmailRawMessage(
        id: 'msg_yt_1',
        headers: {
          'From': 'Google Payments <googlepayments-noreply@google.com>',
          'Subject': 'Your receipt for YouTube Premium',
          'Date': '2026-11-15T00:00:00Z',
        },
        snippet: 'YouTube Premium monthly membership: ₹149.00',
        plainTextBody: '''
YouTube Premium
Monthly membership: ₹149.00
Next billing date: 15 Dec 2026
Learn more about our refund policy.
''',
      );

      final extracted = service.parseMessage(message);
      expect(extracted, isNotNull);
      expect(extracted!.merchantName, 'YouTube Premium');
      expect(extracted.amount?.minorUnits, 14900);
      expect(extracted.amount?.code, 'INR');
      expect(extracted.billingCycle, BillingCycle.monthly);
      expect(extracted.nextRenewalDate, DateTime(2026, 12, 15));
      expect(extracted.renewalDateIsEstimated, isFalse);
    });

    test('extracts Spotify subscription from HTML email with base64 encoded content', () {
      const html = r'<html><body><h1>Your receipt</h1><p>Spotify Premium monthly plan: $10.99 billed on your card.</p></body></html>';

      final message = GmailRawMessage(
        id: 'msg_spotify_1',
        headers: const {
          'From': 'Spotify <no-reply@spotify.com>',
          'Subject': 'Your Spotify receipt',
          'Date': '2026-10-15T08:00:00Z',
        },
        snippet: 'Receipt for Spotify Premium',
        htmlBody: html,
      );

      final extracted = service.parseMessage(message);
      expect(extracted, isNotNull);
      expect(extracted!.merchantName, 'Spotify');
      expect(extracted.amount?.minorUnits, 1099);
      expect(extracted.amount?.code, 'USD');
      expect(extracted.billingCycle, BillingCycle.monthly);
    });

    test('extracts annual subscription and explicit renewal date', () {
      const message = GmailRawMessage(
        id: 'msg_aws_1',
        headers: {
          'From': 'Amazon Web Services <aws-billing@amazon.com>',
          'Subject': 'AWS Annual Plan Subscription Renewal',
          'Date': '2026-06-01T00:00:00Z',
        },
        snippet: r'Your annual plan has renewed for $120.00. Next billing date: 2027-06-01.',
        plainTextBody: r'Your annual plan has renewed for $120.00. Next billing date: 2027-06-01.',
      );

      final extracted = service.parseMessage(message);
      expect(extracted, isNotNull);
      expect(extracted!.eventType, GmailEventType.subscriptionRenewal);
      expect(extracted.amount?.minorUnits, 12000);
      expect(extracted.amount?.code, 'USD');
      expect(extracted.billingCycle, BillingCycle.yearly);
      expect(extracted.nextRenewalDate, DateTime(2027, 6, 1));
    });

    test('cancellation email returns null and does NOT create a subscription candidate', () {
      const message = GmailRawMessage(
        id: 'msg_cancel_1',
        headers: {
          'From': 'Disney Plus <billing@disneyplus.com>',
          'Subject': 'Your subscription cancellation confirmation',
          'Date': '2026-11-01T12:00:00Z',
        },
        snippet: 'You have cancelled your Disney+ membership.',
        plainTextBody: 'Your Disney+ membership has been cancelled. You will not be charged again.',
      );

      final extracted = service.parseMessage(message);
      expect(extracted, isNull);
    });

    test('refund email returns null and does NOT create a subscription candidate', () {
      const message = GmailRawMessage(
        id: 'msg_refund_1',
        headers: {
          'From': 'Google Play <googleplay-noreply@google.com>',
          'Subject': 'Your Google Play refund has been approved',
          'Date': '2026-11-02T14:00:00Z',
        },
        snippet: r'We refunded $4.99 to your credit card.',
        plainTextBody: r'We have processed your refund of $4.99. The credit will reflect in 3-5 days.',
      );

      final extracted = service.parseMessage(message);
      expect(extracted, isNull);
    });

    test('free trial email extracts trial started event', () {
      const message = GmailRawMessage(
        id: 'msg_trial_1',
        headers: {
          'From': 'Audible <members@audible.com>',
          'Subject': 'Welcome to your 30-day Free Trial',
          'Date': '2026-11-10T11:00:00Z',
        },
        snippet: r'Your 30-day free trial has started. Monthly membership is $14.95 after trial.',
        plainTextBody: r'Enjoy your free trial! After 30 days, your subscription will renew at $14.95 per month.',
      );

      final extracted = service.parseMessage(message);
      expect(extracted, isNotNull);
      expect(extracted!.eventType, GmailEventType.trialStarted);
      expect(extracted.amount?.minorUnits, 1495);
      expect(extracted.amount?.code, 'USD');
      expect(extracted.billingCycle, BillingCycle.monthly);
    });

    test('processMessages groups multiple emails for same merchant and boosts confidence', () {
      final messages = [
        const GmailRawMessage(
          id: 'msg_1',
          headers: {
            'From': 'GitHub <support@github.com>',
            'Subject': 'GitHub Pro receipt',
            'Date': '2026-09-10T00:00:00Z',
          },
          plainTextBody: r'GitHub Pro subscription: $4.00 per month charged.',
        ),
        const GmailRawMessage(
          id: 'msg_2',
          headers: {
            'From': 'GitHub <support@github.com>',
            'Subject': 'GitHub Pro receipt',
            'Date': '2026-10-10T00:00:00Z',
          },
          plainTextBody: r'GitHub Pro subscription: $4.00 per month charged.',
        ),
      ];

      final candidates = service.processMessages(
        messages: messages,
        existingSubscriptions: const [],
        now: () => now,
      );

      expect(candidates.length, 1);
      final candidate = candidates.first;
      expect(candidate.merchantName, 'Github');
      expect(candidate.amount.minorUnits, 400);
      expect(candidate.emailEvidence.length, 2);
      expect(candidate.sourceTypes.contains(DetectionSource.gmail), isTrue);
      expect(candidate.confidenceScore, greaterThan(0.70));
    });

    test('processMessages suppresses merchants listed in ignoredMerchants', () {
      final messages = [
        const GmailRawMessage(
          id: 'msg_gym',
          headers: {
            'From': 'Equinox Gym <billing@equinox.com>',
            'Subject': 'Your gym membership receipt',
            'Date': '2026-10-01T00:00:00Z',
          },
          plainTextBody: r'Your monthly membership fee of $250.00 was charged.',
        ),
      ];

      final candidates = service.processMessages(
        messages: messages,
        existingSubscriptions: const [],
        ignoredMerchants: {'equinox'},
        now: () => now,
      );

      expect(candidates, isEmpty);
    });
  });
}