import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class MockRegistryCatalog {
  static final items = <RegistryItem>[
    RegistryItem(
      id: 'car_insurance',
      type: RegistryItemType.document,
      status: RegistryStatus.urgent,
      impact: RegistryImpact.high,
      impactScore: 100,
      actionDate: DateTime.utc(2026, 9, 20),
      dueDate: DateTime.utc(2026, 10, 5),
      isHero: true,
      needsAttention: true,
    ),
    RegistryItem(
      id: 'passport',
      type: RegistryItemType.document,
      status: RegistryStatus.upcoming,
      impact: RegistryImpact.high,
      impactScore: 78,
      actionDate: DateTime.utc(2026, 10, 1),
      dueDate: DateTime.utc(2026, 11, 12),
      isHero: false,
      needsAttention: true,
    ),
    RegistryItem(
      id: 'streaming',
      type: RegistryItemType.subscription,
      status: RegistryStatus.upcoming,
      impact: RegistryImpact.medium,
      impactScore: 64,
      actionDate: DateTime.utc(2026, 9, 22),
      dueDate: DateTime.utc(2026, 9, 28),
      isHero: false,
      needsAttention: true,
    ),
    RegistryItem(
      id: 'driving_licence',
      type: RegistryItemType.document,
      status: RegistryStatus.upcoming,
      impact: RegistryImpact.medium,
      impactScore: 42,
      actionDate: DateTime.utc(2026, 11, 15),
      dueDate: DateTime.utc(2026, 12, 1),
      isHero: false,
      needsAttention: false,
    ),
    RegistryItem(
      id: 'gym',
      type: RegistryItemType.subscription,
      status: RegistryStatus.active,
      impact: RegistryImpact.low,
      impactScore: 28,
      actionDate: DateTime.utc(2026, 10, 10),
      dueDate: DateTime.utc(2026, 10, 18),
      isHero: false,
      needsAttention: false,
    ),
  ];

  static List<RegistryItem> byImpact(Iterable<RegistryItem> source) {
    return [...source]..sort((a, b) => b.impactScore.compareTo(a.impactScore));
  }

  static bool matches(RegistryItem item, String query, AppLocalizations l10n) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    final haystack = [
      item.title(l10n),
      item.heroTitle(l10n),
      item.actionLabel(l10n),
      item.typeLabel(l10n),
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }
}
