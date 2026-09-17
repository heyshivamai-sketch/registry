import 'package:intl/intl.dart';

/// Shared document/home date presentation. Always includes day, month and year.
abstract final class RegistryDateFormatter {
  static String dayMonthYear(DateTime date, String locale) {
    final local = DateTime(date.year, date.month, date.day);
    final day = DateFormat('dd', locale).format(local);
    final month = DateFormat.MMM(locale).format(local);
    final year = DateFormat('yyyy', locale).format(local);
    return '$day $month $year';
  }
}
