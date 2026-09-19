import 'package:intl/intl.dart';

class Money {
  const Money({required this.minorUnits, required this.currencyCode});

  final int minorUnits;
  final String currencyCode;

  bool get isZero => minorUnits == 0;

  String get code => currencyCode.toUpperCase();

  @override
  bool operator ==(Object other) {
    return other is Money &&
        other.minorUnits == minorUnits &&
        other.code == code;
  }

  @override
  int get hashCode => Object.hash(minorUnits, code);
}

class MoneyParseException implements Exception {
  const MoneyParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class CurrencyInfo {
  static const supportedCodes = <String>[
    'USD',
    'EUR',
    'GBP',
    'INR',
    'AED',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'DZD',
    'MAD',
  ];

  static int fractionDigits(String currencyCode) {
    return switch (currencyCode.toUpperCase()) {
      'JPY' ||
      'KRW' ||
      'VND' ||
      'CLP' ||
      'ISK' ||
      'BIF' ||
      'DJF' ||
      'GNF' ||
      'KMF' ||
      'PYG' ||
      'RWF' ||
      'UGX' ||
      'VUV' ||
      'XAF' ||
      'XOF' ||
      'XPF' => 0,
      'BHD' || 'IQD' || 'JOD' || 'KWD' || 'LYD' || 'OMR' || 'TND' => 3,
      _ => 2,
    };
  }

  static int pow10(int digits) {
    var value = 1;
    for (var i = 0; i < digits; i++) {
      value *= 10;
    }
    return value;
  }
}

abstract final class MoneyParser {
  static Money parse(String raw, String currencyCode) {
    final code = currencyCode.trim().toUpperCase();
    if (code.isEmpty || !RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      throw const MoneyParseException('Invalid currency.');
    }
    var text = raw.trim();
    if (text.isEmpty) {
      throw const MoneyParseException('Amount is required.');
    }
    text = text.replaceAll(RegExp(code, caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'[^\d,.\-]'), '');
    text = text.trim();
    if (text.isEmpty || text == '-' || text == '.' || text == ',') {
      throw const MoneyParseException('Amount is required.');
    }
    if (text.contains('-')) {
      throw const MoneyParseException('Amount cannot be negative.');
    }

    final digits = CurrencyInfo.fractionDigits(code);
    final decimalIndex = _decimalSeparatorIndex(text, digits);
    String whole;
    String fraction;
    if (decimalIndex < 0) {
      whole = text.replaceAll(RegExp(r'[.,\s]'), '');
      fraction = '';
    } else {
      whole = text.substring(0, decimalIndex).replaceAll(RegExp(r'[.,\s]'), '');
      fraction = text.substring(decimalIndex + 1).replaceAll(RegExp(r'\D'), '');
    }
    if (whole.isEmpty) {
      whole = '0';
    }
    if (!RegExp(r'^\d+$').hasMatch(whole) ||
        (fraction.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fraction))) {
      throw const MoneyParseException('Amount is invalid.');
    }
    if (fraction.length > digits) {
      throw const MoneyParseException('Amount has too many decimal places.');
    }
    if (digits == 0 && fraction.isNotEmpty) {
      throw const MoneyParseException('Amount has too many decimal places.');
    }
    fraction = fraction.padRight(digits, '0');
    final minor = int.parse('$whole$fraction');
    if (minor < 0) {
      throw const MoneyParseException('Amount cannot be negative.');
    }
    return Money(minorUnits: minor, currencyCode: code);
  }

  static int _decimalSeparatorIndex(String text, int fractionDigits) {
    final lastDot = text.lastIndexOf('.');
    final lastComma = text.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      return lastDot > lastComma ? lastDot : lastComma;
    }
    if (lastDot >= 0) {
      return lastDot;
    }
    if (lastComma >= 0) {
      final after = text.substring(lastComma + 1).replaceAll(RegExp(r'\D'), '');
      if (fractionDigits > 0 && after.length <= fractionDigits) {
        return lastComma;
      }
      return -1;
    }
    return -1;
  }
}

abstract final class MoneyFormat {
  static String format(Money money, String locale) {
    final digits = CurrencyInfo.fractionDigits(money.code);
    final symbols = NumberFormat.decimalPattern(locale).symbols;
    final abs = money.minorUnits.abs();
    final divisor = CurrencyInfo.pow10(digits);
    final whole = abs ~/ divisor;
    final fraction = abs % divisor;
    final grouped = NumberFormat.decimalPattern(locale).format(whole);
    final sign = money.minorUnits < 0 ? symbols.MINUS_SIGN : '';
    if (digits == 0) {
      return '$sign$grouped ${money.code}';
    }
    final fractionText = fraction.toString().padLeft(digits, '0');
    return '$sign$grouped${symbols.DECIMAL_SEP}$fractionText ${money.code}';
  }
}

class MoneyRational {
  MoneyRational({
    required this.numerator,
    required this.denominator,
    required this.currencyCode,
  }) : assert(denominator != BigInt.zero);

  factory MoneyRational.fromMinor(int minorUnits, String currencyCode) {
    return MoneyRational(
      numerator: BigInt.from(minorUnits),
      denominator: BigInt.one,
      currencyCode: currencyCode.toUpperCase(),
    );
  }

  final BigInt numerator;
  final BigInt denominator;
  final String currencyCode;

  MoneyRational operator +(MoneyRational other) {
    if (currencyCode != other.currencyCode) {
      throw ArgumentError('Cannot add different currencies.');
    }
    return MoneyRational(
      numerator: numerator * other.denominator + other.numerator * denominator,
      denominator: denominator * other.denominator,
      currencyCode: currencyCode,
    );
  }

  Money roundHalfUp() {
    final sign = numerator.isNegative || denominator.isNegative ? -1 : 1;
    final num = numerator.abs();
    final den = denominator.abs();
    var whole = num ~/ den;
    final remainder = num.remainder(den);
    if (remainder * BigInt.two >= den) {
      whole += BigInt.one;
    }
    return Money(
      minorUnits: (whole.toInt()) * sign,
      currencyCode: currencyCode,
    );
  }
}
