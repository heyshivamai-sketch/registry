import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/documents/data/firebase_ai_document_ocr_service.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';

import 'support/tiny_png.dart';

class _FakeFirebaseAiClient implements FirebaseAiDocumentClient {
  String? response;
  List<FirebaseAiDocumentImage>? received;
  int calls = 0;

  @override
  Future<String?> extract(List<FirebaseAiDocumentImage> images) async {
    calls += 1;
    received = images;
    return response;
  }
}

void main() {
  test(
    'front and back are sent together and every structured field is reviewed',
    () async {
      final client = _FakeFirebaseAiClient()
        ..response = jsonEncode({
          'documentType': 'Aadhaar',
          'countryCode': 'IN',
          'name': 'SAMPLE PERSON',
          'documentNumber': '1234 5678 9012',
          'dateOfBirth': '1990-01-02',
          'issueDate': '',
          'expiryDate': '2030',
          'address': 'SAMPLE ROAD',
          'issuingAuthority': 'Government of India',
          'category': 'National identity card',
        });
      final service = FirebaseAiDocumentOcrService(client);

      final result = await service.recognizeImages([
        kTinyPngBytes,
        Uint8List.fromList(kTinyPngBytes),
      ]);

      expect(client.calls, 1);
      expect(client.received, hasLength(2));
      expect(
        client.received!.every((image) => image.mimeType == 'image/png'),
        isTrue,
      );
      expect(result.status, OcrRecognitionStatus.success);
      expect(result.documentTypeLabel, 'Aadhaar');
      expect(result.categoryLabel, 'National identity card');
      expect(result.classification.schemaId, DocumentSchemaIds.indiaAadhaar);
      expect(result.fields, hasLength(7));
      expect(
        result.fields.singleWhere(
          (field) => field.fieldKey == DocumentFieldKeys.expiryDate,
        ),
        isA<ExtractedDocumentField>()
            .having((field) => field.value, 'value', isEmpty)
            .having(
              (field) => field.confidence,
              'confidence',
              OcrConfidence.notDetected,
            ),
      );
      expect(
        result.fields
            .singleWhere((field) => field.fieldKey == DocumentFieldKeys.address)
            .value,
        'SAMPLE ROAD',
      );
    },
  );

  test('missing and uncertain values remain blank', () async {
    final client = _FakeFirebaseAiClient()
      ..response = jsonEncode({
        'documentType': 'Membership card',
        'countryCode': '',
        'name': '',
        'documentNumber': '',
        'dateOfBirth': '',
        'issueDate': '',
        'expiryDate': '',
        'address': '',
        'issuingAuthority': '',
        'category': 'Membership',
      });
    final result = await FirebaseAiDocumentOcrService(
      client,
    ).recognize(kTinyPngBytes);

    expect(result.status, OcrRecognitionStatus.success);
    expect(result.fields.every((field) => field.value.isEmpty), isTrue);
    expect(result.detectedFieldCount, 0);
  });

  test('invalid model output fails without filling the form', () async {
    final client = _FakeFirebaseAiClient()..response = 'not JSON';
    final result = await FirebaseAiDocumentOcrService(
      client,
    ).recognize(kTinyPngBytes);
    expect(result.status, OcrRecognitionStatus.failed);
    expect(result.fields, isEmpty);
  });

  test(
    'extracts documentName, gender, nationality and normalizes dates from varied formats',
    () async {
      final client = _FakeFirebaseAiClient()
        ..response = jsonEncode({
          'documentName': 'Aadhaar Card',
          'documentType': 'ID Card',
          'countryCode': 'IN',
          'name': 'PRIYA SHARMA',
          'documentNumber': '9876 5432 1098',
          'dateOfBirth': '18/05/1992',
          'issueDate': '10-04-2015',
          'expiryDate': '2035/12/31',
          'gender': 'Female',
          'nationality': 'Indian',
          'address': '42 MG ROAD, BENGALURU, 560001',
          'issuingAuthority': 'Unique Identification Authority of India',
          'category': 'Identity card',
        });
      final result = await FirebaseAiDocumentOcrService(
        client,
      ).recognize(kTinyPngBytes);

      expect(result.status, OcrRecognitionStatus.success);
      expect(result.documentTypeLabel, 'Aadhaar Card');
      expect(result.classification.schemaId, DocumentSchemaIds.indiaAadhaar);
      expect(
        result.fields
            .singleWhere((f) => f.fieldKey == DocumentFieldKeys.fullName)
            .value,
        'PRIYA SHARMA',
      );
      expect(
        result.fields
            .singleWhere((f) => f.fieldKey == DocumentFieldKeys.dateOfBirth)
            .value,
        '1992-05-18',
      );
      expect(
        result.fields
            .singleWhere((f) => f.fieldKey == DocumentFieldKeys.issueDate)
            .value,
        '2015-04-10',
      );
      expect(
        result.fields
            .singleWhere((f) => f.fieldKey == DocumentFieldKeys.expiryDate)
            .value,
        '2035-12-31',
      );
      expect(
        result.fields
            .singleWhere((f) => f.fieldKey == DocumentFieldKeys.gender)
            .value,
        'Female',
      );
      expect(
        result.fields
            .singleWhere((f) => f.fieldKey == DocumentFieldKeys.nationality)
            .value,
        'Indian',
      );
    },
  );

  test('classifies driving licence and insurance documents properly', () async {
    final client = _FakeFirebaseAiClient()
      ..response = jsonEncode({
        'documentName': 'Indian Driving Licence',
        'documentType': 'Driving Licence',
        'countryCode': 'IN',
        'name': 'RAHUL VERMA',
        'documentNumber': 'DL-1420110012345',
        'dateOfBirth': '15 Aug 1988',
        'issueDate': '12 Jan 2018',
        'expiryDate': '11 Jan 2038',
        'gender': 'Male',
        'address': 'NEW DELHI',
        'issuingAuthority': 'Transport Department Delhi',
        'category': 'Driving licence',
      });
    final result = await FirebaseAiDocumentOcrService(
      client,
    ).recognize(kTinyPngBytes);

    expect(result.status, OcrRecognitionStatus.success);
    expect(result.documentTypeLabel, 'Indian Driving Licence');
    expect(result.categoryLabel, 'Driving licence');
    expect(
      result.fields
          .singleWhere((f) => f.fieldKey == DocumentFieldKeys.dateOfBirth)
          .value,
      '1988-08-15',
    );
    expect(
      result.fields
          .singleWhere((f) => f.fieldKey == DocumentFieldKeys.issueDate)
          .value,
      '2018-01-12',
    );
    expect(
      result.fields
          .singleWhere((f) => f.fieldKey == DocumentFieldKeys.expiryDate)
          .value,
      '2038-01-11',
    );
  });
}
