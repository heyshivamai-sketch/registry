import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/document_renewal.dart';

import 'support/sample_document.dart';

void main() {
  const registry = DocumentSchemaRegistry();

  test('schema registry lookup and generic fallback', () {
    expect(
      registry.byId(DocumentSchemaIds.genericPassport).id,
      DocumentSchemaIds.genericPassport,
    );
    expect(registry.byId('missing').id, DocumentSchemaIds.genericOther);
    expect(registry.fallback().id, DocumentSchemaIds.genericOther);
  });

  test('passport schema contains required identity and date fields', () {
    final schema = registry.byId(DocumentSchemaIds.genericPassport);
    expect(schema.countryCode, DocumentCountryCodes.generic);
    expect(schema.category, DocumentCategory.passport);
    expect(
      schema.fieldIds,
      containsAll([
        DocumentFieldKeys.passportNumber,
        DocumentFieldKeys.fullName,
        DocumentFieldKeys.nationality,
        DocumentFieldKeys.dateOfBirth,
        DocumentFieldKeys.issueDate,
        DocumentFieldKeys.expiryDate,
        DocumentFieldKeys.issuingAuthority,
      ]),
    );
    expect(
      schema.fieldById(DocumentFieldKeys.passportNumber)?.sensitive,
      isTrue,
    );
  });

  test('aadhaar schema', () {
    final schema = registry.byId(DocumentSchemaIds.indiaAadhaar);
    expect(schema.countryCode, DocumentCountryCodes.india);
    expect(
      schema.fieldIds,
      containsAll([
        DocumentFieldKeys.aadhaarNumber,
        DocumentFieldKeys.fullName,
        DocumentFieldKeys.dateOfBirth,
        DocumentFieldKeys.gender,
        DocumentFieldKeys.address,
      ]),
    );
  });

  test('france national id schema', () {
    final schema = registry.byId(DocumentSchemaIds.franceNationalId);
    expect(schema.countryCode, DocumentCountryCodes.france);
    expect(
      schema.fieldIds,
      containsAll([
        DocumentFieldKeys.documentNumber,
        DocumentFieldKeys.surname,
        DocumentFieldKeys.givenNames,
        DocumentFieldKeys.nationality,
        DocumentFieldKeys.dateOfBirth,
      ]),
    );
  });

  test('emirates id schema', () {
    final schema = registry.byId(DocumentSchemaIds.uaeEmiratesId);
    expect(schema.countryCode, DocumentCountryCodes.uae);
    expect(
      schema.fieldIds,
      containsAll([
        DocumentFieldKeys.idNumber,
        DocumentFieldKeys.name,
        DocumentFieldKeys.nationality,
        DocumentFieldKeys.dateOfBirth,
      ]),
    );
  });

  test('generic fallback has no hard-coded extra fields', () {
    expect(registry.byId(DocumentSchemaIds.genericOther).fields, isEmpty);
  });

  test('sensitive field masking', () {
    const field = DocumentFieldValue(
      id: 'n',
      fieldKey: DocumentFieldKeys.aadhaarNumber,
      value: '1234 5678 9012',
      sensitive: true,
    );
    expect(field.maskedValue, '••••••••••9012');
    expect(
      const DocumentFieldValue(
        id: 's',
        fieldKey: 'x',
        value: 'AB12',
        sensitive: true,
      ).maskedValue,
      '••••',
    );
  });

  test('dynamic field immutability and copyWith', () {
    final original = sampleDocument(
      dynamicFields: const [
        DocumentFieldValue(
          id: 'nationality',
          fieldKey: DocumentFieldKeys.nationality,
          value: 'Sample',
        ),
      ],
    );
    final updated = original.copyWith(name: 'Renamed');
    expect(updated.dynamicFields, original.dynamicFields);
    expect(updated.schemaId, original.schemaId);
    expect(
      () => original.dynamicFields.add(
        const DocumentFieldValue(id: 'x', fieldKey: 'x', value: 'y'),
      ),
      throwsUnsupportedError,
    );
  });

  test('edit copyWith preserves dynamic fields', () {
    final original = sampleDocument(
      schemaId: DocumentSchemaIds.indiaAadhaar,
      countryCode: DocumentCountryCodes.india,
      dynamicFields: const [
        DocumentFieldValue(
          id: 'gender',
          fieldKey: DocumentFieldKeys.gender,
          value: 'F',
        ),
      ],
    );
    final edited = original.copyWith(
      name: 'Updated aadhaar',
      updatedAt: DateTime(2026, 4, 1),
    );
    expect(edited.id, original.id);
    expect(edited.dynamicFields.single.value, 'F');
    expect(edited.countryCode, DocumentCountryCodes.india);
  });

  test('renewal preserves dynamic fields', () {
    final original = sampleDocument(
      dynamicFields: const [
        DocumentFieldValue(
          id: 'nationality',
          fieldKey: DocumentFieldKeys.nationality,
          value: 'Sample',
        ),
      ],
    );
    final renewed = DocumentRenewal.record(
      document: original,
      renewedOn: DateTime(2026, 10, 1),
      newExpiryDate: DateTime(2032, 10, 5),
    );
    expect(renewed.dynamicFields, original.dynamicFields);
    expect(renewed.schemaId, original.schemaId);
  });
}
