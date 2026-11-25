import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/registry_status_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscriptions/domain/money.dart';
import '../data/registry_date_formatter.dart';
import '../data/registry_item.dart';

enum HomeItemUrgency {
  overdue,
  expiringSoon,
  upcoming,
}

class HomeUpcomingItem extends StatelessWidget {
  const HomeUpcomingItem({
    required this.item,
    required this.isLast,
    super.key,
    this.onTap,
    this.showStatus = true,
    this.locale,
    this.now,
  });

  final RegistryItem item;
  final bool isLast;
  final VoidCallback? onTap;
  final bool showStatus;
  final String? locale;
  final DateTime? now;

  HomeItemUrgency _resolveUrgency(DateTime? clockNow) {
    final expiryDays = RegistryDateFormatter.daysUntil(item.dueDate, now: clockNow);
    final actionDays = RegistryDateFormatter.daysUntil(item.actionDate, now: clockNow);

    if (item.status == RegistryStatus.expired || expiryDays < 0) {
      return HomeItemUrgency.overdue;
    }
    if (item.status == RegistryStatus.urgent || actionDays <= 0 || (expiryDays >= 0 && expiryDays <= 5)) {
      return HomeItemUrgency.expiringSoon;
    }
    return HomeItemUrgency.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final resolvedLocale = locale ?? l10n.localeName;
    final clockNow = now ?? DateTime.now();
    final urgency = _resolveUrgency(clockNow);

    final day = RegistryDateFormatter.dayNumber(item.actionDate, resolvedLocale);
    final month = DateTime(item.actionDate.year, item.actionDate.month, item.actionDate.day);
    final monthLabel = RegistryDateFormatter.monthYear(month, resolvedLocale).split(' ').first.toUpperCase();
    final actionDate = RegistryDateFormatter.dayMonthYear(item.actionDate, resolvedLocale);
    final dueDate = RegistryDateFormatter.dayMonthYear(item.dueDate, resolvedLocale);
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    final (chipStatus, chipLabel) = switch (urgency) {
      HomeItemUrgency.overdue => (
        RegistryStatus.expired,
        l10n.statusOverdue,
      ),
      HomeItemUrgency.expiringSoon => (
        RegistryStatus.upcoming,
        item.status == RegistryStatus.urgent
            ? l10n.actionNeeded
            : l10n.statusExpiringSoon,
      ),
      HomeItemUrgency.upcoming => (
        RegistryStatus.active,
        l10n.statusUpcoming,
      ),
    };

    final chevronColor = switch (urgency) {
      HomeItemUrgency.overdue => statusColors.urgent.withValues(alpha: 0.9),
      HomeItemUrgency.expiringSoon => statusColors.onWarningContainer.withValues(alpha: 0.9),
      HomeItemUrgency.upcoming => const Color(0xFF737B91),
    };

    Widget trailing;
    if (item.type == RegistryItemType.subscription && item.amount != null) {
      final amountColor = switch (urgency) {
        HomeItemUrgency.overdue => statusColors.urgent,
        HomeItemUrgency.expiringSoon => statusColors.onWarningContainer,
        HomeItemUrgency.upcoming => theme.colorScheme.onSurface,
      };
      final dateColor = switch (urgency) {
        HomeItemUrgency.overdue => statusColors.urgent,
        HomeItemUrgency.expiringSoon => statusColors.onWarningContainer,
        HomeItemUrgency.upcoming => theme.colorScheme.onSurfaceVariant,
      };
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            MoneyFormat.format(item.amount!, resolvedLocale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 13,
              fontWeight: urgency == HomeItemUrgency.upcoming ? FontWeight.w500 : FontWeight.w700,
              color: amountColor,
            ),
          ),
          Text(
            actionDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: dateColor,
              fontWeight: urgency == HomeItemUrgency.upcoming ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      final eyebrowStyle = theme.textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: urgency == HomeItemUrgency.upcoming ? FontWeight.normal : FontWeight.w700,
        color: switch (urgency) {
          HomeItemUrgency.overdue => statusColors.urgent,
          HomeItemUrgency.expiringSoon => statusColors.onWarningContainer,
          HomeItemUrgency.upcoming => theme.colorScheme.onSurfaceVariant,
        },
      );
      final dateStyle = theme.textTheme.bodySmall?.copyWith(
        fontWeight: urgency == HomeItemUrgency.upcoming ? FontWeight.normal : FontWeight.w600,
        color: switch (urgency) {
          HomeItemUrgency.overdue => statusColors.urgent,
          HomeItemUrgency.expiringSoon => statusColors.onWarningContainer,
          HomeItemUrgency.upcoming => theme.colorScheme.onSurfaceVariant,
        },
      );
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            urgency == HomeItemUrgency.overdue ? l10n.statusOverdue : l10n.pulseExpiresEyebrow,
            style: eyebrowStyle,
          ),
          Text(dueDate, style: dateStyle),
        ],
      );
    }

    final dateDayColor = switch (urgency) {
      HomeItemUrgency.overdue => statusColors.urgent,
      HomeItemUrgency.expiringSoon => statusColors.onWarningContainer,
      HomeItemUrgency.upcoming => theme.colorScheme.onSurface,
    };
    final dateMonthColor = switch (urgency) {
      HomeItemUrgency.overdue => statusColors.urgent,
      HomeItemUrgency.expiringSoon => statusColors.onWarningContainer,
      HomeItemUrgency.upcoming => theme.colorScheme.onSurfaceVariant,
    };

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 36,
                      decoration: BoxDecoration(
                        color: switch (urgency) {
                          HomeItemUrgency.overdue => statusColors.urgent,
                          HomeItemUrgency.expiringSoon => statusColors.warning,
                          HomeItemUrgency.upcoming => Colors.transparent,
                        },
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Text(
                            day,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: dateDayColor,
                            ),
                          ),
                          Text(
                            monthLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 0.6,
                              fontSize: 10,
                              fontWeight: urgency == HomeItemUrgency.upcoming ? FontWeight.normal : FontWeight.w600,
                              color: dateMonthColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _LeadingMark(item: item, urgency: urgency),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title(l10n),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
                          ),
                          if (showStatus) ...[
                            const SizedBox(height: 4),
                            RegistryAuraStatusPill(
                              status: chipStatus,
                              label: chipLabel,
                              compact: true,
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            item.type == RegistryItemType.subscription
                                ? l10n.homeDecideBeforeRenewal
                                : l10n.homeStartRenewal,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: trailing),
                    Icon(chevron, color: chevronColor),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: colorScheme.outlineVariant),
      ],
    );
  }
}

class _LeadingMark extends StatelessWidget {
  const _LeadingMark({required this.item, required this.urgency});

  final RegistryItem item;
  final HomeItemUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = AppBrandColors.of(context);
    final statusColors = AppStatusColors.of(context);

    final (Color background, Color foreground) = switch (urgency) {
      HomeItemUrgency.overdue => (
        statusColors.urgentContainer,
        statusColors.urgent,
      ),
      HomeItemUrgency.expiringSoon => (
        statusColors.warningContainer,
        statusColors.onWarningContainer,
      ),
      HomeItemUrgency.upcoming => item.type == RegistryItemType.subscription
          ? (theme.colorScheme.primaryContainer, brand.indigo)
          : (brand.mintSurface, theme.colorScheme.primary),
    };

    if (item.type == RegistryItemType.subscription) {
      return DecoratedBox(
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              item.initialBadge(),
              style: theme.textTheme.titleSmall?.copyWith(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(item.icon, size: 16, color: foreground),
      ),
    );
  }
}
