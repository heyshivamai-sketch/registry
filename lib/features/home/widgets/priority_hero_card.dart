import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_countdown_ring.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
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
    final stacked = textScale > 18 || MediaQuery.sizeOf(context).width < 340;

    Widget dateCell(String eyebrow, String value) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: onHero.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: onHero.withValues(alpha: 0.09)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFAEB9DB),
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: onHero,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        borderRadius: BorderRadius.circular(AppSpacing.pulseRadius),
        boxShadow: AppShadows.pulse(context),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand.heroStart, brand.heroEnd],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.pulseRadius),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -30,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        brand.heroHighlight.withValues(alpha: 0.55),
                        brand.heroHighlight.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: const SizedBox(width: 180, height: 180),
                ),
              ),
            ),
            Positioned(
              right: -46,
              bottom: -80,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: onHero.withValues(alpha: 0.09)),
                  ),
                  child: const SizedBox(width: 150, height: 150),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stacked) ...[
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ring,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RegistryAuraStatusPill(
                      status: item.status,
                      label: l10n.actionNeeded,
                      onDark: true,
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RegistryAuraStatusPill(
                            status: item.status,
                            label: l10n.actionNeeded,
                            onDark: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ring,
                      ],
                    ),
                  const SizedBox(height: 15),
                  Text(
                    l10n.pulseEyebrow,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFAEB9DB),
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.heroTitle(l10n),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: onHero,
                      fontSize: 25,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.title(l10n)} · ${item.impactLabel(l10n)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFCBD3ED),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackedDates = constraints.maxWidth < 280;
                      final start = dateCell(
                        item.type == RegistryItemType.subscription
                            ? l10n.pulseDecideByEyebrow
                            : l10n.pulseStartByEyebrow,
                        startDate,
                      );
                      final expiry = dateCell(
                        item.type == RegistryItemType.subscription
                            ? l10n.pulseNextChargeEyebrow
                            : l10n.pulseExpiresEyebrow,
                        expiryDate,
                      );
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
                          minimumSize: const Size(AppSpacing.minTapTarget, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    child: RegistryPrimaryButton(
                      key: const ValueKey<String>('hero-review'),
                      label: l10n.reviewAction,
                      trailing: Icon(
                        Icons.north_east_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      onPressed: () =>
                          AppRoutes.openRegistryItem(context, item),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
