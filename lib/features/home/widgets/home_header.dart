import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brand = AppBrandColors.of(context);
    final dateLine = RegistryDateFormatter.weekdayDateLine(
      DateTime.now(),
      l10n.localeName,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLine.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.tertiary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.homeTitle, style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: l10n.profileButton,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey<String>('home-profile'),
              onTap: () => AppRoutes.openProfile(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Ink(
                width: AppSpacing.minTapTarget,
                height: AppSpacing.minTapTarget,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [brand.heroStart, brand.indigo],
                  ),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: colorScheme.onPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          button: true,
          label: l10n.notificationsButton,
          child: Material(
            color: colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: InkWell(
              key: const ValueKey<String>('home-notifications'),
              onTap: () => AppRoutes.openNotifications(context),
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: AppSpacing.minTapTarget,
                height: AppSpacing.minTapTarget,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: colorScheme.onSurface,
                    ),
                    PositionedDirectional(
                      top: 10,
                      end: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppStatusColors.of(context).urgent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surfaceContainerLowest,
                            width: 2,
                          ),
                        ),
                        child: const SizedBox(width: 8, height: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
