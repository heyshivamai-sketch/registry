import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
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
    final locale = l10n.localeName;
    final startDate = RegistryDateFormatter.dayMonthYear(
      item.actionDate,
      locale,
    );
    final expiryDate = RegistryDateFormatter.dayMonthYear(item.dueDate, locale);
    final accent = Color.lerp(
      colorScheme.primary,
      colorScheme.secondary,
      0.38,
    )!;

    return Semantics(
      button: true,
      label: item.heroTitle(l10n),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardBorder,
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colorScheme.primary, accent],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.icon, color: colorScheme.onPrimary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item.typeLabel(l10n),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.86),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.16),
                      borderRadius: AppRadius.chipBorder,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Text(
                        l10n.highImpactLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                item.heroTitle(l10n),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.actionLabel(l10n),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                item.actionDateLabel(l10n, startDate),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                item.dueDateLabel(l10n, expiryDate),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: Theme(
                  data: theme.copyWith(
                    filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.surface,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
