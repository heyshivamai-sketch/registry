import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/documents/widgets/document_attachment_preview_page.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_document_ocr_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/tiny_png.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryDocumentRepository documents;
  late FakeImagePickerService images;
  late FakeDatePickerService dates;
  late FakeDocumentOcrService ocr;

  Widget app() {
    return RegistryApp(
      key: UniqueKey(),
      onboardingRepository: FakeOnboardingRepository(completed: true),
      documentRepository: documents,
      imagePickerService: images,
      datePickerService: dates,
      documentOcrService: ocr,
    );
  }

  setUp(() {
    documents = InMemoryDocumentRepository();
    images = FakeImagePickerService();
    dates = FakeDatePickerService();
    ocr = FakeDocumentOcrService();
  });

  Future<void> openAddDocument(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-document')));
    await tester.pumpAndSettle();
  }

  testWidgets('supports front and back camera selection when taking initial photo', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await openAddDocument(tester);

    // Verify back and front camera options exist
    expect(find.byKey(const ValueKey<String>('attach-camera')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attach-camera-front')), findsOneWidget);

    // Tap back camera
    images.cameraResult = ImagePickResult.success(kTinyPngBytes);
    await tester.tap(find.byKey(const ValueKey<String>('attach-camera')));
    await tester.pumpAndSettle();

    expect(images.lastCameraLens, AppCameraLens.back);
  });

  testWidgets('front camera option invokes camera with front lens', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await openAddDocument(tester);

    images.cameraResult = ImagePickResult.success(kTinyPngBytes);
    await tester.tap(find.byKey(const ValueKey<String>('attach-camera-front')));
    await tester.pumpAndSettle();

    expect(images.lastCameraLens, AppCameraLens.front);
  });

  testWidgets('supports additional pages with preview, retake and removal', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await openAddDocument(tester);

    // Pick initial image
    images.cameraResult = ImagePickResult.success(kTinyPngBytes);
    await tester.tap(find.byKey(const ValueKey<String>('attach-camera')));
    await tester.pumpAndSettle();

    // Verify initial attachment is present
    expect(find.byKey(const ValueKey<String>('attach-replace')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attach-remove')), findsOneWidget);

    // Add back / additional page using front camera
    final addPhotoFront = find.byKey(const ValueKey<String>('add-photo-front'));
    expect(addPhotoFront, findsOneWidget);
    await tester.ensureVisible(addPhotoFront);
    await tester.pumpAndSettle();

    images.cameraResult = ImagePickResult.success(kTinyPngBytes);
    await tester.tap(addPhotoFront);
    await tester.pumpAndSettle();

    expect(images.lastCameraLens, AppCameraLens.front);

    // Additional page should be rendered
    final backSideBadge = find.text('Back side');
    await tester.ensureVisible(backSideBadge);
    await tester.pumpAndSettle();
    expect(backSideBadge, findsOneWidget);

    final replaceBackSide = find.byKey(const ValueKey<String>('attach-replace-Back side'));
    final removeBackSide = find.byKey(const ValueKey<String>('attach-remove-Back side'));
    expect(replaceBackSide, findsOneWidget);
    expect(removeBackSide, findsOneWidget);

    // Test preview functionality
    final previewBackSide = find.byKey(const ValueKey<String>('attach-preview-Back side'));
    expect(previewBackSide, findsOneWidget);
    await tester.ensureVisible(previewBackSide);
    await tester.pumpAndSettle();
    await tester.tap(previewBackSide);
    await tester.pumpAndSettle();

    // Verify preview page is shown
    expect(find.byType(DocumentAttachmentPreviewPage), findsOneWidget);

    // Close preview
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentAttachmentPreviewPage), findsNothing);

    // Retake / Replace Back side
    await tester.ensureVisible(replaceBackSide);
    await tester.pumpAndSettle();
    await tester.tap(replaceBackSide);
    await tester.pumpAndSettle();

    // Replacement options should include Front Camera, Back Camera, Gallery
    expect(find.byKey(const ValueKey<String>('replace-source-camera')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replace-source-camera-front')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replace-source-gallery')), findsOneWidget);

    // Pick replacement using front camera
    images.cameraResult = ImagePickResult.success(kTinyPngBytes);
    await tester.tap(find.byKey(const ValueKey<String>('replace-source-camera-front')));
    await tester.pumpAndSettle();

    expect(images.lastCameraLens, AppCameraLens.front);
    expect(find.text('Back side'), findsOneWidget);

    // Remove Back side
    await tester.ensureVisible(removeBackSide);
    await tester.pumpAndSettle();
    await tester.tap(removeBackSide);
    await tester.pumpAndSettle();

    expect(find.text('Back side'), findsNothing);
  });
}
