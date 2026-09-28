import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:the_registry/features/entitlements/billing_runtime.dart';
import 'package:the_registry/features/entitlements/verified_entitlement.dart';

/// Checks a server-signed grant. A bad signature, the wrong installation,
/// product, or environment produces no proof.
Future<VerifiedEntitlementProof?> proofFromSignedGrant({
  required BillingRuntime runtime,
  required String installationId,
  required String canonical,
  required String signatureBase64,
}) async {
  if (!runtime.isReady) {
    return null;
  }
  final publicKeyBytes = _decodePublicKey(runtime.grantPublicKeyBase64);
  final signatureBytes = _decodeSignature(signatureBase64);
  if (publicKeyBytes == null || signatureBytes == null) {
    return null;
  }
  final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
  final ok = await Ed25519().verify(
    utf8.encode(canonical),
    signature: Signature(signatureBytes, publicKey: publicKey),
  );
  if (!ok) {
    return null;
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(canonical);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) {
    return null;
  }
  final claims = decoded.cast<Object?, Object?>();
  if (claims['installationId'] != installationId) {
    return null;
  }
  if (claims['productId'] != runtime.productId) {
    return null;
  }
  if (claims['environment'] != runtime.environment) {
    return null;
  }
  final status = claims['status'];
  if (status == 'inactive') {
    return VerifiedEntitlementProof(
      productId: runtime.productId,
      accepted: false,
      revoked: true,
    );
  }
  if (status != 'active') {
    return null;
  }
  return VerifiedEntitlementProof(productId: runtime.productId, accepted: true);
}

String? revalidateAfter(String canonical) {
  try {
    final decoded = jsonDecode(canonical);
    if (decoded is Map && decoded['revalidateAfter'] is String) {
      return decoded['revalidateAfter'] as String;
    }
  } on FormatException {
    return null;
  }
  return null;
}

List<int>? _decodePublicKey(String value) {
  try {
    final bytes = base64Decode(value);
    if (bytes.length != 32) {
      return null;
    }
    return bytes;
  } on FormatException {
    return null;
  }
}

List<int>? _decodeSignature(String value) {
  try {
    final bytes = base64Decode(value);
    if (bytes.length != 64) {
      return null;
    }
    return bytes;
  } on FormatException {
    return null;
  }
}
