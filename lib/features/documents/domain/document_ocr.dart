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
    this.categoryLabel,
    this.documentTypeLabel,
  });

  const DocumentOcrResult.failed()
    : categoryLabel = null,
      documentTypeLabel = null,
      status = OcrRecognitionStatus.failed,
      classification = const DocumentClassification(
        schemaId: DocumentSchemaIds.genericOther,
        countryCode: DocumentCountryCodes.other,
        category: DocumentCategory.other,
        confidence: OcrConfidence.notDetected,
      ),
      fields = const [],
      overallConfidence = OcrConfidence.notDetected;

  const DocumentOcrResult.cancelled()
    : categoryLabel = null,
      documentTypeLabel = null,
      status = OcrRecognitionStatus.cancelled,
      classification = const DocumentClassification(
        schemaId: DocumentSchemaIds.genericOther,
        countryCode: DocumentCountryCodes.other,
        category: DocumentCategory.other,
        confidence: OcrConfidence.notDetected,
      ),
      fields = const [],
      overallConfidence = OcrConfidence.notDetected;

  final OcrRecognitionStatus status;
  final String? categoryLabel;
  final String? documentTypeLabel;
  final DocumentClassification classification;
  final List<ExtractedDocumentField> fields;
  final OcrConfidence overallConfidence;

  int get detectedFieldCount =>
      fields.where((field) => field.value.trim().isNotEmpty).length;

  DocumentOcrResult copyWith({
    OcrRecognitionStatus? status,
    String? categoryLabel,
    String? documentTypeLabel,
    bool clearDocumentTypeLabel = false,
    DocumentClassification? classification,
    List<ExtractedDocumentField>? fields,
    OcrConfidence? overallConfidence,
  }) {
    return DocumentOcrResult(
      status: status ?? this.status,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      documentTypeLabel: clearDocumentTypeLabel
          ? null
          : documentTypeLabel ?? this.documentTypeLabel,
      classification: classification ?? this.classification,
      fields: fields ?? this.fields,
      overallConfidence: overallConfidence ?? this.overallConfidence,
    );
  }
}

abstract class DocumentOcrService {
  bool get isAvailable => true;

  Future<DocumentOcrResult> recognize(Uint8List imageBytes);
}

class DisabledDocumentOcrService implements DocumentOcrService {
  const DisabledDocumentOcrService();

  @override
  bool get isAvailable => false;

  @override
  Future<DocumentOcrResult> recognize(Uint8List imageBytes) async =>
      const DocumentOcrResult.failed();
}

abstract interface class MultiImageDocumentOcrService {
  Future<DocumentOcrResult> recognizeImages(List<Uint8List> images);
}

Future<DocumentOcrResult> recognizeDocumentImages(
  DocumentOcrService service,
  List<Uint8List> images,
) async {
  if (!service.isAvailable) {
    return const DocumentOcrResult.failed();
  }
  if (service is MultiImageDocumentOcrService) {
    return (service as MultiImageDocumentOcrService).recognizeImages(images);
  }
  final results = <DocumentOcrResult>[];
  for (final image in images) {
    final result = await service.recognize(image);
    if (result.status == OcrRecognitionStatus.cancelled) return result;
    if (result.status == OcrRecognitionStatus.success) results.add(result);
  }
  if (results.isEmpty) return const DocumentOcrResult.failed();
  final fields = <String, ExtractedDocumentField>{};
  for (final result in results) {
    for (final field in result.fields) {
      if (field.value.trim().isNotEmpty ||
          !fields.containsKey(field.fieldKey)) {
        fields[field.fieldKey] = field;
      }
    }
  }
  return results.first.copyWith(fields: fields.values.toList());
}
