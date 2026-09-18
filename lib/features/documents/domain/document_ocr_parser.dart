import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';

abstract final class DocumentOcrParser {
  static const _registry = DocumentSchemaRegistry();

  static DocumentOcrResult parse(String text) {
    final normalized = text.replaceAll('\r\n', '\n');
    final lower = normalized.toLowerCase();
    final classification = classify(lower);
    final schema = _registry.byId(classification.schemaId);
    final extracted = <ExtractedDocumentField>[
      for (final field in schema.orderedFields)
        _extractSchemaField(field, normalized, lower),
    ];
    for (final custom in _unknownFields(normalized, lower, extracted)) {
      extracted.add(custom);
    }
    return DocumentOcrResult(
      status: OcrRecognitionStatus.success,
      classification: classification,
      fields: extracted,
      overallConfidence: _overall(classification.confidence, extracted),
    );
  }

  static DocumentClassification classify(String lowerText) {
    if (_isAadhaar(lowerText)) {
      return const DocumentClassification(
        schemaId: DocumentSchemaIds.indiaAadhaar,
        countryCode: DocumentCountryCodes.india,
        category: DocumentCategory.idCard,
        confidence: OcrConfidence.high,
      );
    }
    if (_isEmiratesId(lowerText)) {
      return const DocumentClassification(
        schemaId: DocumentSchemaIds.uaeEmiratesId,
        countryCode: DocumentCountryCodes.uae,
        category: DocumentCategory.idCard,
        confidence: OcrConfidence.high,
      );
    }
    if (_isFrenchId(lowerText)) {
      return const DocumentClassification(
        schemaId: DocumentSchemaIds.franceNationalId,
        countryCode: DocumentCountryCodes.france,
        category: DocumentCategory.idCard,
        confidence: OcrConfidence.high,
      );
    }
    if (_isPassport(lowerText)) {
      return const DocumentClassification(
        schemaId: DocumentSchemaIds.genericPassport,
        countryCode: DocumentCountryCodes.generic,
        category: DocumentCategory.passport,
        confidence: OcrConfidence.high,
      );
    }
    return const DocumentClassification(
      schemaId: DocumentSchemaIds.genericOther,
      countryCode: DocumentCountryCodes.other,
      category: DocumentCategory.other,
      confidence: OcrConfidence.review,
    );
  }

  static DocumentOcrResult remap({
    required DocumentOcrResult current,
    required DocumentSchema schema,
    required List<ExtractedDocumentField> confirmedFields,
  }) {
    final byKey = <String, ExtractedDocumentField>{
      for (final field in confirmedFields)
        if (!field.isCustom) field.fieldKey: field,
    };
    final remapped = <ExtractedDocumentField>[
      for (final definition in schema.orderedFields)
        byKey[definition.id]?.copyWith(
              sensitive: definition.sensitive,
              isDate: definition.isDate,
              removable: false,
              isCustom: false,
            ) ??
            ExtractedDocumentField(
              id: definition.id,
              fieldKey: definition.id,
              confidence: OcrConfidence.notDetected,
              sensitive: definition.sensitive,
              isDate: definition.isDate,
            ),
    ];
    for (final field in confirmedFields) {
      if (field.isCustom) {
        remapped.add(field);
      }
    }
    final classification = DocumentClassification(
      schemaId: schema.id,
      countryCode: schema.countryCode,
      category: schema.category,
      confidence: OcrConfidence.review,
    );
    return current.copyWith(
      classification: classification,
      fields: remapped,
      overallConfidence: _overall(classification.confidence, remapped),
    );
  }

  static bool _isAadhaar(String text) {
    return text.contains('aadhaar') ||
        text.contains('government of india') ||
        _aadhaarPattern.hasMatch(text);
  }

  static bool _isEmiratesId(String text) {
    return text.contains('emirates id') ||
        text.contains('federal authority') ||
        text.contains('united arab emirates') ||
        _emiratesPattern.hasMatch(text);
  }

  static bool _isFrenchId(String text) {
    return text.contains('carte nationale') ||
        text.contains('identité') ||
        text.contains('identite') ||
        text.contains('république française') ||
        text.contains('republique francaise');
  }

  static bool _isPassport(String text) {
    return text.contains('passport') ||
        text.contains('passeport') ||
        text.contains('p<') ||
        text.contains('date of expiry');
  }

