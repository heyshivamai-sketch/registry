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
    final account = await _googleSignIn.signIn();
    return account?.email;
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
    account ??= await _googleSignIn.signInSilently();
    if (account == null) {
      throw StateError('User is not signed into Google');
    }

    final authHeaders = await account.authHeaders;
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

