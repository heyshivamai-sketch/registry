import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/add_document_controller.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/documents/presentation/document_detail_screen.dart';
import 'package:the_registry/features/documents/widgets/document_list_card.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
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

  Future<void> openDocuments(WidgetTester tester) async {
    await tester.tap(_navLabel('Documents'));
    await tester.pumpAndSettle();
  }

  Future<void> openDetail(WidgetTester tester) async {
    await openDocuments(tester);
    await tester.ensureVisible(find.byType(DocumentListCard));
    await tester.tap(find.byType(DocumentListCard));
    await tester.pumpAndSettle();
  }

  Future<void> openEdit(WidgetTester tester) async {
    await openDetail(tester);
    await tester.tap(find.byKey(const ValueKey<String>('document-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('action-edit')));
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

  testWidgets('Document card opens detail', (tester) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('Document details'), findsOneWidget);
    expect(find.text('Family passport'), findsWidgets);
    expect(find.text('Passport'), findsWidgets);
  });

  testWidgets('Digital pass, dates, masked number and empty optionals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(
      sampleDocument(
        issuingAuthority: null,
        costOfLapsing: null,
        dependency: null,
        expectedChanges: null,
        notes: null,
        reminders: {},
        ownerName: 'Amira',
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.textContaining('Amira'), findsWidgets);
    expect(find.text('••••••5678'), findsOneWidget);
    expect(find.text('Deadline health'), findsOneWidget);
    expect(
      find.text(
        RegistryDateFormatter.dayMonthYear(DateTime(2027, 10, 5), 'en'),
      ),
      findsWidgets,
    );
    expect(find.text('No reminders selected'), findsOneWidget);
    expect(find.text('No photo attached'), findsOneWidget);
    expect(find.text('No renewals recorded yet.'), findsOneWidget);
    expect(find.text('Issued by'), findsNothing);
    expect(find.text('Cost of lapsing'), findsNothing);
  });

  testWidgets('Attachment and populated reminders render on detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(
      sampleDocument(
        attachmentBytes: kTinyPngBytes,
        reminders: {
          ReminderPreference.onActionDate,
          ReminderPreference.sevenDaysBefore,
        },
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('On action date'), findsOneWidget);
    expect(find.text('7 days before'), findsOneWidget);
  });

  testWidgets('Edit action prefills every supported field and image', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(sampleDocument(attachmentBytes: kTinyPngBytes));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openEdit(tester);

    expect(find.byType(AddDocumentScreen), findsOneWidget);
    expect(find.text('Edit document'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('field-name')))
          .controller!
          .text,
      'Family passport',
    );
    expect(find.text('Passport'), findsWidgets);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('field-owner')))
          .controller!
          .text,
      'Amira',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('field-number')))
          .controller!
          .text,
      'AB12345678',
    );
    expect(find.text('17 Sep 2026'), findsOneWidget);
    expect(find.text('05 Oct 2027'), findsOneWidget);
    expect(find.text('01 Sep 2027'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await reveal(
      tester,
      find.byKey(const ValueKey<String>('section-additional')),
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('field-issuer')))
          .controller!
          .text,
      'Algeria',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('field-cost')))
          .controller!
          .text,
      'Travel disruption',
    );
  });

  testWidgets('Edit image replace and remove work', (tester) async {
    await documents.save(sampleDocument(attachmentBytes: kTinyPngBytes));
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openEdit(tester);

    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('attach-replace')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('replace-source-gallery')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('attach-remove')));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Edit validation blocks empty required fields', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openEdit(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
    expect(find.byType(AddDocumentScreen), findsOneWidget);
  });

  testWidgets('Dirty edit shows discard dialog', (tester) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openEdit(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Changed name',
    );
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets('Clean edit does not show discard dialog', (tester) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openEdit(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byType(DocumentDetailScreen), findsOneWidget);
  });

  testWidgets('Update returns to refreshed detail without duplicating', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openEdit(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Updated passport',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('Updated passport'), findsWidgets);
    expect(find.text('Document updated for this session.'), findsOneWidget);
    expect(documents.documents, hasLength(1));
    expect(documents.documents.single.id, 'doc_1');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentListCard), findsOneWidget);
    expect(find.text('Updated passport'), findsOneWidget);
  });

  testWidgets('Delete cancel keeps the document', (tester) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);
    await tester.tap(find.byKey(const ValueKey<String>('document-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('action-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this document?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('delete-cancel')));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(documents.documents, hasLength(1));
  });

  testWidgets('Delete confirm returns to Documents and removes the card', (
    tester,
  ) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);
    await tester.tap(find.byKey(const ValueKey<String>('document-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('action-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailScreen), findsNothing);
    expect(find.byType(DocumentListCard), findsNothing);
    expect(find.text('Document deleted from this session.'), findsOneWidget);
    expect(find.text('No documents yet'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });

  testWidgets('Missing document is handled safely', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final navigator = Navigator.of(tester.element(find.byType(AppShell)));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const DocumentDetailScreen(documentId: 'missing'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Document not available'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('document-unavailable')),
      findsOneWidget,
    );
  });

  testWidgets('Arabic RTL detail', (tester) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('المستندات'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DocumentListCard));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المستند'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(DocumentDetailScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('Record renewal updates expiry and history', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(sampleDocument());
    dates.results['new-expiry'] = DateTime(2032, 10, 5);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);
    await reveal(tester, find.byKey(const ValueKey<String>('record-renewal')));
    await tester.tap(find.byKey(const ValueKey<String>('record-renewal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('date-new-expiry')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('renewal-note')),
      'Embassy visit',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-renewal')));
    await tester.pumpAndSettle();

    expect(find.text('Renewal recorded for this session.'), findsOneWidget);
    expect(find.text('Embassy visit'), findsOneWidget);
    expect(find.text('05 Oct 2032'), findsWidgets);
    expect(documents.documents.single.renewalHistory, hasLength(1));
    expect(documents.documents.single.actionDate, DateTime(2027, 9, 1));
  });

  testWidgets('Home and Documents add entry points still work', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-document')));
    await tester.pumpAndSettle();
    expect(find.byType(AddDocumentScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await openDocuments(tester);
    await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
    await tester.pumpAndSettle();
    expect(find.byType(AddDocumentScreen), findsOneWidget);
  });

  testWidgets(
    'Large text and small screen have no overflow on form and detail',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final overflows = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        overflows.add(details);
        original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);

      await documents.save(sampleDocument(attachmentBytes: kTinyPngBytes));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final navigator = Navigator.of(tester.element(find.byType(AppShell)));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const DocumentDetailScreen(documentId: 'doc_1'),
        ),
      );
      await tester.pumpAndSettle();
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const AddDocumentScreen(documentId: 'doc_1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        overflows.where((details) => details.toString().contains('overflowed')),
        isEmpty,
      );
    },
  );

  DateTime dateOnlyToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  testWidgets('High-impact Active document does not need attention', (
    tester,
  ) async {
    final today = dateOnlyToday();
    await documents.save(
      sampleDocument(
        impact: DocumentImpact.high,
        expiryDate: today.add(const Duration(days: 420)),
        actionDate: today.add(const Duration(days: 390)),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);

    expect(find.text('0 need attention'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DocumentListCard),
        matching: find.text('Active'),
      ),
      findsOneWidget,
    );
    expect(find.text('Action needed'), findsNothing);
  });

  testWidgets('High-impact Action needed document counts as attention', (
    tester,
  ) async {
    final today = dateOnlyToday();
    await documents.save(
      sampleDocument(
        impact: DocumentImpact.high,
        expiryDate: today.add(const Duration(days: 40)),
        actionDate: today.subtract(const Duration(days: 2)),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);

    expect(find.text('1 needs attention'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DocumentListCard),
        matching: find.text('Action needed'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Overdue document is counted as needing attention', (
    tester,
  ) async {
    final today = dateOnlyToday();
    await documents.save(
      sampleDocument(
        impact: DocumentImpact.low,
        expiryDate: today.subtract(const Duration(days: 3)),
        actionDate: today.subtract(const Duration(days: 30)),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);

    expect(find.text('1 needs attention'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DocumentListCard),
        matching: find.text('Overdue'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Renewal that becomes Active updates the attention summary immediately',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final today = dateOnlyToday();
      await documents.save(
        sampleDocument(
          impact: DocumentImpact.high,
          expiryDate: today.add(const Duration(days: 20)),
          actionDate: today.subtract(const Duration(days: 1)),
        ),
      );
      dates.results['new-expiry'] = today.add(const Duration(days: 420));
      dates.results['new-action'] = today.add(const Duration(days: 390));

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await openDocuments(tester);
      expect(find.text('1 needs attention'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DocumentListCard),
          matching: find.text('Action needed'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(DocumentListCard));
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const ValueKey<String>('record-renewal')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('record-renewal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('date-new-expiry')));
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const ValueKey<String>('date-new-action')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('date-new-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('save-renewal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('0 need attention'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DocumentListCard),
          matching: find.text('Active'),
        ),
        findsOneWidget,
      );
      expect(find.text('Action needed'), findsNothing);
    },
  );

  testWidgets('Arabic remaining-days values render from ARB strings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = dateOnlyToday();
    final cases = <int, String>{
      1: 'متبقي يوم واحد',
      2: 'متبقي يومين',
      5: 'متبقي 5 أيام',
      55: 'متبقي 55 يومًا',
    };

    for (final entry in cases.entries) {
      await documents.save(
        sampleDocument(
          id: 'days_${entry.key}',
          name: 'Passport ${entry.key}',
          expiryDate: today.add(Duration(days: entry.key + 40)),
          actionDate: today.add(Duration(days: entry.key)),
        ),
      );
    }

    await tester.pumpWidget(app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('المستندات'));
    await tester.pumpAndSettle();

    for (final entry in cases.entries) {
      await tester.tap(find.text('Passport ${entry.key}'));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  });

  test('Controller dirty tracking distinguishes create and edit', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final controller = AddDocumentController();
    expect(controller.isDirty, isFalse);
    controller.setName('Draft');
    expect(controller.isDirty, isTrue);
    expect(controller.validate(l10n), isFalse);

    final edit = AddDocumentController()..loadDocument(sampleDocument());
    expect(edit.isDirty, isFalse);
    edit.setName('Family passport');
    expect(edit.isDirty, isFalse);
    edit.setName('Other');
    expect(edit.isDirty, isTrue);
  });
}
