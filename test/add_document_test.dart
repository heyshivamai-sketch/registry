import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_ocr_parser.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/documents/presentation/add_document_controller.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_document_ocr_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
import 'support/save_screenshot.dart';
import 'support/tiny_png.dart';

Finder _navLabel(String label) {
  return switch (label) {
    'Documents' => find.byKey(const ValueKey<String>('nav-documents')),
    'Subscriptions' => find.byKey(const ValueKey<String>('nav-subscriptions')),
    'Home' => find.byKey(const ValueKey<String>('nav-home')),
    'Profile' => find.byKey(const ValueKey<String>('nav-profile')),
    _ => find.byTooltip(label),
  };
}

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

  Future<void> openFromHomeSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-document')));
    await tester.pumpAndSettle();
  }

  Future<void> tapDocumentsAdd(WidgetTester tester) async {
    final add = find.byKey(const ValueKey<String>('documents-add'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
  }

  Future<void> openFromDocumentsTab(WidgetTester tester) async {
    await tester.tap(_navLabel('Documents'));
    await tester.pumpAndSettle();
    await tapDocumentsAdd(tester);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignment: 0.35,
      duration: Duration.zero,
    );
    await tester.pump();
  }

  Future<void> continueWizard(WidgetTester tester) async {
    await reveal(tester, find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
  }

  Future<void> goToDates(WidgetTester tester) async {
    await continueWizard(tester);
    await reveal(tester, find.byKey(const ValueKey<String>('field-name')));
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Family passport',
    );
    await reveal(tester, find.byKey(const ValueKey<String>('field-category')));
    await tester.tap(find.byKey(const ValueKey<String>('field-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('category-passport')));
    await tester.pumpAndSettle();
    await continueWizard(tester);
  }

  Future<void> goToRenewal(WidgetTester tester) async {
    await goToDates(tester);
    dates.results['expiry'] = DateTime(2027, 10, 5);
    await reveal(tester, find.byKey(const ValueKey<String>('date-expiry')));
    await tester.tap(find.byKey(const ValueKey<String>('date-expiry')));
    await tester.pumpAndSettle();
    await continueWizard(tester);
  }

  Future<void> fillRequiredFields(WidgetTester tester) async {
    await continueWizard(tester);
    await reveal(tester, find.byKey(const ValueKey<String>('field-name')));
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Family passport',
    );
    await reveal(tester, find.byKey(const ValueKey<String>('field-category')));
    await tester.tap(find.byKey(const ValueKey<String>('field-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('category-passport')));
    await tester.pumpAndSettle();
    await continueWizard(tester);

    dates.results['expiry'] = DateTime(2027, 10, 5);
    await reveal(tester, find.byKey(const ValueKey<String>('date-expiry')));
    await tester.tap(find.byKey(const ValueKey<String>('date-expiry')));
    await tester.pumpAndSettle();
    await continueWizard(tester);

    await reveal(tester, find.byKey(const ValueKey<String>('impact-high')));
    await tester.tap(find.byKey(const ValueKey<String>('impact-high')));
    await tester.pumpAndSettle();
    await continueWizard(tester);
  }

  testWidgets('Add Document opens from Home add sheet', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromHomeSheet(tester);

    expect(find.byType(AddDocumentScreen), findsOneWidget);
    expect(find.text('Add a document'), findsOneWidget);
    expect(find.text('Scan or enter the details manually.'), findsOneWidget);
  });

  testWidgets('Add Document opens from Documents tab', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);

    expect(find.byType(AddDocumentScreen), findsOneWidget);
    expect(find.text('Add a document'), findsOneWidget);
  });

  testWidgets('Required field validation', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);

    await tester.tap(find.byKey(const ValueKey<String>('entry-manual')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
  });

  testWidgets('Invalid issue/expiry date validation', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await fillRequiredFields(tester);
    await reveal(
      tester,
      find.byKey(const ValueKey<String>('review-jump-dates')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('review-jump-dates')));
    await tester.pumpAndSettle();

    dates.results['issue'] = DateTime(2028, 1, 1);
    await reveal(tester, find.byKey(const ValueKey<String>('date-issue')));
    await tester.tap(find.byKey(const ValueKey<String>('date-issue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Issue date cannot be after the expiry date.'),
      findsOneWidget,
    );
  });

  testWidgets('Invalid action/expiry date validation', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await fillRequiredFields(tester);
    await reveal(
      tester,
      find.byKey(const ValueKey<String>('review-jump-dates')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('review-jump-dates')));
    await tester.pumpAndSettle();

    dates.results['action'] = DateTime(2028, 2, 1);
    await reveal(tester, find.byKey(const ValueKey<String>('date-action')));
    await tester.tap(find.byKey(const ValueKey<String>('date-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Renewal start date cannot be after the expiry date.'),
      findsOneWidget,
    );
  });

  testWidgets('Fake gallery image selection displays preview', (tester) async {
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);

    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attach-remove')), findsOneWidget);
  });

  testWidgets('Remove attachment clears preview', (tester) async {
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);

    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey<String>('attach-remove')));
    await tester.tap(find.byKey(const ValueKey<String>('attach-remove')));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const ValueKey<String>('entry-manual')), findsOneWidget);
  });

  testWidgets('Cancelled picker leaves the form usable', (tester) async {
    images.galleryResult = const ImagePickResult.cancelled();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);

    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();

    expect(find.byType(AddDocumentScreen), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('wizard-continue')),
      findsOneWidget,
    );
  });

  testWidgets('Successful save adds the document to Documents', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await fillRequiredFields(tester);

    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
    await tester.pumpAndSettle();

    expect(find.byType(AddDocumentScreen), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('featured-document-pass')),
      findsOneWidget,
    );
    expect(find.text('Family passport'), findsOneWidget);
    expect(find.text('Document saved to this session.'), findsOneWidget);
    expect(find.textContaining('1 saved'), findsOneWidget);
    expect(find.textContaining('need attention'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('featured-document-pass')),
        matching: find.byType(Icon),
      ),
      findsWidgets,
    );
  });

  testWidgets('Saved card shows action date and expiry separately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await fillRequiredFields(tester);

    dates.results['action'] = DateTime(2027, 9, 1);
    await reveal(
      tester,
      find.byKey(const ValueKey<String>('review-jump-dates')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('review-jump-dates')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey<String>('date-action')));
    await tester.tap(find.byKey(const ValueKey<String>('date-action')));
    await tester.pumpAndSettle();
    await continueWizard(tester);
    await continueWizard(tester);
    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Start by'), findsOneWidget);
    expect(find.textContaining('Expires'), findsOneWidget);
    expect(
      find.textContaining(
        RegistryDateFormatter.dayMonthYear(DateTime(2027, 9, 1), 'en'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        RegistryDateFormatter.dayMonthYear(DateTime(2027, 10, 5), 'en'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Back with dirty form shows discard confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('entry-manual')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey<String>('field-name')));
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Draft name',
    );
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Discard this draft?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('discard-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(AddDocumentScreen), findsNothing);
  });

  testWidgets('Arabic Add Document flow renders RTL', (tester) async {
    await tester.pumpWidget(app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('المستندات'));
    await tester.pumpAndSettle();
    await tapDocumentsAdd(tester);

    expect(find.text('إضافة مستند'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.byType(AddDocumentScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('Small-screen layout has no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details);
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);

    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
    expect(find.byType(AddDocumentScreen), findsOneWidget);
  });

  testWidgets('Renewal helper displays without forced one-line truncation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await goToDates(tester);

    const helper =
        'The date you should start taking action, which may be earlier than the expiry date.';
    await reveal(tester, find.text(helper));
    expect(find.text(helper), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(helper));
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets('Impact options have clear selected and unselected states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await goToRenewal(tester);
    await reveal(tester, find.byKey(const ValueKey<String>('impact-high')));

    FilterChip chipOf(String key) {
      return tester.widget<FilterChip>(
        find.descendant(
          of: find.byKey(ValueKey<String>(key)),
          matching: find.byType(FilterChip),
        ),
      );
    }

    expect(chipOf('impact-low').selected, isFalse);
    expect(chipOf('impact-low').side?.color, isNot(Colors.transparent));
    await tester.tap(find.byKey(const ValueKey<String>('impact-high')));
    await tester.pumpAndSettle();
    expect(chipOf('impact-high').selected, isTrue);
    expect(chipOf('impact-high').showCheckmark, isTrue);
    expect(chipOf('impact-low').selected, isFalse);
  });

  testWidgets('Renewal effort selection works', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await goToRenewal(tester);
    await reveal(tester, find.byKey(const ValueKey<String>('effort-moderate')));
    await tester.tap(find.byKey(const ValueKey<String>('effort-moderate')));
    await tester.pumpAndSettle();

    final selected = tester.widget<FilterChip>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('effort-moderate')),
        matching: find.byType(FilterChip),
      ),
    );
    expect(selected.selected, isTrue);
  });

  testWidgets('Reminder multi-selection works', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await goToRenewal(tester);
    await reveal(tester, find.byKey(const ValueKey<String>('reminder-30')));
    await tester.tap(find.byKey(const ValueKey<String>('reminder-action')));
    await tester.tap(find.byKey(const ValueKey<String>('reminder-7')));
    await tester.pumpAndSettle();

    bool selected(String key) {
      return tester
          .widget<FilterChip>(
            find.descendant(
              of: find.byKey(ValueKey<String>(key)),
              matching: find.byType(FilterChip),
            ),
          )
          .selected;
    }

    expect(selected('reminder-action'), isTrue);
    expect(selected('reminder-7'), isTrue);
    expect(selected('reminder-30'), isFalse);
  });

  testWidgets('Empty attachment state shows Camera and Gallery actions', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);

    expect(find.byKey(const ValueKey<String>('attach-camera')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('attach-gallery')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('attach-replace')), findsNothing);
    expect(find.byKey(const ValueKey<String>('attach-remove')), findsNothing);
  });

  testWidgets('Selected attachment state shows only Replace and Remove', (
    tester,
  ) async {
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attach-camera')), findsNothing);
    expect(find.byKey(const ValueKey<String>('attach-gallery')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('attach-replace')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('attach-remove')), findsOneWidget);
  });

  testWidgets('Replace source chooser shows Camera and Gallery', (
    tester,
  ) async {
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey<String>('attach-replace')));
    await tester.tap(find.byKey(const ValueKey<String>('attach-replace')));
    await tester.pumpAndSettle();

    expect(find.text('Replace photo'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('replace-source-camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('replace-source-gallery')),
      findsOneWidget,
    );
  });

  testWidgets('Cancelled Replace retains the original image', (tester) async {
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();

    images.galleryResult = const ImagePickResult.cancelled();
    await reveal(tester, find.byKey(const ValueKey<String>('attach-replace')));
    await tester.tap(find.byKey(const ValueKey<String>('attach-replace')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('replace-source-gallery')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('attach-replace')),
      findsOneWidget,
    );
  });

  testWidgets('Final form controls scroll completely above the Save button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await goToRenewal(tester);
    await reveal(tester, find.byKey(const ValueKey<String>('reminder-30')));

    final reminderBox = tester.getRect(
      find.byKey(const ValueKey<String>('reminder-30')),
    );
    final saveBox = tester.getRect(
      find.byKey(const ValueKey<String>('wizard-continue')),
    );
    expect(reminderBox.bottom, lessThanOrEqualTo(saveBox.top + 0.5));
  });

  testWidgets('Issue, expiry and action dates display day month and year', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await fillRequiredFields(tester);
    await reveal(
      tester,
      find.byKey(const ValueKey<String>('review-jump-dates')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('review-jump-dates')));
    await tester.pumpAndSettle();

    dates.results['issue'] = DateTime(2026, 9, 17);
    await reveal(tester, find.byKey(const ValueKey<String>('date-issue')));
    await tester.tap(find.byKey(const ValueKey<String>('date-issue')));
    await tester.pumpAndSettle();

    dates.results['action'] = DateTime(2027, 8, 17);
    await reveal(tester, find.byKey(const ValueKey<String>('date-action')));
    await tester.tap(find.byKey(const ValueKey<String>('date-action')));
    await tester.pumpAndSettle();

    expect(find.text('17 Sep 2026'), findsOneWidget);
    expect(find.text('05 Oct 2027'), findsOneWidget);
    expect(find.text('17 Aug 2027'), findsOneWidget);
  });

  testWidgets('French date display does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details);
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(app(locale: const Locale('fr')));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('Documents'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('documents-add')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();
    await goToDates(tester);

    dates.results['expiry'] = DateTime(2027, 10, 5);
    await reveal(tester, find.byKey(const ValueKey<String>('date-expiry')));
    await tester.tap(find.byKey(const ValueKey<String>('date-expiry')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        RegistryDateFormatter.dayMonthYear(DateTime(2027, 10, 5), 'fr'),
      ),
      findsOneWidget,
    );
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('Arabic date display remains RTL and does not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details);
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('المستندات'));
    await tester.pumpAndSettle();
    await tapDocumentsAdd(tester);
    await goToDates(tester);

    dates.results['expiry'] = DateTime(2027, 10, 5);
    await reveal(tester, find.byKey(const ValueKey<String>('date-expiry')));
    await tester.tap(find.byKey(const ValueKey<String>('date-expiry')));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(AddDocumentScreen))),
      TextDirection.rtl,
    );
    expect(
      find.text(
        RegistryDateFormatter.dayMonthYear(DateTime(2027, 10, 5), 'ar'),
      ),
      findsOneWidget,
    );
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  test('Full date formatter always includes year', () {
    expect(
      RegistryDateFormatter.dayMonthYear(DateTime(2026, 9, 17), 'en'),
      '17 Sep 2026',
    );
  });

  testWidgets('Screenshots for Add Document milestone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ocr.result = const DocumentOcrResult.cancelled();

    await tester.pumpWidget(wrapForScreenshot(app()));
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await saveScreenshot(
      tester,
      'add_document_start',
      folder: 'registry_aura_phase3',
    );

    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'selected_attachment',
      folder: 'registry_aura_phase3',
    );

    await reveal(tester, find.byKey(const ValueKey<String>('attach-remove')));
    await tester.tap(find.byKey(const ValueKey<String>('attach-remove')));
    await tester.pumpAndSettle();
    await fillRequiredFields(tester);
    await reveal(
      tester,
      find.byKey(const ValueKey<String>('review-jump-dates')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('review-jump-dates')));
    await tester.pumpAndSettle();
    dates.results['issue'] = DateTime(2026, 9, 17);
    await reveal(tester, find.byKey(const ValueKey<String>('date-issue')));
    await tester.tap(find.byKey(const ValueKey<String>('date-issue')));
    await tester.pumpAndSettle();
    dates.results['action'] = DateTime(2027, 8, 17);
    await reveal(tester, find.byKey(const ValueKey<String>('date-action')));
    await tester.tap(find.byKey(const ValueKey<String>('date-action')));
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'full_year_dates',
      folder: 'registry_aura_phase3',
    );
    await continueWizard(tester);
    await reveal(tester, find.byKey(const ValueKey<String>('impact-high')));
    await tester.tap(find.byKey(const ValueKey<String>('effort-moderate')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey<String>('reminder-action')));
    await tester.tap(find.byKey(const ValueKey<String>('reminder-action')));
    await tester.tap(find.byKey(const ValueKey<String>('reminder-7')));
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'renewal_planning',
      folder: 'registry_aura_phase3',
    );
    await reveal(tester, find.byKey(const ValueKey<String>('reminder-30')));
    await saveScreenshot(
      tester,
      'bottom_above_save',
      folder: 'registry_aura_phase3',
    );
    await continueWizard(tester);
    await saveScreenshot(
      tester,
      'review_and_save',
      folder: 'registry_aura_phase3',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'saved_dynamic_detail',
      folder: 'registry_aura_phase3',
    );
  });

  test('Controller validates required and date order', () {
    final controller = AddDocumentController();
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(controller.validate(l10n), isFalse);
    expect(controller.nameError, isNotNull);
    expect(controller.expiryError, isNotNull);

    controller
      ..setName('Visa')
      ..setCategory(DocumentCategory.visaResidence)
      ..setExpiryDate(DateTime.utc(2026, 6, 1))
      ..setIssueDate(DateTime.utc(2026, 8, 1))
      ..setImpact(DocumentImpact.medium);

    expect(controller.validate(l10n), isFalse);
    expect(controller.issueDateError, isNotNull);

    controller
      ..setIssueDate(DateTime.utc(2026, 1, 1))
      ..setActionDate(DateTime.utc(2026, 7, 1));
    expect(controller.validate(l10n), isFalse);
    expect(controller.actionDateError, isNotNull);

    controller.setActionDate(DateTime.utc(2026, 5, 1));
    expect(controller.validate(l10n), isTrue);
  });

  testWidgets('Create starts at step 1', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    expect(find.text('How would you like to add it?'), findsOneWidget);
    expect(find.textContaining('Step 1 of 5'), findsOneWidget);
  });

  testWidgets('OCR success opens review and confirm does not save', (
    tester,
  ) async {
    ocr.result = DocumentOcrParser.parse('''
Government of India
Aadhaar
Name: SAMPLE NAME
1234 5678 9012
''');
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('ocr-review')), findsOneWidget);
    expect(find.text('Aadhaar'), findsWidgets);
    expect(find.text('Document type'), findsWidgets);
    expect(find.text('Category'), findsWidgets);
    expect(find.text('ID card'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('ocr-schema')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ocr-category')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('ocr-schema')),
        matching: find.text('Document type'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('ocr-schema')),
        matching: find.text('Aadhaar'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('ocr-category')),
        matching: find.text('Category'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('ocr-category')),
        matching: find.text('ID card'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('ocr-country')),
        matching: find.text('Country or region'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('ocr-country')),
        matching: find.text('India'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('ocr-confirm')));
    await tester.pumpAndSettle();
    expect(documents.documents, isEmpty);
    expect(find.byKey(const ValueKey<String>('field-name')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('field-schema')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('field-category')),
      findsOneWidget,
    );
    expect(find.text('Document type'), findsWidgets);
    expect(find.text('Category *'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('field-schema')),
        matching: find.text('Aadhaar'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('field-category')),
        matching: find.text('ID card'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('field-country')),
        matching: find.text('India'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('OCR failure keeps the image and allows retry', (tester) async {
    ocr.result = const DocumentOcrResult.failed();
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('ocr-failed')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ocr-retry')), findsOneWidget);
  });

  testWidgets('OCR cancellation is not treated as an error', (tester) async {
    ocr.result = const DocumentOcrResult.cancelled();
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('ocr-failed')), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Add and remove custom field', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('entry-manual')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-custom-field')));
    await tester.pumpAndSettle();
    expect(find.text('Field name'), findsOneWidget);
    await tester.tap(find.text('Remove field'));
    await tester.pumpAndSettle();
    expect(find.text('Remove field'), findsNothing);
  });

  testWidgets('Double save is prevented by the controller', (tester) async {
    final controller = AddDocumentController()
      ..setName('Visa')
      ..setCategory(DocumentCategory.visaResidence)
      ..setExpiryDate(DateTime.utc(2026, 6, 1))
      ..setImpact(DocumentImpact.medium);
    final l10n = lookupAppLocalizations(const Locale('en'));
    controller.saving = true;
    expect(await controller.submit(l10n: l10n, save: (_) async {}), isFalse);
  });

  test('Empty dynamic fields are omitted from the saved document', () {
    final controller = AddDocumentController()
      ..setName('Visa')
      ..setCategory(DocumentCategory.visaResidence)
      ..setExpiryDate(DateTime.utc(2026, 6, 1))
      ..setImpact(DocumentImpact.medium)
      ..addCustomField(label: 'Club', value: '  ');
    expect(controller.toDocument().dynamicFields, isEmpty);
  });

  testWidgets('Phase 3 extra screenshots', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> remount({Locale locale = const Locale('en')}) async {
      await tester.pumpWidget(wrapForScreenshot(app(locale: locale)));
      await tester.pumpAndSettle();
    }

    await remount();
    await openFromDocumentsTab(tester);
    await continueWizard(tester);
    await saveScreenshot(
      tester,
      'manual_identity',
      folder: 'registry_aura_phase3',
    );

    await reveal(tester, find.byKey(const ValueKey<String>('field-name')));
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Family passport',
    );
    await reveal(tester, find.byKey(const ValueKey<String>('field-category')));
    await tester.tap(find.byKey(const ValueKey<String>('field-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('category-passport')));
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.byKey(const ValueKey<String>('add-custom-field')),
    );
    await saveScreenshot(
      tester,
      'dynamic_fields',
      folder: 'registry_aura_phase3',
    );
    await continueWizard(tester);
    await saveScreenshot(
      tester,
      'important_dates',
      folder: 'registry_aura_phase3',
    );

    await remount(locale: const Locale('ar'));
    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    await tapDocumentsAdd(tester);
    await saveScreenshot(
      tester,
      'add_document_arabic',
      folder: 'registry_aura_phase3',
    );

    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    await remount();
    await openFromDocumentsTab(tester);
    await saveScreenshot(
      tester,
      'add_document_large_text',
      folder: 'registry_aura_phase3',
    );
    tester.platformDispatcher.clearTextScaleFactorTestValue();

    ocr.result = const DocumentOcrResult.cancelled();
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await remount();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey<String>('attach-replace')));
    await tester.tap(find.byKey(const ValueKey<String>('attach-replace')));
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'scan_source_sheet',
      folder: 'registry_aura_phase3',
    );

    ocr.delay = const Duration(milliseconds: 400);
    ocr.result = DocumentOcrParser.parse('''
Government of India
Aadhaar
Name: SAMPLE NAME
DOB: 1990
Gender: Female
1234 5678 9012
Address: SAMPLE STREET, CITY
''');
    await remount();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pump();
    await saveScreenshot(
      tester,
      'ocr_processing',
      folder: 'registry_aura_phase3',
      settle: false,
    );
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'ocr_review_aadhaar',
      folder: 'registry_aura_phase3',
    );
    ocr.delay = null;

    ocr.result = DocumentOcrParser.parse('''
Membership Card
Club: SAMPLE CLUB
Member code: ZX-99
''');
    await remount();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'ocr_low_confidence',
      folder: 'registry_aura_phase3',
    );

    ocr.result = DocumentOcrParser.parse('''
PASSPORT
Passport No. P1234567
Surname SAMPLE
Given names JANE MARIE
Nationality SAMPLELAND
Date of birth 12 JAN 1990
Date of issue 01 MAR 2020
Date of expiry 01 MAR 2030
Authority SAMPLE OFFICE
''');
    await remount();
    await openFromDocumentsTab(tester);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    await saveScreenshot(
      tester,
      'ocr_passport',
      folder: 'registry_aura_phase3',
    );

    await documents.save(
      sampleDocument(
        schemaId: DocumentSchemaIds.genericPassport,
        countryCode: DocumentCountryCodes.generic,
        dynamicFields: const [
          DocumentFieldValue(
            id: DocumentFieldKeys.nationality,
            fieldKey: DocumentFieldKeys.nationality,
            value: 'Sampleland',
          ),
        ],
      ),
    );
    await remount();
    await tester.tap(_navLabel('Documents'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('featured-document-pass')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('document-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('action-edit')));
    await tester.pumpAndSettle();
    await continueWizard(tester);
    await saveScreenshot(
      tester,
      'edit_prefilled',
      folder: 'registry_aura_phase3',
    );
  });

  testWidgets('Identity selectors keep labels distinct from selected values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await continueWizard(tester);

    final country = find.byKey(const ValueKey<String>('field-country'));
    final schema = find.byKey(const ValueKey<String>('field-schema'));
    final category = find.byKey(const ValueKey<String>('field-category'));

    expect(
      find.descendant(of: country, matching: find.text('Country or region')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: country, matching: find.text('Other')),
      findsNothing,
    );
    expect(
      find.descendant(of: schema, matching: find.text('Document type')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: schema, matching: find.text('Other document')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: category, matching: find.text('Category *')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: category, matching: find.text('ID card')),
      findsNothing,
    );

    await reveal(tester, country);
    await tester.tap(country);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('country-IN')));
    await tester.pumpAndSettle();
    await reveal(tester, category);
    await tester.tap(category);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('category-idCard')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: country, matching: find.text('India')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: country, matching: find.text('Country or region')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: schema, matching: find.text('Aadhaar')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: schema, matching: find.text('Document type')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: category, matching: find.text('ID card')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: category, matching: find.text('Category *')),
      findsOneWidget,
    );
  });

  testWidgets('Identity selectors do not overflow at large text or in Arabic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final overflows = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details);
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('المستندات'));
    await tester.pumpAndSettle();
    await tapDocumentsAdd(tester);
    await continueWizard(tester);

    expect(
      Directionality.of(tester.element(find.byType(AddDocumentScreen))),
      TextDirection.rtl,
    );
    expect(find.text('البلد أو المنطقة'), findsWidgets);
    expect(find.text('نوع المستند'), findsWidgets);
    expect(find.text('الفئة *'), findsWidgets);
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  test('EN FR AR cover Pulse, 90-day and identity labels', () {
    for (final locale in const [Locale('en'), Locale('fr'), Locale('ar')]) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.reviewAction, isNotEmpty);
      expect(l10n.snapshotNinetyDayView, isNotEmpty);
      expect(l10n.horizonOpenCalendar, isNotEmpty);
      expect(l10n.fieldCountry, isNotEmpty);
      expect(l10n.fieldDocumentType, isNotEmpty);
      expect(l10n.fieldCategory, isNotEmpty);
      expect(l10n.catalogReviewTitle, isNotEmpty);
      expect(l10n.horizon90EmptyTitle, isNotEmpty);
    }
    expect(
      lookupAppLocalizations(const Locale('en')).reviewAction,
      'Review now',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).fieldCountry,
      'Country or region',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).fieldDocumentType,
      'Document type',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).fieldCategory,
      'Category',
    );
    expect(
      lookupAppLocalizations(const Locale('fr')).reviewAction,
      'Examiner maintenant',
    );
    expect(
      lookupAppLocalizations(const Locale('ar')).reviewAction,
      'راجع الآن',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).wizardContinue,
      'Continue',
    );
    expect(
      lookupAppLocalizations(const Locale('fr')).wizardContinue,
      'Continuer',
    );
    expect(lookupAppLocalizations(const Locale('ar')).wizardContinue, 'متابعة');
    expect(
      lookupAppLocalizations(const Locale('en')).actionNeeded,
      'Action needed',
    );
    expect(
      lookupAppLocalizations(const Locale('fr')).actionNeeded,
      'Action requise',
    );
    expect(
      lookupAppLocalizations(const Locale('ar')).actionNeeded,
      'يلزم اتخاذ إجراء',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).statusUrgent,
      'Action needed',
    );
  });

  testWidgets('Continue uses a directional icon, not a Unicode arrow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);

    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('→'), findsNothing);
    final icon = tester.widget<Icon>(
      find.byKey(const ValueKey<String>('wizard-continue-arrow')),
    );
    expect(icon.icon, Icons.arrow_forward_rounded);
    expect(icon.icon!.matchTextDirection, isTrue);
  });

  testWidgets('RTL Continue keeps the mirrored forward arrow', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('المستندات'));
    await tester.pumpAndSettle();
    await tapDocumentsAdd(tester);

    expect(
      Directionality.of(tester.element(find.byType(AddDocumentScreen))),
      TextDirection.rtl,
    );
    expect(find.text('متابعة'), findsWidgets);
    expect(find.text('رجوع'), findsNothing);
    final icon = tester.widget<Icon>(
      find.byKey(const ValueKey<String>('wizard-continue-arrow')),
    );
    expect(icon.icon!.matchTextDirection, isTrue);
    expect(find.byKey(const ValueKey<String>('save-document')), findsNothing);
  });
}