  static ExtractedDocumentField _extractSchemaField(
    DynamicDocumentField field,
    String original,
    String lower,
  ) {
    final value = _valueFor(field, original, lower);
    final confidence = value == null
        ? OcrConfidence.notDetected
        : (field.ocrAliases.any(lower.contains)
              ? OcrConfidence.high
              : OcrConfidence.review);
    return ExtractedDocumentField(
      id: field.id,
      fieldKey: field.id,
      value: value ?? '',
      confidence: confidence,
      sensitive: field.sensitive,
      isDate: field.isDate,
    );
  }

  static String? _valueFor(
    DynamicDocumentField field,
    String original,
    String lower,
  ) {
    switch (field.id) {
      case DocumentFieldKeys.aadhaarNumber:
        return _firstMatch(_aadhaarPattern, original);
      case DocumentFieldKeys.idNumber:
        return _firstMatch(_emiratesPattern, original);
      case DocumentFieldKeys.passportNumber:
        return _labeled(original, [
              'passport no',
              'passport number',
              'passeport',
            ]) ??
            _firstMatch(_passportNumberPattern, original);
      case DocumentFieldKeys.documentNumber:
        return _labeled(original, [
          'document no',
          'document number',
          'n°',
          'numero',
        ]);
      case DocumentFieldKeys.gender:
        return _gender(lower);
      case DocumentFieldKeys.address:
        return _labeled(original, ['address']);
      case DocumentFieldKeys.fullName:
      case DocumentFieldKeys.name:
        return _fullName(original, lower);
      case DocumentFieldKeys.surname:
        return _labeled(original, ['nom', 'surname']);
      case DocumentFieldKeys.givenNames:
        return _labeled(original, ['prénoms', 'prenoms', 'given names']);
      case DocumentFieldKeys.nationality:
        return _labeled(original, [
          'nationality',
          'nationalité',
          'nationalite',
        ]);
      case DocumentFieldKeys.dateOfBirth:
        return _labeled(original, [
              'date of birth',
              'dob',
              'yob',
              'year of birth',
              'date de naissance',
            ]) ??
            _nearbyDate(original, [
              'date of birth',
              'dob',
              'naissance',
              'year of birth',
            ]);
      case DocumentFieldKeys.issueDate:
        return _labeled(original, [
              'date of issue',
              'issue date',
              'date de délivrance',
              'delivrance',
            ]) ??
            _nearbyDate(original, ['issue', 'délivrance', 'delivrance']);
      case DocumentFieldKeys.expiryDate:
        return _labeled(original, [
              'date of expiry',
              'date d\'expiration',
              'expiry',
              'expiration',
            ]) ??
            _nearbyDate(original, ['expiry', 'expiration']);
      case DocumentFieldKeys.issuingAuthority:
        return _labeled(original, ['authority', 'autorité', 'issuing']);
      default:
        return _labeled(original, field.ocrAliases);
    }
  }

  static String? _fullName(String original, String lower) {
    final given = _labeled(original, ['given names', 'prénoms', 'prenoms']);
    final surname = _labeled(original, ['surname', 'nom']);
    if (surname != null && given != null) {
      return '$given $surname'.trim();
    }
    return _labeled(original, ['name', 'full name']) ??
        given ??
        surname ??
        (_isAadhaar(lower) ? _unlabeledPersonName(original) : null);
  }

  static String? _unlabeledPersonName(String original) {
    for (final raw in original.split('\n')) {
      final line = _clean(raw);
      if (line.isEmpty || _aadhaarPattern.hasMatch(line)) {
        continue;
      }
      final lower = line.toLowerCase();
      if (_nameSkipLines.any((skip) => lower.contains(skip))) {
        continue;
      }
      if (RegExp(r'\d').hasMatch(line)) {
        continue;
      }
      final words = line
          .split(' ')
          .where((word) => word.isNotEmpty)
          .toList(growable: false);
      if (words.length < 2 || words.length > 4) {
        continue;
      }
      if (words.every(
        (word) => RegExp(r"^[A-Za-z][A-Za-z'.-]*$").hasMatch(word),
      )) {
        return line;
      }
    }
    return null;
  }

  static String? _gender(String lower) {
    if (RegExp(r'\bfemale\b').hasMatch(lower) ||
        RegExp(r'\bgender\s*[:\-]?\s*f\b').hasMatch(lower) ||
        RegExp(r'\bsex\s*[:\-]?\s*f\b').hasMatch(lower)) {
      return 'F';
    }
    if (RegExp(r'\bmale\b').hasMatch(lower) ||
        RegExp(r'\bgender\s*[:\-]?\s*m\b').hasMatch(lower) ||
        RegExp(r'\bsex\s*[:\-]?\s*m\b').hasMatch(lower)) {
      return 'M';
    }
    final labeled = _labeled(lower, ['gender', 'sex']);
    return labeled?.toUpperCase();
  }

