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
      required String shortLabel,
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
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTapTarget,
                minHeight: AppSpacing.minTapTarget,
              ),
              child: AnimatedContainer(
                duration: reduceMotion ? Duration.zero : AppMotion.short,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.onPrimary.withValues(alpha: 0.075)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? selectedIcon : icon,
                      size: 18,
                      color: selected
                          ? colorScheme.onPrimary
                          : brand.dockForeground,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          shortLabel,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: selected
                                    ? colorScheme.onPrimary
                                    : brand.dockForeground,
                                fontSize: 10,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                    ] else if (selected) ...[
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          shortLabel,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontSize: 10,
                                letterSpacing: 0,
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
                  colors: [brand.addStart, brand.addEnd],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF444FC6).withValues(alpha: 0.42),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: colorScheme.onPrimary,
                size: 25,
              ),
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
        AppSpacing.dockBottom,
      ),
      child: SizedBox(
        height: AppSpacing.dockHeight + AppSpacing.addButtonLift,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: AppRadius.dockBorder,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: brand.dock,
                    borderRadius: AppRadius.dockBorder,
                    border: Border.all(
                      color: colorScheme.onPrimary.withValues(alpha: 0.125),
                    ),
                    boxShadow: AppShadows.dock(context),
                  ),
                  child: SizedBox(
                    height: AppSpacing.dockHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: destination(
                              index: 0,
                              icon: Icons.home_outlined,
                              selectedIcon: Icons.home_rounded,
                              label: l10n.navHome,
                              shortLabel: l10n.navHome,
                              key: const ValueKey<String>('nav-home'),
                            ),
                          ),
                          Expanded(
                            child: destination(
                              index: 1,
                              icon: Icons.folder_outlined,
                              selectedIcon: Icons.folder_rounded,
                              label: l10n.navDocuments,
                              shortLabel: l10n.navDocumentsShort,
                              key: const ValueKey<String>('nav-documents'),
                            ),
                          ),
                          const SizedBox(width: 58),
                          Expanded(
                            child: destination(
                              index: 2,
                              icon: Icons.subscriptions_outlined,
                              selectedIcon: Icons.subscriptions_rounded,
                              label: l10n.navSubscriptions,
                              shortLabel: l10n.navSubscriptionsShort,
                              key: const ValueKey<String>('nav-subscriptions'),
                            ),
                          ),
                          Expanded(
                            child: destination(
                              index: 3,
                              icon: Icons.person_outline_rounded,
                              selectedIcon: Icons.person_rounded,
                              label: l10n.navProfile,
                              shortLabel: l10n.navProfileShort,
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
            Positioned(top: -AppSpacing.addButtonLift, child: addButton),
          ],
        ),
      ),
    );
  }
}
