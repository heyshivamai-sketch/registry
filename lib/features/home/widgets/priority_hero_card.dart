import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_countdown_ring.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class PriorityHeroCard extends StatelessWidget {
  const PriorityHeroCard({super.key, required this.item});

  final RegistryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brand = AppBrandColors.of(context);
    final locale = l10n.localeName;
    final startDate = RegistryDateFormatter.dayMonthYear(
      item.actionDate,
      locale,
    );
    final expiryDate = RegistryDateFormatter.dayMonthYear(item.dueDate, locale);
    final onHero = colorScheme.onPrimary;
    final days = item.remainingDays();
    final textScale = MediaQuery.textScalerOf(context).scale(14);
    final stacked = textScale > 18 || MediaQuery.sizeOf(context).width < 400;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RegistryIconBadge(
              icon: item.icon,
              background: onHero.withValues(alpha: 0.14),
              foreground: onHero,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: onHero.withValues(alpha: 0.14),
                borderRadius: AppRadius.chipBorder,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                child: Wrap(
                  spacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.priority_high_rounded,
                      size: AppSpacing.md,
                      color: onHero,
                    ),
                    Text(
                      l10n.actionNeeded,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: onHero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.pulseEyebrow,
          style: theme.textTheme.labelMedium?.copyWith(
            color: onHero.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          item.heroTitle(l10n),
          style: theme.textTheme.titleLarge?.copyWith(color: onHero),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.actionDateLabel(l10n, startDate),
          style: theme.textTheme.titleSmall?.copyWith(color: onHero),
        ),
        Text(
          item.dueDateLabel(l10n, expiryDate),
          style: theme.textTheme.bodySmall?.copyWith(
            color: onHero.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Theme(
          data: theme.copyWith(
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerLowest,
                foregroundColor: colorScheme.primary,
                minimumSize: const Size(
                  AppSpacing.minTapTarget,
                  AppSpacing.minTapTarget,
                ),
              ),
            ),
          ),
          child: RegistryPrimaryButton(
            key: const ValueKey<String>('hero-review'),
            label: l10n.reviewAction,
            onPressed: () {},
          ),
        ),
      ],
    );

    final ring = RegistryCountdownRing(
      key: const ValueKey<String>('hero-countdown'),
      daysUntil: days,
      valueLabel: item.countdownValueLabel(),
      unitLabel: item.countdownUnitLabel(l10n),
      semanticLabel: item.remainingLabel(l10n),
      status: item.status,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgBorder,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [brand.heroStart, brand.heroEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: brand.heroStart.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  details,
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ring,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  const SizedBox(width: AppSpacing.sm),
                  ring,
                ],
              ),
      ),
    );
  }
}
