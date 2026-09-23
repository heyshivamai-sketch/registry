import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/document_ocr_parser.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_document_ocr_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
import 'support/save_screenshot.dart';
import 'support/tiny_png.dart';

const _folder = 'registry_aura_fidelity';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryDocumentRepository documents;
  late FakeImagePickerService images;
  late FakeDatePickerService dates;
  late FakeDocumentOcrService ocr;

  Widget app({Locale locale = const Locale('en')}) {
    return RegistryApp(
      key: UniqueKey(),
      onboardingRepository: FakeOnboardingRepository(completed: true),
      documentRepository: documents,
      imagePickerService: images,
      datePickerService: dates,
      documentOcrService: ocr,
      locale: locale,
    );
  }

  setUp(() {
    documents = InMemoryDocumentRepository();
    images = FakeImagePickerService();
    dates = FakeDatePickerService();
    ocr = FakeDocumentOcrService();
  });

  void pixel8(WidgetTester tester, {double height = 1600}) {
    tester.view.physicalSize = Size(412, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignment: 0.2,
      duration: Duration.zero,
    );
    await tester.pump();
  }

  testWidgets('Registry Aura fidelity screenshots', (tester) async {
    pixel8(tester, height: 1400);
    await tester.pumpWidget(wrapForScreenshot(app()));
    await tester.pumpAndSettle();

    await saveScreenshot(tester, 'home_reference_match', folder: _folder);
    final metrics = find.byKey(const ValueKey<String>('home-metrics'));
    if (metrics.evaluate().isNotEmpty) {
      await reveal(tester, metrics);
    }
    await saveScreenshot(tester, 'home_pulse', folder: _folder);
    await saveScreenshot(tester, 'home_snapshot', folder: _folder);
    await saveScreenshot(tester, 'home_action_queue', folder: _folder);
    await saveScreenshot(tester, 'home_horizon', folder: _folder);
    await saveScreenshot(tester, 'navigation_dock', folder: _folder);

    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'quick_add_sheet', folder: _folder);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'documents_empty', folder: _folder);

    await documents.save(
      sampleDocument(
        name: 'Travel passport',
        category: DocumentCategory.passport,
        countryCode: DocumentCountryCodes.generic,
        ownerName: 'Alex Rivera',
        documentNumber: 'X1234567',
        expiryDate: DateTime(2026, 11, 12),
        actionDate: DateTime(2026, 10, 12),
        renewalHistory: [
          RenewalHistoryEntry(
            id: 'hist-1',
            renewedOn: DateTime(2026, 9, 18),
            previousExpiryDate: DateTime(2026, 11, 12),
            newExpiryDate: DateTime(2027, 11, 12),
            note: 'Passport renewed',
          ),
        ],
      ),
    );
    await documents.save(
      sampleDocument(
        id: 'doc_2',
        name: 'Car insurance',
        category: DocumentCategory.insurance,
        expiryDate: DateTime(2026, 10, 5),
        actionDate: DateTime(2026, 9, 20),
      ),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'documents_wallet', folder: _folder);

    await tester.tap(
      find.byKey(const ValueKey<String>('featured-document-pass')),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'document_pass', folder: _folder);
    await reveal(tester, find.text('Important dates'));
    await saveScreenshot(tester, 'document_deadline', folder: _folder);
    await reveal(tester, find.text('Document information'));
    await saveScreenshot(tester, 'document_information', folder: _folder);
    await reveal(tester, find.text('Renewal history'));
    await saveScreenshot(tester, 'document_history', folder: _folder);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'add_start', folder: _folder);
    await tester.tap(find.byKey(const ValueKey<String>('entry-manual')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'add_identity', folder: _folder);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Travel passport',
    );
    await tester.tap(find.byKey(const ValueKey<String>('field-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('category-passport')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'add_dates', folder: _folder);
    dates.results['expiry'] = DateTime(2027, 11, 12);
    await tester.tap(find.byKey(const ValueKey<String>('date-expiry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('impact-high')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'add_planning', folder: _folder);
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'add_review', folder: _folder);
  });

  testWidgets('OCR and responsive fidelity screenshots', (tester) async {
    pixel8(tester, height: 1400);
    ocr.result = DocumentOcrParser.parse('''
Government of India
Aadhaar
Name: SAMPLE USER
1234 5678 9012
''');
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);

    await tester.pumpWidget(wrapForScreenshot(app()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();

    ocr.delay = const Duration(milliseconds: 50);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pump();
    await saveScreenshot(
      tester,
      'ocr_processing',
      folder: _folder,
      settle: false,
    );
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'ocr_review', folder: _folder);
    await saveScreenshot(tester, 'ocr_dynamic_fields', folder: _folder);
    await tester.tap(find.byKey(const ValueKey<String>('ocr-confirm')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Aadhaar card',
    );
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    dates.results['expiry'] = DateTime(2028, 6, 22);
    await tester.tap(find.byKey(const ValueKey<String>('date-expiry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('impact-medium')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('featured-document-pass')),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'saved_dynamic_detail', folder: _folder);
  });

  testWidgets('Arabic and large-text fidelity screenshots', (tester) async {
    pixel8(tester, height: 1400);
    await documents.save(
      sampleDocument(
        name: 'Travel passport',
        ownerName: 'Alex Rivera',
        documentNumber: 'X1234567',
      ),
    );

    await tester.pumpWidget(wrapForScreenshot(app(locale: const Locale('ar'))));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'home_arabic', folder: _folder);
    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'documents_arabic', folder: _folder);
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'add_arabic', folder: _folder);

    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(wrapForScreenshot(app()));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'home_large_text', folder: _folder);
    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('featured-document-pass')),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'document_large_text', folder: _folder);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'add_large_text', folder: _folder);
  });
}
