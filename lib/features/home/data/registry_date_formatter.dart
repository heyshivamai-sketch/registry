import 'package:intl/intl.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

/// Shared document/home date presentation. Always includes day, month and year.
abstract final class RegistryDateFormatter {
  static String dayMonthYear(DateTime date, String locale) {
    final local = DateTime(date.year, date.month, date.day);
    final day = DateFormat('dd', locale).format(local);
    final month = DateFormat.MMM(locale).format(local);
    final year = DateFormat('yyyy', locale).format(local);
    return '$day $month $year';
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int daysUntil(DateTime date, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    return dateOnly(date).difference(today).inDays;
  }

  /// 0 = far / unstarted, 1 = due or overdue, across a 90-day horizon.
  static double horizonProgress(int daysUntil) {
    if (daysUntil <= 0) {
      return 1;
    }
    return (1 - (daysUntil / AppSpacing.horizonDays)).clamp(0.0, 1.0);
  }

  static String weekdayDateLine(DateTime date, String locale) {
    final local = DateTime(date.year, date.month, date.day);
    final weekday = DateFormat.EEEE(locale).format(local);
    final rest = DateFormat.yMMMMd(locale).format(local);
    return '$weekday · $rest';
  }

  static bool isWithinHorizon(DateTime date, {DateTime? now}) {
    return daysUntil(date, now: now) <= AppSpacing.horizonDays;
  }

  static String monthYear(DateTime date, String locale) {
    final local = DateTime(date.year, date.month, date.day);
    final month = DateFormat.MMM(locale).format(local);
    final year = DateFormat('yyyy', locale).format(local);
    return '$month $year';
  }

  static String dayNumber(DateTime date, String locale) {
    return DateFormat(
      'dd',
      locale,
    ).format(DateTime(date.year, date.month, date.day));
  }
}
