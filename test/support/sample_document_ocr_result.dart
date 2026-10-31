import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';

DocumentOcrResult sampleAadhaarOcrResult({
  String name = 'SAMPLE NAME',
  String number = '1234 5678 9012',
  String dateOfBirth = '',
  String address = '',
  String category = 'ID card',
}) {
  return DocumentOcrResult(
    status: OcrRecognitionStatus.success,
    classification: const DocumentClassification(
      schemaId: DocumentSchemaIds.indiaAadhaar,
      countryCode: DocumentCountryCodes.india,
      category: DocumentCategory.idCard,
      confidence: OcrConfidence.review,
    ),
    documentTypeLabel: 'Aadhaar',
    categoryLabel: category,
    overallConfidence: OcrConfidence.review,
    fields: [
      _field(DocumentFieldKeys.fullName, name),
      _field(DocumentFieldKeys.aadhaarNumber, number, sensitive: true),
      _field(DocumentFieldKeys.dateOfBirth, dateOfBirth, isDate: true),
      _field(DocumentFieldKeys.issueDate, '', isDate: true),
      _field(DocumentFieldKeys.expiryDate, '', isDate: true),
      _field(DocumentFieldKeys.address, address),
      _field(DocumentFieldKeys.issuingAuthority, ''),
    ],
  );
}

DocumentOcrResult sampleGenericOcrResult() {
  return DocumentOcrResult(
    status: OcrRecognitionStatus.success,
    classification: const DocumentClassification(
      schemaId: DocumentSchemaIds.genericOther,
      countryCode: DocumentCountryCodes.other,
      category: DocumentCategory.other,
      confidence: OcrConfidence.review,
    ),
    documentTypeLabel: 'Membership card',
    categoryLabel: 'Membership',
    overallConfidence: OcrConfidence.review,
    fields: [
      _field(DocumentFieldKeys.fullName, ''),
      _field(DocumentFieldKeys.documentNumber, 'ZX-99', sensitive: true),
      _field(DocumentFieldKeys.dateOfBirth, '', isDate: true),
      _field(DocumentFieldKeys.issueDate, '', isDate: true),
      _field(DocumentFieldKeys.expiryDate, '', isDate: true),
      _field(DocumentFieldKeys.address, ''),
      _field(DocumentFieldKeys.issuingAuthority, 'SAMPLE CLUB'),
    ],
  );
}

DocumentOcrResult samplePassportOcrResult() {
  return DocumentOcrResult(
    status: OcrRecognitionStatus.success,
    classification: const DocumentClassification(
      schemaId: DocumentSchemaIds.genericPassport,
      countryCode: DocumentCountryCodes.generic,
      category: DocumentCategory.passport,
      confidence: OcrConfidence.review,
    ),
    documentTypeLabel: 'Passport',
    categoryLabel: 'Passport',
    overallConfidence: OcrConfidence.review,
    fields: [
      _field(DocumentFieldKeys.fullName, 'SAMPLE JANE MARIE'),
      _field(DocumentFieldKeys.passportNumber, 'P1234567', sensitive: true),
      _field(DocumentFieldKeys.dateOfBirth, '1990-01-12', isDate: true),
      _field(DocumentFieldKeys.issueDate, '2020-03-01', isDate: true),
      _field(DocumentFieldKeys.expiryDate, '2030-03-01', isDate: true),
      _field(DocumentFieldKeys.address, ''),
      _field(DocumentFieldKeys.issuingAuthority, 'SAMPLE OFFICE'),
    ],
  );
}

ExtractedDocumentField _field(
  String key,
  String value, {
  bool sensitive = false,
  bool isDate = false,
}) {
  return ExtractedDocumentField(
    id: key,
    fieldKey: key,
    value: value,
    confidence: value.isEmpty
        ? OcrConfidence.notDetected
        : OcrConfidence.review,
    sensitive: sensitive,
    isDate: isDate,
  );
}
