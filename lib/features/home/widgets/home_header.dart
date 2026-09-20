import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/app/theme/app_typography.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = RegistryDependencies.of(context).clock.now();
    final dateLine = RegistryDateFormatter.weekdayDateLine(
      now,
      l10n.localeName,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLine,
                style: AppTypography.eyebrow(context)?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.homeTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.9,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          button: true,
          label: l10n.profileButton,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey<String>('home-profile'),
              onTap: () => AppRoutes.openProfile(context),
              customBorder: const CircleBorder(),
              child: Ink(
                width: AppSpacing.minTapTarget,
                height: AppSpacing.minTapTarget,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerLowest,
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Center(
                  child: Text(
                    l10n.profileMonogram,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
