import 'document_schema.dart';

class DocumentFieldValue {
  const DocumentFieldValue({
    required this.id,
    required this.fieldKey,
    required this.value,
    this.customLabel,
    this.sensitive = false,
    this.isDate = false,
    this.isCustom = false,
  });

  final String id;
  final String fieldKey;
  final String? customLabel;
  final String value;
  final bool sensitive;
  final bool isDate;
  final bool isCustom;

  bool get isEmpty => value.trim().isEmpty;

  bool get canBeSensitive =>
      !DocumentFieldKeys.isNeverSensitive(fieldKey, customLabel) &&
      !DocumentFieldKeys.isNeverSensitive(id, customLabel);

  String get maskedValue {
    final trimmed = value.trim();
    if (!sensitive || !canBeSensitive || trimmed.isEmpty) {
      return trimmed;
    }
    if (trimmed.length <= 4) {
      return '•' * trimmed.length;
    }
    return '${'•' * (trimmed.length - 4)}${trimmed.substring(trimmed.length - 4)}';
  }

  DocumentFieldValue copyWith({
    String? id,
    String? fieldKey,
    String? customLabel,
    String? value,
    bool? sensitive,
    bool? isDate,
    bool? isCustom,
  }) {
    final nextFieldKey = fieldKey ?? this.fieldKey;
    final nextId = id ?? this.id;
    final nextLabel = customLabel ?? this.customLabel;
    final isAllowedSensitive =
        !DocumentFieldKeys.isNeverSensitive(nextFieldKey, nextLabel) &&
        !DocumentFieldKeys.isNeverSensitive(nextId, nextLabel);
    return DocumentFieldValue(
      id: nextId,
      fieldKey: nextFieldKey,
      customLabel: nextLabel,
      value: value ?? this.value,
      sensitive: isAllowedSensitive && (sensitive ?? this.sensitive),
      isDate: isDate ?? this.isDate,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentFieldValue &&
        other.id == id &&
        other.fieldKey == fieldKey &&
        other.customLabel == customLabel &&
        other.value == value &&
        other.sensitive == sensitive &&
        other.isDate == isDate &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode => Object.hash(
    id,
    fieldKey,
    customLabel,
    value,
    sensitive,
    isDate,
    isCustom,
  );
}
