import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeUpcomingItem extends StatelessWidget {
  const HomeUpcomingItem({
    super.key,
    required this.item,
    required this.isLast,
    this.onTap,
  });

  final RegistryItem item;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = AppStatusColors.of(context);
    final locale = l10n.localeName;
    final dueDate = RegistryDateFormatter.dayMonthYear(item.dueDate, locale);
    final marker = switch (item.status) {
      RegistryStatus.urgent => status.urgent,
      RegistryStatus.upcoming => status.warning,
      RegistryStatus.active => status.success,
      RegistryStatus.expired => status.expired,
    };
    final statusFill = switch (item.status) {
      RegistryStatus.urgent => status.urgentContainer,
      RegistryStatus.upcoming => status.warningContainer,
      RegistryStatus.active => status.successContainer,
      RegistryStatus.expired => status.expiredContainer,
    };
    final fill = Color.lerp(
      colorScheme.surfaceContainerLowest,
      statusFill,
      0.22,
    )!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: AppSpacing.xxl + AppSpacing.xs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  RegistryDateFormatter.dayNumber(item.dueDate, locale),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  RegistryDateFormatter.monthYear(item.dueDate, locale),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: AppSpacing.md,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xs),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: marker,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(width: 10, height: 10),
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      child: Align(
                        child: SizedBox(
                          width: 2,
                          child: ColoredBox(color: colorScheme.outlineVariant),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
              child: Material(
                color: fill,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardBorder,
                  side: BorderSide(color: marker.withValues(alpha: 0.28)),
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: AppRadius.cardBorder,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, color: colorScheme.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title(l10n),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${item.actionLabel(l10n)} · $dueDate',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                item.remainingLabel(l10n),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              RegistryStatusChip(
                                status: item.status,
                                label: item.statusLabel(l10n),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
