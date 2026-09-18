import 'dart:typed_data';

import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';

enum OcrConfidence { high, review, notDetected }

enum OcrRecognitionStatus { success, failed, cancelled }

class ExtractedDocumentField {
  const ExtractedDocumentField({
    required this.id,
    required this.fieldKey,
    required this.confidence,
    this.customLabel,
    this.value = '',
    this.sensitive = false,
    this.isDate = false,
    this.isCustom = false,
    this.removable = false,
  });

  final String id;
  final String fieldKey;
  final String? customLabel;
  final String value;
  final OcrConfidence confidence;
  final bool sensitive;
  final bool isDate;
  final bool isCustom;
  final bool removable;

  ExtractedDocumentField copyWith({
    String? id,
    String? fieldKey,
    String? customLabel,
    String? value,
    OcrConfidence? confidence,
    bool? sensitive,
    bool? isDate,
    bool? isCustom,
    bool? removable,
  }) {
    return ExtractedDocumentField(
      id: id ?? this.id,
      fieldKey: fieldKey ?? this.fieldKey,
      customLabel: customLabel ?? this.customLabel,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      sensitive: sensitive ?? this.sensitive,
      isDate: isDate ?? this.isDate,
      isCustom: isCustom ?? this.isCustom,
      removable: removable ?? this.removable,
    );
  }
}

class DocumentClassification {
  const DocumentClassification({
    required this.schemaId,
    required this.countryCode,
    required this.category,
    required this.confidence,
  });

  final String schemaId;
  final String countryCode;
  final DocumentCategory category;
  final OcrConfidence confidence;

  DocumentClassification copyWith({
    String? schemaId,
    String? countryCode,
    DocumentCategory? category,
    OcrConfidence? confidence,
  }) {
    return DocumentClassification(
      schemaId: schemaId ?? this.schemaId,
      countryCode: countryCode ?? this.countryCode,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
    );
  }
}

class DocumentOcrResult {
  const DocumentOcrResult({
    required this.status,
    required this.classification,
    required this.fields,
    required this.overallConfidence,
  });

  const DocumentOcrResult.failed()
    : status = OcrRecognitionStatus.failed,
      classification = const DocumentClassification(
        schemaId: DocumentSchemaIds.genericOther,
        countryCode: DocumentCountryCodes.other,
        category: DocumentCategory.other,
        confidence: OcrConfidence.notDetected,
      ),
      fields = const [],
      overallConfidence = OcrConfidence.notDetected;

  const DocumentOcrResult.cancelled()
    : status = OcrRecognitionStatus.cancelled,
      classification = const DocumentClassification(
        schemaId: DocumentSchemaIds.genericOther,
        countryCode: DocumentCountryCodes.other,
        category: DocumentCategory.other,
        confidence: OcrConfidence.notDetected,
      ),
      fields = const [],
      overallConfidence = OcrConfidence.notDetected;

  final OcrRecognitionStatus status;
  final DocumentClassification classification;
  final List<ExtractedDocumentField> fields;
  final OcrConfidence overallConfidence;

  int get detectedFieldCount =>
      fields.where((field) => field.value.trim().isNotEmpty).length;

  DocumentOcrResult copyWith({
    OcrRecognitionStatus? status,
    DocumentClassification? classification,
    List<ExtractedDocumentField>? fields,
    OcrConfidence? overallConfidence,
  }) {
    return DocumentOcrResult(
      status: status ?? this.status,
      classification: classification ?? this.classification,
      fields: fields ?? this.fields,
      overallConfidence: overallConfidence ?? this.overallConfidence,
    );
  }
}

abstract class DocumentOcrService {
  Future<DocumentOcrResult> recognize(Uint8List imageBytes);
}
