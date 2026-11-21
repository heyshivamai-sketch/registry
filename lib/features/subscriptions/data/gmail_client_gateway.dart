import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;
import 'package:the_registry/features/subscriptions/domain/gmail_subscription_detection_service.dart';

abstract interface class GmailClientGateway {
  Future<String?> signIn();
  Future<void> signOut();
  Future<String?> getCurrentUserEmail();
  Future<List<GmailRawMessage>> searchBillingEmails({
    DateTime? since,
    int maxResults = 50,
  });
}

class GoogleApiGmailGateway implements GmailClientGateway {
  GoogleApiGmailGateway({
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const [
                'https://www.googleapis.com/auth/gmail.readonly',
              ],
            );

  final GoogleSignIn _googleSignIn;

  @override
  Future<String?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account?.email;
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('failed_to_recover_auth') ||
          str.contains('failed attempt to recover authentication')) {
        // Clear any stale cached session and retry cleanly
        try {
          await _googleSignIn.signOut();
          final account = await _googleSignIn.signIn();
          return account?.email;
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    return _googleSignIn.currentUser?.email;
  }

  @override
  Future<List<GmailRawMessage>> searchBillingEmails({
    DateTime? since,
    int maxResults = 50,
  }) async {
    var account = _googleSignIn.currentUser;
    if (account == null) {
      for (var attempt = 1; attempt <= 2; attempt++) {
        try {
          account = await _googleSignIn.signInSilently();
          break;
        } catch (e) {
          final err = e.toString().toLowerCase();
          final isDeadlock =
              err.contains('deadlock') || err.contains('main thread');
          if (isDeadlock && attempt < 2) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            continue;
          }
          rethrow;
        }
      }
    }
    if (account == null) {
      throw StateError('User is not signed into Google');
    }

    final authHeaders = await _fetchAuthHeaders(account);
    final authenticateClient = _AuthenticatedClient(authHeaders, http.Client());
    final gmailApi = gmail.GmailApi(authenticateClient);

    var query = GmailSubscriptionDetectionService.billingSearchQuery;
    if (since != null) {
      final epochSeconds = since.millisecondsSinceEpoch ~/ 1000;
      query += ' after:$epochSeconds';
    }

    final listResponse = await gmailApi.users.messages.list(
      'me',
      q: query,
      maxResults: maxResults,
    );

    final messages = listResponse.messages;
    if (messages == null || messages.isEmpty) {
      return const [];
    }

    final rawMessages = <GmailRawMessage>[];

    for (final ref in messages) {
      final msgId = ref.id;
      if (msgId == null) continue;

      try {
        final message = await gmailApi.users.messages.get(
          'me',
          msgId,
          format: 'full',
        );

        final headersMap = <String, String>{};
        final payloadHeaders = message.payload?.headers;
        if (payloadHeaders != null) {
          for (final h in payloadHeaders) {
            final name = h.name;
            final value = h.value;
            if (name != null && value != null) {
              headersMap[name] = value;
            }
          }
        }

        String? plainText;
        String? html;

        void extractParts(gmail.MessagePart? part) {
          if (part == null) return;
          final mimeType = part.mimeType?.toLowerCase();
          final data = part.body?.data;
          if (data != null && data.isNotEmpty) {
            final decoded = GmailSubscriptionDetectionService.decodeBase64UrlSafe(data);
            if (mimeType == 'text/plain') {
              plainText = decoded;
            } else if (mimeType == 'text/html') {
              html = decoded;
            }
          }
          if (part.parts != null) {
            for (final subPart in part.parts!) {
              extractParts(subPart);
            }
          }
        }

        extractParts(message.payload);

        rawMessages.add(
          GmailRawMessage(
            id: msgId,
            threadId: message.threadId ?? '',
            headers: headersMap,
            snippet: message.snippet ?? '',
            plainTextBody: plainText,
            htmlBody: html,
          ),
        );
      } catch (_) {
        // Continue parsing next message if single message fetch fails
        continue;
      }
    }

    return rawMessages;
  }

  Future<Map<String, String>> _fetchAuthHeaders(
    GoogleSignInAccount account,
  ) async {
    // Yield to let any active platform channel / Activity transition settle
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        return await account.authHeaders;
      } catch (e) {
        final err = e.toString().toLowerCase();
        final isDeadlock =
            err.contains('deadlock') || err.contains('main thread');
        if (isDeadlock && attempt < 3) {
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        rethrow;
      }
    }
    return await account.authHeaders;
  }
}

class _AuthenticatedClient extends http.BaseClient {
  _AuthenticatedClient(this._headers, this._client);

  final Map<String, String> _headers;
  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

