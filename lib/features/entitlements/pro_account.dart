import 'dart:convert';
import 'dart:io';

import 'package:the_registry/features/entitlements/billing_records.dart';

/// A verified Local Pro email session.
///
/// The token is an opaque server credential. It is stored beside the
/// installation id, outside the registry database and outside `.rgry` backups.
class ProAccountSession {
  const ProAccountSession({required this.token, required this.email});

  final String token;
  final String email;
}

abstract class ProAccountSessionStore {
  Future<ProAccountSession?> read();

  Future<void> write(ProAccountSession session);

  Future<void> clear();
}

class MemoryProAccountSessionStore implements ProAccountSessionStore {
  ProAccountSession? session;

  @override
  Future<void> clear() async {
    session = null;
  }

  @override
  Future<ProAccountSession?> read() async => session;

  @override
  Future<void> write(ProAccountSession session) async {
    this.session = session;
  }
}

class FileProAccountSessionStore implements ProAccountSessionStore {
  FileProAccountSessionStore(this.file);

  final File file;

  @override
  Future<void> clear() async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<ProAccountSession?> read() async {
    if (!await file.exists()) {
      return null;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      return null;
    }
    final token = decoded['token'];
    final email = decoded['email'];
    if (token is! String ||
        token.isEmpty ||
        email is! String ||
        email.isEmpty) {
      return null;
    }
    return ProAccountSession(token: token, email: email);
  }

  @override
  Future<void> write(ProAccountSession session) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({'token': session.token, 'email': session.email}),
    );
  }
}

enum AccountAttemptOutcome {
  verificationPending,
  signedIn,
  invalidCode,
  emailNotConfigured,
  deliveryFailed,
  offline,
  deleted,
  unauthorized,
  failed,
}

class AccountAttempt {
  const AccountAttempt({required this.outcome, this.email});

  final AccountAttemptOutcome outcome;
  final String? email;
}

/// Optional verified email for Local Pro recovery.
///
/// Confirming an email returns a session. It does not grant Local Pro.
abstract class ProAccountClient {
  Future<AccountAttempt> startVerification(String email);

  Future<AccountAttempt> confirmVerification(String email, String code);

  Future<AccountAttempt> deleteAccount();

  Future<ProAccountSession?> readSession();
}

class HttpProAccountClient implements ProAccountClient {
  HttpProAccountClient(this.verifier, this.sessions);

  final BillingVerificationClient verifier;
  final ProAccountSessionStore sessions;

  @override
  Future<AccountAttempt> confirmVerification(String email, String code) async {
    final response = await _post('/v1/accounts/verification/confirm', {
      'email': email.trim(),
      'code': code.trim(),
    });
    if (response.body['result'] == 'signed_in') {
      final token = response.body['sessionToken'];
      final confirmed = response.body['email'];
      if (token is String &&
          token.isNotEmpty &&
          confirmed is String &&
          confirmed.isNotEmpty) {
        await sessions.write(ProAccountSession(token: token, email: confirmed));
        return AccountAttempt(
          outcome: AccountAttemptOutcome.signedIn,
          email: confirmed,
        );
      }
    }
    return _map(response);
  }

  @override
  Future<AccountAttempt> deleteAccount() async {
    final session = await sessions.read();
    if (session == null) {
      return const AccountAttempt(outcome: AccountAttemptOutcome.unauthorized);
    }
    final response = await _post(
      '/v1/accounts/delete',
      const {},
      session.token,
    );
    if (response.body['result'] == 'deleted') {
      await sessions.clear();
      return const AccountAttempt(outcome: AccountAttemptOutcome.deleted);
    }
    if (response.statusCode == 401) {
      await sessions.clear();
      return const AccountAttempt(outcome: AccountAttemptOutcome.unauthorized);
    }
    return _map(response);
  }

  @override
  Future<ProAccountSession?> readSession() => sessions.read();

  @override
  Future<AccountAttempt> startVerification(String email) async {
    final response = await _post('/v1/accounts/verification/start', {
      'email': email.trim(),
    });
    return _map(response);
  }

  Future<BillingServerResponse> _post(
    String path,
    Map<String, Object?> body, [
    String? sessionToken,
  ]) {
    return verifier.post(path, body, sessionToken: sessionToken);
  }

  AccountAttempt _map(BillingServerResponse response) {
    if (response.transportFailure) {
      return const AccountAttempt(outcome: AccountAttemptOutcome.offline);
    }
    final error = response.body['error'];
    if (error == 'email_not_configured') {
      return const AccountAttempt(
        outcome: AccountAttemptOutcome.emailNotConfigured,
      );
    }
    if (error == 'email_delivery_failed') {
      return const AccountAttempt(
        outcome: AccountAttemptOutcome.deliveryFailed,
      );
    }
    if (error == 'invalid_code') {
      return const AccountAttempt(outcome: AccountAttemptOutcome.invalidCode);
    }
    if (response.body['result'] == 'verification_pending') {
      return const AccountAttempt(
        outcome: AccountAttemptOutcome.verificationPending,
      );
    }
    return const AccountAttempt(outcome: AccountAttemptOutcome.failed);
  }
}
