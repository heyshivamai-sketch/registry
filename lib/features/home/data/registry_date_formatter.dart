import 'package:intl/intl.dart';

abstract final class RegistryDateFormatter {
  static String dayMonth(DateTime date, String locale) {
    final month = DateFormat.MMM(locale).format(date);
    final day = date.day.toString().padLeft(2, '0');
    return '$day $month';
  }
}
