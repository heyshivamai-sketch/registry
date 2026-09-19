import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_navigation_dock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';
import 'package:the_registry/features/documents/presentation/add_document_controller.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/documents/presentation/document_detail_screen.dart';
import 'package:the_registry/features/documents/widgets/document_attachment_preview_page.dart';
import 'package:the_registry/features/documents/widgets/document_list_card.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_document_ocr_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';
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

  Future<void> openDocuments(WidgetTester tester) async {
    await tester.tap(_navLabel('Documents'));
    await tester.pumpAndSettle();
  }

  Future<void> openDetail(WidgetTester tester) async {
    await openDocuments(tester);
    final featured = find.byKey(
      const ValueKey<String>('featured-document-pass'),
    );
    if (featured.evaluate().isNotEmpty) {
      await tester.ensureVisible(featured);
      await tester.tap(featured);
    } else {
      await tester.ensureVisible(find.byType(DocumentListCard));
      await tester.tap(find.byType(DocumentListCard));
    }
    await tester.pumpAndSettle();
  }

  Finder featuredStatus(String label) {
    return find.descendant(
      of: find.byKey(const ValueKey<String>('featured-document-pass')),
      matching: find.text(label),
    );
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

  Future<void> continueWizard(WidgetTester tester) async {
    await reveal(tester, find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();
  }

  testWidgets('Document card opens detail', (tester) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('Document pass'), findsOneWidget);
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
    expect(find.text('••••••5678'), findsWidgets);
    expect(find.text('Deadline health'), findsOneWidget);
    expect(
      find.text(
        RegistryDateFormatter.dayMonthYear(DateTime(2027, 10, 5), 'en'),
      ),
      findsWidgets,
    );
    expect(find.text('No reminders selected'), findsOneWidget);
    expect(find.text('No photo attached'), findsNothing);
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
    expect(documents.documents.single.hasAttachment, isTrue);
    expect(documents.documents.single.reminders, hasLength(2));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);
    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('On action date'), findsOneWidget);
    expect(find.text('7 days before'), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey<String>('open-attachment')));
    expect(find.byType(Image), findsWidgets);
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
    await continueWizard(tester);

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
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('field-issuer')))
          .controller!
          .text,
      'Algeria',
    );
    await continueWizard(tester);
    expect(find.text('17 Sep 2026'), findsOneWidget);
    expect(find.text('05 Oct 2027'), findsOneWidget);
    expect(find.text('01 Sep 2027'), findsOneWidget);
    await continueWizard(tester);
    await reveal(
      tester,
      find.byKey(const ValueKey<String>('section-additional')),
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey<String>('field-cost')))
          .controller!
          .text,
      'Travel disruption',
    );
    await tester.tap(find.byKey(const ValueKey<String>('wizard-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('wizard-back')));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Edit image replace and remove work', (tester) async {
    await documents.save(sampleDocument(attachmentBytes: kTinyPngBytes));
    images.galleryResult = ImagePickResult.success(kTinyPngBytes);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openEdit(tester);

    expect(find.byType(Image), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey<String>('attach-replace')));
    await tester.tap(find.byKey(const ValueKey<String>('attach-replace')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('replace-source-gallery')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    await reveal(tester, find.byKey(const ValueKey<String>('attach-remove')));
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
    await continueWizard(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey<String>('wizard-continue')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
    expect(find.byType(AddDocumentScreen), findsOneWidget);
  });

  testWidgets('Dirty edit shows discard dialog', (tester) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openEdit(tester);
    await continueWizard(tester);
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
    await continueWizard(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('field-name')),
      'Updated passport',
    );
    await continueWizard(tester);
    await continueWizard(tester);
    await continueWizard(tester);
    await tester.tap(find.byKey(const ValueKey<String>('save-document')));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('Updated passport'), findsWidgets);
    expect(find.text('Document updated for this session.'), findsOneWidget);
    expect(documents.documents, hasLength(1));
    expect(documents.documents.single.id, 'doc_1');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('featured-document-pass')),
      findsOneWidget,
    );
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
      tester
          .widget<RegistryAuraNavigationDock>(
            find.byType(RegistryAuraNavigationDock),
          )
          .selectedIndex,
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
    await tester.tap(
      find.byKey(const ValueKey<String>('featured-document-pass')),
    );
    await tester.pumpAndSettle();

    expect(find.text('بطاقة المستند'), findsOneWidget);
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
    expect(featuredStatus('Active'), findsOneWidget);
    expect(featuredStatus('Action needed'), findsNothing);
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
    expect(featuredStatus('Action needed'), findsOneWidget);
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
    expect(featuredStatus('Overdue'), findsOneWidget);
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
      expect(featuredStatus('Action needed'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('featured-document-pass')),
      );
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
      expect(featuredStatus('Active'), findsOneWidget);
      expect(featuredStatus('Action needed'), findsNothing);
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
      final name = find.text('Passport ${entry.key}');
      await tester.ensureVisible(name);
      await tester.tap(name);
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

  Future<void> seedWallet(InMemoryDocumentRepository documents) async {
    final today = dateOnlyToday();
    await documents.save(
      sampleDocument(
        id: 'active',
        name: 'Active warranty',
        category: DocumentCategory.warranty,
        expiryDate: today.add(const Duration(days: 400)),
        actionDate: today.add(const Duration(days: 300)),
        impact: DocumentImpact.low,
      ),
    );
    await documents.save(
      sampleDocument(
        id: 'upcoming',
        name: 'Upcoming certificate',
        category: DocumentCategory.certificate,
        expiryDate: today.add(const Duration(days: 80)),
        actionDate: today.add(const Duration(days: 20)),
      ),
    );
    await documents.save(
      sampleDocument(
        id: 'urgent',
        name: 'Urgent licence',
        category: DocumentCategory.drivingLicence,
        expiryDate: today.add(const Duration(days: 20)),
        actionDate: today.subtract(const Duration(days: 1)),
      ),
    );
    await documents.save(
      sampleDocument(
        id: 'overdue',
        name: 'Overdue visa',
        category: DocumentCategory.visaResidence,
        expiryDate: today.subtract(const Duration(days: 2)),
        actionDate: today.subtract(const Duration(days: 10)),
      ),
    );
  }

  testWidgets('Empty documents wallet shows premium empty state', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);

    expect(find.text('Digital wallet'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('documents-empty')),
      findsOneWidget,
    );
    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('documents-add')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('featured-document-pass')),
      findsNothing,
    );
  });

  testWidgets(
    'Populated wallet features overdue pass and excludes it from cards',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await seedWallet(documents);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await openDocuments(tester);

      expect(
        find.byKey(const ValueKey<String>('featured-document-pass')),
        findsOneWidget,
      );
      expect(featuredStatus('Overdue'), findsOneWidget);
      expect(find.text('Overdue visa'), findsOneWidget);
      expect(find.byType(DocumentListCard), findsNWidgets(3));
      expect(
        find.descendant(
          of: find.byType(DocumentListCard),
          matching: find.text('Overdue visa'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('Featured pass opens real document detail', (tester) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);
    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('Verified details'), findsOneWidget);
  });

  testWidgets('Search, clear and empty results do not mutate repository', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await seedWallet(documents);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('documents-search')),
      'licence',
    );
    await tester.pumpAndSettle();
    expect(find.text('Urgent licence'), findsOneWidget);
    expect(find.text('Overdue visa'), findsNothing);
    expect(documents.documents, hasLength(4));

    await tester.enterText(
      find.byKey(const ValueKey<String>('documents-search')),
      'zzzz-no-match',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('documents-filter-empty')),
      findsOneWidget,
    );
    expect(find.text('No matching documents'), findsOneWidget);
    expect(find.text('No documents yet'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('documents-search-clear')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Overdue visa'), findsOneWidget);
    expect(documents.documents, hasLength(4));
  });

  testWidgets('Search query survives opening and returning from detail', (
    tester,
  ) async {
    await documents.save(sampleDocument());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('documents-search')),
      'Family',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('featured-document-pass')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('documents-search')),
          )
          .controller!
          .text,
      'Family',
    );
  });

  testWidgets('Status filters use DocumentStatus.resolve', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await seedWallet(documents);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);

    Future<void> select(String key, String visible, String hidden) async {
      await tester.tap(find.byKey(ValueKey<String>(key)));
      await tester.pumpAndSettle();
      expect(find.text(visible), findsOneWidget);
      expect(find.text(hidden), findsNothing);
    }

    await select('filter-action', 'Urgent licence', 'Overdue visa');
    await select('filter-upcoming', 'Upcoming certificate', 'Urgent licence');
    await select('filter-active', 'Active warranty', 'Upcoming certificate');
    await select('filter-overdue', 'Overdue visa', 'Active warranty');
    await tester.tap(find.byKey(const ValueKey<String>('filter-all')));
    await tester.pumpAndSettle();
    expect(find.text('Overdue visa'), findsOneWidget);
    expect(find.text('Active warranty'), findsOneWidget);
    expect(find.text('Action needed'), findsWidgets);
    expect(find.text('Action'), findsNothing);
  });

  testWidgets('Action needed copy survives large text on wallet chips', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
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

    await seedWallet(documents);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);

    expect(find.text('Action needed'), findsWidgets);
    expect(find.text('Action'), findsNothing);
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('Digital pass hides missing optional fields', (tester) async {
    await documents.save(
      sampleDocument(
        ownerName: null,
        documentNumber: null,
        issuingAuthority: null,
        attachmentBytes: null,
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);
    expect(find.text('Amira'), findsNothing);
    expect(find.text('••••••5678'), findsNothing);
    await openDetail(tester);
    expect(find.text('Owner'), findsNothing);
    expect(find.text('Issued by'), findsNothing);
    expect(find.byKey(const ValueKey<String>('quick-view-scan')), findsNothing);
  });

  testWidgets('Detail sections, masked number and attachment preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(sampleDocument(attachmentBytes: kTinyPngBytes));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.text('Deadline health'), findsOneWidget);
    expect(find.text('Document information'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('••••••5678'), findsWidgets);
    expect(find.text('AB12345678'), findsNothing);
    await reveal(tester, find.byKey(const ValueKey<String>('open-attachment')));
    await tester.tap(find.byKey(const ValueKey<String>('open-attachment')));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentAttachmentPreviewPage), findsOneWidget);
  });

  testWidgets('Renewal history is newest first', (tester) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(
      sampleDocument(
        renewalHistory: [
          RenewalHistoryEntry(
            id: 'old',
            renewedOn: DateTime(2024, 1, 2),
            previousExpiryDate: DateTime(2022, 1, 1),
            newExpiryDate: DateTime(2024, 1, 1),
            note: 'Older renewal',
          ),
          RenewalHistoryEntry(
            id: 'new',
            renewedOn: DateTime(2025, 2, 2),
            previousExpiryDate: DateTime(2024, 1, 1),
            newExpiryDate: DateTime(2025, 2, 1),
            note: 'Newer renewal',
          ),
        ],
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);
    await reveal(tester, find.text('Newer renewal'));
    final newer = tester.getTopLeft(find.text('Newer renewal')).dy;
    await reveal(tester, find.text('Older renewal'));
    final older = tester.getTopLeft(find.text('Older renewal')).dy;
    expect(newer, lessThan(older));
    expect(find.text('01 Jan 2022'), findsOneWidget);
    expect(find.text('01 Feb 2025'), findsOneWidget);
  });

  testWidgets('French detail dates include four-digit years', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(sampleDocument());
    await tester.pumpWidget(app(locale: const Locale('fr')));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('Documents'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('featured-document-pass')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        RegistryDateFormatter.dayMonthYear(DateTime(2027, 10, 5), 'fr'),
      ),
      findsWidgets,
    );
    expect(find.textContaining('2027'), findsWidgets);
  });

  testWidgets('Documents list clears the navigation dock and has no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
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

    await seedWallet(documents);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDocuments(tester);

    final list = tester.widget<ListView>(find.byType(ListView).first);
    expect(
      (list.padding as EdgeInsetsDirectional).bottom,
      AppSpacing.scrollDockClearance,
    );

    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    await tester.pumpAndSettle();
    expect(
      overflows.where((details) => details.toString().contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('Detail masks sensitive dynamic fields', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await documents.save(
      sampleDocument(
        name: 'Aadhaar',
        category: DocumentCategory.idCard,
        schemaId: DocumentSchemaIds.indiaAadhaar,
        countryCode: DocumentCountryCodes.india,
        dynamicFields: const [
          DocumentFieldValue(
            id: DocumentFieldKeys.aadhaarNumber,
            fieldKey: DocumentFieldKeys.aadhaarNumber,
            value: '1234 5678 9012',
            sensitive: true,
          ),
          DocumentFieldValue(
            id: DocumentFieldKeys.gender,
            fieldKey: DocumentFieldKeys.gender,
            value: 'F',
          ),
        ],
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openDetail(tester);

    expect(find.text('••••••••••9012'), findsOneWidget);
    expect(find.text('1234 5678 9012'), findsNothing);
    expect(find.text('F'), findsOneWidget);
    expect(find.text('Document type'), findsWidgets);
    expect(find.text('Category'), findsWidgets);
    expect(find.text('Aadhaar'), findsWidgets);
    expect(find.text('ID card'), findsWidgets);
  });

  testWidgets('Edit prefills saved dynamic fields', (tester) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openEdit(tester);
    await continueWizard(tester);

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('dynamic-nationality')),
          )
          .controller!
          .text,
      'Sampleland',
    );
  });
}
