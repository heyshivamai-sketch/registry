import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_ocr_parser.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';

void main() {
  test('classifies synthetic passport text', () {
    const text = '''
PASSPORT
Passport No. P1234567
Surname SAMPLE
Given names JANE MARIE
Nationality SAMPLELAND
Date of birth 12 JAN 1990
Date of issue 01 MAR 2020
Date of expiry 01 MAR 2030
Authority SAMPLE OFFICE
''';
    final result = DocumentOcrParser.parse(text);
    expect(result.classification.schemaId, DocumentSchemaIds.genericPassport);
    expect(result.fields.where((field) => field.value.isNotEmpty), isNotEmpty);
    expect(
      result.fields
          .firstWhere((field) => field.fieldKey == DocumentFieldKeys.expiryDate)
          .value,
      contains('2030'),
    );
  });

  test('classifies synthetic aadhaar text', () {
    const text = '''
Government of India
Aadhaar
Name: SAMPLE NAME
DOB: 1990
Gender: Female
1234 5678 9012
Address: SAMPLE STREET, CITY
''';
    final result = DocumentOcrParser.parse(text);
    expect(result.classification.schemaId, DocumentSchemaIds.indiaAadhaar);
    expect(
      result.fields
          .firstWhere(
            (field) => field.fieldKey == DocumentFieldKeys.aadhaarNumber,
          )
          .value,
      '1234 5678 9012',
    );
    expect(
      result.fields
          .firstWhere((field) => field.fieldKey == DocumentFieldKeys.gender)
          .value,
      'F',
    );
  });

  test('extracts unlabeled aadhaar name, dob and gender', () {
    const text = '''
GOVERNMENT OF INDIA
AADHAAR
SHIVAM TEST
DOB: 14/02/1992
MALE
1234 5678 9012
FOR TESTING ONLY
''';
    final result = DocumentOcrParser.parse(text);
    expect(result.classification.schemaId, DocumentSchemaIds.indiaAadhaar);
    expect(
      result.fields
          .firstWhere(
            (field) => field.fieldKey == DocumentFieldKeys.aadhaarNumber,
          )
          .value,
      '1234 5678 9012',
    );
    expect(
      result.fields
          .firstWhere((field) => field.fieldKey == DocumentFieldKeys.fullName)
          .value,
      'SHIVAM TEST',
    );
    expect(
      result.fields
          .firstWhere(
            (field) => field.fieldKey == DocumentFieldKeys.dateOfBirth,
          )
          .value,
      '14/02/1992',
    );
    expect(
      result.fields
          .firstWhere((field) => field.fieldKey == DocumentFieldKeys.gender)
          .value,
      'M',
    );
  });

  test('classifies synthetic french id text', () {
    const text = '''
République Française
Carte Nationale d'Identité
Nom: EXEMPLE
Prénoms: MARIE
Nationalité: FRANÇAISE
Date de naissance: 01.01.1990
Date d'expiration: 01.01.2030
Document No: X123456
''';
    final result = DocumentOcrParser.parse(text);
    expect(result.classification.schemaId, DocumentSchemaIds.franceNationalId);
    expect(
      result.fields
          .firstWhere((field) => field.fieldKey == DocumentFieldKeys.surname)
          .value,
      'EXEMPLE',
    );
  });

  test('classifies synthetic emirates id text', () {
    const text = '''
UNITED ARAB EMIRATES
Emirates ID
Federal Authority
ID Number 784-1990-1234567-1
Name: SAMPLE PERSON
Nationality: ARE
Date of Birth: 01/01/1990
Expiry: 01/01/2032
''';
    final result = DocumentOcrParser.parse(text);
    expect(result.classification.schemaId, DocumentSchemaIds.uaeEmiratesId);
    expect(
      result.fields
          .firstWhere((field) => field.fieldKey == DocumentFieldKeys.idNumber)
          .value,
      contains('784'),
    );
  });

  test('unknown labels become custom fields and generic fallback', () {
    const text = '''
Membership Card
Club: SAMPLE CLUB
Member code: ZX-99
''';
    final result = DocumentOcrParser.parse(text);
    expect(result.classification.schemaId, DocumentSchemaIds.genericOther);
    expect(result.fields.where((field) => field.isCustom), isNotEmpty);
  });

  test('remap preserves compatible confirmed values', () {
    final parsed = DocumentOcrParser.parse('''
PASSPORT
Passport No. P1234567
Nationality SAMPLELAND
''');
    final remapped = DocumentOcrParser.remap(
      current: parsed,
      schema: const DocumentSchemaRegistry().byId(
        DocumentSchemaIds.genericOther,
      ),
      confirmedFields: [
        parsed.fields
            .firstWhere(
              (field) => field.fieldKey == DocumentFieldKeys.nationality,
            )
            .copyWith(),
        const ExtractedDocumentField(
          id: 'custom_1',
          fieldKey: 'custom',
          customLabel: 'Club',
          value: 'SAMPLE CLUB',
          confidence: OcrConfidence.review,
          isCustom: true,
          removable: true,
        ),
      ],
    );
    expect(remapped.classification.schemaId, DocumentSchemaIds.genericOther);
    expect(
      remapped.fields.where((field) => field.isCustom).single.value,
      'SAMPLE CLUB',
    );
  });
}
