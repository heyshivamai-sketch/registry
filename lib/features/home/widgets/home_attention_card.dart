import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeAttentionCard extends StatelessWidget {
  const HomeAttentionCard({super.key, required this.item, this.onTap});

  final RegistryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = AppStatusColors.of(context);
    final locale = l10n.localeName;
    final dueDate = RegistryDateFormatter.dayMonthYear(item.dueDate, locale);
    final palette = switch (item.status) {
      RegistryStatus.urgent => (
        fill: status.urgentContainer,
        accent: status.urgent,
        icon: status.onUrgentContainer,
      ),
      RegistryStatus.upcoming => (
        fill: Color.lerp(
          status.warningContainer,
          colorScheme.surfaceContainerLowest,
          0.45,
        )!,
        accent: status.warning,
        icon: status.onWarningContainer,
      ),
      RegistryStatus.active => (
        fill: status.successContainer,
        accent: status.success,
        icon: status.onSuccessContainer,
      ),
      RegistryStatus.expired => (
        fill: status.expiredContainer,
        accent: status.expired,
        icon: status.onExpiredContainer,
      ),
    };

    final content = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegistryIconBadge(
            icon: item.icon,
            background: palette.fill,
            foreground: palette.icon,
          ),
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
                  '${item.actionLabel(l10n)} · ${item.dueDateLabel(l10n, dueDate)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.remainingLabel(l10n),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
          if (onTap != null)
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    return Material(
      color: Color.lerp(palette.fill, colorScheme.surfaceContainerLowest, 0.35),
      borderRadius: AppRadius.cardBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardBorder,
            border: BorderDirectional(
              start: BorderSide(
                color: palette.accent,
                width: item.status == RegistryStatus.urgent ? 4 : 3,
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
