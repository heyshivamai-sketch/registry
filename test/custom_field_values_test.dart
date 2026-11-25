import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/presentation/add_document_controller.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_document_ocr_service.dart';
import 'support/fake_image_picker_service.dart';
import 'support/fake_onboarding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddDocumentController custom fields and values', () {
    test('only allows 1 field name with max 5 values', () {
      final controller = AddDocumentController();
      expect(controller.hasCustomField, isFalse);

      // Add initial custom field
      controller.addCustomField(label: 'Special ID', value: 'Val 1');
      expect(controller.hasCustomField, isTrue);
      expect(controller.customFields.length, 1);
      expect(controller.customFields.first.customLabel, 'Special ID');
      expect(controller.customFields.first.value, 'Val 1');

      // Attempting to add another custom field does nothing (only 1 field name allowed)
      controller.addCustomField(label: 'Another Name', value: 'Val X');
      expect(controller.customFields.length, 1);
      expect(controller.customFields.first.customLabel, 'Special ID');

      // Add values up to 5
      controller.addCustomValue(value: 'Val 2');
      controller.addCustomValue(value: 'Val 3');
      controller.addCustomValue(value: 'Val 4');
      controller.addCustomValue(value: 'Val 5');
      expect(controller.customFields.length, 5);

      // Attempting to add a 6th value does nothing (max 5 values)
      controller.addCustomValue(value: 'Val 6');
      expect(controller.customFields.length, 5);

      // Updating field name updates all values' customLabel
      controller.setCustomFieldLabel('Updated Label');
      for (final f in controller.customFields) {
        expect(f.customLabel, 'Updated Label');
      }

      // Removing individual value at index 1
      controller.removeCustomValue(1);
      expect(controller.customFields.length, 4);

      // Removing custom field removes all custom fields
      controller.removeCustomField();
      expect(controller.hasCustomField, isFalse);
      expect(controller.customFields, isEmpty);
    });
  });

  group('UI: Custom field block, eye icon, values, and removal', () {
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

    testWidgets('UI: no eye icon, add value up to 5, and remove field', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Open Add Document -> Manual entry
      await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('add-document')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('entry-manual')));
      await tester.pumpAndSettle();

      // Open Identity extras section
      await tester.tap(find.byKey(const ValueKey<String>('section-identity-extras')));
      await tester.pumpAndSettle();

      // Add custom field button is visible initially
      final addCustomFieldBtn = find.byKey(const ValueKey<String>('add-custom-field'));
      expect(addCustomFieldBtn, findsOneWidget);

      await tester.tap(addCustomFieldBtn);
      await tester.pumpAndSettle();

      // "Add custom field" button should now be hidden because only 1 field name is allowed
      expect(find.byKey(const ValueKey<String>('add-custom-field')), findsNothing);

      // "Field name" input and "Value" input are present
      expect(find.text('Field name'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);

      // 1. Verify NO eye icon in custom value field
      final valueField = find.ancestor(
        of: find.text('Value'),
        matching: find.byType(TextField),
      );
      expect(
        find.descendant(of: valueField, matching: find.byIcon(Icons.visibility_outlined)),
        findsNothing,
      );
      expect(
        find.descendant(of: valueField, matching: find.byIcon(Icons.visibility_off_outlined)),
        findsNothing,
      );

      // 2. Add value button should be present
      final addValueBtn = find.byKey(const ValueKey<String>('add-custom-value'));
      expect(addValueBtn, findsOneWidget);
      expect(find.text('Add value'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      // Tap "Add value" to create Value 2
      await tester.tap(addValueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Value 2'), findsOneWidget);

      // Tap "Add value" again for Value 3
      await tester.tap(addValueBtn);
      await tester.pumpAndSettle();
      expect(find.text('Value 3'), findsOneWidget);

      // Tap "Add value" again for Value 4
      await tester.tap(addValueBtn);
      await tester.pumpAndSettle();
      expect(find.text('Value 4'), findsOneWidget);

      // Tap "Add value" again for Value 5
      await tester.tap(addValueBtn);
      await tester.pumpAndSettle();
      expect(find.text('Value 5'), findsOneWidget);

      // At 5 values, "Add value" should be hidden (max 5 values)
      expect(find.byKey(const ValueKey<String>('add-custom-value')), findsNothing);

      // Remove an individual value (e.g. Value 5)
      final removeValue4Btn = find.byKey(const ValueKey<String>('remove-value-4'));
      expect(removeValue4Btn, findsOneWidget);
      await tester.tap(removeValue4Btn);
      await tester.pumpAndSettle();

      expect(find.text('Value 5'), findsNothing);
      // Now at 4 values (Value, Value 2, Value 3, Value 4), "Add value" reappears
      expect(find.byKey(const ValueKey<String>('add-custom-value')), findsOneWidget);

      // Tap "Remove" button at the bottom: it deletes the value field separately (Value 4), NOT the entire field
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Field name'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Value 2'), findsOneWidget);
      expect(find.text('Value 3'), findsOneWidget);
      expect(find.text('Value 4'), findsNothing);

      // Tap "Remove" again: deletes Value 3
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Field name'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Value 2'), findsOneWidget);
      expect(find.text('Value 3'), findsNothing);

      // Tap "Remove" again: deletes Value 2
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Field name'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Value 2'), findsNothing);

      // Tap "Remove" on the last remaining value: deletes the custom field block
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Field name'), findsNothing);
      expect(find.text('Value'), findsNothing);

      // "Add custom field" button reappears
      expect(find.byKey(const ValueKey<String>('add-custom-field')), findsOneWidget);
    });
  });
}
