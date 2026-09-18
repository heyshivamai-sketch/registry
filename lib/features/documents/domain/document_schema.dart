import 'package:the_registry/features/documents/domain/registry_document.dart';

enum DocumentFieldInputType { text, number, multiline, date }

enum DocumentBaseBinding {
  none,
  title,
  owner,
  issuer,
  number,
  issueDate,
  expiryDate,
}

class DynamicDocumentField {
  const DynamicDocumentField({
    required this.id,
    required this.labelKey,
    required this.order,
    this.inputType = DocumentFieldInputType.text,
    this.required = false,
    this.optional = true,
    this.sensitive = false,
    this.isDate = false,
    this.binding = DocumentBaseBinding.none,
    this.ocrAliases = const [],
  });

  final String id;
  final String labelKey;
  final int order;
  final DocumentFieldInputType inputType;
  final bool required;
  final bool optional;
  final bool sensitive;
  final bool isDate;
  final DocumentBaseBinding binding;
  final List<String> ocrAliases;
}

class DocumentSchema {
  const DocumentSchema({
    required this.id,
    required this.countryCode,
    required this.typeKey,
    required this.category,
    required this.fields,
  });

  final String id;
  final String countryCode;
  final String typeKey;
  final DocumentCategory category;
  final List<DynamicDocumentField> fields;

  List<DynamicDocumentField> get orderedFields {
    final copy = [...fields];
    copy.sort((a, b) => a.order.compareTo(b.order));
    return copy;
  }

  DynamicDocumentField? fieldById(String id) {
    for (final field in fields) {
      if (field.id == id) {
        return field;
      }
    }
    return null;
  }

  Set<String> get fieldIds => {for (final field in fields) field.id};
}

abstract final class DocumentSchemaIds {
  static const genericPassport = 'generic_passport';
  static const indiaAadhaar = 'india_aadhaar';
  static const franceNationalId = 'france_national_id';
  static const uaeEmiratesId = 'uae_emirates_id';
  static const genericOther = 'generic_other';
}

abstract final class DocumentCountryCodes {
  static const generic = 'GEN';
  static const india = 'IN';
  static const france = 'FR';
  static const uae = 'AE';
  static const other = 'XX';

  static const all = [generic, india, france, uae, other];
}

abstract final class DocumentFieldKeys {
  static const passportNumber = 'passport_number';
  static const fullName = 'full_name';
  static const nationality = 'nationality';
  static const dateOfBirth = 'date_of_birth';
  static const issueDate = 'issue_date';
  static const expiryDate = 'expiry_date';
  static const issuingAuthority = 'issuing_authority';
  static const aadhaarNumber = 'aadhaar_number';
  static const gender = 'gender';
  static const address = 'address';
  static const documentNumber = 'document_number';
  static const surname = 'surname';
  static const givenNames = 'given_names';
  static const idNumber = 'id_number';
  static const name = 'name';
}

class DocumentSchemaRegistry {
  const DocumentSchemaRegistry();

  static final List<DocumentSchema> schemas = [
    _passport,
    _aadhaar,
    _franceId,
    _emiratesId,
    _genericOther,
  ];

  DocumentSchema byId(String? id) {
    for (final schema in schemas) {
      if (schema.id == id) {
        return schema;
      }
    }
    return _genericOther;
  }

  List<DocumentSchema> byCountry(String? countryCode) {
    if (countryCode == null || countryCode == DocumentCountryCodes.other) {
      return schemas;
    }
    final matches = [
      for (final schema in schemas)
        if (schema.countryCode == countryCode) schema,
    ];
    if (matches.isEmpty) {
      return [_genericOther];
    }
    if (!matches.any((schema) => schema.id == DocumentSchemaIds.genericOther)) {
      return [...matches, _genericOther];
    }
    return matches;
  }

  DocumentSchema fallback() => _genericOther;

