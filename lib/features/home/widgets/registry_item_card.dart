import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistryItemCard extends StatelessWidget {
  const RegistryItemCard({super.key, required this.item, this.onTap});

  final RegistryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = l10n.localeName;
    final actionDate = RegistryDateFormatter.dayMonthYear(
      item.actionDate,
      locale,
    );
    final dueDate = RegistryDateFormatter.dayMonthYear(item.dueDate, locale);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: SizedBox(
                  width: AppSpacing.minTapTarget,
                  height: AppSpacing.minTapTarget,
                  child: Icon(
                    item.icon,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.typeLabel(l10n),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      item.title(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      item.actionLabel(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.actionDateLabel(l10n, actionDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      item.dueDateLabel(l10n, dueDate),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RegistryStatusChip(
                      status: item.status,
                      label: item.impact == RegistryImpact.high
                          ? l10n.highImpactLabel
                          : item.statusLabel(l10n),
                    ),
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
