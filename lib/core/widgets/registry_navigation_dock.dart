import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_motion.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistryAuraNavigationDock extends StatelessWidget {
  const RegistryAuraNavigationDock({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
  });

  /// 0 Home, 1 Documents, 2 Subscriptions, 3 Profile.
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = AppBrandColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final compact = AppSpacing.compactNavigation(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget destination({
      required int index,
      required IconData icon,
      required IconData selectedIcon,
      required String label,
      required Key key,
    }) {
      final selected = selectedIndex == index;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            key: key,
            onTap: () => onDestinationSelected(index),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTapTarget,
                minHeight: AppSpacing.minTapTarget,
              ),
              child: AnimatedContainer(
                duration: reduceMotion ? Duration.zero : AppMotion.short,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.onPrimary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? selectedIcon : icon,
                      size: 20,
                      color: selected
                          ? colorScheme.onPrimary
                          : brand.dockForeground,
                    ),
                    if (selected && !compact) ...[
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final addButton = Semantics(
      button: true,
      label: l10n.addFabTooltip,
      child: Tooltip(
        message: l10n.addFabTooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey<String>('home-fab'),
            onTap: onAddPressed,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Ink(
              width: AppSpacing.addButtonSize,
              height: AppSpacing.addButtonSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand.violet, brand.indigo],
                ),
                boxShadow: [
                  BoxShadow(
                    color: brand.violet.withValues(alpha: 0.42),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded, color: colorScheme.onPrimary),
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.dockInset,
        0,
        AppSpacing.dockInset,
        AppSpacing.xs,
      ),
      child: SizedBox(
        height: AppSpacing.dockHeight + 12,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: AppRadius.dockBorder,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: brand.dock,
                      borderRadius: AppRadius.dockBorder,
                      border: Border.all(
                        color: colorScheme.onPrimary.withValues(alpha: 0.12),
                      ),
                      boxShadow: AppShadows.dock(context),
                    ),
                    child: SizedBox(
                      height: AppSpacing.dockHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: destination(
                                index: 0,
                                icon: Icons.home_outlined,
                                selectedIcon: Icons.home_rounded,
                                label: l10n.navHome,
                                key: const ValueKey<String>('nav-home'),
                              ),
                            ),
                            Expanded(
                              child: destination(
                                index: 1,
                                icon: Icons.folder_outlined,
                                selectedIcon: Icons.folder_rounded,
                                label: l10n.navDocuments,
                                key: const ValueKey<String>('nav-documents'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.addButtonSize),
                            Expanded(
                              child: destination(
                                index: 2,
                                icon: Icons.subscriptions_outlined,
                                selectedIcon: Icons.subscriptions_rounded,
                                label: l10n.navSubscriptions,
                                key: const ValueKey<String>(
                                  'nav-subscriptions',
                                ),
                              ),
                            ),
                            Expanded(
                              child: destination(
                                index: 3,
                                icon: Icons.person_outline_rounded,
                                selectedIcon: Icons.person_rounded,
                                label: l10n.navProfile,
                                key: const ValueKey<String>('nav-profile'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(top: 0, child: addButton),
          ],
        ),
      ),
    );
  }
}
