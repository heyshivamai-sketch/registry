import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import '../data/detected_subscription_repository.dart';
import 'bank_subscription_detection_service.dart';
import 'detected_subscription.dart';
import 'subscription_repository.dart';

class SubscriptionDiscoveryService extends ChangeNotifier {
  SubscriptionDiscoveryService({
    required this.detectedRepository,
    required this.subscriptionRepository,
    BankSubscriptionDetectionService? bankService,
  }) : _bankService = bankService ?? const BankSubscriptionDetectionService() {
    detectedRepository.addListener(notifyListeners);
    subscriptionRepository.addListener(notifyListeners);
  }

  final DetectedSubscriptionRepository detectedRepository;
  final SubscriptionRepository subscriptionRepository;
  final BankSubscriptionDetectionService _bankService;

  List<DetectedSubscriptionCandidate> get allCandidates =>
      detectedRepository.candidates;

  List<DetectedSubscriptionCandidate> get pendingCandidates =>
      detectedRepository.candidates
          .where((c) => c.reviewStatus == DetectionReviewStatus.pendingReview)
          .toList();

  List<DetectedSubscriptionCandidate> get visibleCandidates {
    final list = detectedRepository.candidates
        .where((c) => c.reviewStatus != DetectionReviewStatus.ignored)
        .toList();
    list.sort((a, b) {
      final aAdded = isCandidateAdded(a);
      final bAdded = isCandidateAdded(b);
      if (aAdded != bAdded) {
        return aAdded ? 1 : -1;
      }
      return b.lastPaymentDate.compareTo(a.lastPaymentDate);
    });
    return list;
  }

  bool isCandidateAdded(DetectedSubscriptionCandidate candidate) {
    if (candidate.reviewStatus == DetectionReviewStatus.accepted) {
      return true;
    }
    final normCandidate =
        _bankService.normalizeMerchant(candidate.merchantName).toLowerCase();
    return subscriptionRepository.subscriptions.any((sub) {
      final normSub =
          _bankService.normalizeMerchant(sub.serviceName).toLowerCase();
      return normSub == normCandidate ||
          normSub.contains(normCandidate) ||
          normCandidate.contains(normSub);
    });
  }

  Set<String> get ignoredMerchants => detectedRepository.ignoredMerchants;

  GmailSyncMetadata? get gmailMetadata => detectedRepository.gmailMetadata;

  /// Merges cross-source candidates (Bank Statement + Gmail), eliminating duplicates,
  /// fusing evidence, boosting confidence, and persisting them to storage.
  Future<List<DetectedSubscriptionCandidate>> mergeAndIngestCandidates(List<DetectedSubscriptionCandidate> incoming, {
    required DateTime Function() now,
  }) async {
    final existingList = List<DetectedSubscriptionCandidate>.from(allCandidates);
    final suppressed = ignoredMerchants;
    final activeSubs = subscriptionRepository.subscriptions;

    final merged = <DetectedSubscriptionCandidate>[...existingList];

    for (final inc in incoming) {
      final normalizedName = _bankService.normalizeMerchant(inc.merchantName).toLowerCase();

      // Check if suppressed
      if (suppressed.any((ignored) =>
      normalizedName == ignored || normalizedName.contains(ignored))) {
        continue;
      }

      // Check for match in existing merged list
      final matchIndex = merged.indexWhere((cand) {
        final candNorm = _bankService.normalizeMerchant(cand.merchantName).toLowerCase();
        if (candNorm != normalizedName) {
          return false;
        }
        if (cand.amount.code != inc.amount.code) {
          return false;
        }
        // Match exact or price change within 20%
        final delta = (cand.amount.minorUnits - inc.amount.minorUnits).abs();
        final maxAmount = math.max(cand.amount.minorUnits, inc.amount.minorUnits);
        return maxAmount == 0 || (delta / maxAmount) <= 0.25;
      });

      if (matchIndex >= 0) {
        final target = merged[matchIndex];
        // Combine sources
        final combinedSources = {...target.sourceTypes, ...inc.sourceTypes};

        // Combine evidence
        final bankEvMap = <int, BankTransactionEvidence>{
          for (final b in target.bankEvidence) b.lineNumber: b,
          for (final b in inc.bankEvidence) b.lineNumber: b,
        };
        final emailEvMap = <String, EmailEvidence>{
          for (final e in target.emailEvidence) e.messageId: e,
          for (final e in inc.emailEvidence) e.messageId: e,
        };

        // Boost confidence when evidence comes from both bank and email
        final baseScore = math.max(target.confidenceScore, inc.confidenceScore);
        final boostedScore = combinedSources.length > 1
            ? math.min(1.0, baseScore + 0.15)
            : baseScore;

        // Pick later payment date
        final latestPayment = target.lastPaymentDate.isAfter(inc.lastPaymentDate)
            ? target.lastPaymentDate
            : inc.lastPaymentDate;

        // Prefer explicit renewal date if one has it
        final bool isEstimated;
        final DateTime? nextRenewal;
        if (target.nextPaymentDate != null && !target.nextPaymentIsEstimated) {
          nextRenewal = target.nextPaymentDate;
          isEstimated = false;
        } else if (inc.nextPaymentDate != null && !inc.nextPaymentIsEstimated) {
          nextRenewal = inc.nextPaymentDate;
          isEstimated = false;
        } else {
          nextRenewal = target.lastPaymentDate.isAfter(inc.lastPaymentDate)
              ? target.nextPaymentDate
              : inc.nextPaymentDate;
          isEstimated = true;
        }

        // Pick amount of the most recent payment date
        final latestAmount = inc.lastPaymentDate.isAfter(target.lastPaymentDate)
            ? inc.amount
            : target.amount;

        merged[matchIndex] = target.copyWith(
          amount: latestAmount,
          lastPaymentDate: latestPayment,
          nextPaymentDate: nextRenewal,
          nextPaymentIsEstimated: isEstimated,
          sourceTypes: combinedSources,
          confidenceScore: double.parse(boostedScore.toStringAsFixed(2)),
          bankEvidence: bankEvMap.values.toList(),
          emailEvidence: emailEvMap.values.toList(),
          updatedAt: now(),
        );
      } else {
        // Check if existing manual or active subscription matches
        final isDuplicate = activeSubs.any((sub) =>
        _bankService.normalizeMerchant(sub.serviceName).toLowerCase() ==
            normalizedName &&
            sub.amount.code == inc.amount.code);

        merged.add(inc.copyWith(possibleDuplicate: isDuplicate));
      }
    }

    await detectedRepository.saveCandidates(merged);
    return merged;
  }

  /// Marks a candidate as accepted after user adds it to ResiDay.
  Future<void> acceptCandidate(String candidateId) async {
    await detectedRepository.updateCandidateStatus(
      candidateId,
      DetectionReviewStatus.accepted,
    );
  }

  /// Ignores a detected candidate and remembers the suppression preference locally
  /// so it will never be suggested again.
  Future<void> ignoreCandidate(String candidateId) async {
    final candidate = allCandidates.firstWhere((c) => c.id == candidateId);
    await detectedRepository.ignoreMerchant(candidate.merchantName);
  }

  /// Removes suppression preference for a merchant.
  Future<void> unignoreMerchant(String merchantName) async {
    await detectedRepository.unignoreMerchant(merchantName);
  }

  @override
  void dispose() {
    detectedRepository.removeListener(notifyListeners);
    subscriptionRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
