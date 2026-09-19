import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
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
    this.showStatus = false,
  });

  final RegistryItem item;
  final bool isLast;
  final VoidCallback? onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = l10n.localeName;
    final dueDate = RegistryDateFormatter.dayMonthYear(item.dueDate, locale);
    final aqua = AppBrandColors.of(context).aqua;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(
                  RegistryDateFormatter.dayNumber(item.actionDate, locale),
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                Text(
                  RegistryDateFormatter.monthYear(item.actionDate, locale),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0,
                    fontSize: 11,
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
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: aqua,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 3),
                  ),
                  child: const SizedBox(width: 9, height: 9),
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Align(
                        child: SizedBox(
                          width: 1,
                          child: ColoredBox(color: const Color(0xFFD8DBE6)),
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
              padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
              child: Material(
                color: colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title(l10n),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        if (showStatus) ...[
                          const SizedBox(height: 6),
                          RegistryAuraStatusPill(
                            status: item.status,
                            label: item.statusLabel(l10n),
                            compact: true,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${item.actionLabel(l10n)} · $dueDate',
                          style: theme.textTheme.bodySmall,
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
