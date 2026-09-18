import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_ocr_parser.dart';

class MlKitDocumentOcrService implements DocumentOcrService {
  MlKitDocumentOcrService({this._recognizer});

  final TextRecognizer? _recognizer;

  @override
  Future<DocumentOcrResult> recognize(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      return const DocumentOcrResult.failed();
    }
    Directory? tempDir;
    final recognizer =
        _recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);
    final ownsRecognizer = _recognizer == null;
    try {
      tempDir = await Directory.systemTemp.createTemp('registry_ocr_');
      final file = File('${tempDir.path}/scan.png');
      await file.writeAsBytes(imageBytes, flush: true);
      final input = InputImage.fromFilePath(file.path);
      final recognized = await recognizer.processImage(input);
      return DocumentOcrParser.parse(recognized.text);
    } catch (_) {
      return const DocumentOcrResult.failed();
    } finally {
      if (ownsRecognizer) {
        await recognizer.close();
      }
      try {
        await tempDir?.delete(recursive: true);
      } catch (_) {}
    }
  }
}
