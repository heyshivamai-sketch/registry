abstract final class PersistedValues {
  static String encodeDate(DateTime value) {
    final zone = value.isUtc ? 'u' : 'l';
    return '$zone:${value.microsecondsSinceEpoch}';
  }

  static DateTime decodeDate(Object? value) {
    final raw = decodeString(value);
    final separator = raw.indexOf(':');
    if (separator != 1) {
      throw FormatException('Unreadable date "$raw"');
    }
    final zone = raw.substring(0, separator);
    if (zone != 'u' && zone != 'l') {
      throw FormatException('Unreadable date "$raw"');
    }
    final micros = int.tryParse(raw.substring(separator + 1));
    if (micros == null) {
      throw FormatException('Unreadable date "$raw"');
    }
    return DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: zone == 'u');
  }

  static String? encodeOptionalDate(DateTime? value) {
    return value == null ? null : encodeDate(value);
  }

  static DateTime? decodeOptionalDate(Object? value) {
    if (value == null) {
      return null;
    }
    return decodeDate(value);
  }

  static String encodeEnumSet<T extends Enum>(Set<T> values) {
    final sorted = values.toList()..sort((a, b) => a.index.compareTo(b.index));
    return sorted.map((value) => value.name).join(',');
  }

  static Set<T> decodeEnumSet<T extends Enum>(List<T> values, Object? raw) {
    final stored = decodeString(raw);
    if (stored.isEmpty) {
      return <T>{};
    }
    return {for (final part in stored.split(',')) decodeEnum(values, part)};
  }

  static T decodeEnum<T extends Enum>(List<T> values, Object? raw) {
    final name = decodeString(raw);
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw FormatException('Unknown stored value "$name"');
  }

  static int encodeBool(bool value) => value ? 1 : 0;

  static bool decodeBool(Object? value) {
    if (value == 1 || value == true) {
      return true;
    }
    if (value == 0 || value == false) {
      return false;
    }
    throw FormatException('Expected a stored flag, got $value');
  }

  static int decodeInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('Expected a stored integer, got $value');
  }

  static int? decodeOptionalInt(Object? value) {
    if (value == null) {
      return null;
    }
    return decodeInt(value);
  }

  static String decodeString(Object? value) {
    if (value is String) {
      return value;
    }
    throw FormatException('Expected stored text, got $value');
  }

  static String? decodeOptionalString(Object? value) {
    if (value == null) {
      return null;
    }
    return decodeString(value);
  }
}
