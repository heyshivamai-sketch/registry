import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:the_registry/features/entitlements/billing_records.dart';

class HttpBillingVerificationClient implements BillingVerificationClient {
  HttpBillingVerificationClient(this.baseUrl, {HttpClient? client})
    : _client = client ?? HttpClient();

  final Uri baseUrl;
  final HttpClient _client;

  @override
  Future<BillingServerResponse> post(
    String path,
    Map<String, Object?> body, {
    String? sessionToken,
  }) async {
    try {
      final request = await _client.postUrl(baseUrl.resolve(path));
      request.headers.contentType = ContentType.json;
      if (sessionToken != null && sessionToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $sessionToken',
        );
      }
      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final text = await utf8.decoder.bind(response).join();
      return BillingServerResponse(
        statusCode: response.statusCode,
        body: _object(text),
      );
    } on SocketException {
      return const BillingServerResponse.unreachable();
    } on TimeoutException {
      return const BillingServerResponse.unreachable();
    } on HttpException {
      return const BillingServerResponse.unreachable();
    }
  }

  Map<String, Object?> _object(String text) {
    if (text.isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      return const {};
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
}
