import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_countdown_ring.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

/// Home mock catalog items are not stored in [DocumentRepository], so Review
/// has no production detail route in this phase.
const bool kHomeHeroReviewOpensDetail = false;

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

    Widget dateCell(String eyebrow, String value) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: onHero.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: onHero.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onHero.withValues(alpha: 0.72),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(color: onHero),
              ),
            ],
          ),
        ),
      );
    }

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegistryAuraStatusPill(status: item.status, label: l10n.actionNeeded),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.pulseEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: onHero.withValues(alpha: 0.78),
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          item.heroTitle(l10n),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: onHero,
            fontSize: 25,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${item.title(l10n)} · ${item.impactLabel(l10n)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onHero.withValues(alpha: 0.86),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackedDates = constraints.maxWidth < 280;
            final start = dateCell(l10n.pulseStartByEyebrow, startDate);
            final expiry = dateCell(l10n.pulseExpiresEyebrow, expiryDate);
            if (stackedDates) {
              return Column(
                children: [
                  SizedBox(width: double.infinity, child: start),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(width: double.infinity, child: expiry),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: start),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: expiry),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
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
          child: SizedBox(
            width: double.infinity,
            child: RegistryPrimaryButton(
              key: const ValueKey<String>('hero-review'),
              label: l10n.reviewAction,
              onPressed: kHomeHeroReviewOpensDetail ? () {} : () {},
            ),
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
        borderRadius: BorderRadius.circular(27),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand.heroStart, brand.heroEnd],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(alignment: AlignmentDirectional.centerEnd, child: ring),
                  const SizedBox(height: AppSpacing.sm),
                  details,
                ],
              )
            : Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [const Spacer(), ring],
                  ),
                  details,
                ],
              ),
      ),
    );
  }
}
