import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:the_registry/features/documents/data/firebase_ai_document_ocr_service.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/firebase_options.dart';

const _modelName = String.fromEnvironment(
  'FIREBASE_AI_MODEL',
  defaultValue: 'gemini-3.5-flash-lite',
);

/// App Check is bypassed by default so local development and testing
/// works seamlessly on any device without registering debug tokens.
/// Pass `--dart-define=ENABLE_APP_CHECK=true` for production Play Store release.
const bool _enableAppCheck = bool.fromEnvironment(
  'ENABLE_APP_CHECK',
  defaultValue: false,
);

Future<DocumentOcrService> initializeFirebaseAiDocumentScanner() async {
  try {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (_enableAppCheck) {
      await FirebaseAppCheck.instanceFor(app: app).activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    }
    final ai = FirebaseAI.googleAI(
      app: app,
      useLimitedUseAppCheckTokens: _enableAppCheck,
    );
    return FirebaseAiDocumentOcrService(
      FirebaseAiLogicDocumentClient(ai: ai, model: _modelName),
    );
  } on Object catch (error) {
    debugPrint(
      'Firebase AI Scan is disabled because Firebase is not configured: $error',
    );
    return const DisabledDocumentOcrService();
  }
}
