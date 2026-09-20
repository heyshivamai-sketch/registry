import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/widgets/registry_hero_pass_stack.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class PriorityHeroCard extends StatelessWidget {
  const PriorityHeroCard({super.key, this.item, this.upcomingItem, this.now});

  final RegistryItem? item;
  final RegistryItem? upcomingItem;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brand = AppBrandColors.of(context);
    final clockNow = now ?? RegistryDependencies.maybeOf(context)?.clock.now();
    final onHero = colorScheme.onPrimary;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final stacked = textScale >= 1.35 || MediaQuery.sizeOf(context).width < 340;
    final highlighted = item;

    final content = highlighted == null
        ? _CalmContent(
            l10n: l10n,
            theme: theme,
            onHero: onHero,
            upcomingItem: upcomingItem,
          )
        : _AttentionContent(
            item: highlighted,
            l10n: l10n,
            theme: theme,
            onHero: onHero,
            locale: l10n.localeName,
            now: clockNow,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.pulse(context),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [brand.heroStart, brand.heroEnd],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -8,
              top: -12,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        brand.heroHighlight.withValues(alpha: 0.45),
                        brand.heroHighlight.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: const SizedBox(width: 150, height: 150),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        content,
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: RegistryHeroPassStack(icon: highlighted?.icon),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: content),
                        const SizedBox(width: 4),
                        RegistryHeroPassStack(icon: highlighted?.icon),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionContent extends StatelessWidget {
  const _AttentionContent({
    required this.item,
    required this.l10n,
    required this.theme,
    required this.onHero,
    required this.locale,
    required this.now,
  });

  final RegistryItem item;
  final AppLocalizations l10n;
  final ThemeData theme;
  final Color onHero;
  final String locale;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final date = RegistryDateFormatter.dayMonthYear(item.actionDate, locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.actionNeeded.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFFFF9B94),
            letterSpacing: 1.4,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.heroTitle(l10n),
          style: theme.textTheme.titleLarge?.copyWith(
            color: onHero,
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.heroExplanation(l10n, now: now),
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFFD5DBF2),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: onHero),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(color: onHero),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            key: const ValueKey<String>('hero-review'),
            onPressed: () => AppRoutes.openRegistryItem(context, item),
            style: FilledButton.styleFrom(
              backgroundColor: onHero,
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              shape: const StadiumBorder(),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.reviewAction),
                  const SizedBox(width: 6),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalmContent extends StatelessWidget {
  const _CalmContent({
    required this.l10n,
    required this.theme,
    required this.onHero,
    required this.upcomingItem,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final Color onHero;
  final RegistryItem? upcomingItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeCalmTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: onHero,
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.homeCalmMessage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFFD5DBF2),
          ),
        ),
        if (upcomingItem != null) ...[
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey<String>('hero-view-upcoming'),
            onPressed: () => AppRoutes.openHorizon90Day(context),
            style: FilledButton.styleFrom(
              backgroundColor: onHero,
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              shape: const StadiumBorder(),
            ),
            child: Text(l10n.homeCalmUpcomingCta),
          ),
        ],
      ],
    );
  }
}