  static const _passport = DocumentSchema(
    id: DocumentSchemaIds.genericPassport,
    countryCode: DocumentCountryCodes.generic,
    typeKey: DocumentSchemaIds.genericPassport,
    category: DocumentCategory.passport,
    fields: [
      DynamicDocumentField(
        id: DocumentFieldKeys.passportNumber,
        labelKey: DocumentFieldKeys.passportNumber,
        order: 10,
        sensitive: true,
        required: true,
        optional: false,
        binding: DocumentBaseBinding.number,
        ocrAliases: [
          'passport no',
          'passport number',
          'passeport n',
          'document no',
        ],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.fullName,
        labelKey: DocumentFieldKeys.fullName,
        order: 20,
        binding: DocumentBaseBinding.owner,
        ocrAliases: ['surname', 'given names', 'name', 'nom', 'prénoms'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.nationality,
        labelKey: DocumentFieldKeys.nationality,
        order: 30,
        ocrAliases: ['nationality', 'nationalité', 'nation'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.dateOfBirth,
        labelKey: DocumentFieldKeys.dateOfBirth,
        order: 40,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        ocrAliases: ['date of birth', 'birth', 'naissance', 'dob'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.issueDate,
        labelKey: DocumentFieldKeys.issueDate,
        order: 50,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        binding: DocumentBaseBinding.issueDate,
        ocrAliases: ['date of issue', 'issue date', 'délivrance'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.expiryDate,
        labelKey: DocumentFieldKeys.expiryDate,
        order: 60,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        required: true,
        optional: false,
        binding: DocumentBaseBinding.expiryDate,
        ocrAliases: [
          'date of expiry',
          'expiry',
          'expiration',
          'date d\'expiration',
        ],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.issuingAuthority,
        labelKey: DocumentFieldKeys.issuingAuthority,
        order: 70,
        binding: DocumentBaseBinding.issuer,
        ocrAliases: ['authority', 'issuing', 'autorité'],
      ),
    ],
  );

  static const _aadhaar = DocumentSchema(
    id: DocumentSchemaIds.indiaAadhaar,
    countryCode: DocumentCountryCodes.india,
    typeKey: DocumentSchemaIds.indiaAadhaar,
    category: DocumentCategory.idCard,
    fields: [
      DynamicDocumentField(
        id: DocumentFieldKeys.aadhaarNumber,
        labelKey: DocumentFieldKeys.aadhaarNumber,
        order: 10,
        inputType: DocumentFieldInputType.number,
        sensitive: true,
        required: true,
        optional: false,
        binding: DocumentBaseBinding.number,
        ocrAliases: ['aadhaar', 'uid', 'enrolment'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.fullName,
        labelKey: DocumentFieldKeys.fullName,
        order: 20,
        binding: DocumentBaseBinding.owner,
        ocrAliases: ['name', 'naam'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.dateOfBirth,
        labelKey: DocumentFieldKeys.dateOfBirth,
        order: 30,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        ocrAliases: ['dob', 'yob', 'year of birth', 'date of birth'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.gender,
        labelKey: DocumentFieldKeys.gender,
        order: 40,
        ocrAliases: ['gender', 'male', 'female', 'sex'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.address,
        labelKey: DocumentFieldKeys.address,
        order: 50,
        inputType: DocumentFieldInputType.multiline,
        ocrAliases: ['address', 's/o', 'd/o', 'c/o'],
      ),
    ],
  );

  static const _franceId = DocumentSchema(
    id: DocumentSchemaIds.franceNationalId,
    countryCode: DocumentCountryCodes.france,
    typeKey: DocumentSchemaIds.franceNationalId,
    category: DocumentCategory.idCard,
    fields: [
      DynamicDocumentField(
        id: DocumentFieldKeys.documentNumber,
        labelKey: DocumentFieldKeys.documentNumber,
        order: 10,
        sensitive: true,
        required: true,
        optional: false,
        binding: DocumentBaseBinding.number,
        ocrAliases: ['document no', 'n°', 'numero', 'carte'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.surname,
        labelKey: DocumentFieldKeys.surname,
        order: 20,
        ocrAliases: ['nom', 'surname'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.givenNames,
        labelKey: DocumentFieldKeys.givenNames,
        order: 30,
        ocrAliases: ['prénoms', 'prenoms', 'given names'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.nationality,
        labelKey: DocumentFieldKeys.nationality,
        order: 40,
        ocrAliases: ['nationalité', 'nationalite', 'nationality'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.dateOfBirth,
        labelKey: DocumentFieldKeys.dateOfBirth,
        order: 50,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        ocrAliases: ['date de naissance', 'naissance', 'date of birth'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.issueDate,
        labelKey: DocumentFieldKeys.issueDate,
        order: 60,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        binding: DocumentBaseBinding.issueDate,
        ocrAliases: ['date de délivrance', 'delivrance', 'issue'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.expiryDate,
        labelKey: DocumentFieldKeys.expiryDate,
        order: 70,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        binding: DocumentBaseBinding.expiryDate,
        ocrAliases: ['date d\'expiration', 'expiration', 'expiry'],
      ),
    ],
  );

  static const _emiratesId = DocumentSchema(
    id: DocumentSchemaIds.uaeEmiratesId,
    countryCode: DocumentCountryCodes.uae,
    typeKey: DocumentSchemaIds.uaeEmiratesId,
    category: DocumentCategory.idCard,
    fields: [
      DynamicDocumentField(
        id: DocumentFieldKeys.idNumber,
        labelKey: DocumentFieldKeys.idNumber,
        order: 10,
        sensitive: true,
        required: true,
        optional: false,
        binding: DocumentBaseBinding.number,
        ocrAliases: ['id number', 'identity number', 'id no'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.name,
        labelKey: DocumentFieldKeys.name,
        order: 20,
        binding: DocumentBaseBinding.owner,
        ocrAliases: ['name', 'full name'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.nationality,
        labelKey: DocumentFieldKeys.nationality,
        order: 30,
        ocrAliases: ['nationality', 'nation'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.dateOfBirth,
        labelKey: DocumentFieldKeys.dateOfBirth,
        order: 40,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        ocrAliases: ['date of birth', 'dob', 'birth'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.issueDate,
        labelKey: DocumentFieldKeys.issueDate,
        order: 50,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        binding: DocumentBaseBinding.issueDate,
        ocrAliases: ['issue date', 'date of issue', 'issuing'],
      ),
      DynamicDocumentField(
        id: DocumentFieldKeys.expiryDate,
        labelKey: DocumentFieldKeys.expiryDate,
        order: 60,
        inputType: DocumentFieldInputType.date,
        isDate: true,
        binding: DocumentBaseBinding.expiryDate,
        ocrAliases: ['expiry', 'expiration', 'date of expiry'],
      ),
    ],
  );

  static const _genericOther = DocumentSchema(
    id: DocumentSchemaIds.genericOther,
    countryCode: DocumentCountryCodes.other,
    typeKey: DocumentSchemaIds.genericOther,
    category: DocumentCategory.other,
    fields: [],
  );
}
