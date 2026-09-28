import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:the_registry/features/entitlements/verified_entitlement.dart';

abstract class InstallationIdStore {
  Future<String> getOrCreate();
}

class MemoryInstallationIdStore implements InstallationIdStore {
  MemoryInstallationIdStore(this.id);

  final String id;

  @override
  Future<String> getOrCreate() async => id;
}

class FileInstallationIdStore implements InstallationIdStore {
  FileInstallationIdStore(this.file);

  final File file;

  @override
  Future<String> getOrCreate() async {
    if (await file.exists()) {
      final existing = (await file.readAsString()).trim();
      if (_uuid.hasMatch(existing)) {
        return existing;
      }
    }
    final created = newInstallationId();
    await file.parent.create(recursive: true);
    await file.writeAsString(created);
    return created;
  }
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

String newInstallationId([Random? random]) {
  final bytes = List<int>.generate(
    16,
    (_) => (random ?? Random.secure()).nextInt(256),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class CachedGrant {
  const CachedGrant({required this.canonical, required this.signature});

  final String canonical;
  final String signature;
}

abstract class EntitlementCacheStore {
  Future<CachedGrant?> read();

  Future<void> write(CachedGrant grant);
}

class MemoryEntitlementCache implements EntitlementCacheStore {
  CachedGrant? grant;
  var writes = 0;

  @override
  Future<CachedGrant?> read() async => grant;

  @override
  Future<void> write(CachedGrant grant) async {
    writes += 1;
    this.grant = grant;
  }
}

class FileEntitlementCache implements EntitlementCacheStore {
  FileEntitlementCache(this.file);

  final File file;

  @override
  Future<CachedGrant?> read() async {
    if (!await file.exists()) {
      return null;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      return null;
    }
    final canonical = decoded['canonical'];
    final signature = decoded['signature'];
    if (canonical is! String || signature is! String) {
      return null;
    }
    return CachedGrant(canonical: canonical, signature: signature);
  }

  @override
  Future<void> write(CachedGrant grant) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({'canonical': grant.canonical, 'signature': grant.signature}),
    );
  }
}

class PendingPurchaseRecord {
  const PendingPurchaseRecord({
    required this.purchaseKey,
    required this.productId,
    required this.platform,
    required this.payload,
    required this.stage,
  });

  final String purchaseKey;
  final String productId;
  final String platform;
  final String payload;

  /// `pending`, `needsVerification`, `verified`, or `completed`.
  final String stage;

  PendingPurchaseRecord copyWith({String? stage}) {
    return PendingPurchaseRecord(
      purchaseKey: purchaseKey,
      productId: productId,
      platform: platform,
      payload: payload,
      stage: stage ?? this.stage,
    );
  }
}

abstract class PendingPurchaseStore {
  Future<List<PendingPurchaseRecord>> read();

  Future<void> write(List<PendingPurchaseRecord> records);
}

class MemoryPendingPurchaseStore implements PendingPurchaseStore {
  List<PendingPurchaseRecord> records = [];

  @override
  Future<List<PendingPurchaseRecord>> read() async => List.of(records);

  @override
  Future<void> write(List<PendingPurchaseRecord> records) async {
    this.records = List.of(records);
  }
}

class FilePendingPurchaseStore implements PendingPurchaseStore {
  FilePendingPurchaseStore(this.file);

  final File file;

  @override
  Future<List<PendingPurchaseRecord>> read() async {
    if (!await file.exists()) {
      return const [];
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      return const [];
    }
    return [
      for (final item in decoded)
        if (item is Map &&
            item['purchaseKey'] is String &&
            item['productId'] is String &&
            item['platform'] is String &&
            item['payload'] is String &&
            item['stage'] is String)
          PendingPurchaseRecord(
            purchaseKey: item['purchaseKey'] as String,
            productId: item['productId'] as String,
            platform: item['platform'] as String,
            payload: item['payload'] as String,
            stage: item['stage'] as String,
          ),
    ];
  }

  @override
  Future<void> write(List<PendingPurchaseRecord> records) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode([
        for (final record in records)
          {
            'purchaseKey': record.purchaseKey,
            'productId': record.productId,
            'platform': record.platform,
            'payload': record.payload,
            'stage': record.stage,
          },
      ]),
    );
  }
}

class BillingServerResponse {
  const BillingServerResponse({
    required this.statusCode,
    required this.body,
    this.transportFailure = false,
  });

  const BillingServerResponse.unreachable()
    : statusCode = 0,
      body = const {},
      transportFailure = true;

  final int statusCode;
  final Map<String, Object?> body;
  final bool transportFailure;
}

abstract class BillingVerificationClient {
  Future<BillingServerResponse> post(String path, Map<String, Object?> body);
}

/// Proof plus the optional one-time restore code from a verify response.
class VerifiedPurchaseResult {
  const VerifiedPurchaseResult({this.proof, this.recoveryCode});

  final VerifiedEntitlementProof? proof;
  final String? recoveryCode;
}
