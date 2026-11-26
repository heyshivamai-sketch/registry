import 'package:flutter/material.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/registry_dependencies.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/paper_wallet_engraving.dart';
import '../../../l10n/app_localizations.dart';
import '../data/registry_item.dart';

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
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.pulse(context),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand.heroStart, brand.heroEnd],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            const Positioned.fill(
              child: PaperWalletEngraving(opacity: 0.13),
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: onHero.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Icon(item.icon, size: 16, color: onHero),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.actionNeeded.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFFFB4AC),
                  letterSpacing: isRtl ? 0 : 1.1,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          item.heroTitle(l10n),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.serif(
            context,
            fontSize: 19,
            height: 1.18,
            color: onHero,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: Color(0xFFDCE1F4),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.heroExplanation(l10n, now: now),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFDCE1F4),
                  fontSize: 12.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
          key: const ValueKey<String>('hero-review'),
          onPressed: () => AppRoutes.openRegistryItem(context, item),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFFCF7),
            foregroundColor: theme.colorScheme.primary,
            minimumSize: const Size(48, 42),
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
                  isRtl
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  size: 16,
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
          style: AppTypography.serif(
            context,
            fontSize: 18,
            height: 1.2,
            color: onHero,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.homeCalmMessage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFFDCE1F4),
            fontSize: 12.5,
          ),
        ),
        if (upcomingItem != null) ...[
          const SizedBox(height: 14),
          FilledButton(
            key: const ValueKey<String>('hero-view-upcoming'),
            onPressed: () => AppRoutes.openHorizon90Day(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFFCF7),
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size(48, 42),
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
