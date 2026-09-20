import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeUpcomingItem extends StatelessWidget {
  const HomeUpcomingItem({
    super.key,
    required this.item,
    required this.isLast,
    this.onTap,
    this.showStatus = false,
    this.locale,
  });

  final RegistryItem item;
  final bool isLast;
  final VoidCallback? onTap;
  final bool showStatus;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedLocale = locale ?? l10n.localeName;
    final day = RegistryDateFormatter.dayNumber(
      item.actionDate,
      resolvedLocale,
    );
    final month = DateTime(
      item.actionDate.year,
      item.actionDate.month,
      item.actionDate.day,
    );
    final monthLabel = RegistryDateFormatter.monthYear(
      month,
      resolvedLocale,
    ).split(' ').first.toUpperCase();
    final actionDate = RegistryDateFormatter.dayMonthYear(
      item.actionDate,
      resolvedLocale,
    );
    final dueDate = RegistryDateFormatter.dayMonthYear(
      item.dueDate,
      resolvedLocale,
    );
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    Widget trailing;
    if (item.type == RegistryItemType.subscription && item.amount != null) {
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            MoneyFormat.format(item.amount!, resolvedLocale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
          ),
          Text(
            actionDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    } else {
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(l10n.pulseExpiresEyebrow, style: theme.textTheme.bodySmall),
          Text(dueDate, style: theme.textTheme.bodySmall),
        ],
      );
    }

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Text(
                            day,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            monthLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 0.6,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _LeadingMark(item: item),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title(l10n),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          if (showStatus) ...[
                            const SizedBox(height: 4),
                            RegistryAuraStatusPill(
                              status: item.status,
                              label: item.statusLabel(l10n),
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
                    Icon(chevron, color: const Color(0xFF737B91)),
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
  const _LeadingMark({required this.item});

  final RegistryItem item;

  @override
  Widget build(BuildContext context) {
    final brand = AppBrandColors.of(context);
    if (item.type == RegistryItemType.subscription) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              item.initialBadge(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: brand.indigo,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.mintSurface,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          item.icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
