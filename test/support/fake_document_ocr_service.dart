import 'dart:typed_data';

import 'package:the_registry/features/documents/domain/document_ocr.dart';

class FakeDocumentOcrService implements DocumentOcrService {
  DocumentOcrResult result = const DocumentOcrResult.failed();
  Duration? delay;
  int recognizeCount = 0;

  @override
  Future<DocumentOcrResult> recognize(Uint8List imageBytes) async {
    recognizeCount += 1;
    final wait = delay;
    if (wait != null) {
      await Future<void>.delayed(wait);
    }
    return result;
  }
}
