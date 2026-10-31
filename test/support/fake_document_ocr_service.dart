import 'dart:typed_data';

import 'package:the_registry/features/documents/domain/document_ocr.dart';

class FakeDocumentOcrService extends DocumentOcrService
    implements MultiImageDocumentOcrService {
  DocumentOcrResult result = const DocumentOcrResult.failed();
  Duration? delay;
  int recognizeCount = 0;
  List<Uint8List>? receivedImages;
  bool available = true;

  @override
  bool get isAvailable => available;

  @override
  Future<DocumentOcrResult> recognize(Uint8List imageBytes) async {
    recognizeCount += 1;
    final wait = delay;
    if (wait != null) {
      await Future<void>.delayed(wait);
    }
    return result;
  }

  @override
  Future<DocumentOcrResult> recognizeImages(List<Uint8List> images) async {
    receivedImages = images;
    recognizeCount += 1;
    final wait = delay;
    if (wait != null) {
      await Future<void>.delayed(wait);
    }
    return result;
  }
}
