import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_registry/core/persistence/registry_store.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/backup_payload.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/presentation/add_document_controller.dart';
import 'support/sample_document.dart';
import 'support/sample_document_ocr_result.dart';
import 'support/tiny_png.dart';

class _MultiScanner extends DocumentOcrService
    implements MultiImageDocumentOcrService {
  final pending = Completer<DocumentOcrResult>();
  List<Uint8List>? received;
  @override
  Future<DocumentOcrResult> recognize(Uint8List bytes) =>
      throw UnimplementedError();
  @override
  Future<DocumentOcrResult> recognizeImages(List<Uint8List> images) {
    received = images;
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'front and back survive save, restart, backup, restore and edit',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final root = await Directory.systemTemp.createTemp('multi_image_');
      RegistryStore? store;
      try {
        Future<RegistryStore> open() => RegistryStore.open(
          databasePath: '${root.path}/db',
          attachmentsDirectory: Directory('${root.path}/images'),
        );
        store = await open();
        final doc = sampleDocument(attachmentBytes: kTinyPngBytes).copyWith(
          additionalImages: [
            Uint8List.fromList([1, 2, 3]),
          ],
          categoryLabel: 'Identity card — India',
        );
        await store.documents.save(doc);
        await store.close();
        store = await open();
        final loaded = store.documents.documents.single;
        expect(loaded.additionalImages.single, [1, 2, 3]);
        expect(loaded.categoryLabel, doc.categoryLabel);
        final backup = RegistryBackupPayload.encode(
          BackupSnapshot(documents: [loaded], subscriptions: []),
        );
        final decoded = RegistryBackupPayload.decode(backup);
        expect(decoded.attachmentCount, 2);
        final restored = decoded.documents.single;
        expect(restored.additionalImages.single, [1, 2, 3]);
        expect(restored.categoryLabel, doc.categoryLabel);
        final controller = AddDocumentController()..loadDocument(restored);
        expect(controller.toDocument().additionalImages.single, [1, 2, 3]);
        controller.removeImage(0);
        expect(controller.isDirty, isTrue);
        await store.documents.update(controller.toDocument());
        await store.close();
        store = await open();
        expect(store.documents.documents.single.additionalImages, isEmpty);
        controller.dispose();
      } finally {
        await store?.close();
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'one scan receives all sides and ignores results after image removal',
    () async {
      final controller = AddDocumentController()
        ..setAttachment(kTinyPngBytes)
        ..addImage(Uint8List.fromList([1, 2]));
      final scanner = _MultiScanner();
      final scanning = controller.recognizeAttachment(scanner);
      expect(scanner.received, hasLength(2));
      controller.removeImage(0);
      scanner.pending.complete(sampleAadhaarOcrResult());
      await scanning;
      expect(controller.ocrStatus, OcrUiStatus.idle);
      expect(controller.ocrResult, isNull);
      controller.dispose();
    },
  );

  test('Gemini category fills form and remains freely editable', () async {
    final controller = AddDocumentController()..setAttachment(kTinyPngBytes);
    final scanner = _MultiScanner();
    final scanning = controller.recognizeAttachment(scanner);
    scanner.pending.complete(
      sampleAadhaarOcrResult(category: 'National identity'),
    );
    await scanning;
    controller.confirmOcr();
    expect(controller.categoryLabel, 'National identity');
    expect(controller.expiryDate, isNull);
    controller.setCategoryLabel('Personal records');
    expect(controller.categoryLabel, 'Personal records');
    controller.setCategoryLabel('');
    expect(controller.category, isNull);
    controller.dispose();
  });
}
