import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brand = AppBrandColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeGreeting,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.homeTitle, style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          container: true,
          button: true,
          label: l10n.profileButton,
          child: Material(
            color: colorScheme.primary,
            shape: CircleBorder(
              side: BorderSide(color: brand.indigo, width: 2),
            ),
            child: InkWell(
              key: const ValueKey<String>('home-profile'),
              customBorder: const CircleBorder(),
              onTap: () => AppRoutes.openProfile(context),
              child: SizedBox(
                width: AppSpacing.minTapTarget,
                height: AppSpacing.minTapTarget,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: colorScheme.onPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
