import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/documents/data/firebase_ai_document_ocr_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an unconfigured checkout disables AI Scan', () async {
    final scanner = await initializeFirebaseAiDocumentScanner();

    expect(scanner.isAvailable, isFalse);
  });
}
