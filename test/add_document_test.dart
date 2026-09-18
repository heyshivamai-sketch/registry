import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/documents/presentation/add_document_controller.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/documents/widgets/document_list_card.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/save_screenshot.dart';
import 'support/tiny_png.dart';

Finder _navLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryDocumentRepository documents;
  late FakeImagePickerService images;
  late FakeDatePickerService dates;

  Widget app({Locale locale = const Locale('en')}) {
    return RegistryApp(
      onboardingRepository: FakeOnboardingRepository(completed: true),
      documentRepository: documents,
      imagePickerService: images,
      datePickerService: dates,
      locale: locale,
    );
  }

  setUp(() {
    documents = InMemoryDocumentRepository();
    images = FakeImagePickerService();
    dates = FakeDatePickerService();
  });

  Future<void> openFromHomeSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-document')));
    await tester.pumpAndSettle();
  }

  Future<void> openFromDocumentsTab(WidgetTester tester) async {
    await tester.tap(_navLabel('Documents'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignment: 0.35,
      duration: Duration.zero,
    );
    await tester.pump();
  }

  Future<void> fillRequiredFields(WidgetTester tester) async {
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

    dates.results['expiry'] = DateTime(2027, 10, 5);
    await reveal(tester, find.byKey(const ValueKey<String>('date-expiry')));
    await tester.tap(find.byKey(const ValueKey<String>('date-expiry')));
    await tester.pumpAndSettle();

    await reveal(tester, find.byKey(const ValueKey<String>('impact-high')));
    await tester.tap(find.byKey(const ValueKey<String>('impact-high')));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
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

    dates.results['issue'] = DateTime(2028, 1, 1);
    await reveal(tester, find.byKey(const ValueKey<String>('date-issue')));
    await tester.tap(find.byKey(const ValueKey<String>('date-issue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
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

    dates.results['action'] = DateTime(2028, 2, 1);
    await reveal(tester, find.byKey(const ValueKey<String>('date-action')));
    await tester.tap(find.byKey(const ValueKey<String>('date-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
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
    await tester.tap(find.byKey(const ValueKey<String>('attach-remove')));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.text('Add a photo of this document'), findsOneWidget);
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
    expect(find.byKey(const ValueKey<String>('save-document')), findsOneWidget);
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
    expect(find.byType(DocumentListCard), findsOneWidget);
    expect(find.text('Family passport'), findsOneWidget);
    expect(find.text('Document saved to this session.'), findsOneWidget);
    expect(find.textContaining('1 saved'), findsOneWidget);
    expect(find.textContaining('need attention'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DocumentListCard),
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
    await reveal(tester, find.byKey(const ValueKey<String>('date-action')));
    await tester.tap(find.byKey(const ValueKey<String>('date-action')));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();

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
    await reveal(tester, find.byKey(const ValueKey<String>('reminder-30')));

    final reminderBox = tester.getRect(
      find.byKey(const ValueKey<String>('reminder-30')),
    );
    final saveBox = tester.getRect(
      find.byKey(const ValueKey<String>('save-document')),
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
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(wrapForScreenshot(app()));
    await tester.pumpAndSettle();
    await openFromDocumentsTab(tester);
    await saveScreenshot(tester, 'empty_attachment');

    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.tap(find.byKey(const ValueKey<String>('attach-gallery')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'selected_attachment');

    await tester.tap(find.byKey(const ValueKey<String>('attach-remove')));
    await tester.pumpAndSettle();
    await fillRequiredFields(tester);
    dates.results['issue'] = DateTime(2026, 9, 17);
    await reveal(tester, find.byKey(const ValueKey<String>('date-issue')));
    await tester.tap(find.byKey(const ValueKey<String>('date-issue')));
    await tester.pumpAndSettle();
    dates.results['action'] = DateTime(2027, 8, 17);
    await reveal(tester, find.byKey(const ValueKey<String>('date-action')));
    await tester.tap(find.byKey(const ValueKey<String>('date-action')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey<String>('impact-high')));
    await tester.tap(find.byKey(const ValueKey<String>('effort-moderate')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey<String>('reminder-action')));
    await tester.tap(find.byKey(const ValueKey<String>('reminder-action')));
    await tester.tap(find.byKey(const ValueKey<String>('reminder-7')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'selected_chips');

    await reveal(tester, find.byKey(const ValueKey<String>('date-issue')));
    await saveScreenshot(tester, 'full_year_dates');

    await reveal(tester, find.byKey(const ValueKey<String>('reminder-30')));
    await saveScreenshot(tester, 'bottom_above_save');

    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, 'saved_document_card');
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
}
