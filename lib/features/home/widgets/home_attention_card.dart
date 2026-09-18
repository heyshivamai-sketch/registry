import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
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
    final accent = item.status.accent(status);
    final fill = item.status == RegistryStatus.urgent
        ? const Color(0xFFFFF8F7)
        : colorScheme.surfaceContainerLowest;

    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          RegistryAuraIconTile(
            icon: item.icon,
            size: 43,
            background: const Color(0xFFF0EFFF),
            foreground: colorScheme.tertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.actionLabel(l10n)} · $dueDate',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                RegistryAuraStatusPill(
                  status: item.status,
                  label: item.statusLabel(l10n),
                  compact: true,
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: const Color(0xFF737B91),
            ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppShadows.card(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardBorder,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardBorder,
              border: BorderDirectional(
                start: BorderSide(color: accent, width: 3),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTapTarget,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
