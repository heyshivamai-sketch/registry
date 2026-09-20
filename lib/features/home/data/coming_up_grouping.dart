import 'package:intl/intl.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class ComingUpGroup {
  const ComingUpGroup({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<RegistryItem> items;
}

abstract final class ComingUpGrouping {
  static List<ComingUpGroup> group({
    required Iterable<RegistryItem> items,
    required DateTime now,
    required String locale,
    required AppLocalizations l10n,
  }) {
    final weekStart = RegistryDateFormatter.startOfWeek(now, locale);
    final weekEnd = RegistryDateFormatter.endOfWeek(now, locale);
    final month = RegistryDateFormatter.dateOnly(now);
    final thisWeek = <RegistryItem>[];
    final laterThisMonth = <RegistryItem>[];
    final later = <String, List<RegistryItem>>{};

    for (final item in items) {
      final day = RegistryDateFormatter.dateOnly(item.actionDate);
      if (RegistryDateFormatter.isInRange(day, weekStart, weekEnd)) {
        thisWeek.add(item);
        continue;
      }
      if (day.year == month.year &&
          day.month == month.month &&
          day.isAfter(weekEnd)) {
        laterThisMonth.add(item);
        continue;
      }
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}';
      later.putIfAbsent(key, () => []).add(item);
    }

    final groups = <ComingUpGroup>[
      if (thisWeek.isNotEmpty)
        ComingUpGroup(
          id: 'this-week',
          label: l10n.comingUpThisWeek(weekStart.year.toString()),
          items: thisWeek,
        ),
      if (laterThisMonth.isNotEmpty)
        ComingUpGroup(
          id: 'later-month',
          label: l10n.comingUpLaterThisMonth(month.year.toString()),
          items: laterThisMonth,
        ),
    ];

    final laterKeys = later.keys.toList()..sort();
    for (final key in laterKeys) {
      final bucket = later[key]!;
      final sample = RegistryDateFormatter.dateOnly(bucket.first.actionDate);
      groups.add(
        ComingUpGroup(
          id: 'month-$key',
          label: l10n.comingUpMonthYear(
            DateFormat.MMMM(locale).format(sample).toUpperCase(),
            sample.year.toString(),
          ),
          items: bucket,
        ),
      );
    }
    return groups;
  }
}