  static String? _labeled(String text, List<String> labels) {
    final lines = text.split('\n');
    for (final label in labels) {
      final needle = label.toLowerCase();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final lower = line.toLowerCase();
        if (!lower.contains(needle)) {
          continue;
        }
        final separator = RegExp(
          '${RegExp.escape(label)}\\s*[:\\-#]?',
          caseSensitive: false,
        ).firstMatch(line);
        if (separator != null) {
          final rest = line.substring(separator.end).trim();
          if (rest.isNotEmpty && rest.toLowerCase() != needle) {
            return _clean(rest);
          }
        }
        if (i + 1 < lines.length) {
          final next = _clean(lines[i + 1]);
          if (next.isNotEmpty && !_looksLikeLabel(next)) {
            return next;
          }
        }
      }
    }
    return null;
  }

  static String? _nearbyDate(String text, List<String> labels) {
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (!labels.any(lower.contains)) {
        continue;
      }
      final current = _firstMatch(_datePattern, lines[i]);
      if (current != null) {
        return current;
      }
      if (i + 1 < lines.length) {
        final next = _firstMatch(_datePattern, lines[i + 1]);
        if (next != null) {
          return next;
        }
      }
    }
    return null;
  }

  static List<ExtractedDocumentField> _unknownFields(
    String original,
    String lower,
    List<ExtractedDocumentField> known,
  ) {
    if (_isAadhaar(lower) ||
        _isEmiratesId(lower) ||
        _isFrenchId(lower) ||
        _isPassport(lower)) {
      return const [];
    }
    final knownValues = {
      for (final field in known)
        if (field.value.trim().isNotEmpty) field.value.trim().toLowerCase(),
    };
    final customs = <ExtractedDocumentField>[];
    final labelPattern = RegExp(
      r"^([A-Za-z][A-Za-z '/]{2,30})\s*[:\-]\s*(.+)$",
    );
    for (final raw in original.split('\n')) {
      final match = labelPattern.firstMatch(raw.trim());
      if (match == null) {
        continue;
      }
      final label = _clean(match.group(1)!);
      final value = _clean(match.group(2)!);
      if (value.isEmpty || knownValues.contains(value.toLowerCase())) {
        continue;
      }
      if (_looksLikeLabel(value)) {
        continue;
      }
      customs.add(
        ExtractedDocumentField(
          id: 'custom_${customs.length + 1}',
          fieldKey: 'custom',
          customLabel: label,
          value: value,
          confidence: OcrConfidence.review,
          isCustom: true,
          removable: true,
        ),
      );
    }
    return customs;
  }

  static OcrConfidence _overall(
    OcrConfidence classification,
    List<ExtractedDocumentField> fields,
  ) {
    if (classification == OcrConfidence.notDetected) {
      return OcrConfidence.notDetected;
    }
    final detected = fields.where((field) => field.value.trim().isNotEmpty);
    if (detected.isEmpty) {
      return OcrConfidence.review;
    }
    if (detected.any((field) => field.confidence == OcrConfidence.review)) {
      return OcrConfidence.review;
    }
    return classification;
  }

  static String? _firstMatch(RegExp pattern, String text) {
    final match = pattern.firstMatch(text);
    return match == null ? null : _clean(match.group(0)!);
  }

  static String _clean(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _looksLikeLabel(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith(':') || lower.length < 2;
  }

  static const _nameSkipLines = [
    'government of india',
    'unique identification',
    'aadhaar',
    'male',
    'female',
    'for testing only',
    'dob',
    'date of birth',
    'address',
    'year of birth',
  ];

  static final _aadhaarPattern = RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b');
  static final _emiratesPattern = RegExp(r'\b784-?\d{4}-?\d{7}-?\d\b');
  static final _passportNumberPattern = RegExp(r'\b[A-Z]{1,2}\d{6,9}\b');
  static final _datePattern = RegExp(
    r'\b\d{1,2}[./\-\s](?:[A-Za-z]{3,}|0?\d|1[0-2])[./\-\s]\d{2,4}\b|\b(?:0?\d|1[0-2])[./-]\d{1,2}[./-]\d{2,4}\b|\b(?:19|20)\d{2}\b',
  );
}
