import 'package:flutter/material.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/registry_dependencies.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../core/widgets/attention_entrance.dart';
import '../../../l10n/app_localizations.dart';
import '../data/registry_item.dart';
import 'registry_hero_pass_stack.dart';

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.pulse(context),
        gradient: LinearGradient(colors: [brand.heroStart, brand.heroEnd]),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                        brand.heroHighlight.withValues(alpha: 0.35),
                        brand.heroHighlight.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: const SizedBox(width: 140, height: 140),
                ),
              ),
            ),
            if (highlighted != null)
              PositionedDirectional(
                end: -10,
                bottom: -15,
                child: IgnorePointer(
                  child: AttentionEntrance(
                    child: Opacity(
                      opacity: 0.65,
                      child: Transform.scale(
                        scale: 0.85,
                        alignment: AlignmentDirectional.bottomEnd,
                        child: RegistryHeroPassStack(icon: highlighted.icon),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: content,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.actionNeeded.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFFFF9B94),
            letterSpacing: 1.2,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.heroTitle(l10n),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: onHero,
            fontSize: 19,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: Color(0xFFD5DBF2),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                item.heroExplanation(l10n, now: now),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFD5DBF2),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey<String>('hero-review'),
          onPressed: () => AppRoutes.openRegistryItem(context, item),
          style: FilledButton.styleFrom(
            backgroundColor: onHero,
            foregroundColor: theme.colorScheme.primary,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle: theme.textTheme.labelMedium?.copyWith(
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
                  size: 15,
                ),
              ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.homeCalmTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: onHero,
            fontSize: 18,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.homeCalmMessage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFFD5DBF2),
          ),
        ),
        if (upcomingItem != null) ...[
          const SizedBox(height: 10),
          FilledButton(
            key: const ValueKey<String>('hero-view-upcoming'),
            onPressed: () => AppRoutes.openHorizon90Day(context),
            style: FilledButton.styleFrom(
              backgroundColor: onHero,
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: theme.textTheme.labelMedium?.copyWith(
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
