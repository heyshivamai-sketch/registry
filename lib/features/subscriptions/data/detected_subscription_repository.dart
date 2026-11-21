import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:the_registry/features/subscriptions/domain/detected_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

class GmailSyncMetadata {
  const GmailSyncMetadata({
    required this.emailAddress,
    this.lastSuccessfulScan,
    this.lastScannedMessageId,
    required this.connectedAt,
  });

  final String emailAddress;
  final DateTime? lastSuccessfulScan;
  final String? lastScannedMessageId;
  final DateTime connectedAt;

  GmailSyncMetadata copyWith({
    String? emailAddress,
    DateTime? lastSuccessfulScan,
    String? lastScannedMessageId,
    DateTime? connectedAt,
  }) {
    return GmailSyncMetadata(
      emailAddress: emailAddress ?? this.emailAddress,
      lastSuccessfulScan: lastSuccessfulScan ?? this.lastSuccessfulScan,
      lastScannedMessageId: lastScannedMessageId ?? this.lastScannedMessageId,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}

abstract interface class DetectedSubscriptionRepository extends ChangeNotifier {
  List<DetectedSubscriptionCandidate> get candidates;
  Set<String> get ignoredMerchants;
  GmailSyncMetadata? get gmailMetadata;

  Future<void> saveCandidates(List<DetectedSubscriptionCandidate> newCandidates);
  Future<void> updateCandidateStatus(String id, DetectionReviewStatus status);
  Future<void> ignoreMerchant(String merchantName);
  Future<void> unignoreMerchant(String merchantName);
  Future<void> saveGmailMetadata(GmailSyncMetadata metadata);
  Future<void> clearGmailMetadata();
}

class InMemoryDetectedSubscriptionRepository extends ChangeNotifier
    implements DetectedSubscriptionRepository {
  InMemoryDetectedSubscriptionRepository({
    List<DetectedSubscriptionCandidate>? initialCandidates,
    Set<String>? initialIgnored,
    this.gmailMetadata,
  })  : _candidates = initialCandidates ?? [],
        _ignoredMerchants = initialIgnored ?? {};

  final List<DetectedSubscriptionCandidate> _candidates;
  final Set<String> _ignoredMerchants;
  @override
  GmailSyncMetadata? gmailMetadata;

  @override
  List<DetectedSubscriptionCandidate> get candidates =>
      List.unmodifiable(_candidates);

  @override
  Set<String> get ignoredMerchants => Set.unmodifiable(_ignoredMerchants);

  @override
  Future<void> saveCandidates(
      List<DetectedSubscriptionCandidate> newCandidates) async {
    for (final candidate in newCandidates) {
      final index = _candidates.indexWhere((c) => c.id == candidate.id);
      if (index >= 0) {
        _candidates[index] = candidate;
      } else {
        _candidates.add(candidate);
      }
    }
    notifyListeners();
  }

  @override
  Future<void> updateCandidateStatus(
      String id, DetectionReviewStatus status) async {
    final index = _candidates.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _candidates[index] = _candidates[index].copyWith(reviewStatus: status);
      notifyListeners();
    }
  }

  @override
  Future<void> ignoreMerchant(String merchantName) async {
    _ignoredMerchants.add(merchantName.toLowerCase().trim());
    // Mark pending candidates for this merchant as ignored
    for (var i = 0; i < _candidates.length; i++) {
      if (_candidates[i].merchantName.toLowerCase().trim() ==
          merchantName.toLowerCase().trim()) {
        _candidates[i] = _candidates[i]
            .copyWith(reviewStatus: DetectionReviewStatus.ignored);
      }
    }
    notifyListeners();
  }

  @override
  Future<void> unignoreMerchant(String merchantName) async {
    _ignoredMerchants.remove(merchantName.toLowerCase().trim());
    notifyListeners();
  }

  @override
  Future<void> saveGmailMetadata(GmailSyncMetadata metadata) async {
    gmailMetadata = metadata;
    notifyListeners();
  }

  @override
  Future<void> clearGmailMetadata() async {
    gmailMetadata = null;
    notifyListeners();
  }
}

class SqliteDetectedSubscriptionRepository extends ChangeNotifier
    implements DetectedSubscriptionRepository {
  SqliteDetectedSubscriptionRepository._(this._database);

  final Database _database;
  final List<DetectedSubscriptionCandidate> _candidates = [];
  final Set<String> _ignoredMerchants = {};
  GmailSyncMetadata? _gmailMetadata;

  static Future<SqliteDetectedSubscriptionRepository> load(
      Database database) async {
    final repo = SqliteDetectedSubscriptionRepository._(database);
    await repo._readAll();
    return repo;
  }

  @override
  List<DetectedSubscriptionCandidate> get candidates =>
      List.unmodifiable(_candidates);

  @override
  Set<String> get ignoredMerchants => Set.unmodifiable(_ignoredMerchants);

  @override
  GmailSyncMetadata? get gmailMetadata => _gmailMetadata;

  Future<void> _readAll() async {
    // 1. Read candidates
    final candidateRows = await _database.query(
      'detected_subscriptions',
      orderBy: 'created_at DESC',
    );
    _candidates.clear();
    for (final row in candidateRows) {
      _candidates.add(_fromRow(row));
    }

    // 2. Read ignored merchants
    final ignoredRows = await _database.query('ignored_merchants');
    _ignoredMerchants.clear();
    for (final row in ignoredRows) {
      final name = row['merchant_name'] as String?;
      if (name != null) {
        _ignoredMerchants.add(name.toLowerCase().trim());
      }
    }

    // 3. Read gmail sync metadata
    final metadataRows = await _database.query(
      'gmail_sync_metadata',
      where: 'key = ?',
      whereArgs: ['connection'],
    );
    if (metadataRows.isNotEmpty) {
      final row = metadataRows.first;
      _gmailMetadata = GmailSyncMetadata(
        emailAddress: row['email_address'] as String? ?? '',
        lastSuccessfulScan: row['last_successful_scan'] != null
            ? DateTime.tryParse(row['last_successful_scan'] as String)
            : null,
        lastScannedMessageId: row['last_scanned_message_id'] as String?,
        connectedAt: row['connected_at'] != null
            ? DateTime.tryParse(row['connected_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
    } else {
      _gmailMetadata = null;
    }

    notifyListeners();
  }

  @override
  Future<void> saveCandidates(
      List<DetectedSubscriptionCandidate> newCandidates) async {
    await _database.transaction((txn) async {
      for (final candidate in newCandidates) {
        await txn.insert(
          'detected_subscriptions',
          _toRow(candidate),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    for (final candidate in newCandidates) {
      final index = _candidates.indexWhere((c) => c.id == candidate.id);
      if (index >= 0) {
        _candidates[index] = candidate;
      } else {
        _candidates.insert(0, candidate);
      }
    }
    notifyListeners();
  }

  @override
  Future<void> updateCandidateStatus(
      String id, DetectionReviewStatus status) async {
    await _database.update(
      'detected_subscriptions',
      {'review_status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    final index = _candidates.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _candidates[index] = _candidates[index].copyWith(reviewStatus: status);
      notifyListeners();
    }
  }

  @override
  Future<void> ignoreMerchant(String merchantName) async {
    final normalized = merchantName.toLowerCase().trim();
    await _database.insert(
      'ignored_merchants',
      {
        'merchant_name': normalized,
        'suppressed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _ignoredMerchants.add(normalized);

    // Also mark matching pending candidates as ignored in database
    await _database.update(
      'detected_subscriptions',
      {'review_status': DetectionReviewStatus.ignored.name},
      where: 'LOWER(TRIM(merchant_name)) = ?',
      whereArgs: [normalized],
    );

    for (var i = 0; i < _candidates.length; i++) {
      if (_candidates[i].merchantName.toLowerCase().trim() == normalized) {
        _candidates[i] = _candidates[i]
            .copyWith(reviewStatus: DetectionReviewStatus.ignored);
      }
    }
    notifyListeners();
  }

  @override
  Future<void> unignoreMerchant(String merchantName) async {
    final normalized = merchantName.toLowerCase().trim();
    await _database.delete(
      'ignored_merchants',
      where: 'merchant_name = ?',
      whereArgs: [normalized],
    );
    _ignoredMerchants.remove(normalized);
    notifyListeners();
  }

  @override
  Future<void> saveGmailMetadata(GmailSyncMetadata metadata) async {
    await _database.insert(
      'gmail_sync_metadata',
      {
        'key': 'connection',
        'email_address': metadata.emailAddress,
        'last_successful_scan': metadata.lastSuccessfulScan?.toIso8601String(),
        'last_scanned_message_id': metadata.lastScannedMessageId,
        'connected_at': metadata.connectedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _gmailMetadata = metadata;
    notifyListeners();
  }

  @override
  Future<void> clearGmailMetadata() async {
    await _database.delete(
      'gmail_sync_metadata',
      where: 'key = ?',
      whereArgs: ['connection'],
    );
    _gmailMetadata = null;
    notifyListeners();
  }

  static Map<String, dynamic> _toRow(DetectedSubscriptionCandidate c) {
    return {
      'id': c.id,
      'merchant_name': c.merchantName,
      'minor_units': c.amount.minorUnits,
      'currency_code': c.amount.code,
      'billing_cycle': c.billingCycle.name,
      'last_payment_date': c.lastPaymentDate.toIso8601String(),
      'next_payment_date': c.nextPaymentDate?.toIso8601String(),
      'next_payment_is_estimated': c.nextPaymentIsEstimated ? 1 : 0,
      'source_types': jsonEncode(c.sourceTypes.map((s) => s.name).toList()),
      'confidence_score': c.confidenceScore,
      'review_status': c.reviewStatus.name,
      'bank_evidence': jsonEncode(c.bankEvidence.map((e) => e.toJson()).toList()),
      'email_evidence':
          jsonEncode(c.emailEvidence.map((e) => e.toJson()).toList()),
      'created_at': c.createdAt.toIso8601String(),
      'updated_at': c.updatedAt?.toIso8601String(),
    };
  }

  static DetectedSubscriptionCandidate _fromRow(Map<String, dynamic> row) {
    final sourcesList = (jsonDecode(row['source_types'] as String) as List)
        .cast<String>();
    final sources = sourcesList
        .map((s) => DetectionSource.values.firstWhere(
              (v) => v.name == s,
              orElse: () => DetectionSource.bankStatement,
            ))
        .toSet();

    final bankEvidenceJson = row['bank_evidence'] != null
        ? (jsonDecode(row['bank_evidence'] as String) as List)
            .cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final bankEvidence = bankEvidenceJson
        .map((json) => BankTransactionEvidence.fromJson(json))
        .toList();

    final emailEvidenceJson = row['email_evidence'] != null
        ? (jsonDecode(row['email_evidence'] as String) as List)
            .cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final emailEvidence = emailEvidenceJson
        .map((json) => EmailEvidence.fromJson(json))
        .toList();

    final cycle = BillingCycle.values.firstWhere(
      (c) => c.name == row['billing_cycle'],
      orElse: () => BillingCycle.monthly,
    );

    final status = DetectionReviewStatus.values.firstWhere(
      (s) => s.name == row['review_status'],
      orElse: () => DetectionReviewStatus.pendingReview,
    );

    return DetectedSubscriptionCandidate(
      id: row['id'] as String,
      merchantName: row['merchant_name'] as String,
      amount: Money(
        minorUnits: row['minor_units'] as int,
        currencyCode: row['currency_code'] as String,
      ),
      billingCycle: cycle,
      lastPaymentDate: DateTime.parse(row['last_payment_date'] as String),
      nextPaymentDate: row['next_payment_date'] != null
          ? DateTime.parse(row['next_payment_date'] as String)
          : null,
      nextPaymentIsEstimated: (row['next_payment_is_estimated'] as int) == 1,
      sourceTypes: sources,
      confidenceScore: (row['confidence_score'] as num).toDouble(),
      reviewStatus: status,
      bankEvidence: bankEvidence,
      emailEvidence: emailEvidence,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }
}

