import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_colors.dart';
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
    final brand = AppBrandColors.of(context);
    final dateLine = RegistryDateFormatter.weekdayDateLine(
      DateTime.now(),
      l10n.localeName,
    );

    Widget headerButton({
      required Key key,
      required String label,
      required VoidCallback onTap,
      required Widget child,
      BoxDecoration? decoration,
      ShapeBorder? shape,
    }) {
      return Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          shape: shape,
          child: InkWell(
            key: key,
            onTap: onTap,
            customBorder: shape,
            child: Ink(
              width: AppSpacing.minTapTarget,
              height: AppSpacing.minTapTarget,
              decoration: decoration,
              child: Center(child: child),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLine.toUpperCase(),
                style: AppTypography.eyebrow(context),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.homeTitle, style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        headerButton(
          key: const ValueKey<String>('home-profile'),
          label: l10n.profileButton,
          onTap: () => AppRoutes.openProfile(context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [brand.heroStart, brand.indigo],
            ),
          ),
          child: Text(
            l10n.profileMonogram,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        headerButton(
          key: const ValueKey<String>('home-notifications'),
          label: l10n.notificationsButton,
          onTap: () => AppRoutes.openNotifications(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
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
                  child: const SizedBox(width: 7, height: 7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
