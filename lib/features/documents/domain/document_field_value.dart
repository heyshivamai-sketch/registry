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

  String get maskedValue {
    final trimmed = value.trim();
    if (!sensitive || trimmed.isEmpty) {
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
    return DocumentFieldValue(
      id: id ?? this.id,
      fieldKey: fieldKey ?? this.fieldKey,
      customLabel: customLabel ?? this.customLabel,
      value: value ?? this.value,
      sensitive: sensitive ?? this.sensitive,
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
